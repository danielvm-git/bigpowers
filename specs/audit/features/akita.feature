Feature: Akita Compliance (Clean Code for AI Agents)
  As a developer
  I want my code to be agent-friendly
  So that future agents can easily read and navigate it

  Scenario: Agent-Friendly Code Structure
    Given a project with bigpowers conventions
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
