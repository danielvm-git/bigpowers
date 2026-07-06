# story: e37s06
# scripts/generate-context-bundle.sh — AGENTS.md single source + all derivatives

## Acceptance Criteria

test -f scripts/generate-context-bundle.sh && bash scripts/generate-context-bundle.sh --dry-run 2>&1 | grep -qi 'AGENTS.md' && echo OK

