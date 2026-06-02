Feature: Conventions Compliance
  As a project architect
  I want CONVENTIONS.md to be the single source of truth for quality
  So that all agents (human and AI) follow the same rigorous standards

  Scenario: Conventions Alignment with Benchmarks
    Given the file CONVENTIONS.md
    Then it must mandate Conventional Commits 1.0.0 and SemVer 2.0.0
    And it must mandate function size limits (4-20 lines)
    And it must mandate file size limits (< 300 lines)
    And it must mandate the SRP (Single Responsibility Principle)
    And it must mandate explicit typing
    And it must mandate the "Why not What" commenting rule
    And it must mandate "Provenance" links for complex logic
    And it must mandate the F.I.R.S.T rubric for tests
    And it must mandate remediation hints in error messages
    And it must mandate the "Boy Scout Rule" (Leave code cleaner)
    And it must prohibit direct work on main/master branches
    And it must require every change to be verified with a runnable command
    And land branch script exists
    And solo git profile exists
    And sync skills preserves plus in descriptions
