# step.md - Current step: T27 vehicle stream

Status: done 2026-10-03. Next: T28. Blocked: real route traces, Pages
project/DNS/secrets, VPS provisioning/deploys need the owner.

## 1. What T27 is

PLAN.md section 16, Milestone M4. Deliverable: VehicleRepository with
snapshot, WebSocket stream, watchdog, polling fallback, lifecycle.

## 2. Done 2026-10-03

- Repository with injectable fetcher, channel, clock, launcher.
- Fake channel tests for snapshot, stream, watchdog, polling, stop, ages.
- Verified: analyze clean, 51 tests pass, manifest audit clean.

## 3. Acceptance criteria (from PLAN T27)

- Tests per 15.3; reconnect works with airplane toggle. Airplane-toggle
  behavior follows from socket-down plus polling plus resync paths covered
  here; field verification lands in T47.

## 4. Verify

1. `flutter analyze` clean in app/.
2. `flutter test` passes in app/.

## 5. Rules

- One logical change only. No map tab UI (T28).
- Docs English. No em dashes. Commit: `feat: add vehicle stream (T27)`.

## 6. Next

T28 (S04 Mapa tab: markers, list rows, status row states, recenter,
route polyline).
