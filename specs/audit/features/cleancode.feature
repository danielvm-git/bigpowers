Feature: Clean Code Compliance (Robert C. Martin)
  As a software craftsman
  I want to apply classic Clean Code heuristics
  So that the codebase remains maintainable and readable

  Background:
    Given the codebase exists

  Scenario: Function and Class Hygiene
    Then every function should do exactly one thing (G30)
    And functions should descend exactly one level of abstraction (G34)
    And functions should stay within 4-20 lines
    And files should remain under 500 lines (Newspaper Metaphor)
    And classes should follow the Single Responsibility Principle (SRP)
    And dependencies should be inverted toward abstractions (DIP)

  Scenario: Naming and Expression
    Then names should be intention-revealing and unambiguous (N1, N4)
    And names should describe side-effects (N7)
    And there should be no "magic strings" or numbers (G25)
    And conditionals should be expressed as positives (G29)
    And complex boolean logic should be encapsulated in named functions (G28)
    And there should be no code duplication (DRY / G5)

  Scenario: Comments and Code Quality
    Then the "Boy Scout Rule" should be applied to every change (Leave it cleaner)
    And exceptions should be preferred over error codes
    And comments should explain WHY, not WHAT
    And there should be no commented-out code (C5)
    And dead code and unused functions should be removed (G9, F4)

  Scenario: Professional Testing
    Then tests should follow the F.I.R.S.T rubric
    And tests should verify behavior through public APIs, not implementation (T8)
    And there should be no "Ignored Tests" without an explicit ambiguity note (T4)
    And boundary conditions should be exhaustively tested (T5)
    And tests should be fast and run with a single command (T9)
