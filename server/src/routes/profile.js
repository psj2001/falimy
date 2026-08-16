const express = require('express');
const User = require('../models/User');
const { authRequired } = require('../middleware/auth');

const router = express.Router();

router.get('/', authRequired, async (req, res) => {
  try {
    const user = await User.findById(req.userId);
    if (!user) {
      return res.status(404).json({ message: 'Profile not found' });
    }
    return res.json({ profile: user.toProfile() });
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
