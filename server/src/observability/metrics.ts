// Aggregate counters only. No PII, no coordinates. See PLAN.md RNF18.

export interface MetricsSnapshot {
  startedAt: string;
  uptimeS: number;
  requestsTotal: number;
  healthChecksTotal: number;
}

const startedAtMs = Date.now();
let requestsTotal = 0;
let healthChecksTotal = 0;

export function recordRequest(): void {
  requestsTotal += 1;
}

export function recordHealthCheck(): void {
  healthChecksTotal += 1;
  requestsTotal += 1;
}

export function snapshot(): MetricsSnapshot {
  return {
    startedAt: new Date(startedAtMs).toISOString(),
    uptimeS: Math.floor((Date.now() - startedAtMs) / 1000),
    requestsTotal,
    healthChecksTotal,
  };
}
