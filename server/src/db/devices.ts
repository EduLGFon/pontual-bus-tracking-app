// Device repository. Pseudonymous rows only, no location.
// SECURITY: every lookup is scoped by the authenticated device id or its
// token hash derived server-side. Never accept ownership from the client.
import type { Sql } from "./client.ts";

export interface DeviceRow {
  id: string;
  tokenHash: Uint8Array;
  createdAt: Date;
  lastSeenAt: Date;
  expiresAt: Date;
}

export async function insertDevice(
  sql: Sql,
  tokenHash: Uint8Array,
  expiresAt: Date,
): Promise<DeviceRow> {
  const rows = await sql`
    insert into devices (token_hash, expires_at)
    values (${tokenHash}, ${expiresAt})
    returning id, token_hash as "tokenHash", created_at as "createdAt",
      last_seen_at as "lastSeenAt", expires_at as "expiresAt"`;
  return rows[0] as DeviceRow;
}

export async function findDeviceByTokenHash(
  sql: Sql,
  tokenHash: Uint8Array,
): Promise<DeviceRow | null> {
  const rows = await sql`
    select id, token_hash as "tokenHash", created_at as "createdAt",
      last_seen_at as "lastSeenAt", expires_at as "expiresAt"
    from devices where token_hash = ${tokenHash} limit 1`;
  return (rows[0] as DeviceRow | undefined) ?? null;
}

export async function deleteDevice(sql: Sql, deviceId: string): Promise<void> {
  await sql`delete from devices where id = ${deviceId}`;
}

export async function purgeExpiredDevices(
  sql: Sql,
  now: Date,
): Promise<number> {
  const rows =
    await sql`delete from devices where expires_at <= ${now} returning id`;
  return rows.length;
}
