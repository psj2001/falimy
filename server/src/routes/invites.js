const express = require('express');
const User = require('../models/User');
const Invite = require('../models/Invite');
const Notification = require('../models/Notification');
const { authRequired } = require('../middleware/auth');
const { sendFamilyInvite } = require('../services/mail');
const {
  generateReferralCode,
  normalizeReferralCode,
  maskEmail,
} = require('../utils/referral');

const router = express.Router();

function normalizeEmail(email) {
  return String(email || '').trim().toLowerCase();
}

async function createInviteWithCode(fields) {
  for (let attempt = 0; attempt < 6; attempt += 1) {
    try {
      return await Invite.create({
        ...fields,
        referralCode: generateReferralCode(),
      });
    } catch (err) {
      if (err && err.code === 11000 && attempt < 5) {
        continue;
      }
      throw err;
    }
  }
  throw new Error('Could not allocate a unique referral code');
}

router.get('/referral/:code', async (req, res) => {
  try {
    const code = normalizeReferralCode(req.params.code);
    if (code.length < 6) {
      return res.status(400).json({ message: 'Enter a valid referral code' });
    }

    const invite = await Invite.findOne({
      referralCode: code,
      status: 'pending',
    });
    if (!invite) {
      return res.status(404).json({
        message: 'Invalid or already used referral code',
      });
    }

    return res.json({
      inviterName: invite.inviterName || '',
      memberName: invite.memberName,
      memberRole: invite.memberRole,
      memberKind: invite.memberKind,
      familyName: invite.familyName || null,
      inviteeEmailHint: maskEmail(invite.inviteeEmail),
    });
  } catch (err) {
    console.error('resolve referral', err);
    return res.status(500).json({ message: 'Failed to look up referral code' });
  }
});

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

    const invite = await createInviteWithCode({
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

    const existingInvitee = await User.findOne({ email: inviteeEmail }).select(
      '_id',
    );
    if (existingInvitee) {
      await Notification.create({
        recipientUserId: existingInvitee._id,
        type: 'family_invite',
        title: 'Family invitation',
        message: `${invite.inviterName} invited you to join their family tree as ${invite.memberRole}.`,
        eventKey: `family_invite:${invite._id}:${existingInvitee._id}`,
        data: {
          inviteId: invite._id.toString(),
          inviterUserId: inviter._id.toString(),
          memberKey: invite.memberKey,
          memberRole: invite.memberRole,
          referralCode: invite.referralCode,
        },
      });
    }

    const mail = await sendFamilyInvite({
      to: inviteeEmail,
      inviterName: invite.inviterName,
      memberName: invite.memberName,
      memberRole: invite.memberRole,
      familyName: invite.familyName,
      referralCode: invite.referralCode,
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
        referralCode: invite.referralCode,
        status: invite.status,
      },
      emailDelivered: mail.delivered === true,
    });
  } catch (err) {
    console.error('send invite', err);
    return res.status(500).json({ message: 'Failed to send invite' });
  }
});

module.exports = router;
