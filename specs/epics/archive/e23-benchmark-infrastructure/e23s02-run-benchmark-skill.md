---
story_id: e23s02
title: "Create run-benchmark skill"
status: backlog
bcps: 1
type: feat
context: infra
---

# Story e23s02: run-benchmark skill

Create `run-benchmark/SKILL.md` — the skill that reads benchmark definitions
from `specs/benchmarks/`, executes each scenario's grader, and outputs a
structured pass@k report that `evolve-skill` can consume.

## Acceptance Criteria

- [ ] `run-benchmark/SKILL.md` exists with verb-noun naming, model frontmatter
- [ ] Skill documents how to run all benchmarks or a single skill's benchmarks
- [ ] Output format: `specs/benchmarks/reports/BENCHMARK-<skill>-<date>.yaml`
- [ ] Report includes: skill, pass_count, fail_count, pass_at_k, scenarios[]

## Gherkin Scenarios

```gherkin
Given specs/benchmarks/survey-context.yaml exists with 2 scenarios
When run-benchmark survey-context executes
Then it runs each scenario's grader command
And writes specs/benchmarks/reports/BENCHMARK-survey-context-<date>.yaml
And the report contains pass_at_k = passed / total

Given run-benchmark runs with no skill argument
When it executes
Then it benchmarks all skills with a definition in specs/benchmarks/
And writes one report per skill
```

## Verification

```bash
test -f run-benchmark/SKILL.md && \
grep -q 'run-benchmark' SKILL-INDEX.md && \
echo "OK: skill exists and indexed" || echo "FAIL"
```

## Implementation Notes

- Model: `haiku` (mechanical runner, not reasoning-heavy)
- Code graders: run the `command` in the repo root, check exit code + stdout
- Rubric graders: present criteria to the agent for a binary yes/no per criterion
- pass@k = (scenarios where grader returns PASS) / (total weighted scenarios)
- Report location: `specs/benchmarks/reports/` (gitignored for CI cost reasons)
