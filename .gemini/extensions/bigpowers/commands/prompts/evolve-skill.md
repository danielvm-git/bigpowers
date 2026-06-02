
# Evolve Skill

> **HARD GATE** — No skill change ships without benchmark score ≥ pre-change baseline. Learning is measured and versioned — never implicit.

## Loop

1. Run `bigpowers-benchmark` (external repo); save report path in state.yaml.
2. Identify target skill + measurable gap from report.
3. `plan-work` — minimal change proposal with verify commands.
4. Edit via `craft-skill` / direct SKILL.md edit; run `sync-skills.sh`.
5. Re-run benchmark; compare scores.
6. Record decision in `specs/adr/` + `session-state`; revert if regression.

## Verify

→ verify: benchmark report shows post-change score ≥ baseline (document paths in state.yaml)

See [REFERENCE.md](REFERENCE.md) for ADR template.

---

# Evolve Skill — ADR snippet

```markdown
## ADR-XXXX: Evolve &lt;skill-name&gt;

**Status:** Accepted
**Benchmark:** before X% / after Y%
**Change:** one-sentence summary
**Evidence:** path/to/benchmark-report.md
```

Benchmark repo: `/Users/danielvm/Developer/bigpowers-benchmark/`
