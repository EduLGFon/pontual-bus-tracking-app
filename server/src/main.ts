// Bootstrap: config, HTTP server, internal metrics listener, shutdown.
// See PLAN.md 6.2, 6.9, 6.10.
import { loadConfig } from "./config/config.ts";
import { openDb } from "./db/client.ts";
import { buildApp } from "./http/app.ts";
import { setLogLevel } from "./observability/log.ts";
import { snapshot } from "./observability/metrics.ts";

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
const app = buildApp({
  sql,
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
  controller.abort();
  metricsController.abort();
  void sql.end();
}

Deno.addSignalListener("SIGTERM", shutdown);
Deno.addSignalListener("SIGINT", shutdown);

await Promise.all([server.finished, metricsServer.finished]);
