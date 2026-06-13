Feature: Harness Smoke Test
  Scenario: Simple Pass
    Given a skill exists
    When I audit it
    Then it should pass
