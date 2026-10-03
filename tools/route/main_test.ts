// Route tool tests on synthetic traces. No real GPS data is committed.
import { assert, assertEquals } from "@std/assert";
import {
  decodePolyline,
  encodePolyline,
  parseGeoJson,
  parseGpx,
  type Point,
  simplify,
} from "./main.ts";

function straight(n: number): Point[] {
  const pts: Point[] = [];
  for (let i = 0; i < n; i++) {
    pts.push({ lat: -18.72 + i * 0.0001, lng: -39.85 + i * 0.0001 });
  }
  return pts;
}

Deno.test("simplify keeps shape within tolerance", () => {
  const raw = straight(200);
  raw[100] = { lat: raw[100].lat + 0.001, lng: raw[100].lng };
  const kept = simplify(raw, 5);
  assert(kept.length < raw.length && kept.length >= 3);
  assertEquals(kept[0], raw[0]);
  assertEquals(kept[kept.length - 1], raw[raw.length - 1]);
});

Deno.test("polyline round-trips within precision", () => {
  const pts = straight(50);
  const text = encodePolyline(pts, 5);
  const back = decodePolyline(text, 5);
  assertEquals(back.length, pts.length);
  for (let i = 0; i < pts.length; i++) {
    assert(Math.abs(back[i].lat - pts[i].lat) < 1e-5);
    assert(Math.abs(back[i].lng - pts[i].lng) < 1e-5);
  }
  assert(new TextEncoder().encode(text).length < 8 * 1024);
});

Deno.test("parsers read gpx and geojson", () => {
  const gpx =
    `<?xml version="1.0"?><gpx><trk><trkseg><trkpt lat="-18.72" lon="-39.85"/><trkpt lat="-18.71" lon="-39.84"/></trkseg></trk></gpx>`;
  assertEquals(parseGpx(gpx), [{ lat: -18.72, lng: -39.85 }, {
    lat: -18.71,
    lng: -39.84,
  }]);
  const geo = JSON.stringify({
    type: "LineString",
    coordinates: [[-39.85, -18.72], [-39.84, -18.71]],
  });
  assertEquals(parseGeoJson(geo), [{ lat: -18.72, lng: -39.85 }, {
    lat: -18.71,
    lng: -39.84,
  }]);
});
