const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema(
  {
    recipientUserId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    type: {
      type: String,
      enum: ['family_invite', 'family_linked', 'admin'],
      required: true,
    },
    title: { type: String, required: true },
    message: { type: String, required: true },
    eventKey: {
      type: String,
      unique: true,
      sparse: true,
      index: true,
    },
    data: { type: mongoose.Schema.Types.Mixed, default: {} },
    readAt: { type: Date, default: null, index: true },
  },
  { timestamps: true },
);

notificationSchema.index({ recipientUserId: 1, createdAt: -1 });

module.exports = mongoose.model('Notification', notificationSchema);
