Feature: Harness Falsification Test
  As a compliance engineer
  I want to verify that the harness correctly reports FAIL
  So that a passing harness actually means something

  Scenario: Intentional Failure
    Given the codebase exists
    Then this step always fails
