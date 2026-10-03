# step.md - Current step: T16 static deploy

Status: partial 2026-10-03 (repo side done). Next: T17. Blocked: Pages
project, DNS, and secrets need the owner (INFRA-05, INFRA-06). T04 and T05
blocked on owner infra answers.

## 1. What T16 is

PLAN.md section 16, Milestone M2. Deliverable: Cloudflare Pages deploy of
build/ plus _headers.

## 2. Done 2026-10-03

- Builder writes build/_headers per PLAN 12.5 with env API origin.
- deploy-static.yml builds data plus web (no-CDN) and deploys via pinned
  wrangler-action to project pontual with environment static-prod.
- Builder test asserts manifest/config revalidation rules.
- Verified: tools tests pass, _headers content checked, YAML parses.

## 3. Still owner-blocked

Pages project creation, DNS, CLOUDFLARE_API_TOKEN, CLOUDFLARE_ACCOUNT_ID,
API_ORIGIN production value, vars.API_ORIGIN. Live ETag revalidation
against Pages stays VERIFY after the owner connects the project.

## 4. Verify

1. `deno task data-test` passes in tools/.
2. `build/_headers` contains the CSP and no-cache rules.

## 5. Rules

- One logical change only. No route geometry (T17).
- Docs English. No em dashes. Commit: `feat: add static deploy files (T16)`.

## 6. Next

T17 (route tool: GPX/GeoJSON to encoded polyline plus route file loaded by
the server). Geometry traces need owner field rides; the tool itself is
buildable and testable on synthetic input now.
