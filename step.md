# step.md - Current step: T07 database

Status: done 2026-10-02. Next: T08. T04 and T05 blocked on owner infra answers.

## 1. What T07 is

PLAN.md section 16, Milestone M1. Deliverable: migration 0001 (tables, roles and grants), dbmate setup, repositories (devices, consents, blocked, appConfig), app_config loader with 30 s refresh contract, no_location_at_rest test.

## 2. Done 2026-10-02

- Migration `0001_init.sql` with dbmate up and down blocks; least-privilege grants to pontual_app; no coordinate columns.
- Repositories with parameterized queries scoped by device id or token hash.
- Runtime config loader with compiled defaults and app_config overrides.
- Tests: config, health, no_location_at_rest, plus DB integration (devices, consents, blocked, purge, runtime config).
- CI server job runs postgres:16 service, dbmate migrate, deno task test.
- Verified: migrate applies to clean DB, 11 tests pass, fmt/lint/check clean.

## 3. Acceptance criteria (from PLAN T07)

- Migrations apply to a clean DB; AC22 passes.

## 4. Verify

1. `dbmate -d ./db/migrations up` on a clean DB.
2. `deno task test` passes (needs TEST_DATABASE_URL).
3. `deno fmt --check`, `deno lint`, `deno check src/main.ts` clean.

## 5. Rules

- One logical change only. No auth middleware or engine code (T08 onward).
- Docs English. No em dashes. Commit: `feat: add database layer (T07)`.

## 6. Next

T08 (security middleware plus device, consent, and delete endpoints). Schema library choice (Valibot vs Zod) lands there.
