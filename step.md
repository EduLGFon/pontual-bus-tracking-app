# step.md - Current step: T01 repo skeleton

Status: done 2026-10-02. Next: T02. Do not start T03 or any spike until T02 acceptance passes.

## 1. What T01 is

PLAN.md section 16, Milestone M0. Deliverable: repo skeleton (`app/ server/ data/ tools/ docs/ .github/`), `README.md`, `DECISIONS.md`, `CHANGELOG.md`, `.gitignore`, `LICENSE` decision, `SECURITY.md`, issue and PR templates with the DoD checklist.

Why now: the repo has only `AGENTS.md`, `PLAN.md`, `LICENSE`, `.git/`. Nothing else can be built or tested without the skeleton, version pins, and CI entry points. `DECISIONS.md` exists as of 2026-10-02 but the rest of T01 is missing.

## 2. Done vs remaining

Done 2026-10-02 (owner answers D22-D28 recorded):

- `AGENTS.md`, `PLAN.md` present.
- `DECISIONS.md` with D01-D21 plus owner round 1 (D22-D28).
- `LICENSE` kept as GPLv2 per owner (D23).
- Directories: `app/ server/ data/ tools/ docs/privacy docs/security docs/runbooks docs/field-tests .github/workflows .github/ISSUE_TEMPLATE env/`.
- `README.md` (name Pontual, appId `com.spotnik.pontual`, domains TBD), `CHANGELOG.md`, `.gitignore`, `SECURITY.md`.
- `env/example.json`, `server/.env.example` (names only, dummy values).
- PR template and task issue template with DoD checklist.
- Verified: tree lists skeleton, `git status` shows only intended new files, secret scan clean (only spec text matches), no em dashes.

Remaining: commit as `chore: add repo skeleton (T01)`.

## 3. Acceptance criteria (from PLAN T01)

- Clone plus README steps work on a clean machine.
- No secrets in the tree. No env values beyond example files.

## 4. Verify (run in this order, record output in the PR)

1. `ls -R` shows the skeleton and no `build/`, no `.env`, no keystore.
2. `git status --short` shows only intended new files.
3. `grep -r -i -E "DATABASE_URL|bm1_|BEGIN (RSA )?PRIVATE KEY" --exclude-dir=.git .` returns nothing.
4. `git log --oneline -1` plus `git diff --stat` confirm one logical change (T01 only).

No formatter, analyzer, or test run is possible yet. T02 creates the Flutter project and T03 creates CI. Do not claim those checks.

## 5. Rules for this step

- One logical change only. No app code, no server code, no dependencies, no data files beyond placeholders.
- Do not invent: Flutter version, Deno version, API URLs, VPS facts, domains, or licence. Mark them TODO with pointer to `DECISIONS.md` INFRA item.
- Docs language English. No em dashes. Conventional commit: `chore: add repo skeleton (T01)`.

## 6. Next step after T01 passes

T02 (`flutter create` + pins + analyzer config), then T03 (CI), then S1 and S2 spikes in parallel before T06. T04 and T05 need owner infra answers (INFRA-01 to INFRA-12) and cannot complete without them.
