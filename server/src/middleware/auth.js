const jwt = require('jsonwebtoken');
const { jwtSecret, jwtExpiresIn } = require('../config');
const User = require('../models/User');

function signToken(user) {
  return jwt.sign(
    {
      sub: user._id.toString(),
      email: user.email,
      role: user.role || 'user',
    },
    jwtSecret,
    { expiresIn: jwtExpiresIn },
  );
}

function readBearer(req) {
  const header = req.headers.authorization || '';
  return header.startsWith('Bearer ') ? header.slice(7) : null;
}

function authRequired(req, res, next) {
  const token = readBearer(req);
  if (!token) {
    return res.status(401).json({ message: 'Sign in required' });
  }
  try {
    const payload = jwt.verify(token, jwtSecret);
    req.userId = payload.sub;
    req.userEmail = payload.email;
    req.userRole = payload.role || 'user';
    return next();
  } catch (_) {
    return res.status(401).json({ message: 'Session expired. Sign in again.' });
  }
}

async function adminRequired(req, res, next) {
  const token = readBearer(req);
  if (!token) {
    return res.status(401).json({ message: 'Sign in required' });
  }
  try {
    const payload = jwt.verify(token, jwtSecret);
    const user = await User.findById(payload.sub);
    if (!user || user.role !== 'admin') {
      return res.status(403).json({ message: 'Admin access required' });
    }
    req.userId = user._id.toString();
    req.userEmail = user.email;
    req.userRole = 'admin';
    req.adminUser = user;
    return next();
  } catch (_) {
    return res.status(401).json({ message: 'Session expired. Sign in again.' });
  }
}

module.exports = { signToken, authRequired, adminRequired };
