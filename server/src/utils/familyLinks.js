function normalizeName(value) {
  return String(value || '').trim().toLowerCase();
}

/**
 * The invite only links the inviter's tree slot. This maps the inverse:
 * which slot in the invitee's own tree the inviter occupies.
 */
function reciprocalMemberLinks({ user, link, inviter }) {
  if (!user || !link || !inviter) return {};

  const inviterName = String(inviter.fullName || link.inviterName || '').trim();
  if (!inviterName) return {};

  const kind = String(link.memberKind || '').toLowerCase();
  const base = {
    userId: inviter._id.toString(),
    email: inviter.email || '',
    name: inviterName,
    linkedAt: new Date(),
  };

  if (kind === 'father' || kind === 'mother') {
    const index = (user.children || []).findIndex(
      (child) => normalizeName(child.name) === normalizeName(inviterName),
    );
    if (index < 0) return {};
    return {
      [`child_${index}`]: { ...base, kind: 'child', role: 'Child' },
    };
  }

  if (kind === 'spouse') {
    return { spouse: { ...base, kind: 'spouse', role: 'Spouse' } };
  }

  if (kind === 'sibling') {
    const index = (user.siblings || []).findIndex(
      (sibling) => normalizeName(sibling.name) === normalizeName(inviterName),
    );
    if (index < 0) return {};
    return {
      [`sibling_${index}`]: { ...base, kind: 'sibling', role: 'Sibling' },
    };
  }

  if (kind === 'child') {
    if (normalizeName(user.fatherName) === normalizeName(inviterName)) {
      return { father: { ...base, kind: 'father', role: 'Father' } };
    }
    if (normalizeName(user.motherName) === normalizeName(inviterName)) {
      return { mother: { ...base, kind: 'mother', role: 'Mother' } };
    }
  }

  return {};
}

module.exports = { reciprocalMemberLinks };
