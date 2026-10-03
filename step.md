# step.md - Current step: T25 timetables tab

Status: done 2026-10-03. Next: T26. Blocked: real route traces, Pages
project/DNS/secrets, VPS provisioning/deploys need the owner.

## 1. What T25 is

PLAN.md section 16, Milestone M4. Deliverable: S05 Horários tab with day
types, origin selector, next departure, disclaimer.

## 2. Done 2026-10-03

- Pure schedule helpers plus ScheduleTab plus LineScreen with tabs.
- Router serves the real line screen; map tab is a placeholder to T26/T28.
- Verified: analyze clean, 43 tests pass, manifest audit clean.

## 3. Acceptance criteria (from PLAN T25)

- Correct for all day types; offline.

## 4. Verify

1. `flutter analyze` clean in app/.
2. `flutter test` passes in app/.

## 5. Rules

- One logical change only. No map widget (T26).
- Docs English. No em dashes. Commit: `feat: add timetables tab (T25)`.

## 6. Next

T26 (map widget: TileSource, OSM compliance, capped cache, bounds,
attribution; S3 results applied).
