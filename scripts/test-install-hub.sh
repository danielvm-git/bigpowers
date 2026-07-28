#!/usr/bin/env bash
# story: e37s05
# test-install-hub.sh — one registry-driven check of install-hub wiring for
# every target, replacing 14 hand-written test-<target>-hub.sh scripts.
#
# Those 14 were line-for-line identical apart from three substituted tokens, and
# none of them were reachable from any gate. They also covered only 14 of the 18
# targets install.sh actually defines, so antigravity, claude, cursor and pi had
# no hub coverage at all.
#
# Targets are discovered from install.sh's own install_<id>() definitions —
# the authoritative statement of what the hub installs — rather than from a
# table that would drift. Each target's display label is read out of its
# install function body, so adding a target needs no edit here.
#
# Usage: bash scripts/test-install-hub.sh [--self-test]
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/skill-common.sh"
resolve_repo_root
cd "$REPO_ROOT"

TA_PASS=0
TA_FAIL=0
TA_TMPDIR=""

source "$(dirname "${BASH_SOURCE[0]}")/lib/test-assertions.sh"
trap ta_cleanup EXIT

INSTALL_SH="scripts/install.sh"
HELPERS_JS="scripts/lib/install-helpers.js"
SETUP_JS="bin/setup.js"
TARGETS_YAML="scripts/targets.yaml"
INSTALL_SRC="$INSTALL_SH scripts/lib/install-targets-a.sh scripts/lib/install-targets-b.sh scripts/lib/install-targets-c.sh scripts/lib/install-targets-d.sh"

# setup.js registers Kilo under a shortened id; everything else matches 1:1.
setup_id_for() { [[ "$1" == "kilocode" ]] && echo "kilo" || echo "$1"; }

discover_targets() {
  # shellcheck disable=SC2086
  grep -hoE "^install_[a-z0-9]+\(\)" $INSTALL_SRC 2>/dev/null \
    | sed 's/^install_//; s/()//' | sort -u
}

# Pull `echo "Label → ..."` out of the target's own install function body.
label_for() {
  local id="$1"
  # shellcheck disable=SC2086
  # Strip around the arrow with sub() rather than substr()/RLENGTH — the arrow
  # is multi-byte UTF-8 and byte-indexed slicing corrupts the trailing char.
  awk -v fn="install_${id}()" '
    $0 ~ "^" fn { inside = 1; next }
    inside && /^}/ { exit }
    inside && /echo "[^"]* →/ {
      line = $0
      sub(/^[^"]*"/, "", line)
      sub(/ →.*$/, "", line)
      print line; exit
    }
  ' $INSTALL_SRC 2>/dev/null | head -1
}

# Returns the delegate id when install_<id>() does nothing but call another
# install_<other>, otherwise empty.
alias_target_for() {
  local id="$1"
  # shellcheck disable=SC2086
  awk -v fn="install_${id}()" '
    $0 ~ "^" fn { inside = 1; body = ""; next }
    inside && /^}/ { exit }
    inside {
      line = $0
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
      if (line != "") body = body line "\n"
    }
    END {
      n = split(body, lines, "\n")
      count = 0; only = ""
      for (i = 1; i <= n; i++) if (lines[i] != "") { count++; only = lines[i] }
      if (count == 1 && only ~ /^install_[a-z0-9]+$/) { sub(/^install_/, "", only); print only }
    }
  ' $INSTALL_SRC 2>/dev/null | head -1
}

echo "=== test-install-hub.sh ==="

TARGETS=$(discover_targets)
[[ -n "$TARGETS" ]] || { ta_fail "no install_<id>() functions discovered"; echo "test-install-hub: $TA_PASS passed, $TA_FAIL failed"; exit 1; }
echo "Discovered $(wc -w <<<"$TARGETS" | tr -d ' ') install targets"

DRY_OUT="$(bash "$INSTALL_SH" --dry-run 2>&1 || true)"
DRY_UNINSTALL="$(bash "$INSTALL_SH" --dry-run --uninstall 2>&1 || true)"
SETUP_IDS="$(sed -n '/SUPPORTED_IDS = new Set/,/);/p' "$SETUP_JS")"

for id in $TARGETS; do
  # shellcheck disable=SC2086
  grep -qE "^uninstall_${id}\(\)" $INSTALL_SRC \
    && ta_pass "$id: uninstall_${id}() defined" \
    || ta_fail "$id: uninstall_${id}() missing"

  # Some targets are pure aliases (install_antigravity just calls install_agy).
  # They own no label; the delegate's label is asserted on its own pass.
  alias_of="$(alias_target_for "$id")"
  label="$(label_for "$id")"
  if [[ -z "$label" && -n "$alias_of" ]]; then
    ta_pass "$id: alias of $alias_of (label asserted there)"
  elif [[ -z "$label" ]]; then
    ta_fail "$id: no 'Label →' line found inside install_${id}()"
  else
    grep -qF "$label →" <<<"$DRY_OUT" \
      && ta_pass "$id: dry-run shows '$label'" \
      || ta_fail "$id: dry-run missing '$label' section"
    grep -qF "$label →" <<<"$DRY_UNINSTALL" \
      && ta_pass "$id: dry-run --uninstall shows '$label'" \
      || ta_fail "$id: dry-run --uninstall missing '$label' section"
  fi

  grep -q "case '${id}'" "$HELPERS_JS" \
    && ta_pass "$id: install-helpers case" \
    || ta_fail "$id: install-helpers missing case '${id}'"

  sid="$(setup_id_for "$id")"
  grep -q "'${sid}'" <<<"$SETUP_IDS" \
    && ta_pass "$id: setup.js SUPPORTED_IDS carries '${sid}'" \
    || ta_fail "$id: setup.js SUPPORTED_IDS missing '${sid}'"
done

# Global syntax gates — previously repeated in all 14 scripts.
bash -n "$INSTALL_SH" && ta_pass "bash -n install.sh" || ta_fail "bash -n install.sh"
node --check "$HELPERS_JS" >/dev/null 2>&1 && ta_pass "node --check install-helpers.js" || ta_fail "node --check install-helpers.js"
node --check "$SETUP_JS" >/dev/null 2>&1 && ta_pass "node --check setup.js" || ta_fail "node --check setup.js"
grep -q "SUPPORTED_IDS = new Set" "$SETUP_JS" && ta_pass "setup.js defines SUPPORTED_IDS" || ta_fail "setup.js missing SUPPORTED_IDS"

# Registry coverage is reported, not enforced: copilot, opencode, claude and
# antigravity ship install functions but have no targets.yaml row today.
# Failing on that here would block unrelated work; it is tracked separately.
for id in $TARGETS; do
  grep -q "id: ${id}$" "$TARGETS_YAML" || echo "  note: $id installs but has no targets.yaml row"
done

echo "test-install-hub: $TA_PASS passed, $TA_FAIL failed"
[[ "$TA_FAIL" -eq 0 ]] || exit 1
