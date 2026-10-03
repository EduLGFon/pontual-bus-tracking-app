# step.md - Current step: T20 networking base

Status: done 2026-10-03. Next: T21. Blocked: real route traces, Pages
project/DNS/secrets, VPS provisioning/deploys need the owner.

## 1. What T20 is

PLAN.md section 16, Milestone M3. Deliverable: data/net HTTP client
(keep-alive, timeouts) plus BusApi base plus token storage and
registration on demand.

## 2. Done 2026-10-03

- Keep-alive factory with web conditional import, env.dart, token store,
  BusApi with lazy single registration.
- Verified: analyze clean, 16 tests pass, manifest audit clean, web build
  compiles.

## 3. Acceptance criteria (from PLAN T20)

- Cold start unaffected with first frame never on network; one
  registration per install, only when sharing.

## 4. Verify

1. `flutter analyze` clean in app/.
2. `flutter test` passes in app/.

## 5. Rules

- One logical change only. No typed endpoint wrappers (T21).
- Docs English. No em dashes. Commit: `feat: add networking base (T20)`.

## 6. Next

T21 (BusApi typed wrappers plus DTOs plus error mapping, fake plus
real contract tests).
