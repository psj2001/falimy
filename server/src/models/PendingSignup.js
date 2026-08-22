const mongoose = require('mongoose');
const { geoLocationSchema } = require('./geoLocation');

const pendingSignupSchema = new mongoose.Schema(
  {
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },
    passwordHash: { type: String, required: true },
    otpHash: { type: String, required: true },
    otpExpiresAt: { type: Date, required: true },
    otpAttempts: { type: Number, default: 0 },
    referralCode: {
      type: String,
      uppercase: true,
      trim: true,
      default: null,
    },
    location: geoLocationSchema,
  },
  { timestamps: true },
);

// Auto-clean stale pending signups after 24h
pendingSignupSchema.index({ createdAt: 1 }, { expireAfterSeconds: 60 * 60 * 24 });

module.exports = mongoose.model('PendingSignup', pendingSignupSchema);
