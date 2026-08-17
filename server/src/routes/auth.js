const crypto = require('crypto');
const express = require('express');
const bcrypt = require('bcryptjs');
const User = require('../models/User');
const PendingSignup = require('../models/PendingSignup');
const Invite = require('../models/Invite');
const Notification = require('../models/Notification');
const { signToken, authRequired } = require('../middleware/auth');
const { sendSignupOtp, isMailConfigured } = require('../services/mail');
const { normalizeReferralCode } = require('../utils/referral');
const { reciprocalMemberLinks } = require('../utils/familyLinks');
const config = require('../config');

const router = express.Router();

const OTP_TTL_MS = 10 * 60 * 1000;
const OTP_MAX_ATTEMPTS = 5;

function normalizeEmail(email) {
  return String(email || '').trim().toLowerCase();
}

function generateOtp() {
  return String(crypto.randomInt(100000, 1000000));
}

async function hashOtp(otp) {
  return bcrypt.hash(otp, 10);
}

function shouldExposeDevOtp() {
  return config.mailDevExposeOtp || !isMailConfigured();
}

async function issuePendingSignup({ email, passwordHash, referralCode }) {
  const otp = generateOtp();
  const otpHash = await hashOtp(otp);
  const otpExpiresAt = new Date(Date.now() + OTP_TTL_MS);

  await PendingSignup.findOneAndUpdate(
    { email },
    {
      email,
      passwordHash,
      otpHash,
      otpExpiresAt,
      otpAttempts: 0,
      referralCode: referralCode || null,
    },
    { upsert: true, new: true, setDefaultsOnInsert: true },
  );

  const mail = await sendSignupOtp({ to: email, otp });

  const payload = {
    needsVerification: true,
    email,
    message: mail.delivered
      ? 'We sent a verification code to your email'
      : 'Verification code created. Check server logs if email was not delivered.',
    emailDelivered: mail.delivered,
  };

  if (shouldExposeDevOtp()) {
    payload.devOtp = otp;
  }

  return payload;
}

function spouseFromInviterTree(invite, inviter) {
  if (!inviter) return null;
  const familyName = inviter.familyName || invite.familyName || '';
  const kind = String(invite.memberKind || '').toLowerCase();

  // Son invites father → spouse is mother on the son's tree.
  if (kind === 'father' && inviter.motherName) {
    return {
      name: String(inviter.motherName).trim(),
      profession: '',
      age: 0,
      familyName: String(familyName).trim(),
      relationLabel: 'Mother',
    };
  }

  // Son invites mother → spouse is father on the son's tree.
  if (kind === 'mother' && inviter.fatherName) {
    return {
      name: String(inviter.fatherName).trim(),
      profession: '',
      age: 0,
      familyName: String(familyName).trim(),
      relationLabel: 'Father',
    };
  }

  return null;
}

function ageFromDateOfBirth(dateOfBirth) {
  if (!dateOfBirth) return 0;
  const dob = new Date(dateOfBirth);
  if (Number.isNaN(dob.getTime())) return 0;
  const now = new Date();
  let age = now.getUTCFullYear() - dob.getUTCFullYear();
  const beforeBirthday =
    now.getUTCMonth() < dob.getUTCMonth() ||
    (now.getUTCMonth() === dob.getUTCMonth() &&
      now.getUTCDate() < dob.getUTCDate());
  if (beforeBirthday) age -= 1;
  return Math.max(0, age);
}

function childrenFromInviterTree(invite, inviter) {
  if (!inviter) return [];
  const kind = String(invite.memberKind || '').toLowerCase();
  if (kind !== 'father' && kind !== 'mother') return [];

  const children = [];
  const seen = new Set();
  const addChild = (name, age = 0) => {
    const cleanName = String(name || '').trim();
    const key = cleanName.toLowerCase();
    if (!cleanName || seen.has(key)) return;
    seen.add(key);
    children.push({ name: cleanName, age });
  };

  addChild(
    inviter.fullName || invite.inviterName,
    ageFromDateOfBirth(inviter.dateOfBirth),
  );
  for (const sibling of inviter.siblings || []) {
    addChild(sibling.name);
  }
  return children;
}

async function claimInvite(user, invite) {
  const email = normalizeEmail(user.email);
  invite.status = 'accepted';
  invite.acceptedUserId = user._id;
  invite.acceptedAt = new Date();
  await invite.save();

  const inviter = await User.findById(invite.inviterUserId);

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

  const spouseSuggestion = spouseFromInviterTree(invite, inviter);
  const childrenSuggestion = childrenFromInviterTree(invite, inviter);

  const linkMeta = {
    inviteId: invite._id.toString(),
    inviterUserId: invite.inviterUserId.toString(),
    inviterName: invite.inviterName || (inviter && inviter.fullName) || '',
    memberKey: invite.memberKey,
    memberName: invite.memberName,
    memberKind: invite.memberKind,
    memberRole: invite.memberRole,
    familyName: invite.familyName || null,
    spouseSuggestionName: spouseSuggestion?.name || null,
    spouseSuggestionRole: spouseSuggestion?.relationLabel || null,
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
  if (spouseSuggestion?.name && !(user.spouse && user.spouse.name)) {
    updates.$set = {
      ...(updates.$set || {}),
      spouse: {
        name: spouseSuggestion.name,
        profession: spouseSuggestion.profession,
        age: spouseSuggestion.age,
        familyName: spouseSuggestion.familyName,
      },
    };
  }
  if (childrenSuggestion.length && !(user.children && user.children.length)) {
    updates.$set = {
      ...(updates.$set || {}),
      hasChildren: true,
      children: childrenSuggestion,
    };
  }

  await User.findByIdAndUpdate(user._id, updates);
  if (!user.fullName && invite.memberName) {
    user.fullName = invite.memberName;
  }
  if (!user.familyName && invite.familyName) {
    user.familyName = invite.familyName;
  }
  if (spouseSuggestion?.name && !(user.spouse && user.spouse.name)) {
    user.spouse = {
      name: spouseSuggestion.name,
      profession: spouseSuggestion.profession,
      age: spouseSuggestion.age,
      familyName: spouseSuggestion.familyName,
    };
  }
  if (childrenSuggestion.length && !(user.children && user.children.length)) {
    user.hasChildren = true;
    user.children = childrenSuggestion;
  }

  const reciprocal = reciprocalMemberLinks({ user, link: invite, inviter });
  if (Object.keys(reciprocal).length) {
    const reciprocalSet = {};
    for (const [memberKey, value] of Object.entries(reciprocal)) {
      reciprocalSet[`memberLinks.${memberKey}`] = value;
    }
    await User.findByIdAndUpdate(user._id, { $set: reciprocalSet });
  }

  await Promise.all([
    Notification.create({
      recipientUserId: user._id,
      type: 'family_linked',
      title: 'Joined a family tree',
      message: `You are now linked as ${invite.memberRole} in ${
        invite.inviterName || inviter?.fullName || 'your family member'
      }'s tree.`,
      eventKey: `joined_tree:${invite._id}:${user._id}`,
      data: {
        inviteId: invite._id.toString(),
        inviterUserId: invite.inviterUserId.toString(),
        memberKey: invite.memberKey,
        memberRole: invite.memberRole,
        event: 'joined_tree',
      },
    }),
    Notification.create({
      recipientUserId: invite.inviterUserId,
      type: 'family_linked',
      title: 'Family member joined',
      message: `${user.fullName || invite.memberName} joined your family tree as ${invite.memberRole}.`,
      eventKey: `member_joined:${invite._id}:${invite.inviterUserId}`,
      data: {
        inviteId: invite._id.toString(),
        joinedUserId: user._id.toString(),
        memberKey: invite.memberKey,
        memberRole: invite.memberRole,
        event: 'member_joined',
      },
    }),
  ]);

  return {
    id: invite._id.toString(),
    inviteeEmail: invite.inviteeEmail,
    inviterUserId: invite.inviterUserId.toString(),
    inviterName: invite.inviterName || (inviter && inviter.fullName) || '',
    memberKey: invite.memberKey,
    memberName: invite.memberName,
    memberKind: invite.memberKind,
    memberRole: invite.memberRole,
    familyName: invite.familyName || null,
    referralCode: invite.referralCode || null,
    spouseSuggestionName: spouseSuggestion?.name || null,
    spouseSuggestionRole: spouseSuggestion?.relationLabel || null,
    status: 'accepted',
    acceptedUserId: user._id.toString(),
  };
}

async function claimPendingInvites(user, referralCode) {
  const email = normalizeEmail(user.email);
  const claimed = [];
  const claimedIds = new Set();

  const code = normalizeReferralCode(referralCode);
  if (code) {
    const byCode = await Invite.findOne({
      referralCode: code,
      status: 'pending',
    });
    if (byCode) {
      if (normalizeEmail(byCode.inviteeEmail) !== email) {
        throw Object.assign(new Error('Referral email mismatch'), {
          statusCode: 400,
          publicMessage:
            'This referral code was sent to a different email address',
        });
      }
      claimed.push(await claimInvite(user, byCode));
      claimedIds.add(byCode._id.toString());
    }
  }

  const pending = await Invite.find({
    inviteeEmail: email,
    status: 'pending',
  });

  for (const invite of pending) {
    if (claimedIds.has(invite._id.toString())) continue;
    claimed.push(await claimInvite(user, invite));
  }

  return claimed;
}

async function validateReferralForSignup(email, referralCode) {
  const code = normalizeReferralCode(referralCode);
  if (!code) return null;

  const invite = await Invite.findOne({
    referralCode: code,
    status: 'pending',
  });
  if (!invite) {
    const error = new Error('Invalid or already used referral code');
    error.statusCode = 400;
    error.publicMessage = 'Invalid or already used referral code';
    throw error;
  }
  if (normalizeEmail(invite.inviteeEmail) !== email) {
    const error = new Error('Referral email mismatch');
    error.statusCode = 400;
    error.publicMessage =
      'This referral code was sent to a different email address';
    throw error;
  }
  return code;
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

    let referralCode;
    try {
      referralCode = await validateReferralForSignup(
        email,
        req.body.referralCode,
      );
    } catch (err) {
      if (err.statusCode) {
        return res.status(err.statusCode).json({
          message: err.publicMessage || err.message,
        });
      }
      throw err;
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const payload = await issuePendingSignup({
      email,
      passwordHash,
      referralCode,
    });
    return res.status(201).json(payload);
  } catch (err) {
    console.error('sign-up', err);
    return res.status(500).json({ message: 'Sign up failed' });
  }
});

router.post('/verify-email', async (req, res) => {
  try {
    const email = normalizeEmail(req.body.email);
    const otp = String(req.body.otp || '').trim();

    if (!email || !email.includes('@')) {
      return res.status(400).json({ message: 'Enter a valid email address' });
    }
    if (!/^\d{6}$/.test(otp)) {
      return res.status(400).json({ message: 'Enter the 6-digit code from your email' });
    }

    const pending = await PendingSignup.findOne({ email });
    if (!pending) {
      return res.status(404).json({
        message: 'No pending signup found. Please sign up again.',
      });
    }

    if (pending.otpAttempts >= OTP_MAX_ATTEMPTS) {
      return res.status(429).json({
        message: 'Too many attempts. Request a new code and try again.',
      });
    }

    if (pending.otpExpiresAt.getTime() < Date.now()) {
      return res.status(400).json({
        message: 'Code expired. Request a new one.',
      });
    }

    const match = await bcrypt.compare(otp, pending.otpHash);
    if (!match) {
      pending.otpAttempts += 1;
      await pending.save();
      return res.status(400).json({ message: 'Incorrect verification code' });
    }

    const existing = await User.findOne({ email });
    if (existing) {
      await PendingSignup.deleteOne({ _id: pending._id });
      return res
        .status(409)
        .json({ message: 'An account already exists for this email' });
    }

    const user = await User.create({
      email,
      passwordHash: pending.passwordHash,
    });
    await PendingSignup.deleteOne({ _id: pending._id });

    const claimedInvites = await claimPendingInvites(
      user,
      pending.referralCode,
    );
    const fresh = await User.findById(user._id);

    return res.status(201).json({
      token: signToken(fresh),
      user: fresh.toPublic(),
      profile: fresh.toProfile(),
      claimedInvites,
    });
  } catch (err) {
    if (err.statusCode) {
      return res.status(err.statusCode).json({
        message: err.publicMessage || err.message,
      });
    }
    console.error('verify-email', err);
    return res.status(500).json({ message: 'Email verification failed' });
  }
});

router.post('/resend-otp', async (req, res) => {
  try {
    const email = normalizeEmail(req.body.email);

    if (!email || !email.includes('@')) {
      return res.status(400).json({ message: 'Enter a valid email address' });
    }

    const existing = await User.findOne({ email });
    if (existing) {
      return res
        .status(409)
        .json({ message: 'An account already exists for this email' });
    }

    const pending = await PendingSignup.findOne({ email });
    if (!pending) {
      return res.status(404).json({
        message: 'No pending signup found. Please sign up again.',
      });
    }

    const otp = generateOtp();
    pending.otpHash = await hashOtp(otp);
    pending.otpExpiresAt = new Date(Date.now() + OTP_TTL_MS);
    pending.otpAttempts = 0;
    await pending.save();

    const mail = await sendSignupOtp({ to: email, otp });

    const payload = {
      needsVerification: true,
      email,
      message: mail.delivered
        ? 'We sent a new verification code to your email'
        : 'New verification code created. Check server logs if email was not delivered.',
      emailDelivered: mail.delivered,
    };

    if (shouldExposeDevOtp()) {
      payload.devOtp = otp;
    }

    return res.json(payload);
  } catch (err) {
    console.error('resend-otp', err);
    return res.status(500).json({ message: 'Failed to resend code' });
  }
});

router.post('/sign-in', async (req, res) => {
  try {
    const email = normalizeEmail(req.body.email);
    const password = String(req.body.password || '');

    const user = await User.findOne({ email });
    if (!user) {
      const pending = await PendingSignup.findOne({ email });
      if (pending) {
        const otp = generateOtp();
        pending.otpHash = await hashOtp(otp);
        pending.otpExpiresAt = new Date(Date.now() + OTP_TTL_MS);
        pending.otpAttempts = 0;
        await pending.save();
        await sendSignupOtp({ to: email, otp });

        const payload = {
          message: 'Verify your email before signing in',
          needsVerification: true,
          email,
        };
        if (shouldExposeDevOtp()) {
          payload.devOtp = otp;
        }
        return res.status(403).json(payload);
      }
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
    if (err.statusCode) {
      return res.status(err.statusCode).json({
        message: err.publicMessage || err.message,
      });
    }
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
