# step.md - Current step: T35 two-device test

Status: T34 done 2026-10-03. Next: T35. Blocked: real route traces, Pages
project/DNS/secrets, VPS provisioning/deploys, staging E2E need owner.

## 1. What T34 delivered

PLAN.md section 16, Milestone M5. Auto-end plus RF16 prompt plus offline
saver plus GPS-off and permission-revoked handling.

- TripSupervisor (health tracking plus round evaluation) plus
  TripController wiring (state transitions plus sampling).
- S08 status rows are live (offline, paused, role) plus the RF16 dialog
  plus S09 walking and GPS end messages.
- Fixes from testing: first-fix handoff no longer kills the position
  stream; requestMode recreates the stream with hysteresis.
- Verified: analyze clean, 102 tests pass (20 new), manifest audit
  clean, no new permissions or dependencies.

## 2. Acceptance criteria (from PLAN T35)

- Two-device test with simulator plus real phones: leader hand-over,
  promotion latency measured.
- Meets alpha criteria 2-3 or documented.

## 3. Verify

1. `flutter analyze` clean in app/.
2. `flutter test` passes in app/.

## 4. Rules

- One logical change only. No M6 web work.
- Docs English. No em dashes. Commit: `feat: add trip auto-end and offline saver (T34)`.
- T34 commit is pending; include it in the T34 change set or commit now.

## 5. Next

T35 (two-device hand-over test with simulator plus real phones).
Staging owner-blocked; local-server runs first.
