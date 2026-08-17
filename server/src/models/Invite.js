const mongoose = require('mongoose');

const inviteSchema = new mongoose.Schema(
  {
    inviteeEmail: {
      type: String,
      required: true,
      lowercase: true,
      trim: true,
      index: true,
    },
    inviterUserId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    inviterName: { type: String, default: '' },
    memberKey: { type: String, required: true },
    memberName: { type: String, required: true },
    memberKind: { type: String, required: true },
    memberRole: { type: String, required: true },
    familyName: String,
    referralCode: {
      type: String,
      uppercase: true,
      trim: true,
      index: true,
      unique: true,
      sparse: true,
    },
    status: {
      type: String,
      enum: ['pending', 'accepted', 'cancelled'],
      default: 'pending',
      index: true,
    },
    acceptedUserId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    acceptedAt: Date,
  },
  { timestamps: true },
);

inviteSchema.index({ inviteeEmail: 1, status: 1 });

module.exports = mongoose.model('Invite', inviteSchema);
