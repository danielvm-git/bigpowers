# Security Review — BUG-2026-11-02-pipefail-pipe-race

## Scope Resolution
Scanned: `danielvm-git/angry-einstein-728328` vs `main` (1 commit).
Files changed:
- `scripts/bp-churn-rank.sh`, `scripts/check-spec-version-gap.sh`, `scripts/land-branch.sh`
- `scripts/lib/golden-suite-gates.sh`, `scripts/lib/parallel-review-worktrees.sh`
- `scripts/run-smoke.sh`, `scripts/validate-doctrine.sh`
- `scripts/test-pipefail-pipe-race.sh` (new regression guard)
- `specs/bugs/BUG-2026-11-02-pipefail-pipe-race.md` (+ `.okf.md`, `registry.yaml`)

Languages: Bash + Markdown. No network, no credentials, no new dependencies.

## Threat Trace
The change replaces `producer | grep -q` / `| head` pipelines with captured
output (`out="$(...)"` then `grep -q ... <<<"$out"`) or full-read readers
(`awk -v limit=`, `sed -n '1,Np'`). Static assertions live in
`scripts/test-pipefail-pipe-race.sh`, wired into the golden gate suite.

| Category | Finding | Severity | Mitigation |
|----------|---------|----------|------------|
| Command injection | Here-strings pass data as stdin, never as argv or `eval` | NONE | No new interpolation site; `$content_signal` was already passed to `grep -E` pre-change |
| Auth/attribution bypass | `land-branch.sh` Co-authored-by scan now captures `git log` output before matching | LOW | Fix removes a *false negative* (race made a real footer read as absent); regex and deny path unchanged |
| Fail-open gates | Race could make a found match read as "not found" | LOW | Each gate now compares captured text; `|| true` keeps the earlier empty-log semantics |
| Secrets exposure | None — no new file reads, no logging of env | NONE | — |
| Data handling | `run-smoke.sh` content-signal match moved off an `echo`-piped `grep -q` | NONE | Same here-string path already used elsewhere in the script |
| Supply chain | No new actions, packages, or pinned versions | NONE | — |

Residual risk: `set -o pipefail` remains on; other call sites outside `scripts/`
and `hooks/` are covered by check (c) of the regression test only for git-fed
pipelines. Documented as scope of BUG-2026-11-02.

## Verdict
**PASS** — no exploitable surface introduced; the change removes a
false-negative class in the attribution and gate-scan paths.
