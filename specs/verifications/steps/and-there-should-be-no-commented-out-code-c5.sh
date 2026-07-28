#!/usr/bin/env bash
# And there should be no commented-out code (C5)
# Check: lines that match commented-out shell syntax (if [, for , while [, function).
#
# Tightened to require actual shell-statement shape (a bracket test with
# then/do, a real `for x in`, or `name() {`) rather than the bare words
# "if"/"for"/"while"/"function" anywhere in a comment. The loose version
# flagged ordinary prose:
#   - "...install function still reads..." (the word "function", no `() {`)
#   - "...registering the mapping ... for a one-release expiry window."
#     (the word "for", not followed by `x in`)
#   - "...function runs inside a command-substitution subshell..." (same as
#     the first)
#
# Usage: bash and-there-should-be-no-commented-out-code-c5.sh [--self-test]
set -euo pipefail

PATTERN='^[[:space:]]*#[[:space:]]*(if \[.*\][[:space:]]*;?[[:space:]]*then\b|for [a-zA-Z_][a-zA-Z0-9_]* in \b|while \[.*\][[:space:]]*;?[[:space:]]*do\b|[a-zA-Z_][a-zA-Z0-9_]*\(\)[[:space:]]*\{)'

c5_find_violations() { # $1 = root(s), space-separated
  grep -rnE "$PATTERN" $1 2>/dev/null || true
}

if [[ "${1:-}" == "--self-test" ]]; then
  TMP=$(mktemp -d)
  trap 'rm -rf "$TMP"' EXIT
  # Built line-by-line via printf, not a literal heredoc: this script's own
  # source lives under specs/verifications/steps/, which the real check below
  # also scans, so a heredoc body written as genuine column-0 "# if [...];
  # then" text would match the pattern in THIS file, not just the fixture.
  {
    echo '#!/usr/bin/env bash'
    printf '# %s\n' 'if [ -f x ]; then'
    printf '# %s\n' '  echo "old code, commented out"'
    printf '# %s\n' 'fi'
    printf '# %s\n' 'The install function still reads a rendered directory for the target.'
  } > "$TMP/fixture.sh"
  violations=$(c5_find_violations "$TMP")
  ok=1
  grep -q 'fixture.sh:.*if \[ -f x \]; then' <<<"$violations" || ok=0
  grep -q 'The install function' <<<"$violations" && ok=0
  if [[ "$ok" -eq 1 ]]; then
    echo "self-test: PASS — flags the genuine commented-out code, not the prose"
    exit 0
  fi
  echo "self-test: FAIL — got:"
  echo "$violations"
  exit 1
fi

VIOLATIONS=$(c5_find_violations "scripts/ specs/verifications/steps/")

if [[ -z "$VIOLATIONS" ]]; then
  exit 0
else
  echo "Commented-out code found:"
  echo "$VIOLATIONS"
  exit 1
fi
