#!/usr/bin/env bash
# story: BUG-2026-11-03-cli-nontty-silent-noop
# story: BUG-2026-11-03-cli-update-stale-version
# test-bigpowers-cli.sh — the CLI must be usable from a shell with no TTY.
#
# Two defects, one gate:
#   1. `update` printed the version the process started with (require() cache from
#      before the self-update), not the one it had just installed.
#   2. With stdin at EOF (agent, CI, `| cat`), `setup`/`install`/`update` drew the
#      first @clack/prompts menu, installed nothing and exited 0 — a silent no-op
#      that reports success.
#
# Every CLI invocation runs under an alarm watchdog: if the installer ever starts
# waiting on a prompt again, this gate fails instead of hanging the suite.
#
# Usage: bash scripts/test-bigpowers-cli.sh
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/skill-common.sh"
resolve_repo_root
cd "$REPO_ROOT"

source scripts/lib/test-assertions.sh
TA_PASS=0
TA_FAIL=0
TA_TMPDIR="$(mktemp -d)"
trap ta_cleanup EXIT

echo "=== test-bigpowers-cli.sh ==="

VERSION="$(node -p "require('./package.json').version")"
CLI="$REPO_ROOT/bin/bigpowers.js"
FAKE_HOME="$TA_TMPDIR/home"
mkdir -p "$FAKE_HOME"

# run_cli <stdin-mode: closed|empty> <seconds> <args...>
# Isolated HOME, npm fetch disabled, alarm watchdog. A non-zero exit is reported
# as a trailing __EXIT_<n>__ line so callers can assert on both streams and code.
run_cli() {
  local stdin_mode="$1" seconds="$2"
  shift 2
  (
    cd "$REPO_ROOT"
    run() { HOME="$FAKE_HOME" BIGPOWERS_SKIP_SELF_UPDATE=1 \
      perl -e 'alarm shift; exec @ARGV' "$seconds" node "$CLI" "$@" 2>&1; }
    if [ "$stdin_mode" = "closed" ]; then
      run "$@" < /dev/null
    else
      printf '' | run "$@"
    fi
  ) || echo "__EXIT_$?__"
}

# ── 1. version is read from disk, not from the require cache ────────────────
mkdir -p "$TA_TMPDIR/pkgver"
CACHE_OUT="$(node -e '
const fs = require("fs"), path = require("path");
const dir = process.argv[1];
fs.writeFileSync(path.join(dir, "package.json"), JSON.stringify({ version: "2.88.5" }));
const required = require(path.join(dir, "package.json"));           // populates the cache
fs.writeFileSync(path.join(dir, "package.json"), JSON.stringify({ version: "2.92.0" }));
const { readPackageVersion } = require(process.argv[2]);
const seen = readPackageVersion(dir);
process.stdout.write(`${required.version}|${seen}`);
' "$TA_TMPDIR/pkgver" "$REPO_ROOT/scripts/lib/cli-version.js" 2>/dev/null || echo "MODULE_MISSING")"
if [ "$CACHE_OUT" = "2.88.5|2.92.0" ]; then
  ta_pass "(1) readPackageVersion sees the on-disk version after the file changes"
else
  ta_fail "(1) version read ignored the on-disk file (got '$CACHE_OUT', want '2.88.5|2.92.0')"
fi

# ── 2. setup with no TTY and no --yes must fail fast, not draw a menu ───────
RC2_OUT="$(run_cli closed 25 setup)"
RC2="$(printf '%s' "$RC2_OUT" | sed -n 's/^__EXIT_\([0-9]*\)__$/\1/p' | tail -1)"
BODY2="$(printf '%s' "$RC2_OUT" | sed 's/^__EXIT_[0-9]*__$//')"
if [ "${RC2:-0}" -eq 2 ] && printf '%s' "$BODY2" | grep -q -- "--yes"; then
  ta_pass "(2) setup without a TTY and without --yes fails fast with guidance (exit 2)"
elif [ "${RC2:-0}" -eq 0 ]; then
  ta_fail "(2) setup without a TTY exited 0 without installing (the silent no-op)"
else
  ta_fail "(2) setup without a TTY exited ${RC2:-?} without naming --yes in the message"
fi

# ── 3. update with no TTY replays the manifest and installs ─────────────────
mkdir -p "$FAKE_HOME/.bigpowers"
cat > "$FAKE_HOME/.bigpowers/install-state.json" <<'JSON'
{ "scope": "global", "tools": ["pi"] }
JSON
RC3_OUT="$(run_cli closed 60 update)"
RC3="$(printf '%s' "$RC3_OUT" | sed -n 's/^__EXIT_\([0-9]*\)__$/\1/p' | tail -1)"
BODY3="$(printf '%s' "$RC3_OUT" | sed 's/^__EXIT_[0-9]*__$//')"
LINK3="$FAKE_HOME/.pi/agent/skills/survey-context"
if [ "${RC3:-0}" -ne 0 ]; then
  ta_fail "(3) update without a TTY exited ${RC3:-?} (want 0)"
elif printf '%s' "$BODY3" | grep -q "How would you like to proceed"; then
  ta_fail "(3) update without a TTY still drew an interactive menu"
elif [ ! -L "$LINK3" ]; then
  ta_fail "(3) update without a TTY installed nothing ($LINK3 is not a symlink)"
else
  ta_pass "(3) update without a TTY installs from the manifest and prints no menu"
fi

# ── 4. explicit flags make setup non-interactive ────────────────────────────
rm -rf "$FAKE_HOME/.pi"
RC4_OUT="$(run_cli closed 60 setup --yes --tools=pi)"
RC4="$(printf '%s' "$RC4_OUT" | sed -n 's/^__EXIT_\([0-9]*\)__$/\1/p' | tail -1)"
if [ "${RC4:-0}" -eq 0 ] && [ -L "$FAKE_HOME/.pi/agent/skills/survey-context" ]; then
  ta_pass "(4) setup --yes --tools=pi installs without prompting"
else
  ta_fail "(4) setup --yes --tools=pi exited ${RC4:-?} and left no symlink"
fi

# ── 5. the banner reports the version that is on disk ──────────────────────
if printf '%s' "$BODY3" | grep -q "v${VERSION}"; then
  ta_pass "(5) update banner reports the installed version (v$VERSION)"
else
  ta_fail "(5) update banner did not report v$VERSION"
fi

# ── 6. --uninstall removes the links it installed, without a prompt ────────
RC6_OUT="$(run_cli closed 60 setup --uninstall --yes)"
RC6="$(printf '%s' "$RC6_OUT" | sed -n 's/^__EXIT_\([0-9]*\)__$/\1/p' | tail -1)"
if [ "${RC6:-0}" -eq 0 ] && [ ! -e "$FAKE_HOME/.pi/agent/skills/survey-context" ]; then
  ta_pass "(6) setup --uninstall --yes removes the links without prompting"
elif [ "${RC6:-0}" -ne 0 ]; then
  ta_fail "(6) setup --uninstall --yes exited ${RC6:-?}"
else
  ta_fail "(6) setup --uninstall --yes left $FAKE_HOME/.pi/agent/skills/survey-context in place"
fi

echo "$TA_PASS passed, $TA_FAIL failed"
[[ "$TA_FAIL" -eq 0 ]]
