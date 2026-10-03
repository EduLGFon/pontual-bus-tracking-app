# step.md - Current step: T19 client core

Status: done 2026-10-03. Next: T20. Blocked: real route traces, Pages
project/DNS/secrets, VPS provisioning/deploys need the owner.

## 1. What T19 is

PLAN.md section 16, Milestone M3. Deliverable: core/ (Clock, Log, geo
helpers, backoff, Result/failures) plus unit tests.

## 2. Done 2026-10-03

- Clock, Log, geo, backoff, failures with full docs.
- 9 core unit tests; 97.4 percent line coverage on core.
- Verified: analyze clean, 12 tests pass.

## 3. Acceptance criteria (from PLAN T19)

- Coverage 90 percent or better on the pure core code.

## 4. Verify

1. `flutter analyze` clean in app/.
2. `flutter test --coverage` passes; core total over 90 percent.

## 5. Rules

- One logical change only. No networking code (T20 onward).
- Docs English. No em dashes. Commit: `feat: add client core utilities (T19)`.

## 6. Next

T20 (data/net HTTP client with keep-alive and timeouts plus BusApi base
plus token storage and registration on demand).
