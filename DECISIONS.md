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
