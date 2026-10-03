// Hono app. Middleware order per PLAN.md 6.9: request id, secure headers,
// client IP resolution, then per-route body limit, rate limit, auth, schema
// validation, handler, and the global error handler.
import { Hono } from "@hono/hono";
import type { Sql } from "../db/client.ts";
import { recordHealthCheck, recordRequest } from "../observability/metrics.ts";
import { clientIp } from "../security/clientIp.ts";
import type { LineResolver } from "../data/lines.ts";
import type { Store } from "../state/store.ts";
import { buildAccountRoutes } from "./routes.ts";
import { buildTripRoutes } from "./tripRoutes.ts";

export interface AppOptions {
  sql: Sql | null;
  store: Store | null;
  lines: LineResolver;
  followerJitterS: number;
  trustCloudflare: boolean;
  allowedOrigins: string[];
}

type Vars = {
  Variables: { requestId: string; deviceId: string; clientIp: string };
};

export function buildApp(opts: AppOptions): Hono<Vars> {
  const app = new Hono<Vars>();

  app.use("*", async (c, next) => {
    const requestId = crypto.randomUUID();
    c.set("requestId", requestId);
    const socketAddr = c.req.header("x-socket-addr") ?? null;
    c.set(
      "clientIp",
      clientIp(
        socketAddr,
        c.req.header("cf-connecting-ip") ?? null,
        opts.trustCloudflare,
      ),
    );
    const start = Date.now();
    await next();
    const durationMs = Date.now() - start;
    recordRequest();
    console.log(
      JSON.stringify({
        level: "info",
        msg: "request",
        method: c.req.method,
        route: c.req.routePath,
        status: c.res.status,
        durationMs,
        requestId,
      }),
    );
    c.header("x-request-id", requestId);
    c.header("x-content-type-options", "nosniff");
    c.header("referrer-policy", "no-referrer");
    c.header("cache-control", "no-store");
    const origin = c.req.header("origin");
    if (origin && opts.allowedOrigins.includes(origin)) {
      c.header("access-control-allow-origin", origin);
      c.header("vary", "Origin");
    }
  });

  app.get("/v1/health", (c) => {
    recordHealthCheck();
    return c.json({ ok: true });
  });

  if (opts.sql) {
    app.route("/", buildAccountRoutes(opts.sql));
  }
  if (opts.sql && opts.store) {
    app.route(
      "/",
      buildTripRoutes({
        sql: opts.sql,
        store: opts.store,
        lines: opts.lines,
        followerJitterS: opts.followerJitterS,
      }),
    );
  }

  app.notFound((c) => c.json({ code: "not_found" }, 404));
  app.onError((_err, c) => {
    console.log(JSON.stringify({ level: "error", msg: "unhandled" }));
    return c.json({ code: "internal" }, 500);
  });

  return app;
}
