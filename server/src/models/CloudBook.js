const mongoose = require('mongoose');

const cloudBookSchema = new mongoose.Schema(
  {
    ownerUserId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    bookId: { type: String, required: true },
    book: { type: mongoose.Schema.Types.Mixed, required: true },
    entries: { type: [mongoose.Schema.Types.Mixed], default: [] },
    categories: { type: [mongoose.Schema.Types.Mixed], default: [] },
    paymentModes: { type: [mongoose.Schema.Types.Mixed], default: [] },
    syncedAt: { type: Date, default: Date.now },
  },
  { timestamps: true },
);

cloudBookSchema.index({ ownerUserId: 1, bookId: 1 }, { unique: true });

module.exports = mongoose.model('CloudBook', cloudBookSchema);
