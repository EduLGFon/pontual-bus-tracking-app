# DECISIONS.md

Append-only record of architecture decisions (ADRs), spike results, and
deviations from PLAN.md. PLAN.md is the build contract. This file records what
was decided, why, and what is still pending.

Conventions:

- Status: `Accepted`, `Proposed`, `Pending owner`, `Superseded`.
- IDs `D01-D21` are imported from PLAN.md v1.1 section 2 and are `Accepted`
  unless noted.
- New deviations use the next `Dxx` number. Pending infra questions use
  `INFRA-xx` until the owner decides, then they become `Dxx`.
- Spikes use `S1-S4` from PLAN.md section 16.
- No em dashes in this repo. Use hyphens.
- Language: English.

## 1. Imported decisions (PLAN.md v1.1, Accepted)

These are binding per PLAN.md section 2. Summarized here so builders do not need
to re-derive them.

| ID  | Decision                                                                                                    | Why (short)                                                    |
| --- | ----------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------- |
| D01 | Use `geolocator` directly, not `smart_location`                                                             | Claimed features do not exist; wrapper is tiny and new         |
| D02 | No ping history, no location at rest                                                                        | LGPD minimization; location lives only in API memory           |
| D03 | Clients talk only to our Deno API, never to PostgreSQL                                                      | One enforcement point; stream cannot be spoofed                |
| D04 | Attach-at-ping online clustering with dead reckoning, pure TypeScript engine                                | Followers report rarely; windowed DBSCAN would split one bus   |
| D05 | Vehicle position is newest accepted fix, not centroid                                                       | Centroid of mixed-age fixes is biased backwards                |
| D06 | Role and interval returned in `ping` response; two-phase hand-over                                          | No extra connection; no gap at hand-over                       |
| D07 | Timetables are static versioned JSON, not a DB table                                                        | Zero DB load; cacheable; works offline                         |
| D08 | Server time only, no client `recorded_at`                                                                   | Client clocks are wrong or spoofable                           |
| D09 | Revised data budgets (leader <= ~0.15 MB/h, etc.)                                                           | Real HTTP header cost measured; old budget unreachable         |
| D10 | Consent (LGPD art. 7, I) for location sharing                                                               | Opt-in per trip; matches Play prominent disclosure             |
| D11 | No `ACCESS_BACKGROUND_LOCATION`; foreground service type `location` only                                    | Avoids strict Play review; more private; swipe ends trip       |
| D12 | OSM raster tiles via `flutter_map` cache, behind `TileSource` abstraction                                   | Light-use policy compliance; exit plan before Phase 2          |
| D13 | Compact JSON over WebSocket, not binary                                                                     | ~45 bytes per vehicle; binary only if spike proves gain        |
| D14 | Owner VPS with PostgreSQL, not Supabase                                                                     | Owner decision; R$0 recurring; owner operates host             |
| D15 | Read-only WebSocket stream served by API                                                                    | No client publish path; viewers need no login                  |
| D16 | Anonymous opaque device tokens (256-bit, SHA-256 hash stored, 30-day sliding expiry)                        | Small requests; instant revocation; nothing stored for viewers |
| D17 | In-process tick loop every ~5 s                                                                             | No cold starts; no scheduler quota; low map latency            |
| D18 | Hot state in memory, single instance; restart drops live state                                              | Privacy and simplicity; clients resume via `resume`            |
| D19 | Cloudflare proxy in front; Caddy at origin; Deno binds localhost; firewall accepts web only from Cloudflare | Hides origin; absorbs floods; free TLS and snapshot caching    |
| D20 | Future analytics only on de-identified aggregates; raw tracks never stored                                  | Keeps roadmap open without breaking privacy design             |
| D21 | Server libs: Hono, postgres.js, one schema lib (Valibot or Zod), dbmate                                     | Small Deno-friendly stack; each needs version ADR below        |

## 2. Infra decisions needed (Pending owner - do not guess)

Per AGENTS.md section 1 and PLAN.md section 19.2, the items below MUST be asked,
not guessed. They affect security, LGPD, persisted data, or public contracts.
Status is `Pending owner` until answered.

### 2.1 Host and database

- INFRA-01 - VPS facts. Needed: provider, region, CPU/RAM/disk, OS
  (Debian/Ubuntu LTS + version), PostgreSQL version, Postgres on same host or
  private net. PLAN prefers Brazil region for LGPD transfer simplicity and
  latency (D14, 13.7). Blocks T04, T06, T07.
- INFRA-02 - Staging instance. Needed: yes or no to a second API instance +
  separate DB/subdomain on the same VPS for simulator and field tests. PLAN
  marks staging optional. Blocks T04 and T13.
- INFRA-03 - Swap and disk encryption. Needed: what the provider offers (swap
  off or encrypted, full-disk encryption yes/no). Affects LGPD art. 46 memory
  hygiene (12.8). Blocks T04.
- INFRA-04 - SSH and admin access. Needed: admin username, SSH source
  restriction possible or not, 2FA on provider account confirmed. Blocks T04.

### 2.2 Network, TLS, Cloudflare

- INFRA-05 - Domains and DNS. Needed: API domain (proposal `api.<domain>`),
  static site domain, confirmation DNS is on Cloudflare. Until decided, use
  `*.pages.dev` and localhost only. Blocks T04, T05, T16, T20. See PLAN 19.2
  items 1 and 10.
- INFRA-06 - Cloudflare plan and features. Needed: plan name, WebSocket idle
  timeout behavior, whether free plan can cache `GET /v1/lines/{id}/vehicles`
  and `GET /v1/live` with a cache rule, current IP ranges refresh method,
  Authenticated Origin Pulls yes/no. VERIFY in S2. Blocks T04, T12.
- INFRA-07 - Origin TLS mode. Needed: Caddy automatic TLS vs Cloudflare origin
  certificate. Blocks T04.
- INFRA-08 - Caddy log policy. Needed: confirm no access logs or IP-free format
  with short retention (12.8, 13.2). Affects privacy. Blocks T04.

### 2.3 Backups, monitoring, ops

- INFRA-09 - Backup target and key holder. Needed: off-host storage location,
  who holds the `age` encryption key, confirm 30-day retention. Backups hold
  pseudonymous device rows only, no location. Blocks T04. See PLAN 19.2 item 11.
- INFRA-10 - Uptime monitor. Needed: which external service pings
  `GET /v1/health`. It receives only the health URL, no user data. Blocks T05.
  See PLAN 19.2 item 12.
- INFRA-11 - Deploy method for alpha. Needed: confirm manual deploy by owner via
  T05 script (default) vs a restricted GitHub workflow with deploy key and
  approval environment. No production server credentials in CI beyond the
  approved path. Blocks T05. See PLAN 17.2.
- INFRA-12 - Secret rotation schedule. Needed: confirm 6-month rotation for DB
  password, env file, SSH keys, tokens, plus on-suspicion rotation. Blocks T04
  runbook.

### 2.4 Server runtime pins (ADR required by D21)

Pending S2 results. One ADR each with version, licence, Deno compatibility. Do
not add other deps without ADR.

- INFRA-13 - Hono version + JSR source + licence + `Deno.upgradeWebSocket` path.
  Fallback if poor fit: bare `Deno.serve` plus ~100-line router.
- INFRA-14 - `postgres` (postgres.js) version + licence + TLS/pooling on Deno.
- INFRA-15 - Schema library: Valibot vs Zod. Needed: version, licence, Deno
  compat, bundle size irrelevance on server but API clarity. Pick one only.
- INFRA-16 - dbmate availability on target OS. VERIFY. Fallback: tiny Deno
  runner with checksums (PLAN 6.1).
- INFRA-17 - Deno version pin. Needed: latest stable at T06, pinned in
  `deno.json` and systemd unit, plus exact `--allow-net`, `--allow-env`,
  `--allow-read` flags. No `--allow-write`, `--allow-run`, `--allow-ffi`,
  `--allow-sys`.
- INFRA-18 - systemd sandbox flags. Needed: confirm full list in 12.8 works on
  target OS, esp. `MemoryDenyWriteExecute`, `LimitNOFILE` value, `LimitCORE=0`.

### 2.5 Client and release infra (blocks M0-M9)

- INFRA-19 - Code and data licences. Needed: code licence (suggest AGPL-3.0 or
  MIT) and compiled data licence (suggest CC BY 4.0 or ODbL). Current `LICENSE`
  is GPLv2 and conflicts with PLAN 19.2 item 3. Must be resolved in T01 before
  wider distribution.
- INFRA-20 - Android `applicationId` (proposal `app.pontual`), app name
  confirmation. Cannot change after first store upload. Blocks T02. See PLAN
  19.2 item 1.
- INFRA-21 - Play account path: limited-distribution (<= 20 devices, no fee) for
  Phase 0-1 vs Play Console (US$25) with early closed test. VERIFY current
  tester count and days. Blocks T48. See PLAN 19.2 item 5.
- INFRA-22 - Flutter version pin at M0 (`.fvmrc` or CI `flutter-version`) and
  `minSdk`/`targetSdk` VERIFY at release. Blocks T02.
- INFRA-23 - Controller identity and contact e-mail for policy and data-subject
  requests. Blocks T42. See PLAN 19.2 item 2.
- INFRA-24 - Pilot lines (1-3) and first route traces. Blocks T15, T17. See PLAN
  19.2 item 6.

Out of infra scope but still pending owner (PLAN 19.2): lawyer/DPO who and when,
operator outreach owner and timing, web sharing in alpha yes/no (default viewer
first), history/analytics roadmap confirm per D20.

## 3. VERIFY list (must check against official sources, record result here)

Collected from PLAN 3.2 and 19.3. Each gets a dated result entry under section 5
when its spike or task runs.

- V01 (S1): `geolocator` foreground-service with screen off 30 min, swipe-away
  behavior, `Position.isMocked`, notification action support, Android 13
  `POST_NOTIFICATIONS` flow.
- V02 (S2): Deno stable version, permission flags, Hono +
  `Deno.upgradeWebSocket`, postgres.js TLS/pooling, dbmate on target OS,
  Cloudflare WebSocket timeout, edge-cache rule, IP ranges, bytes per ping at 15
  s vs 90 s cadence.
- V03 (S3): `flutter_map` >= 8.2.0 `BuiltInMapCachingProvider` 50 MB cap API,
  OSM User-Agent and attribution, fps on low-end device.
- V04 (S4): Flutter Web `--wasm` size/startup, `--no-web-resources-cdn` flag
  name, service worker default, Screen Wake Lock on iOS PWA, COOP/COEP vs OSM
  tiles.
- V05 (release): Play foreground-service declaration, closed-test tester count
  and days, target audience and Data safety wording for location.
- V06 (legal): ANPD Res. CD/ANPD no. 2/2022 small-agent applicability, Res.
  CD/ANPD no. 15/2024 breach deadline (currently 3 business days), ECA Digital
  Lei 15.211/2025 applicability, minimum-age wording, 15-day declaration
  deadline.
- V07 (host): `MemoryDenyWriteExecute` support on target systemd, provider
  disk-encryption and swap options, `bbox` values against real municipal routes.

## 4. Spikes (S1-S4 done 2026-10-02)

- S1: geolocator foreground service. See V01. Done, findings in section 5.
- S2: Deno + Caddy + Cloudflare + postgres.js + dbmate. See V02. Done,
  findings in section 5.
- S3: flutter_map cache and perf. See V03. Done, findings in section 5.
- S4: Flutter Web wasm, PWA, wake lock. See V04. Done, findings in section 5.

Rule: run spikes before building on their assumptions (AGENTS.md section 3,
PLAN.md 0.3).

## 5. Results log (append-only, newest at bottom)

- 2026-10-02: File created. D01-D21 imported from PLAN.md v1.1 as Accepted.
  INFRA-01 to INFRA-24 opened as Pending owner. V01-V07 opened. No spikes run
  yet. No code changes yet.
- 2026-10-02: Owner answers round 1 recorded in section 6 (D22-D28). VPS
  baseline set. App name and applicationId set. Web sharing in scope. D20
  confirmed.
- 2026-10-02: T01 fix. Restored `app/` skeleton directory (was misplaced as
  `docs/app/`). Verified no `build/`, no real `.env`, no keystore, no private
  keys. `DATABASE_URL` appears only in `server/.env.example` dummy value plus
  spec text in PLAN, AGENTS, step.
- 2026-10-02: T02 done. Flutter 3.47.6 pinned via `.fvmrc` (INFRA-22 partial;
  CI pin lands in T03). `flutter create --org com.spotnik --project-name
  pontual --platforms=android,web --empty` confirms applicationId
  `com.spotnik.pontual` per D22. Added `flutter_riverpod 3.4.3` only
  (allow-list PLAN 8.2, no ADR needed). Strict analyzer per PLAN 14.2 with
  `public_member_api_docs` enabled globally. Empty `ProviderScope` app boots
  with no network on first paint. Merged-manifest audit: source has no
  location permissions; only INTERNET in debug/profile; no forbidden
  permissions. `flutter analyze` clean, `flutter test` passes.
- 2026-10-02: T03 done. CI `ci.yml` with actions pinned by SHA (checkout v4
  11d5960a, setup-java v5 b6effb05, flutter-action v2 1a449444, setup-deno v2
  22d081ff deferred, gitleaks-action v2 ff98106e; SHAs verified via
  api.github.com). Used setup-java v5, not v4, because v4 is deprecated.
  Jobs: flutter analyze, format check, test, manifest audit, web size report,
  gitleaks. Deno job deferred to T06 per PLAN. Manifest audit is source-level;
  full merged-manifest check lands in T45. Size report is non-blocking in T03:
  local `flutter build web --release` produced 40 MB uncompressed (canvaskit
  37 MB, main.dart.js 1.7 MB); compressed first-load and AAB gates land in
  T44/T45 after S4 wasm/CDN work. Local verify: analyze clean, test passes,
  audit PASS, YAML parses.
- 2026-10-02: S1 done (V01). geolocator 14.1.1 (MIT, Baseflow, Flutter
  Favorite) with geolocator_android 5.1.1+1; compatible with Flutter 3.47.6
  (needs >= 3.29.0). Foreground service via AndroidSettings
  foregroundNotificationConfig; bound service stops on swipe-away per D11, no
  ACCESS_BACKGROUND_LOCATION needed. Position.isMocked available on Android.
  No notification action button (tap opens app; RF03 fallback stands).
  POST_NOTIFICATIONS must be declared and requested separately on API 33+;
  geolocator does not request it. Plugin manifest contributes only the
  location FGS service entry; app must declare FINE/COARSE,
  FOREGROUND_SERVICE plus FOREGROUND_SERVICE_LOCATION, POST_NOTIFICATIONS.
  Remains VERIFY on device: 30 min screen-off, swipe-away, denied
  notifications, merged manifest, isMocked, Play FGS declaration.
- 2026-10-02: S2 done (V02). Deno 2.9.7 stable pinned line 2.x; flags
  --allow-net, --allow-env (scoped), --allow-read (scoped); no write, run,
  ffi, sys. Hono 4.13.12 MIT via jsr:@hono/hono, Deno.serve plus
  upgradeWebSocket from jsr:@hono/hono/deno wrapping Deno.upgradeWebSocket
  (idleTimeout default 30 s). postgres.js 3.4.9 Unlicense, TLS plus pooling
  options fit same-host PG; import specifier and TLS mode VERIFY at
  T06/T07. dbmate v2.36.0 MIT, linux amd64/arm64 assets cover VPS arches;
  install via release binary, VERIFY on VPS. Cloudflare Free supports WS,
  idle timeout unpublished (25 s heartbeat stands), Cache Rules on Free can
  edge-cache snapshot GETs, IP ranges via api.cloudflare.com/client/v4/ips,
  AOP available on Free. Ping bytes estimated 0.6 to 1.2 KB per ping; S2 gate
  0.6 KB per ping must be measured at 15 s vs 90 s on staging.
- 2026-10-02: S3 done (V03). flutter_map 8.3.2 BSD-3-Clause plus latlong2
  0.10.1 Apache-2.0; cache API BuiltInMapCachingProvider with maxCacheSize
  supports 50 MB cap, auto-enabled on non-web, no-op on web. OSM policy:
  https tile.openstreetmap.org only, real User-Agent via
  userAgentPackageName, visible attribution, no bulk download or prefetch,
  cache per headers. PLAN D12 stands with TileSource abstraction and exit
  plan before Phase 2. Remains VERIFY on device: 55 fps pan, 50 MB cap,
  first vs repeat bytes, real UA tiles, PSS memory.
- 2026-10-02: S4 done (V04). Flag is --wasm (dual wasm plus JS fallback);
  default is dart2js plus CanvasKit; --web-renderer removed. Single-threaded
  skwasm beats CanvasKit on 3.47.x; iOS browsers always get JS fallback.
  --no-web-resources-cdn self-hosts CanvasKit but not Roboto from
  fonts.gstatic.com (open issue). No Flutter service worker by default now;
  use Cache-Control and ETag. Wake Lock needs visible document and HTTPS;
  iOS standalone PWA broken before 18.4; geolocation stops when hidden per
  spec, matching KL4 foreground-only design. --wasm needs no COOP/COEP for
  single-threaded; credentialless keeps OSM tiles working. Remains VERIFY on
  staging and devices: no-CDN requests, wasm vs js bytes vs 3 MB budget,
  crossOriginIsolated, wake lock on recorded iOS versions.
- 2026-10-02: T06 done. Server skeleton with Deno 2.9.7, Hono 4.13.12 MIT via
  JSR, deno.lock committed. Config fail-fast per PLAN 6.3, Log wrapper with
  no coordinate or token API, GET /v1/health plus generic 404 and error
  handler, graceful shutdown, localhost-only metrics listener. Minimal flags:
  allow-net bind plus db, allow-env listed vars, allow-read DATA_DIR; no
  write, run, ffi, sys. Schema library (Valibot vs Zod) deferred to T08 where
  request validation lands. CI server job added with setup-deno v2 pinned.
  Local verify: deno fmt, lint, check clean; 5 tests pass; boot serves health
  and metrics; invalid env refuses to start.
- 2026-10-02: T07 done. Migration 0001 with devices, consents,
  blocked_devices, app_config plus pontual_app least-privilege grants; no
  location columns (AC22 scan passes). Repositories for devices, consents,
  blocked, plus runtime config loader with compiled defaults and
  app_config overrides. postgres.js 3.4.9 Unlicense via npm specifier.
  postgres.js scans PG* env at startup, so the test task uses broad
  --allow-env with dummy CI values; dev and start keep the scoped list.
  Local PG is postgres:16-alpine on 5433; prod PG version still VERIFY at
  T04. CI server job now runs postgres:16 service plus dbmate 2.36.0 migrate
  plus deno task test. Local verify: migrate applies to clean DB, 11 tests
  pass, fmt/lint/check clean.
- 2026-10-02: T08 done. Schema library INFRA-15 decided: Valibot 1.5.0 MIT via
  JSR, zero deps, Deno-compatible; safeParse at the boundary with strict
  objects. Middleware order per PLAN 6.9 with secure headers and exact-origin
  CORS. Token is bm1_ plus 43 base64url chars from 32 CSPRNG bytes, SHA-256
  stored, 30-day expiry, in-memory 60 s lookup cache evicted on delete.
  Routes: POST /v1/devices, POST /v1/consents (version must equal current),
  DELETE /v1/me (cascade plus evict; trip eviction lands in T10 with the
  engine). AC03 note: the device id returned at registration is by design
  per PLAN 6.5; no trip or session ids exist anywhere. Per-IP and global
  registration caps plus per-device consents and delete caps. Local verify:
  17 tests pass covering AC01, AC03, AC11, AC13, AC18, AC23; live boot
  register plus consent plus delete plus 401 paths verified via curl.
- 2026-10-02: T09 done. Pure engine per PLAN 6.6: geo helpers, validation,
  attach-at-ping with dead reckoning, election, startTrip plus applyPing
  plus endTrip, tick, snapshot builder, in-memory store. Jitter and time are
  parameters, no I/O or clock in domain. One refinement vs the literal text:
  dead-leader replacement prefers a fresh member (inside
  leader_dead_after_s) and falls back to all members, so a dead leader is
  never re-picked while a live follower waits. Engine unit tests 1-18 and
  20-24 pass (23 tests); test 19 restarts lands in T11. Full suite is 40
  tests green with fmt, lint, and check clean.
- 2026-10-02: T10 done. Trip endpoints wired to the engine: POST /v1/trip
  with line, consent, blocklist, kill-switch, quota, and capacity checks;
  POST /v1/trip/ping with jittered follower intervals; DELETE /v1/trip
  idempotent. Line registry resolves from injected data; the file loader
  lands with the T14 bundle, so production returns 404 line until then.
  Quota is consumed only by known lines. RF16 walking hint deferred to the
  client auto-end work. Local verify: 46 tests pass covering AC02, AC07,
  AC09, AC10, AC14; live register plus consent plus start plus ping plus
  delete flow verified via curl.
- 2026-10-02: T13 done. Driver simulator in tools/sim with buses, riders,
  abuse scenarios (localhost only), and a latency report over real HTTP
  plus WebSocket. Two fixes from the first runs: applyPing now emits
  vehicleUpdated so every position update broadcasts immediately (viewers
  previously waited for tick-driven changes), and dev/start tasks list the
  full PG* env set the postgres.js shim probes (scoped flags kept; the
  driver names each missing var at boot). LINES_JSON seeds lines for local
  runs until the T14 bundle lands. CI runs tools fmt/lint plus a 60 s sim
  smoke. Local verify: 90 s and 45 s runs with hand-overs observed,
  snapshots flowing, p50 latency 4 to 7 ms, no errors. The full 30-min run
  and 8-hour soak land in T46.
- 2026-10-03: T14 done. Static data pipeline: JSON Schemas for line,
  manifest, and config files; a Deno validator plus builder driven by the
  schema files with semantic checks (unique ids, codes, shorts; sorted
  unique HH:MM times; 100 KB budget) and content-hashed immutable outputs
  plus manifest plus config plus server bundle. The server loads the bundle
  from DATA_DIR with LINES_JSON as fallback. data/sources.md stubbed for
  T15. CI has a data job with fmt, lint, tool tests, validation, build,
  and a size-budget gate. Local verify: tool tests pass, empty set builds,
  bundle-backed endpoints serve live.
- 2026-10-03: T16 partial (repo side done). The data builder writes
  build/_headers from PLAN 12.5 with the API origin from the environment,
  and deploy-static.yml builds data plus web and deploys to Pages via a
  pinned wrangler-action. Still owner-blocked: Cloudflare project and DNS
  (INFRA-05, INFRA-06), API_TOKEN and ACCOUNT_ID secrets, and the
  production API_ORIGIN value. Local verify: _headers content checked,
  builder test asserts the revalidation rules, both workflows parse.
- 2026-10-03: T17 partial (tool done). Route converter in tools/route
  reads GPX tracks or GeoJSON LineString, simplifies with Douglas-Peucker
  at 5 m, and writes data/routes/<code>.geojson; the data builder encodes
  precision-5 polylines into build/routes with an 8 KB budget and wires
  the manifest routes map; the server decodes them into the route check.
  Verified on synthetic traces (300 points kept 2, 16 B polyline) with
  round-trip tests plus parser tests. Real pilot traces need owner field
  rides, so no geometry is committed.
- 2026-10-03: T15 done. All 21 urban lines seeded from onibus.online
  (retrieved 2026-10-03): 4 pilot lines (60, 62, 64, 66) with transcribed
  weekday timetables plus Sat and Sun where published, 17 names-only lines
  with pilot false. Ids are the official line numbers; the two 62 variants
  share one id until route geometry decides otherwise. Stripped itinerary
  digits and collapsed duplicate minutes are recorded in data/sources.md
  with VERIFY flags. Validator passes, bundle is 8.6 KB, trip start on a
  bundle line verified live.
- 2026-10-02: T12 done. Public reads plus stream: GET
  /v1/lines/{id}/vehicles with ETag, 304, and 5 s edge cache headers; GET
  /v1/live with 10 s headers; read-only hub with per-IP and global caps,
  128-byte and 10-per-minute message limits, and bye on shutdown. Heartbeat
  is two layers: Deno protocol ping/pong via idleTimeout 60 plus an
  app-level 25 s message for Cloudflare idle timeouts; clients ignore
  unknown keys. Fixed header order so routes override the no-store default
  with cache headers. Local verify: 63 tests pass covering AC05 (HTTP part),
  AC06 (unit plus live 101 upgrade and invalid-line close), and AC08
  (device and IP floods contained); live snapshot endpoints checked via
  curl. Full WS relay through Cloudflare stays VERIFY on staging.
- 2026-10-02: T11 done. Background jobs with overlap-guarded tick, 30 s
  config refresh, daily 03:30 Sao Paulo device purge, and 10 s db health
  probe; all timers stop on shutdown. Engine test 19 passes: fresh store
  answers gone, resume rebuilds the vehicle. Full suite is 52 tests green.
- 2026-10-03: T33 done. TripController owning the full consent to end
  lifecycle with first-fix start, ping loop, role updates, auto-end, and
  best-effort end, plus the S08 trip screen with visible-only ticker and
  S09 end cards. Fixes from testing: broadcast fix stream for the
  start-to-loop handoff, fire-and-forget stops for test zones, and
  pump-flushed starts in widget tests. Staging E2E stays owner-blocked;
  the same calls verified live against the local server on bundle data.
  Local verify: analyze clean, 82 client tests pass, manifest audit clean.
- 2026-10-03: T32 done. Ping sender with one request in flight,
  latest-wins coalescing, 5 to 60 s jittered backoff with retry of the
  latest fix, single 401 refresh plus retry, and typed server outcomes
  including auth exhaustion. Local verify: analyze clean, 78 client tests
  pass, manifest audit clean.
- 2026-10-03: T31 done. Location service with geolocator stream modes,
  foreground notification config, mock plus accuracy plus bbox plus stale
  filters, send-format rounding, and hysteresis, plus the geolocator
  permission gateway and the allow-listed manifest permissions. S1
  device criteria stay VERIFY for the T47 field test. Local verify:
  analyze clean, 73 client tests pass, manifest audit clean.
- 2026-10-03: T30 done. Consent sheet with the S06 copy, permission
  education plus denied plus blocked plus services-off sheets with a
  gateway interface for the T31 geolocator wiring, local consent
  versioning, and an offline-tolerant consent flow that never starts a
  trip uncovered. Local verify: analyze clean, 69 client tests pass,
  manifest audit clean.
- 2026-10-03: T29 done. Pure client trip domain: sealed TripState with a
  total reducer, sampling policy with 30 s hysteresis, and auto-end policy
  with priority order. Local verify: analyze clean, 62 client tests pass,
  manifest audit clean.
- 2026-10-03: T28 done. Map tab with live, stale, connecting, offline,
  and empty states, marker plus text-row vehicles, recenter button,
  non-pilot note, and route polyline support. Test lessons recorded:
  widget teardown needs pump-flushed disposal in FakeAsync, and the
  watchdog correctly heals staleness so the stale test fails its fetcher.
  Also fixed a live-with-zero-vehicles crash in the status row. Local
  verify: analyze clean, 55 client tests pass, manifest audit clean.
- 2026-10-03: T27 done. Vehicle stream repository with snapshot-first
  start, read-only socket, 45 s watchdog resync, 30 s polling fallback,
  and clean background stop, all on an injectable clock and fake channel.
  stream_channel added as an explicit test-only companion of the
  allow-listed web_socket_channel (same Dart team, no permissions).
  stop() now nulls cancelled timers so state reads clean. Local verify:
  analyze clean, 51 client tests pass, manifest audit clean.
- 2026-10-03: T26 done. Map widget with the OSM tile layer behind a
  TileSource seam, 50 MB cache cap, area bounds with zoom limits, and a
  tappable OSM attribution inside a RepaintBoundary. Unit tests avoid the
  native cache init with the disabled provider. Local verify: analyze
  clean, 45 client tests pass, manifest audit clean.
- 2026-10-03: T25 done. Timetable tab with day-type default from the
  São Mateus date, origin selector, next-departure card, dimmed past
  times, and the unofficial-data disclaimer; pure schedule helpers live
  in domain with widget tests. Two real bugs fixed along the way: the
  origin dropdown needed initialValue on current Flutter, and lines
  without any schedules crashed initState. Local verify: analyze clean,
  43 client tests pass, manifest audit clean.
- 2026-10-03: T24 done. Home screen with local search, cached line list,
  and live indicators that fill in without spinners, wired through
  Riverpod providers. Fixed asset manifest parsing to real JSON decode.
  Local verify: analyze clean, 37 client tests pass, manifest audit clean.
- 2026-10-03: T23 done. Remote flags repository with bundled defaults,
  daily refresh, and version comparison, plus S13 system screens for
  maintenance, update, and unreachable states and the S14 offline banner.
  Local verify: analyze clean, 33 client tests pass, manifest audit clean.
- 2026-10-03: T22 done. Offline-first static data repository: bundled
  assets ship in the app, cache is read before any network, manifest
  revalidates at most daily, and versioned writes swap atomically with the
  manifest pointer last. Local verify: analyze clean, 27 tests pass,
  manifest audit clean.
- 2026-10-03: T21 done. Typed API wrappers with DTOs and error mapping for
  every endpoint, fake mapping tests plus a live contract test against the
  local server. The live run caught a real client bug: DELETE requests fell
  through to GET and are now sent correctly. Local verify: analyze clean,
  21 tests pass with 1 live, manifest audit clean.
- 2026-10-03: T20 done. Client networking base: keep-alive HTTP factory
  with a web-safe conditional import, env.dart for dart-define URLs, token
  store, and BusApi registration on demand (one per install, never at
  startup). Local verify: analyze clean, 16 tests pass, manifest audit
  clean, web release build compiles.
- 2026-10-03: T19 done. Client core utilities: injectable Clock, Log ring
  buffer with no PII API, pure geo helpers, jittered backoff ladder, and
  sealed Result plus AppFailure types. Local verify: analyze clean, 12
  widget plus unit tests pass, line coverage 97.4 percent on core.
- 2026-10-03: T18 done. App foundation: Material 3 tokens from PLAN 9.2,
  pt-BR string table, go_router skeleton with all ten alpha routes as
  placeholders. The 200 percent scale test caught a real welcome-screen
  overflow; the screen scrolls now. Local verify: analyze clean, 3 widget
  tests pass, manifest audit clean (go_router adds no permissions).
- 2026-10-03: T34 done. Auto-end plus RF16 prompt plus offline saver plus
  GPS-off and permission-revoked handling. New TripSupervisor owns health
  tracking and round evaluation (polls, slow clock, silence clock,
  sampling intent); TripController applies decisions to the state machine.
  Walking prompt after 4 min slow, 3 min no-answer end; GPS off pauses and
  ends after 5 min; permission revoked ends at once; offline saver after
  3 failures or 120 s silence with heal on success; probes reuse the
  PingClient backoff (5 to 60 s plus jitter, PLAN said 30/60/120 probes;
  more frequent is bounded and recovers faster, no change needed).
  Two real bugs fixed: the start-to-loop handoff cancelled the position
  stream via onCancel (only the first fix ever flowed; removed the
  handler, stop() still owns shutdown), and LocationService.requestMode
  never recreated the stream (now it does, hysteresis kept). Server RF16
  "a" flag stays unimplemented (PLAN marks it optional); local slow
  detection covers RF16. File review: trip_controller.dart is 490 lines;
  the TripSupervisor split is taken and the rest is one lifecycle flow,
  revisit past 600 lines or on new responsibilities. Local verify:
  analyze clean, 102 client tests pass (20 new), manifest audit clean,
  no new permissions or dependencies.
- 2026-10-03: HEAD faceb05 reconciled (was unrecorded). It closes the M5
  sharing gap: `share_flow.dart` wires MapTab buttons through services check,
  consent sheet, permission education, TripController start, then navigates
  to /trip with the started controller; /trip without a controller shows the
  fallback placeholder; non-pilot lines are a no-op. Plus server hardening:
  config-refresh and purge jobs catch DB errors instead of crashing the
  process (reads stay up while the database is down), a `lines loaded`
  boot log with an empty-registry hint, and `deno task dev` reads
  `--env-file=.env`. AC impact: none beyond T33/T34 scope; no schema or
  contract change.
- 2026-10-03: T35 local part done (real phones stay owner-blocked, see T47).
  Ran against the local server on bundle data (21 lines) with an isolated
  docker PG (owner DB connection is recorded below). 90 s sim, 1 bus,
  2 riders on line 60: 36 pings, 2 role changes, 1 hand-over, 34 WS
  snapshots, last vehicle age 0 s, p50 latency 6 ms, p95 about 5 s
  (snapshot cadence), no errors. Leader-kill script: riders merged to one
  L plus one F, killing the leader promoted the follower in about 5 s
  (next ping, inside the KL1 bound), snapshot ages stayed under 20 s.
  Alpha criteria 2 and 3 hold locally. Test hygiene found: AC14 leaves
  `service_enabled=false` in the shared dev database, so later runs 503
  until app_config is cleared; the 8-hour soak (T46) must reset app_config
  first. Owner-blocked: the repo-root .env database rejects the 0001
  migration with `permission denied to create role` (restricted DB user,
  needs CREATEROLE or a one-time superuser migrate); local runs used the
  docker PG on 5433 instead.
- 2026-10-03: T36 test repairs (client suite had 2 failures from the
  unrecorded HEAD commit). (1) `trip_rig.start()` hung forever under
  testWidgets: it yielded with `Future.delayed(Duration.zero)`, a timer
  that never fires in FakeAsync without pumped time. Plain `test()` uses
  real async so it passed there. Fixed with a microtask yield, which works
  in both zones. (2) Second share-flow test went silent: `shareButton`
  read flags through the real `remoteConfigRepoProvider`, whose
  rootBundle asset load answers only the first testWidgets per file and
  never completes later (mocked channels repeat fine; engine-served
  assets do not - verified with isolated probes). Tests now override the
  provider with literal bundle JSON per the existing home_test pattern,
  so no widget test touches rootBundle or the network. No production
  change: every silent share path either shows UI or correctly aborts a
  dead screen, and no trip starts without consent. File green (5 tests),
  analyze clean.
- 2026-10-03: Late-outcome dispose guard (production fix). The rig timing
  change exposed a real crash: a ping outcome arriving after the trip
  screen is gone called notifyListeners on a disposed TripController
  (same for a resumed auto-end check). `_onOutcome` and `_checkAutoEnd`
  now ignore work after dispose via a `_disposed` flag. The previously
  failing auto-end test is the regression cover. Targeted files green,
  full suite re-running.
- 2026-10-03: T36 done. Web build config: PWA manifest rebranded to
  Pontual with the app green (#0B6E4F), deploy builds with
  `--no-web-resources-cdn --wasm` (S4: single-threaded skwasm beats
  CanvasKit; iOS keeps the JS fallback). Measured first load gzipped:
  default path about 2.9 MB (main.dart.js 870 KB plus chromium
  canvaskit.wasm 2010 KB plus fonts), wasm path about 2.6 MB; both
  inside the 3 MB budget, so no size ADR needed. CSP unchanged and
  strict (wasm-unsafe-eval already allowed; no COOP/COEP needed for
  single-threaded skwasm); Google Fonts stays blocked so web uses
  fallback fonts until the S4 font issue is resolved. Verified: full
  client suite green (107 passed), analyze clean, both builds compile.
  Owner-blocked deploy (Pages project, DNS, secrets) unchanged.
- 2026-10-03: T37 parked. Browser and on-device checks move to another
  machine (owner todo): this host has no usable browser (only a snap
  stub; flutter test needs a real Chrome) and no phones. Desktop-Chrome
  widget runs plus the shipping web build stay the verify path there.
  Viewer code itself is platform-clean (one conditional import, no
  dart:io in features).
- 2026-10-03: T39 done. One-time iOS install hint: pure
  `shouldShowInstallHint` (iOS web and unseen only), prefs-backed
  `InstallHintStore`, dismissible Safari share-sheet card slotted at
  the top of Home (no-op off iOS web). Verified: 4 new tests green,
  existing home tests green, analyze clean. Real Safari PWA check
  stays on a phone (owner todo, T47).
- 2026-10-03: T40 done. S10 Settings (theme Sistema/Claro/Escuro
  with prefs persistence via `themeModeProvider`, privacy and about
  entries, help texts, timetable build date from the manifest) plus
  S12 About (non-affiliation disclaimer, onibus.online source line,
  OSM copyright link, licence page, repo link). Contact row hidden
  while `supportEmail` is empty (INFRA-23 still owner-blocked).
  Riverpod 3 note: `StateProvider` no longer exists, theme uses a
  tiny `ThemeModeNotifier`. Verified: full suite green (124 passed),
  analyze clean, manifest audit PASS.
- 2026-10-03: T41 done. S11 privacy center: bundled short
  policy/terms (offline), 6-line collection summary per 13.2,
  `PrivacyActions` (delete-my-data with honest offline outcome,
  revoke with best-effort trip end), policy/terms text routes,
  contact hidden until INFRA-23. Support code cut per the cut
  order. Verified: AC13 end-to-end in-widget (confirm clears token
  and returns to welcome; cancel and offline keep data), full suite
  green (131 passed), analyze clean.
- 2026-10-03: T42 done (docs only, no code besides the bundled-text
  pointer). `docs/privacy/policy.md` and `terms.md` drafts (pt-BR,
  per 13.9, with [DEFINIR] markers for controller, contact,
  domains, licences), `ripd.md` (RIPD-lite with KL2 residual risk),
  `inventory.md` (processing records from 13.2). Owner-blocked:
  lawyer review, contact e-mail (INFRA-23), licences (INFRA-19
  data half), canonical URLs (INFRA-05).
- 2026-10-03: T43 done. Ran every AC test that can run on this host:
  server 67 green (first run showed 24 `TEST_DATABASE_URL is not
  set` errors, env gap only), client 131 green, fmt/lint/check and
  analyze clean, manifest source audit PASS. AC17 debug-log trip
  audit has zero hits for coordinates, tokens, or device ids. Wrote
  docs/security/review-alpha.md: no open P0/P1 in code; AC04, AC20,
  AC21 blocked on the VPS (server/deploy/ still empty, T05); AC15
  partial until the release AAB; AC16 partial until a gitleaks run
  (CI covers it per release); AC08 scale and AC06 relay need
  staging.
- 2026-10-03: T44 partial. Measured ping wire size by curl trace
  (0.62 KB per ping; leader ~0.15 MB/h at budget, follower ~0.025
  MB/h inside) and web first load (JS 2.95 MB gz inside, wasm 3.08
  MB gz ~3 % over). Wrote docs/field-tests/budgets.md. No Android
  SDK on this host so no AAB/APK size; no phones so no
  frame/RAM/CPU/battery/fps/latency numbers. All recorded as TODO
  for the capable machine.
- 2026-10-03: T45 done as far as this host allows (no Android SDK,
  so no AAB to inspect). In-tree: `allowBackup=false` on the
  application tag (AC15, token cannot clone via cloud backup),
  R8 `isMinifyEnabled` + `isShrinkResources` with stock
  `proguard-rules.pro` (rollback documented in-file), audit script
  now also fails on missing allowBackup and on cleartext, new
  `release-android.yml` (tag build with --obfuscate, merged
  manifest audit, AAB <= 15 MB gate, `gh release upload`, no new
  third-party action). Owner-blocked: upload keystore secrets,
  first tagged build plus install-launch, merged-manifest result.
- 2026-10-03: T49 done (docs only). `docs/field-tests/pilot-kit.md`
  with the 1-page pt-BR guide, known-limitations summary, and a
  copy-paste feedback form. Organizer contact still [DEFINIR]
  (INFRA-23).
- 2026-10-03: T38 done. Foreground-only web sharing: `wakelock_plus`
  1.8.0 (allow-list PLAN 8.2, no ADR needed; its Android manifest adds
  no permissions, source audit still PASS) behind a `WebWakeLock` seam
  in `platform/web/` with a fake for tests; pure `WebVisibilityTracker`
  pauses sends after 60 s hidden (`webHiddenPauseMs`) and resumes on
  visible; TripController drops fixes while `isWebHidden` (server
  10-min timeout is the backstop, no explicit end needed); trip screen
  shows the always-visible PLAN banner plus brightness tip, wake-lock
  status, and hidden-paused state on web only (`kIsWeb`). Size note:
  release web build compiles; JS path 2.95 MB gz (inside budget), wasm
  path 3.08 MB gz (about 3 percent over the 3 MB RNF14 target;
  canvaskit.wasm 2.06 MB gz dominates, nearest achievable without a
  renderer change; iOS browsers take the JS path). Full client suite
  green (116 passed, 9 new), analyze clean. Browser run of the banner
  and wake lock stays on the T37 machine (owner todo).

## 6. Owner answers round 1 (2026-10-02, Accepted)

Source: owner message answering PLAN.md 19.2. Section 2 above stays as the
request history; the entries below supersede it where decided.

- D22 - Product name `Pontual`, Android `applicationId` `com.spotnik.pontual`.
  Repo name stays `pontual`. API and static domains TBD; until then use
  `*.pages.dev` for static and localhost for API. Unblocks T02 appId. See
  INFRA-05 (still pending), INFRA-20 (decided).
- D23 - Code licence stays GPLv2 (file `LICENSE` already in tree). This
  overrides the PLAN suggestion of AGPL-3.0 or MIT. Compiled data licence still
  open; default is repo licence until the owner picks CC BY 4.0 or ODbL in
  T14/T15. See INFRA-19 (code decided, data pending).
- D24 - VPS baseline: Oracle Cloud, region Sao Paulo Brazil, Ubuntu LTS (owner
  wrote 24/26; T04 must confirm exact image), 1 oCPU, 6 GB RAM, 50 GB disk,
  PostgreSQL on localhost (owner wrote 16/18; T07 must confirm exact version and
  pin it). Brazil region satisfies the LGPD preference in D14 and 13.7. See
  INFRA-01 (baseline decided, exact OS and PG versions to verify in T04/T07).
- D25 - Pilot lines: 66 (Centro / Ufes-Ifes), 62 (Guriri / Ufes-Ifes via Jacui),
  62 (Guriri / Ufes-Ifes via BR-101), 64 (Villages), 60 (Litoraneo). Notes: this
  is 5 service patterns, above the 1-3 pilot guidance in PLAN 1.5; accepted as
  the owner set. T15 must assign stable numeric ids, slugs, and shorts, and
  confirm whether both 62 variants share one line id or get separate ids. No
  route traces yet. See INFRA-24 (set decided, formalization pending in
  T15/T17).
- D26 - Web shares location in alpha. T38 stays in scope and is not cut.
  Viewer-first still applies; sharing is foreground only with wake lock and
  banner per PLAN 8.12. Cut order in PLAN 16 still applies to the rest.
- D27 - Deferred: controller identity and contact e-mail, lawyer/DPO, Play
  account path and closed-test timing, operator outreach, backup target and key
  holder, uptime monitor, Cloudflare Authenticated Origin Pulls and edge-cache
  rules (default for alpha: AOP off; S2/T12 verify WebSocket timeout and whether
  snapshot caching is used). Deploy stays manual by owner per PLAN 17.2 until
  decided otherwise. See INFRA-02, INFRA-03, INFRA-04, INFRA-06, INFRA-07,
  INFRA-08, INFRA-09, INFRA-10, INFRA-11, INFRA-12, INFRA-21, INFRA-23 (still
  pending).
- D28 - D20 roadmap confirmed: history and analytics only on de-identified
  aggregates, raw per-trip tracks never stored, consent bump plus RIPD update
  plus legal review before any such work.
