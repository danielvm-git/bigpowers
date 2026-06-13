#!/usr/bin/env bash
# Doctrine drift guard — fails CI if any tracked invariants regress.
# Run after sync-skills.sh and before merging any branch.
# Extended by each epic: add new assertions below the relevant section header.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

ERRORS=0

fail() {
  echo "FAIL: $*" >&2
  ERRORS=$((ERRORS + 1))
}

pass() {
  echo "ok  : $*"
}

# ── Epic 1: Dead skill names in model-profiles.md ─────────────────────────────
# Scope: model-profiles.md is the canonical skill-roster reference.
# Other docs may legitimately reference npm tools or conceptual names.
echo "--- [Epic 1] dead skill names in docs/references/model-profiles.md ---"
DEAD=()
while IFS= read -r name; do
  if [[ ! -d "$name" ]]; then
    DEAD+=("$name")
  fi
done < <(grep -oE '`[a-z][a-z-]+`' docs/references/model-profiles.md \
  | tr -d '`' \
  | grep -E '^[a-z]+-[a-z]+(-[a-z]+)?$' \
  | sort -u)

if [[ ${#DEAD[@]} -eq 0 ]]; then
  pass "all skill names in model-profiles.md resolve to real directories"
else
  for name in "${DEAD[@]}"; do
    fail "dead skill name in model-profiles.md: '$name' has no matching directory"
  done
fi

# ── Epic 1: Legacy MD artifact names in docs/ (excluding historical file-structure/) ──
# docs/file-structure/ is intentional historical comparison material (Epic 6 archives it).
echo "--- [Epic 1] legacy MD artifact names in docs/ ---"
LEGACY_HITS=$(grep -rE "PLAN\.md|STATE\.md|PROJECT\.md|CONTEXT\.md|SUMMARY\.md|VERIFICATION\.md|RESEARCH\.md|RELEASE-PLAN\.md" \
  docs/ 2>/dev/null \
  | grep -v "docs/file-structure/" \
  | grep -v "docs/report-gsd-integration.md" \
  | grep -v "specs/archive" \
  | wc -l | tr -d ' ') || true
if [[ "$LEGACY_HITS" -eq 0 ]]; then
  pass "no legacy MD artifact names in docs/ (outside file-structure/)"
else
  fail "legacy MD artifact names found in docs/ ($LEGACY_HITS occurrences)"
  grep -rE "PLAN\.md|STATE\.md|PROJECT\.md|CONTEXT\.md|SUMMARY\.md|VERIFICATION\.md|RESEARCH\.md|RELEASE-PLAN\.md" \
    docs/ 2>/dev/null \
    | grep -v "docs/file-structure/" \
    | grep -v "docs/report-gsd-integration.md" \
    | grep -v "specs/archive" | head -20 >&2
fi

# ── Epic 1: Skill count consistency ───────────────────────────────────────────
echo "--- [Epic 1] skill count consistency ---"
LIVE_COUNT=$(ls -d */SKILL.md 2>/dev/null | wc -l | tr -d ' ')
STALE_COUNT_HITS=$(grep -rE "expect [0-9]+" docs/ 2>/dev/null \
  | grep -v "expect $LIVE_COUNT" | wc -l | tr -d ' ') || true
if [[ "$STALE_COUNT_HITS" -eq 0 ]]; then
  pass "skill count annotations match live count ($LIVE_COUNT)"
else
  fail "stale skill count annotation in docs/ (live=$LIVE_COUNT, $STALE_COUNT_HITS mismatches)"
  grep -rE "expect [0-9]+" docs/ 2>/dev/null | grep -v "expect $LIVE_COUNT" >&2
fi

# ── Epic 2: Non-canonical specs/ subpaths ─────────────────────────────────────
# Exclusions: specs/archive, specs/epics/archive, CHANGELOG.md (auto-gen),
#   specs/verifications/reports/ (generated reports), PLAN-evolve-structure.md
#   (migration plan that documents the before→after paths as historical record).
echo "--- [Epic 2] canonical specs/ subpaths ---"
LEGACY_SPECS=$(grep -rE "specs/(requirements|plans|audit)\b" \
  --include="*.md" --include="*.sh" --include="*.yaml" --include="*.yml" --include="*.json" . \
  2>/dev/null \
  | grep -v "specs/archive\|specs/epics/archive\|\.git\|node_modules\|\.gemini\|\.cursor" \
  | grep -v "CHANGELOG\.md\|specs/verifications/reports/\|PLAN-evolve-structure\.md" \
  | wc -l | tr -d ' ') || true
if [[ "$LEGACY_SPECS" -eq 0 ]]; then
  pass "no legacy specs/ subpaths (requirements/, plans/, audit/)"
else
  fail "legacy specs/ subpaths found ($LEGACY_SPECS occurrences)"
  grep -rE "specs/(requirements|plans|audit)\b" \
    --include="*.md" --include="*.sh" --include="*.yaml" --include="*.yml" --include="*.json" . \
    2>/dev/null \
    | grep -v "specs/archive\|specs/epics/archive\|\.git\|node_modules\|\.gemini\|\.cursor" \
    | grep -v "CHANGELOG\.md\|specs/verifications/reports/\|PLAN-evolve-structure\.md" \
    | head -10 >&2
fi

# Epic 3 BCP slop guard added here after "Build Commit Points" purge is complete.
# Epic 4 SKILL.md size cap assertion added here after check-skill-size.sh exists.

# ── Summary ────────────────────────────────────────────────────────────────────
echo "---"
if [[ "$ERRORS" -eq 0 ]]; then
  echo "validate-doctrine: ALL checks passed"
  exit 0
else
  echo "validate-doctrine: $ERRORS check(s) FAILED" >&2
  exit 1
fi
