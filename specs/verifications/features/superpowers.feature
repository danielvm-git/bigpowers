Feature: Superpowers Compliance (Hard Gates & Red Flags)
  As a quality engineer
  I want strict enforcement of behavioral gates
  So that agents do not bypass critical design and review steps

  Scenario: Behavioral Gate Enforcement
    Given a high-stakes task
    Then skills should include bold HARD-GATE callout blocks
    And I should not write code before the design is approved
    And I should detect "red flag" rationalizations in my own thought process
    And I should push back if a task is "too simple" to need a plan
    And I should use fresh subagent context for independent reviews
    And I should enforce a two-stage review gate
    And I should automatically bootstrap project context at session start
    And I should visualize implementation progress as a roadmap
    And I should reject PRs that do not meet the 94% quality threshold
