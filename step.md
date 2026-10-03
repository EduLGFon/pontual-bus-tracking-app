# step.md - Parked: T37 browser and device checks

Status: T36 done 2026-10-03 (manifest rebrand, wasm dual build, size
inside budget, full suite 107 green). T35 local done (real phones with
T47). T37 viewer code is platform-clean, but browser and on-device
verification moves to another machine (owner todo).

## 1. Why parked

This host has no usable browser (only an uninstalled snap stub, so
`flutter test --platform chrome` cannot run) and no phones. Per owner
instruction, browser and native app tasks wait for a capable machine.

## 2. Verify path on the other machine

1. `flutter analyze` clean in app/.
2. `flutter test` passes in app/.
3. Viewer widget tests on desktop Chrome
   (`flutter test --platform chrome` with `CHROME_EXECUTABLE` set).
4. Web release build compiles (`--no-web-resources-cdn --wasm`).
5. iOS Safari plus Android Chrome smoke of map, list, timetables.

## 3. Rules (when resumed)

- One logical change only. No T38 sharing work inside T37.
- Docs English. No em dashes. Commit per task when green.

## 4. Next

T37 (web viewer parity on the other machine), then T38 (web sharing
foreground only). Owner-blocked items unchanged: real route traces,
Pages project/DNS/secrets, VPS provisioning/deploys, owner DB role,
staging E2E, real phones.
