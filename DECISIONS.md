# DECISIONS.md - BusMateus

Append-only record of architecture decisions (ADRs), spike results, and deviations from PLAN.md.
PLAN.md is the build contract. This file records what was decided, why, and what is still pending.

Conventions:

- Status: `Accepted`, `Proposed`, `Pending owner`, `Superseded`.
- IDs `D01-D21` are imported from PLAN.md v1.1 section 2 and are `Accepted` unless noted.
- New deviations use the next `Dxx` number. Pending infra questions use `INFRA-xx` until the owner decides, then they become `Dxx`.
- Spikes use `S1-S4` from PLAN.md section 16.
- No em dashes in this repo. Use hyphens.
- Language: English.

## 1. Imported decisions (PLAN.md v1.1, Accepted)

These are binding per PLAN.md section 2. Summarized here so builders do not need to re-derive them.

| ID | Decision | Why (short) |
|---|---|---|
| D01 | Use `geolocator` directly, not `smart_location` | Claimed features do not exist; wrapper is tiny and new |
| D02 | No ping history, no location at rest | LGPD minimization; location lives only in API memory |
| D03 | Clients talk only to our Deno API, never to PostgreSQL | One enforcement point; stream cannot be spoofed |
| D04 | Attach-at-ping online clustering with dead reckoning, pure TypeScript engine | Followers report rarely; windowed DBSCAN would split one bus |
| D05 | Vehicle position is newest accepted fix, not centroid | Centroid of mixed-age fixes is biased backwards |
| D06 | Role and interval returned in `ping` response; two-phase hand-over | No extra connection; no gap at hand-over |
| D07 | Timetables are static versioned JSON, not a DB table | Zero DB load; cacheable; works offline |
| D08 | Server time only, no client `recorded_at` | Client clocks are wrong or spoofable |
| D09 | Revised data budgets (leader <= ~0.15 MB/h, etc.) | Real HTTP header cost measured; old budget unreachable |
| D10 | Consent (LGPD art. 7, I) for location sharing | Opt-in per trip; matches Play prominent disclosure |
| D11 | No `ACCESS_BACKGROUND_LOCATION`; foreground service type `location` only | Avoids strict Play review; more private; swipe ends trip |
| D12 | OSM raster tiles via `flutter_map` cache, behind `TileSource` abstraction | Light-use policy compliance; exit plan before Phase 2 |
| D13 | Compact JSON over WebSocket, not binary | ~45 bytes per vehicle; binary only if spike proves gain |
| D14 | Owner VPS with PostgreSQL, not Supabase | Owner decision; R$0 recurring; owner operates host |
| D15 | Read-only WebSocket stream served by API | No client publish path; viewers need no login |
| D16 | Anonymous opaque device tokens (256-bit, SHA-256 hash stored, 30-day sliding expiry) | Small requests; instant revocation; nothing stored for viewers |
| D17 | In-process tick loop every ~5 s | No cold starts; no scheduler quota; low map latency |
| D18 | Hot state in memory, single instance; restart drops live state | Privacy and simplicity; clients resume via `resume` |
| D19 | Cloudflare proxy in front; Caddy at origin; Deno binds localhost; firewall accepts web only from Cloudflare | Hides origin; absorbs floods; free TLS and snapshot caching |
| D20 | Future analytics only on de-identified aggregates; raw tracks never stored | Keeps roadmap open without breaking privacy design |
| D21 | Server libs: Hono, postgres.js, one schema lib (Valibot or Zod), dbmate | Small Deno-friendly stack; each needs version ADR below |

## 2. Infra decisions needed (Pending owner - do not guess)

Per AGENTS.md section 1 and PLAN.md section 19.2, the items below MUST be asked, not guessed.
They affect security, LGPD, persisted data, or public contracts. Status is `Pending owner` until answered.

### 2.1 Host and database

- INFRA-01 - VPS facts. Needed: provider, region, CPU/RAM/disk, OS (Debian/Ubuntu LTS + version), PostgreSQL version, Postgres on same host or private net. PLAN prefers Brazil region for LGPD transfer simplicity and latency (D14, 13.7). Blocks T04, T06, T07.
- INFRA-02 - Staging instance. Needed: yes or no to a second API instance + separate DB/subdomain on the same VPS for simulator and field tests. PLAN marks staging optional. Blocks T04 and T13.
- INFRA-03 - Swap and disk encryption. Needed: what the provider offers (swap off or encrypted, full-disk encryption yes/no). Affects LGPD art. 46 memory hygiene (12.8). Blocks T04.
- INFRA-04 - SSH and admin access. Needed: admin username, SSH source restriction possible or not, 2FA on provider account confirmed. Blocks T04.

### 2.2 Network, TLS, Cloudflare

- INFRA-05 - Domains and DNS. Needed: API domain (proposal `api.<domain>`), static site domain, confirmation DNS is on Cloudflare. Until decided, use `*.pages.dev` and localhost only. Blocks T04, T05, T16, T20. See PLAN 19.2 items 1 and 10.
- INFRA-06 - Cloudflare plan and features. Needed: plan name, WebSocket idle timeout behavior, whether free plan can cache `GET /v1/lines/{id}/vehicles` and `GET /v1/live` with a cache rule, current IP ranges refresh method, Authenticated Origin Pulls yes/no. VERIFY in S2. Blocks T04, T12.
- INFRA-07 - Origin TLS mode. Needed: Caddy automatic TLS vs Cloudflare origin certificate. Blocks T04.
- INFRA-08 - Caddy log policy. Needed: confirm no access logs or IP-free format with short retention (12.8, 13.2). Affects privacy. Blocks T04.

### 2.3 Backups, monitoring, ops

- INFRA-09 - Backup target and key holder. Needed: off-host storage location, who holds the `age` encryption key, confirm 30-day retention. Backups hold pseudonymous device rows only, no location. Blocks T04. See PLAN 19.2 item 11.
- INFRA-10 - Uptime monitor. Needed: which external service pings `GET /v1/health`. It receives only the health URL, no user data. Blocks T05. See PLAN 19.2 item 12.
- INFRA-11 - Deploy method for alpha. Needed: confirm manual deploy by owner via T05 script (default) vs a restricted GitHub workflow with deploy key and approval environment. No production server credentials in CI beyond the approved path. Blocks T05. See PLAN 17.2.
- INFRA-12 - Secret rotation schedule. Needed: confirm 6-month rotation for DB password, env file, SSH keys, tokens, plus on-suspicion rotation. Blocks T04 runbook.

### 2.4 Server runtime pins (ADR required by D21)

Pending S2 results. One ADR each with version, licence, Deno compatibility. Do not add other deps without ADR.

- INFRA-13 - Hono version + JSR source + licence + `Deno.upgradeWebSocket` path. Fallback if poor fit: bare `Deno.serve` plus ~100-line router.
- INFRA-14 - `postgres` (postgres.js) version + licence + TLS/pooling on Deno.
- INFRA-15 - Schema library: Valibot vs Zod. Needed: version, licence, Deno compat, bundle size irrelevance on server but API clarity. Pick one only.
- INFRA-16 - dbmate availability on target OS. VERIFY. Fallback: tiny Deno runner with checksums (PLAN 6.1).
- INFRA-17 - Deno version pin. Needed: latest stable at T06, pinned in `deno.json` and systemd unit, plus exact `--allow-net`, `--allow-env`, `--allow-read` flags. No `--allow-write`, `--allow-run`, `--allow-ffi`, `--allow-sys`.
- INFRA-18 - systemd sandbox flags. Needed: confirm full list in 12.8 works on target OS, esp. `MemoryDenyWriteExecute`, `LimitNOFILE` value, `LimitCORE=0`.

### 2.5 Client and release infra (blocks M0-M9)

- INFRA-19 - Code and data licences. Needed: code licence (suggest AGPL-3.0 or MIT) and compiled data licence (suggest CC BY 4.0 or ODbL). Current `LICENSE` is GPLv2 and conflicts with PLAN 19.2 item 3. Must be resolved in T01 before wider distribution.
- INFRA-20 - Android `applicationId` (proposal `app.busmateus`), app name confirmation. Cannot change after first store upload. Blocks T02. See PLAN 19.2 item 1.
- INFRA-21 - Play account path: limited-distribution (<= 20 devices, no fee) for Phase 0-1 vs Play Console (US$25) with early closed test. VERIFY current tester count and days. Blocks T48. See PLAN 19.2 item 5.
- INFRA-22 - Flutter version pin at M0 (`.fvmrc` or CI `flutter-version`) and `minSdk`/`targetSdk` VERIFY at release. Blocks T02.
- INFRA-23 - Controller identity and contact e-mail for policy and data-subject requests. Blocks T42. See PLAN 19.2 item 2.
- INFRA-24 - Pilot lines (1-3) and first route traces. Blocks T15, T17. See PLAN 19.2 item 6.

Out of infra scope but still pending owner (PLAN 19.2): lawyer/DPO who and when, operator outreach owner and timing, web sharing in alpha yes/no (default viewer first), history/analytics roadmap confirm per D20.

## 3. VERIFY list (must check against official sources, record result here)

Collected from PLAN 3.2 and 19.3. Each gets a dated result entry under section 5 when its spike or task runs.

- V01 (S1): `geolocator` foreground-service with screen off 30 min, swipe-away behavior, `Position.isMocked`, notification action support, Android 13 `POST_NOTIFICATIONS` flow.
- V02 (S2): Deno stable version, permission flags, Hono + `Deno.upgradeWebSocket`, postgres.js TLS/pooling, dbmate on target OS, Cloudflare WebSocket timeout, edge-cache rule, IP ranges, bytes per ping at 15 s vs 90 s cadence.
- V03 (S3): `flutter_map` >= 8.2.0 `BuiltInMapCachingProvider` 50 MB cap API, OSM User-Agent and attribution, fps on low-end device.
- V04 (S4): Flutter Web `--wasm` size/startup, `--no-web-resources-cdn` flag name, service worker default, Screen Wake Lock on iOS PWA, COOP/COEP vs OSM tiles.
- V05 (release): Play foreground-service declaration, closed-test tester count and days, target audience and Data safety wording for location.
- V06 (legal): ANPD Res. CD/ANPD no. 2/2022 small-agent applicability, Res. CD/ANPD no. 15/2024 breach deadline (currently 3 business days), ECA Digital Lei 15.211/2025 applicability, minimum-age wording, 15-day declaration deadline.
- V07 (host): `MemoryDenyWriteExecute` support on target systemd, provider disk-encryption and swap options, `bbox` values against real municipal routes.

## 4. Spikes (not started)

- S1: geolocator foreground service. See V01.
- S2: Deno + Caddy + Cloudflare + postgres.js + dbmate. See V02.
- S3: flutter_map cache and perf. See V03.
- S4: Flutter Web wasm, PWA, wake lock. See V04.

Rule: run spikes before building on their assumptions (AGENTS.md section 3, PLAN.md 0.3).

## 5. Results log (append-only, newest at bottom)

- 2026-10-02: File created. D01-D21 imported from PLAN.md v1.1 as Accepted. INFRA-01 to INFRA-24 opened as Pending owner. V01-V07 opened. No spikes run yet. No code changes yet.
