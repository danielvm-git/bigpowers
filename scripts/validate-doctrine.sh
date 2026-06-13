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

# ── Epic 1: Legacy MD artifact names in live docs/ (docs/archive/ exempt) ─────
# docs/archive/ holds historical/exploratory material (Epic 6); legacy names there are expected.
echo "--- [Epic 1] legacy MD artifact names in docs/ ---"
LEGACY_HITS=$(grep -rE "PLAN\.md|STATE\.md|PROJECT\.md|CONTEXT\.md|SUMMARY\.md|VERIFICATION\.md|RESEARCH\.md|RELEASE-PLAN\.md" \
  docs/ 2>/dev/null \
  | grep -v "docs/archive/" \
  | grep -v "specs/archive" \
  | wc -l | tr -d ' ') || true
if [[ "$LEGACY_HITS" -eq 0 ]]; then
  pass "no legacy MD artifact names in live docs/ (docs/archive/ exempt)"
else
  fail "legacy MD artifact names found in docs/ ($LEGACY_HITS occurrences)"
  grep -rE "PLAN\.md|STATE\.md|PROJECT\.md|CONTEXT\.md|SUMMARY\.md|VERIFICATION\.md|RESEARCH\.md|RELEASE-PLAN\.md" \
    docs/ 2>/dev/null \
    | grep -v "docs/archive/" \
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
  | grep -v "specs/archive\|specs/epics/archive\|docs/archive/\|\.git\|node_modules\|\.gemini\|\.cursor" \
  | grep -v "CHANGELOG\.md\|specs/verifications/reports/\|PLAN-evolve-structure\.md" \
  | wc -l | tr -d ' ') || true
if [[ "$LEGACY_SPECS" -eq 0 ]]; then
  pass "no legacy specs/ subpaths (requirements/, plans/, audit/)"
else
  fail "legacy specs/ subpaths found ($LEGACY_SPECS occurrences)"
  grep -rE "specs/(requirements|plans|audit)\b" \
    --include="*.md" --include="*.sh" --include="*.yaml" --include="*.yml" --include="*.json" . \
    2>/dev/null \
    | grep -v "specs/archive\|specs/epics/archive\|docs/archive/\|\.git\|node_modules\|\.gemini\|\.cursor" \
    | grep -v "CHANGELOG\.md\|specs/verifications/reports/\|PLAN-evolve-structure\.md" \
    | head -10 >&2
fi

# ── Epic 3: BCP slop guard ────────────────────────────────────────────────────
echo "--- [Epic 3] BCP terminology ---"
BCP_SLOP=$(grep -ri "build commit point" . 2>/dev/null \
  | grep -v "specs/archive\|\.git\|node_modules\|\.gemini\|\.cursor\|validate-doctrine\.sh" \
  | wc -l | tr -d ' ') || true
if [[ "$BCP_SLOP" -eq 0 ]]; then
  pass "no 'Build Commit Point' slop — BCP = Business Complexity Points"
else
  fail "'Build Commit Point' found ($BCP_SLOP hits) — canonical term is 'Business Complexity Points'; see docs/references/bcp.md"
  grep -ri "build commit point" . 2>/dev/null \
    | grep -v "specs/archive\|\.git\|node_modules\|\.gemini\|\.cursor\|validate-doctrine\.sh" | head -5 >&2
fi

# ── Epic 4: SKILL.md size cap ─────────────────────────────────────────────────
echo "--- [Epic 4] SKILL.md size cap ---"
if bash "$REPO_ROOT/scripts/check-skill-size.sh" >/dev/null 2>&1; then
  pass "all SKILL.md files within tiered size cap (150 critical-path / 120 utility)"
else
  fail "a SKILL.md exceeds its size cap — run: bash scripts/check-skill-size.sh"
  bash "$REPO_ROOT/scripts/check-skill-size.sh" 2>&1 | grep "^FAIL:" >&2 || true
fi

# ── Epic 5: Critical-path skills document a handoff target ─────────────────────
echo "--- [Epic 5] critical-path handoff targets ---"
CRITICAL_HANDOFF=(survey-context plan-work develop-tdd verify-work audit-code release-branch kickoff-branch commit-message)
MISSING_HANDOFF=()
for s in "${CRITICAL_HANDOFF[@]}"; do
  if [[ -f "$s/SKILL.md" ]] && ! grep -qiE "handoff|next_skill|next:" "$s/SKILL.md"; then
    MISSING_HANDOFF+=("$s")
  fi
done
if [[ ${#MISSING_HANDOFF[@]} -eq 0 ]]; then
  pass "all critical-path skills document a handoff target"
else
  for s in "${MISSING_HANDOFF[@]}"; do
    fail "critical-path skill '$s' has no documented handoff/next_skill"
  done
fi

# ── Summary ────────────────────────────────────────────────────────────────────
echo "---"
if [[ "$ERRORS" -eq 0 ]]; then
  echo "validate-doctrine: ALL checks passed"
  exit 0
else
  echo "validate-doctrine: $ERRORS check(s) FAILED" >&2
  exit 1
fi
