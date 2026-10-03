# step.md - Current step: T29 trip domain

Status: done 2026-10-03. Next: T30. Blocked: real route traces, Pages
project/DNS/secrets, VPS provisioning/deploys need the owner.

## 1. What T29 is

PLAN.md section 16, Milestone M5. Deliverable: domain/trip with TripState,
TripReducer, SamplingPolicy, AutoEndPolicy (pure) plus tests.

## 2. Done 2026-10-03

- Sealed state machine with total reducer and illegal-event tolerance.
- Sampling modes with hysteresis; auto-end with priority order.
- Verified: analyze clean, 62 tests pass, manifest audit clean.

## 3. Acceptance criteria (from PLAN T29)

- All transitions covered.

## 4. Verify

1. `flutter analyze` clean in app/.
2. `flutter test` passes in app/.

## 5. Rules

- One logical change only. No consent or permission UI (T30).
- Docs English. No em dashes. Commit: `feat: add trip domain (T29)`.

## 6. Next

T30 (S06 consent plus S07 permission flows plus consent versioning).
