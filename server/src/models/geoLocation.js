const mongoose = require('mongoose');

const geoLocationSchema = new mongoose.Schema(
  {
    country: { type: String, default: '' },
    state: { type: String, default: '' },
    place: { type: String, default: '' },
    address: { type: String, default: '' },
    latitude: { type: Number, default: null },
    longitude: { type: Number, default: null },
    accuracyMeters: { type: Number, default: null },
    source: { type: String, enum: ['gps', 'ip'], default: 'ip' },
    ip: { type: String, default: '' },
    capturedAt: { type: Date },
  },
  { _id: false },
);

function toLocationJson(loc) {
  if (!loc) return null;
  const obj = typeof loc.toObject === 'function' ? loc.toObject() : loc;
  const hasAny =
    obj.country ||
    obj.state ||
    obj.place ||
    obj.address ||
    obj.latitude != null ||
    obj.longitude != null;
  if (!hasAny) return null;
  return {
    country: obj.country || '',
    state: obj.state || '',
    place: obj.place || '',
    address: obj.address || '',
    latitude: obj.latitude ?? null,
    longitude: obj.longitude ?? null,
    accuracyMeters: obj.accuracyMeters ?? null,
    source: obj.source || 'ip',
    ip: obj.ip || '',
    capturedAt: obj.capturedAt || null,
  };
}

module.exports = { geoLocationSchema, toLocationJson };
