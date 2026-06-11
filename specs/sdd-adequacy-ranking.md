# SDD Directory Structures: Comparative Suitability Analysis

This document provides a systematic evaluation and ranking of the **22 mapped Software-Driven Development (SDD)** directory structures stored under [docs/file-structure/](file:///Users/danielvm/Developer/bigpowers/docs/file-structure). The goal is to determine the most adequate directory structure for building software using autonomous AI agents.

This updated evaluation combines **five new criteria** (based on [docs/PRINCIPLES.md](file:///Users/danielvm/Developer/bigpowers/docs/PRINCIPLES.md) and [specs/audit/features/](file:///Users/danielvm/Developer/bigpowers/specs/audit/features)) positioned **on top of the five former structural criteria**, evaluating each layout on a scale of **1.0 to 5.0** across all **10 dimensions** (maximum score: **50.0**).

---

## 1. Evaluation Methodology & Criteria Key

Each structure is graded across two main categories of criteria:

### Category A: Core Philosophical Principles (New Criteria)
*   **C1: Clean Code SRP Compliance (Uncle Bob)**
    *   *Source*: [`cleancode.feature`](file:///Users/danielvm/Developer/bigpowers/specs/audit/features/cleancode.feature).
    *   *Metric*: Separates static business specifications (*what*) from dynamic task checklists and runnable verifications (*how*). Avoids monolithic specifications.
*   **C2: Complexity Management & Token Economy (Ousterhout & Pocock)**
    *   *Source*: [`pocock.feature`](file:///Users/danielvm/Developer/bigpowers/specs/audit/features/pocock.feature).
    *   *Metric*: Encapsulates features into directories (Feature Capsules) and supports active context window pruning (e.g. archiving completed epics).
*   **C3: Spec-Driven & Runnable Verifiability (Wasowski)**
    *   *Source*: [`conventions.feature`](file:///Users/danielvm/Developer/bigpowers/specs/audit/features/conventions.feature).
    *   *Metric*: Maps all specifications directly to Gherkin scenarios with explicit, machine-runnable verification scripts for every task.
*   **C4: Agent-Centric Searchability & Navigation (Akita)**
    *   *Source*: [`akita.feature`](file:///Users/danielvm/Developer/bigpowers/specs/audit/features/akita.feature).
    *   *Metric*: Standardizes directory naming schemas to ensure global symbol `grep` searches return `< 5 results` and minimize `read_file` counts.
*   **C5: Hard-Gated Session Governance & Integrity (Superpowers)**
    *   *Source*: [`superpowers.feature`](file:///Users/danielvm/Developer/bigpowers/specs/audit/features/superpowers.feature).
    *   *Metric*: Structural blocks preventing coding before design approval; roadmap progress metrics derived directly from the filesystem.

### Category B: Structural Mechanics (Former Criteria)
*   **C6: Token Efficiency (Token Overhead)**: How well does the structure minimize loaded context? (e.g. via capsules, archiving, colocation, or small story files).
*   **C7: Toolability & Machine Parsability**: Can scripts (bash, Python) programmatically read, validate, or write state? (e.g., structured YAML/JSON vs. free-text Markdown tables).
*   **C8: Verification Loop Integration**: Is there a dedicated structure/folder for test logs, UAT logs, or grader reports to ensure code is verified before merging?
*   **C9: Change Isolation (Feature Capsules)**: Are feature specifications, plans, and tasks grouped together in a single folder, or scattered across multiple root-level folders?
*   **C10: Source Tree Cleanliness (Non-Intrusiveness)**: Does the SDD metadata stay out of the application code (`src/`), preventing build pollution?

---

## 2. Global Ranking Table

| Rank | Methodology | C1 (SRP) | C2 (Tkn) | C3 (Ver) | C4 (Grp) | C5 (Gat) | C6 (T.Eff) | C7 (Tl) | C8 (V.Lp) | C9 (Chg) | C10 (Cln) | Total Score |
|:---:|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| 1 | **Evolved bigpowers** | 5.0 | 5.0 | 5.0 | 5.0 | 5.0 | 5.0 | 5.0 | 5.0 | 5.0 | 5.0 | **50.0 / 50.0** |
| 2 | **GSD 2 (gsd-pi)** | 4.5 | 4.5 | 4.5 | 4.0 | 5.0 | 4.5 | 5.0 | 4.5 | 4.0 | 5.0 | **45.5 / 50.0** |
| 3 | **Taskmaster** | 4.5 | 4.5 | 4.5 | 4.5 | 4.5 | 4.5 | 5.0 | 4.5 | 4.0 | 5.0 | **45.5 / 50.0** |
| 4 | **fspec** | 4.5 | 4.0 | 5.0 | 4.5 | 4.5 | 4.0 | 5.0 | 4.5 | 4.0 | 5.0 | **45.0 / 50.0** |
| 5 | **MoAI-ADK** | 4.5 | 4.5 | 4.0 | 4.5 | 4.5 | 4.5 | 4.5 | 4.0 | 4.5 | 5.0 | **44.5 / 50.0** |
| 6 | **OpenSpec** | 4.5 | 5.0 | 3.5 | 4.5 | 4.5 | 5.0 | 4.0 | 3.5 | 5.0 | 5.0 | **44.5 / 50.0** |
| 7 | **openspec-cn** | 4.5 | 5.0 | 3.5 | 4.5 | 4.5 | 5.0 | 4.0 | 3.5 | 5.0 | 5.0 | **44.5 / 50.0** |
| 8 | **Spec Kit** | 4.5 | 4.5 | 3.5 | 4.5 | 4.5 | 4.5 | 4.0 | 3.5 | 5.0 | 5.0 | **43.5 / 50.0** |
| 9 | **SpecPulse** | 4.0 | 4.0 | 4.0 | 4.5 | 4.5 | 4.5 | 4.5 | 3.5 | 3.5 | 5.0 | **42.0 / 50.0** |
| 10 | **get-shit-done-redux** | 4.0 | 4.0 | 4.0 | 4.0 | 4.0 | 4.0 | 3.5 | 4.0 | 4.0 | 5.0 | **40.5 / 50.0** |
| 11 | **GSD v1** | 4.0 | 4.0 | 4.0 | 3.5 | 4.0 | 4.0 | 3.0 | 4.0 | 4.0 | 5.0 | **39.5 / 50.0** |
| 12 | **cc-sdd** | 4.0 | 4.0 | 3.0 | 4.0 | 4.0 | 4.0 | 3.0 | 3.0 | 4.5 | 5.0 | **38.5 / 50.0** |
| 13 | **AIDD** | 3.5 | 3.5 | 3.5 | 4.0 | 3.5 | 3.0 | 4.0 | 3.5 | 3.0 | 5.0 | **36.5 / 50.0** |
| 14 | **gsd-core** | 3.5 | 3.5 | 3.0 | 3.5 | 4.0 | 3.5 | 3.5 | 3.0 | 3.5 | 5.0 | **36.0 / 50.0** |
| 15 | **SpecBoot** | 3.0 | 3.5 | 3.0 | 4.0 | 3.5 | 3.0 | 4.5 | 3.0 | 2.5 | 5.0 | **35.0 / 50.0** |
| 16 | **Original bigpowers** | 3.0 | 3.0 | 3.0 | 4.0 | 3.5 | 3.0 | 4.0 | 3.0 | 2.0 | 5.0 | **33.5 / 50.0** |
| 17 | **specdd** | 4.0 | 5.0 | 2.5 | 3.5 | 1.0 | 5.0 | 3.5 | 2.5 | 4.5 | 1.0 | **32.5 / 50.0** |
| 18 | **MetaSpec** | 3.0 | 3.5 | 2.0 | 3.5 | 3.0 | 3.0 | 4.0 | 2.0 | 2.5 | 5.0 | **31.5 / 50.0** |
| 19 | **ArcBlock/idd** | 4.0 | 4.5 | 2.5 | 3.0 | 1.0 | 4.5 | 3.0 | 2.5 | 4.0 | 2.0 | **31.5 / 50.0** |
| 20 | **Superpowers** | 3.0 | 3.0 | 2.0 | 3.0 | 3.0 | 3.0 | 3.5 | 2.0 | 2.5 | 5.0 | **30.0 / 50.0** |
| 21 | **SDD_Flow** | 2.0 | 2.0 | 4.0 | 2.0 | 3.0 | 2.0 | 1.5 | 4.0 | 1.5 | 5.0 | **27.0 / 50.0** |
| 22 | **BMAD** | 2.0 | 2.0 | 2.5 | 2.0 | 3.0 | 2.0 | 2.0 | 2.5 | 2.0 | 5.0 | **25.0 / 50.0** |

---

## 3. Top-Tier Recommendations (Compliance Analysis)

### #1. Evolved bigpowers (50.0/50.0)
*   **Archetype**: `Centralized Spec-First (Capsule/Archive)`
*   **Key Strengths**: Shifting from monolithic yaml specs to **Epic Capsule Directories** (`specs/epics/eXX-slug/`) that house decoupled, independent story markdown specifications (`eXXsYY-slug.md`) and dynamic task checklists (`eXXsYY-tasks.yaml`). Epic-specific ADRs live directly inside their parent epic capsules (`specs/epics/eXX-slug/adr/`), while concurrency is safeguarded using a state write-lock file (`specs/state.yaml.lock`). Completed epic folders are actively moved to `specs/epics/archive/`.
*   **Alignment with Principles & Features**:
    *   *Uncle Bob (C1)*: Decoupling business requirements (*what*) from build checklists (*how*) achieves perfect compliance with the SRP (Single Responsibility Principle) scenario in `cleancode.feature`.
    *   *Pocock & Ousterhout (C2 & C6)*: Archiving completed epics completely removes inactive context from the agent workspace. Storing build tasks in lightweight YAML rather than narrative markdown restricts token surface area, preventing context window truncation.
    *   *Wasowski & Conventions (C3 & C8)*: Standalone story specs enforce Gherkin-only acceptance criteria. In addition, the central `specs/verifications/` ledger enforces that all runs log validation evidence, checking the 94% quality threshold gate.
    *   *Akita (C4)*: High-specificity kebab-case layouts allow direct targeted file accesses, guaranteeing symbol grep lookups return `< 5 results` matching Akita's grep-ability requirements.
    *   *Superpowers & Governance (C5 & C9)*: Perfect 5.0. State locking via `state.yaml.lock` prevents concurrency conflicts for parallel agents, and epic-local ADRs ensure that no records are orphaned during archiving.

### #2. GSD 2 (gsd-pi) (45.5/50.0)
*   **Archetype**: `Centralized Spec-First`
*   **Key Strengths**: Incorporates SQLite database schemas to lock session state and execution statuses, preventing formats from shifting dynamically during agent executions.
*   **Alignment with Principles & Features**:
    *   *Superpowers & Governance (C5)*: Excellent ACID transaction guarantees and locking state schemas ensure the absolute highest session integrity.
    *   *Akita Failure (C4 & C7)*: SQLite stores state in a binary format, failing Akita's text grep-ability rule. Standard grep tools cannot parse it. AI agents must execute custom MCP connectors to query states, increasing token overhead and navigation complexity.

### #3. Taskmaster (45.5/50.0)
*   **Archetype**: `Centralized Spec-First`
*   **Key Strengths**: Structured JSON files represent global configurations, and it features autonomous loop log scripts and dedicated execution outcome folders.
*   **Alignment with Principles & Features**:
    *   *Uncle Bob (C1)*: Good separation of states, but tasks are documented as unstructured flat text instructions, which blends specification details with implementation notes.
    *   *Akita (C4)*: Predictable paths, though unstructured text tasks make programmatic parsing more fragile.

### #4. fspec (45.0/50.0)
*   **Archetype**: `Centralized Spec-First`
*   **Key Strengths**: Strict JSON registries map specific vertical story slices directly to code test coverage.
*   **Alignment with Principles & Features**:
    *   *Wasowski (C3)*: Perfect 5.0. It features an exceptional direct mapping between Gherkin scenario keys and target unit tests.
    *   *Complexity (C2 & C9)*: It splits specifications, designs, and static attachments into scattered folders at the root level, breaking the cohesive "Feature Capsule" model. Global JSON registry files must be parsed entirely, causing context bloat.

---

## 4. Key Architectural Insights

### 4.1. Decentralized Colocation vs. Source Cleanliness
A core tension in SDD directory structures exists between **Decentralized Colocation** (placing specifications directly in `src/` next to code files, as in `specdd` and `ArcBlock/idd`) and **Source Cleanliness** (keeping specifications in `/specs` at the root, preserving `src/` for application binaries only).

*   **The Colocation Case**: In `specdd`, placing `Header.sdd` next to `Header.tsx` scores a perfect **5.0** on Token Economy. When modifying `Header.tsx`, the agent only needs to open the directory it is already in, pulling the spec and code together with zero search overhead.
*   **The Compliance Failure**: However, placing SDD files inside `src/` violates Clean Code (C1) and Session Governance (C5). It pollutes the production build system, makes it harder for security tools to scan code without scanning specs, and scatters the ubiquitous language across hundreds of directories.
*   **The Evolved bigpowers Resolution**: **Evolved bigpowers** resolves this tension by using the **Capsule Epic Directory** model. By keeping all spec assets inside isolated capsule directories (`specs/epics/eXX-slug/`) outside `src/`, it maintains 100% source tree cleanliness while achieving similar token efficiency by grouping the story spec (`eXXsYY-slug.md`) and task checklist (`eXXsYY-tasks.yaml`) together.

### 4.2. Decoupling Specification from Task Execution (The SRP Victory)
Legacy systems (including Original bigpowers and Superpowers) stored specs and checklists in monolithic YAMLs. This created severe token rot. Every time an agent executed a minor coding task, it had to parse the entire specification, leading to context truncation.

By decoupling the Gherkin specifications (`eXXsYY-slug.md`) from the toolable tasks (`eXXsYY-tasks.yaml`), the developer agent only loads the high-density tasks YAML during build iterations, conserving the token budget and satisfying Uncle Bob's SRP heuristics.

---

## 5. Detailed Scores for All Remaining Frameworks

### #5. MoAI-ADK (44.5/50.0)
*   **Archetype**: `Centralized Spec-First`
*   **Breakdown**: C1: 4.5 | C2: 4.5 | C3: 4.0 | C4: 4.5 | C5: 4.5 | C6: 4.5 | C7: 4.5 | C8: 4.0 | C9: 4.5 | C10: 5.0
*   **Analysis**: Provides strong feature capsules, but the `brain/` directory accumulates massive memory logs, causing token inflation.

### #6. OpenSpec (44.5/50.0)
*   **Archetype**: `Change/Proposal-Driven`
*   **Breakdown**: C1: 4.5 | C2: 5.0 | C3: 3.5 | C4: 4.5 | C5: 4.5 | C6: 5.0 | C7: 4.0 | C8: 3.5 | C9: 5.0 | C10: 5.0
*   **Analysis**: Excellent change proposal directories that are archived upon merging. Lacks a dedicated `verifications/` ledger to store test runs.

### #7. openspec-cn (44.5/50.0)
*   **Archetype**: `Change/Proposal-Driven`
*   **Breakdown**: C1: 4.5 | C2: 5.0 | C3: 3.5 | C4: 4.5 | C5: 4.5 | C6: 5.0 | C7: 4.0 | C8: 3.5 | C9: 5.0 | C10: 5.0
*   **Analysis**: Chinese-localized version of OpenSpec; identical strengths and weaknesses.

### #8. Spec Kit (43.5/50.0)
*   **Archetype**: `Centralized Spec-First`
*   **Breakdown**: C1: 4.5 | C2: 4.5 | C3: 3.5 | C4: 4.5 | C5: 4.5 | C6: 4.5 | C7: 4.0 | C8: 3.5 | C9: 5.0 | C10: 5.0
*   **Analysis**: Scopes work in branch-specific directories. Lacks centralized UAT verification tracking.

### #9. SpecPulse (42.0/50.0)
*   **Archetype**: `Centralized Spec-First`
*   **Breakdown**: C1: 4.0 | C2: 4.0 | C3: 4.0 | C4: 4.5 | C5: 4.5 | C6: 4.5 | C7: 4.5 | C8: 3.5 | C9: 3.5 | C10: 5.0
*   **Analysis**: Features a structured `config.yml` and active developer memory logs, but memory logs grow excessively large, violating C2 token limitations.

### #10. get-shit-done-redux (40.5/50.0)
*   **Archetype**: `Centralized Spec-First`
*   **Breakdown**: C1: 4.0 | C2: 4.0 | C3: 4.0 | C4: 4.0 | C5: 4.0 | C6: 4.0 | C7: 3.5 | C8: 4.0 | C9: 4.0 | C10: 5.0
*   **Analysis**: Milestone-based organization. Decent structure, but specs are scattered, violating C2 capsule isolation.

### #11. GSD v1 (39.5/50.0)
*   **Archetype**: `Centralized Spec-First`
*   **Breakdown**: C1: 4.0 | C2: 4.0 | C3: 4.0 | C4: 3.5 | C5: 4.0 | C6: 4.0 | C7: 3.0 | C8: 4.0 | C9: 4.0 | C10: 5.0
*   **Analysis**: Legacy precursor to GSD Redux. Suffers from unstructured text logs and scattered files.

### #12. cc-sdd (38.5/50.0)
*   **Archetype**: `Centralized Spec-First`
*   **Breakdown**: C1: 4.0 | C2: 4.0 | C3: 3.0 | C4: 4.0 | C5: 4.0 | C6: 4.0 | C7: 3.0 | C8: 3.0 | C9: 4.5 | C10: 5.0
*   **Analysis**: Scoped feature specification folders (`specs/photo-albums/`) containing requirements, designs, and tasks. Lacks verification reporting.

### #13. AIDD (36.5/50.0)
*   **Archetype**: `Centralized Spec-First`
*   **Breakdown**: C1: 3.5 | C2: 3.5 | C3: 3.5 | C4: 4.0 | C5: 3.5 | C6: 3.0 | C7: 4.0 | C8: 3.5 | C9: 3.0 | C10: 5.0
*   **Analysis**: Rigid separation between human-written and agent-written specs. Increases navigation friction.

### #14. gsd-core (36.0/50.0)
*   **Archetype**: `Centralized Spec-First`
*   **Breakdown**: C1: 3.5 | C2: 3.5 | C3: 3.0 | C4: 3.5 | C5: 4.0 | C6: 3.5 | C7: 3.5 | C8: 3.0 | C9: 3.5 | C10: 5.0
*   **Analysis**: Highly minimal GSD structure. Includes `LEARNINGS.md`, but lacks capsule structure.

### #15. SpecBoot (35.0/50.0)
*   **Archetype**: `Centralized Spec-First`
*   **Breakdown**: C1: 3.0 | C2: 3.5 | C3: 3.0 | C4: 4.0 | C5: 3.5 | C6: 3.0 | C7: 4.5 | C8: 3.0 | C9: 2.5 | C10: 5.0
*   **Analysis**: Rigidly centered around OpenAPI specifications. Poor suitability for behavioral user stories.

### #16. Original bigpowers (33.5/50.0)
*   **Archetype**: `Centralized Spec-First`
*   **Breakdown**: C1: 3.0 | C2: 3.0 | C3: 3.0 | C4: 4.0 | C5: 3.5 | C6: 3.0 | C7: 4.0 | C8: 3.0 | C9: 2.0 | C10: 5.0
*   **Analysis**: Legacy flat spec format. Monolithic epics couple specifications with active task lists, causing context rot.

### #17. specdd (32.5/50.0)
*   **Archetype**: `Decentralized / Colocated`
*   **Breakdown**: C1: 4.0 | C2: 5.0 | C3: 2.5 | C4: 3.5 | C5: 1.0 | C6: 5.0 | C7: 3.5 | C8: 2.5 | C9: 4.5 | C10: 1.0
*   **Analysis**: Perfect colocation score, but completely pollutes `src/` with specification artifacts, failing on build isolation.

### #18. MetaSpec (31.5/50.0)
*   **Archetype**: `Centralized Spec-First`
*   **Breakdown**: C1: 3.0 | C2: 3.5 | C3: 2.0 | C4: 3.5 | C5: 3.0 | C6: 3.0 | C7: 4.0 | C8: 2.0 | C9: 2.5 | C10: 5.0
*   **Analysis**: Constitution-driven. Lacks structured task lists and verification tracing.

### #19. ArcBlock/idd (31.5/50.0)
*   **Archetype**: `Decentralized / Colocated`
*   **Breakdown**: C1: 4.0 | C2: 4.5 | C3: 2.5 | C4: 3.0 | C5: 1.0 | C6: 4.5 | C7: 3.0 | C8: 2.5 | C9: 4.0 | C10: 2.0
*   **Analysis**: Places IDD specifications inside `src/`. Compromises build isolation.

### #20. Superpowers (30.0/50.0)
*   **Archetype**: `Centralized Spec-First`
*   **Breakdown**: C1: 3.0 | C2: 3.0 | C3: 2.0 | C4: 3.0 | C5: 3.0 | C6: 3.0 | C7: 3.5 | C8: 2.0 | C9: 2.5 | C10: 5.0
*   **Analysis**: Heavy legacy structures. Feature scatter is high, and lack of verifications folder hurts scoring.

### #21. SDD_Flow (27.0/50.0)
*   **Archetype**: `Chronological / Lifecycle`
*   **Breakdown**: C1: 2.0 | C2: 2.0 | C3: 4.0 | C4: 2.0 | C5: 3.0 | C6: 2.0 | C7: 1.5 | C8: 4.0 | C9: 1.5 | C10: 5.0
*   **Analysis**: Stores files chronologically. Leads to massive text accumulation and poor searchability.

### #22. BMAD (25.0/50.0)
*   **Archetype**: `Chronological / Lifecycle`
*   **Breakdown**: C1: 2.0 | C2: 2.0 | C3: 2.5 | C4: 2.0 | C5: 3.0 | C6: 2.0 | C7: 2.0 | C8: 2.5 | C9: 2.0 | C10: 5.0
*   **Analysis**: Too many narrative files (PRFAQs, brainstorming docs) that inflate context surface area without offering executable verifications.
