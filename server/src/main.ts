// Bootstrap: config, HTTP server, internal metrics listener, shutdown.
// See PLAN.md 6.2, 6.9, 6.10.
import { loadConfig } from "./config/config.ts";
import { registryResolver } from "./data/lines.ts";
import { openDb } from "./db/client.ts";
import { defaultEngineConfig } from "./domain/types.ts";
import { buildApp } from "./http/app.ts";
import { startJobs } from "./jobs/jobs.ts";
import { setLogLevel } from "./observability/log.ts";
import { snapshot } from "./observability/metrics.ts";
import { createStore } from "./state/store.ts";

function readEnv(): Record<string, string | undefined> {
  const names = [
    "APP_ENV",
    "HOST",
    "PORT",
    "DATABASE_URL",
    "ALLOWED_ORIGINS",
    "TRUST_CLOUDFLARE",
    "DATA_DIR",
    "LOG_LEVEL",
    "METRICS_PORT",
  ];
  const out: Record<string, string | undefined> = {};
  for (const n of names) out[n] = Deno.env.get(n);
  return out;
}

const config = loadConfig(readEnv());
setLogLevel(config.logLevel);

const sql = openDb(config.databaseUrl);
// Line registry loads from the built bundle in T14; empty until then.
const lines = registryResolver([]);
const store = createStore();
const app = buildApp({
  sql,
  store,
  lines,
  followerJitterS: 10,
  trustCloudflare: config.trustCloudflare,
  allowedOrigins: config.allowedOrigins,
});

const controller = new AbortController();

const server = Deno.serve(
  { hostname: config.host, port: config.port, signal: controller.signal },
  app.fetch,
);

// Internal metrics listener on localhost only. Never exposed via Cloudflare.
const metricsController = new AbortController();
const metricsServer = Deno.serve(
  {
    hostname: config.metricsHost,
    port: config.metricsPort,
    signal: metricsController.signal,
  },
  (_req) => Response.json(snapshot()),
);

function shutdown(): void {
  jobs.stop();
  controller.abort();
  metricsController.abort();
  void sql.end();
}

const engine = defaultEngineConfig();
const jobs = startJobs({
  sql,
  store,
  engine,
  events: [],
  tickPeriodMs: engine.tickPeriodS * 1000,
  configRefreshMs: 30 * 1000,
  // Next 03:30 America/Sao_Paulo (fixed UTC-3, no DST since 2019).
  purgeAtMs: (nowMs: number) => {
    const sao = new Date(nowMs - 3 * 3600 * 1000);
    const next = new Date(sao);
    next.setUTCHours(3, 30, 0, 0);
    if (next.getTime() <= sao.getTime()) next.setUTCDate(next.getUTCDate() + 1);
    return next.getTime() + 3 * 3600 * 1000;
  },
  dbHealthMs: 10 * 1000,
  onTick: () => {},
  onConfig: () => {},
});

Deno.addSignalListener("SIGTERM", shutdown);
Deno.addSignalListener("SIGINT", shutdown);

await Promise.all([server.finished, metricsServer.finished]);
