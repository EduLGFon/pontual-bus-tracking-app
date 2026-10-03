# Changelog

Format: Keep a Changelog. Versioning: `0.1.0-alpha.N` for alpha builds.

## [Unreleased] - 0.1.0-alpha.0

- T01 repo skeleton done (README, CHANGELOG, gitignore, SECURITY, templates, env examples). Restored `app/` directory.
- T02 Flutter shell done (Flutter 3.47.6, applicationId `com.spotnik.pontual`, strict analyzer, empty ProviderScope app, smoke test).
- T03 CI done (pinned actions, analyze plus format plus test, manifest audit, web size report, gitleaks; deno job lands in T06).
- S1 and S2 spikes done (geolocator 14.1.1 plus FGS findings; Deno 2.9.7 plus Hono 4.13.12 plus postgres.js 3.4.9 plus dbmate and Cloudflare findings).
- S3 and S4 spikes done (flutter_map 8.3.2 plus 50 MB cache plus OSM policy; --wasm plus no-CDN plus wake lock findings).
- T06 server skeleton done (Deno 2.9.7, Hono 4.13.12, fail-fast config, health plus metrics, CI server job).
- T07 database done (migration 0001, repositories, runtime config loader, no_location_at_rest, CI postgres plus dbmate).
- T08 security middleware done (Valibot 1.5.0, token auth, device plus consent plus delete routes, AC01 plus AC03 plus AC11 plus AC13 plus AC18 plus AC23).
- T09 pure engine done (attach plus election plus tick plus snapshot, tests 1-18 and 20-24).
- Recorded owner answers round 1 in DECISIONS.md (D22-D28).
