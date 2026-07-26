#!/usr/bin/env bash
# story: e37s05
# generate-workflow-diagrams.sh — render docs/WORKFLOWS.md from specs/workflows/*.yaml.
#
# specs/assets/bigpowers-workflow.svg was a find-and-replace of a BMad Method
# chart with bigpowers skill names dropped into BMad's slots. Nothing regenerated
# it, so it drifted: it routed PLAN through define-success (archived), placed
# seed-conventions in PHASE 4 when it is the greenfield entry point, omitted the
# whole planning spine, build-epic and the entire verify/release arc, and used
# "Sprints" — a word absent from every bigpowers doctrine file.
#
# A diagram nothing regenerates is a diagram that lies. This derives the chains
# from the same YAML the /slash commands read, so the source cannot drift from
# the picture without the picture changing.
#
# Usage: bash scripts/generate-workflow-diagrams.sh [--check]
#   --check  fail if the committed output is stale (for CI)

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/python-env.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/skill-common.sh"
resolve_repo_root
cd "$REPO_ROOT"

OUT="docs/WORKFLOWS.md"
CHECK=0
[[ "${1:-}" == "--check" ]] && CHECK=1

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

$PYTHON - "$TMP" <<'PY'
import sys, glob, os
import yaml

out = open(sys.argv[1], "w", encoding="utf-8")
w = out.write

w("# bigpowers Workflows\n\n")
w("<!-- story: e37s05 -->\n\n")
w("> **Generated** by `scripts/generate-workflow-diagrams.sh` from\n")
w("> `specs/workflows/*.yaml`. Do not hand-edit — change the YAML and re-run.\n")
w("> CI enforces freshness via `--check`.\n\n")
w("Each recipe below is a composed chain of skills, invocable as a slash command.\n\n")

recipes = []
for path in sorted(glob.glob("specs/workflows/*.yaml")):
    d = yaml.safe_load(open(path, encoding="utf-8")) or {}
    if d.get("name") and d.get("skills"):
        recipes.append(d)

w("## Recipes\n\n")
w("| Command | Chain | Purpose |\n|---|---|---|\n")
for r in recipes:
    chain = " → ".join("`%s`" % s for s in r["skills"])
    desc = (r.get("description") or "").replace("|", "\\|").strip()
    w("| `%s` | %s | %s |\n" % (r.get("command", "/" + r["name"]), chain, desc))
w("\n")

w("## Chains\n\n```mermaid\nflowchart LR\n")
for i, r in enumerate(recipes):
    w("  subgraph %s[\"%s\"]\n" % ("w%d" % i, r.get("command", r["name"])))
    prev = None
    for j, s in enumerate(r["skills"]):
        node = "n%d_%d" % (i, j)
        w("    %s[\"%s\"]\n" % (node, s))
        if prev:
            w("    %s --> %s\n" % (prev, node))
        prev = node
    w("  end\n")
w("```\n\n")

# Skill reuse across recipes is the interesting structural fact: it shows which
# skills are load-bearing across the catalog.
counts = {}
for r in recipes:
    for s in r["skills"]:
        counts[s] = counts.get(s, 0) + 1
shared = sorted([(v, k) for k, v in counts.items() if v > 1], reverse=True)
if shared:
    w("## Skills shared across recipes\n\n")
    w("| Skill | Recipes |\n|---|---|\n")
    for v, k in shared:
        w("| `%s` | %d |\n" % (k, v))
    w("\n")

w("_%d recipes, %d distinct skills._\n" % (len(recipes), len(counts)))
out.close()
PY

if [[ "$CHECK" -eq 1 ]]; then
  if [[ ! -f "$OUT" ]] || ! diff -q "$TMP" "$OUT" >/dev/null 2>&1; then
    echo "generate-workflow-diagrams: $OUT is stale — run bash scripts/generate-workflow-diagrams.sh" >&2
    exit 1
  fi
  echo "generate-workflow-diagrams: $OUT is current"
  exit 0
fi

mkdir -p "$(dirname "$OUT")"
cp "$TMP" "$OUT"
echo "generate-workflow-diagrams: wrote $OUT"
