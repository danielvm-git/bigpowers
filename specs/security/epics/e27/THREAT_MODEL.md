# Threat Model — e27: Specs Output Naming Convention

**Date:** 2026-06-29
**Risk Level:** LOW

## Surface Area

Pure documentation change: rename 7 output path strings inside SKILL.md files and 1
variable in `scripts/build-skill-index.sh`. No runtime code, no API surface, no data
processed or persisted. Only text files are modified.

## Vulnerability Categories

| Category | Assessment |
|----------|-----------|
| Injection | N/A — no code execution paths modified |
| Path traversal | N/A — paths stay within `specs/` subtree, no user-controlled input |
| Information disclosure | N/A — documentation project; no credentials or secrets touched |
| Denial of service | N/A — no runtime impact |
| Supply chain | Low — `build-skill-index.sh` OUT variable changed; if the new path were writable by an attacker this could be exploited, but the path is within the repo's `specs/` directory under version control |
| Broken access control | N/A — no auth/authz in scope |

## Mitigations

- Review that new `_LATEST.md` paths stay within `specs/` root (no traversal)
- Confirm `scripts/build-skill-index.sh` output is committed to version control (not writable at runtime by CI workers with excessive permissions)
- Run `sync-skills.sh` in CI to detect stale artifact paths early

## Verdict

**No security gates required.** Proceed to step 1.
