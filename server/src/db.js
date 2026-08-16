const mongoose = require('mongoose');
const { mongoUri, useMemoryMongo } = require('./config');

let memoryServer;

function safeMongoUri(uri) {
  return String(uri || '').replace(/\/\/([^:]+):([^@]+)@/, '//$1:***@');
}

async function connectDb() {
  mongoose.set('strictQuery', true);

  if (useMemoryMongo) {
    if (process.env.NODE_ENV === 'production') {
      throw new Error(
        'USE_MEMORY_MONGO cannot be true in production. Set MONGODB_URI to Atlas.',
      );
    }
    const { MongoMemoryServer } = require('mongodb-memory-server');
    memoryServer = await MongoMemoryServer.create();
    const uri = memoryServer.getUri('falimy');
    await mongoose.connect(uri);
    console.log('MongoDB connected (in-memory — fine for local dev)');
    console.log('Tip: data resets when the server stops.');
    return;
  }

  if (!mongoUri || mongoUri.includes('127.0.0.1') || mongoUri.includes('localhost')) {
    if (process.env.NODE_ENV === 'production') {
      throw new Error(
        'MONGODB_URI is missing or points to localhost. Set Atlas URI in Render → Environment.',
      );
    }
  }

  try {
    // family: 4 forces IPv4 — required on many Render free instances with Atlas SRV.
    await mongoose.connect(mongoUri, {
      serverSelectionTimeoutMS: 20000,
      family: 4,
    });
    console.log(`MongoDB connected (${safeMongoUri(mongoUri)})`);
  } catch (err) {
    console.error('Could not connect to MongoDB at', safeMongoUri(mongoUri));
    console.error(err.message);
    console.error(
      'Check: 1) Render env MONGODB_URI  2) Atlas Network Access allows 0.0.0.0/0',
    );

    if (process.env.NODE_ENV === 'production') {
      throw err;
    }

    console.warn('Falling back to in-memory MongoDB...');
    const { MongoMemoryServer } = require('mongodb-memory-server');
    memoryServer = await MongoMemoryServer.create();
    const uri = memoryServer.getUri('falimy');
    await mongoose.connect(uri);
    console.log('MongoDB connected (in-memory fallback)');
    console.log('Tip: data resets when the server stops.');
  }
}

async function disconnectDb() {
  await mongoose.disconnect();
  if (memoryServer) {
    await memoryServer.stop();
    memoryServer = undefined;
  }
}

module.exports = { connectDb, disconnectDb };
