// In-memory rate limiter. Fixed-window buckets per key, pruned on access.
// IPs are bucket keys only, never stored beyond the window. Limits stay
// generous but finite per PLAN.md 12.4 (CGNAT: never block by IP).
// Time is a parameter so tests use a fake clock.

export interface Bucket {
  count: number;
  windowStartMs: number;
}

export class RateLimiter {
  private buckets = new Map<string, Bucket>();

  constructor(private limit: number, private windowMs: number) {}

  /** True when the hit is allowed. Advances the window when expired. */
  hit(key: string, nowMs: number): boolean {
    const cur = this.buckets.get(key);
    if (!cur || nowMs - cur.windowStartMs >= this.windowMs) {
      this.buckets.set(key, { count: 1, windowStartMs: nowMs });
      return true;
    }
    if (cur.count >= this.limit) return false;
    cur.count += 1;
    return true;
  }

  /** Drop expired buckets. Called on the tick. */
  prune(nowMs: number): void {
    for (const [k, b] of this.buckets) {
      if (nowMs - b.windowStartMs >= this.windowMs) this.buckets.delete(k);
    }
  }

  size(): number {
    return this.buckets.size;
  }
}
