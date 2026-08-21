const express = require('express');
const UserAsset = require('../models/UserAsset');
const { authRequired } = require('../middleware/auth');

const router = express.Router();
router.use(authRequired);

function asAsset(raw) {
  if (!raw || typeof raw !== 'object') return null;
  const id = String(raw.id || '').trim();
  if (!id) return null;
  return { ...raw, id };
}

router.get('/', async (req, res, next) => {
  try {
    const docs = await UserAsset.find({ ownerUserId: req.userId }).lean();
    res.json({
      assets: docs.map((doc) => doc.asset).filter(Boolean),
    });
  } catch (err) {
    next(err);
  }
});

router.put('/', async (req, res, next) => {
  try {
    const list = Array.isArray(req.body?.assets) ? req.body.assets : [];
    for (const item of list) {
      const asset = asAsset(item);
      if (!asset) continue;
      await UserAsset.findOneAndUpdate(
        { ownerUserId: req.userId, assetId: asset.id },
        { ownerUserId: req.userId, assetId: asset.id, asset },
        { upsert: true, setDefaultsOnInsert: true },
      );
    }
    const docs = await UserAsset.find({ ownerUserId: req.userId }).lean();
    res.json({ assets: docs.map((doc) => doc.asset).filter(Boolean) });
  } catch (err) {
    next(err);
  }
});

router.put('/:assetId', async (req, res, next) => {
  try {
    const asset = asAsset({ ...(req.body?.asset || req.body || {}), id: req.params.assetId });
    if (!asset) {
      return res.status(400).json({ message: 'asset payload is required' });
    }
    const doc = await UserAsset.findOneAndUpdate(
      { ownerUserId: req.userId, assetId: asset.id },
      { ownerUserId: req.userId, assetId: asset.id, asset },
      { upsert: true, new: true, setDefaultsOnInsert: true },
    ).lean();
    res.json({ asset: doc.asset });
  } catch (err) {
    next(err);
  }
});

router.delete('/:assetId', async (req, res, next) => {
  try {
    await UserAsset.deleteOne({
      ownerUserId: req.userId,
      assetId: req.params.assetId,
    });
    res.status(204).send();
  } catch (err) {
    next(err);
  }
});

module.exports = router;
