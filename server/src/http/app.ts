// Hono app for T06. Thin routes only; no business rules here.
// See PLAN.md 6.5 and 6.9.
import { Hono } from "@hono/hono";
import { recordHealthCheck, recordRequest } from "../observability/metrics.ts";

export function buildApp(): Hono<{ Variables: { requestId: string } }> {
  const app = new Hono<{ Variables: { requestId: string } }>();

  app.use("*", async (c, next) => {
    const requestId = crypto.randomUUID();
    c.set("requestId", requestId);
    const start = Date.now();
    await next();
    const durationMs = Date.now() - start;
    recordRequest();
    const route = c.req.routePath;
    console.log(
      JSON.stringify({
        level: "info",
        msg: "request",
        method: c.req.method,
        route,
        status: c.res.status,
        durationMs,
        requestId,
      }),
    );
    c.header("x-request-id", requestId);
  });

  app.get("/v1/health", (c) => {
    recordHealthCheck();
    return c.json({ ok: true });
  });

  app.notFound((c) => c.json({ code: "not_found" }, 404));
  app.onError((err, c) => {
    console.log(JSON.stringify({ level: "error", msg: "unhandled" }));
    void err;
    return c.json({ code: "internal" }, 500);
  });

  return app;
}
