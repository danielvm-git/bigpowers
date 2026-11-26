#!/usr/bin/env bash
# story: BUG-2026-11-06-install-uninstall-noop
# Regression guard for issue #219: uninstall must match an entry by its
# resolved path (following symlink chains) against BOTH the current repo and a
# node_modules/bigpowers install root, and the manifest must round-trip. Before
# this, install.sh --uninstall matched only the literal link text against
# $REPO_ROOT/, so a checkout uninstall of an npm-installed tree removed 0 of N.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIB="$REPO_ROOT/scripts/lib/install-manifest.sh"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

pass=0
fail=0
ok()  { printf 'ok   %s\n' "$1"; pass=$((pass + 1)); }
bad() { printf 'FAIL %s\n' "$1"; fail=$((fail + 1)); }

# Build a fake repo and a fake npm install, both containing skills/audit-code.
FAKE_REPO="$WORK/repo"
FAKE_NPM="$WORK/node_modules/bigpowers"
mkdir -p "$FAKE_REPO/skills/audit-code" "$FAKE_NPM/skills/audit-code"
printf -- '---\nname: audit-code\ndescription: x\n---\nbody\n' > "$FAKE_REPO/skills/audit-code/SKILL.md"
printf -- '---\nname: audit-code\ndescription: x\n---\nbody\n' > "$FAKE_NPM/skills/audit-code/SKILL.md"

export BP_MANIFEST_DIR="$WORK/.bigpowers"
# bp <cmd...> — run one command string inside the sourced lib environment.
bp() {
  REPO_ROOT="$FAKE_REPO" DRY_RUN=false BP_MANIFEST_DIR="$BP_MANIFEST_DIR" bash -c "
    set -euo pipefail
    source '$LIB'
    $1
  "
}

# T1 — a direct link into $REPO_ROOT is managed and resolves.
ln -s "$FAKE_REPO/skills/audit-code" "$WORK/link-repo"
OUT="$(bp "bp_target_managed '$WORK/link-repo'")"
if [ "$OUT" = "$FAKE_REPO/skills/audit-code" ]; then
  ok "T1 link into REPO_ROOT resolves to its real path"
else
  bad "T1 got '$OUT'"
fi

# T2 — a link into node_modules/bigpowers is managed (npm install).
ln -s "$FAKE_NPM/skills/audit-code" "$WORK/link-npm"
OUT="$(bp "bp_target_managed '$WORK/link-npm'")"
if [ "$OUT" = "$FAKE_NPM/skills/audit-code" ]; then
  ok "T2 link into node_modules/bigpowers resolves as managed"
else
  bad "T2 got '$OUT'"
fi

# T3 — a chained hop (.agents -> .claude -> node_modules) resolves through the
# chain and is still recognized.
mkdir -p "$WORK/.claude/skills" "$WORK/.agents"
ln -s "$FAKE_NPM/skills/audit-code" "$WORK/.claude/skills/audit-code"
ln -s "$WORK/.claude/skills/audit-code" "$WORK/.agents/skills-audit-code"
OUT="$(bp "bp_target_managed '$WORK/.agents/skills-audit-code'")"
if [ "$OUT" = "$FAKE_NPM/skills/audit-code" ]; then
  ok "T3 chained symlink resolves through the hop and is managed"
else
  bad "T3 got '$OUT'"
fi

# T4 — a foreign symlink is left alone.
mkdir -p "$WORK/elsewhere/thing"
ln -s "$WORK/elsewhere/thing" "$WORK/link-foreign"
OUT="$(bp "bp_target_managed '$WORK/link-foreign'")"
if [ -z "$OUT" ]; then
  ok "T4 foreign link is not managed"
else
  bad "T4 got '$OUT'"
fi

# T5 — manifest round-trip: replay cleanup removes a copy-mode dir (contains
# SKILL.md) and leaves a foreign dir alone.
mkdir -p "$WORK/copy-skill" "$WORK/foreign-dir"
printf -- '---\nname: x\ndescription: x\n---\nbody\n' > "$WORK/copy-skill/SKILL.md"
printf 'not a skill\n' > "$WORK/foreign-dir/readme.txt"
bp "bp_manifest_add '$WORK/copy-skill' '$FAKE_REPO/skills/audit-code'"
bp "bp_manifest_add '$WORK/foreign-dir' '$FAKE_REPO/skills/audit-code'"
COUNT="$(bp "bp_manifest_dsts | grep -c . || true")"
if [ "$COUNT" -eq 2 ]; then
  ok "T5 manifest records both destinations"
else
  bad "T5 manifest recorded $COUNT entries, expected 2"
fi
bp "bp_manifest_replay_cleanup" >/dev/null
if [ ! -e "$WORK/copy-skill" ] && [ -e "$WORK/foreign-dir" ]; then
  ok "T5 replay removes the skill copy, leaves the foreign dir"
else
  bad "T5 replay removed the wrong things"
fi

printf '\n%s\n' "$( [ "$fail" -eq 0 ] && echo "PASS: $pass/$((pass + fail)) install-manifest checks" || echo "FAIL: $fail of $((pass + fail)) checks" )"
[ "$fail" -eq 0 ] || exit 1
