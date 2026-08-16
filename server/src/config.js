require('dotenv').config();

function env(name, fallback = '') {
  const raw = process.env[name];
  if (raw == null || raw === '') return fallback;
  // Strip accidental quotes from Render/dashboard paste
  return String(raw).trim().replace(/^['"]|['"]$/g, '');
}

module.exports = {
  port: Number(env('PORT', '3000')),
  mongoUri: env('MONGODB_URI', 'mongodb://127.0.0.1:27017/falimy'),
  // When true (default in .env for local), skip Homebrew Mongo and use in-memory.
  useMemoryMongo:
    String(env('USE_MEMORY_MONGO')).toLowerCase() === 'true' ||
    env('USE_MEMORY_MONGO') === '1',
  jwtSecret: env('JWT_SECRET', 'falimy-dev-secret'),
  jwtExpiresIn: env('JWT_EXPIRES_IN', '30d'),
};
