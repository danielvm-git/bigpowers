#!/usr/bin/env bash
# And names should describe side-effects (N7)
# Check: scripts/functions named get_* or check_* or is_* must be pure — a
# query-shaped name promises no write, so a genuine write belongs in a
# get_/set_ pair, not hidden behind one of these names.
#
# Scoped to each function's own body via awk, rather than "does this FILE
# contain both a query-named function and a write anywhere" (the original
# two-stage grep). File-level scoping flagged three pure functions purely
# because their file also contained an unrelated write:
#   - verify-cwe-fixture-sync.sh: check_sync() itself never writes; the
#     writes live in a --self-test block outside the function.
#   - lib/land-branch-push.sh: is_protected_branch_rejection()'s "hits" were
#     ==>/-> inside echo prose, not shell redirection.
#   - golden-g12-status-consistency.sh: check_tree() doesn't write; the hits
#     were an unrelated EXIT trap and a "->" inside a Python f-string.
#
# Usage: bash and-names-should-describe-side-effects-n7.sh [--self-test]
set -euo pipefail

extract_body() {
  # $1 = file, $2 = function name (no parens). Prints the lines strictly
  # between "name() {" (or "function name() {") and the matching top-level
  # closing "}" — this repo's functions close at column 0.
  awk -v fn="$2" '
    $0 ~ ("^" fn "\\(\\)") || $0 ~ ("^function " fn "\\(\\)") { inside = 1; next }
    inside && /^}/ { exit }
    inside { print }
  ' "$1"
}

n7_find_violations() { # $1 = root dir to scan
  local root="$1" file def name body writes
  local violations=""
  while IFS= read -r file; do
    while IFS= read -r def; do
      name=$(sed -E 's/^(function )?([a-zA-Z0-9_]+)\(\).*/\2/' <<<"$def")
      [[ "$name" =~ ^(get_|check_|is_) ]] || continue
      body=$(extract_body "$file" "$name")
      # Real write ops only, outside comment lines: >> redirection, a solitary
      # > (not part of -> or =>), or rm as a command word. Do NOT also exclude
      # echo/printf lines — "echo ... >> file" is the single most common real
      # write in this codebase, and excluding it would blind the check to
      # exactly the violation it exists to catch.
      writes=$(grep -vE '^[[:space:]]*#' <<<"$body" \
        | grep -E '>>|[^=-]>[[:space:]]|^[[:space:]]*rm[[:space:]]' || true)
      if [[ -n "$writes" ]]; then
        violations="${violations}${file}:${name}"$'\n'
      fi
    done < <(grep -oE '^(function )?[a-zA-Z0-9_]+\(\)' "$file" 2>/dev/null)
  done < <(grep -rlE '^(function )?(get_|check_|is_)[a-zA-Z0-9_]*\(\)' "$root" --include='*.sh' 2>/dev/null)
  printf '%s' "$violations"
}

if [[ "${1:-}" == "--self-test" ]]; then
  TMP=$(mktemp -d)
  trap 'rm -rf "$TMP"' EXIT
  cat > "$TMP/fixture.sh" <<'FIXTUREEOF'
#!/usr/bin/env bash
is_pure_check() {
  local x="$1"
  [[ -n "$x" ]]
}
get_and_write() {
  echo "reading" >> /tmp/n7-selftest-should-never-run.log
}
FIXTUREEOF
  violations=$(n7_find_violations "$TMP")
  ok=1
  grep -q "fixture.sh:get_and_write" <<<"$violations" || ok=0
  grep -q "fixture.sh:is_pure_check" <<<"$violations" && ok=0
  if [[ "$ok" -eq 1 ]]; then
    echo "self-test: PASS — flags the genuine writer, not the pure function"
    exit 0
  fi
  echo "self-test: FAIL — expected only get_and_write, got:"
  echo "$violations"
  exit 1
fi

VIOLATIONS=$(n7_find_violations scripts)

if [[ -z "$VIOLATIONS" ]]; then
  exit 0
else
  echo "Functions with pure names but write side-effects:"
  echo "$VIOLATIONS"
  exit 1
fi
