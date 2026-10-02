// Bearer auth. The device id comes from the verified token only.
// SECURITY: no client-supplied ids anywhere; one active trip per device is
// enforced later by the engine. Unknown or expired tokens behave exactly
// like missing ones: 401 with a generic code.
import type { Context, Next } from "@hono/hono";
import type { Sql } from "../db/client.ts";
import { findDeviceByTokenHash } from "../db/devices.ts";
import { bearerToken, tokenHash } from "./token.ts";

interface CacheEntry {
  deviceId: string;
  expiresAtMs: number;
}

const cache = new Map<string, CacheEntry>();
const CACHE_TTL_MS = 60 * 1000;

/** Evict a token hash from the cache (revocation path). */
export function evictTokenHash(hashHex: string): void {
  cache.delete(hashHex);
}

function hashHex(hash: Uint8Array): string {
  return [...hash].map((b) => b.toString(16).padStart(2, "0")).join("");
}

export function authMiddleware(sql: Sql) {
  return async (
    c: Context<{ Variables: { requestId: string; deviceId: string } }>,
    next: Next,
  ) => {
    const token = bearerToken(c.req.header("authorization") ?? null);
    if (!token) return c.json({ e: "auth" }, 401);
    const hash = await tokenHash(token);
    const key = hashHex(hash);
    const now = Date.now();
    const hit = cache.get(key);
    if (hit && hit.expiresAtMs > now) {
      c.set("deviceId", hit.deviceId);
      await next();
      return;
    }
    const row = await findDeviceByTokenHash(sql, hash);
    if (!row || row.expiresAt.getTime() <= now) {
      return c.json({ e: "auth" }, 401);
    }
    cache.set(key, { deviceId: row.id, expiresAtMs: now + CACHE_TTL_MS });
    c.set("deviceId", row.id);
    await next();
  };
}
