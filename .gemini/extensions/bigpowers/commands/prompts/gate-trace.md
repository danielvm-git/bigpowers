
# Gate Trace

Deterministic quality gate that combines traceability coverage and blind-spot data into a single PASS/FAIL/CONCERNS/WAIVED decision before release.

## Decision Rules

| Rule | Condition | Verdict |
|------|-----------|---------|
| R1 | Any undone story with 0 code tags | FAIL |
| R2 | Any story done but no verify evidence | CONCERNS |
| R3 | P0 story (top WSJF quartile) with 0% coverage | FAIL |
| R4 | Overall coverage < 60% | CONCERNS |
| R6 | P0 story + eNN-TEST_PLAN_LATEST.md exists + zero SC-eNNsYY-P0-* in test files | CONCERNS |
| R5 | Overall ≥ 80% + no critical gaps + all verify → PASS | PASS |

## Oracle Confidence Downgrade

TEA-inspired: if trace links rely on heuristics rather than explicit tags, confidence drops.

| Heuristic Ratio | Downgrade |
|-----------------|-----------|
| > 50% links from heuristics (file-name or task-reference) | One level (PASS→CONCERNS, CONCERNS→FAIL) |
| > 80% links from heuristics | Two levels (PASS→FAIL, CONCERNS→FAIL) |

## Process

1. **Pre-flight:** Ensure `scripts/trace-stories.sh --json` has been run (produces `specs/traceability-matrix.json`). If not present, run it.
2. Ensure `scripts/check-blind-spots.sh` has been run (produces `specs/blind-spots.json`). If not present, run it.
3. Read `specs/traceability-matrix.json` and `specs/blind-spots.json`.
4. Apply decision rules R1–R5 in order (first match wins).
5. Apply oracle confidence downgrade based on the heuristic link ratio from the matrix's `oracle_stats`.
6. **Drift check (e39s03):** If `specs/drift-report.json` exists and has suspect links, mark verdict as CONCERNS with note: "Drift detected — some implementing files are newer than their specs. Run scripts/check-spec-drift.sh for details."
7. Output verdict + rationale to stdout.
7. Update `specs/execution-status.yaml` with gate-trace result.

## Verdict Semantics

| Verdict | Meaning | Action |
|---------|---------|--------|
| PASS | All gates satisfied | Proceed with merge |
| CONCERNS | Non-critical issues found | Requires explicit human override in `state.yaml` |
| FAIL | Critical traceability gap | Block merge — fix gap first |
| WAIVED | Cannot evaluate (missing inputs) | Skip gate — data not available |

## Output Format

```yaml
gate_trace:
  verdict: PASS|CONCERNS|FAIL|WAIVED
  generated_at: "<ISO 8601>"
  rationale: "<human-readable explanation>"
  heuristic_ratio: <0.0–1.0>
  downgrade_applied: <true|false>
```

## Integration Points

- **release-branch SKILL.md** — pre-PR gate (FAIL blocks merge).
- **sync-skills.yml** — CI gate (FAIL blocks pipeline).
- **verify-work SKILL.md** — runs blind-spot checks; gate-trace consumes the result.

## References

- BMAD TEA traceability approach (market survey 2026-07-02).
- scripts/trace-stories.sh (e38s01) — produces traceability-matrix.json.
- scripts/check-blind-spots.sh (e38s04) — produces blind-spots.json.
- specs/execution-status.yaml — output target for gate result.

## Handoff

Gate: READY → next: release-branch (final step before merge)
Writes: state.yaml handoff.next_skill = release-branch
