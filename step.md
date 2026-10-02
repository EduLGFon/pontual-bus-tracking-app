# step.md - Current step: T08 security middleware

Status: done 2026-10-02. Next: T09. T04 and T05 blocked on owner infra answers.

## 1. What T08 is

PLAN.md section 16, Milestone M1. Deliverable: security middleware (request id, secure headers, body limit, content-type, CORS, IP resolution, in-memory rate limiter, bearer auth with hash lookup and cache, error handler) plus POST /v1/devices, POST /v1/consents, DELETE /v1/me.

## 2. Done 2026-10-02

- Valibot 1.5.0 MIT via JSR for strict boundary schemas.
- Token, client IP, rate limiter, cached auth middleware.
- Account routes with per-IP and global registration caps.
- Security tests for AC01, AC03, AC11, AC13, AC18, AC23.
- Verified: 17 tests pass, fmt/lint/check clean, live register/consent/delete flow via curl.

## 3. Acceptance criteria (from PLAN T08)

- AC01, AC03, AC11, AC13, AC18, AC23 pass.

## 4. Verify

1. `deno task test` passes (needs TEST_DATABASE_URL).
2. `deno fmt --check`, `deno lint`, `deno check src/main.ts` clean.
3. Live boot flow via curl.

## 5. Rules

- One logical change only. No trip engine code (T09 onward).
- Docs English. No em dashes. Commit: `feat: add security middleware and account routes (T08)`.

## 6. Next

T09 (pure engine: geo helpers, validation, plausibility, startTrip, applyPing, endTrip, tick, snapshot builder, in-memory store, event bus).
