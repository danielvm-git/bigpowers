---
name: setup-environment
description: Pre-install dependencies and configure tools before development work begins. Use at session start on a fresh clone, before kickoff-branch, or when user says setup environment or install deps.
model: haiku
---

# Setup Environment
> **HARD GATE** — **HARD GATE** — Environment setup must be idempotent and reproducible. If setup fails, provide clear error messages and remediation steps. Do NOT assume prior state.


Idempotent prep so BUILD phase commands succeed on first run.

## Checklist

1. Read `CLAUDE.md` / `CONVENTIONS.md` for required runtimes and commands.
2. Verify runtime versions (`node -v`, `swift --version`, etc.).
3. Install dependencies (`npm ci`, `bundle install`, etc.) — prefer lockfile installs.
4. Copy `.env.example` → `.env` if documented; never commit secrets.
5. Run smoke: lint + one fast test or `--version` on key tools.
6. Record versions in `specs/state.yaml` under Environment.

## Verify

→ verify: commands from CLAUDE.md Test/Lint rows exit 0
