const bcrypt = require('bcryptjs');
const User = require('../models/User');
const config = require('../config');

async function ensureAdmin() {
  const email = String(config.adminEmail || '').trim().toLowerCase();
  const password = String(config.adminPassword || '');
  if (!email || !email.includes('@') || password.length < 6) {
    console.warn('Admin seed skipped: set ADMIN_EMAIL and ADMIN_PASSWORD');
    return;
  }

  const passwordHash = await bcrypt.hash(password, 10);
  await User.findOneAndUpdate(
    { email },
    {
      $set: {
        email,
        passwordHash,
        role: 'admin',
        fullName: 'Falimy Admin',
        onboardingComplete: true,
      },
    },
    { upsert: true, new: true, setDefaultsOnInsert: true },
  );
  console.log(`Admin account ready: ${email}`);
}

module.exports = { ensureAdmin };
