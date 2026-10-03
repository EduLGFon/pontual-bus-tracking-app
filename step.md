# step.md - Current step: T09 pure engine

Status: done 2026-10-02. Next: T10. T04 and T05 blocked on owner infra answers.

## 1. What T09 is

PLAN.md section 16, Milestone M1. Deliverable: pure engine with geo helpers, validation, plausibility, startTrip, applyPing (attach, coherence, idle, roles, hand-over), endTrip, tick, snapshot builder, in-memory store, event bus.

## 2. Done 2026-10-02

- Domain files: types, geo, validate, attach, election, ping, tick, snapshot. Store in state/store.ts.
- Engine tests 1-18 and 20-24 pass (23 tests, fake clock, deterministic).
- Full suite 40 tests green; fmt, lint, check clean.
- Dead-leader replacement prefers fresh members (recorded in DECISIONS.md).

## 3. Acceptance criteria (from PLAN T09)

- Engine unit tests 1-18, 20-24 pass.

## 4. Verify

1. `deno task test` passes (needs TEST_DATABASE_URL).
2. `deno fmt --check`, `deno lint`, `deno check src/main.ts` clean.

## 5. Rules

- One logical change only. No HTTP wiring (T10) or jobs (T11).
- Docs English. No em dashes. Commit: `feat: add pure trip engine (T09)`.

## 6. Next

T10 (trip endpoints POST /v1/trip, /v1/trip/ping, DELETE /v1/trip wired to the engine with quotas, capacity, resume, kill switch).
