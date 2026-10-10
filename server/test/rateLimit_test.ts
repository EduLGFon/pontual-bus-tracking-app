// RateLimiter unit tests: window behavior and pruning.
import { assert, assertEquals } from "@std/assert";
import { pruneLimiters, RateLimiter } from "../src/security/rateLimit.ts";

Deno.test("window allows limit then refuses", () => {
  const limiter = new RateLimiter(2, 60 * 1000);
  assert(limiter.hit("a", 0));
  assert(limiter.hit("a", 1000));
  assert(!limiter.hit("a", 2000));
  assert(limiter.hit("b", 2000));
});

Deno.test("prune drops expired buckets", () => {
  const limiter = new RateLimiter(1, 1000);
  assert(limiter.hit("a", 0));
  assertEquals(limiter.size(), 1);
  pruneLimiters(2000);
  assertEquals(limiter.size(), 0);
});
