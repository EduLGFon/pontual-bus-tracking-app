# step.md - progress past T37

Status 2026-10-03: T38 through T50 done except T46 (8-hour soak
running in background, completes about 21:30 UTC) and owner-blocked
items. T37 browser and on-device checks stay parked for a capable
machine (this host has no usable browser, no phones, no Android
SDK). Full suites green at each commit: client 131, server 67.

## Done since T37

- T38 web sharing (wake lock, banner, 60 s hidden pause).
- T39 iOS install hint. T40 settings plus about. T41 privacy
  center with delete-my-data end-to-end. T42 privacy docs (policy,
  terms, RIPD-lite, inventory).
- T43 security review (`docs/security/review-alpha.md`, no open
  P0/P1 in code). T44 budgets (`docs/field-tests/budgets.md`,
  device items TODO). T45 release hardening (R8 flags,
  allowBackup=false, release-android.yml).
- T49 pilot kit. T50 ops runbooks plus a real kill-switch drill
  on an isolated instance.

## Still owner-blocked (unchanged)

Real route traces, Pages project/DNS/secrets, VPS
provisioning/deploys (T04/T05, `server/deploy/` empty), owner DB
role, staging E2E, real phones (T47), distribution (T48),
lawyer/DPO review, controller contact (INFRA-23), data licence
half of INFRA-19.

## Next

1. T46: collect the 8-hour soak result when it finishes.
2. T37 + device TODOs on the other machine (browser widget runs,
   web build smoke, AAB size, budgets table, merged manifest).
3. Hand owner-blocked list to the owner.
