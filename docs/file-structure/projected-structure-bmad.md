# Projected BMAD Method Project Directory Structure

Below is the projected filesystem folder and file structure for a hypothetical project built using the **BMAD Method (BMM)**.

```text
my-project/
├── .github/                       # CI/CD workflows and configurations
├── .claude/                       # Claude Code configurations and custom commands
├── .cursor/                       # Cursor rules and configurations
│
├── _bmad-output/                  # Main output folder for BMad artifacts
│   └── project-context.md         # Constitution/rules detailing tech stack and developer preferences
│
├── docs/                          # Optional project documentation (often contains BMM logs/reports)
│   ├── brainstorming-report.md    # Phase 1: Guided brainstorming session results
│   ├── product-brief.md           # Phase 1: Strategic vision brief
│   ├── prfaq-core-service.md      # Phase 1: PRFAQ backwards-working concept validator
│   │
│   ├── prd.md                     # Phase 2: Coached Product Requirements Document (PRD)
│   ├── addendum.md                # Phase 2: Tracked scope shifts and addenda
│   ├── decision-log.md            # Phase 2: Log of design/product decisions made
│   ├── validation-report.md       # Phase 2: Structured critique of the PRD
│   ├── ux-spec.md                 # Phase 2: Strategic UX layout specifications
│   │
│   ├── architecture.md            # Phase 3: Technical solutions and ADRs
│   ├── sprint-status.yaml         # Phase 4: Tracked stories and active sprint state
│   ├── story-[slug].md            # Phase 4: Detailed tasks and context for a developer story
│   └── spec-quick-dev.md          # Quick Flow: Scoped specs for small/isolated tasks
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
