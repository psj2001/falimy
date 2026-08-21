const User = require('../models/User');

function escapeRegex(value) {
  return String(value).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function normalizeName(value) {
  return String(value || '')
    .trim()
    .toLowerCase();
}

function isRemotePhoto(value) {
  const path = String(value || '').trim();
  return path.startsWith('https://') || path.startsWith('http://');
}

function remotePhoto(value) {
  const path = String(value || '').trim();
  return isRemotePhoto(path) ? path : null;
}

function asPlain(value) {
  if (value == null) return {};
  if (typeof value.toObject === 'function') return value.toObject();
  if (typeof value.toJSON === 'function' && value.constructor?.name !== 'Object') {
    try {
      return value.toJSON();
    } catch (_) {
      // Fall through to a shallow copy.
    }
  }
  return { ...value };
}

function namesMatch(left, right) {
  const a = normalizeName(left);
  const b = normalizeName(right);
  if (!a || !b) return false;
  if (a === b) return true;
  const aFirst = a.split(/\s+/)[0];
  const bFirst = b.split(/\s+/)[0];
  return aFirst.length >= 4 && aFirst === bFirst;
}

function collectSlotNames(profile) {
  const names = [];
  const add = (memberKey, name, kind, role) => {
    const clean = String(name || '').trim();
    if (!clean) return;
    names.push({ memberKey, name: clean, kind, role });
  };

  add('father', profile.fatherName, 'father', 'Father');
  add('mother', profile.motherName, 'mother', 'Mother');
  add('spouse', profile.spouse?.name, 'spouse', 'Spouse');

  (profile.siblings || []).forEach((sibling, index) => {
    add(`sibling_${index}`, sibling?.name, 'sibling', 'Sibling');
  });
  (profile.children || []).forEach((child, index) => {
    add(`child_${index}`, child?.name, 'child', 'Child');
  });

  return names;
}

function findFamilyMatch(name, familyUsers, usedIds) {
  const exact = familyUsers.filter(
    (user) =>
      !usedIds.has(user._id.toString()) &&
      normalizeName(user.fullName) === normalizeName(name),
  );
  if (exact.length === 1) return exact[0];
  if (exact.length > 1) {
    return exact.find((user) => remotePhoto(user.photoPath)) || exact[0];
  }

  const fuzzy = familyUsers.filter(
    (user) =>
      !usedIds.has(user._id.toString()) && namesMatch(user.fullName, name),
  );
  if (fuzzy.length === 1) return fuzzy[0];
  return null;
}

/**
 * Attach live account photos to family-tree slots so other devices can render
 * Cloudinary URLs instead of device-local file paths.
 */
async function hydrateProfile(user) {
  if (!user) return null;

  try {
    const profile = user.toProfile();
    const rawLinks = profile.memberLinks || {};
    const links = {};
    for (const [key, value] of Object.entries(rawLinks)) {
      links[key] = asPlain(value);
    }

    const slots = collectSlotNames(profile);
    const linkedIds = Object.values(links)
      .map((link) => String(link?.userId || '').trim())
      .filter(Boolean);

    const familyName = String(profile.familyName || '').trim();
    const queries = [];

    if (linkedIds.length) {
      queries.push(
        User.find({ _id: { $in: linkedIds } }).select(
          'fullName photoPath email familyName',
        ),
      );
    } else {
      queries.push(Promise.resolve([]));
    }

    if (familyName) {
      queries.push(
        User.find({
          _id: { $ne: user._id },
          familyName: new RegExp(`^${escapeRegex(familyName)}$`, 'i'),
          onboardingComplete: true,
        }).select('fullName photoPath email familyName'),
      );
    } else {
      queries.push(Promise.resolve([]));
    }

    const [linkedUsers, familyUsers] = await Promise.all(queries);
    const byId = new Map(
      linkedUsers.map((linked) => [linked._id.toString(), linked]),
    );
    const usedIds = new Set([user._id.toString()]);

    const applyPerson = (memberKey, person, fallback = {}) => {
      if (!person && !fallback.userId) return;
      const id = person?._id?.toString() || String(fallback.userId || '');
      if (id) usedIds.add(id);
      links[memberKey] = {
        ...fallback,
        userId: id || fallback.userId,
        name: person?.fullName || fallback.name || '',
        kind: fallback.kind || '',
        role: fallback.role || '',
        email: person?.email || fallback.email || '',
        photoPath: remotePhoto(person?.photoPath) || remotePhoto(fallback.photoPath),
        joined: Boolean(person),
      };
    };

    for (const slot of slots) {
      const existing = links[slot.memberKey] || {};
      const linked = byId.get(String(existing.userId || ''));
      if (linked) {
        applyPerson(slot.memberKey, linked, { ...existing, ...slot });
        continue;
      }
      const matched = findFamilyMatch(slot.name, familyUsers, usedIds);
      applyPerson(slot.memberKey, matched, { ...existing, ...slot });
    }

    // Keep leftover invite links that did not map onto a named slot.
    const drop = [];
    for (const [memberKey, existing] of Object.entries(links)) {
      if (existing?.photoPath && !isRemotePhoto(existing.photoPath)) {
        const linked = byId.get(String(existing.userId || ''));
        existing.photoPath = remotePhoto(linked?.photoPath);
      }
      if (!existing?.userId) drop.push(memberKey);
    }
    for (const memberKey of drop) {
      delete links[memberKey];
    }

    profile.memberLinks = links;
    return profile;
  } catch (err) {
    console.error('hydrateProfile', err);
    return user.toProfile();
  }
}

module.exports = {
  hydrateProfile,
  isRemotePhoto,
  remotePhoto,
};
