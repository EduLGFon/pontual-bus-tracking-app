# step.md - Current step: T13 simulator

Status: done 2026-10-02. Next: T14. T04 and T05 blocked on owner infra answers.

## 1. What T13 is

PLAN.md section 16, Milestone M1. Deliverable: Deno simulator tools/sim (buses, riders, abuse scenarios, latency report) using real HTTP and WebSocket against the local/staging server.

## 2. Done 2026-10-02

- Simulator with deterministic seed, role tracking, WS viewer, abuse mode (localhost only), JSON report.
- Position updates broadcast immediately on ping (found by the first run).
- CI runs tools fmt/lint plus a 60 s sim smoke against the postgres service.
- Verified: 75 s and 45 s runs clean with hand-overs, snapshots, p50 4 ms.

## 3. Acceptance criteria (from PLAN T13)

- 30-min run, metrics printed, no errors. Short runs pass here; the full 30-min run and 8-hour soak land in T46.

## 4. Verify

1. `deno task test` passes in server/ (needs TEST_DATABASE_URL).
2. Boot with LINES_JSON plus migrate, run sim, confirm clean report.

## 5. Rules

- One logical change only. No static data files (T14/T15).
- Docs English. No em dashes. Commit: `feat: add driver simulator (T13)`.

## 6. Next

M2 static data: T14 (JSON Schema plus validator plus builder), T15 (seed pilot lines per D25 plus all 21 urban line names), T16 (Pages deploy), T17 (route tool).
