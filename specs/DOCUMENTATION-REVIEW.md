# Documentation Review Audit — 2026-05-19

## Summary

This audit evaluates the consistency between the **Bigpowers 2.0 Reference Library** (v2.0.0) and the **Skill Implementation** (v1.18.0). While the reference library provides excellent high-level guidance, several "drift" issues were identified where skills do not yet reflect the documented standards or refer to non-existent artifacts.

---

## 1. High-Priority: Broken Skill References

The following documents refer to `publish-release (SKILL.md)`, which does not exist in the codebase. The intended skill is likely `release-branch`.

| Document | Current Reference | Suggested Fix |
| :--- | :--- | :--- |
| `orchestrate/SKILL.md` | `publish-release` | `release-branch` |
| `docs/references/git-integration.md` | `publish-release` | `release-branch` |
| `docs/references/model-profiles.md` | `publish-release` | `release-branch` |

---

## 2. High-Priority: Implementation Gaps (Slopcheck)

`docs/references/security-threats.md` describes a supply-chain defense integration using `slopcheck` that is currently missing from the actual skill definitions.

- **`plan-work/SKILL.md`**: Missing the documented requirement to run `slopcheck` for all recommended packages and tag them with `[OK]`, `[SUS]`, or `[SLOP]`.
- **`audit-code/SKILL.md`**: Missing the defense checklist item regarding `slopcheck` verification.
- **Command Status**: `slopcheck` is not an installed command in the current environment.

**Recommendation:** Decide if `slopcheck` should be implemented as a new skill/script or if the documentation should be marked as "planned/future" for v2.1.0.

---

## 3. Medium-Priority: Naming Convention Inconsistency

`CONVENTIONS.md` mandates **verb-noun** naming (two words, kebab-case) for all skill directories. Several skills deviate from this:

- `orchestrate` (Single verb)
- `terse-mode` (Adjective-noun)
- `visual-dashboard` (Adjective-noun)

**Recommendation:** Either rename these skills (e.g., `orchestrate-project`, `enable-terse-mode`, `view-dashboard`) or update `CONVENTIONS.md` to allow exceptions for meta-skills and specialized utilities.

---

## 4. Low-Priority: Script Hygiene

`scripts/sync-skills.sh` contains duplicated variable assignments for `REPO_ROOT` and `CURSOR_RULES` at the top of the file.

```bash
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CURSOR_RULES="$REPO_ROOT/.cursor/rules"
GEMINI_COMMANDS="$REPO_ROOT/.gemini/extensions/bigpowers/commands"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CURSOR_RULES="$REPO_ROOT/.cursor/rules"
```

---

## 5. BMAD Compliance Check

| Principle | Status | Notes |
| :--- | :--- | :--- |
| **B**old | ✅ Pass | Documents use strong assertions and hard gates. |
| **M**inimal | ✅ Pass | Skill files and reference docs are focused and high-density. |
| **A** actionble | ⚠️ Partial | References to `slopcheck` and `publish-release` are not actionable as the targets don't exist. |
| **D**urable | ✅ Pass | Nested indexing and hierarchy (Global -> Project -> Sub-directory) is well-implemented. |

---

## Next Steps

1. **Fix Broken References**: Rename `publish-release` to `release-branch` across all docs.
2. **Address Slopcheck Drift**: Either implement a minimal `slopcheck` stub/script or update `security-threats.md` to reflect it as a future feature.
3. **Clean up `sync-skills.sh`**: Remove duplicated lines.
4. **Normalize Naming**: Renaming `orchestrate` to `orchestrate-project` would bring it into full compliance.
