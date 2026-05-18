Feature: Clean Code Compliance (Robert C. Martin)
  As a software craftsman
  I want to apply classic Clean Code heuristics
  So that the codebase remains maintainable and readable

  Scenario: Professional Craftsmanship
    Given the codebase exists
    Then every function should do exactly one thing
    And files should remain under 500 lines
    And there should be no "magic strings" or numbers
    And exceptions should be preferred over error codes
    And classes should follow the Single Responsibility Principle (SRP)
    And dependencies should be inverted (DIP)
    And tests should follow the F.I.R.S.T rubric
    And the "Boy Scout Rule" should be applied to every change
    And public APIs should be small and focused
    And names should reveal intention without requiring comments
