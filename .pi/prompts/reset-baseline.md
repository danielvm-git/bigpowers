---
description: Restore the project to a known clean state between agent runs or experiments. Use between benchmark runs, after a failed spike, or when user wants a clean working tree.model: haiku
---


# Reset Baseline

> **HARD GATE** — Confirm with user before any destructive git operation. Never `reset --hard` without explicit approval.

## Process

1. `git status` — list uncommitted and untracked files.
2. Ask: stash, discard, or keep each category.
3. Safe defaults: `git stash push -u -m "reset-baseline"` for WIP; never force-push.
4. Re-run `setup-environment` after reset.
5. Run test baseline from `kickoff-branch` verify command.

## Verify

→ verify: `git status --short | wc -l | awk '{if($1==0) print "OK"; else print "DIRTY:" $1}'
