# step.md - Current step: T23 remote flags

Status: done 2026-10-03. Next: T24. Blocked: real route traces, Pages
project/DNS/secrets, VPS provisioning/deploys need the owner.

## 1. What T23 is

PLAN.md section 16, Milestone M3. Deliverable: remote config.json
handling plus S13/S14 (maintenance, update required, offline banner).

## 2. Done 2026-10-03

- RemoteConfig repository with bundle/cache/daily refresh and version compare.
- SystemScreen variants plus OfflineBanner with semantics.
- Bundled config.json asset.
- Verified: analyze clean, 33 tests pass, manifest audit clean.

## 3. Acceptance criteria (from PLAN T23)

- Simulated flags show screens; timetables remain usable.

## 4. Verify

1. `flutter analyze` clean in app/.
2. `flutter test` passes in app/.

## 5. Rules

- One logical change only. No viewing screens (M4).
- Docs English. No em dashes. Commit: `feat: add remote flags and system screens (T23)`.

## 6. Next

M4 viewing: T24 (welcome plus home with search, list, live indicators),
T25 (timetables tab), T26 (map widget), T27 (vehicle repository), T28
(map tab).
