# e58s04: ablation arms — which part of bigpowers produces the gain

<!-- story: e58s04 -->

```
STORY KEY: e58s04
TITLE:     Compare bigpowers parts (seed, core skills, full catalog) against vanilla
TYPE:      Enabler
PARENT:    e58
STATUS:    Refined
AUTHOR:    danielvm-git (planned with claude-opus-5-5)   DATE: 2026-11-02
MATURITY:  4
SIZE:      S (2)
```

Source: the k=3 and k=10 runs show bigpowers helps on the behaviour-preserving refactor (ab-06:
13/13 vs 8/13 over two models) and nowhere else. e56 needs to know which part causes that before
cutting the catalog. Arms are config, so the ablation is config plus two runner options.

## Requirements

### ADDED

- `ab-arm-bigpowers.sh` MUST read `AB_BP_SKILLS` (`all` default, `none`, or a comma list of skill
  names) and `AB_BP_SEED` (path to the seed file relative to the bigpowers checkout, or `none`).
  `scripts/` is copied only when at least one skill is copied. Defaults keep today's arm unchanged.
- Arms in `config.yaml`: `bp-core` (seed + the six skills the seed names), `bp-seed` (seed only),
  `bp-skills` (all skills, no seed) and `tdd-line` (a three-line TDD rule with no skill names).
- The report MUST add `deltas_vs_vanilla`: for every non-vanilla arm, pass-rate delta with CI,
  cost delta, and score delta with CI when scores exist. The console prints one line per arm.
  `delta` (bigpowers − vanilla) stays as it is.

## Acceptance criteria

```gherkin
Scenario: A skill subset is installed
  Given AB_BP_SKILLS=develop-tdd,verify-work
  When the arm setup runs
  Then exactly those skills are in .claude/skills and .agents/skills, and scripts/ exists

Scenario: Seed only
  Given AB_BP_SKILLS=none and the default seed
  Then AGENTS.md exists and there is no skills folder and no scripts/

Scenario: Skills only
  Given AB_BP_SEED=none
  Then there is no AGENTS.md or CLAUDE.md

Scenario: Every arm gets a delta against vanilla
  Given runs for vanilla, bigpowers and bp-seed
  Then deltas_vs_vanilla has bigpowers and bp-seed, each with ci95
```

## Out of scope

- Per-skill leave-one-out ablation (80 arms; later, if the coarse split points somewhere).

## Acceptance

```bash
python3 tests/test_ab_ablation.py && bash scripts/run-ab-eval.sh --dry-run --arms vanilla,bigpowers,bp-core,bp-seed,bp-skills,tdd-line && echo OK
```
