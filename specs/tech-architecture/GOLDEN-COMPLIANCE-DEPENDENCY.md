# GOLDEN Compliance Gate — Dependency Map

**Story:** e53s03 (Gate-trace the compliance-to-GOLDEN hard-gate coupling)
**Purpose:** map every consumer of the `compliance` gate's pass/fail signal and every
doc citing the 94% threshold as a Hard Stop, so a later epic (e58,
evals-over-compliance) can demote the gate without silently breaking something
nobody remembered was coupled to it.

**Scope boundary:** this document maps the dependency only — it does not flip
`scripts/lib/golden-suite-gates.sh:9`'s `is_optional` flag, and it does not change
any of the 5 cited docs. That work is out of scope for this story and belongs to e58.

## 1. What `compliance` measures

`npm run compliance` runs `scripts/audit-compliance.sh specs/verifications/features`,
`scripts/validate-doctrine.sh`, and `scripts/check-skill-links.py`. The headline
number is a `PASS/TOTAL` Gherkin scenario count from `specs/verifications/features/`
(currently reported as e.g. "97% (threshold 94%)"). The project must score at least
94% for the gate to pass.

## 2. The gate chain — every consumer of the pass/fail signal

```
scripts/lib/golden-suite-gates.sh          (defines the gate)
  └─ GOLDEN_GATES[0] = "compliance:npm run compliance:false"   ← line 9, is_optional=false
  └─ golden_run_deterministic_gates()                          ← runs it, tracks FAIL_COUNT
       └─ called by: scripts/lib/golden-suite-run.sh:74 (golden_suite_main)
            └─ called by: scripts/run-verification-gates.sh:8   (thin wrapper, no logic of its own)
                 └─ scripts/lib/golden-suite-report.sh:11
                      FAIL_COUNT > 0  →  OVERALL="fail"  →  "Combined verdict: FAIL"
```

**Direct invokers of `run-verification-gates.sh` / the Preflight chain:**

| Consumer | How | File:line |
|---|---|---|
| `kickoff-branch` skill | Preflight = `npm run compliance && bash scripts/run-verification-gates.sh`, hard block before any code is written | `skills/kickoff-branch/SKILL.md` |
| `verify-work` skill | Step 0a — same Preflight command, hard block before all verification phases | `skills/verify-work/SKILL.md` |
| CI: `publish.yml` | **Independent** dedicated "Compliance gate" step: `npm run compliance` (does not go through `golden-suite-gates.sh` at all — a second, separate hard gate) | `.github/workflows/publish.yml:44-45` |

**Important finding — two independent enforcement points, not one:** the GOLDEN-suite
chain (`golden-suite-gates.sh` → `golden-suite-report.sh`) and `publish.yml`'s
"Compliance gate" CI step both run `npm run compliance` and both currently treat any
failure as blocking, but they are **not the same code path**. Flipping
`golden-suite-gates.sh:9`'s `is_optional` value has **zero effect** on `publish.yml`'s
standalone step — that CI job would need its own separate change to stop blocking the
release/publish workflow.

## 3. `is_optional=false` does not do what its name implies today

`golden_run_deterministic_gates()` (`scripts/lib/golden-suite-gates.sh:64-107`) only
ever reads `is_optional` inside the branch that checks whether a `bash <script>`
gate's script file exists yet (lines 74-88) — if the script is missing **and**
`is_optional=true`, the gate is SKIPPED rather than FAILED. For any gate whose command
actually runs (including `compliance`, whose command is `npm run compliance`, not a
`bash <script>` invocation — `main_cmd` resolves to `npm`, so the missing-script
branch never applies), the exit code is counted toward `PASS_COUNT`/`FAIL_COUNT`
**unconditionally** (lines 90-105), regardless of `is_optional`'s value.

**Consequence for e58:** simply flipping line 9 from `false` to `true` will change
nothing — `compliance` isn't a `bash <script>` gate, so the flag is never consulted
for it. Demoting `compliance` to advisory requires **new logic** in
`golden_run_deterministic_gates()` — e.g. a general "if `is_optional=true` and the
command fails, route to `SKIP_COUNT`/a new WARN bucket instead of `FAIL_COUNT`"
branch — not just a data-value change. This is the single most important finding for
e58 to act on: the flag exists and is already named for this purpose, but the code
that would make it work for an executed (not missing) gate hasn't been written yet.

## 4. The 5 "Hard Stop" citations

| # | File:line | Citing text | Change required if compliance is demoted? |
|---|---|---|---|
| 1 | `docs/PRINCIPLES.md:71` | "**94% Quality Threshold:** ... the project must score at least 94% ... Falling below this threshold is treated as a Hard Stop." | **Yes** — states the Hard Stop as an absolute project rule |
| 2 | `docs/RELEASE-HISTORY.md:75` | "**Compliance CI gate**: `npm run compliance` must pass ≥ 94% before any merge. Hard stop." | **Yes** — explicit "Hard stop" language, directly contradicted once demoted |
| 3 | `docs/WORKFLOW-SOP-v2.md:83` | "Gate fails (quality < 94%) \| Do NOT advance. Fix issues, re-run `audit-code`. Never lower threshold." | **Yes** — "Do NOT advance" / "Never lower threshold" become stale operator guidance |
| 4 | `docs/WORKFLOW-SOP-v2.md:101` | "**Quality** \| `audit-code` \| `npm run compliance` ≥ 94% \| Score < 94%" (failure-mode table row) | **Yes** — same table implies hard block on failure |
| 5 | `docs/using-bigpowers.md:41` | ASCII lifecycle diagram: "6. audit-code ← quality gate ≥ 94%" | **Yes** — diagram implies a mandatory, non-advisory gate |

`docs/WORKFLOW-SOP-v2.md` carries 2 of the 5 citations, matching the story's own
precondition ("WORKFLOW-SOP-v2.md x2").

**Note on generated copies:** `website/src/content/docs/guides/{PRINCIPLES,
RELEASE-HISTORY,WORKFLOW-SOP-v2,using-bigpowers}.md` mirror these 4 files but are
build-generated from `docs/` (per `CLAUDE.md`: "Website content ... is auto-generated
by prebuild; edit repo sources, not site files") — they are not counted as separate
sources requiring independent edits; updating the `docs/` originals and rerunning the
prebuild is sufficient.

**Not in scope for this count:** many other files matched a broad `94%` search (94
audit report artifacts under `specs/verifications/reports/audit-superpowers-*.md`
that happen to have scored 94% on an unrelated rubric, `CLAUDE.md`'s Preflight
command table which references the mechanism but not as prose "Hard Stop" language,
`docs/references/gates.md` which cross-references PRINCIPLES.md rather than
restating the threshold itself). These are noise relative to the story's "5 docs"
precondition and were excluded — see the Reproduce commands below for how the 5
were isolated from the broader match set.

## 5. Reproduce

```bash
# Isolate is_optional's actual code effect
sed -n '64,107p' scripts/lib/golden-suite-gates.sh

# Confirm publish.yml's independent compliance step
grep -n -B2 -A2 "npm run compliance" .github/workflows/publish.yml

# Confirm the 5 Hard Stop citations (broad 94% grep returns 190+ false positives
# from historical audit reports; these 4 files are the actual doctrine sources)
for f in docs/PRINCIPLES.md docs/RELEASE-HISTORY.md docs/WORKFLOW-SOP-v2.md docs/using-bigpowers.md; do
  echo "=== $f ==="; grep -n "94%\|Hard Stop" "$f"
done
```

## 6. Summary for e58

To demote `compliance` from hard to advisory, e58 will need to touch **at least**:

1. `scripts/lib/golden-suite-gates.sh` — add real is_optional-aware handling in
   `golden_run_deterministic_gates()` for executed (not just missing) gates.
2. `.github/workflows/publish.yml:44-45` — a second, independent hard gate; must be
   changed separately or it will still block releases regardless of (1).
3. `docs/PRINCIPLES.md:71`, `docs/RELEASE-HISTORY.md:75`,
   `docs/WORKFLOW-SOP-v2.md:83,101`, `docs/using-bigpowers.md:41` — all 5 citations
   need updated language once the gate is genuinely advisory.

This story maps the dependency only — none of the above are changed here.
