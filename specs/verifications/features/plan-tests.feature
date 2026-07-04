Feature: plan-tests

  Scenario: Generate a test plan for an epic
    Given a sliced epic with P0 or P1 tasks
    When I run plan-tests
    Then it produces specs/tech-architecture/eNN-TEST_PLAN_LATEST.md
    And the plan contains a risk matrix
    And the plan contains scenario IDs in the format SC-eNNsYY-P{0|1|2|3}-NN
    And the plan specifies test levels and fixture architectures
