const jwt = require('jsonwebtoken');
const { jwtSecret, jwtExpiresIn } = require('../config');

function signToken(user) {
  return jwt.sign(
    { sub: user._id.toString(), email: user.email },
    jwtSecret,
    { expiresIn: jwtExpiresIn },
  );
}

function authRequired(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) {
    return res.status(401).json({ message: 'Sign in required' });
  }
  try {
    const payload = jwt.verify(token, jwtSecret);
    req.userId = payload.sub;
    req.userEmail = payload.email;
    return next();
  } catch (_) {
    return res.status(401).json({ message: 'Session expired. Sign in again.' });
  }
}

module.exports = { signToken, authRequired };
