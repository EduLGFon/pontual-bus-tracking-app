# step.md - Current step: T01 repo skeleton

Status: not started. This is the single next step. Do not start T02, T03, or any spike until T01 acceptance passes.

## 1. What T01 is

PLAN.md section 16, Milestone M0. Deliverable: repo skeleton (`app/ server/ data/ tools/ docs/ .github/`), `README.md`, `DECISIONS.md`, `CHANGELOG.md`, `.gitignore`, `LICENSE` decision, `SECURITY.md`, issue and PR templates with the DoD checklist.

Why now: the repo has only `AGENTS.md`, `PLAN.md`, `LICENSE`, `.git/`. Nothing else can be built or tested without the skeleton, version pins, and CI entry points. `DECISIONS.md` exists as of 2026-10-02 but the rest of T01 is missing.

## 2. Done vs remaining

Done:

- `AGENTS.md` present.
- `PLAN.md` v1.1 present.
- `DECISIONS.md` created with D01-D21 imported and INFRA-01 to INFRA-24 opened.
- `LICENSE` file exists but is GPLv2, which conflicts with PLAN 19.2 item 3 (suggest AGPL-3.0 or MIT). Needs owner call in this step, recorded as INFRA-19.

Remaining (all part of this one step):

1. Directories: `app/ server/ data/ tools/ docs/privacy docs/security docs/runbooks docs/field-tests .github/workflows .github/ISSUE_TEMPLATE`.
2. `README.md`: setup, run, test, release placeholders with pinned Flutter and Deno versions marked TODO (pins land in T02 and T06; do not invent version numbers).
3. `CHANGELOG.md`: `0.1.0-alpha.0` unreleased section.
4. `.gitignore`: Flutter, Deno, `build/`, env files (`server/.env`, `env/*.json` except `*.example.json`), keystores, IDE.
5. `server/.env.example` and `env/example.json`: variable names only, no secrets.
6. `SECURITY.md`: contact channel placeholder, supported versions, pointer to PLAN 12.7 incident steps.
7. Issue template and PR template containing the Definition of Done from PLAN 14.10.
8. Owner answers for T01 scope only: code licence (INFRA-19) and confirmation of repo name `busmateus`.

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
