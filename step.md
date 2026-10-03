# step.md - Current step: T22 static repository

Status: done 2026-10-03. Next: T23. Blocked: real route traces, Pages
project/DNS/secrets, VPS provisioning/deploys need the owner.

## 1. What T22 is

PLAN.md section 16, Milestone M3. Deliverable: StaticDataRepository with
bundle first, cache, conditional GET, atomic swap.

## 2. Done 2026-10-03

- Repository with offline-first lines(), daily conditional refresh(),
  versioned atomic swap, bundled assets in app/assets/data/.
- Tests for bundle-first, 304, swap, corrupt-remote, throttle.
- Verified: analyze clean, 27 pass with 1 live-skip, manifest audit clean.

## 3. Acceptance criteria (from PLAN T22)

- Offline first run shows lines.

## 4. Verify

1. `flutter analyze` clean in app/.
2. `flutter test` passes in app/.

## 5. Rules

- One logical change only. No remote config handling (T23).
- Docs English. No em dashes. Commit: `feat: add static data repository (T22)`.

## 6. Next

T23 (remote config.json handling plus S13/S14 maintenance, update
required, offline banner).
