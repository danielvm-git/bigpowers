# Plan: v1.4.0 (Workflow & Git Safety Hook)

## Context
Convert `guard-git` into a functional hook (PreToolUse) that enforces Conventional Commits and blocks destructive operations (like direct pushes to `main`) automatically across all supported harnesses (Claude Code, Antigravity, Cursor, Gemini CLI).

## Steps

1. **Implement `hooks/pre-tool-use.sh`** → verify: `ls hooks/pre-tool-use.sh`
2. **Update `guard-git/SKILL.md` to reference the functional hook** → verify: `grep "enforce Conventional Commits" guard-git/SKILL.md`
3. **Update `guard-git/REFERENCE.md` with configuration snippets** → verify: `grep "pre-tool-use.sh" guard-git/REFERENCE.md`
4. **Update `specs/RELEASE_PLAN.md` status** → verify: `grep "v1.4.0" specs/RELEASE_PLAN.md | grep "✅"`

## Out of scope
- Implementation of `session-state` (v1.3.0) or `HARD-GATE` blocks (v1.5.0).
