const express = require('express');
const CloudBook = require('../models/CloudBook');
const { authRequired } = require('../middleware/auth');

const router = express.Router();

router.use(authRequired);

// Full package for every book — used to restore data on a new device.
router.get('/snapshot', async (req, res, next) => {
  try {
    const docs = await CloudBook.find({ ownerUserId: req.userId }).lean();
    res.json({
      books: docs.map((doc) => ({
        book: doc.book,
        entries: doc.entries ?? [],
        categories: doc.categories ?? [],
        paymentModes: doc.paymentModes ?? [],
        syncedAt: doc.syncedAt,
      })),
    });
  } catch (err) {
    next(err);
  }
});

// List cloud books for current user (metadata)
router.get('/books', async (req, res, next) => {
  try {
    const docs = await CloudBook.find({ ownerUserId: req.userId })
      .select('bookId book syncedAt updatedAt')
      .lean();
    res.json({
      books: docs.map((d) => ({
        id: d.bookId,
        name: d.book?.name ?? '',
        access: d.book?.access ?? 'justMe',
        createdAt: d.book?.createdAt,
        updatedAt: d.book?.updatedAt,
        syncedAt: d.syncedAt,
      })),
    });
  } catch (err) {
    next(err);
  }
});

// Full book package
router.get('/books/:bookId', async (req, res, next) => {
  try {
    const doc = await CloudBook.findOne({
      ownerUserId: req.userId,
      bookId: req.params.bookId,
    }).lean();
    if (!doc) {
      return res.status(404).json({ message: 'Cloud book not found' });
    }
    res.json({
      book: doc.book,
      entries: doc.entries ?? [],
      categories: doc.categories ?? [],
      paymentModes: doc.paymentModes ?? [],
      syncedAt: doc.syncedAt,
    });
  } catch (err) {
    next(err);
  }
});

// Upsert whole book package
router.put('/books/:bookId', async (req, res, next) => {
  try {
    const { book, entries, categories, paymentModes } = req.body || {};
    if (!book || typeof book !== 'object') {
      return res.status(400).json({ message: 'book payload is required' });
    }

    const bookId = req.params.bookId;
    const payload = {
      ...book,
      id: bookId,
    };

    const syncedAt = new Date();
    const doc = await CloudBook.findOneAndUpdate(
      { ownerUserId: req.userId, bookId },
      {
        ownerUserId: req.userId,
        bookId,
        book: payload,
        entries: Array.isArray(entries) ? entries : [],
        categories: Array.isArray(categories) ? categories : [],
        paymentModes: Array.isArray(paymentModes) ? paymentModes : [],
        syncedAt,
      },
      { upsert: true, new: true, setDefaultsOnInsert: true },
    ).lean();

    res.json({
      book: doc.book,
      syncedAt: doc.syncedAt,
    });
  } catch (err) {
    next(err);
  }
});

// Remove from cloud only
router.delete('/books/:bookId', async (req, res, next) => {
  try {
    await CloudBook.deleteOne({
      ownerUserId: req.userId,
      bookId: req.params.bookId,
    });
    res.status(204).send();
  } catch (err) {
    next(err);
  }
});

module.exports = router;
