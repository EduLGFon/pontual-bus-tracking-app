# Pontual

Independent, non-official crowd-sourced bus tracker for Sao Mateus, ES, Brazil.
No affiliation with Viacao Sao Gabriel or the municipality.

- Product name: Pontual
- Android applicationId: `com.spotnik.pontual`
- Design contract: `PLAN.md`
- Agent rules: `AGENTS.md`
- Decisions: `DECISIONS.md`

## Layout

- `app/` - Flutter client (Android + Web/PWA). Created in T02.
- `server/` - Deno/TypeScript API + PostgreSQL migrations. Created in T06/T07.
- `data/` - Static timetable source of truth (`data/lines/*.json`,
  `data/routes/*`). Built in T14.
- `tools/` - Deno tooling and simulator (T13/T14).
- `docs/` - `privacy/`, `security/`, `runbooks/`, `field-tests/`.
- `.github/` - CI and templates.

## Setup (T01 skeleton)

Clone and read `PLAN.md` sections 0, 16, 19 plus `DECISIONS.md` section 6.

- Flutter version: TODO (pinned in T02, see DECISIONS.md INFRA-22).
- Deno version: TODO (pinned in T06, see DECISIONS.md INFRA-17).
- Client env: copy `env/example.json` to `env/dev.json` and set `API_BASE_URL`
  and `STATIC_BASE_URL`. No secrets in client env.
- Server env: copy `server/.env.example` to a root-owned `server/.env` on the
  host only. Never commit it.

## Run / test / release

- T02 defines `flutter analyze` and `flutter test` from `app/`.
- T06 defines `deno fmt`, `deno lint`, `deno check`, `deno test` from `server/`.
- T14 defines the data build. Do not invent the command before then.
- Release follows PLAN.md 17.3 and 17.5. Deploys are manual by the owner in
  alpha.

## Domains (TBD)

API and static domains are undecided (DECISIONS.md D22, INFRA-05). Until then:
static on `*.pages.dev`, API on localhost for dev.
