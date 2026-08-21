const express = require('express');
const UserReminder = require('../models/UserReminder');
const { authRequired } = require('../middleware/auth');

const router = express.Router();
router.use(authRequired);

function asReminder(raw) {
  if (!raw || typeof raw !== 'object') return null;
  const id = String(raw.id || '').trim();
  if (!id) return null;
  return { ...raw, id };
}

router.get('/', async (req, res, next) => {
  try {
    const docs = await UserReminder.find({ ownerUserId: req.userId }).lean();
    res.json({
      reminders: docs.map((doc) => doc.reminder).filter(Boolean),
    });
  } catch (err) {
    next(err);
  }
});

router.put('/', async (req, res, next) => {
  try {
    const list = Array.isArray(req.body?.reminders) ? req.body.reminders : [];
    for (const item of list) {
      const reminder = asReminder(item);
      if (!reminder) continue;
      await UserReminder.findOneAndUpdate(
        { ownerUserId: req.userId, reminderId: reminder.id },
        { ownerUserId: req.userId, reminderId: reminder.id, reminder },
        { upsert: true, setDefaultsOnInsert: true },
      );
    }
    const docs = await UserReminder.find({ ownerUserId: req.userId }).lean();
    res.json({ reminders: docs.map((doc) => doc.reminder).filter(Boolean) });
  } catch (err) {
    next(err);
  }
});

router.put('/:reminderId', async (req, res, next) => {
  try {
    const reminder = asReminder({
      ...(req.body?.reminder || req.body || {}),
      id: req.params.reminderId,
    });
    if (!reminder) {
      return res.status(400).json({ message: 'reminder payload is required' });
    }
    const doc = await UserReminder.findOneAndUpdate(
      { ownerUserId: req.userId, reminderId: reminder.id },
      { ownerUserId: req.userId, reminderId: reminder.id, reminder },
      { upsert: true, new: true, setDefaultsOnInsert: true },
    ).lean();
    res.json({ reminder: doc.reminder });
  } catch (err) {
    next(err);
  }
});

router.delete('/:reminderId', async (req, res, next) => {
  try {
    await UserReminder.deleteOne({
      ownerUserId: req.userId,
      reminderId: req.params.reminderId,
    });
    res.status(204).send();
  } catch (err) {
    next(err);
  }
});

module.exports = router;
