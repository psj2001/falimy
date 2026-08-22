const express = require('express');
const cors = require('cors');
const morgan = require('morgan');

const { port } = require('./config');
const { connectDb } = require('./db');
const { ensureAdmin } = require('./services/ensureAdmin');
const authRoutes = require('./routes/auth');
const profileRoutes = require('./routes/profile');
const inviteRoutes = require('./routes/invites');
const financialRoutes = require('./routes/financial');
const notificationRoutes = require('./routes/notifications');
const budgetRoutes = require('./routes/budget');
const familyRoutes = require('./routes/families');
const assetRoutes = require('./routes/assets');
const reminderRoutes = require('./routes/reminders');
const adminRoutes = require('./routes/admin');

async function main() {
  await connectDb();
  await ensureAdmin();

  const app = express();
  app.use(cors());
  app.use(express.json({ limit: '2mb' }));
  app.use(morgan('dev'));

  app.get('/health', (_req, res) => {
    res.json({ ok: true, service: 'falimy-api' });
  });

  app.use('/api/auth', authRoutes);
  app.use('/api/profile', profileRoutes);
  app.use('/api/invites', inviteRoutes);
  app.use('/api/financial', financialRoutes);
  app.use('/api/notifications', notificationRoutes);
  app.use('/api/budget', budgetRoutes);
  app.use('/api/families', familyRoutes);
  app.use('/api/assets', assetRoutes);
  app.use('/api/reminders', reminderRoutes);
  app.use('/api/admin', adminRoutes);

  app.use((err, _req, res, _next) => {
    console.error(err);
    res.status(500).json({ message: 'Unexpected server error' });
  });

  app.listen(port, '0.0.0.0', () => {
    console.log(`Falimy API listening on http://0.0.0.0:${port}`);
  });
}

main().catch((err) => {
  console.error('Failed to start server', err);
  process.exit(1);
});
