# step.md - Current step: T24 home screen

Status: done 2026-10-03. Next: T25. Blocked: real route traces, Pages
project/DNS/secrets, VPS provisioning/deploys need the owner.

## 1. What T24 is

PLAN.md section 16, Milestone M4. Deliverable: S02 Welcome plus S03 Home
with search, list, and live indicators via GET /v1/live.

## 2. Done 2026-10-03

- Providers wiring features to data with test overrides.
- HomeScreen with local search, cached list, live dots, footnote.
- Router serves the real home; welcome keeps final copy.
- Verified: analyze clean, 37 tests pass, manifest audit clean.

## 3. Acceptance criteria (from PLAN T24)

- No spinners on cached content; live dots appear.

## 4. Verify

1. `flutter analyze` clean in app/.
2. `flutter test` passes in app/.

## 5. Rules

- One logical change only. No timetables tab (T25).
- Docs English. No em dashes. Commit: `feat: add home screen (T24)`.

## 6. Next

T25 (S05 timetables tab: day types, origin selector, next departure,
disclaimer).
