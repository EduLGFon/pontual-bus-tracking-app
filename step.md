# step.md - Current step: T32 ping sender

Status: done 2026-10-03. Next: T33. Blocked: real route traces, Pages
project/DNS/secrets, VPS provisioning/deploys need the owner.

## 1. What T32 is

PLAN.md section 16, Milestone M5. Deliverable: PingClient with seq,
in-flight 1, latest-wins, backoff plus jitter, 401 refresh, server codes.

## 2. Done 2026-10-03

- PingClient with injected sender, clock-free delays, and outcomes.
- Tests for success, backoff ladder, 401 refresh, latest-wins, end codes.
- Verified: analyze clean, 78 tests pass, manifest audit clean.

## 3. Acceptance criteria (from PLAN T32)

- Tests per 15.3.

## 4. Verify

1. `flutter analyze` clean in app/.
2. `flutter test` passes in app/.

## 5. Rules

- One logical change only. No trip controller wiring (T33).
- Docs English. No em dashes. Commit: `feat: add ping sender (T32)`.

## 6. Next

T33 (TripController wiring plus S08 trip screen plus S09 end states plus
Android notification).
