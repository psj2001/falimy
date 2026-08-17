const mongoose = require('mongoose');

const budgetSchema = new mongoose.Schema(
  {
    ownerUserId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    month: { type: String, required: true },
    currency: { type: String, default: 'AED' },
    savingsTargetPercent: { type: Number, default: 20 },
    incomes: { type: [mongoose.Schema.Types.Mixed], default: [] },
    categories: { type: [mongoose.Schema.Types.Mixed], default: [] },
  },
  { timestamps: true },
);

budgetSchema.index({ ownerUserId: 1, month: 1 }, { unique: true });

module.exports = mongoose.model('Budget', budgetSchema);
