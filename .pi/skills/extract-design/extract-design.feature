Feature: Extract DESIGN.md from HTML prototype

  Scenario: Extract tokens from a styled prototype
    Given an HTML prototype with 3+ colors, 2+ font sizes, spacing values, and rounded corners
    When extract-design runs on the prototype
    Then DESIGN_LATEST.md contains a colors token group with at least 3 entries
    And DESIGN_LATEST.md contains a typography token group with at least 2 levels
    And all 8 prose sections are present

  Scenario: Handle dark mode prototypes
    Given an HTML prototype that responds to prefers-color-scheme: dark
    When extract-design runs dual-pass extraction
    Then DESIGN_LATEST.md contains a colors-dark token group

  Scenario: Degrade gracefully on unstyleable HTML
    Given an HTML file with no computed styles
    When extract-design runs on the prototype
    Then DESIGN_LATEST.md is written with a degradation warning

  Scenario: Flag uncertain classifications
    Given an HTML prototype where one color is used ambiguously
    When extract-design classifies colors
    Then the uncertain color's prose rationale contains an AGENT NOTE comment
