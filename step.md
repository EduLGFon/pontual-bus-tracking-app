# step.md - Current step: T26 map widget

Status: done 2026-10-03. Next: T27. Blocked: real route traces, Pages
project/DNS/secrets, VPS provisioning/deploys need the owner.

## 1. What T26 is

PLAN.md section 16, Milestone M4. Deliverable: map widget with TileSource,
OSM compliance, capped cache, bounds, attribution.

## 2. Done 2026-10-03

- TileSource seam plus PontualMap with attribution and RepaintBoundary.
- flutter_map 8.3.2 plus latlong2 0.10.1 (allow-list, no ADR needed).
- Verified: analyze clean, 45 tests pass, manifest audit clean.

## 3. Acceptance criteria (from PLAN T26)

- Perf budget; attribution visible.

## 4. Verify

1. `flutter analyze` clean in app/.
2. `flutter test` passes in app/.

## 5. Rules

- One logical change only. No vehicle stream (T27).
- Docs English. No em dashes. Commit: `feat: add map widget (T26)`.

## 6. Next

T27 (VehicleRepository: snapshot, WebSocket stream, watchdog, polling
fallback, lifecycle).
