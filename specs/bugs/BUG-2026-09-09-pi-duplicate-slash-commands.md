---
bug_id: BUG-2026-09-09-pi-duplicate-slash-commands
status: resolved
severity: medium
scope: extensions / pi
title: "Pi shows every Bigpowers slash command twice (#121)"
issue: https://github.com/danielvm-git/bigpowers/issues/121
files_changed: "extensions/omp-hooks.ts, scripts/omp-smoke.ts, scripts/validate-omp-extension.sh, README.md, CONTRIBUTORS.md"
approach: "Keep Pi prompt templates as the canonical slash-command provider and remove redundant extension command registration"
risk_level: low
commit_message: "fix(pi): prevent duplicate Bigpowers slash commands"
---

# BUG-2026-09-09: Pi shows every Bigpowers slash command twice (#121)

## Problem

- **Actual:** Installing Bigpowers 2.88.1 or newer as a Pi package makes every
  Bigpowers workflow appear twice in slash-command autocomplete.
- **Expected:** Each workflow appears once while native skill discovery, explicit
  slash invocation, the `bigpowers_skill` tool, and Git safety guards remain available.
- **Reproduce:** Install Bigpowers as a Pi package, start Pi, type `/`, and inspect
  entries such as `/commit-message` or `/grill-me`.

**Security impact: NONE** — this is a command-discovery usability defect. No security
exploit path was identified.

## Root Cause Analysis

Pi merges slash-command providers without deduplicating by name. In
`packages/coding-agent/src/modes/interactive/interactive-mode.ts`, autocomplete
concatenates `templateCommands` (from `package.json` `pi.prompts` → `.pi/prompts/`)
and `extensionCommands` (from `pi.registerCommand()` in `extensions/omp-hooks.ts`).

Bigpowers ships both surfaces for every skill since v2.88.1 (e82 OMP extension, #118):

1. **Prompt templates (pre-existing):** `package.json` declares `"prompts": ["./.pi/prompts"]`;
   `sync-skills.sh` generates one `.md` template per skill.
2. **Extension commands (new in 2.88.1):** `omp-hooks.ts` loops `discoverSkills()` and
   calls `pi.registerCommand(skill.name, …)` for each skill.

Same names, same descriptions → duplicate autocomplete entries for all ~81 skills.

The prompt-template surface predates the extension and is the documented Pi command
mechanism. It works without requiring extension execution. The extension retains distinct
responsibilities: `bigpowers_skill` tool and Git safety hooks.

**Prior art:** Related to BUG-2026-09-05-pi-omp-extension-load-crash (#119) — same
extension file, different failure mode (startup crash vs duplicate commands).

## TDD Fix Plan

1. **RED:** Update `scripts/omp-smoke.ts` to require zero extension-provided workflow
   commands while confirming prompt templates remain declared by the package.
   **GREEN:** Remove per-skill `registerCommand` loop from `extensions/omp-hooks.ts`.
   **verify:** `node scripts/omp-smoke.ts`

2. **RED:** Update `scripts/validate-omp-extension.sh` to reject `pi.registerCommand`
   while still requiring the skill tool and Git safety hook.
   **GREEN:** Align extension comments and validation expectations.
   **verify:** `bash scripts/validate-omp-extension.sh`

## Acceptance Criteria

- [x] Pi receives one slash-command provider per Bigpowers workflow.
- [x] Generated Pi prompt templates remain available.
- [x] Native Pi skill discovery remains available.
- [x] The `bigpowers_skill` tool still supports list, get, and run.
- [x] Git safety hooks remain registered.
- [x] Extension smoke and integrity tests pass.
- [x] Full repository verification passes.

## Resolution

Removed per-skill `registerCommand` from `extensions/omp-hooks.ts`. Generated Pi
prompt templates (`.pi/prompts/`) remain the sole slash-command provider. The
extension still registers `bigpowers_skill`, session notification, and Git safety
hooks. Regression coverage in `scripts/omp-smoke.ts` and
`scripts/validate-omp-extension.sh` rejects duplicate command registration.

Focused validation:

- `node scripts/omp-smoke.ts` — pass
- `bash scripts/validate-omp-extension.sh` — pass
- `npm run compliance && bash scripts/run-verification-gates.sh && bash scripts/sync-skills.sh && bash scripts/trace-stories.sh --strict` — pass; golden suite 40/40
