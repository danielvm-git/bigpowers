---
bug_id: BUG-2026-07-03-yaml-roundtrip-corruption
status: fixed
severity: critical
scope: release-pipeline
title: "Release prepare-hook corrupts YAML cockpit via lossy round-trip — 40 spec files flattened and committed"
risk_level: critical
fix_branch: fix-validate-specs-yaml-real-parser
---

## Summary

The semantic-release `prepareCmd` destroys the project's YAML spec cockpit on
**every release**. As of 2026-07-03, **40 spec YAML files are corrupt and
committed to `main`**, including the two most load-bearing files:
`specs/release-plan.yaml` (collapsed from ~470 lines to 49 lines of garbage)
and `specs/state.yaml`.

This is the root cause of the traceability gate seeing only 1 story (see
[[BUG-2026-07-03-trace-engine-vacuous-gate]]) and is the same fail-open class
as the earlier validate-okf incidents.

## Root Cause

`.releaserc.json` wires a prepare hook:

```json
"prepareCmd": "bash scripts/sync-version-mirrors.sh ${nextRelease.version}"
```

`scripts/sync-version-mirrors.sh` calls `python3 scripts/yaml-tools.py set` to
stamp the new version into `specs/state.yaml` (`bigpowers_version`) and
`specs/release-plan.yaml` (`release.version`).

`scripts/yaml-tools.py` reads with a lossy hand-rolled `_parse_simple_yaml()`
and re-serializes with `dump_yaml()`. The round trip is **not information-
preserving**:

- All nesting is flattened to a fixed 2-space indent, destroying list/mapping structure.
- Block scalars (`note: >`, `rationale: >`) are emitted as `key: ">"` and their prose bodies are left as orphan lines.
- Every colon inside prose (`Source: "market survey..."`, `Delivered: "..."`) becomes a bogus top-level key.

Because this runs inside `@semantic-release/git`, the flattened file is
committed automatically as `chore(release): x.y.z [skip ci]` — so the
corruption is invisible in normal workflow and accumulates every release.

Ironic provenance: this hook was introduced as the *fix* for
[[BUG-2026-07-03-version-mirror-drift]]. The fix for drift created the
corruption.

## Blast Radius (measured 2026-07-03)

40 corrupt files confirmed via `python3 -c "import yaml; yaml.safe_load(open(f))"`:

- `specs/release-plan.yaml` (49L, was ~470L) — epic index destroyed
- `specs/state.yaml` (86L)
- `specs/epics/e36-doc-dedup/epic.yaml`, `e43-showcase-repo/epic.yaml`, `e46-risk-based-verification/epic.yaml` (e43/e46 born corrupt — no clean git version exists)
- ~33 `*-tasks.yaml` files, mostly under `specs/epics/archive/`
- `specs/benchmarks/reports/BASELINE-GOLDEN.yaml`, `specs/verifications/e13s03-verify.yaml`

## Fix Approach

1. **Stop the bleeding:** rewrite `scripts/yaml-tools.py` to use PyYAML
   (`yaml.safe_load` / `yaml.safe_dump`, installed 6.0.3) for both read and
   write, OR change `sync-version-mirrors.sh` to a surgical in-place line edit
   (`sed`-style single-field replace) that never re-serializes the whole file.
   Do not cut a release until this lands.
2. **Recover the 40 files** — reconstruct `release-plan.yaml` + `state.yaml`
   from the pre-corruption structure plus the ~224 still-valid capsule files;
   git-restore archive `*-tasks.yaml` where a clean version exists; hand-rebuild
   e43/e46 epic.yaml (born corrupt). Recovery source is a data-loss decision:
   reconstruct-to-preserve-plan vs git-restore-and-lose-recent-planning.
3. Depends on [[BUG-2026-07-03-validate-specs-no-real-parser]] landing first so
   recovery is gated by a real parse check.

## Verify Steps

- [x] All real specs parse — `bash scripts/validate-specs-yaml.sh && echo OK`.
      Adjusted from the original literal glob command to exclude
      `specs/verifications/fixtures/**`, which the G-08 golden check (added
      while fixing the prerequisite bug) deliberately fills with broken YAML
      for negative-path testing; `validate-specs-yaml.sh` now implements this
      exclusion itself.
- [x] `bash scripts/sync-version-mirrors.sh 9.9.9-test` (the actual release
      prepare-hook, run for real, then reverted) — both `release-plan.yaml` and
      `state.yaml` parsed cleanly afterward, `release.version` correctly updated
      to `9.9.9-test`, and **the epics[] list still had all 13 entries** (not
      destroyed). This proves the fix holds through the real corrupting pathway,
      not just in isolated tests. Reverted via backup copies — `git status`
      confirms no residual diff.
- [x] `assert len(d['epics'])>=30` — **superseded, not met by design.** The
      original assumption (a ~470-line file with 30+ live epic entries) predates
      the recovery decision to scope `epics[]` to active/proposed epics only (13
      entries); the other 33 are done and referenced via `done_epics_summary`
      instead of re-listed. See resolution below.
- [x] `bash scripts/run-golden-suite.sh` — 6/6 passed, overall: pass (not in the
      original verify list, but the actual pre-merge gate this repo runs).

## Resolution (2026-07-03)

**Root cause fixed:** `scripts/yaml-tools.py` rewritten to use `yaml.safe_load`/
`yaml.safe_dump` instead of the hand-rolled parser (no more silent corruption on
the next release). New `scripts/golden-g09-yaml-roundtrip.sh` proves it
losslessly round-trips a list + block-scalar fixture; verified RED against the
old parser (via `git stash`), GREEN against the fix.

**Recovery, by file:**
- `specs/release-plan.yaml` — rebuilt from clean ground truth, not the
  scrambled fragments: `specs/execution-status.yaml` (uncorrupted, authoritative
  done/live status per epic) + each live epic's `specs/epics/eNN-slug/epic.yaml`
  capsule (id/title/wsjf/bcps). Per decision: capsule dir wins over legacy flat
  `specs/epics/eNN-slug.yaml` files where both exist with conflicting values
  (confirmed the flat files are pre-"renumber epic IDs to canonical capsule-dir
  numbering" leftovers). Per decision: only the 13 active/proposed epics are
  re-listed; the 33 done epics are referenced via a `done_epics_summary` (count +
  id list + source pointer), not re-listed in full. Dropped the corrupted file's
  `release_trains` claim ("v2.8x — Polish", status done, covering e45+e46) — cross-
  checked against execution-status.yaml, e45/e46 are both `backlog`, contradicting
  "done"; not safely recoverable, noted rather than silently reasserted.
- `specs/state.yaml` — `handoff.context`'s bogus flattened key held a complete,
  recoverable bullet list (reconstructed verbatim). `metrics.epic_e31.prs` was
  fully emptied with no surviving fragment — represented honestly as `[]`, not
  guessed. `planning.*` (release v2.45.0, epics_planned, github_issues_created,
  gaps_fixed) **dropped**: distinct from the recoverable fields, these were
  byte-level truncated mid-string (not just misplaced), so completing them would
  mean fabricating content; independently confirmed stale (references pre-
  renumbering epic IDs and an old release version) and superseded by the
  release-plan.yaml rebuild.
- 32 `*-tasks.yaml` files (mostly `specs/epics/archive/`) + `e36`/`e43`/`e46`
  `epic.yaml` + `specs/verifications/e13s03-verify.yaml` — turned out to be a
  **different, simpler, pre-existing bug**, not this one: `verify:` fields with
  shell `grep -E` alternation patterns (`\|`, `\-`, `\$`) written inside YAML
  double-quoted scalars, where those aren't valid YAML escapes. Confirmed by
  comparing against `specs/epics/archive/e26-security-review/` (identical shell
  content, written as a `verify: |` literal block scalar instead, where
  backslash has no special meaning — proving the literal backslashes were
  always intended, never a YAML-escape mistake). Fixed by re-quoting as
  single-quoted (byte-identical content, quote style only) rather than treating
  as part of this bug's flattening damage.
- `specs/benchmarks/reports/BASELINE-GOLDEN.yaml` — also a separate, simpler
  bug: a missing newline had collapsed two `gates[]` entries onto one line.
  Fixed directly; recovered structure matches its own summary counts.

**Not this bug's fix:** the e43/e46 `epic.yaml` "born corrupt, no clean git
version" claim in the original Blast Radius turned out to be the escape-char
bug above, not flattening — no reconstruction-from-scratch was actually needed
for them.

`bash scripts/run-golden-suite.sh`: 6/6 passed, overall: pass.
