import { assertEquals } from "@std/assert";
import { buildApp } from "../src/http/app.ts";

Deno.test("GET /v1/health returns ok", async () => {
  const app = buildApp();
  const res = await app.request("/v1/health");
  assertEquals(res.status, 200);
  assertEquals(await res.json(), { ok: true });
});

Deno.test("unknown path returns generic not_found", async () => {
  const app = buildApp();
  const res = await app.request("/admin");
  assertEquals(res.status, 404);
  assertEquals(await res.json(), { code: "not_found" });
});
