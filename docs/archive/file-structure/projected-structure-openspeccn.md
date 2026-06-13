# Projected openspec-cn Project Directory Structure

Below is the projected filesystem folder and file structure for a hypothetical project built using **openspec-cn** (OpenSpec Chinese Localization).

```text
my-project/
├── .github/                       # CI/CD workflows and action configurations
│
├── openspec/                      # Core OpenSpec change management directory
│   ├── config.yaml                # Chinese/English localization and schema rules
│   ├── changes/                   # Active and historical changesets (变更管理)
│   │   ├── add-dark-mode/         # Focused directory for an active proposal/feature
│   │   │   ├── proposal.md        # 变更提案 (Problem statement, why, and description)
│   │   │   ├── specs/             # 变更规格 (Scenarios and detailed requirements)
│   │   │   │   └── theme-toggle.md
│   │   │   ├── design.md          # 详细设计 (Technical design, file plan, and API specs)
│   │   │   └── tasks.md           # 任务列表 (Implementation checklist and boundaries)
│   │   │
│   │   └── archive/               # Historical change archives (归档变更)
│   │       ├── 2026-05-01-oauth/
│   │       └── 2026-06-10-landing/
│   │
│   └── schemas/                   # Custom workflow and validation schemas (验证模式)
│
├── src/                           # Application Source Code
│   ├── components/
│   ├── lib/
│   └── index.ts
│
├── tests/                         # Automated tests (verifiers)
│   └── integration/
│
├── CLAUDE.md                      # Agent fast-reference instructions (commands, conventions)
└── package.json                   # Project manifest (includes versioning and dev dependencies)
```
