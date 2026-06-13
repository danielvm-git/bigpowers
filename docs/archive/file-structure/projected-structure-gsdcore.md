# Projected gsd-core Project Directory Structure

Below is the projected filesystem folder and file structure for a hypothetical project built using **gsd-core**.

```text
my-project/
├── .github/                       # CI/CD workflows and action configurations
├── .planning/                     # Core planning context and state management
│   ├── PROJECT.md                 # Strategic vision, developer principles, constraints
│   ├── ROADMAP.md                 # Sequenced roadmap with status tags ([done], [in-progress])
│   ├── STATE.md                   # Live session state: decisions, active phase, active git branch
│   ├── REQUIREMENTS.md            # Feature mapping (Must Haves, Nice-to-Haves, Out of Scope)
│   ├── MILESTONES.md              # Milestones listing and release target tracking
│   ├── BACKLOG.md                 # Flat list of unresolved issues or future efforts
│   ├── LEARNINGS.md               # Cumulative developer heuristics and gotchas
│   ├── THREADS.md                 # Tracked asynchronous conversations or investigations
│   ├── RETROSPECTIVE.md           # Retrospective learnings post-release
│   ├── config.json                # GSD configuration file (sub_repos, commit_docs)
│   ├── CLAUDE.md                  # Local overrides for agent reference
│   │
│   ├── milestones/                # Archive directory for completed milestones
│   │   └── v1.0.0-MILESTONE-AUDIT.md
│   │
│   ├── workstreams/               # Live workstream configuration and scope maps
│   │   └── feature-auth.json
│   │
│   ├── research/                  # High-density tech stack and dependency investigations
│   │   └── STACK.md
│   │
│   └── phases/                    # Isolated execution phase specs and checkpoints
│       └── phase-1.md
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
