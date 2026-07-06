---
bug_id: BUG-2026-07-06-evolve-skill-sync-oversized
status: fixed
severity: medium
scope: skills/evolve-skill
title: "evolve-skill: Underlying compilation script sync-skills.sh exceeds line limits and contains duplicate helper function names"
---

# BUG-2026-07-06-evolve-skill-sync-oversized

## Problem

Same root script as BUG-2026-07-06-craft-skill-sync-oversized — `scripts/sync-skills.sh` at 707 lines with shadowed `parse_frontmatter`.

## Resolution

Fixed by craft-skill-sync-oversized refactor — see that bug file for details.
