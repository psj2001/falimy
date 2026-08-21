const mongoose = require('mongoose');

const userReminderSchema = new mongoose.Schema(
  {
    ownerUserId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    reminderId: { type: String, required: true },
    reminder: { type: mongoose.Schema.Types.Mixed, required: true },
  },
  { timestamps: true },
);

userReminderSchema.index({ ownerUserId: 1, reminderId: 1 }, { unique: true });

module.exports = mongoose.model('UserReminder', userReminderSchema);
