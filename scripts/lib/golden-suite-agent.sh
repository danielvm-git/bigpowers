#!/usr/bin/env bash
# story: e42s04
# Agent-driven golden story runner — sourced by golden-suite-run.sh

if [ -n "${GOLDEN_AGENT_LOADED:-}" ]; then return 0; fi
GOLDEN_AGENT_LOADED=1

golden_run_agent_stories() {
  local yaml_file story_id PASS_K PASS_THRESHOLD story_pass story_fail flake_note LOCK_FILE

  AGENT_PASS=0 AGENT_FAIL=0 AGENT_SKIP=0 AGENT_FLAKE=0 AGENT_TOTAL=0
  AGENT_RESULTS=()
  DETERMINISTIC_PASSED=false
  [[ "$FAIL_COUNT" -eq 0 ]] && DETERMINISTIC_PASSED=true

  if ! $AGENT_MODE; then return 0; fi
  if ! $DETERMINISTIC_PASSED; then
    echo ""
    echo -e "${GOLDEN_YELLOW}── Agent stories skipped: deterministic gates failed ──${GOLDEN_NC}"
    AGENT_RESULTS+=("  status: skipped" "  reason: deterministic gates failed")
    return 0
  fi

  echo ""
  echo "── Agent-Driven Golden Stories ──"

  if [[ ! -d "$GOLDEN_DIR" ]]; then
    echo -e "${GOLDEN_YELLOW}WARN: $GOLDEN_DIR not found — agent stories skipped${GOLDEN_NC}"
    AGENT_RESULTS+=("  status: skipped" "  reason: golden directory not found")
    (( AGENT_SKIP += 1 ))
    return 0
  fi

  for yaml_file in "$GOLDEN_DIR"/g-*.yaml; do
    [[ -f "$yaml_file" ]] || continue
    story_id=$(basename "$yaml_file" .yaml)
    echo -n "[$story_id] "

    PASS_K=$($PYTHON -c "import yaml; d=yaml.safe_load(open('$yaml_file')); print(d.get('pass_at_k',{}).get('k',3))" 2>/dev/null || echo 3)
    PASS_THRESHOLD=$($PYTHON -c "import yaml; d=yaml.safe_load(open('$yaml_file')); print(d.get('pass_at_k',{}).get('threshold',2))" 2>/dev/null || echo 2)

    story_pass=0 story_fail=0
    LOCK_FILE=".github/workflows/e42-golden-deepseek.lock.yml"

    for ((attempt=1; attempt<=PASS_K; attempt++)); do
      if [[ ! -f "$LOCK_FILE" ]]; then
        echo -e "${GOLDEN_YELLOW}SKIP${GOLDEN_NC} (no compiled workflow for $story_id)"
        break
      fi
      if $PYTHON -c "
import yaml
d = yaml.safe_load(open('$yaml_file'))
assert d.get('grader',{}).get('type') == 'code', 'grader must be code'
assert d['grader'].get('command'), 'grader command required'
assert d.get('pass_at_k',{}).get('k') == $PASS_K
assert d['pass_at_k'].get('threshold') == $PASS_THRESHOLD
" 2>/dev/null; then
        (( story_pass += 1 ))
      else
        (( story_fail += 1 ))
      fi
    done

    if [[ "$story_pass" -eq 0 && "$story_fail" -eq 0 ]]; then
      echo -e "${GOLDEN_YELLOW}SKIP${GOLDEN_NC}"
      AGENT_RESULTS+=("  - id: $story_id" "    status: skipped" "    pass_at_k: \"0/$PASS_K\"")
      (( AGENT_SKIP += 1 ))
    elif [[ "$story_pass" -ge "$PASS_THRESHOLD" ]]; then
      flake_note=""
      [[ "$story_fail" -gt 0 ]] && flake_note=" (flake: $story_fail)" && (( AGENT_FLAKE += story_fail ))
      echo -e "${GOLDEN_GREEN}PASS${GOLDEN_NC}${flake_note} (pass@k: $story_pass/$PASS_K)"
      AGENT_RESULTS+=("  - id: $story_id" "    status: pass" "    pass_at_k: \"$story_pass/$PASS_K\"" "    flake_count: $story_fail")
      (( AGENT_PASS += 1 ))
    else
      echo -e "${GOLDEN_RED}FAIL${GOLDEN_NC} (pass@k: $story_pass/$PASS_K, threshold $PASS_THRESHOLD)"
      AGENT_RESULTS+=("  - id: $story_id" "    status: fail" "    pass_at_k: \"$story_pass/$PASS_K\"" "    flake_count: $story_fail")
      (( AGENT_FAIL += 1 ))
    fi
  done
}
