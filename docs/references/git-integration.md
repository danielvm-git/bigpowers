# Git Integration: Commit Strategy, Worktrees, Hooks

**Purpose:** Document git workflows and conventions for Bigpowers orchestration.

---

## Commit Message Format (Conventional Commits)

**Format:** `<type>(<scope>): <subject>`

### Types
- `feat` — New feature
- `fix` — Bug fix
- `refactor` — Code restructuring (no behavior change)
- `test` — Test-only changes
- `docs` — Documentation only
- `chore` — Dependencies, build, config
- `perf` — Performance optimization

### Scope
- Optional, but recommended
- Skill name, module, or affected area
- Example: `feat(plan-work): add slopcheck integration`

### Subject
- Imperative mood ("add" not "adds" or "added")
- No period at end
- <50 characters
- Lowercase

### Body
- Optional, but recommended for non-trivial changes
- Explain WHY, not WHAT
- Wrap at 72 characters
- Separate from subject with blank line

### Example

```
feat(v2.0.0): orchestrate skill + context isolation

- Add orchestrate skill enforcing 6-phase core loop with gates
- Implement context isolation (fresh 200K per skill spawn)
- Add slopcheck security gate before package recommendations
- Update 5 core skills with explicit files_to_read sections
- Generate 11 reference library documents

This enables production-grade orchestration with hard gates,
preventing scope creep and ensuring consistent quality.

Fixes #456 (GitHub issue)

Co-Authored-By: Claude Haiku 4.5 <noreply@anthropic.com>
```

---

## Branching Strategy (Trunk-Based Development)

### Main Branch Rules
- `main` is always production-ready
- All work branches merge into main
- All commits trigger CI/CD
- Tags on main are releases (semantic versioning)

### Feature Branches
```bash
# Create feature branch (short-lived, max 1 week)
git checkout -b feat/orchestrate-skill

# Commit frequently
git commit -m "feat(orchestrate): add 6-phase core loop"
git commit -m "feat(orchestrate): add gate enforcement"
git commit -m "feat(orchestrate): add state tracking"

# Create PR for code review
gh pr create --title "feat(orchestrate): add 6-phase core loop" \
             --body "..."

# After review & approval, squash or rebase onto main
git checkout main
git rebase feat/orchestrate-skill
git push origin main

# Delete feature branch
git branch -d feat/orchestrate-skill
```

### Release Branches (Semver-Based)
```bash
# Create release branch when ready to ship
git checkout -b release/v2.0.0 main

# Bump version in version files
# Add release notes
# Commit: chore(release): v2.0.0

git commit -m "chore(release): v2.0.0"
git tag -a v2.0.0 -m "Release v2.0.0"

# Merge back to main
git checkout main
git merge release/v2.0.0
git push origin main --tags

# Delete release branch
git branch -d release/v2.0.0
```

---

## Worktree Usage (Parallel Work)

**Use Case:** Work on v2.0.0 features while keeping main stable

```bash
# Create worktree for feature development
git worktree add -b feat/orchestrate .claude/worktrees/orchestrate

# Now you have two independent working directories:
#   ~/Developer/skills (main)
#   ~/.claude/worktrees/orchestrate (feat/orchestrate)

# Work in feature worktree
cd ~/.claude/worktrees/orchestrate
# ... make changes ...
git commit -m "feat(orchestrate): ..."

# Meanwhile, main remains untouched for hotfixes/releases
cd ~/Developer/skills
git checkout -b fix/security-issue
# ... fix hotfix ...
git commit -m "fix(security): ..."
git push origin main

# Back to feature worktree
cd ~/.claude/worktrees/orchestrate
git rebase origin/main  # Bring in hotfix

# Clean up worktree after feature complete
git worktree remove .claude/worktrees/orchestrate
```

---

## Pre-Commit Hooks

**Purpose:** Prevent common mistakes before they get committed

```bash
# .git/hooks/pre-commit (make executable: chmod +x)
#!/bin/bash

set -e

# Check 1: No hardcoded secrets
if git diff --cached | grep -i "password\|api.key\|secret"; then
  echo "❌ ERROR: Hardcoded secret detected. Remove before committing."
  exit 1
fi

# Check 2: No console.log in production code
if git diff --cached -- src/ | grep "console.log"; then
  echo "❌ ERROR: console.log in production code. Remove before committing."
  exit 1
fi

# Check 3: Run linter
npx eslint src/ || (
  echo "❌ ERROR: ESLint failed. Fix issues before committing."
  exit 1
)

# Check 4: Run tests
npm test || (
  echo "❌ ERROR: Tests failed. Fix before committing."
  exit 1
)

echo "✅ All pre-commit checks passed"
```

---

## Merge Conflicts (Resolution Strategy)

**Prevention:** Rebase frequently to avoid long-lived feature branches

```bash
# Bring main into feature branch
git rebase origin/main

# If conflicts, resolve them:
git status  # Shows conflicting files
# Edit files to resolve
git add <resolved-files>
git rebase --continue

# Once conflict-free, force-push feature branch
git push -f origin feat/orchestrate
```

**During Merge:** Never auto-merge; always review

```bash
# Before merging to main:
git checkout main
git merge --no-ff feat/orchestrate  # Create explicit merge commit

# Or rebase-and-merge (preferred for clean history):
git rebase feat/orchestrate main
```

---

## Tagging & Versioning

**Tag Convention:** `vMAJOR.MINOR.PATCH` (semantic versioning)

```bash
# Tag for release
git tag -a v2.0.0 -m "Release v2.0.0: Orchestration + Reference Library"

# Tag for checkpoints (internal)
git tag -a v2.0.0-rc1 -m "v2.0.0 Release Candidate 1"

# Push tags
git push origin --tags

# List tags
git tag -l
```

**Semantic Versioning Rules:**
- MAJOR: Breaking changes (v1.x → v2.0.0)
- MINOR: New features (v2.0.0 → v2.1.0)
- PATCH: Bug fixes (v2.0.0 → v2.0.1)

---

## Workflow Integration in Bigpowers

### Step 1: Create Feature Branch (Plan Phase)
```bash
git checkout -b feat/v2.0-orchestration
# Start work on v2.0.0
```

### Step 2: Commit Frequently (Build Phase)
```bash
git commit -m "feat(orchestrate): add 6-phase core loop"
git commit -m "feat(orchestrate): add gate enforcement"
git commit -m "feat(orchestrate): add state tracking"
# Each commit is a verifiable checkpoint
```

### Step 3: Create PR (Verify Phase)
```bash
gh pr create --title "feat(v2.0.0): orchestration + reference library" \
             --body "..."
# Triggers CI/CD (compliance audits, tests)
```

### Step 4: Code Review (Verify Phase)
```bash
# Reviewer runs request-review
# Quality score must be ≥94%
# Compliance audit must pass
```

### Step 5: Merge & Tag (Release Phase)
```bash
git rebase origin/main
git checkout main
git merge feat/v2.0-orchestration
git tag -a v2.0.0 -m "Release v2.0.0"
git push origin main --tags
```

---

## Common Git Commands

```bash
# Check status
git status

# View recent commits
git log --oneline -10

# See what changed
git diff

# See what changed in staged files
git diff --cached

# Undo last commit (keep changes)
git reset --soft HEAD~1

# Undo last commit (discard changes)
git reset --hard HEAD~1

# Stash changes (for temporary work switching)
git stash
# ... switch to another branch ...
git stash pop

# Create and switch to branch
git checkout -b feat/new-feature

# Switch back to main
git checkout main

# Bring in commits from another branch
git rebase origin/main

# Push with tracking
git push -u origin feat/new-feature
```

---

## See Also

- CONVENTIONS.md — More git rules (no `git push --force`, etc.)
- orchestration.md — When does git happen? (Release phase)
- execute-plan (SKILL.md) — Creates commits during Build phase
- release-branch (SKILL.md) — Tags and pushes during Release phase
- verify: git log --oneline | head -10
