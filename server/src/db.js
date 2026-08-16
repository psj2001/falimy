const mongoose = require('mongoose');
const { mongoUri, useMemoryMongo } = require('./config');

let memoryServer;

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

  try {
    await mongoose.connect(mongoUri, { serverSelectionTimeoutMS: 8000 });
    const safeUri = mongoUri.replace(/\/\/([^:]+):([^@]+)@/, '//$1:***@');
    console.log(`MongoDB connected (${safeUri})`);
  } catch (err) {
    console.warn('Could not connect to MongoDB at', mongoUri);
    console.warn(err.message);

    // Never fall back to memory in production — data would vanish on restart.
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
