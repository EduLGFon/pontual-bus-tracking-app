# step.md - Current step: T12 reads and stream

Status: done 2026-10-02. Next: T13. T04 and T05 blocked on owner infra answers.

## 1. What T12 is

PLAN.md section 16, Milestone M1. Deliverable: read endpoints (GET /v1/lines/{id}/vehicles with ETag, GET /v1/live), WebSocket hub (subscribe, caps, heartbeat, backpressure, bye), edge-cache headers.

## 2. Done 2026-10-02

- Snapshot builders plus read routes plus hub plus main wiring (tick broadcast, 25 s heartbeat, bye on shutdown).
- Tests for AC05 (HTTP part), AC06, AC08.
- Verified: 63 tests pass, fmt/lint/check clean, live 101 upgrade and endpoint checks via curl.

## 3. Acceptance criteria (from PLAN T12)

- AC05, AC06, AC08 pass.

## 4. Verify

1. `deno task test` passes (needs TEST_DATABASE_URL).
2. `deno fmt --check`, `deno lint`, `deno check src/main.ts` clean.

## 5. Rules

- One logical change only. No simulator (T13) or static data (T14).
- Docs English. No em dashes. Commit: `feat: add read endpoints and stream (T12)`.

## 6. Next

T13 (Deno simulator tools/sim with buses, riders, abuse scenarios, latency report against local/staging). Then M2 static data (T14-T17).
