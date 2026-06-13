Feature: Akita Compliance (Clean Code for AI Agents)
  As a developer
  I want my code to be agent-friendly
  So that future agents can easily read and navigate it

  Background:
    Given a project with bigpowers conventions

  Scenario: Agent-Friendly Code Structure
    Then functions should be small (4-20 lines)
    And each module should follow the Single Responsibility Principle
    And names should be meaningful and unique
    And comments should explain WHY, not WHAT
    And types should be explicit
    And there should be no code duplication (DRY)
    And every change should include runnable tests as verification
    And the directory structure should be predictable
    And dependencies should be injected, not global
    And nesting should be shallow (max 2 levels)
    And error messages should include the offending value and expected shape
    And formatting should be consistent
    And there should be no redundant comments that restate code

  Scenario: Agent-Friendly Navigation and Self-Correction
    Then public symbols should be unique enough to be searched with 'grep' (< 5 results)
    And filenames should accurately describe their contents to minimize 'read_file' calls
    And error messages should include a "remediation hint" for the agent
    And complex logic should include "Provenance" links (ADRs, Jira, or Commits)
    And files should be small enough to avoid context window truncation (< 300 lines)
