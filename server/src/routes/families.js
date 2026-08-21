const express = require('express');
const User = require('../models/User');
const { authRequired } = require('../middleware/auth');

const router = express.Router();

function escapeRegex(value) {
  return String(value).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function cleanName(value) {
  return String(value || '').trim();
}

function asLinks(raw) {
  if (!raw) return {};
  if (typeof raw.get === 'function') {
    return Object.fromEntries(raw.entries());
  }
  return raw;
}

function linkPhoto(link, photosById) {
  const userId = String(link?.userId || '');
  if (!userId) return null;
  const photo = photosById.get(userId);
  if (!photo) return null;
  const path = String(photo || '').trim();
  if (path.startsWith('https://') || path.startsWith('http://')) return path;
  return null;
}

function addPerson(people, { name, photoPath, role }) {
  const clean = cleanName(name);
  if (!clean) return;
  const key = clean.toLowerCase();
  const existing = people.get(key);
  if (!existing) {
    people.set(key, {
      name: clean,
      photoPath: photoPath || null,
      role: role || 'Member',
    });
    return;
  }
  if (!existing.photoPath && photoPath) {
    existing.photoPath = photoPath;
  }
}

function siblingRole(sibling) {
  const isElder = String(sibling?.seniority || '').toLowerCase() === 'elder';
  const isMale = String(sibling?.gender || '').toLowerCase() === 'male';
  if (isMale) return isElder ? 'Elder brother' : 'Younger brother';
  return isElder ? 'Elder sister' : 'Younger sister';
}

function spouseRole(user) {
  const suggestion = String(
    user.linkedFromInvites?.[0]?.spouseSuggestionRole || '',
  ).toLowerCase();
  if (suggestion === 'wife') return 'Wife';
  if (suggestion === 'husband') return 'Husband';
  return 'Spouse';
}

router.get('/search', authRequired, async (req, res) => {
  try {
    const query = String(req.query.q || '').trim();
    if (query.length < 2) {
      return res.json({ families: [] });
    }

    const regex = new RegExp(escapeRegex(query), 'i');
    const users = await User.find({
      familyName: { $regex: regex },
      onboardingComplete: true,
    })
      .select(
        'fullName familyName photoPath fatherName motherName siblings spouse children isMarried memberLinks',
      )
      .limit(80)
      .lean();

    const linkedIds = [];
    for (const user of users) {
      const links = asLinks(user.memberLinks);
      for (const value of Object.values(links)) {
        if (value?.userId) linkedIds.push(String(value.userId));
      }
    }

    const linkedUsers = linkedIds.length
      ? await User.find({ _id: { $in: linkedIds } })
          .select('photoPath')
          .lean()
      : [];
    const photosById = new Map(
      linkedUsers.map((linked) => [
        String(linked._id),
        linked.photoPath || null,
      ]),
    );

    const groups = new Map();
    for (const user of users) {
      const familyName = cleanName(user.familyName);
      if (!familyName) continue;
      const key = familyName.toLowerCase();
      if (!groups.has(key)) {
        groups.set(key, { familyName, people: new Map() });
      }
      const group = groups.get(key);
      if (familyName.length > group.familyName.length) {
        group.familyName = familyName;
      }

      const links = asLinks(user.memberLinks);
      addPerson(group.people, {
        name: user.fullName,
        photoPath: user.photoPath,
        role: 'Member',
      });
      addPerson(group.people, {
        name: user.fatherName,
        photoPath: linkPhoto(links.father, photosById),
        role: 'Father',
      });
      addPerson(group.people, {
        name: user.motherName,
        photoPath: linkPhoto(links.mother, photosById),
        role: 'Mother',
      });

      (user.siblings || []).forEach((sibling, index) => {
        addPerson(group.people, {
          name: sibling.name,
          photoPath: linkPhoto(links[`sibling_${index}`], photosById),
          role: siblingRole(sibling),
        });
      });

      if (user.isMarried && user.spouse) {
        addPerson(group.people, {
          name: user.spouse.name,
          photoPath: linkPhoto(links.spouse, photosById),
          role: spouseRole(user),
        });
      }

      (user.children || []).forEach((child, index) => {
        addPerson(group.people, {
          name: child.name,
          photoPath: linkPhoto(links[`child_${index}`], photosById),
          role: 'Child',
        });
      });
    }

    const needle = query.toLowerCase();
    const families = Array.from(groups.values())
      .map((group) => ({
        familyName: group.familyName,
        personCount: group.people.size,
        members: Array.from(group.people.values()),
      }))
      .sort((a, b) => {
        const aName = a.familyName.toLowerCase();
        const bName = b.familyName.toLowerCase();
        const aExact = aName === needle ? 0 : aName.startsWith(needle) ? 1 : 2;
        const bExact = bName === needle ? 0 : bName.startsWith(needle) ? 1 : 2;
        if (aExact !== bExact) return aExact - bExact;
        return a.familyName.localeCompare(b.familyName);
      })
      .slice(0, 12);

    return res.json({ families });
  } catch (err) {
    console.error('search families', err);
    return res.status(500).json({ message: 'Failed to search families' });
  }
});

module.exports = router;
