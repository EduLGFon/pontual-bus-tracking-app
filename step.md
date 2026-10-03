# step.md - Current step: T30 consent flows

Status: done 2026-10-03. Next: T31. Blocked: real route traces, Pages
project/DNS/secrets, VPS provisioning/deploys need the owner.

## 1. What T30 is

PLAN.md section 16, Milestone M5. Deliverable: S06 consent plus S07
permission flows plus consent versioning (local plus POST /v1/consents).

## 2. Done 2026-10-03

- ConsentSheet, permission sheets, PermissionGateway interface,
  ConsentStore, offline-tolerant ensureConsent flow.
- Verified: analyze clean, 69 tests pass, manifest audit clean.

## 3. Acceptance criteria (from PLAN T30)

- Cannot start a trip without consent; denied/permanent-denied states.

## 4. Verify

1. `flutter analyze` clean in app/.
2. `flutter test` passes in app/.

## 5. Rules

- One logical change only. No location service (T31).
- Docs English. No em dashes. Commit: `feat: add consent flows (T30)`.

## 6. Next

T31 (LocationService: geolocator stream, foreground service,
notification, filters, mode switching with hysteresis).
