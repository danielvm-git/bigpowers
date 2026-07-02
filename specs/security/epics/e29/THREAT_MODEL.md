# Threat Model — e29: Repository Layout — Skill Sources Under skills/

**Epic:** e29 — Repository Layout — Skill Sources Under skills/
**Date:** 2026-07-02
**Risk Level:** LOW
**Reviewer:** build-epic Step 0 (automated)

---

## Surface Area

### What moves
| Component | Change |
|---|---|
| ~72 verb-noun skill dirs (`*/SKILL.md`) | `git mv` from repo root → `skills/` |
| 8 consumer Bash scripts | `SKILLS_ROOT` variable replaces bare `$REPO_ROOT/*/` globs |
| `.github/workflows/sync-skills.yml` | Path trigger updated for `skills/**` |
| `e28` capsule verify globs | Updated to `skills/` layout |
| Root docs (`COMMIT-MESSAGE.md`, `RELEASE.md`) | Moved to `docs/` |

### What does NOT move (hard constraint)
- Generated targets: `.cursor/rules`, `.gemini/extensions/bigpowers/`, `.pi/`
- Tool-read root files: `CLAUDE.md`, `GEMINI.md`, `opencode.json`, `index.js`
- `guard-git/` (referenced by `install.sh` hardcoded path — must stay)

---

## Vulnerability Categories

### 1. Path Traversal / Directory Confusion
**Likelihood: LOW** | **Impact: LOW**

The `SKILLS_ROOT` variable is set from a controlled `[[ -d "$REPO_ROOT/skills" ]]` check and
never constructed from user input. No external data enters the path calculation.
No traversal risk.

### 2. Supply-Chain / Install Integrity
**Likelihood: MEDIUM** | **Impact: HIGH** → mitigated to LOW

**Risk:** `npm postinstall` runs `sync-skills.sh` + `install.sh` concurrently at install time.
If a published npm version resolves `SKILLS_ROOT` to the new `skills/` path but
the actual skill directories have not been moved yet (split release), `postinstall`
would install zero skills silently.

**Mitigation (required by epic scope):**
- e29s01 (location-agnostic scripts) ships before e29s02 (directory move)
- Both must land in the same npm release — the epic's hard constraint
- CI gate in e29s02 step 4: `bash scripts/sync-skills.sh && git diff --quiet` proves no drift

### 3. Artifact Drift / Silent Skill Loss
**Likelihood: MEDIUM** | **Impact: MEDIUM**

**Risk:** A script missed during the `SKILLS_ROOT` refactor continues to glob
`$REPO_ROOT/*/SKILL.md` after the move, finding zero files and silently no-oping.

**Mitigation:**
- Task 2 in e29s01 uses `grep -L 'SKILLS_ROOT'` across all 5 secondary scripts
- Task 4 runs `sync-skills.sh && git diff --quiet` proving zero artifact drift at root (canary)
- e29s02 verify re-runs the full chain and compares skill count to `skills-lock.json`

### 4. Git History Loss
**Likelihood: LOW** | **Impact: LOW**

`git mv` preserves rename history. Epic AC requires `git log --follow` to show history.
Risk: if `cp` + `rm` is used instead of `git mv`. Implementation MUST use `git mv`.

### 5. Broken install.sh Hardcoded Paths
**Likelihood: LOW** | **Impact: MEDIUM**

`install.sh` hardcodes `$REPO_ROOT/guard-git/scripts/block-dangerous-git.sh` (line 80).
`guard-git/` is NOT moved in this epic. Verify this holds — no `guard-git/` move in scope.

### 6. CI Workflow Path Trigger Mismatch
**Likelihood: LOW** | **Impact: LOW**

After the move, `.github/workflows/sync-skills.yml` must trigger on `skills/**`.
Failure would mean PRs touching skill files do not run CI.
Addressed in e29s02 AC and verify.

---

## Risk Score

| Category | Likelihood | Impact | Score |
|---|---|---|---|
| Path Traversal | Low | Low | 1 |
| Supply-Chain (install) | Low (mitigated) | High | 3 |
| Artifact Drift | Low (mitigated) | Medium | 2 |
| Git History Loss | Low | Low | 1 |
| install.sh hardcoded paths | Low | Medium | 2 |
| CI path trigger | Low | Low | 1 |
| **Overall** | | | **2 / 10** |

**Risk Level: LOW** — No gate required. Proceed to Step 1 (survey-context).

---

## Mitigation Guidance

1. **Always use `git mv`** — never `cp` + `rm` when relocating skill directories.
2. **Canary run** — Task 4 of e29s01 must pass (zero artifact drift with skills still at root) before any directory move in e29s02.
3. **Atomic release** — e29s01 and e29s02 must land in the same npm semver minor bump.
4. **SKILLS_ROOT grep gate** — `grep -L 'SKILLS_ROOT'` on all 5 secondary scripts must return 0 files before merging e29s01.
5. **Count verification** — After e29s02, `find skills -maxdepth 2 -name SKILL.md | wc -l` must equal `skills-lock.json` entry count.
6. **guard-git exclusion** — Confirm `guard-git/` is not in the `git mv` target list.
