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
# Effort model (git-hours, kimmobrunfeldt/git-hours src/index.js:15,18):
#   * commits sorted by author-date across the WHOLE range;
#   * gap < IDLE (120 min)  -> real elapsed time, credited to the *later*
#                              commit's story (the work that produced it);
#   * gap >= IDLE           -> session boundary: credit a flat PAD (120 min)
#                              to the later commit's story, drop the idle time;
#   * the very first commit of the stream is never padded (no left neighbour).
#
# Why not run git-hours per story and sum? Because it doesn't sum: each
# per-story run re-pads its own first commit and drops its own leading gap,
# so the sum leaks both ways. The global partition above is additive by
# construction. Attribution of a shared <120-min window to "the later commit's
# story" is a documented CONVENTION, not a physical truth — it is the only way
# to keep the numbers summable without double-counting.
#
# Story attribution: a `Story: <id>` trailer in the commit message. Commits
# with no trailer land in the `unattributed` bucket (surfaced, never dropped).
# Merge commits are excluded (--no-merges); duplicate SHAs cannot occur in a
# single range.
#
# Usage:
#   scripts/record-cycle-time.sh report [--range <git-range>] [--story-key <key>]
#   scripts/record-cycle-time.sh append --story <id> --bcps <n> \
#         [--range <git-range>] [--merged-at <epoch>] [--file <path>] [--story-key <key>]
#
# `report`  prints the per-story partition + an additivity self-check.
# `append`  recomputes the partition and appends one row for <id> to the ledger.
#
set -euo pipefail

IDLE_SECONDS=$(( 120 * 60 ))   # git-hours maxCommitDiffInMinutes
PAD_SECONDS=$(( 120 * 60 ))    # git-hours firstCommitAdditionInMinutes
STORY_KEY="Story"

die() { echo "record-cycle-time: $*" >&2; exit 1; }

command -v git >/dev/null 2>&1 || die "git not found"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || die "not inside a git repo"

# ---- engine ---------------------------------------------------------------
# Emits, per story bucket, a TSV line:  story <TAB> effort_hours <TAB> commit_count <TAB> first_epoch <TAB> last_epoch
# Reads the whole range once and partitions globally, so the lines are additive.
partition() {
  local range="$1" key="$2"
  # US (\x1f) between fields; one commit per line, oldest→newest by author date.
  git -C "$ROOT" log --no-merges "$range" \
      --pretty=format:"%at%x1f%H%x1f%(trailers:key=${key},valueonly,separator=%x2C)" \
    | sort -n \
    | awk -F '\x1f' -v IDLE="$IDLE_SECONDS" -v PAD="$PAD_SECONDS" '
        {
          ts = $1 + 0
          story = $3
          gsub(/[[:space:]]/, "", story)
          if (story == "") story = "unattributed"
          count[story]++
          seen[story] = 1
          if (NR > 1) {
            gap = ts - prev
            if (gap < 0) gap = 0              # guard against author-date skew
            if (gap < IDLE) eff[story] += gap  # real elapsed effort -> later commit
            else            eff[story] += PAD   # new session pad -> later commit
          }
          if (!(story in first)) first[story] = ts
          last[story] = ts
          prev = ts
        }
        END {
          for (s in seen)
            printf "%s\t%.4f\t%d\t%d\t%d\n", s, eff[s] / 3600.0, count[s], first[s], last[s]
        }' \
    | sort
}

# Whole-range effort in one bucket — the independent additivity oracle.
whole_range_hours() {
  local range="$1"
  git -C "$ROOT" log --no-merges "$range" --pretty=format:"%at" \
    | sort -n \
    | awk -v IDLE="$IDLE_SECONDS" -v PAD="$PAD_SECONDS" '
        { ts=$1+0; if(NR>1){gap=ts-prev; if(gap<0)gap=0; if(gap<IDLE)e+=gap; else e+=PAD} prev=ts }
        END { printf "%.4f\n", e/3600.0 }'
}

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
  while [ $# -gt 0 ]; do
    case "$1" in
      --story) story="$2"; shift 2 ;;
      --bcps) bcps="$2"; shift 2 ;;
      --range) range="$2"; shift 2 ;;
      --merged-at) merged_at="$2"; shift 2 ;;
      --file) file="$2"; shift 2 ;;
      --story-key) key="$2"; shift 2 ;;
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

  {
    printf -- '- id: %s\n' "$story"
    printf -- '  bcps: %s\n' "$bcps"
    printf -- '  effort_hours: %s        # ADDITIVE, idle-stripped (120-min threshold)\n' "$eff"
    printf -- '  lead_time_minutes: %s   # calendar latency, first-commit → merge; median-aggregate, never sum\n' "$lead_min"
    printf -- '  commit_count: %s\n' "$count"
    printf -- '  first_commit: "%s"\n' "$first_iso"
    printf -- '  commit_range: "%s..%s"\n' "${range_lo:-$range_hi}" "$range_hi"
    printf -- '  source: measured\n'
    printf -- '  idle_threshold_min: 120\n'
  } >> "$file"

  echo "record-cycle-time: appended row for $story to $file (effort_hours=$eff, lead_time_minutes=$lead_min, commits=$count)"
}

[ $# -ge 1 ] || die "usage: record-cycle-time.sh {report|append} [flags]"
sub="$1"; shift
case "$sub" in
  report) cmd_report "$@" ;;
  append) cmd_append "$@" ;;
  *) die "unknown subcommand '$sub' (expected report|append)" ;;
esac
