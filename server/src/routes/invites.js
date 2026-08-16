const express = require('express');
const User = require('../models/User');
const Invite = require('../models/Invite');
const { authRequired } = require('../middleware/auth');

const router = express.Router();

function normalizeEmail(email) {
  return String(email || '').trim().toLowerCase();
}

router.post('/', authRequired, async (req, res) => {
  try {
    const inviteeEmail = normalizeEmail(req.body.inviteeEmail);
    const memberKey = String(req.body.memberKey || '').trim();
    const memberName = String(req.body.memberName || '').trim();
    const memberKind = String(req.body.memberKind || '').trim();
    const memberRole = String(req.body.memberRole || '').trim();
    const familyName = req.body.familyName
      ? String(req.body.familyName).trim()
      : null;

    if (!inviteeEmail.includes('@')) {
      return res.status(400).json({ message: 'Enter a valid email address' });
    }
    if (!memberKey || !memberName || !memberKind || !memberRole) {
      return res.status(400).json({ message: 'Missing member details' });
    }

    const inviter = await User.findById(req.userId);
    if (!inviter) {
      return res.status(401).json({ message: 'Sign in required' });
    }

    if (inviteeEmail === normalizeEmail(inviter.email)) {
      return res
        .status(400)
        .json({ message: 'You cannot invite your own email address.' });
    }

    const invite = await Invite.create({
      inviteeEmail,
      inviterUserId: inviter._id,
      inviterName: inviter.fullName || inviter.email,
      memberKey,
      memberName,
      memberKind,
      memberRole,
      familyName,
      status: 'pending',
    });

    return res.status(201).json({
      invite: {
        id: invite._id.toString(),
        inviteeEmail: invite.inviteeEmail,
        inviterUserId: inviter._id.toString(),
        inviterName: invite.inviterName,
        memberKey: invite.memberKey,
        memberName: invite.memberName,
        memberKind: invite.memberKind,
        memberRole: invite.memberRole,
        familyName: invite.familyName,
        status: invite.status,
      },
      emailDelivered: false,
    });
  } catch (err) {
    console.error('send invite', err);
    return res.status(500).json({ message: 'Failed to send invite' });
  }
});

module.exports = router;
