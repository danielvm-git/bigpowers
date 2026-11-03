---
bug_id: BUG-2026-11-03-atomic-yaml-writes
status: fixed
severity: high
scope: scripts / specs state
title: "Spec state YAML/JSON is written in place, so a concurrent reader or an interrupted run sees a truncated file (yaml ScannerError)"
files_changed: "scripts/lib/atomic_write.py (new), scripts/test-atomic-writes.sh (new), scripts/yaml-tools.py, scripts/sync-bugs-registry.sh, scripts/lib/trace-stories.py, scripts/lib/trace_renderer.py, scripts/lib/blind-spots.py, scripts/lib/blind-spot-checks.py, scripts/lib/ab_report.py, scripts/lib/run-benchmark.py, scripts/okf-add-references.py, scripts/lib/srp_engine_okf.py, scripts/lib/golden-suite-gates.sh"
approach: "One helper, one shape: same-directory temp file, write, flush, fsync, os.replace (atomic rename), then fsync the directory. Every runtime writer of state YAML/JSON goes through it, and a golden gate proves the race is real before proving it is gone"
risk_level: medium
commit_message: "fix(scripts): write spec state atomically instead of in place"
---

# BUG-2026-11-03: in-place state writes expose truncated YAML

Issue #181 (defect family 6 — YAML parsing & round-trip integrity).

## Problem

- **Actual:** every runtime writer of spec state used `Path.write_text(...)` or `open(..., "w")`:
  truncate the destination, then stream the new bytes. A reader that arrives inside that window —
  the dashboard snapshot loop, a subagent running `bp-yaml-set`, a gate in another shell — parses a
  half-written file and dies with `yaml.scanner.ScannerError`. An agent that is interrupted between
  the truncate and the last chunk leaves the file truncated permanently.
- **Expected:** a state file is always parseable; a reader sees the previous version or the new one.
- **Found in:** `scripts/yaml-tools.py` (issue #181), and 9 further runtime writers found by the
  sibling scan below.

## Root Cause Analysis

1. **Reproduce:** one process writes a ~19 MB YAML document 8 times with `write_text` while another
   polls the file and samples its size. A size that is neither empty nor final is a reader standing
   inside the truncate window: **15 000–20 000 partial samples per run**. The same writes through
   `atomic_write_text`: **0 partial samples** (the inode is swapped, so no intermediate size exists).
2. **Isolate:** `write_text` = `open("w")` + `write` + `close`; the truncate is visible to any other
   process immediately, and the kernel does not make the subsequent writes atomic.
3. **Hypothesize:** routing every state write through one helper that writes a same-directory temp
   file and `os.replace()`s it removes the window entirely — `rename(2)` is atomic on POSIX.
4. **Verify:** `scripts/test-atomic-writes.sh` (a) proves the truncating shape is observable before
   the fix, (b) proves the helper is never observable half-written, (c) statically holds every
   watched writer to the helper.

### Sibling scan (defect family 6, § 7.2)

```bash
grep -rnE '\.write_text\(|\.open\(["'"'"']w["'"'"']' scripts/*.py scripts/lib/*.py
```
Ten runtime writers found; fixtures and one-off migration patchers (`wave_b_hub_patch.py`,
`convert-legado.sh`) excluded — they write new files, not live state.

## Fix

`scripts/lib/atomic_write.py`:

```
temp file in the target directory → write → flush → os.fsync(fd)
→ preserve the target's mode → os.replace(tmp, target) → fsync(parent dir)
```

Same directory is mandatory: `os.replace` is only atomic within one filesystem.

Converted writers: `yaml-tools.py` (state.yaml / execution-status.yaml / epic.yaml / tasks),
`sync-bugs-registry.sh` (registry.yaml + OKF bundles), `trace-stories.py`, `trace_renderer.py`
(traceability matrix, TRACEABILITY_LATEST.md, OKF concepts), `blind-spots.py`,
`blind-spot-checks.py`, `ab_report.py` (AB-*.yaml + jsonl, read by the dashboard while a run
appends), `run-benchmark.py`, `okf-add-references.py`, `srp_engine_okf.py`.

## Regression guard

`atomic-writes` in `scripts/lib/golden-suite-gates.sh`:
- (a) anti-vacuity — the truncating shape *is* caught by a concurrent reader, so a green (b) means
  something;
- (b) zero partial reads through `atomic_write_text`;
- (c) static guard — a new `write_text` in any watched state writer fails the gate by name.

## Evidence

```
PASS (a) plain write_text exposes a partial file (20072 samples)
PASS (b) atomic_write_text: 0 partial samples
PASS (c) all 10 watched state writers use atomic_write
3 passed, 0 failed        (3 consecutive runs, zero flake)
```
Functional checks after conversion: `yaml-tools.py set` preserves the surrounding document and its
ordering, `sync-bugs-registry.sh` is idempotent (no diff), `trace-stories.sh --strict` exits 0,
`check-blind-spots.sh` exits 0, `render_okf_concept()` writes a valid page.
