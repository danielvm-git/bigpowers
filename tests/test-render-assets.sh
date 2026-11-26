#!/usr/bin/env bash
# story: BUG-2026-11-06-dist-render-missing-assets
# Guard for issue #218: a rendered skill payload must contain the bundled files
# the skill instructs the model to read or run. The pi package channel ships
# .pi/skills, and the Antigravity channel ships .agents/skills; before this,
# both carried SKILL.md only — 38 skills pointed at files that were not there.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HELPER="$REPO_ROOT/scripts/lib/adapter-assets.sh"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

pass=0
fail=0
ok() { printf 'ok   %s\n' "$1"; pass=$((pass + 1)); }
bad() { printf 'FAIL %s\n' "$1"; fail=$((fail + 1)); }

# Fixture repo with one skill that has a markdown sibling and a script dir.
FIX="$WORK/repo"
mkdir -p "$FIX/skills/demo/scripts" "$FIX/.pi/skills"
printf -- '---\nname: demo\ndescription: fixture\n---\nbody\n' > "$FIX/skills/demo/SKILL.md"
printf '# reference\n' > "$FIX/skills/demo/REFERENCE.md"
printf '#!/usr/bin/env bash\necho hi\n' > "$FIX/skills/demo/scripts/tool.sh"
printf 'hidden\n' > "$FIX/skills/demo/.secret"

run_helper() {
  BP_REPO_ROOT="$FIX" SKILLS_ROOT="$FIX/skills" bash -c "
    set -euo pipefail
    source '$HELPER'
    $1
  "
}

# T1 — mirror copies markdown, nested directories and dotfiles, but not SKILL.md
if run_helper 'mirror_skill_assets "$BP_REPO_ROOT/.pi/skills/demo" demo' >/dev/null 2>&1; then
  if [[ -f "$FIX/.pi/skills/demo/REFERENCE.md" \
     && -f "$FIX/.pi/skills/demo/scripts/tool.sh" \
     && -f "$FIX/.pi/skills/demo/.secret" \
     && ! -f "$FIX/.pi/skills/demo/SKILL.md" ]]; then
    ok "T1 mirrors .md, nested dirs and dotfiles; skips SKILL.md"
  else
    bad "T1 mirror produced the wrong set: $(find "$FIX/.pi/skills/demo" -type f | sort | tr '\n' ' ')"
  fi
else
  bad "T1 mirror_skill_assets exited non-zero"
fi

# T2 — assertion passes on a complete payload
if run_helper 'assert_skill_assets "$BP_REPO_ROOT/.pi/skills"' >/dev/null 2>&1; then
  ok "T2 assertion passes when every sibling is present"
else
  bad "T2 assertion failed on a complete payload"
fi

# T3 — assertion fails, and names the file, when an asset is missing
rm -rf "$FIX/.pi/skills/demo/scripts"
set +e
OUT="$(run_helper 'assert_skill_assets "$BP_REPO_ROOT/.pi/skills"' 2>&1)"
STATUS=$?
set -e
if [ "$STATUS" -ne 0 ] && grep -q 'missing asset: .*scripts' <<<"$OUT"; then
  ok "T3 assertion fails and names the missing asset"
else
  bad "T3 expected failure naming scripts/, got status=$STATUS out=$(head -3 <<<"$OUT")"
fi

# T4 — the live .pi/skills payload satisfies the assertion (post-sync truth)
if [ -d "$REPO_ROOT/.pi/skills" ]; then
  if BP_REPO_ROOT="$REPO_ROOT" bash -c "source '$HELPER'; assert_skill_assets '$REPO_ROOT/.pi/skills'" >/dev/null 2>&1; then
    ok "T4 repository .pi/skills carries every bundled asset"
  else
    bad "T4 repository .pi/skills is missing assets — run scripts/sync-skills.sh"
  fi
else
  bad "T4 .pi/skills missing"
fi

printf '\n%s\n' "$( [ "$fail" -eq 0 ] && echo "PASS: $pass/$((pass + fail)) render-asset checks" || echo "FAIL: $fail of $((pass + fail)) checks" )"
[ "$fail" -eq 0 ] || exit 1
