#!/usr/bin/env bash
# story: e40s04
# git-hours.sh — deterministic, additive git-hours effort engine.
# Source this file in scripts that compute effort from commit history.
# Requires: IDLE_SECONDS, PAD_SECONDS, ROOT set before sourcing.
#
# Model (kimmobrunfeldt/git-hours):
#   * commits sorted by author-date across the WHOLE range;
#   * gap < IDLE  -> real elapsed time, credited to later commit's story;
#   * gap >= IDLE -> session boundary: credit PAD to later commit's story;
#   * first commit never padded.
#
# partition() emits per-story TSV: story \t effort_hours \t commits \t first_epoch \t last_epoch
# whole_range_hours() emits a single float: whole-range effort (additivity oracle)

partition() {
  local range="$1" key="$2"
  git -C "$ROOT" log --no-merges "$range" \
      --pretty=format:"%at%x1f%H%x1f%(trailers:key=${key},valueonly,separator=%x2C)" \
    | sort -n \
    | awk -v FS="$(printf '\037')" -v IDLE="$IDLE_SECONDS" -v PAD="$PAD_SECONDS" '
        {
          ts = $1 + 0; story = $3
          gsub(/[[:space:]]/, "", story)
          if (story == "") story = "unattributed"
          count[story]++; seen[story] = 1
          if (NR > 1) {
            gap = ts - prev
            if (gap < 0) gap = 0
            if (gap < IDLE) eff[story] += gap
            else            eff[story] += PAD
          }
          if (!(story in first)) first[story] = ts
          last[story] = ts; prev = ts
        }
        END {
          for (s in seen)
            printf "%s\t%.4f\t%d\t%d\t%d\n", s, eff[s] / 3600.0, count[s], first[s], last[s]
        }' \
    | sort
}

whole_range_hours() {
  local range="$1"
  git -C "$ROOT" log --no-merges "$range" --pretty=format:"%at" \
    | sort -n \
    | awk -v IDLE="$IDLE_SECONDS" -v PAD="$PAD_SECONDS" '
        { ts=$1+0; if(NR>1){gap=ts-prev; if(gap<0)gap=0; if(gap<IDLE)e+=gap; else e+=PAD} prev=ts }
        END { printf "%.4f\n", e/3600.0 }'
}
