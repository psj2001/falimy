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
  jwtExpiresIn: env('JWT_EXPIRES_IN', '365d'),

  // Free SMTP (Gmail App Password, Brevo, Mailjet, etc.)
  smtpHost: env('SMTP_HOST', 'smtp.gmail.com'),
  smtpPort: Number(env('SMTP_PORT', '587')),
  smtpSecure:
    String(env('SMTP_SECURE')).toLowerCase() === 'true' ||
    env('SMTP_SECURE') === '1',
  smtpUser: env('SMTP_USER'),
  smtpPass: env('SMTP_PASS'),
  mailFrom: env('MAIL_FROM', env('SMTP_USER', 'Falimy <noreply@falimy.app>')),
  // When true (or SMTP unset), include OTP in API JSON for local testing
  mailDevExposeOtp:
    String(env('MAIL_DEV_EXPOSE_OTP')).toLowerCase() === 'true' ||
    env('MAIL_DEV_EXPOSE_OTP') === '1',
};
