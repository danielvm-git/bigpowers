Feature: Karpathy Compliance (Behavioral Principles)
  As an AI agent
  I want to follow high-integrity behavioral principles
  So that I avoid common failure modes and over-complication

  Scenario: High-Integrity Agent Behavior
    Given a new task
    Then I should surface assumptions before writing code
    And I should present multiple interpretations of ambiguous requests
    And I should prioritize the minimum viable implementation
    And I should avoid speculative abstractions
    And my changes should be surgical, touching only what is required
    And I should match the existing code style and conventions
    And I should define verifiable success criteria for every step
    And I should loop until behavioral correctness is verified
    And I should push back on unnecessary complexity
 Broadway
