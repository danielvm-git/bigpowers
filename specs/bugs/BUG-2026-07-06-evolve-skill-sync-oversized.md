---
bug_id: BUG-2026-07-06-evolve-skill-sync-oversized
status: open
severity: medium
scope: skills/evolve-skill
title: "evolve-skill: Underlying compilation script sync-skills.sh exceeds line limits and contains duplicate helper function names"
---

# BUG-2026-07-06-evolve-skill-sync-oversized

## Problem

**Actual behavior:** The compiler script `scripts/sync-skills.sh` has grown to 707 lines, violating both the 300-line context window limit and the 500-line newspaper metaphor limit. It also contains duplicate helper functions.
- `scripts/sync-skills.sh` — 707 lines (exceeds 300 and 500 lines)
- Defines duplicate symbols `show_help`, `usage`, `fail`, `pass`, etc.

**Expected behavior:** Code compilation and rule synchronization should reside in small, modular scripts under 300 lines with unique function signatures.

**How to reproduce:**
1. Run `bash scripts/run-verification-gates.sh` with waivers disabled (e.g., hidden `waivers.yaml`).
2. Observe the failures in `akita.feature` (file size > 300, duplicate grep hits) and `cleancode.feature` (file size > 500).

## Root Cause Analysis
Monolithic script architecture. Build and verification logic for compiling skill structures was kept in a single shell script `sync-skills.sh` which expanded as new validations were added.

## Proposed Resolution
Refactor `scripts/sync-skills.sh` by splitting validation and file generation logic into dedicated sub-scripts or python helpers under `scripts/lib/`, keeping the main orchestrator script below 300 lines.
