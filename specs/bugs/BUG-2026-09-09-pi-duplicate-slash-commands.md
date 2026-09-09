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

The Pi package already supplies one prompt template per workflow. Pi exposes those
prompt templates as slash commands. A later extension integration independently began
registering one slash command per source skill under the same names. Pi retains both
providers in autocomplete, so all workflow commands appear twice.

The prompt-template surface predates the extension and is the documented Pi command
mechanism. It also works without requiring extension execution. The extension still
has distinct responsibilities: exposing the unified skill tool and enforcing Git
safety policy. Removing only its duplicate command registrations preserves those
responsibilities and avoids removing an established package artifact.

This is a regression introduced when extension command registration was added. Risk is
**Low** because the fix removes one redundant route while retaining the documented
slash-command route and all non-command extension behavior.

## TDD Fix Plan

1. **RED:** Update the extension runtime smoke test to require zero extension-provided
   workflow commands while confirming prompt templates remain declared by the package.
   The current extension fails because it registers every source skill as a command.
   **GREEN:** Remove per-skill slash-command registration from the extension.
   **verify:** `node scripts/omp-smoke.ts`

2. **RED:** Update the extension integrity gate to reject workflow command registration
   while still requiring the skill tool and Git safety hook.
   **GREEN:** Align extension comments and validation expectations with the separated
   responsibilities.
   **verify:** `bash scripts/validate-omp-extension.sh`

**REFACTOR:** Remove command-only prompt construction and injection helpers if no
remaining extension path uses them; retain shared behavior required by the skill tool.

## Acceptance Criteria

- [x] Pi receives one slash-command provider per Bigpowers workflow.
- [x] Generated Pi prompt templates remain available.
- [x] Native Pi skill discovery remains available.
- [x] The `bigpowers_skill` tool still supports list, get, and run.
- [x] Git safety hooks remain registered.
- [x] Extension smoke and integrity tests pass.
- [x] Full repository verification passes.

## Resolution

Removed per-skill command registration from the extension while retaining generated Pi
prompt templates as the canonical slash-command provider. The extension continues to
register `bigpowers_skill`, session notification, and Git safety hooks. The runtime
smoke now asserts zero extension commands, one prompt-template manifest entry, and a
working `bigpowers_skill run` path.

Focused validation:

- `node scripts/omp-smoke.ts` — pass
- `bash scripts/validate-omp-extension.sh` — pass
- `bash -n scripts/validate-omp-extension.sh` — pass
- `git diff --check` — pass
- `npm run compliance && bash scripts/run-verification-gates.sh && bash scripts/sync-skills.sh && bash scripts/trace-stories.sh --strict` — pass; deterministic golden suite 40/40
