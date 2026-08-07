---
bug_id: BUG-2026-08-06-pi-drops-skills-frontmatter
status: fixed
severity: high
scope: skills / install
title: "pi drops 16 skills as 'description is required' — story tags before frontmatter delimiter break parsing"
---

# BUG-2026-08-06: pi drops 16 skills as "description is required"

## Problem

- **Actual**: pi (v0.82.0, reproducible on current source) reports `description is required` at startup for exactly 16 skills: audit-code, craft-skill, deepen-architecture, deploy, develop-tdd, diagnose-stall, enforce-first, fix-bug, gate-trace, plan-work, quick-fix, request-review, run-evals, smoke-test, validate-contracts, validate-fix. The skills are silently dropped from the `~/.pi/agent/skills/` source of truth (warnings only — no hard failure).
- **Expected**: All 81 skill sources load with their descriptions; zero startup warnings.
- **Reproduce**: Start pi in a bigpowers checkout, or point pi at a fresh `bash scripts/install.sh` (pi target symlinks `~/.pi/agent/skills/<name>` → `skills/<name>` source). The startup banner lists the 16 files under `description is required`. Reporter's original report: https://github.com/danielvm-git/bigpowers/issues/108.

**Security impact: NONE** — no exploit path identified; the defect only drops skill metadata from an agent's prompt context.

## Root Cause Analysis

### Reproduce

Start pi in the bigpowers repo → banner shows `description is required` for the 16 files above. Programmatic reproduction (mirror of pi's parser): for each `skills/*/SKILL.md`, if the file does not start with the two characters `---`, pi returns an empty frontmatter object and rejects the skill. 16 of 81 sources fail this check; the other 65 pass.

### Isolate

Pi's frontmatter extractor has a strict gate: the opening delimiter `---` must be the **first characters of the file** (`startsWith("---")`); otherwise no frontmatter is returned at all. Source skills carry `# story: eNNsYY` / `<!-- story: ... -->` traceability tags on the lines *above* the opening `---`, which trips the gate. Every failing skill shares exactly this shape; no other frontmatter field is involved.

### Hypothesize

Confirmed by reading pi's source (`src/utils/frontmatter.ts` in the opensrc-fetched 0.84.0 tree; identical logic in the installed v0.82.0 `dist/utils/frontmatter.js`): comment lines before `---` ⇒ `yamlString: null` ⇒ `frontmatter: {}` ⇒ `description` undefined ⇒ "description is required" ⇒ skill rejected. The Agent Skills spec also mandates frontmatter at the first line, so pi's behavior is correct — the defect is in the skill sources.

Contributing factors:

1. **Inconsistent tag placement convention**: 65 sources place story tags after the frontmatter (or omit them); the 16 affected place them before it. No rule in CONVENTIONS.md pins tag position (traceability only requires ≥1 `story: eNNsNN` tag per story anywhere in a file).
2. **Validation gap**: `scripts/validate-skill-yaml.py` validates only the generated `.pi/skills/` copies, never the `skills/*/SKILL.md` sources, and never checks the "starts with `---`" rule. The generator (`srp-engine.py`) strips the leading comment lines when rendering `.pi/skills/`, so repo-local pi sessions load the clean generated copies and the defect is masked — but every external install (npm `setup` → symlinks to source) hits it.
3. **Stray artifact**: a malformed `SKILL.md` (empty `name:` and `description: ""`) sits at the root of `.agents/skills/`, producing an extra `description is required` warning.

**Risk level**: High — on machines with only the npm install (no repo checkout) the 16 skills do not load at all; everywhere else it is warning noise plus duplicate skill entries across sources.

## TDD Fix Plan

### Preparation

1. **RED**: Extend `scripts/validate-skill-yaml.py` to also scan source `skills/*/SKILL.md`, asserting (a) each file starts with `---` at byte 0 and (b) frontmatter parses. Currently 16 failures.
   **GREEN**: Add the source-scan path with the `startsWith("---")` assertion; report 16 failures, exit 1.
   **verify**: `python3 scripts/validate-skill-yaml.py` → 16 failures; `bash scripts/sync-skills.sh` guard fails on the new gate.

### Fix — normalize tag placement (16 files)

2. **RED**: All 16 source files fail the "starts with `---`" assertion.
   **GREEN**: For each of the 16, move the leading `# story:` / `<!-- story: -->` lines **inside the frontmatter block** immediately after the opening `---`, converted to `# story:` YAML comments (YAML comments are ignored by pi's parser, PyYAML, and the bundled fallback `simple_yaml.py`). The generator re-renders frontmatter from extracted fields, so generated artifacts (`./.pi/skills/`, `.cursor/rules/`, `.gemini/`) stay byte-identical — no golden drift. `trace-stories.sh` greps the whole tree, so traceability is unaffected.
   **verify**: `python3 scripts/validate-skill-yaml.py` → 0 failures, exit 0; `bash scripts/sync-skills.sh` guard passes; generated `.pi/skills/` diffs empty.

3. **RED**: Remove the stray root `.agents/skills/SKILL.md` (empty name/description template) — or the gate must flag it.
   **GREEN**: Delete the stray file; keep the source scan rule that flags empty `description` (already enforced for generated copies).
   **verify**: `python3 scripts/validate-skill-yaml.py` → no `.agents` diagnostics.

### Hardening

4. **RED**: The new source-frontmatter gate must survive future edits.
   **GREEN**: Wire the extended validator into the `sync-skills.sh` post-generation guard and the verification gates (`bash scripts/run-verification-gates.sh`), so any future SKILL.md with tags above `---` fails CI with a message pointing at the delimiter rule.
   **verify**: `npm run compliance && bash scripts/run-verification-gates.sh` green; introduce a synthetic tag-above-`---` file → gate fails.

**REFACTOR**: Optionally add a one-line note to CONVENTIONS.md (§ skills) that story tags must live inside the frontmatter block or below it — never above the opening `---`.

## Acceptance Criteria

- [ ] All 81 source `skills/*/SKILL.md` files start with `---` at byte 0
- [ ] `validate-skill-yaml.py` scans sources and generated copies; 0 failures
- [ ] pi startup shows zero `description is required` warnings for the 16 skills
- [ ] Generated artifacts unchanged (no `.pi/skills/` / `.cursor/` / `.gemini/` churn)
- [ ] `trace-stories.sh --strict` still passes (tag position independence)
- [ ] Stray `.agents/skills/SKILL.md` removed or valid
- [ ] Regression gate wired into sync-skills.sh + verification gates

## Resolution

**Fixed:** 2026-08-07, merged as `3d4f0cf3` (PR #109), released in v2.87.3.

**Root cause confirmed:** pi's frontmatter extractor (`src/utils/frontmatter.ts` — `if (!normalized.startsWith("---")) return { yamlString: null }`) requires the opening `---` at byte 0. 16 source `skills/*/SKILL.md` files placed `# story:` / `<!-- story: -->` tags above the delimiter, so pi returned no frontmatter → no description → skill dropped as "description is required" (issue #108). In-repo the defect was masked because `srp-engine.py` strips the tags when generating `.pi/skills/`; every external install (symlinked sources) hit it.

**Fix applied (3 files + 16 skills + 1 deletion):**
- Moved leading story tags **inside** the frontmatter block as `# story:` YAML comments in the 16 affected SKILL.md sources (valid for pi, PyYAML, and bundled `simple_yaml.py`; `trace-stories.sh` greps the whole tree — traceability unaffected).
- `scripts/validate-skill-yaml.py`: now scans **sources + generated copies** with a new R1 rule (file must start with `---` at byte 0); wired into the `sync-skills.sh` post-generation guard.
- `scripts/lib/skill-common.sh`: `parse_frontmatter` / `parse_frontmatter_okf` skip comment lines (tags inside frontmatter no longer leak into `skills-lock.json` descriptions or the search index).
- Removed stray `.agents/skills/SKILL.md` (empty name/description).

**Hardening added:** the extended validator is part of the sync guard, so any future SKILL.md with tags above the `---` fails generation. Generated `.pi/`, `.cursor/`, `.gemini/` trees verified byte-identical after sync (no artifact churn).

**Evidence:**
- Validator: 162/162 (81 sources + 81 generated), RED→GREEN (16 failures → 0)
- `npm run compliance`: 98/98 PASS
- Golden suite: 38/38 PASS
- `trace-stories.sh --strict`, `check-skill-links`, `check-skill-size`: all PASS
- CI: PR #109 — checks failed only on GitHub Actions infrastructure (`Service Unavailable` at "Set up job", runner provisioning, snyk quota); no code-related CI failure. Locally green on all gates before merge.
