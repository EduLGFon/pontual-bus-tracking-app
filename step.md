# step.md - Current step: T06 server skeleton

Status: done 2026-10-02. Next: T07. T04 and T05 blocked on owner infra answers.

## 1. What T06 is

PLAN.md section 16, Milestone M1. Deliverable: `server/` skeleton with deno.json, import map, lock, fail-fast config, Log wrapper, Hono app, GET /v1/health, graceful shutdown, internal metrics listener, CI job.

## 2. Done 2026-10-02

- Deno 2.9.7 with Hono 4.13.12 MIT via JSR, deno.lock committed.
- Fail-fast env validation per PLAN 6.3, Log wrapper with no PII API, health endpoint, generic errors, shutdown handlers, localhost metrics.
- Minimal permission flags, no write/run/ffi/sys.
- CI server job added with pinned setup-deno.
- Verified: deno fmt/lint/check clean, 5 tests pass, live boot serves health and metrics, invalid env refuses.

## 3. Acceptance criteria (from PLAN T06)

- Server boots with minimal permissions; invalid env refuses to start.

## 4. Verify

1. `deno fmt --check`, `deno lint`, `deno check src/main.ts` clean (in `server/`).
2. `deno task test` passes.
3. Live boot serves `/v1/health` and metrics; bad env exits non-zero.

## 5. Rules

- One logical change only. No DB, auth, or engine code (T07 onward).
- Docs English. No em dashes. Commit: `feat: add server skeleton (T06)`.

## 6. Next

T07 (migration 0001 plus repositories plus app_config loader plus no_location_at_rest test). Needs local PostgreSQL via Docker; staging/prod VPS work stays blocked on owner.
