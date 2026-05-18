Feature: BMAD Compliance (Full-SDLC Consistency)
  As a product owner
  I want a consistent SDLC from analysis to deployment
  So that every feature is tracked and validated against business goals

  Scenario: End-to-End Lifecycle Tracking
    Given a project lifecycle
    Then every session should have a clear "state" artifact
    And specs should accumulate across all phases (discover to sustain)
    And there should be no "phase-gated" handoffs that lose context
    And I should maintain a ubiquitous language glossary
    And I should track architectural decisions in ADRs
    And I should verify every step with a runnable command
    And I should integrate with the project's issue tracker
    And I should support multiple harnesses from a single source of truth
    And I should apply TDD consistently across all implementation tasks
