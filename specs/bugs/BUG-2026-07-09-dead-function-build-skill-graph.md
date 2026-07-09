---
bug_id: BUG-2026-07-09-dead-function-build-skill-graph
status: open
severity: low
scope: scripts
title: Dead function `skill_graph_show_help` in build-skill-graph.sh
discovered: compliance (cleancode G9/F4)
created: 2026-07-09
---

## Summary

Compliance audit (`bash scripts/audit-compliance.sh`) reports 1 FAIL:
"And dead code and unused functions should be removed (G9, F4)" —
`scripts/build-skill-graph.sh: skill_graph_show_help`.

## Root Cause Analysis

### Reproduce

```bash
npm run compliance
# → cleancode.feature: "dead code and unused functions should be removed" — FAIL
# → Potentially dead functions: scripts/build-skill-graph.sh: skill_graph_show_help
```

### Isolate

`skill_graph_show_help()` is defined at line 15 of `scripts/build-skill-graph.sh`:

```bash
skill_graph_show_help() {
  cat <<EOF
Usage: $(basename "$0") [OPTION]
...
EOF
}
```

The function is **never called** anywhere in the codebase:

```bash
rg "skill_graph_show_help" .
# → ./scripts/build-skill-graph.sh:skill_graph_show_help() {  (definition only)
```

The script has **zero argument parsing** — no `--help`, no `--wiki`, no `shift`, no `case`, no `getopts`. The `--wiki` option referenced in the help text is not implemented.

### Hypothesis

The help function was written as documentation intent, but argument parsing was never implemented. It is dead code per Clean Code G9/F4.

### Verify

Grep confirms the function is defined but has zero call sites. Removing it will not change any behavior.

## Fix Approach

Remove the dead `skill_graph_show_help()` function (lines 15–27). If `--help`/`--wiki` support is needed later, it should be added with proper argument parsing, not a dead function.

## Verify Steps

→ verify:
```bash
# 1. Confirm function is removed
rg "skill_graph_show_help" scripts/build-skill-graph.sh && echo "FAIL: still present" || echo "PASS: removed"

# 2. Script still runs
bash scripts/build-skill-graph.sh 2>&1 | head -5

# 3. Compliance passes
npm run compliance 2>&1 | grep "G9, F4"
```
