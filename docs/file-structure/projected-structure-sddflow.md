# Projected SDD_Flow Project Directory Structure

Below is the projected filesystem folder and file structure for a hypothetical project built using **SDD_Flow**.

```text
my-project/
├── .github/                       # CI/CD workflows and action configurations
│
├── docs/                          # Core SDD documentation folders
│   ├── 1.1_initial_hypothesis.md  # Step 1.1: Vision, target audience, assumptions
│   ├── 1.3_market_research_report.md # Step 1.3: Competitive analysis and market trends
│   ├── 1.5_draft_customer_interview_insights.md # Step 1.5: Early feedback and interviews
│   ├── 1.5_draft_early_validation_report.md # Step 1.5: Validation of key assumptions
│   ├── 2_system_architecture.md   # Step 2: Architecture diagram and tech stack choices
│   ├── 3_feature_roadmap.md       # Step 3: Prioritized epics list and roadmap
│   │
│   ├── 5.1_functional_design.md   # Step 5.1: Functional specifications and UI flows
│   ├── 5.3_technical_design.md    # Step 5.3: Database schemas, API endpoints, and designs
│   │
│   ├── 6.1_implementation_plan.md # Step 6.1: Phased execution plan for the active sprint
│   ├── 6.2_implementation_report.md # Step 6.2: Final implementation details and PR checklist
│   ├── 6.2_testing_plan.md        # Step 6.2: Test coverage definitions and test cases
│   ├── 6.3_bug_list.md            # Step 6.3: Tracked bugs during validation
│   ├── 6.3_testing_report.md      # Step 6.3: Verification results (CI logs, manual signs)
│   └── 6.3_updates_list.md        # Step 6.3: Post-testing modifications and updates
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
