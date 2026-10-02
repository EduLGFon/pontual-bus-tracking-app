import { assertEquals, assertThrows } from "@std/assert";
import { loadConfig } from "../src/config/config.ts";

function baseEnv(): Record<string, string | undefined> {
  return {
    APP_ENV: "local",
    HOST: "127.0.0.1",
    PORT: "8080",
    DATABASE_URL: "postgresql://user:pass@127.0.0.1:5432/dbname",
    ALLOWED_ORIGINS: "http://127.0.0.1:8080",
    TRUST_CLOUDFLARE: "false",
    DATA_DIR: "./build",
    LOG_LEVEL: "info",
    METRICS_PORT: "127.0.0.1:9091",
  };
}

Deno.test("valid env loads", () => {
  const cfg = loadConfig(baseEnv());
  assertEquals(cfg.port, 8080);
  assertEquals(cfg.metricsPort, 9091);
});

Deno.test("missing env refuses to start", () => {
  const env = baseEnv();
  delete env.DATABASE_URL;
  assertThrows(() => loadConfig(env), Error, "missing env DATABASE_URL");
});

Deno.test("invalid env refuses to start", () => {
  const badPort = { ...baseEnv(), PORT: "abc" };
  assertThrows(() => loadConfig(badPort), Error, "invalid env PORT");
  const badEnv = { ...baseEnv(), APP_ENV: "qa" };
  assertThrows(() => loadConfig(badEnv), Error, "invalid env APP_ENV");
});
