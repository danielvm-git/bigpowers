#!/usr/bin/env bash
# story: BUG-2026-11-06-validator-yaml-strictness
# story: BUG-2026-11-06-pi-frontmatter-html-comments
# Regression guard for issue #207 / #173: the validator must reject exactly the
# frontmatter forms pi 1.5.0 rejects (HTML comment inside the block, duplicate
# top-level key) and must accept the form that parses (`#` comments).
#
# Runs the real validator against throw-away skill trees so the check cannot
# drift from the host parser it stands in for. No network, no fixtures on disk.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VALIDATOR="$REPO_ROOT/scripts/validate-skill-yaml.py"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

pass=0
fail=0

ok()   { printf 'ok   %s\n' "$1"; pass=$((pass + 1)); }
bad()  { printf 'FAIL %s\n' "$1"; fail=$((fail + 1)); }

# run_in <dir> — invoke the validator with <dir> as cwd, capture status + output.
run_in() {
  local dir="$1"
  set +e
  OUT="$(cd "$dir" && python3 "$VALIDATOR" 2>&1)"
  STATUS=$?
  set -e
}

new_tree() {
  local root="$1" name="$2"
  rm -rf "$root"
  mkdir -p "$root/skills/$name" "$root/.pi/skills"
  printf '%s\n' "$root"
}

# T1 — HTML comment inside the frontmatter block (the #173 defect)
tree="$(new_tree "$WORK/t1" demo)"
cat > "$tree/skills/demo/SKILL.md" <<'EOF'
---
<!-- story: e01s01 -->
<!-- story: e01s02 -->
name: demo
description: fixture
---
body
EOF
run_in "$tree"
if [ "$STATUS" -ne 0 ] && grep -q 'R4' <<<"$OUT"; then
  ok "T1 rejects HTML comment inside frontmatter (R4)"
else
  bad "T1 expected failure with R4, got status=$STATUS out=$(head -3 <<<"$OUT")"
fi

# T2 — duplicate top-level key, invisible to PyYAML's last-wins parsing
tree="$(new_tree "$WORK/t2" demo)"
cat > "$tree/skills/demo/SKILL.md" <<'EOF'
---
name: demo
name: demo-again
description: fixture
---
body
EOF
run_in "$tree"
if [ "$STATUS" -ne 0 ] && grep -q 'R5' <<<"$OUT"; then
  ok "T2 rejects duplicate frontmatter key (R5)"
else
  bad "T2 expected failure with R5, got status=$STATUS"
fi

# T3 — YAML comment form inside the block is legal and must pass
tree="$(new_tree "$WORK/t3" demo)"
cat > "$tree/skills/demo/SKILL.md" <<'EOF'
---
# story: e01s01
# story: e01s02
name: demo
model: haiku
effort: standard
description: fixture
---
<!-- story: e01s03 -->
body
EOF
run_in "$tree"
if [ "$STATUS" -eq 0 ]; then
  ok "T3 accepts '#' story comments inside frontmatter"
else
  bad "T3 expected pass, got status=$STATUS out=$(head -5 <<<"$OUT")"
fi

# T4 — an HTML comment below the closing delimiter is body content, not frontmatter
tree="$(new_tree "$WORK/t4" demo)"
cat > "$tree/skills/demo/SKILL.md" <<'EOF'
---
name: demo
description: fixture
---

<!-- story: e01s01 -->
body
EOF
run_in "$tree"
if [ "$STATUS" -eq 0 ]; then
  ok "T4 accepts HTML story tag in the body"
else
  bad "T4 expected pass, got status=$STATUS"
fi

# T5 — the repository itself must be clean under the strict rules
run_in "$REPO_ROOT"
if [ "$STATUS" -eq 0 ]; then
  ok "T5 repository SKILL.md frontmatter passes strict rules"
else
  bad "T5 repository fails: $(grep -E 'R4|R5|FAIL:' <<<"$OUT" | head -5)"
fi

printf '\n%s\n' "$( [ "$fail" -eq 0 ] && echo "PASS: $pass/$((pass + fail)) frontmatter strictness checks" || echo "FAIL: $fail of $((pass + fail)) checks" )"
[ "$fail" -eq 0 ] || exit 1
