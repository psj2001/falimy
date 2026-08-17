const express = require('express');
const User = require('../models/User');
const { authRequired } = require('../middleware/auth');
const { reciprocalMemberLinks } = require('../utils/familyLinks');

const router = express.Router();

function spouseFromInviterTree(link, inviter) {
  if (!link || !inviter) return null;
  const familyName = inviter.familyName || link.familyName || '';
  const kind = String(link.memberKind || '').toLowerCase();

  if (kind === 'father' && inviter.motherName) {
    return {
      name: String(inviter.motherName).trim(),
      profession: '',
      age: 0,
      familyName: String(familyName).trim(),
      relationLabel: 'Mother',
    };
  }
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

function childrenFromInviterTree(link, inviter) {
  if (!link || !inviter) return [];
  const kind = String(link.memberKind || '').toLowerCase();
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

  addChild(inviter.fullName, ageFromDateOfBirth(inviter.dateOfBirth));
  for (const sibling of inviter.siblings || []) {
    addChild(sibling.name);
  }
  return children;
}

async function ensureFamilyFromLinkedInvite(user) {
  const links = user.linkedFromInvites || [];
  if (!links.length) return user;

  const link = links[0];
  const inviter = await User.findById(link.inviterUserId);
  if (!inviter) return user;

  const updates = {};
  if (!(user.spouse && user.spouse.name)) {
    const spouseSuggestion = spouseFromInviterTree(link, inviter);
    if (spouseSuggestion?.name) {
      updates.spouse = {
        name: spouseSuggestion.name,
        profession: spouseSuggestion.profession,
        age: spouseSuggestion.age,
        familyName: spouseSuggestion.familyName,
      };
      updates['linkedFromInvites.0.spouseSuggestionName'] =
        spouseSuggestion.name;
      updates['linkedFromInvites.0.spouseSuggestionRole'] =
        spouseSuggestion.relationLabel;
    }
  }

  if (!(user.children && user.children.length)) {
    const childrenSuggestion = childrenFromInviterTree(link, inviter);
    if (childrenSuggestion.length) {
      updates.hasChildren = true;
      updates.children = childrenSuggestion;
    }
  }

  if (!Object.keys(updates).length) return user;
  const fresh = await User.findByIdAndUpdate(
    user._id,
    { $set: updates },
    { new: true },
  );
  return fresh || user;
}

async function ensureReciprocalLinks(user) {
  const links = user.linkedFromInvites || [];
  if (!links.length) return user;

  const updates = {};
  for (const link of links) {
    const inviter = await User.findById(link.inviterUserId);
    if (!inviter) continue;

    const reciprocal = reciprocalMemberLinks({ user, link, inviter });
    for (const [memberKey, value] of Object.entries(reciprocal)) {
      const existing = user.memberLinks?.get?.(memberKey);
      if (existing && existing.userId) continue;
      updates[`memberLinks.${memberKey}`] = value;
    }
  }

  if (!Object.keys(updates).length) return user;
  const fresh = await User.findByIdAndUpdate(
    user._id,
    { $set: updates },
    { new: true },
  );
  return fresh || user;
}

async function profileWithLinkedMembers(user) {
  const profile = user.toProfile();
  const links = profile.memberLinks || {};
  const userIds = Object.values(links)
    .map((link) => link?.userId)
    .filter(Boolean);
  if (!userIds.length) return profile;

  const linkedUsers = await User.find({ _id: { $in: userIds } }).select(
    'fullName photoPath email',
  );
  const byId = new Map(
    linkedUsers.map((linked) => [linked._id.toString(), linked]),
  );

  for (const [memberKey, value] of Object.entries(links)) {
    const raw =
      value && typeof value.toObject === 'function' ? value.toObject() : value;
    const linked = byId.get(String(raw?.userId || ''));
    links[memberKey] = {
      ...raw,
      name: linked?.fullName || raw?.name || '',
      email: linked?.email || raw?.email || '',
      photoPath: linked?.photoPath || null,
      joined: Boolean(linked),
    };
  }
  profile.memberLinks = links;
  return profile;
}

router.get('/', authRequired, async (req, res) => {
  try {
    let user = await User.findById(req.userId);
    if (!user) {
      return res.status(404).json({ message: 'Profile not found' });
    }
    user = await ensureFamilyFromLinkedInvite(user);
    user = await ensureReciprocalLinks(user);
    return res.json({ profile: await profileWithLinkedMembers(user) });
  } catch (err) {
    console.error('get profile', err);
    return res.status(500).json({ message: 'Failed to load profile' });
  }
});

router.put('/', authRequired, async (req, res) => {
  try {
    const body = req.body || {};
    const updates = {
      fullName: body.fullName ?? null,
      dateOfBirth: body.dateOfBirth ? new Date(body.dateOfBirth) : null,
      familyName: body.familyName ?? null,
      photoPath: body.photoPath ?? null,
      fatherName: body.fatherName ?? null,
      motherName: body.motherName ?? null,
      siblings: Array.isArray(body.siblings) ? body.siblings : [],
      isMarried: body.isMarried ?? null,
      spouse: body.spouse ?? null,
      hasChildren: body.hasChildren ?? null,
      children: Array.isArray(body.children) ? body.children : [],
      onboardingComplete: Boolean(body.onboardingComplete),
      occupationStatus: body.occupationStatus ?? null,
      companyName: body.companyName ?? null,
      salary: body.salary != null ? Number(body.salary) : null,
      studyClassOrCourse: body.studyClassOrCourse ?? null,
    };

    const user = await User.findByIdAndUpdate(
      req.userId,
      { $set: updates },
      { new: true },
    );

    if (!user) {
      return res.status(404).json({ message: 'Profile not found' });
    }

    return res.json({ profile: user.toProfile() });
  } catch (err) {
    console.error('save profile', err);
    return res.status(500).json({ message: 'Failed to save profile' });
  }
});

router.delete('/', authRequired, async (req, res) => {
  try {
    await User.findByIdAndUpdate(req.userId, {
      $unset: {
        fullName: 1,
        dateOfBirth: 1,
        familyName: 1,
        photoPath: 1,
        fatherName: 1,
        motherName: 1,
        spouse: 1,
        isMarried: 1,
        hasChildren: 1,
        occupationStatus: 1,
        companyName: 1,
        salary: 1,
        studyClassOrCourse: 1,
      },
      $set: {
        siblings: [],
        children: [],
        onboardingComplete: false,
      },
    });
    return res.status(204).send();
  } catch (err) {
    console.error('clear profile', err);
    return res.status(500).json({ message: 'Failed to clear profile' });
  }
});

module.exports = router;
