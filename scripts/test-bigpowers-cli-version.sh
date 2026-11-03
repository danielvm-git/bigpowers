#!/usr/bin/env bash
# story: BUG-2026-11-03-cli-update-stale-version
# test-bigpowers-cli-version.sh — `update` must report the version it just installed.
#
# Reproduces the reported symptom without touching npm or the real HOME:
#   bigpowers update  → banner v2.88.5   (wrong: a require() cache captured at startup,
#                                          before `npm install -g bigpowers@latest`)
#   bigpowers install → banner v2.92.0   (right: a fresh process reads package.json)
#
# Three assertions:
#   1. readPackageVersion() sees the on-disk version even after package.json was
#      already require()d and then rewritten (the exact mechanism).
#   2. the installer's banner renders that fresh value — end to end, from a copy
#      of bin/ whose version changes between process start and banner render.
#   3. neither CLI entry point still interpolates a cached `pkg.version` into a
#      user-facing line (static guard: the cache is invisible at runtime until
#      the day a self-update happens).
#
# Usage: bash scripts/test-bigpowers-cli-version.sh
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/skill-common.sh"
resolve_repo_root
cd "$REPO_ROOT"

source scripts/lib/test-assertions.sh
TA_PASS=0
TA_FAIL=0
TA_TMPDIR="$(mktemp -d)"
trap ta_cleanup EXIT

echo "=== test-bigpowers-cli-version.sh ==="

# ── 1. readPackageVersion ignores the require cache ─────────────────────────
mkdir -p "$TA_TMPDIR/pkgver"
if [ ! -f scripts/lib/cli-version.js ]; then
  ta_fail "(1) scripts/lib/cli-version.js is missing — nothing reads the version from disk"
  CACHE_OUT=""
else
CACHE_OUT="$(node -e '
const fs = require("fs"), path = require("path");
const dir = process.argv[1];
fs.writeFileSync(path.join(dir, "package.json"), JSON.stringify({ version: "2.88.5" }));
const cached = require(path.join(dir, "package.json"));          // what bin/bigpowers.js does at startup
fs.writeFileSync(path.join(dir, "package.json"), JSON.stringify({ version: "2.92.0" }));  // npm install -g @latest
const { readPackageVersion } = require(process.argv[2]);
process.stdout.write(`${cached.version}|${readPackageVersion(dir)}`);
' "$TA_TMPDIR/pkgver" "$REPO_ROOT/scripts/lib/cli-version.js")"
fi
if [ "$CACHE_OUT" = "2.88.5|2.92.0" ]; then
  ta_pass "(1) readPackageVersion sees the on-disk version after package.json is rewritten"
else
  ta_fail "(1) version read followed the require cache: got '$CACHE_OUT' (want '2.88.5|2.92.0')"
fi

# ── 2. the banner an `update` run prints carries the new version ────────────
# Drive the exact sequence bin/bigpowers.js uses: read package.json at startup,
# let `npm install -g bigpowers@latest` replace it, then require bin/setup.js —
# which renders the banner. stdin at EOF makes setup draw the banner and exit, so
# nothing is installed and no prompt is answered.
FAKE_PKG="$TA_TMPDIR/fakepkg"
mkdir -p "$FAKE_PKG"
cp -R "$REPO_ROOT/bin" "$FAKE_PKG/bin"
cp -R "$REPO_ROOT/scripts" "$FAKE_PKG/scripts"
ln -sfn "$REPO_ROOT/node_modules" "$FAKE_PKG/node_modules"
printf '{"name":"bigpowers-fake","version":"2.88.5"}\n' > "$FAKE_PKG/package.json"
cat > "$FAKE_PKG/driver.js" <<'DRIVER'
// Mimics `bigpowers update`: snapshot at startup, reinstall over it, then render.
const { execFileSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const root = __dirname;
const pkg = require(path.join(root, 'package.json'));   // 2.88.5 — the version the process booted with
fs.writeFileSync(path.join(root, 'package.json'), JSON.stringify({ name: 'bigpowers-fake', version: '2.92.0' }));
process.stdout.write(`startup=${pkg.version}\n`);
require(path.join(root, 'bin', 'setup.js'));            // prints the banner
DRIVER
BANNER_OUT="$(
  cd "$FAKE_PKG"
  HOME="$TA_TMPDIR/home" perl -e 'alarm 25; exec @ARGV' node driver.js < /dev/null 2>&1 || true
)"
if printf '%s' "$BANNER_OUT" | grep -q "startup=2.88.5" && printf '%s' "$BANNER_OUT" | grep -q "v2.92.0"; then
  ta_pass "(2) the banner after a self-update reports the installed version (2.92.0), not the startup one (2.88.5)"
elif printf '%s' "$BANNER_OUT" | grep -q "v2.88.5"; then
  ta_fail "(2) the banner reported the startup version (v2.88.5) after 2.92.0 was installed"
else
  ta_fail "(2) no banner version found in the update flow"
fi

# ── 3. no user-facing line interpolates the startup snapshot ────────────────
# `pkg.version` is the value captured when the process started. Anywhere it
# reaches the user after a self-update, it is the version that was replaced.
STALE=0
for f in bin/setup.js bin/bigpowers.js; do
  grep -nE 'pkg\.version' "$f" | grep -vE '^\s*[0-9]+:\s*//' >/dev/null 2>&1 && STALE=1
done
if [ "$STALE" -eq 0 ]; then
  ta_pass "(3) neither bin/setup.js nor bin/bigpowers.js prints a cached pkg.version"
else
  ta_fail "(3) a CLI entry point still interpolates pkg.version (stale after self-update)"
fi

echo "$TA_PASS passed, $TA_FAIL failed"
[[ "$TA_FAIL" -eq 0 ]]
