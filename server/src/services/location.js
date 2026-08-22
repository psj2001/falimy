function clean(value) {
  const text = String(value || '').trim();
  return text || '';
}

function clientIp(req) {
  const forwarded = req.headers['x-forwarded-for'];
  if (forwarded) {
    return String(forwarded).split(',')[0].trim();
  }
  return String(req.socket?.remoteAddress || '')
    .replace('::ffff:', '')
    .trim();
}

function isPublicIp(ip) {
  const value = String(ip || '').replace('::ffff:', '');
  if (!value || value === '::1' || value === '127.0.0.1') return false;
  if (value.startsWith('10.') || value.startsWith('192.168.')) return false;
  if (value.startsWith('172.')) {
    const second = Number(value.split('.')[1]);
    if (second >= 16 && second <= 31) return false;
  }
  return true;
}

function readNumber(value) {
  const n = Number(value);
  return Number.isFinite(n) ? n : null;
}

function fromClient(raw) {
  const input = raw && typeof raw === 'object' ? raw : {};
  const latitude = readNumber(input.latitude);
  const longitude = readNumber(input.longitude);
  return {
    country: clean(input.country),
    state: clean(input.state),
    place: clean(input.place),
    address: clean(input.address),
    latitude,
    longitude,
    accuracyMeters: readNumber(input.accuracyMeters),
    source: latitude != null && longitude != null ? 'gps' : 'ip',
    ip: '',
    capturedAt: new Date(),
  };
}

async function fetchJson(url, options = {}, timeoutMs = 3500) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const res = await fetch(url, { ...options, signal: controller.signal });
    if (!res.ok) return null;
    return await res.json();
  } catch (_) {
    return null;
  } finally {
    clearTimeout(timer);
  }
}

async function reverseGeocode(latitude, longitude) {
  const url =
    'https://nominatim.openstreetmap.org/reverse?format=jsonv2' +
    `&lat=${encodeURIComponent(latitude)}` +
    `&lon=${encodeURIComponent(longitude)}`;
  const data = await fetchJson(url, {
    headers: {
      'User-Agent': 'Falimy/1.0 (family app)',
      Accept: 'application/json',
    },
  });
  if (!data) return null;
  const address = data.address || {};
  return {
    country: clean(address.country),
    state: clean(address.state),
    place: clean(
      address.city ||
        address.town ||
        address.village ||
        address.hamlet ||
        address.suburb ||
        address.county,
    ),
    address: clean(data.display_name),
  };
}

async function lookupIp(ip) {
  if (!isPublicIp(ip)) return null;
  const data = await fetchJson(
    `http://ip-api.com/json/${encodeURIComponent(ip)}?fields=status,country,regionName,city,lat,lon,query`,
  );
  if (!data || data.status !== 'success') return null;
  return {
    country: clean(data.country),
    state: clean(data.regionName),
    place: clean(data.city),
    address: [data.city, data.regionName, data.country].filter(Boolean).join(', '),
    latitude: readNumber(data.lat),
    longitude: readNumber(data.lon),
    source: 'ip',
    ip: clean(data.query) || ip,
  };
}

function hasPlaceNames(loc) {
  return Boolean(loc?.country || loc?.state || loc?.place);
}

function isGps(loc) {
  return loc?.source === 'gps' && loc?.latitude != null && loc?.longitude != null;
}

async function resolveSignupLocation(req) {
  const ip = clientIp(req);
  const loc = fromClient(req.body?.location);
  loc.ip = ip;

  if (loc.latitude != null && loc.longitude != null) {
    loc.source = 'gps';
    if (!hasPlaceNames(loc)) {
      const geo = await reverseGeocode(loc.latitude, loc.longitude);
      if (geo) {
        loc.country = loc.country || geo.country;
        loc.state = loc.state || geo.state;
        loc.place = loc.place || geo.place;
        loc.address = loc.address || geo.address;
      }
    }
    return loc;
  }

  const ipGeo = await lookupIp(ip);
  if (ipGeo) {
    return {
      ...loc,
      ...ipGeo,
      capturedAt: new Date(),
    };
  }

  if (!hasPlaceNames(loc) && loc.latitude == null) {
    return null;
  }
  loc.source = loc.source || 'ip';
  return loc;
}

function shouldReplaceLocation(existing, next) {
  if (!next) return false;
  if (!existing) return true;
  if (!isGps(existing) && isGps(next)) return true;
  if (!hasPlaceNames(existing) && hasPlaceNames(next)) return true;
  return false;
}

module.exports = {
  resolveSignupLocation,
  shouldReplaceLocation,
  isGps,
};
