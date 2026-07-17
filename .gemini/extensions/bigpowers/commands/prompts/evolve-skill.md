---
name: evolve-skill
description: "Benchmark-gated skill evolution — consume bigpowers-benchmark report, propose plan-work change, edit skill via craft-skill, re-run benchmark, record ADR. Use when a skill underperforms on benchmark or stocktake finds systemic gap."
---

# story: e23s03

# story: e09s01
# story: e09s05

# Evolve Skill

> **HARD GATE** — No skill change ships without benchmark score ≥ pre-change baseline. Learning is measured and versioned — never implicit.

## Loop

1. **Regression gate** — Run `bash scripts/run-verification-gates.sh` to catch mechanical regressions (compliance, sync pipeline, size budget) before spending time on benchmark evals. If golden suite fails, fix regressions first — they are pre-requisites for any capability improvement.
2. **Establish baseline** — Run `run-benchmark <skill> --baseline`. If no definition exists at `specs/benchmarks/<skill>.yaml`, create one following `specs/benchmarks/SCHEMA.md` first. Save report path in `state.yaml`. If `specs/benchmarks/reports/BASELINE-<skill>.yaml` already exists, skip this step.

3. **Identify gap** — Read the baseline report (`specs/benchmarks/reports/BASELINE-<skill>.yaml`). Find scenarios with `result: FAIL` or low `pass_at_k`. This is the measurable gap.

4. **`plan-work`** — Write a minimal change proposal targeting the failing scenarios. Include verify commands.

5. **Edit** via `craft-skill` / direct SKILL.md edit; run `bash scripts/sync-skills.sh`.

6. **Re-run benchmark** — `run-benchmark <skill>`. Compare new `pass_at_k` against baseline.
   - **IMPROVED or STABLE** → advance to step 6.
   - **REGRESSION** (`new pass_at_k < baseline`) → revert the change and loop back to step 3.

7. **Record decision** — Write `specs/adr/NNNN-evolve-<skill>.md` with before/after `pass_at_k` scores. Update `session-state`.

## Verify

→ verify: `grep -c 'run-benchmark\|pass_at_k\|BASELINE-' skills/evolve-skill/SKILL.md | awk '{if($1>=2) print "OK"; else print "FAIL"}'`

See [REFERENCE.md](REFERENCE.md) for ADR template.


<!-- story: e31s07 -->

---

# Evolve Skill — ADR snippet

```markdown
## ADR-XXXX: Evolve &lt;skill-name&gt;

**Status:** Accepted
**Benchmark:** before X% / after Y%
**Change:** one-sentence summary
**Evidence:** path/to/benchmark-report.md
```

Benchmark repo: `bigpowers-benchmark` — resolve the local clone on this machine (e.g. `gh repo clone danielvm-git/bigpowers-benchmark` if absent); never assume a hard-coded absolute path.
