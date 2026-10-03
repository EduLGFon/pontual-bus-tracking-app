# step.md - Current step: T18 app foundation

Status: done 2026-10-03. Next: T19. Blocked: real route traces, Pages
project/DNS/secrets, VPS provisioning/deploys need the owner.

## 1. What T18 is

PLAN.md section 16, Milestone M3. Deliverable: theme tokens, light/dark,
strings_pt.dart, router skeleton with all routes as placeholders.

## 2. Done 2026-10-03

- Material 3 tokens, pt-BR strings, go_router with ten alpha routes.
- Welcome copy final; other screens are placeholders.
- Scale test caught and fixed a welcome overflow.
- Verified: analyze clean, 3 widget tests pass, manifest audit clean.

## 3. Acceptance criteria (from PLAN T18)

- Screens navigable; 200 percent text scale ok.

## 4. Verify

1. `flutter analyze` clean in app/.
2. `flutter test` passes in app/.

## 5. Rules

- One logical change only. No business logic in widgets (T19 onward).
- Docs English. No em dashes. Commit: `feat: add app foundation (T18)`.

## 6. Next

T19 (core/: Clock, Log, geo helpers, backoff, Result/failures, plus unit
tests with 90 percent coverage on domain-adjacent pure code).
