# step.md - Current step: T37 web viewer parity

Status: T36 done 2026-10-03 (manifest rebrand, wasm dual build, size
inside budget, full suite 107 green). T35 local done earlier (real
phones with T47). Blocked: real route traces, Pages project/DNS/
secrets, VPS provisioning/deploys, owner DB role, staging E2E.

## 1. What T36 delivered

PLAN.md section 16, Milestone M6. Web build config.

- PWA manifest rebranded (Pontual, #0B6E4F); title tags fixed.
- Deploy builds `--no-web-resources-cdn --wasm`; iOS keeps JS fallback.
- First load gzipped about 2.6 MB (wasm) / 2.9 MB (JS fallback).
- CSP strict unchanged; web uses fallback fonts (Google blocked).
- Test repairs inside T36: rig microtask yield, hermetic share tests,
  dispose guard for late outcomes.

## 2. Acceptance criteria (from PLAN T37)

- Web viewer parity (map, list, timetables).
- Works on iOS Safari plus Chrome Android.

## 3. Verify

1. `flutter analyze` clean in app/.
2. `flutter test` passes in app/.
3. Web build compiles; viewer flows covered by widget tests.

## 4. Rules

- One logical change only. No T38 sharing work inside T37.
- Docs English. No em dashes. Commit per task when green.

## 5. Next

T37 (web viewer parity), then T38 (web sharing foreground only).
