const express = require('express');
const Notification = require('../models/Notification');
const Invite = require('../models/Invite');
const User = require('../models/User');
const { authRequired } = require('../middleware/auth');

const router = express.Router();

function toJson(notification) {
  return {
    id: notification._id.toString(),
    type: notification.type,
    title: notification.title,
    message: notification.message,
    data: notification.data || {},
    isRead: Boolean(notification.readAt),
    readAt: notification.readAt || null,
    createdAt: notification.createdAt,
  };
}

async function backfillFamilyNotifications(userId) {
  const [acceptedInvites, user] = await Promise.all([
    Invite.find({ inviterUserId: userId, status: 'accepted' }),
    User.findById(userId).select('linkedFromInvites'),
  ]);

  const writes = [];
  for (const invite of acceptedInvites) {
    const inviteId = invite._id.toString();
    writes.push(
      Notification.findOneAndUpdate(
        {
          eventKey: `member_joined:${inviteId}:${userId}`,
        },
        {
          $setOnInsert: {
            recipientUserId: userId,
            type: 'family_linked',
            title: 'Family member joined',
            message: `${invite.memberName} joined your family tree as ${invite.memberRole}.`,
            eventKey: `member_joined:${inviteId}:${userId}`,
            data: {
              inviteId,
              joinedUserId: invite.acceptedUserId?.toString() || null,
              memberKey: invite.memberKey,
              memberRole: invite.memberRole,
              event: 'member_joined',
            },
          },
        },
        { upsert: true },
      ),
    );
  }

  for (const link of user?.linkedFromInvites || []) {
    if (!link.inviteId) continue;
    writes.push(
      Notification.findOneAndUpdate(
        {
          eventKey: `joined_tree:${link.inviteId}:${userId}`,
        },
        {
          $setOnInsert: {
            recipientUserId: userId,
            type: 'family_linked',
            title: 'Joined a family tree',
            message: `You are linked as ${link.memberRole} in ${
              link.inviterName || 'your family member'
            }'s tree.`,
            eventKey: `joined_tree:${link.inviteId}:${userId}`,
            data: {
              inviteId: link.inviteId,
              inviterUserId: link.inviterUserId,
              memberKey: link.memberKey,
              memberRole: link.memberRole,
              event: 'joined_tree',
            },
          },
        },
        { upsert: true },
      ),
    );
  }

  await Promise.all(writes);
}

router.get('/', authRequired, async (req, res) => {
  try {
    await backfillFamilyNotifications(req.userId);
    const [notifications, unreadCount] = await Promise.all([
      Notification.find({ recipientUserId: req.userId })
        .sort({ createdAt: -1 })
        .limit(100),
      Notification.countDocuments({
        recipientUserId: req.userId,
        readAt: null,
      }),
    ]);
    return res.json({
      notifications: notifications.map(toJson),
      unreadCount,
    });
  } catch (err) {
    console.error('list notifications', err);
    return res.status(500).json({ message: 'Failed to load notifications' });
  }
});

router.patch('/:id/read', authRequired, async (req, res) => {
  try {
    const notification = await Notification.findOneAndUpdate(
      { _id: req.params.id, recipientUserId: req.userId },
      { $set: { readAt: new Date() } },
      { new: true },
    );
    if (!notification) {
      return res.status(404).json({ message: 'Notification not found' });
    }
    return res.json({ notification: toJson(notification) });
  } catch (err) {
    console.error('read notification', err);
    return res.status(500).json({ message: 'Failed to update notification' });
  }
});

router.post('/read-all', authRequired, async (req, res) => {
  try {
    await Notification.updateMany(
      { recipientUserId: req.userId, readAt: null },
      { $set: { readAt: new Date() } },
    );
    return res.json({ unreadCount: 0 });
  } catch (err) {
    console.error('read all notifications', err);
    return res.status(500).json({ message: 'Failed to update notifications' });
  }
});

module.exports = router;
