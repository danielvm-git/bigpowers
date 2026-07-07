---
name: kickoff-branch
model: haiku
effort: standard
description: Create a git worktree and feature branch, then verify a clean test baseline before any code is written. Use when starting a new feature or task, when user wants to work in isolation from main, or mentions "start a branch" or "new worktree".
---

# story: e51s03
# story: e20s03


# Kickoff Branch

> **HARD GATE** — Direct work on `main` or `master` is PROHIBITED. Every task MUST start with this skill to create a feature branch or worktree.
>
> **HARD GATE** — Do NOT proceed with development until **Preflight** passes on the default branch. Red Preflight blocks branch creation and all forward work — invoke `quick-fix` or `fix-bug` per CONVENTIONS § Discovered Defects.

Create an isolated working environment before touching any code. **Preflight must be green** before you write feature code — solo-default owns the whole tree, not just the current task diff.

## Process

### 1. Confirm task name

Ask if not already known: "What's the name of this feature or task?" Use it as the branch name slug (kebab-case, max 40 chars).

### 2. Anchor on default branch (main or master)

> **HARD GATE** — Kickoff MUST start from an updated, clean default branch in the **primary** repository root (not a linked worktree).

```bash
# Detect default branch
DEFAULT=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo main)

git checkout "$DEFAULT"
git pull --ff-only origin "$DEFAULT"   # skip if no remote
git status                             # working tree MUST be clean
git log --oneline -5
```

**Spec-only pre-kickoff** — before enforcing the clean-tree gate, check whether dirty files are spec artifacts:

```bash
DIRTY=$(git status --porcelain | awk '{print $2}')
NON_SPEC=$(echo "$DIRTY" | grep -v '^specs/' || true)

if [ -z "$DIRTY" ]; then
  : # clean — proceed
elif [ -z "$NON_SPEC" ]; then
  # spec-only dirty tree — offer auto-commit
  echo "Dirty spec artifacts: $(echo $DIRTY | tr '\n' ' ')"
  read -p "Commit spec artifacts before kickoff? [Y/n]: " CONFIRM
  CONFIRM=${CONFIRM:-Y}
  if [[ "$CONFIRM" =~ ^[Yy] ]]; then
    git add specs/
    git commit -m "chore(state): checkpoint before kickoff"
  fi
else
  echo "Dirty tree: $NON_SPEC (not a spec artifact). Stash or commit before proceeding."
  exit 1
fi
```

- **Spec artifacts** match `specs/` — state.yaml, epics YAMLs, execution-status.yaml, etc.
- **Non-spec dirty files** (src/, scripts/, SKILL.md, …) still enforce the full clean-tree gate.
- If not on `$DEFAULT` after checkout, stop and fix before continuing.

### 3. Pre-flight & Conflict Resolution

Before creating the worktree, verify the target environment is clean:

```bash
# 1. Check for existing directory
ls -d ../<task-slug> 2>/dev/null

# 2. Check for existing branch
git branch --list <task-slug>

# 3. Check for "ghost" worktrees (metadata exists but directory is gone)
git worktree list | grep "<task-slug>"
```

**Handling Conflicts:**
- **Directory exists:** If `../<task-slug>` already exists, ask the user if they want to use it or delete it.
- **Branch exists:** If the branch exists but no worktree is attached, ask to use the existing branch (`git worktree add ../<task-slug> <task-slug>`) or delete it.
- **Ghost worktree:** If `git worktree list` shows the path but the directory is missing, run `git worktree prune` to clear the stale metadata.

### 4. Create worktree + branch

```bash
# From the main repo root (not another worktree)
git worktree add ../<task-slug> -b <task-slug>
cd ../<task-slug>
```

If the user prefers a branch without a worktree:
```bash
git checkout -b <task-slug>
```

### 4. Verify clean baseline

> **HARD GATE (e39s02):** Acquire story lock in `specs/agent-locks.yaml` before running tests.

```bash
LOCK="specs/agent-locks.yaml"; STORY="<story-id>"
if [ -f "$LOCK" ]; then
  python3 -c "
import yaml,sys,datetime
d=yaml.safe_load(open('$LOCK'))or{'locks':[]}
for l in d['locks']:
  if l['story_id']=='$STORY':print(f'LOCKED by {l[\"locked_by\"]} at {l[\"locked_at\"]}');sys.exit(1)
d['locks'].append({'story_id':'$STORY','locked_by':'agent: build-epic','locked_at':datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ'),'files_touched':[]})
yaml.dump(d,open('$LOCK','w'),default_flow_style=False)
print(f'LOCK ACQUIRED: $STORY')
"
fi
```

If locked: abort. If unlocked: entry added, proceed.

Run **Preflight** (from `CLAUDE.md` Commands table, or `BP_PREFLIGHT` from `bash scripts/bp-read-agents.sh`) and confirm green before writing any code:

```bash
# Preflight — project's full local verification stack
# bigpowers example:
npm run compliance && bash scripts/run-verification-gates.sh

# Or project-specific from CLAUDE.md / AGENTS.md
```

- [ ] Preflight passes (all chained gates green)
- [ ] No type errors (`npm run typecheck` or equivalent, if not in Preflight)
- [ ] No lint errors (`npm run lint` or equivalent, if not in Preflight)

If Preflight is red, **stop** — route to `quick-fix` or `fix-bug`. Fix before kickoff continues.

### 5. Confirm readiness

Report: `✓ Preflight green` + branch + worktree. Suggest next: `develop-tdd` or `execute-plan`.

## Handoff

Gate: READY -> next: develop-tdd
Writes: state.yaml handoff.next_skill = develop-tdd
