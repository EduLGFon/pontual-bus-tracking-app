# step.md - Current step: T33 trip controller

Status: done 2026-10-03. Next: T34. Blocked: real route traces, Pages
project/DNS/secrets, VPS provisioning/deploys, staging E2E need owner.

## 1. What T33 is

PLAN.md section 16, Milestone M5. Deliverable: TripController wiring
plus S08 trip screen plus S09 end states plus Android notification.

## 2. Done 2026-10-03

- Controller with consent, permission, register, first-fix start, ping
  loop, role updates, auto-end, best-effort end.
- S08 screen with ticker plus role rows plus Desci; S09 end cards.
- Notification is the geolocator foreground notification (tap opens app;
  no action button exists per S1).
- Verified: analyze clean, 82 tests pass, manifest audit clean, local E2E
  on bundle data green.

## 3. Acceptance criteria (from PLAN T33)

- Solo ride works end-to-end on the staging server. Staging is
  owner-blocked; local-server E2E passes instead.

## 4. Verify

1. `flutter analyze` clean in app/.
2. `flutter test` passes in app/.

## 5. Rules

- One logical change only. No auto-end extras (T34).
- Docs English. No em dashes. Commit: `feat: add trip controller (T33)`.

## 6. Next

T34 (auto-end plus RF16 prompt plus offline saver plus GPS-off and
permission-revoked handling).
