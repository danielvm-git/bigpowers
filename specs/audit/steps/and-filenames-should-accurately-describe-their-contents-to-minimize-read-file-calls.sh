#!/usr/bin/env bash
# And filenames should accurately describe their contents to minimize 'read_file' calls
# Check: no generic/vague filenames (utils, helpers, misc, common, temp) in scripts or skill dirs.
VIOLATIONS=$(find scripts/ -name "*.sh" 2>/dev/null \
  | xargs -I{} basename {} .sh \
  | grep -iE '^(utils?|helpers?|misc|common|temp|tmp|stuff)$')

if [[ -z "$VIOLATIONS" ]]; then
  exit 0
else
  echo "Generic filenames found: $VIOLATIONS"
  exit 1
fi
