# Security Policy

Supported versions: alpha only (`0.1.0-alpha.N`). No stable release yet.

## Report a vulnerability

Contact the owner privately. Do not open a public issue for security findings.
Include: affected version, steps to reproduce, impact, and whether personal or location data is involved.
The owner follows PLAN.md 12.7 (contain with kill switch, assess, fix, notify per LGPD, learn).

## Scope rules (from PLAN.md 12)

- Clients never connect to PostgreSQL.
- No location at rest: coordinates never go to the DB, disk, logs, or metrics.
- No secrets in the repo or in client bundles.
- One task per PR. Security tests in PLAN.md 12.6 block releases.
