#!/usr/bin/env bash
#
# record-cycle-time.sh — deterministic, git-derived delivery metrics.
#
# Replaces the agent's hand-written story_start/story_end timestamps and
# hand-arithmetic (which produced fabricated / wall-clock-inflated rows in
# specs/metrics/cycle-times.yaml). Two metrics, honestly separated:
#
#   effort_hours     ADDITIVE. Idle-stripped estimated effort. Computed as a
#                    GLOBAL PARTITION of the commit stream so that
#                    Σ(per-story effort) == whole-repo effort, exactly.
#                    Overnight / weekend / UAT gaps are dropped by construction.
#
#   lead_time_minutes  NON-ADDITIVE. Calendar latency, first-commit → merge.
#                      Aggregate by median/p75 over many stories. NEVER sum.
#
# Effort model (git-hours): commits sorted by author-date; gap < IDLE (120 min)
# credits elapsed time to the later commit's story; gap >= IDLE starts a new
# session with a flat PAD (120 min). Global partition keeps Σ effort additive.
#
# Story attribution: a `Story: <id>` trailer in the commit message. Commits
# with no trailer land in the `unattributed` bucket (surfaced, never dropped).
# Merge commits are excluded (--no-merges); duplicate SHAs cannot occur in a
# single range.
#
# Usage:
#   scripts/record-cycle-time.sh report [--range <git-range>] [--story-key <key>]
#   scripts/record-cycle-time.sh append --story <id> --bcps <n> \
#         [--bcp-plus <n>] [--range <git-range>] [--merged-at <epoch>] [--file <path>] [--story-key <key>]
#
# `report`  prints the per-story partition + an additivity self-check.
# `append`  recomputes the partition and appends one row for <id> to the ledger.
#
set -euo pipefail

IDLE_SECONDS=$(( 120 * 60 ))
PAD_SECONDS=$(( 120 * 60 ))
STORY_KEY="Story"
# git-hours engine — partition + whole_range_hours (additivity oracle)
true && source "$(dirname "${BASH_SOURCE[0]}")/lib/git-hours.sh"
true && source "$(dirname "${BASH_SOURCE[0]}")/lib/record-cycle-time-lib.sh"
true && source "$(dirname "${BASH_SOURCE[0]}")/lib/python-env.sh"

die() { record_cycle_die "$@"; }
usage_cycle() { record_cycle_usage; }

command -v git >/dev/null 2>&1 || die "git not found"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || die "not inside a git repo"

cmd_report() {
  local range="HEAD" key="$STORY_KEY"
  while [ $# -gt 0 ]; do
    case "$1" in
      --range) range="$2"; shift 2 ;;
      --story-key) key="$2"; shift 2 ;;
      *) die "unknown flag: $1" ;;
    esac
  done

  local rows; rows="$(partition "$range" "$key")"
  [ -n "$rows" ] || die "no commits in range '$range'"

  printf '%-16s %12s %8s   %s\n' "story" "effort_hours" "commits" "coding_span"
  printf '%-16s %12s %8s   %s\n' "----------------" "------------" "--------" "-----------------"
  local sum
  sum="$(printf '%s\n' "$rows" | awk -F'\t' '
    {
      span = ($5 - $4) / 60.0
      printf "%-16s %12.2f %8d   %.0f min\n", $1, $2, $3, span
      total += $2
    }
    END { printf "__TOTAL__ %.4f\n", total > "/dev/stderr" }
  ' 2> >(cat >&2))"
  printf '%s\n' "$sum"

  # Additivity self-check: Σ(per-story) must equal the whole-range oracle.
  local part_total whole
  part_total="$(printf '%s\n' "$rows" | awk -F'\t' '{t+=$2} END{printf "%.4f\n", t}')"
  whole="$(whole_range_hours "$range")"
  printf -- '----\n'
  printf 'Σ(per-story effort_hours) = %s\n' "$part_total"
  printf 'whole-range effort_hours  = %s   (independent oracle)\n' "$whole"
  # Compare with a rounding tolerance (per-story values are rounded before summing).
  if awk -v a="$part_total" -v b="$whole" 'BEGIN{d=a-b; if(d<0)d=-d; exit !(d < 0.01)}'; then
    printf 'ADDITIVITY: PASS — the partition sums to the whole (within rounding).\n'
  else
    printf 'ADDITIVITY: FAIL — Σ(%s) != whole(%s)\n' "$part_total" "$whole" >&2
    return 1
  fi
}

cmd_append() {
  local range="HEAD" key="$STORY_KEY" story="" bcps="" merged_at="" file="$ROOT/specs/metrics/cycle-times.yaml"
  local telemetry=""  # path to harness telemetry JSON (GSD-2/gsd-pi format, optional)
  while [ $# -gt 0 ]; do
    case "$1" in
      --story) story="$2"; shift 2 ;;
      --bcps) bcps="$2"; shift 2 ;;
      --bcp-plus) bcp_plus="$2"; shift 2 ;;
      --range) range="$2"; shift 2 ;;
      --merged-at) merged_at="$2"; shift 2 ;;
      --file) file="$2"; shift 2 ;;
      --story-key) key="$2"; shift 2 ;;
      --telemetry) telemetry="$2"; shift 2 ;;
      *) die "unknown flag: $1" ;;
    esac
  done
  [ -n "$story" ] || die "append requires --story <id>"
  [ -n "$bcps" ]  || die "append requires --bcps <n>"
  [ -n "$merged_at" ] || merged_at="$(date -u +%s)"

  local rows line eff count first last
  rows="$(partition "$range" "$key")"
  line="$(printf '%s\n' "$rows" | awk -F'\t' -v s="$story" '$1==s')"
  [ -n "$line" ] || die "story '$story' has no attributable commits in range '$range' (check the 'Story: $story' trailer)"

  eff="$(printf '%s' "$line"   | cut -f2)"
  count="$(printf '%s' "$line" | cut -f3)"
  first="$(printf '%s' "$line" | cut -f4)"
  last="$(printf '%s' "$line"  | cut -f5)"

  # lead time: first commit of the story -> merge (calendar latency; NEVER summed).
  local lead_min
  lead_min="$(awk -v m="$merged_at" -v f="$first" 'BEGIN{printf "%.0f", (m-f)/60.0}')"

  local first_iso range_lo range_hi
  first_iso="$(date -u -d "@$first" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -r "$first" +%Y-%m-%dT%H:%M:%SZ)"
  range_lo="$(git -C "$ROOT" log --no-merges "$range" --pretty=%h --reverse 2>/dev/null \
              | awk 'NR==1{print}')"
  range_hi="$(git -C "$ROOT" rev-parse --short HEAD)"

  local generated_at
  generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  # ---- telemetry ingestion (GSD-2/gsd-pi style; e40s04) ----
  # If --telemetry <json-file> is provided, read the harness data and populate
  # agent.* fields. Otherwise, agent.* stays null (git effort is the fallback).
  local agent_cost agent_tokens_in agent_tokens_out agent_tokens_cache_read
  local agent_tokens_cache_write agent_tokens_total agent_cache_hit
  local agent_compression agent_tool_calls agent_api_requests
  local agent_duration_ms agent_model agent_tier agent_downgraded agent_skills
  agent_cost="null"; agent_tokens_total="null"; agent_cache_hit="null"
  agent_compression="null"; agent_tool_calls="null"; agent_api_requests="null"
  agent_duration_ms="null"; agent_model="null"; agent_tier="null"
  agent_downgraded="null"; agent_skills="[]"

  if [ -n "$telemetry" ] && [ -f "$telemetry" ]; then
    # GSD-2/gsd-pi snapshotUnitMetrics JSON format:
    #   { cost_usd, tokens: {input, output, cache_read, cache_write, total},
    #     cache_hit_rate_pct, compression_savings_pct, tool_calls, api_requests,
    #     agent_duration_ms, model, tier, model_downgraded, skills[] }
    if command -v jq >/dev/null 2>&1; then
      agent_cost="$(jq -r '.cost_usd // "null"' "$telemetry")"
      agent_tokens_total="$(jq -r '.tokens.total // "null"' "$telemetry")"
      agent_cache_hit="$(jq -r '.cache_hit_rate_pct // "null"' "$telemetry")"
      agent_compression="$(jq -r '.compression_savings_pct // "null"' "$telemetry")"
      agent_tool_calls="$(jq -r '.tool_calls // "null"' "$telemetry")"
      agent_api_requests="$(jq -r '.api_requests // "null"' "$telemetry")"
      agent_duration_ms="$(jq -r '.agent_duration_ms // "null"' "$telemetry")"
      agent_model="$(jq -r '.model // "null"' "$telemetry")"
      agent_tier="$(jq -r '.tier // "null"' "$telemetry")"
      agent_downgraded="$(jq -r '.model_downgraded // "null"' "$telemetry")"
      agent_skills="$(jq -c '.skills // []' "$telemetry")"
      agent_tokens_in="$(jq -r '.tokens.input // "null"' "$telemetry")"
      agent_tokens_out="$(jq -r '.tokens.output // "null"' "$telemetry")"
      agent_tokens_cache_read="$(jq -r '.tokens.cache_read // "null"' "$telemetry")"
      agent_tokens_cache_write="$(jq -r '.tokens.cache_write // "null"' "$telemetry")"
    else
      echo "record-cycle-time: jq not found — telemetry file ignored (git effort fallback)" >&2
    fi
  fi

  # Emit OKF bundle (YAML frontmatter + markdown body) per story.
  # This is the canonical format — see specs/templates/story-metrics.okf.md.
  # Fields not yet populated (quality.*, flow.*) carry null placeholders.
  {
    printf -- '---\n'
    printf -- 'okf_kind: story-metrics\n'
    printf -- 'okf_version: "0.1"\n'
    printf -- 'type: StoryMetrics\n'
    printf -- 'id: %s\n' "$story"
    printf -- 'epic: %s\n' "${story%%s*}"          # e40s03 → e40
    printf -- 'bcps: %s\n' "$bcps"
    if [ -n "$bcp_plus" ]; then
      printf -- 'bcp_plus: %s\n' "$bcp_plus"
    fi
    printf -- 'commit_range: "%s..%s"\n' "${range_lo:-$range_hi}" "$range_hi"
    printf -- 'source: measured\n'
    printf -- 'generated_at: %s\n' "$generated_at"
    printf -- 'generator: scripts/record-cycle-time.sh\n'
    printf -- '\n'
    printf -- '# DORA — the four keys (market standard). ⌀ median aggregate.\n'
    printf -- 'dora:\n'
    printf -- '  lead_time_for_changes_min: %s   # ⌀ first commit → merge\n' "$lead_min"
    printf -- '  deployment_frequency: null           # %% populated by e40s05\n'
    printf -- '  change_failure: null                   # %% populated by e40s05\n'
    printf -- '  time_to_restore_min: null              # ⌀ populated by e40s05\n'
    printf -- '\n'
    printf -- '# Agent code-generation telemetry (GSD-2 style). Σ additive.\n'
    printf -- 'agent:\n'
    printf -- '  cost_usd: %s                         # Σ harness telemetry (null = git effort fallback)\n' "$agent_cost"
    printf -- '  tokens:\n'
    printf -- '    input: %s\n' "$agent_tokens_in"
    printf -- '    output: %s\n' "$agent_tokens_out"
    printf -- '    cache_read: %s\n' "$agent_tokens_cache_read"
    printf -- '    cache_write: %s\n' "$agent_tokens_cache_write"
    printf -- '    total: %s\n' "$agent_tokens_total"
    printf -- '  cache_hit_rate_pct: %s               # %%\n' "$agent_cache_hit"
    printf -- '  compression_savings_pct: %s          # %%\n' "$agent_compression"
    printf -- '  tool_calls: %s                       # Σ\n' "$agent_tool_calls"
    printf -- '  api_requests: %s                     # Σ\n' "$agent_api_requests"
    printf -- '  agent_duration_ms: %s                # Σ (excludes human UAT wait)\n' "$agent_duration_ms"
    printf -- '  model: %s                            # •\n' "$agent_model"
    printf -- '  tier: %s                             # • light|standard|heavy\n' "$agent_tier"
    printf -- '  model_downgraded: %s                 # •\n' "$agent_downgraded"
    printf -- '  skills: %s                           # Σ\n' "$agent_skills"
    printf -- '\n'
    printf -- '# Effort (git-derived, idle-stripped, ADDITIVE).\n'
    printf -- 'effort:\n'
    printf -- '  effort_hours: %s              # Σ idle-stripped (git-hours, 120-min threshold)\n' "$eff"
    printf -- '  idle_threshold_min: 120              # • recorded for interpretability\n'
    printf -- '\n'
    printf -- '# Quality gate. ⌀ median / • static.\n'
    printf -- 'quality:\n'
    printf -- '  audit_score_pct: null                 # ⌀ populated by audit-code\n'
    printf -- '  coverage_pct: null                    # ⌀ populated by test suite\n'
    printf -- '  tests_passed: null                    # • populated by test suite\n'
    printf -- '  verify_status: null                   # pass|waived\n'
    printf -- '  rework_count: null                    # Σ reopens → feeds change_failure\n'
    printf -- '\n'
    printf -- '# Flow (worktree telemetry).\n'
    printf -- 'flow:\n'
    printf -- '  merge_duration_ms: null               # ⌀ p50/p95 across stories\n'
    printf -- '  merge_conflicts: null                 # Σ\n'
    printf -- '  worktree_orphaned: null               # •\n'
    printf -- '---\n'
    printf -- '\n'
    printf -- '# Story metrics — %s\n' "$story"
    printf -- '\n'
    printf -- 'Effort derived from git commit history via the git-hours model\n'
    printf -- '(src: kimmobrunfeldt/git-hours, 120-min idle threshold, 120-min\n'
    printf -- 'first-commit pad). Lead time is calendar latency (first commit → merge).\n'
    printf -- '\n'
    printf -- 'Aggregation tags: Σ additive (sum → total) · ⌀ median/p95 (never sum)\n'
    printf -- '· %% rate (ratio over window) · • static (identity).\n'
  } >> "$file"

  echo "record-cycle-time: OKF bundle written for $story → $file (effort=$eff h, lead=$lead_min min, commits=$count)"

  # Also update execution-status.yaml with cycle-time data
  local exec_yaml="$ROOT/specs/execution-status.yaml"
  if [ -f "$exec_yaml" ]; then
    # Compute bcp_per_hour: bcps / effort_hours, handle zero effort
    local bph
    bph="$(awk -v b="$bcps" -v e="$eff" 'BEGIN{if(e>0)printf "%.1f", b/e; else print "0.0"}')"

    $PYTHON -c "
import sys
sys.path.insert(0, '$ROOT/scripts/lib')
import yaml
try:
    with open('$exec_yaml') as f:
        data = yaml.safe_load(f) or {}
except: data = {}

stories = data.setdefault('stories', {})
entry = stories.setdefault('$story', {})
entry['effort_hours'] = float('$eff')
entry['lead_time_minutes'] = int('$lead_min')
entry['bcp_per_hour'] = float('$bph')

with open('$exec_yaml', 'w') as f:
    yaml.dump(data, f, default_flow_style=False, sort_keys=False, allow_unicode=True)
" 2>/dev/null || echo "WARN: could not update execution-status.yaml with cycle-time data" >&2
  fi
}

[ $# -ge 1 ] || { usage_cycle; }

# Trap --help before subcommand dispatch
for a in "$@"; do
  if [ "$a" = "--help" ] || [ "$a" = "-h" ]; then usage_cycle; fi
done

sub="$1"; shift
case "$sub" in
  report) cmd_report "$@" ;;
  append) cmd_append "$@" ;;
  self-test) cmd_report "$@" ;;
  help) usage_cycle ;;
  --help) usage_cycle ;;
  *) die "unknown subcommand '$sub' (run 'record-cycle-time.sh help' for help)" ;;
esac
