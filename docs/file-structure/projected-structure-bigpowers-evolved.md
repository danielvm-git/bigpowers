# Projected Evolved bigpowers Project Directory Structure

Below is the evolved filesystem folder and file structure for a hypothetical project built using the `bigpowers` methodology, incorporating the optimized specs architecture, centralized verifications, epic archiving, and independent markdown story files.

```text
my-project/
├── .github/                       # CI/CD workflows and action configurations
├── .gemini/                       # Extension configs for Gemini CLI (auto-generated)
├── .cursor/                       # Extension configs for Cursor rules (auto-generated)
│   └── rules/                     # Auto-generated .md rules from SKILL.md files
│
├── specs/                         # MANDATORY: All planning and spec output lives here
├── state.yaml                 # Active session state, current epic/bug, git details
├── state.yaml.lock            # Write-lock file to prevent concurrency state conflicts
├── release-plan.yaml          # Release goals, target semver, prioritized epics
├── execution-status.yaml      # Flat key-value store mapping stories (e.g. e01s01) to states
├── planning-status.yaml       # Discover-phase checklist (optional status tracking)
│   │
│   ├── product/                   # Product and domain definitions (replaces requirements/)
│   │   ├── SCOPE_LATEST.yaml      # Detailed scope and functional requirements
│   │   ├── VISION_LATEST.yaml     # North star goals and initiative context
│   │   ├── GLOSSARY_LATEST.yaml   # Domain glossary/vocabulary (Ubiquitous Language)
│   │   └── snapshots/             # Frozen baselines per release version
│   │       └── release-1.0.0/     # Copied release-plan, scope, vision on baseline freeze
│   │
│   ├── epics/                     # Epic and Story specifications (All epics use capsule directories)
│   │   ├── archive/               # Archived/completed epic directories
│   │   │   └── v1.0.0-auth/       # Archived epic folder capsule
│   │   │
│   │   ├── e01-auth-system/       # Epic capsule directory
│   │   │   ├── epic.yaml          # Epic metadata (id, title, wsjf, total BCPs, stories list)
│   │   │   ├── adr/               # Epic-specific Architectural Decision Records
│   │   │   │   └── 0002-jwt-auth.md # Local ADR contained inside epic capsule
│   │   │   ├── e01s01-login.md    # Story spec matching countable-story-format.md (BCPS: N)
│   │   │   ├── e01s01-tasks.yaml  # Step-by-step implementation tasks & verify commands
│   │   │   ├── e01s02-jwt.md      # Story spec matching countable-story-format.md (BCPS: N)
│   │   │   └── e01s02-tasks.yaml  # Step-by-step implementation tasks & verify commands
│   │   │
│   │   └── e02-user-profile/      # Epic capsule directory
│   │       ├── epic.yaml          # Epic metadata (id, title, wsjf, total BCPs, stories list)
│   │       ├── e02s01-profile.md  # Story spec matching countable-story-format.md (BCPS: N)
│   │       ├── e02s01-tasks.yaml  # Step-by-step implementation tasks & verify commands
│   │       ├── e02s02-avatar.md   # Story spec matching countable-story-format.md (BCPS: N)
│   │       └── e02s02-tasks.yaml  # Step-by-step implementation tasks & verify commands
│   │
│   ├── tech-architecture/         # Tech architecture plans (replaces plans/)
│   │   ├── tech-stack.md          # Core architecture, frameworks, database layouts
│   │   ├── security.md            # Security threat model, standards, and compliance gates
│   │   ├── test.md                # Test strategies, automated suites, coverage targets
│   │   ├── design.md              # Global UI/UX rules, theme specifications, layouts
│   │   ├── REFACTOR_LATEST.md     # Structural refactoring guidelines
│   │   └── IMPACT_LATEST.md       # Pre-calculated impact of changes
│   │
│   ├── adr/                       # Global Architectural Decision Records (system-wide decisions)
│   │   └── 0001-use-postgresql.md
│   │
│   ├── verifications/             # Centralized UAT logs & metrics validation
│   │   ├── e01s01-verify.yaml     # Story verification outcome evidence
│   │   └── e02s01-eval-report.md  # LLM/Code evaluation grader results
│   │
│   └── bugs/                      # Bug investigation records
│       ├── registry.yaml          # Auto-generated bug index
│       └── BUG-001-login-fails.md # Investigation, root-cause, fix verification plan (countable format)
│
├── scripts/                       # Shell scripts executing core bigpowers automation
│   ├── sync-skills.sh             # Syncs SKILL.md sources into .cursor and .gemini rules
│   ├── land-branch.sh             # Safely squash-merges and lands a feature branch
│   ├── validate-specs-yaml.sh     # Lints and validates specs/ YAML schemas
│   └── bp-yaml-set.sh             # Helper tool to programmatically update state YAMLs
│
├── profiles/                      # Git and integration profiles
│   └── solo-git.md                # Solo-developer specific flow instructions
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
├── GEMINI.md                      # Gemini-specific agent constraints and token directives
├── CONVENTIONS.md                 # Strict code style rules, testing mandates, and git guidelines
└── package.json                   # Project manifest (includes versioning and dev dependencies)
```

---

## Evolved Architecture Details

### 1. Countable Stories as Independent Markdown Files
Instead of defining story verification tasks inside monolithic YAML files, stories are fully written as standalone `.md` files matching [countable-story-format.md](file:///Users/danielvm/Developer/bigpowers/countable-story-format.md).
*   **Location**: Every epic is organized in its own capsule directory under `specs/epics/eXX-slug/`. All story Markdown spec files live inside their parent epic's directory (`specs/epics/eXX-slug/eXXsYY-slug.md`).
*   **Sizing & Maturity**: The story Markdown file governs the story maturity, sizing (Fibonacci), actors, and Gherkin acceptance criteria.

### 2. Decoupled Story Task Files (YAML)
To enforce the Single Responsibility Principle (SRP) and keep specification separate from execution mechanics:
*   **Location**: Next to the story specification `.md` file in the capsule directory (e.g. `specs/epics/eXX-slug/eXXsYY-tasks.yaml`).
*   **Format**: Structured YAML schema detailing the implementation plan generated by `plan-work`.
*   **Template**:
    ```yaml
    story_id: e01s01
    title: "Self-serve password reset"
    status: todo # todo, in_progress, completed
    bcps: 3
    tasks:
      - id: 1
        description: "Add User model validation tests"
        verify: "npm test -- user-validation.test.ts"
        status: completed
      - id: 2
        description: "Implement uniqueness validation"
        verify: "npm test"
        status: todo
    ```
*   **Sizing & BCP Mapping**: The parent `epic.yaml` file acts as the epic manifest, declaring the epic's metadata (WSJF, title) and dynamically listing/summing the story BCP counts read from the story task YAMLs.

### 3. Product Directory (`specs/product/`)
Replaces the generic `requirements/` folder, clearly establishing the product boundary. It contains business objectives, scope boundaries, and baseline snapshots.

### 4. Tech-Architecture Directory (`specs/tech-architecture/`)
Replaces the `plans/` folder. It consolidates architectural guidelines into standard files:
*   [tech-stack.md](file:///Users/danielvm/Developer/bigpowers/specs/tech-architecture/tech-stack.md): Core tech choices, configurations, databases, and dependencies.
*   [security.md](file:///Users/danielvm/Developer/bigpowers/specs/tech-architecture/security.md): Threat modeling, secret detection patterns, OWASP compliance, and security policies.
*   [test.md](file:///Users/danielvm/Developer/bigpowers/specs/tech-architecture/test.md): Automation strategies, verification run guidelines, and quality thresholds.
*   [design.md](file:///Users/danielvm/Developer/bigpowers/specs/tech-architecture/design.md): Global typography, styling rules, glassmorphism directives, and UX flow standards.

### 5. Archive and Verification Ledgers
*   [archive/](file:///Users/danielvm/Developer/bigpowers/specs/epics/archive/): When an epic is merged and complete, its entire capsule folder (including stories, tasks, and epic-specific ADRs) is moved here to optimize context window tokens, avoiding orphaned records in global folders.
*   [verifications/](file:///Users/danielvm/Developer/bigpowers/specs/verifications/): Holds logs, run sheets, and grader evidence verifying stories before delivery.

### 6. Session Integrity & Concurrency Controls
*   **State Write-Locks**: The presence of `specs/state.yaml.lock` provides a file-based lock mechanism. Before modifying `specs/state.yaml` or `specs/execution-status.yaml`, executing agents must acquire this write-lock, preventing concurrency write conflicts and race conditions when parallel subagents run.

