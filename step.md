# step.md - Current step: T21 typed API

Status: done 2026-10-03. Next: T22. Blocked: real route traces, Pages
project/DNS/secrets, VPS provisioning/deploys need the owner.

## 1. What T21 is

PLAN.md section 16, Milestone M3. Deliverable: BusApi typed wrappers plus
DTOs plus error mapping (fake plus real contract tests).

## 2. Done 2026-10-03

- DTOs plus typed methods for all ten endpoints with error mapping.
- Fake mapping tests plus live contract test (skipped without BUS_API_BASE).
- Live run caught and fixed a DELETE-as-GET client bug.
- Verified: analyze clean, 21 pass with 1 live, manifest audit clean.

## 3. Acceptance criteria (from PLAN T21)

- Contract tests versus the local server.

## 4. Verify

1. `flutter analyze` clean in app/.
2. `flutter test` passes; live contract with BUS_API_BASE set.

## 5. Rules

- One logical change only. No static data repository (T22).
- Docs English. No em dashes. Commit: `feat: add typed API wrappers (T21)`.

## 6. Next

T22 (StaticDataRepository: bundle first, then cache, conditional GET,
atomic swap).
