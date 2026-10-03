# step.md - Current step: T14 static data pipeline

Status: done 2026-10-03. Next: T15. T04 and T05 blocked on owner infra answers.

## 1. What T14 is

PLAN.md section 16, Milestone M2. Deliverable: JSON Schema plus validator plus builder (lines hash file, manifest.json, config.json, server data bundle).

## 2. Done 2026-10-03

- Schemas in data/schema/ for line, manifest, and config files.
- Validator plus builder in tools/data with schema-driven structure checks and semantic checks.
- Server bundle loader with LINES_JSON fallback.
- CI data job with fmt, lint, tests, validation, build, size gate.
- Verified: tool tests pass, empty set builds within budget, bundle endpoints serve live, 66 server tests pass.

## 3. Acceptance criteria (from PLAN T14)

- CI validates; size under 100 KB.

## 4. Verify

1. `deno task data-test`, `data-validate`, `data-build` pass in tools/.
2. `deno task test` passes in server/.
3. Bundle endpoints serve the built data.

## 5. Rules

- One logical change only. No line content (T15) or Pages deploy (T16).
- Docs English. No em dashes. Commit: `feat: add static data pipeline (T14)`.

## 6. Next

T15 (seed pilot lines per D25 plus list all 21 urban line names with sources). Needs timetable research from public sources; route traces need owner rides (T17 may block on that).
