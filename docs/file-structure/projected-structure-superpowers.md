# Projected Superpowers Project Directory Structure

Below is the projected filesystem folder and file structure for a hypothetical project built using **Superpowers**.

```text
my-project/
├── .github/                       # CI/CD workflows and action configurations
├── .claude-plugin/                # Claude-specific skill configurations
├── .codex-plugin/                 # Codex compatibility hooks
├── .cursor-plugin/                # Cursor rule configurations
│
├── docs/
│   └── superpowers/               # Core Superpowers specifications and execution records
│       ├── specs/                 # Scoped design specs with historical date stamps
│       │   └── 2026-06-11-auth-system-design.md
│       └── plans/                 # Detailed technical implementation plans
│           └── 2026-06-11-auth-system.md
│
├── src/                           # Application Source Code
│   ├── components/
│   ├── lib/
│   └── index.ts
│
├── tests/                         # Automated tests (verifiers)
│   └── integration/
│
├── gemini-extension.json          # Gemini-specific extension settings
├── CLAUDE.md                      # Agent fast-reference instructions (commands, conventions)
├── GEMINI.md                      # Gemini CLI-specific instructions
└── package.json                   # Project manifest (includes versioning and dev dependencies)
```
