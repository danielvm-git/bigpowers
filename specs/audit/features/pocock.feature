Feature: Pocock/Ousterhout Compliance (Deep Modules & Token Economy)
  As an engineering lead
  I want to optimize for module depth and context efficiency
  So that the system architecture is robust and agent costs are minimized

  Scenario: Deep Architecture and Efficient Context
    Given the system architecture
    Then modules should be "deep" (simple interface, complex functionality)
    And information should be hidden within modules, not leaked
    And there should be clear "seams" for testing and extension
    And I should explain the code's purpose and callers before modifying (zoom-out)
    And I should use "caveman" mode to reduce token usage
    And I should avoid filler language and pleasantries in terminal output
    And I should compact session state for cold-starts
    And I should identify and deepen "shallow" modules
    And context window constraints should be proactively managed
