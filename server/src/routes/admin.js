const crypto = require('crypto');
const express = require('express');
const bcrypt = require('bcryptjs');
const mongoose = require('mongoose');
const User = require('../models/User');
const Notification = require('../models/Notification');
const Invite = require('../models/Invite');
const UserAsset = require('../models/UserAsset');
const UserReminder = require('../models/UserReminder');
const CloudBook = require('../models/CloudBook');
const Budget = require('../models/Budget');
const { signToken, adminRequired } = require('../middleware/auth');

const router = express.Router();

function escapeRegex(value) {
  return String(value).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function toAdminUser(user) {
  const profile = user.toProfile ? user.toProfile() : {};
  return {
    id: user._id.toString(),
    email: user.email,
    role: user.role || 'user',
    createdAt: user.createdAt,
    updatedAt: user.updatedAt,
    ...profile,
  };
}

function userFilter(q) {
  const filter = { role: { $ne: 'admin' } };
  const term = String(q || '').trim();
  if (!term) return filter;
  const re = new RegExp(escapeRegex(term), 'i');
  filter.$or = [
    { email: re },
    { fullName: re },
    { familyName: re },
    { fatherName: re },
    { motherName: re },
    { companyName: re },
    { occupationStatus: re },
    { 'location.country': re },
    { 'location.state': re },
    { 'location.place': re },
    { 'location.address': re },
  ];
  return filter;
}

router.post('/sign-in', async (req, res) => {
  try {
    const email = String(req.body.email || '')
      .trim()
      .toLowerCase();
    const password = String(req.body.password || '');
    const user = await User.findOne({ email, role: 'admin' });
    if (!user) {
      return res.status(401).json({ message: 'Incorrect email or password' });
    }
    const ok = await bcrypt.compare(password, user.passwordHash);
    if (!ok) {
      return res.status(401).json({ message: 'Incorrect email or password' });
    }
    return res.json({
      token: signToken(user),
      admin: {
        id: user._id.toString(),
        email: user.email,
        fullName: user.fullName || 'Falimy Admin',
      },
    });
  } catch (err) {
    console.error('admin sign-in', err);
    return res.status(500).json({ message: 'Sign in failed' });
  }
});

router.get('/me', adminRequired, async (req, res) => {
  const user = req.adminUser;
  return res.json({
    admin: {
      id: user._id.toString(),
      email: user.email,
      fullName: user.fullName || 'Falimy Admin',
    },
  });
});

router.get('/users', adminRequired, async (req, res) => {
  try {
    const filter = userFilter(req.query.q);
    const [users, total, onboarded, married] = await Promise.all([
      User.find(filter).sort({ createdAt: -1 }),
      User.countDocuments({ role: { $ne: 'admin' } }),
      User.countDocuments({
        role: { $ne: 'admin' },
        onboardingComplete: true,
      }),
      User.countDocuments({ role: { $ne: 'admin' }, isMarried: true }),
    ]);
    return res.json({
      users: users.map(toAdminUser),
      stats: {
        total,
        matched: users.length,
        onboarded,
        married,
      },
    });
  } catch (err) {
    console.error('admin list users', err);
    return res.status(500).json({ message: 'Failed to load users' });
  }
});

router.get('/users/:id', adminRequired, async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({ message: 'Invalid user id' });
    }
    const user = await User.findById(req.params.id);
    if (!user || user.role === 'admin') {
      return res.status(404).json({ message: 'User not found' });
    }

    const [
      assets,
      reminders,
      books,
      budgets,
      invitesSent,
      invitesReceived,
      notifications,
    ] = await Promise.all([
      UserAsset.find({ ownerUserId: user._id }).sort({ updatedAt: -1 }),
      UserReminder.find({ ownerUserId: user._id }).sort({ updatedAt: -1 }),
      CloudBook.find({ ownerUserId: user._id }).sort({ updatedAt: -1 }),
      Budget.find({ ownerUserId: user._id }).sort({ month: -1 }),
      Invite.find({ inviterUserId: user._id }).sort({ createdAt: -1 }),
      Invite.find({ inviteeEmail: user.email }).sort({ createdAt: -1 }),
      Notification.find({ recipientUserId: user._id })
        .sort({ createdAt: -1 })
        .limit(50),
    ]);

    return res.json({
      user: toAdminUser(user),
      assets: assets.map((item) => ({
        id: item._id.toString(),
        assetId: item.assetId,
        asset: item.asset,
        createdAt: item.createdAt,
        updatedAt: item.updatedAt,
      })),
      reminders: reminders.map((item) => ({
        id: item._id.toString(),
        reminderId: item.reminderId,
        reminder: item.reminder,
        createdAt: item.createdAt,
        updatedAt: item.updatedAt,
      })),
      books: books.map((item) => ({
        id: item._id.toString(),
        bookId: item.bookId,
        book: item.book,
        entryCount: Array.isArray(item.entries) ? item.entries.length : 0,
        categoryCount: Array.isArray(item.categories)
          ? item.categories.length
          : 0,
        syncedAt: item.syncedAt,
        createdAt: item.createdAt,
        updatedAt: item.updatedAt,
      })),
      budgets: budgets.map((item) => ({
        id: item._id.toString(),
        month: item.month,
        currency: item.currency,
        savingsTargetPercent: item.savingsTargetPercent,
        incomes: item.incomes,
        categories: item.categories,
        createdAt: item.createdAt,
        updatedAt: item.updatedAt,
      })),
      invitesSent: invitesSent.map((invite) => ({
        id: invite._id.toString(),
        inviteeEmail: invite.inviteeEmail,
        memberName: invite.memberName,
        memberRole: invite.memberRole,
        memberKind: invite.memberKind,
        familyName: invite.familyName,
        status: invite.status,
        referralCode: invite.referralCode,
        acceptedAt: invite.acceptedAt,
        createdAt: invite.createdAt,
      })),
      invitesReceived: invitesReceived.map((invite) => ({
        id: invite._id.toString(),
        inviterName: invite.inviterName,
        memberName: invite.memberName,
        memberRole: invite.memberRole,
        status: invite.status,
        createdAt: invite.createdAt,
      })),
      notifications: notifications.map((item) => ({
        id: item._id.toString(),
        type: item.type,
        title: item.title,
        message: item.message,
        isRead: Boolean(item.readAt),
        createdAt: item.createdAt,
      })),
    });
  } catch (err) {
    console.error('admin user detail', err);
    return res.status(500).json({ message: 'Failed to load user' });
  }
});

router.delete('/users/:id', adminRequired, async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({ message: 'Invalid user id' });
    }

    const user = await User.findById(req.params.id);
    if (!user || user.role === 'admin') {
      return res.status(404).json({ message: 'User not found' });
    }

    const id = user._id.toString();
    const others = await User.find({ _id: { $ne: user._id } }).select(
      'memberLinks',
    );
    const linkCleanups = [];
    for (const other of others) {
      const unset = {};
      const links = other.memberLinks;
      const entries =
        links && typeof links.entries === 'function'
          ? links.entries()
          : Object.entries(links || {});
      for (const [key, value] of entries) {
        if (value && String(value.userId) === id) {
          unset[`memberLinks.${key}`] = 1;
        }
      }
      if (Object.keys(unset).length) {
        linkCleanups.push(
          User.updateOne({ _id: other._id }, { $unset: unset }),
        );
      }
    }

    await Promise.all([
      UserAsset.deleteMany({ ownerUserId: user._id }),
      UserReminder.deleteMany({ ownerUserId: user._id }),
      CloudBook.deleteMany({ ownerUserId: user._id }),
      Budget.deleteMany({ ownerUserId: user._id }),
      Notification.deleteMany({
        $or: [
          { recipientUserId: user._id },
          { 'data.joinedUserId': id },
          { 'data.inviterUserId': id },
        ],
      }),
      Invite.deleteMany({
        $or: [
          { inviterUserId: user._id },
          { acceptedUserId: user._id },
          { inviteeEmail: user.email },
        ],
      }),
      User.updateMany(
        { 'linkedFromInvites.inviterUserId': id },
        { $pull: { linkedFromInvites: { inviterUserId: id } } },
      ),
      ...linkCleanups,
    ]);

    await User.deleteOne({ _id: user._id });

    return res.json({
      deleted: true,
      id,
      email: user.email,
    });
  } catch (err) {
    console.error('admin delete user', err);
    return res.status(500).json({ message: 'Failed to delete user' });
  }
});

router.get('/notifications/recent', adminRequired, async (req, res) => {
  try {
    const items = await Notification.aggregate([
      { $match: { type: 'admin' } },
      { $sort: { createdAt: -1 } },
      {
        $group: {
          _id: '$data.broadcastId',
          title: { $first: '$title' },
          message: { $first: '$message' },
          createdAt: { $first: '$createdAt' },
          recipientCount: { $sum: 1 },
        },
      },
      { $sort: { createdAt: -1 } },
      { $limit: 20 },
    ]);
    return res.json({
      broadcasts: items.map((item) => ({
        id: item._id,
        title: item.title,
        message: item.message,
        createdAt: item.createdAt,
        recipientCount: item.recipientCount,
      })),
    });
  } catch (err) {
    console.error('admin recent notifications', err);
    return res.status(500).json({ message: 'Failed to load notifications' });
  }
});

router.post('/notifications', adminRequired, async (req, res) => {
  try {
    const title = String(req.body.title || '').trim();
    const message = String(req.body.message || '').trim();
    const rawIds = Array.isArray(req.body.userIds) ? req.body.userIds : [];

    if (!title) {
      return res.status(400).json({ message: 'Enter a notification title' });
    }
    if (!message) {
      return res.status(400).json({ message: 'Enter a notification message' });
    }
    if (title.length > 120) {
      return res.status(400).json({ message: 'Title is too long' });
    }
    if (message.length > 2000) {
      return res.status(400).json({ message: 'Message is too long' });
    }

    let recipients;
    if (rawIds.length) {
      const ids = rawIds
        .map((id) => String(id))
        .filter((id) => mongoose.isValidObjectId(id));
      recipients = await User.find({
        _id: { $in: ids },
        role: { $ne: 'admin' },
      }).select('_id');
      if (!recipients.length) {
        return res.status(400).json({ message: 'No matching users to notify' });
      }
    } else {
      recipients = await User.find({ role: { $ne: 'admin' } }).select('_id');
      if (!recipients.length) {
        return res.status(400).json({ message: 'There are no users to notify' });
      }
    }

    const broadcastId = crypto.randomUUID();
    const docs = recipients.map((user) => ({
      recipientUserId: user._id,
      type: 'admin',
      title,
      message,
      eventKey: `admin:${broadcastId}:${user._id}`,
      data: {
        broadcastId,
        event: 'admin_broadcast',
      },
    }));

    await Notification.insertMany(docs, { ordered: false });

    return res.status(201).json({
      broadcastId,
      title,
      message,
      recipientCount: docs.length,
    });
  } catch (err) {
    console.error('admin send notification', err);
    return res.status(500).json({ message: 'Failed to send notification' });
  }
});

module.exports = router;
