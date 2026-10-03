# step.md - Current step: T31 location service

Status: done 2026-10-03. Next: T32. Blocked: real route traces, Pages
project/DNS/secrets, VPS provisioning/deploys need the owner.

## 1. What T31 is

PLAN.md section 16, Milestone M5. Deliverable: LocationService with
geolocator stream, foreground service, notification, filters, mode
switching with hysteresis.

## 2. Done 2026-10-03

- Pure acceptFix filter, rounding, per-mode settings, gateway.
- Manifest permissions per PLAN 8.6 with no forbidden entries.
- Verified: analyze clean, 73 tests pass, manifest audit clean.

## 3. Acceptance criteria (from PLAN T31)

- S1 criteria in real device; manifest audit passes. Device half stays
  VERIFY for T47; audit passes here.

## 4. Verify

1. `flutter analyze` clean in app/.
2. `flutter test` passes in app/.

## 5. Rules

- One logical change only. No ping client (T32).
- Docs English. No em dashes. Commit: `feat: add location service (T31)`.

## 6. Next

T32 (PingClient: seq, in-flight 1, latest-wins, backoff plus jitter, 401
refresh, server codes).
