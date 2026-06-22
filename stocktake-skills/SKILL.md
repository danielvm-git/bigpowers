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
| **Full** | All skills per SKILL-INDEX.md + catalog audit |
| **--verify** | Run `bash scripts/run-skill-verify.sh` and append health results to the stocktake report |

## Process

1. Run `bash scripts/audit-catalog.sh` to verify pi/skills ↔ source SKILL.md sync. Mismatch is a critical finding.
2. Run mode; for each skill check: exists, verb-noun, &lt;300 lines total, HARD GATE present, INDEX row matches.
3. Write `specs/STOCKTAKE-<date>.md` with findings table (skill, issue, severity).
4. **Effectiveness report (--full mode only):** Read `specs/state.yaml` `metrics.skill_timings` and report:
   - Top 5 most-used skills (by calls, total_seconds)
   - Skills with zero calls (potential dead weight)
   - Skills with high average time (candidates for `evolve-skill`)
5. Critical findings → `plan-work` story; cosmetic → `evolve-skill` candidate.
6. **--verify mode:** Run `bash scripts/run-skill-verify.sh` and append a `## Verify Health` section to the stocktake report: `"N/68 PASS, M FAIL, K SKIP"`. FAIL skills are critical findings and go straight to `plan-work`.

### Skill timing data (`metrics.skill_timings`)

In `--full` mode, read `specs/state.yaml` `metrics.skill_timings` for per-skill usage stats:

```yaml
metrics:
  skill_timings:
    survey-context:
      calls: 12
      total_seconds: 180
      avg_seconds: 15.0
    develop-tdd:
      calls: 30
      total_seconds: 5400
      avg_seconds: 180.0
```

Timing data is populated by `scripts/bp-timing.sh start|end <skill>` calls within critical-path skills.

## Verify

→ verify: `test -f specs/STOCKTAKE-*.md && echo OK || echo MISSING`

See [REFERENCE.md](REFERENCE.md) for checklist.
