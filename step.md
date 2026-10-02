# step.md - Current step: T02 Flutter shell

Status: done 2026-10-02. Next: T03. Do not start spikes until T03 passes per PLAN critical path (S1, S2 before T06).

## 1. What T02 is

PLAN.md section 16, Milestone M0. Deliverable: `flutter create` (Android and Web only), applicationId `com.spotnik.pontual` per D22, Flutter version pin, `analysis_options.yaml` per PLAN 14.2, empty `ProviderScope` app, minimal Android manifest.

## 2. Done 2026-10-02

- Ran `flutter create --org com.spotnik --project-name pontual --platforms=android,web --empty app` with Flutter 3.47.6.
- Pinned Flutter 3.47.6 via `.fvmrc` (CI pin lands in T03, see INFRA-22).
- Added `flutter_riverpod 3.4.3` only (PLAN 8.2 allow-list, no ADR needed).
- Strict analyzer per PLAN 14.2 with `strict-casts`, `strict-inference`, `strict-raw-types` plus required lint rules.
- Empty `ProviderScope` app in `app/lib/main.dart` with no network on first paint per PLAN 8.4.
- Smoke widget test in `app/test/app_test.dart`.
- T01 fix included in same window: restored `app/` skeleton directory (was misplaced as `docs/app/`).
- Verified: `flutter analyze` clean, `flutter test` passes, manifest audit clean (no forbidden permissions), secret scan clean (only example dummy plus spec text), no em dashes.

## 3. Acceptance criteria (from PLAN T02)

- `flutter analyze` plus `flutter test` pass.
- Merged manifest has only allowed permissions (PLAN 8.6).

## 4. Verify (run in this order, record output in the PR)

1. `flutter analyze` clean.
2. `flutter test` passes.
3. `grep -rn uses-permission app/android` shows only INTERNET in debug/profile, none forbidden.
4. `git status --short` shows only T02 files.
5. Secret scan shows no real secrets.

## 5. Rules for this step

- One logical change only. No map, location, battery, or networking code.
- Docs language English. No em dashes. Conventional commit: `feat: add Flutter shell (T02)`.

## 6. Next step after T02 passes

T03 (CI: analyze, format check, tests, size report, manifest audit, gitleaks), then S1 and S2 spikes in parallel before T06. T04 and T05 need owner infra answers (INFRA-01 to INFRA-12) and cannot complete without them.
