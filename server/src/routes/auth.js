const express = require('express');
const bcrypt = require('bcryptjs');
const User = require('../models/User');
const Invite = require('../models/Invite');
const { signToken, authRequired } = require('../middleware/auth');

const router = express.Router();

function normalizeEmail(email) {
  return String(email || '').trim().toLowerCase();
}

async function claimPendingInvites(user) {
  const email = normalizeEmail(user.email);
  const pending = await Invite.find({
    inviteeEmail: email,
    status: 'pending',
  });

  if (!pending.length) return [];

  const claimed = [];

  for (const invite of pending) {
    invite.status = 'accepted';
    invite.acceptedUserId = user._id;
    invite.acceptedAt = new Date();
    await invite.save();

    await User.findByIdAndUpdate(invite.inviterUserId, {
      $set: {
        [`memberLinks.${invite.memberKey}`]: {
          userId: user._id.toString(),
          email,
          name: invite.memberName,
          kind: invite.memberKind,
          role: invite.memberRole,
          linkedAt: new Date(),
        },
      },
    });

    const linkMeta = {
      inviteId: invite._id.toString(),
      inviterUserId: invite.inviterUserId.toString(),
      inviterName: invite.inviterName || '',
      memberKey: invite.memberKey,
      memberName: invite.memberName,
      memberKind: invite.memberKind,
      memberRole: invite.memberRole,
      familyName: invite.familyName || null,
    };

    const updates = {
      $push: { linkedFromInvites: linkMeta },
    };
    if (!user.fullName && invite.memberName) {
      updates.$set = {
        ...(updates.$set || {}),
        fullName: invite.memberName,
      };
    }
    if (!user.familyName && invite.familyName) {
      updates.$set = {
        ...(updates.$set || {}),
        familyName: invite.familyName,
      };
    }

    await User.findByIdAndUpdate(user._id, updates);
    claimed.push({
      id: invite._id.toString(),
      inviteeEmail: invite.inviteeEmail,
      inviterUserId: invite.inviterUserId.toString(),
      inviterName: invite.inviterName || '',
      memberKey: invite.memberKey,
      memberName: invite.memberName,
      memberKind: invite.memberKind,
      memberRole: invite.memberRole,
      familyName: invite.familyName || null,
      status: 'accepted',
      acceptedUserId: user._id.toString(),
    });
  }

  return claimed;
}

router.post('/sign-up', async (req, res) => {
  try {
    const email = normalizeEmail(req.body.email);
    const password = String(req.body.password || '');

    if (!email || !email.includes('@')) {
      return res.status(400).json({ message: 'Enter a valid email address' });
    }
    if (password.length < 6) {
      return res
        .status(400)
        .json({ message: 'Password must be at least 6 characters' });
    }

    const existing = await User.findOne({ email });
    if (existing) {
      return res
        .status(409)
        .json({ message: 'An account already exists for this email' });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const user = await User.create({ email, passwordHash });
    const claimedInvites = await claimPendingInvites(user);
    const fresh = await User.findById(user._id);

    return res.status(201).json({
      token: signToken(fresh),
      user: fresh.toPublic(),
      profile: fresh.toProfile(),
      claimedInvites,
    });
  } catch (err) {
    console.error('sign-up', err);
    return res.status(500).json({ message: 'Sign up failed' });
  }
});

router.post('/sign-in', async (req, res) => {
  try {
    const email = normalizeEmail(req.body.email);
    const password = String(req.body.password || '');

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({ message: 'Incorrect email or password' });
    }

    const ok = await bcrypt.compare(password, user.passwordHash);
    if (!ok) {
      return res.status(401).json({ message: 'Incorrect email or password' });
    }

    const claimedInvites = await claimPendingInvites(user);
    const fresh = await User.findById(user._id);

    return res.json({
      token: signToken(fresh),
      user: fresh.toPublic(),
      profile: fresh.toProfile(),
      claimedInvites,
    });
  } catch (err) {
    console.error('sign-in', err);
    return res.status(500).json({ message: 'Sign in failed' });
  }
});

router.get('/me', authRequired, async (req, res) => {
  try {
    const user = await User.findById(req.userId);
    if (!user) {
      return res.status(401).json({ message: 'User not found' });
    }
    return res.json({
      user: user.toPublic(),
      profile: user.toProfile(),
    });
  } catch (err) {
    console.error('me', err);
    return res.status(500).json({ message: 'Failed to load session' });
  }
});

module.exports = router;
