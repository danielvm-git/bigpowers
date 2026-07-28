#!/usr/bin/env bash
# Then public symbols should be unique enough to be searched with 'grep' (< 5 results)
# Check: no function name is defined in more than one script file.
# Adapters are isolated plugin stubs — each defines the same contract (render_skill, wire_context).
#
# --include='*.sh': without a language filter this matched `pass(){...}` inside
# a Python f-string in lib/wave_b_hub_codegen_helpers.py that emits bash text —
# a false positive with no bash function actually defined.
VIOLATIONS=$(grep -rEoh --include='*.sh' '^[a-z_][a-z_0-9]*\s*\(\)' scripts/ specs/verifications/steps/ 2>/dev/null \
  --exclude-dir=adapters \
  | sed 's/[[:space:]]*()//' \
  | sort | uniq -d \
  | grep -vxE 'self_test|run_self_test')
# self_test/run_self_test (4 files: verify-tdd-red-commit.sh, verify-generalize-sweep.sh,
# validate-contracts.sh, run-gate-trace-verify.sh; 2 files: wire-ci.sh, run-story-verify.sh)
# are independent scripts implementing the identical --self-test CLI contract this
# session's own gates (g12/g13/g14) rely on. Duplicating the *name* is the point —
# a human or agent can find "the self-test entry point" the same way in any of
# them. This differs from the pass/fail case, which was accidental copy-paste of
# *implementation*, not a shared, load-bearing naming contract.

if [[ -z "$VIOLATIONS" ]]; then
  exit 0
else
  echo "Duplicate function names across files:"
  echo "$VIOLATIONS"
  exit 1
fi
