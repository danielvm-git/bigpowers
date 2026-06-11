---
name: stocktake-skills
description: Sequential subagent batch audit of the bigpowers skill catalog — Quick Scan (changed only) or Full (all skills). Use during sustain phase, before a major release, or when catalog drift is suspected.
model: sonnet
---

# Stocktake Skills
> **HARD GATE** — **HARD GATE** — Skill inventory must be current. Missing HARD GATEs, stale descriptions, or broken verify commands are defects, not cosmetic. Fix them in `evolve-skill`.


Audit SKILL.md catalog for drift, stale triggers, missing HARD GATEs, and INDEX mismatches.

## Modes

| Mode | Scope |
|------|-------|
| **Quick Scan** | Skills changed since last tag or in current diff |
| **Full** | All 58 skills per SKILL-INDEX.md |

## Process

1. Run mode; for each skill check: exists, verb-noun, &lt;300 lines total, HARD GATE present, INDEX row matches.
2. Write `specs/STOCKTAKE-<date>.md` with findings table (skill, issue, severity).
3. Critical findings → `plan-work` story; cosmetic → `evolve-skill` candidate.

## Verify

→ verify: `test -f specs/STOCKTAKE-*.md && echo OK || echo MISSING`

See [REFERENCE.md](REFERENCE.md) for checklist.
