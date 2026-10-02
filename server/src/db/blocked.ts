// Blocklist repository. Scoped by device id only.
import type { Sql } from "./client.ts";

export async function isBlocked(sql: Sql, deviceId: string): Promise<boolean> {
  const rows =
    await sql`select 1 from blocked_devices where device_id = ${deviceId} limit 1`;
  return rows.length > 0;
}

export async function blockDevice(
  sql: Sql,
  deviceId: string,
  reason: string | null,
): Promise<void> {
  await sql`
    insert into blocked_devices (device_id, reason) values (${deviceId}, ${reason})
    on conflict (device_id) do update set reason = excluded.reason`;
}
