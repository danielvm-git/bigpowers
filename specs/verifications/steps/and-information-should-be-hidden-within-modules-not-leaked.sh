#!/usr/bin/env bash
# And information should be hidden within modules, not leaked
# Check: no script in scripts/ cross-sources another (no global state leakage).
# Exclusions: sourcing scripts/lib/ is intentional modularization
#
# Resolves one level of variable indirection before applying the /lib/
# exemption: scripts/install.sh hoists `_INSTALL_LIB="$(dirname ...)/lib"`
# on one line, then sources `"$_INSTALL_LIB/install-targets-a.sh"` on a
# later line. The literal substring "/lib/" isn't in the source line itself,
# only in the variable's own assignment — ~105 other source lines elsewhere
# spell the path inline and are already correctly exempted. This does not
# attempt general variable analysis, only this repo's one existing
# hoist-then-source pattern (assign a path variable, then `source "$VAR/..."`).
#
# Also exempts a sourcing FILE that itself lives under scripts/lib/ (peer lib
# module composing another lib module — audit-compliance-runner.sh sourcing
# audit-compliance-judge.sh, migrate-version-run.sh sourcing its siblings,
# etc). The original grep -v '/lib/' exempted this too, but only by accident:
# it ran over the whole "path:line:content" string, so a *sourcing file's own
# path* containing scripts/lib/ satisfied it regardless of the target. A
# rewrite scoped to content-only lost that. Restored explicitly rather than
# left as an accident, because lib-to-lib sourcing already has its own
# dedicated, more precise gate: specs/import-boundaries.json +
# check-import-boundaries.sh. This check's job is catching leakage from
# ordinary scripts/*.sh into each other, not re-litigating lib/ composition.
#
# Usage: bash and-information-should-be-hidden-within-modules-not-leaked.sh [--self-test]
set -euo pipefail

# $1 = a source/. line's content, $2 = the file it's in. True if the target
# resolves to a /lib/ path, directly or via one hoisted variable.
infohide_resolves_to_lib() {
  local content="$1" file="$2" var assign
  [[ "$content" =~ /lib/ ]] && return 0
  [[ "$content" =~ ^(source|\.)[[:space:]]+\"?\$\{?([A-Za-z_][A-Za-z0-9_]*)\}?/ ]] || return 1
  var="${BASH_REMATCH[2]}"
  assign=$(grep -E "^${var}=" "$file" | head -1)
  [[ "$assign" =~ /lib ]]
}

infohide_find_violations() { # $1 = root dir
  local root="$1" file lineno content
  local violations=""
  while IFS= read -r file; do
    [[ "$file" == */lib/* ]] && continue
    # grep -n on a single file yields "LINENO:CONTENT" (2 fields) — reading
    # into exactly 2 vars lets `content` correctly absorb any further colons
    # the line itself contains, rather than truncating it.
    while IFS=: read -r lineno content; do
      infohide_resolves_to_lib "$content" "$file" && continue
      violations="${violations}${file}:${lineno}:${content}"$'\n'
    done < <(grep -nE '^source |^\. ' "$file" 2>/dev/null)
  done < <(grep -rlE '^source |^\. ' "$root" --include='*.sh' 2>/dev/null)
  printf '%s' "$violations"
}

if [[ "${1:-}" == "--self-test" ]]; then
  TMP=$(mktemp -d)
  trap 'rm -rf "$TMP"' EXIT
  {
    echo '#!/usr/bin/env bash'
    echo 'LIBDIR="$(dirname "$0")/lib"'
    echo 'source "$LIBDIR/helper.sh"'
    echo 'source "scripts/sibling-script.sh"'
  } > "$TMP/fixture.sh"
  violations=$(infohide_find_violations "$TMP")
  ok=1
  grep -q 'sibling-script.sh' <<<"$violations" || ok=0
  grep -q 'LIBDIR/helper.sh' <<<"$violations" && ok=0
  if [[ "$ok" -eq 1 ]]; then
    echo "self-test: PASS — resolves the hoisted lib var, still flags a real cross-source"
    exit 0
  fi
  echo "self-test: FAIL — got:"
  echo "$violations"
  exit 1
fi

VIOLATIONS=$(infohide_find_violations scripts)

if [[ -z "$VIOLATIONS" ]]; then
  exit 0
else
  echo "Cross-module sourcing found (information leakage):"
  echo "$VIOLATIONS"
  exit 1
fi
