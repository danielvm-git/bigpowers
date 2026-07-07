---
bug_id: BUG-2026-07-06-gate-trace-matrix-oversized
status: fixed
severity: medium
scope: skills/gate-trace
title: "gate-trace: Underlying matrix compilation engine trace-matrix.py exceeds line limits"
---

# BUG-2026-07-06-gate-trace-matrix-oversized

## Problem

**Actual behavior:** The Python script `scripts/lib/trace-matrix.py` responsible for compiling and evaluating traceability metrics grew to 523 lines. This violated both the 300-line context window limit and the 500-line newspaper metaphor limit.

**Expected behavior:** Shared python modules and engines should be small, cohesive, and remain under 300 lines of code.

**How to reproduce:**
1. Run `bash specs/verifications/steps/and-files-should-be-small-enough-to-avoid-context-window-truncation-300-lines.sh`
2. Run `bash specs/verifications/steps/and-files-should-remain-under-500-lines-newspaper-metaphor.sh`
3. Note `scripts/lib/trace-matrix.py` in the failure list (523 lines).

**Security impact:** NONE — file-size compliance only; no security exploit path identified.

## Root Cause Analysis

### Reproduce

With waivers disabled, compliance audit flagged `scripts/lib/trace-matrix.py` at 523 lines under both the 300-line (akita.feature) and 500-line (cleancode.feature) gates. `wc -l scripts/lib/trace-matrix.py` confirmed 523.

### Isolate

The script combined four responsibilities in one file:
- Custom YAML parsing (`parse_simple_yaml`)
- Story inventory building from release-plan and epic capsules
- Tag scanning and oracle-tier resolution (heuristic + task refs)
- Output rendering (JSON matrix, markdown report, OKF wiki bundle)

No other module imported these helpers — the coupling was internal monolith growth, not cross-module leakage.

### Hypothesize

1. **Monolithic growth** (most likely) — parser, matrix logic, and renderers were added incrementally without extraction.
2. **Duplicate engine** — `trace-stories.py` is the live engine called by `trace-stories.sh`; `trace-matrix.py` is a parallel implementation that inherited the same bloat pattern.
3. **Waiver masking** — waivers.yaml exempted the file-size step, hiding the problem from the denominator.

Falsification: extracting `parse_simple_yaml` and emit functions into `scripts/lib/simple_yaml.py` and `scripts/lib/trace_renderer.py` should drop `trace-matrix.py` below 300 without changing observable matrix output.

### Verify

After extraction:
- `wc -l scripts/lib/trace-matrix.py` → 252 (under 300 and 500)
- `wc -l scripts/lib/simple_yaml.py` → 130
- `wc -l scripts/lib/trace_renderer.py` → 147
- File-size compliance steps pass with waivers cleared
- `bash scripts/trace-stories.sh --strict` exits 0

**Risk level:** Low — mechanical extraction; no behavior change to the live `trace-stories.py` engine.

## TDD Fix Plan

1. **RED:** Assert `trace-matrix.py` exceeds 300 lines (pre-fix baseline).
   **GREEN:** N/A — characterization of the bug.
   **verify:** `wc -l scripts/lib/trace-matrix.py | awk '$1 > 300 {exit 0} {exit 1}'`

2. **RED:** File-size compliance step fails on `trace-matrix.py`.
   **GREEN:** Extract `parse_simple_yaml` to `scripts/lib/simple_yaml.py`.
   **verify:** `python3 -c "from scripts.lib.simple_yaml import parse_simple_yaml; assert parse_simple_yaml('key: val')['key']=='val'"`

3. **RED:** `trace-matrix.py` still over 300 after parser extraction.
   **GREEN:** Extract `emit_matrix_json`, `emit_trace_md`, `emit_okf_bundle` to `scripts/lib/trace_renderer.py`.
   **verify:** `wc -l scripts/lib/trace-matrix.py | awk '$1 <= 300 {exit 0} {exit 1}'`

4. **RED:** Compliance gate still waives file-size failures.
   **GREEN:** Remove trace-matrix entries from `waivers.yaml` and CONVENTIONS file-size exceptions table.
   **verify:** `bash specs/verifications/steps/and-files-should-be-small-enough-to-avoid-context-window-truncation-300-lines.sh`

**REFACTOR:** Add `scripts/test-trace-matrix-size.sh` as recurrence guard.

## Acceptance Criteria

- [x] `trace-matrix.py` ≤ 300 lines
- [x] `trace-matrix.py` ≤ 500 lines
- [x] Extracted modules importable and under 300 lines each
- [x] File-size compliance steps pass without waiver
- [x] `bash scripts/trace-stories.sh --strict` exits 0
- [x] `npm run compliance` passes
- [x] `bash scripts/run-verification-gates.sh` passes

## Resolution

**Fixed:** 2026-07-06
**Root cause confirmed:** Monolithic trace-matrix engine combined YAML parsing, matrix compilation, and output rendering in a single 523-line file.
**Fix applied:** Extracted `simple_yaml.py` (parser) and `trace_renderer.py` (JSON/MD/OKF emitters); `trace-matrix.py` reduced to 252 lines. Cleared file-size waivers and updated CONVENTIONS exceptions table.
**Hardening added:** `scripts/test-trace-matrix-size.sh` — asserts trace-matrix.py and extracted modules stay under 300 lines.
**Verified by:** `bash scripts/test-trace-matrix-size.sh && npm run compliance && bash scripts/run-verification-gates.sh`
