---
bug_id: BUG-2026-08-05-ste-glob-wordcount
status: fixed
severity: medium
scope: validate-agentic-ste
title: "validate-agentic-ste.sh counts markdown bold (**) as every file in cwd — false FAIL on valid prose"
discovered: e81s01 (docs story) — AGENTS.md template Token Economy section failed --strict on markdown-bold list items
created: 2026-08-05
---

## Summary

**Actual:** `ste_count_words` in `scripts/validate-agentic-ste.sh` does
`local words=($1)` — an unquoted array assignment. Bash word-splits `$1`,
then **pathname-expands (globs) every word**. A standalone `**` word (a
markdown bold opener, e.g. `1. **Check deps first.** DO …`) expands to every
non-hidden file in the current directory, inflating the word count and
tripping the 20-word sentence gate with a false FAIL. Reproduced on the
AGENTS.md template Token Economy lines: reported "sentence has 49 words"
for an actual 18-word sentence (49 = 18 + files in repo root).

**Expected:** `ste_count_words` counts whitespace-separated words only.
Glob characters (`*`) must never expand to filenames.

## Reproduce

```bash
mkdir -p /tmp/ste-glob && cd /tmp/ste-glob && touch a.txt b.txt c.txt
bash -c 'w=(**); echo "words=${#w[@]}"'   # → "words=3" (globs a.txt b.txt c.txt)
cd /Users/danielvm/Developer/bigpowers
printf '1. **Check deps first.** DO inspect what your current dependencies already do before writing your own code.\n' > /tmp/ste-glob/test.md
bash scripts/validate-agentic-ste.sh --strict /tmp/ste-glob/test.md
# → FAIL: sentence has N words (N = real words + files in cwd)
```

## Root Cause Analysis

`ste_count_words`:
```bash
ste_count_words() {
  # shellcheck disable=SC2207
  local words=($1)
  echo "${#words[@]}"
}
```
The unquoted `($1)` performs word splitting AND pathname expansion per word.
A bare `**` matches all files (bash treats `**` as `*` without `globstar`).
The existing baseline template only ever contained `**` glued inside words
(`**Workflow Mandate:**`), where the glob pattern either matched nothing and
stayed literal, or required a literal prefix (`Mandate:` + `*`) that no file
satisfies — so the bug lay dormant. A markdown-bold **list item** (`1. **…**`)
places `**` at a word boundary for the first time and detonates it.

**Scope of blast radius:** any `SKILL.md`, `CLAUDE.md`, `CONVENTIONS.md`, or
`AGENTS.md` prose line whose sentence starts with a `**` at a word boundary.
skill bodies use `**` labels liberally, but almost always mid-word; list-item
bold openers are the trigger. Affected paths audited in e81s01: template
Token Economy list; none of the other 200+ scanned files currently trip it.

## Fix Plan

1. `ste_count_words`: disable pathname expansion around the array assignment
   (`set -f` … `set +f`). The function is only ever called inside a command
   substitution (`wc="$(ste_count_words "$trimmed")"`), so the `set` change
   stays confined to the subshell.
2. Add a regression fixture `good-bold.md` (markdown-bold list item, <20 real
   words) to `--self-test`; the fixture must PASS post-fix and FAIL pre-fix.
3. Verify: `bash scripts/validate-agentic-ste.sh --self-test` green, and
   `--strict` on `docs/templates/AGENTS.md` green.

## Verification

```bash
bash scripts/validate-agentic-ste.sh --self-test
bash scripts/validate-agentic-ste.sh --strict docs/templates/AGENTS.md
```
