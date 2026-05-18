# Plan: v1.12.1 — CONVENTIONS.md Hardening

## Context

The Claude-judged audit (2026-05-18) scored 75% (67/89). The conventions.feature and cleancode.feature
test CONVENTIONS.md directly and found 10 missing mandates. Adding them to CONVENTIONS.md is the
highest-WSJF action remaining (8.7): minimal effort, ~8 additional audit passes.
Target file: CONVENTIONS.md (currently 101 lines). No other files touched.

## Steps

1. Add **Boy Scout Rule** to Code Style section: "Leave every file you touch at least as clean as you found it." → verify: `grep -c "Boy Scout" CONVENTIONS.md`

2. Add **G25 — No magic strings or numbers** to Code Style section: named constants only, no bare string literals or numeric literals in logic. → verify: `grep -c "G25\|magic string\|magic number" CONVENTIONS.md`

3. Add **G28 — Boolean logic in named functions** to Code Style section: complex boolean expressions must be extracted into a named predicate function. → verify: `grep -c "G28\|boolean\|predicate" CONVENTIONS.md`

4. Add **N7 — Names describe side-effects** to Code Style section: if a function sends email, writes a file, or mutates state, the name must say so. → verify: `grep -c "N7\|side.effect" CONVENTIONS.md`

5. Add **C5 — No commented-out code** to Comments section: dead code must be deleted, not commented out. → verify: `grep -c "C5\|commented.out\|comment.*dead" CONVENTIONS.md`

6. Add **Exceptions over error codes** to Code Style section: throw/raise exceptions rather than returning numeric or boolean error codes. → verify: `grep -c "exception\|error code" CONVENTIONS.md`

7. Add **G9/F4 — Remove dead code** to Code Style section: unused functions, unreachable branches, and stale imports must be deleted. → verify: `grep -c "G9\|F4\|dead code\|unused" CONVENTIONS.md`

8. Add **T5 — Test boundary conditions** to Tests section: every test suite must cover exact edge values (empty, max, off-by-one). → verify: `grep -c "T5\|boundary" CONVENTIONS.md`

9. Add **T8 — Test through public interfaces only** to Tests section: tests must assert on observable outcomes (API responses, return values, UI state) — never on internal state or private methods. → verify: `grep -c "T8\|public interface\|implementation detail" CONVENTIONS.md`

10. Add **Verify mandate** to Tests section (or a new Verification section): every change must be verifiable with a single runnable command before marking a step done. → verify: `grep -c "verify\|runnable command" CONVENTIONS.md`

11. Validate CONVENTIONS.md is well-formed and under 300 lines → verify: `wc -l CONVENTIONS.md && bash scripts/sync-skills.sh 2>&1 | tail -2`

## Out of scope

- Editing any SKILL.md files
- Changing the audit feature files themselves
- Adding T4 (ignored tests) — targeted for v1.16.0

## Risks

- File growth: CONVENTIONS.md is 101 lines; 10 additions will bring it to ~120 lines — well under the 300-line limit.
- Wording must be tight enough to pass the Claude judge ("clearly satisfies the criterion") — cite heuristic codes (G25, N7, etc.) so the judge can match them directly.
