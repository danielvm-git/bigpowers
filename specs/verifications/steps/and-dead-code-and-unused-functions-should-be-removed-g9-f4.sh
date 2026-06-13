#!/usr/bin/env bash
# And dead code and unused functions should be removed (G9, F4)
# Check: functions defined in scripts/ that are never called outside their own file.
DEAD=""
while IFS= read -r file; do
  while IFS= read -r func; do
    # Count occurrences across all .sh files; definition counts as 1
    total=$(grep -rc "\b${func}\b" scripts/ 2>/dev/null | awk -F: '{sum+=$2} END{print sum+0}')
    if [[ "$total" -le 1 ]]; then
      DEAD="$DEAD\n$file: $func"
    fi
  done < <(grep -oE '^[a-z_][a-z_0-9]*\s*\(\)' "$file" 2>/dev/null | grep -oE '^[a-z_][a-z_0-9]*')
done < <(find scripts/ -name "*.sh" 2>/dev/null)

if [[ -z "$DEAD" ]]; then
  exit 0
else
  printf "Potentially dead functions:%b\n" "$DEAD"
  exit 1
fi
