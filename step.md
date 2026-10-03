# step.md - Current step: T28 map tab

Status: done 2026-10-03. Next: M5 trip sharing (T29). Blocked: real route
traces, Pages project/DNS/secrets, VPS provisioning/deploys need the owner.

## 1. What T28 is

PLAN.md section 16, Milestone M4. Deliverable: S04 Mapa tab with markers,
list rows, status row states, recenter, route polyline.

## 2. Done 2026-10-03

- MapTab with all status states, markers, TalkBack rows, recenter FAB,
  non-pilot note, share entry point, polyline support.
- LineScreen wires the real map tab with the tile URL provider.
- Verified: analyze clean, 55 tests pass, manifest audit clean.

## 3. Acceptance criteria (from PLAN T28)

- All states reachable in widget tests; TalkBack reads vehicle list.

## 4. Verify

1. `flutter analyze` clean in app/.
2. `flutter test` passes in app/.

## 5. Rules

- One logical change only. No trip sharing logic (M5).
- Docs English. No em dashes. Commit: `feat: add map tab (T28)`.

## 6. Next

M5 trip sharing on Android: T29 (domain trip state machine plus policies
plus tests), T30 (consent plus permission flows), T31 (LocationService),
T32 (PingClient), T33 (TripController plus trip screen), T34 (auto-end
plus offline saver), T35 (two-device test).
