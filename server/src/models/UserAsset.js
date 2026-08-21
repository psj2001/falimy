const mongoose = require('mongoose');

const userAssetSchema = new mongoose.Schema(
  {
    ownerUserId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    assetId: { type: String, required: true },
    asset: { type: mongoose.Schema.Types.Mixed, required: true },
  },
  { timestamps: true },
);

userAssetSchema.index({ ownerUserId: 1, assetId: 1 }, { unique: true });

module.exports = mongoose.model('UserAsset', userAssetSchema);
