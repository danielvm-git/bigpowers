# bigpowers Skill Suitability & Evolved File Structure Evaluation

This evaluation report analyzes whether the proposed evolved directory structure for `bigpowers` projects can successfully accommodate all information produced and consumed by the **61 active agent skills**, identifying any gaps, conflicts, or required skill-level updates.

---

## 1. Executive Summary

The proposed evolved structure ([projected-structure-bigpowers-evolved.md](file:///Users/danielvm/Developer/bigpowers/docs/file-structure/projected-structure-bigpowers-evolved.md)) is a **highly superior and robust architecture** compared to the legacy flat-file structures. By shifting to **Capsule Epic Directories**, **independent Countable Story Markdown files**, and a **centralized verifications ledger**, it solves the "feature scatter" and "context rot" issues common in long-running agentic workflows.

However, because many active `bigpowers` skills hardcode specific file paths and schema structures in their `SKILL.md` rules, migrating to this structure requires updating the implementation of several key skills.

> [!IMPORTANT]
> **Key Finding & Resolution**: The most significant architectural friction was the transition from **flat YAML epics** (`specs/epics/eNN-*.yaml` storing both story metadata and task lists) to **Epic Capsule Directories** containing **independent Countable Story Markdown files**. Because the 20-section Countable Story Format does not natively define a `tasks[]` list with `verify` commands, we have resolved to **decouple specifications from execution tasks** by introducing a dedicated `eXXsYY-tasks.yaml` file next to each story markdown file inside the epic capsule directory.

---

## 2. Skill-to-Path Mapping & Compatibility Index

The table below maps all active `bigpowers` skills that read or write specifications, plans, or tracking files to their legacy and evolved targets.

| BMAD Phase | Skill | Legacy Path | Evolved Path | Status | Notes / Required Action |
| :--- | :--- | :--- | :--- | :---: | :--- |
| **Discover** | `survey-context` | `specs/state.yaml`<br>`specs/epics/*.yaml` | `specs/state.yaml` (+ `.lock`)<br>`specs/epics/eXX-*/` | ⚠️ **Update Required** | Must acquire `state.yaml.lock` before scanning capsule directories. |
| **Discover** | `map-codebase` | `specs/plans/TECH_STACK_LATEST.md` | `specs/tech-architecture/tech-stack.md` | ⚠️ **Update Required** | Simple rename of the target file path. |
| **Elaborate** | `model-domain` | `specs/plans/TECH_STACK_LATEST.md`<br>`specs/adr/` | `specs/tech-architecture/tech-stack.md`<br>`specs/epics/eXX-*/adr/`<br>`specs/adr/` | ⚠️ **Update Required** | Write epic-specific ADRs directly to their capsule directories. |
| **Elaborate** | `define-language` | `specs/UBIQUITOUS_LANGUAGE.md` | `specs/product/GLOSSARY_LATEST.yaml` | ⚠️ **Update Required** | Changes format from Markdown to YAML to support full toolability. |
| **Elaborate** | `deepen-architecture` | `specs/plans/TECH_STACK_LATEST.md` | `specs/tech-architecture/tech-stack.md` | ⚠️ **Update Required** | Update target references. |
| **Elaborate** | `design-interface` | `specs/INTERFACE-OPTIONS.md` | `specs/tech-architecture/design.md` | ⚠️ **Update Required** | Centralizes UI/UX specifications under `tech-architecture/`. |
| **Plan** | `scope-work` | `specs/requirements/SCOPE_LATEST.yaml` | `specs/product/SCOPE_LATEST.yaml` | ⚠️ **Update Required** | Update parent folder path to `specs/product/`. |
| **Plan** | `assess-impact` | `specs/IMPACT.md` | `specs/tech-architecture/IMPACT_LATEST.md` | ⚠️ **Update Required** | Relocates impact assessments to tech architecture. |
| **Plan** | `change-request` | `specs/release-plan.yaml` | `specs/release-plan.yaml` | ✅ **Compatible** | Direct match. |
| **Plan** | `slice-tasks` | `specs/epics/eNN-*.yaml` | `specs/epics/eXX-*/` | ⚠️ **Update Required** | **Crucial**: Must write capsule folder, `epic.yaml`, story markdown stubs, and tasks YAML stubs instead of a single YAML file. |
| **Plan** | `plan-work` | `specs/epics/eNN-*.yaml` (`tasks[]`) | `specs/epics/eXX-*/eXXsYY-tasks.yaml` | ⚠️ **Update Required** | **Crucial**: Must write implementation plans to the dedicated YAML tasks file. |
| **Plan** | `plan-refactor` | `specs/REFACTOR.md` | `specs/tech-architecture/REFACTOR_LATEST.md` | ⚠️ **Update Required** | Relocates refactoring plans to tech architecture. |
| **Plan** | `plan-release` | `specs/release-plan.yaml` | `specs/release-plan.yaml` | ✅ **Compatible** | Direct match. |
| **Spike** | `spike-prototype` | `specs/archive/spikes/` | `specs/tech-architecture/snapshots/` | ⚠️ **Update Required** | Group spikes under tech snapshots or archive. |
| **Build** | `develop-tdd` | `specs/epics/*.yaml` | `specs/epics/eXX-*/eXXsYY-tasks.yaml` | ⚠️ **Update Required** | Reads verification steps from the dedicated tasks YAML file. |
| **Build** | `build-epic` | `specs/epics/*.yaml` | `specs/epics/eXX-*/` | ⚠️ **Update Required** | **Crucial**: Update the 8-step orchestrator loop to scan capsule directories. |
| **Verify** | `verify-work` | `specs/epics/*.yaml` | `specs/verifications/eXXsYY-verify.yaml` | ⚠️ **Update Required** | **Crucial**: Reads stories from capsule folders, writes UAT evidence to centralized folder. |
| **Verify** | `run-evals` | `specs/EVALS-*.md` | `specs/verifications/*-eval-report.md` | ⚠️ **Update Required** | Relocates capability and regression reports to verifications ledger. |
| **Bug** | `investigate-bug` | `specs/bugs/BUG-*.md` | `specs/bugs/BUG-*.md` | ✅ **Compatible** | Match. Uses `registry.yaml` in both structures. |
| **Sustain** | `stocktake-skills` | `specs/STOCKTAKE-*.md` | `specs/STOCKTAKE-*.md` (or `specs/audit/`) | ✅ **Compatible** | Can write directly to root `specs/` or a subfolder. |
| **Utility** | `session-state` | `specs/state.yaml` | `specs/state.yaml`<br>`specs/state.yaml.lock` | ⚠️ **Update Required** | Must acquire the lock file to prevent concurrency conflict during session updates. |
| **Utility** | `run-planning` | `specs/planning-status.yaml` | `specs/planning-status.yaml` | ✅ **Compatible** | Direct match. |

---

## 3. Core Architectural Decisions

### Decision 1: Dedicated Story Task File (`eXXsYY-tasks.yaml`)

To resolve the challenge of defining step-by-step implementation checklists within independent stories without violating the strict Countable Story Format, we will create a dedicated task file for each story: `specs/epics/eXX-slug/eXXsYY-tasks.yaml`.

#### Evaluation against `PRINCIPLES.md`
*   **Clean Code (Uncle Bob): Single Responsibility Principle (SRP)**
    *   *Evaluation*: The story Markdown spec (`eXXsYY-*.md`) has the single responsibility of defining *what* the capability does (the business narrative, value statement, Gherkin acceptance criteria). The story tasks YAML (`eXXsYY-tasks.yaml`) has the single responsibility of detailing *how* it is built (the step-by-step implementation tasks and verify commands). Decoupling them prevents spec churn during development.
*   **Complexity Management (Ousterhout/Pocock): Information Hiding & Token Economy**
    *   *Evaluation*: The developer agent only needs to read `eXXsYY-tasks.yaml` during execution. It does not need to load the heavy 20-section spec markdown file. This keeps token overhead minimal, saving context and preventing context rot.
*   **Spec-Driven Development (Wasowski): Verification Loop & Toolability**
    *   *Evaluation*: A structured YAML file is highly machine-parsable. It allows automated tools (e.g. bash scripts, LSP engines) to easily read, validate, or update task states, and run verify commands programmatically without fragile regex markdown table parsing.
*   **Agentic Standard (Akita): Searchability & Context Minimization**
    *   *Evaluation*: Clear filenames describing contents (`e01s01-login.md` and `e01s01-tasks.yaml`) within the isolated capsule directory makes navigation highly predictable and minimizes unnecessary `read_file` calls.

#### Evaluation against `specs/audit/features/` Features
*   **`pocock.feature`**: Directly satisfies "context window constraints should be proactively managed" by splitting execution checklists from long specifications, and aligns with "context efficiency".
*   **`conventions.feature`**: Enforces "every change to be verified with a runnable command" by requiring each task in the YAML schema to have an explicit, executable `verify:` property.
*   **`superpowers.feature`**: Supports "visualize implementation progress as a roadmap" since structured task files make progress indicators (like `% complete`) easily readable by dashboards.

---

### Decision 2: Glossary Toolability (`GLOSSARY_LATEST.yaml`)

To resolve the glossary open question, we adopt a structured YAML format at `specs/product/GLOSSARY_LATEST.yaml` rather than a flat Markdown document.

#### Toolability Framework
*   **Schema Definition**:
    ```yaml
    version: 1.0.0
    terms:
      - term: customer_account
        definition: "A verified customer profile linked to a single email address."
        source: signup_flow
        classification: PII
        invariants:
          - "Email must be unique"
          - "Must contain at least one credentials model"
      - term: jwt_token
        definition: "JSON Web Token used to securely transmit claims between client and server."
        source: auth_system
        classification: Secret
    ```

*   **Continuous Synchronization & Readability**:
    *   To keep the glossary human-readable and easily indexable, we introduce a build task in `sync-skills.sh` (or `scripts/build-glossary.sh`) that automatically compiles `specs/product/GLOSSARY_LATEST.yaml` into a formatted markdown file `specs/product/GLOSSARY_LATEST.md`.
    *   This provides the best of both worlds: **100% toolable source of truth** (YAML) for automated validation, linting, and autocomplete APIs, combined with **100% human/agent readable documentation** (Markdown).

---

## 4. Verification & Action Plan

To fully implement this evolved structure, we propose the following task checklist to evolve the skill definitions:

### Phase 1: Update Planning & Spec Generation Skills
- [ ] **`seed-conventions`**: Update template to create the new folder layout (`specs/product/`, `specs/tech-architecture/`, `specs/epics/`, `specs/verifications/`, `specs/bugs/`).
- [ ] **`scope-work`**: Update path from `specs/requirements/SCOPE_LATEST.yaml` to `specs/product/SCOPE_LATEST.yaml`.
- [ ] **`define-language`**: Update to output terms to `specs/product/GLOSSARY_LATEST.yaml` using the structured schema, and add compilation to `.md`.
- [ ] **`map-codebase`**: Update output path to `specs/tech-architecture/tech-stack.md`.
- [ ] **`model-domain` / `deepen-architecture`**: Update reading references from `TECH_STACK_LATEST.md` to `tech-stack.md`.

### Phase 2: Update Slicing & Execution Skills
- [ ] **`slice-tasks`**: Rewrite to create epic capsule folders, stub countable story files, and stub tasks YAML files (`eXXsYY-tasks.yaml`) instead of writing to a single YAML.
- [ ] **`plan-work`**: Update task appending logic to target the story tasks file `specs/epics/eXX-slug/eXXsYY-tasks.yaml` using the defined schema.
- [ ] **`develop-tdd`**: Update planning phase checks to read tasks and verify commands from the dedicated tasks YAML file.
- [ ] **`verify-work`**: Re-target manual UAT confirmation output to write to `specs/verifications/eXXsYY-verify.yaml`.
- [ ] **`run-evals`**: Re-target eval reports to write to `specs/verifications/eXXsYY-eval-report.md`.

---

> [!TIP]
> **Conclusion**: The evolved file structure is fully capable of accommodating all needed project information and significantly improves token economy. The migration is highly recommended, provided the above skill-level updates are executed to ensure seamless toolability.
