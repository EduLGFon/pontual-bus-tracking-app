# step.md - Current step: T11 background jobs

Status: done 2026-10-02. Next: T12. T04 and T05 blocked on owner infra answers.

## 1. What T11 is

PLAN.md section 16, Milestone M1. Deliverable: tick job and background jobs (tick, config refresh, device purge, db health) with overlap guard.

## 2. Done 2026-10-02

- Jobs module with guarded tick, refresh, purge, health probe, shutdown stop.
- Wired into main.ts with 5 s, 30 s, daily 03:30 Sao Paulo, 10 s schedules.
- Tests including restart semantics (test 19).
- Verified: 52 tests pass, fmt/lint/check clean.

## 3. Acceptance criteria (from PLAN T11)

- Test 19 and tick behaviour tests pass.

## 4. Verify

1. `deno task test` passes (needs TEST_DATABASE_URL).
2. `deno fmt --check`, `deno lint`, `deno check src/main.ts` clean.

## 5. Rules

- One logical change only. No read endpoints (T12) or simulator (T13).
- Docs English. No em dashes. Commit: `feat: add background jobs (T11)`.

## 6. Next

T12 (read endpoints GET /v1/lines/{id}/vehicles with ETag and GET /v1/live, plus WebSocket hub with subscribe, caps, heartbeat, backpressure, bye, and edge-cache headers).
