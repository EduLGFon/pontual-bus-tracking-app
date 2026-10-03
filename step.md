# step.md - Current step: T17 route tool

Status: partial 2026-10-03 (tool done). Next: M3 client foundation (T18).
Blocked: real route traces need owner field rides; Pages project, DNS, and
secrets need the owner; VPS provisioning and deploys need the owner.

## 1. What T17 is

PLAN.md section 16, Milestone M2. Deliverable: route tool with GPX/GeoJSON
to encoded polyline plus route file loaded by the server.

## 2. Done 2026-10-03

- Converter with 5 m simplification, 1000-point cap, 8 KB polyline budget.
- Builder encodes routes into the bundle and manifest; server decodes.
- Verified on synthetic traces with unit tests; 67 server tests pass.

## 3. Acceptance criteria (from PLAN T17)

- Polyline under 8 KB per line: met by construction and enforced by the tool.

## 4. Verify

1. `deno task route-test` and `data-test` pass in tools/.
2. `deno task test` passes in server/.

## 5. Rules

- One logical change only. No real traces committed.
- Docs English. No em dashes. Commit: `feat: add route geometry tool (T17)`.

## 6. Next

M3 client foundation: T18 (theme tokens, light/dark, strings_pt, router
skeleton), T19 (core utilities plus tests), T20-T23 (networking, API,
static data, remote config). Backend M1 and data M2 are complete except
owner-blocked deploys and traces.
