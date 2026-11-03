# A/B task review and difficulty calibration

Date: 2026-11-03 · Scope: the 14 tasks in `specs/benchmarks/ab/tasks/`, including ab-09, ab-17,
ab-19 and ab-20 added by another agent in `b0cfa015` · Model for all data:
`opencode-go/deepseek-v4.1-flash`.

## 1. Difficulty: no task discriminates

A task can show a difference between arms only if vanilla passes it 20–80% of the time. Vanilla
pass rates from every pinned run:

| Task | k=10 easy (opencode) | ablation (opencode) | k=10 hard (pi-docker) | Verdict |
|---|---|---|---|---|
| ab-01–05, ab-07, ab-08 | 10/10 each | – | – | saturated |
| ab-06 stepdown refactor | 7/10 | 9/10 | – | near the band |
| ab-09 reservations | – | – | 10/10 | saturated |
| ab-11 ledger rounding | – | 8/10 | 9/10 | near the band |
| ab-13 orders split | – | 10/10 | 10/10 | saturated |
| ab-17 payment alias | – | – | 10/10 | saturated |
| ab-19 catalog segregation | – | – | 10/10 | saturated |
| ab-20 brand discount | – | – | 10/10 | saturated |

**0 of 14 tasks are in the band.** Running more repetitions of these tasks cannot produce a
gate-worthy signal. The suite needs harder or less prescriptive tasks first.

## 2. Review of ab-09, ab-17, ab-19, ab-20

All four pass the calibration tests (the fixture fails, the solution passes, the prompt does not name
bigpowers, grade commands use globs). Findings:

| # | Finding | Tasks | Severity |
|---|---|---|---|
| 1 | **Prescriptive specs.** The spec gives formulas (`expiresAt = clock.now() + 15 * 60 * 1000`), the function to call (`allocate(discount, brandLines, brandSubtotal)`) and every object shape. This is the "answer in the prompt" pattern found in ab-01–08, so requirement discovery is never tested. | ab-09, ab-17, ab-20 (ab-19 is behavioural and fine) | high |
| 2 | **Shallow hidden tests.** 5–7 hidden tests per task cover only part of each spec. ab-17 never tests CNPJ, unsupported types, the business limit of 20 or the quota message. ab-09 never tests `qty <= 0` or cancelling an unknown reservation. | all four | high |
| 3 | **Wrong story tag.** Every task carries `# story: e58s08`, which is the VSM classifier story. No story in the ledger covers these tasks, so traceability points at the wrong place. | all four | medium |
| 4 | **Spec contradiction.** The spec says "UUID v4", its own example (`123e4567-e89b-12d3-…`) is version 1, and the solution accepts versions 1–5. The hidden test uses a v4 key, so the contradiction is never exercised. | ab-17 | low |
| 5 | **Duplicate report in a non-standard folder.** `specs/benchmarks/ab/reports/AB-2026-11-03-k10-elite.yaml` and its jsonl hold the same 120 runs as `specs/benchmarks/reports/AB-2026-11-03-pi-docker-flash-k10-hard.*`, which also has the lean blocks and provenance notes. SCHEMA.md documents `specs/benchmarks/reports/`. | – | low |
| 6 | **Audit step.** `audit:` runs 2 extra tests after grading and records failures as `bugs_opened`, outside pass and score. This is useful as a separate signal, but it isn't documented in SCHEMA.md and only ab-20 uses it. | ab-20 | low |

## 3. Recommended fixes, in order

1. **De-prescribe the specs (finding 1).** Keep the observable contract a caller depends on (function
   names, error messages, return shapes). Remove how to implement it (formulas, helper calls,
   internal field mapping). Where a rule matters, state it as behaviour ("a hold lasts 15 minutes"),
   not code.
2. **Cover every stated requirement in the hidden tests (finding 2).** Add one hidden test per spec
   requirement plus its boundaries (for example 2999 vs 3000 cents, the 6th alias, an expired hold
   at exactly `expiresAt`). Move ab-20's audit tests into hidden, or document `audit` as a separate
   signal.
3. **Then calibrate.** Run vanilla only, k=10, on the reworked tasks (about $0.50). Keep tasks in
   the 20–80% band and rework or retire the rest. Target about 10 discriminating tasks before the
   calibration story starts.
4. **Housekeeping (findings 3–6).** Re-tag the tasks to a real story, fix the UUID wording, remove
   the duplicate report, and document `audit` in SCHEMA.md.

Saturation is not only a task problem. This flash model is strong at small, fully specified
changes. Tasks where requirements are implied, spread over several documents, or changed partway
through (HARDER-TASKS_LATEST.md: ab-12, ab-15, ab-16) are the ones most likely to land in the band.
