// Runtime config loader. Defaults compiled in; app_config rows override.
// Reloaded every 30 s by the background job (T11). Time is a parameter so
// tests use a fake clock. See PLAN.md 6.3.
import type { Sql } from "../db/client.ts";

export interface RuntimeConfig {
  serviceEnabled: boolean;
  consentVersion: number;
  maxActiveTrips: number;
}

export function defaultRuntimeConfig(): RuntimeConfig {
  return { serviceEnabled: true, consentVersion: 1, maxActiveTrips: 300 };
}

/** Load overrides from app_config. Unknown keys are ignored. */
export async function loadRuntimeConfig(sql: Sql): Promise<RuntimeConfig> {
  const cfg = defaultRuntimeConfig();
  const rows = await sql`select key, value from app_config`;
  for (const row of rows as unknown as { key: string; value: unknown }[]) {
    if (row.key === "service_enabled" && typeof row.value === "boolean") {
      cfg.serviceEnabled = row.value;
    } else if (row.key === "consent_version" && typeof row.value === "number") {
      cfg.consentVersion = Math.trunc(row.value);
    } else if (
      row.key === "max_active_trips" && typeof row.value === "number"
    ) {
      cfg.maxActiveTrips = Math.trunc(row.value);
    }
  }
  return cfg;
}
