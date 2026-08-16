require('dotenv').config();

module.exports = {
  port: Number(process.env.PORT || 3000),
  mongoUri: process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/falimy',
  // When true (default in .env for local), skip Homebrew Mongo and use in-memory.
  useMemoryMongo:
    String(process.env.USE_MEMORY_MONGO || '').toLowerCase() === 'true' ||
    process.env.USE_MEMORY_MONGO === '1',
  jwtSecret: process.env.JWT_SECRET || 'falimy-dev-secret',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '30d',
};
