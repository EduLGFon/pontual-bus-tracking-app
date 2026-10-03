# step.md - Current step: T15 line seed

Status: done 2026-10-03. Next: T16. T04 and T05 blocked on owner infra answers.

## 1. What T15 is

PLAN.md section 16, Milestone M2. Deliverable: seed pilot lines (owner set
D25) and list all 21 urban line names with data/sources.md.

## 2. Done 2026-10-03

- 21 line files in data/lines/, 4 pilot with timetables, 17 names-only.
- Sources recorded with VERIFY flags.
- Verified: validator passes, bundle 8.6 KB, trip start on bundle line live.

## 3. Acceptance criteria (from PLAN T15)

- Validator passes; sources recorded.

## 4. Verify

1. `deno task data-validate` passes in tools/.
2. Bundle builds within budget.

## 5. Rules

- One logical change only. No Pages deploy (T16) or route geometry (T17).
- Docs English. No em dashes. Commit: `feat: seed urban lines (T15)`.

## 6. Next

T16 (Cloudflare Pages deploy of build/ plus _headers). Needs Cloudflare
account and DNS decisions (INFRA-05, INFRA-06); if blocked, continue with
T17 tool (route geometry code) while route traces await owner field rides.
