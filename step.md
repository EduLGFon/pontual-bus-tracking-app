# step.md - Current step: T10 trip endpoints

Status: done 2026-10-02. Next: T11. T04 and T05 blocked on owner infra answers.

## 1. What T10 is

PLAN.md section 16, Milestone M1. Deliverable: trip endpoints (POST /v1/trip, /v1/trip/ping, DELETE /v1/trip) wired to the engine with quotas, capacity, resume, kill switch.

## 2. Done 2026-10-02

- Trip schemas plus routes plus line resolver stub.
- Tests for AC02, AC07, AC09, AC10, AC14.
- Verified: 46 tests pass, fmt/lint/check clean, live flow via curl.

## 3. Acceptance criteria (from PLAN T10)

- AC02, AC07, AC09, AC10, AC14 pass.

## 4. Verify

1. `deno task test` passes (needs TEST_DATABASE_URL).
2. `deno fmt --check`, `deno lint`, `deno check src/main.ts` clean.

## 5. Rules

- One logical change only. No tick jobs (T11) or read endpoints (T12).
- Docs English. No em dashes. Commit: `feat: add trip endpoints (T10)`.

## 6. Next

T11 (tick job and background jobs: tick, config refresh, device purge, db health, with overlap guard).
