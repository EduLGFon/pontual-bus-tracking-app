# step.md - Current step: T03 CI

Status: done 2026-10-02. Next: S1 and S2 spikes in parallel before T06. T04 and T05 need owner infra answers (INFRA-01 to INFRA-12) and cannot complete without them.

## 1. What T03 is

PLAN.md section 16, Milestone M0. Deliverable: CI with analyze, format check, tests, size report, manifest audit, gitleaks (server job added in T06).

## 2. Done 2026-10-02

- Created `.github/workflows/ci.yml` with actions pinned by SHA and `permissions: contents: read`.
- Flutter job: analyze, format check, test, manifest audit, web size report.
- Gitleaks job on full history.
- Deno job deferred to T06 per PLAN.
- Scripts in `tools/ci/`: `manifest_audit.sh` (forbidden permission check), `size_report.sh` (report only).
- Verified locally: `flutter analyze` clean, `flutter test` passes, manifest audit PASS, `ci.yml` YAML parses, web build measured 40 MB uncompressed (canvaskit dominated, needs S4).

## 3. Acceptance criteria (from PLAN T03)

- Green on empty app.

## 4. Verify (run in this order, record output in the PR)

1. `flutter analyze` clean (in `app/`).
2. `dart format --set-exit-if-changed lib test` clean.
3. `flutter test` passes.
4. `bash tools/ci/manifest_audit.sh` PASS.
5. `ci.yml` YAML parses; actions pinned by SHA.

## 5. Rules for this step

- One logical change only. No app logic, no server code, no new dependencies.
- Docs language English. No em dashes. Conventional commit: `chore: add CI pipeline (T03)`.

## 6. Next step after T03 passes

S1 and S2 spikes in parallel before T06 (PLAN critical path). T04 and T05 blocked on owner infra answers. M1 backend (T06 onward) can proceed locally once S2 closes.
