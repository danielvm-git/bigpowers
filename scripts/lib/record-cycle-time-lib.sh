#!/usr/bin/env bash
# record-cycle-time-lib.sh — shared helpers for record-cycle-time.sh

record_cycle_die() { echo "record-cycle-time: $*" >&2; exit 1; }

record_cycle_usage() {
  cat <<'EOF'
Usage: scripts/record-cycle-time.sh <command> [flags]

Commands:
  report      Compute per-story effort partition + additivity self-check.
              Flags: --range <git-range>  --story-key <trailer-key>
  append      Recompute partition and append one row for a story.\n              Flags: --story <id> --bcps <n> [--bcp-plus <n>] [--range <git-range>]\n                     [--merged-at <epoch>] [--file <path>] [--story-key <trailer-key>]
  self-test   Run report, then exit 0 on additivity PASS; exit 1 on FAIL.
              Flags: --range <git-range>  --story-key <trailer-key>
  help        Show this message.

Global flags:
  --help      Show this message (works with any subcommand).

Description:
  Computes git-derived, additive effort from commit history.
  Two metrics, separated: effort_hours (ADDITIVE, Σ = total) and
  lead_time_minutes (calendar latency, median-aggregate, NEVER sum).

  Uses the git-hours model: commits sorted by author-date across the
  whole range; gaps < 120 min counted as effort; gaps >= 120 min
  start a new session with a 120-min pad.
EOF
  exit 0
}
