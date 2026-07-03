#!/usr/bin/env bash
# story: e40s06
# emit-okf-metrics.sh — shared OKF story-metrics bundle emitter (e40 provenance gate).
# Sourced by scripts/record-cycle-time.sh; emits YAML frontmatter + markdown body.
# Not meant to be run standalone.

# Usage: emit_okf_metrics <story> <bcps> <effort_hours> <lead_min> <commit_range> <generated_at>
#                         <agent_cost> <agent_tokens_total> <agent_cache_hit>
#                         <agent_compression> <agent_tool_calls> <agent_api_requests>
#                         <agent_duration_ms> <agent_model> <agent_tier>
#                         <agent_downgraded> <agent_skills>
#                         <agent_tokens_in> <agent_tokens_out>
#                         <agent_tokens_cache_read> <agent_tokens_cache_write>
#                         [--file <path>]
emit_okf_metrics() {
  local story="$1" bcps="$2" eff="$3" lead_min="$4" commit_range="$5" generated_at="$6"
  local agent_cost="${7:-null}" agent_tokens_total="${8:-null}" agent_cache_hit="${9:-null}"
  local agent_compression="${10:-null}" agent_tool_calls="${11:-null}" agent_api_requests="${12:-null}"
  local agent_duration_ms="${13:-null}" agent_model="${14:-null}" agent_tier="${15:-null}"
  local agent_downgraded="${16:-null}" agent_skills="${17:-[]}"
  local agent_tokens_in="${18:-null}" agent_tokens_out="${19:-null}"
  local agent_tokens_cache_read="${20:-null}" agent_tokens_cache_write="${21:-null}"

  local file
  file="$(git rev-parse --show-toplevel 2>/dev/null)/specs/metrics/cycle-times.yaml"
  while [ $# -gt 0 ]; do
    case "$1" in --file) file="$2"; shift 2 ;; *) shift ;; esac
  done

  {
    printf -- '---\n'
    printf -- 'okf_kind: story-metrics\n'
    printf -- 'okf_version: "0.1"\n'
    printf -- 'id: %s\n' "$story"
    printf -- 'epic: %s\n' "${story%%s*}"
    printf -- 'bcps: %s\n' "$bcps"
    printf -- 'commit_range: "%s"\n' "$commit_range"
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
    printf -- '  cost_usd: %s                         # Σ\n' "$agent_cost"
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
    printf -- '  agent_duration_ms: %s                # Σ\n' "$agent_duration_ms"
    printf -- '  model: %s                            # •\n' "$agent_model"
    printf -- '  tier: %s                             # •\n' "$agent_tier"
    printf -- '  model_downgraded: %s                 # •\n' "$agent_downgraded"
    printf -- '  skills: %s                           # Σ\n' "$agent_skills"
    printf -- '\n'
    printf -- '# Effort (git-derived, idle-stripped, ADDITIVE).\n'
    printf -- 'effort:\n'
    printf -- '  effort_hours: %s              # Σ idle-stripped\n' "$eff"
    printf -- '  idle_threshold_min: 120              # •\n'
    printf -- '\n'
    printf -- '# Quality gate. ⌀ median / • static.\n'
    printf -- 'quality:\n'
    printf -- '  audit_score_pct: null                 # ⌀\n'
    printf -- '  coverage_pct: null                    # ⌀\n'
    printf -- '  tests_passed: null                    # •\n'
    printf -- '  verify_status: null                   # pass|waived\n'
    printf -- '  rework_count: null                    # Σ\n'
    printf -- '\n'
    printf -- '# Flow (worktree telemetry).\n'
    printf -- 'flow:\n'
    printf -- '  merge_duration_ms: null               # ⌀\n'
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
}
