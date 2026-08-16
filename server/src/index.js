const express = require('express');
const cors = require('cors');
const morgan = require('morgan');

const { port } = require('./config');
const { connectDb } = require('./db');
const authRoutes = require('./routes/auth');
const profileRoutes = require('./routes/profile');
const inviteRoutes = require('./routes/invites');

async function main() {
  await connectDb();

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
