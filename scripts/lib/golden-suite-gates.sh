#!/usr/bin/env bash
# story: e42s04 e45s02 e45s14 e60s01
# Deterministic gate runner for golden suite — sourced by golden-suite-run.sh

if [ -n "${GOLDEN_GATES_LOADED:-}" ]; then return 0; fi
GOLDEN_GATES_LOADED=1

GOLDEN_GATES=(
  "compliance:npm run compliance:false"
  "g04-selftest:bash scripts/golden-g04-selftest.sh:true"
  "g06-migrate-version:bash tests/run-golden-migrate-version.sh:true"
  "g07-negative-path:bash scripts/golden-g07-negative-path.sh:false"
  "g08-anti-vacuity:bash scripts/golden-g08-anti-vacuity.sh:false"
  "g09-yaml-roundtrip:bash scripts/golden-g09-yaml-roundtrip.sh:false"
  "g10-trace-anti-vacuity:bash scripts/golden-g10-trace-anti-vacuity.sh:false"
  "g11-gitignore-venv:bash scripts/golden-g11-gitignore-venv.sh:false"
  # Planning SoT consistency (BUG-2026-07-26-planning-sot-drift): live epic
  # shards, execution-status.yaml and release-plan.yaml must agree. Self-test
  # first so a vacuous gate is caught before its verdict is trusted.
  "g12-status-selftest:bash scripts/golden-g12-status-consistency.sh --self-test:false"
  "g12-status-consistency:bash scripts/golden-g12-status-consistency.sh:false"
  # Anti-vacuity for the target-contract seam: every contract declared in
  # targets.yaml must have a real assertion, and an unknown contract must FAIL
  # rather than SKIP+exit 0 (seven contracts were fail-open before this).
  # Writing a test must be enough to make it run: G-13 fails if any
  # scripts/test-*.sh is absent from this list.
  "g13-test-orphans-selftest:bash scripts/golden-g13-test-orphans.sh --self-test:false"
  "g13-test-orphans:bash scripts/golden-g13-test-orphans.sh:false"
  # An adapter that defines render_skill() must be dispatched by targets.yaml,
  # or sync renders nothing for it while its install still claims success.
  # docs/WORKFLOWS.md is generated from specs/workflows/*.yaml; a diagram nothing
  # regenerates is a diagram that lies (see specs/archive/assets/README.md).
  "workflow-diagrams-fresh:bash scripts/generate-workflow-diagrams.sh --check:false"
  "g14-adapter-dispatch-selftest:bash scripts/golden-g14-adapter-dispatch.sh --self-test:false"
  "g14-adapter-dispatch:bash scripts/golden-g14-adapter-dispatch.sh:false"
  "target-contracts:bash scripts/test-target-contracts.sh:false"
  # Registry-driven replacements for the 25 hand-written per-target scripts.
  "install-hub:bash scripts/test-install-hub.sh:false"
  "adapter-render:bash scripts/test-adapter-render.sh:false"
  "adapters:bash scripts/test-adapters.sh:false"
  # Previously orphaned: present in scripts/ but reachable from no gate.
  "tombstone-mechanism:bash scripts/test-tombstone-mechanism.sh:false"
  "trace-strict:bash scripts/test-trace-strict.sh:false"
  "trace-matrix-size:bash scripts/test-trace-matrix-size.sh:false"
  "setup-no-pyyaml:bash scripts/test-setup-no-pyyaml.sh:false"
  "install-distribute-only:bash scripts/test-install-distribute-only.sh:false"
  "completeness-critic-scope:bash scripts/test-completeness-critic-scope.sh:false"
  "epics-wiki-zero-stories:bash scripts/test-generate-epics-wiki-zero-stories.sh:false"
  "golden-g11-worktree-venv:bash scripts/test-golden-g11-worktree-venv.sh:false"
  "install-helpers:bash scripts/test-install-helpers.sh:false"
  "import-boundaries:bash scripts/check-import-boundaries.sh:false"
  "skill-catalog:bash scripts/validate-skill-catalog.sh:false"
  "specs-parse:bash scripts/validate-specs-yaml.sh:false"
  # Tier 2 of the verify arc (#106): executes the verify: of every story marked
  # done. Tier 1 (SKILL.md) is run-skill-verify.sh in golden-suite.yml.
  "story-verify-selftest:bash scripts/run-story-verify.sh --self-test:false"
  "story-verify:bash scripts/run-story-verify.sh:false"
)

GOLDEN_GREEN='\033[0;32m'
GOLDEN_RED='\033[0;31m'
GOLDEN_YELLOW='\033[0;33m'
GOLDEN_NC='\033[0m'

golden_agent_dry_run() {
  local yaml_count=0 yaml_ok=0 yaml_fail=0 yaml_file story_id

  echo "Agent Golden Stories — DRY RUN"
  echo "Golden YAML directory: $GOLDEN_DIR"

  if [[ ! -d "$GOLDEN_DIR" ]]; then
    echo -e "${GOLDEN_YELLOW}WARN: $GOLDEN_DIR not found${GOLDEN_NC}"
    return 0
  fi

  for yaml_file in "$GOLDEN_DIR"/g-*.yaml; do
    [[ -f "$yaml_file" ]] || continue
    (( yaml_count += 1 ))
    story_id=$(basename "$yaml_file" .yaml)

    if $PYTHON -c "import yaml; yaml.safe_load(open('$yaml_file'))" 2>/dev/null; then
      local grader_type pass_k
      grader_type=$($PYTHON -c "import yaml; d=yaml.safe_load(open('$yaml_file')); print(d.get('grader',{}).get('type',''))" 2>/dev/null)
      pass_k=$($PYTHON -c "import yaml; d=yaml.safe_load(open('$yaml_file')); pk=d.get('pass_at_k',{}); print(f\"{pk.get('k',0)}-of-{pk.get('threshold',0)}\")" 2>/dev/null)
      echo -e "  ${GOLDEN_GREEN}OK${GOLDEN_NC}   $story_id — grader=$grader_type, pass@k=$pass_k"
      (( yaml_ok += 1 ))
    else
      echo -e "  ${GOLDEN_RED}FAIL${GOLDEN_NC} $story_id — YAML parse error"
      (( yaml_fail += 1 ))
    fi
  done

  echo ""
  echo "Agent YAML validation: $yaml_ok/$yaml_count parseable"
  if [[ "$yaml_fail" -gt 0 ]]; then
    echo -e "${GOLDEN_RED}$yaml_fail YAML(s) failed to parse${GOLDEN_NC}"
    return 1
  fi
  return 0
}

golden_run_deterministic_gates() {
  local gate name cmd is_optional main_cmd script_path
  PASS_COUNT=0 FAIL_COUNT=0 SKIP_COUNT=0
  GATE_RESULTS=()

  for gate in "${GOLDEN_GATES[@]}"; do
    IFS=':' read -r name cmd is_optional <<< "$gate"
    echo -n "[$name] "

    main_cmd=$(echo "$cmd" | awk '{print $1}')
    if [[ "$main_cmd" == "bash" ]]; then
      script_path=$(echo "$cmd" | awk '{print $2}')
      if [[ ! -f "$script_path" ]]; then
        if [[ "$is_optional" == "true" ]]; then
          echo -e "${GOLDEN_YELLOW}SKIP${GOLDEN_NC} (script not yet implemented)"
          GATE_RESULTS+=("  - name: $name" "    exit_code: skipped" "    duration_seconds: 0" "    status: skipped" "    note: script not found: $script_path")
          (( SKIP_COUNT += 1 ))
          continue
        fi
        echo -e "${GOLDEN_RED}FAIL${GOLDEN_NC} (script not found: $script_path)"
        GATE_RESULTS+=("  - name: $name" "    exit_code: 127" "    duration_seconds: 0" "    status: fail" "    error: script not found: $script_path")
        (( FAIL_COUNT += 1 ))
        continue
      fi
    fi

    local START_TIME END_TIME DURATION_MS DURATION_SEC GATE_EXIT
    START_TIME=$(date +%s%N)
    eval "$cmd" >/dev/null 2>&1 && GATE_EXIT=$? || GATE_EXIT=$?
    END_TIME=$(date +%s%N)
    DURATION_MS=$(( (END_TIME - START_TIME) / 1000000 ))
    DURATION_SEC=$(echo "scale=2; $DURATION_MS / 1000" | bc 2>/dev/null || echo "0")

    if [[ "$GATE_EXIT" -eq 0 ]]; then
      echo -e "${GOLDEN_GREEN}PASS${GOLDEN_NC} (${DURATION_SEC}s)"
      GATE_RESULTS+=("  - name: $name" "    exit_code: 0" "    duration_seconds: $DURATION_SEC" "    status: pass")
      (( PASS_COUNT += 1 ))
    else
      echo -e "${GOLDEN_RED}FAIL${GOLDEN_NC} (${DURATION_SEC}s, exit $GATE_EXIT)"
      GATE_RESULTS+=("  - name: $name" "    exit_code: $GATE_EXIT" "    duration_seconds: $DURATION_SEC" "    status: fail")
      (( FAIL_COUNT += 1 ))
    fi
  done
}
