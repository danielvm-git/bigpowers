---
bug_id: BUG-2026-07-06-craft-skill-sync-oversized
status: open
severity: medium
scope: skills/craft-skill
title: "craft-skill: Underlying compilation script sync-skills.sh exceeds line limits and contains duplicate helper function names"
---

# BUG-2026-07-06-craft-skill-sync-oversized

## Problem

**Actual behavior:** The underlying compilation and sync engine `scripts/sync-skills.sh` has grown to 707 lines, violating both the 300-line context window limit and the 500-line newspaper metaphor limit. It also contains duplicate helper functions.
- `scripts/sync-skills.sh` — 707 lines (exceeds 300 and 500 lines)
- Defines duplicate symbols `show_help`, `usage`, `fail`, `pass`, etc.

**Expected behavior:** Code compilation and rule synchronization should reside in small, modular scripts under 300 lines with unique function signatures.

**How to reproduce:**
1. Run `bash scripts/run-verification-gates.sh` with waivers disabled (e.g., hidden `waivers.yaml`).
2. Observe the failures in `akita.feature` (file size > 300, duplicate grep hits) and `cleancode.feature` (file size > 500).

## Root Cause Analysis
Procedural build and verification logic for the skills compiler was kept in a single monolithic script `sync-skills.sh`. As rule synchronization, markdown validation, and package generation features were added, the script expanded past compliance caps.

## Proposed Resolution
Refactor `scripts/sync-skills.sh` by splitting validation and file generation logic into dedicated sub-scripts or python helpers under `scripts/lib/`, keeping the main orchestrator script below 300 lines.
