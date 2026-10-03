// Pure geo helpers. No I/O, no clock. See PLAN.md 6.6.
// Units carry suffixes: distM, speedMps, dtS.

const EARTH_M = 6371000;
const DEG_M = 111320;

/** Haversine distance in meters. */
export function distM(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number,
): number {
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lng2 - lng1) * Math.PI) / 180;
  const a = Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) * Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLng / 2) ** 2;
  return 2 * EARTH_M * Math.asin(Math.sqrt(a));
}

export interface Predicted {
  lat: number;
  lng: number;
}

/**
 * Dead reckoning (equirectangular, fine at city scale). Heading h is radians
 * clockwise from north. Null heading keeps position; callers widen tolerance
 * by v*dt. See PLAN.md 6.6.
 */
export function predict(
  lat: number,
  lng: number,
  speedMps: number,
  heading: number | null,
  dtS: number,
): Predicted {
  if (heading === null || speedMps <= 0 || dtS <= 0) return { lat, lng };
  const d = speedMps * dtS;
  const lat2 = lat + (d * Math.cos(heading)) / DEG_M;
  const lng2 = lng +
    (d * Math.sin(heading)) / (DEG_M * Math.cos((lat * Math.PI) / 180));
  return { lat: lat2, lng: lng2 };
}

/** Attach tolerance: min(max, base + factor * speed * age). */
export function attachTolM(
  baseTolM: number,
  speedFactor: number,
  tolMaxM: number,
  speedMps: number,
  ageS: number,
): number {
  return Math.min(tolMaxM, baseTolM + speedFactor * speedMps * ageS);
}

function distToSegM(
  lat: number,
  lng: number,
  aLat: number,
  aLng: number,
  bLat: number,
  bLng: number,
): number {
  const kx = DEG_M * Math.cos(((aLat + bLat) / 2 * Math.PI) / 180);
  const px = (lng - aLng) * kx;
  const py = (lat - aLat) * DEG_M;
  const ax = 0;
  const ay = 0;
  const bx = (bLng - aLng) * kx;
  const by = (bLat - aLat) * DEG_M;
  const dx = bx - ax;
  const dy = by - ay;
  const len2 = dx * dx + dy * dy;
  let t = len2 === 0 ? 0 : ((px - ax) * dx + (py - ay) * dy) / len2;
  t = Math.max(0, Math.min(1, t));
  const cx = ax + t * dx;
  const cy = ay + t * dy;
  return Math.hypot(px - cx, py - cy);
}

/** Distance to a polyline in meters. Linear scan; routes are small. */ export function distToPolylineM(
  lat: number,
  lng: number,
  polyline: { lat: number; lng: number }[],
): number {
  if (polyline.length === 0) return Infinity;
  if (polyline.length === 1) {
    return distM(lat, lng, polyline[0].lat, polyline[0].lng);
  }
  let best = Infinity;
  for (let i = 0; i + 1 < polyline.length; i++) {
    const d = distToSegM(
      lat,
      lng,
      polyline[i].lat,
      polyline[i].lng,
      polyline[i + 1].lat,
      polyline[i + 1].lng,
    );
    if (d < best) best = d;
  }
  return best;
}

/**
 * Decode a Google polyline at the given precision. Mirrors the data route
 * tool (tools/route/main.ts); kept in sync by the round-trip test.
 */
export function decodePolyline(
  text: string,
  precision = 5,
): { lat: number; lng: number }[] {
  const factor = 10 ** precision;
  const pts: { lat: number; lng: number }[] = [];
  let lat = 0;
  let lng = 0;
  let i = 0;
  while (i < text.length) {
    let shift = 0;
    let delta = 0;
    let b: number;
    do {
      b = text.charCodeAt(i++) - 63;
      delta |= (b & 31) << shift;
      shift += 5;
    } while (b >= 32);
    lat += delta & 1 ? ~(delta >> 1) : delta >> 1;
    shift = 0;
    delta = 0;
    do {
      b = text.charCodeAt(i++) - 63;
      delta |= (b & 31) << shift;
      shift += 5;
    } while (b >= 32);
    lng += delta & 1 ? ~(delta >> 1) : delta >> 1;
    pts.push({ lat: lat / factor, lng: lng / factor });
  }
  return pts;
}
