// Public snapshot payloads. Vehicles only, never trips or device data.
// Coordinates at 5 decimals, member count capped at 3. See PLAN.md 6.6.
import { buildSnapshot } from "../domain/snapshot.ts";
import { membersOf, vehiclesOfLine } from "../state/store.ts";
import type { Store } from "../state/store.ts";

/** Snapshot body for one line plus its ETag. */
export function lineSnapshot(
  store: Store,
  lineId: number,
  nowMs: number,
  publishTtlS: number,
): { body: string; etag: string } {
  const vehicles = vehiclesOfLine(store, lineId);
  const members = new Map();
  for (const v of vehicles) {
    members.set(v.id, membersOf(store, v.id, nowMs, 300));
  }
  const snap = buildSnapshot(vehicles, members, lineId, nowMs, publishTtlS);
  const body = JSON.stringify(snap);
  return { body, etag: etagOf(body) };
}

/** Live-lines payload: only lines with a published vehicle. */
export function livePayload(
  store: Store,
  nowMs: number,
  publishTtlS: number,
): { body: string } {
  const rows: [number, number][] = [];
  for (const [lineId] of store.byLine) {
    const snap = lineSnapshot(store, lineId, nowMs, publishTtlS);
    const count = (JSON.parse(snap.body) as { v: unknown[] }).v.length;
    if (count > 0) rows.push([lineId, count]);
  }
  rows.sort((a, b) => a[0] - b[0]);
  return { body: JSON.stringify(rows) };
}

/** Weak ETag from a tiny content hash. */
export function etagOf(body: string): string {
  let h = 5381;
  for (let i = 0; i < body.length; i++) {
    h = ((h << 5) + h + body.charCodeAt(i)) | 0;
  }
  return `W/"${(h >>> 0).toString(16)}-${body.length}"`;
}
