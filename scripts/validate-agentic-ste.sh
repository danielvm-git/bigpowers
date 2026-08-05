#!/usr/bin/env bash
# story: e79s02
# validate-agentic-ste.sh — mechanical Agentic STE checks for instructional prose.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

MAX_WORDS=20
BANNED_RE='\b(should|might|could|may|consider|try|generally|typically)\b'

STRICT=false
AUDIT=false
SELF_TEST=false
TARGETS=()

ste_usage() {
  echo "Usage: bash scripts/validate-agentic-ste.sh [--self-test|--strict|--audit] [file|dir ...]"
  echo "  (no args)     Run built-in fixture self-test"
  echo "  --strict      Exit 1 on violations (craft-skill gate)"
  echo "  --audit       WARN-only catalog scan (stocktake)"
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --strict) STRICT=true; shift ;;
    --audit) AUDIT=true; shift ;;
    --self-test) SELF_TEST=true; shift ;;
    -h|--help) ste_usage ;;
    --) shift; TARGETS+=("$@"); break ;;
    -*) echo "Unknown flag: $1" >&2; ste_usage ;;
    *) TARGETS+=("$1"); shift ;;
  esac
done

VIOLATIONS=0
WARNINGS=0

ste_report_fail() {
  echo "FAIL: $1" >&2
  VIOLATIONS=$((VIOLATIONS + 1))
}

ste_report_warn() {
  echo "WARN: $1" >&2
  WARNINGS=$((WARNINGS + 1))
}

ste_strip_frontmatter() {
  awk '
    BEGIN { n=0; emit=0 }
    /^---$/ { n++; if (n==1) next; if (n==2) { emit=1; next } }
    emit { print }
  ' "$1"
}

ste_extract_prose() {
  local file="$1"
  local body
  if [[ "$(basename "$file")" == "SKILL.md" ]]; then
    body="$(ste_strip_frontmatter "$file")"
  else
    body="$(cat "$file")"
  fi
  printf '%s\n' "$body" | awk '
    BEGIN { in_code=0 }
    /^```/ { in_code = !in_code; next }
    in_code { next }
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*\|/ { next }
    /^[[:space:]]*<!--/ { next }
    /^[[:space:]]*$/ { next }
    /^# story:/ { next }
    /^<!-- story:/ { next }
    { print }
  '
}

ste_count_words() {
  # shellcheck disable=SC2207
  local words
  # BUG-2026-08-05-ste-glob-wordcount: ($1) globs each word — a bare ** (markdown
  # bold opener) expands to every file in cwd and inflates the count. Disable
  # pathname expansion; safe here because this function only runs inside $( ).
  set -f
  words=($1)
  set +f
  echo "${#words[@]}"
}

ste_audit_line() {
  local file="$1"
  local line_no="$2"
  local line="$3"
  local label="${file}:${line_no}"

  if echo "$line" | grep -qiE "$BANNED_RE"; then
    local word
    word="$(echo "$line" | grep -oiE "$BANNED_RE" | head -1)"
    if $STRICT; then
      ste_report_fail "$label — banned hedge modal '$word'"
    else
      ste_report_warn "$label — banned hedge modal '$word'"
    fi
  fi

  local sentence
  while IFS= read -r sentence; do
    [[ -z "$sentence" ]] && continue
    local trimmed
    trimmed="$(echo "$sentence" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    [[ -z "$trimmed" ]] && continue
    local wc
    wc="$(ste_count_words "$trimmed")"
    if (( wc > MAX_WORDS )); then
      if $STRICT; then
        ste_report_fail "$label — sentence has ${wc} words (max ${MAX_WORDS}): ${trimmed:0:60}..."
      else
        ste_report_warn "$label — sentence has ${wc} words (max ${MAX_WORDS}): ${trimmed:0:60}..."
      fi
    fi
  done < <(echo "$line" | sed 's/[.!?]/&\n/g')
}

ste_audit_file() {
  local file="$1"
  [[ -f "$file" ]] || { ste_report_fail "not found: $file"; return; }

  local prose line_no=0
  prose="$(ste_extract_prose "$file")"
  while IFS= read -r line; do
    line_no=$((line_no + 1))
    ste_audit_line "$file" "$line_no" "$line"
  done <<< "$prose"
}

ste_collect_files() {
  local path="$1"
  if [[ -f "$path" ]]; then
    echo "$path"
  elif [[ -d "$path" ]]; then
    find "$path" -type f \( -name 'SKILL.md' -o -name 'CLAUDE.md' -o -name 'CONVENTIONS.md' -o -name 'AGENTS.md' \) | sort
  fi
}

ste_run_self_test() {
  local tmp
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN

  cat > "$tmp/good-skill.md" <<'EOF'
---
name: fixture-good
description: Test fixture for Agentic STE validator. Use when running self-test.
---
# Fixture Good
> **HARD GATE** — Run Preflight before forward work.
Run tests after every change.
Write specs to specs/ at project root.
EOF

  cat > "$tmp/bad-hedge.md" <<'EOF'
---
name: fixture-bad
description: Bad fixture.
---
You should consider running tests generally.
EOF

  cat > "$tmp/bad-long.md" <<'EOF'
---
name: fixture-long
description: Long sentence fixture.
---
Run the full local green stack including compliance verification gates sync skills trace stories and catalog drift check before any forward implementation work on this repository.
EOF

  cat > "$tmp/good-bold.md" <<'EOF'
---
name: fixture-bold
description: Bold markdown list fixture (BUG-2026-08-05-ste-glob-wordcount).
---
1. **Check dependencies first.** DO inspect what your current dependencies already do before writing your own code.
EOF

  local saved_strict=$STRICT saved_audit=$AUDIT
  STRICT=true
  AUDIT=false
  VIOLATIONS=0

  ste_audit_file "$tmp/good-skill.md"
  if (( VIOLATIONS > 0 )); then
    echo "SELF-TEST FAIL: good fixture should pass" >&2
    return 1
  fi

  VIOLATIONS=0
  ste_audit_file "$tmp/good-bold.md"
  if (( VIOLATIONS > 0 )); then
    echo "SELF-TEST FAIL: bold-markdown fixture should pass (glob word-count bug, BUG-2026-08-05)" >&2
    return 1
  fi

  VIOLATIONS=0
  ste_audit_file "$tmp/bad-hedge.md"
  if (( VIOLATIONS == 0 )); then
    echo "SELF-TEST FAIL: hedge fixture should fail" >&2
    return 1
  fi

  VIOLATIONS=0
  ste_audit_file "$tmp/bad-long.md"
  if (( VIOLATIONS == 0 )); then
    echo "SELF-TEST FAIL: long-sentence fixture should fail" >&2
    return 1
  fi

  STRICT=$saved_strict
  AUDIT=$saved_audit
  VIOLATIONS=0
  echo "validate-agentic-ste: self-test PASS"
  return 0
}

if $SELF_TEST || [[ ${#TARGETS[@]} -eq 0 ]]; then
  ste_run_self_test
  exit $?
fi

if $AUDIT; then
  STRICT=false
fi

for target in "${TARGETS[@]}"; do
  while IFS= read -r f; do
    [[ -n "$f" ]] && ste_audit_file "$f"
  done < <(ste_collect_files "$target")
done

if (( VIOLATIONS > 0 )); then
  echo "validate-agentic-ste: $VIOLATIONS violation(s)" >&2
  exit 1
fi

if $AUDIT; then
  echo "validate-agentic-ste: audit complete ($WARNINGS warning(s))"
else
  echo "validate-agentic-ste: PASS"
fi
