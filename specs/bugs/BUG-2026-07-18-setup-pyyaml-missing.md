---
bug_id: BUG-2026-07-18-setup-pyyaml-missing
status: fixed
severity: high
scope: scripts (setup path)
title: "bigpowers setup crashes when python3 lacks PyYAML (Issue #77)"
---

# BUG-2026-07-18-setup-pyyaml-missing

/ GitHub: https://github.com/danielvm-git/bigpowers/issues/77

## Problem

**Actual behavior:** On a fresh macOS (reported: 15.7.2) with no `.venv` and a
system `python3` that lacks PyYAML, `pnpx bigpowers setup` aborts:

```
python-env: WARN — python3 lacks PyYAML
sync-skills: WARN — targets.yaml missing; using legacy render list
Traceback (most recent call last):
  File ".../scripts/lib/srp-engine.py", line 8, in <module>
    import yaml
ModuleNotFoundError: No module named 'yaml'
❌ Failed: bash scripts/sync-skills.sh
```

**Expected behavior:** `bigpowers setup` completes without PyYAML installed. The
repo already ships a dependency-free parser (`scripts/lib/simple_yaml.py`,
e38s01); the setup path must use it as a fallback rather than hard-crash.

**How to reproduce:**
1. `python3 -m venv /tmp/noyaml` (a fresh venv has no PyYAML).
2. `/tmp/noyaml/bin/python scripts/lib/srp-engine.py --all` → `ModuleNotFoundError`, exit 1.
3. `/tmp/noyaml/bin/python scripts/validate-skill-yaml.py` → "ERROR: PyYAML required", exit 2.

**Security impact:** NONE — install-time crash only; no exploit path.

## Root Cause Analysis

### Reproduce

Under a PyYAML-free interpreter, `srp-engine.py` exits 1 (traceback) and
`validate-skill-yaml.py` exits 2 (`ImportError` → `sys.exit(2)`). Confirmed with
a throwaway venv.

### Isolate

`bin/bigpowers.js:36` runs `bash scripts/sync-skills.sh`, which sources
`scripts/lib/python-env.sh`. `python-env.sh` deliberately **warns and continues**
when the resolved interpreter lacks PyYAML (this is by design, per
BUG-2026-07-04-python-interpreter-fragility — it only pins *which* python3 runs).
Two setup-path scripts then hard-depend on PyYAML:

1. **`scripts/lib/srp-engine.py`** — top-level `import yaml`; invoked at
   `sync-skills.sh:85`. Crashes first (the reported traceback).
2. **`scripts/validate-skill-yaml.py`** — `except ImportError: sys.exit(2)`;
   invoked via `sync-skills.sh:99` → `sync_post_run` → `sync_post_regression_guards`
   (`scripts/lib/sync-post.sh:98,132`), whose `if ! $PYTHON "$validate_script"`
   turns exit-2 into `sync-skills: FAIL … exit 1`. A second landmine, reached only
   once #1 is fixed — so both must be fixed for setup to complete.

`scripts/install.sh` (the second setup step) has no Python/YAML dependency.

Two fallback fidelity gaps surfaced once `simple_yaml` was wired in: it did not
un-escape YAML double-quoted escapes (`\"`) and dropped folded/literal block
scalars (`>` / `|`) entirely — producing over-escaped or empty descriptions for
`align-grid` and `security-review`.

### Hypothesize

Give the two consumers the `simple_yaml` fallback the rest of the repo already
uses (`trace-matrix.py`, `generate-allure-report.sh`), and close the two parser
gaps so the PyYAML-free path is byte-identical to PyYAML. `pip install` was
rejected: PEP 668 externally-managed-environment errors are the exact fragility
this codebase moved away from.

### Verify

Under a PyYAML-free venv: both scripts exit 0, and a full `sync-skills.sh` run
completes with only the (expected, deliberate) PyYAML WARN — no traceback, no
FAIL. Regenerated `.cursor/.gemini/.pi` artifacts are **byte-identical** to the
committed PyYAML-generated ones, proving the fallback is faithful.

## Fix

- `scripts/lib/srp-engine.py` — `import yaml` → try/except shim binding
  `_load_yaml` to `yaml.safe_load` or `simple_yaml.parse_simple_yaml`; both call
  sites use `_load_yaml`.
- `scripts/validate-skill-yaml.py` — same shim (adds `scripts/lib` to
  `sys.path`); `except yaml.YAMLError` → `except Exception`.
- `scripts/lib/simple_yaml.py` — `_yaml_scalar` un-escapes double-quoted scalars;
  new `_fold_block` folds `>`/`|` block scalars to match PyYAML; the parse loop
  captures block-scalar content instead of skipping it.
- `scripts/sync-skills.sh` — corrected the misleading `targets.yaml missing`
  warning (it also fires when `yq` is absent, which is the common case).

**Hardening added:** `scripts/test-setup-no-pyyaml.sh` — recurrence guard.
Asserts srp-engine.py and validate-skill-yaml.py run under a PyYAML-free venv and
that `simple_yaml` output equals PyYAML for every skill's frontmatter.

## Verify steps

→ verify: `bash scripts/test-setup-no-pyyaml.sh`

**Evidence:**
- `bash scripts/test-setup-no-pyyaml.sh` → 3/3 PASS.
- `PATH=/tmp/noyaml/bin:$PATH bash scripts/sync-skills.sh` → exit 0, no traceback;
  `git status` on `.cursor/.gemini/.pi` → clean (fallback ≡ PyYAML).
