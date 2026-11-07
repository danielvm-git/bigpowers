#!/usr/bin/env bash
# story: e83s01
# stamp-skill-counts.sh — stamp the live skill count into package.json's
# description and the scripts/mcp-server.js header. Called by sync-skills.sh.
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
n=$(find "$REPO_ROOT/skills" -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')
perl -0pi -e 's/("description": ")(?:\d+ )?agent skills/${1}'"$n"' agent skills/' "$REPO_ROOT/package.json"
perl -pi -e 's/exposes \d+ skills/exposes '"$n"' skills/ if $. <= 3' "$REPO_ROOT/scripts/mcp-server.js"
echo "stamp-skill-counts: $n skills"
