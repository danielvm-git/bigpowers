---
bug_id: BUG-2026-07-06-run-evals-golden-suite-oversized
status: fixed
severity: medium
scope: skills/run-evals
title: "run-evals: Underlying test suite runner run-golden-suite.sh exceeds 300-line context window limit"
---

# BUG-2026-07-06-run-evals-golden-suite-oversized

Fixed by BUG-2026-07-06-verify-work-runner-scripts-oversized — `run-golden-suite.sh` reduced to 8-line wrapper sourcing `scripts/lib/golden-suite-run.sh`.
