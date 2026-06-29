---
name: trace-requirement
model: haiku
description: Link story IDs from specs/release-plan.yaml + epic capsule directories to the implementing code and tests. Produces specs/TRACEABILITY_LATEST.md. Use when you want to verify coverage of a release plan, audit which stories are implemented, or find "dark" stories with no code.
---

# Trace Requirement

Build a traceability matrix from `specs/release-plan.yaml + epic capsule directories` to implementing code and tests. Surfaces gaps in both directions: stories with no code, and code with no story.

## Pre-flight

> **HARD GATE** — `specs/release-plan.yaml + epic capsule directories` must exist. If it doesn't, run `plan-release` first.

→ verify: `[ -f specs/release-plan.yaml + epic capsule directories ] && echo "ready" || echo "BLOCKED: run plan-release first"`

Read `specs/release-plan.yaml + epic capsule directories` fully before proceeding.

## Process

### 1. Extract story IDs

From release-plan.yaml, collect all story IDs (e.g. `1.1`, `1.2`, `2.1`).

→ verify: `grep -o "Story [0-9]\+\.[0-9]\+" specs/release-plan.yaml + epic capsule directories | sort -u`

### 2. Search for story tags in code

Look for `// story: X.Y` or `# story: X.Y` comments in source files and tests:

```
grep -rn "story: " . --include="*.ts" --include="*.js" --include="*.py" --include="*.sh" | grep -v node_modules
```

→ verify: `grep -rn "story: " . --include="*.ts" --include="*.sh" | wc -l`

### 3. Build the matrix

For each story ID:
- **Implemented**: list files that contain `// story: X.Y`
- **Tested**: list test files that contain `// story: X.Y`
- **Dark**: story has no tag in any file — flag as unimplemented

For each tagged file with no matching story ID in release-plan.yaml:
- **Orphan**: code exists but story was removed or never planned — flag for cleanup

### 4. Write specs/TRACEABILITY_LATEST.md

```
## Story Coverage

| Story | Title              | Files | Tests | Status    |
|-------|--------------------|-------|-------|-----------|
| 1.1   | [title]            | 2     | 1     | Covered   |
| 1.2   | [title]            | 0     | 0     | Dark      |

## Orphan Code (no story tag)
- [file]: contains untagged implementation

## Gaps (dark stories)
- Story 1.2: no implementation found → run plan-work

## Coverage summary
Stories: [X] covered / [Y] dark / [Z] total
```

→ verify: `grep -c "Covered\|Dark" specs/TRACEABILITY_LATEST.md`

Suggest `plan-work` for each dark story found.
