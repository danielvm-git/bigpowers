# Sandi Metz: Practical Object-Oriented Design

**Purpose:** Documents Sandi Metz's practical approach to SOLID principles, message-level testing, and object-oriented design — showing how bigpowers skills embody these practices for testable, maintainable code.

**Credit:** Sandi Metz. Key works: *Practical Object-Oriented Design in Ruby* (POODR, 2012), *99 Bottles of OOP* (2016, with Katrina Owen).

---

## SOLID in Practice

Metz translates the five SOLID principles from abstract theory into concrete, testable design rules:

| Principle | Metz's Practical Rule |
|---|---|
| **Single Responsibility** | Classes that are easy to describe have one responsibility |
| **Open/Closed** | Use dependency injection to vary behavior without editing existing code |
| **Liskov Substitution** | Subclasses must honor the contract of their superclass — test this |
| **Interface Segregation** | Depend on things that change less often than you do |
| **Dependency Inversion** | Depend on abstractions, not concretions — inject the difference |

---

## Message-Level Testing

Metz distinguishes between two kinds of messages sent between objects:

| Message Type | Testing Strategy |
|---|---|
| **Query** — returns a value, no side effects | Test the sender: assert the return value |
| **Command** — changes state, may not return | Test the receiver: assert the side effect occurred |

This distinction produces tests that verify behavior at the right boundary — query messages are tested by their callers, command messages by their implementors. Message-level testing avoids testing private implementation details while still verifying system behavior.

---

## The Metz Rules (for manageable classes)

1. Classes can be no longer than 100 lines
2. Methods can be no longer than 5 lines
3. Methods can accept no more than 4 parameters (hash options count as one)
4. Controllers can instantiate only one object

These rules are intentionally strict — following them forces you to decompose and extract, producing smaller, more testable objects.

---

## How bigpowers uses

| Metz Concept | bigpowers Skill | How it's embodied |
|---|---|---|
| SOLID in practice | `audit-code` | Checks for SRP violations, large classes, and tight coupling |
| Message-level testing | `enforce-first` | Validates tests verify behavior at the right boundary (F.I.R.S.T) |
| Dependency injection | `plan-refactor` | Extracts seams for dependency injection before behavioral changes |
| Small classes/methods | `investigate-bug` | Extracts classes and methods at seams for testability |

---

## See Also

- [`uncle-bob.md`](uncle-bob.md) — Martin's Clean Code and SOLID origins
- [`fowler.md`](fowler.md) — Fowler's refactoring catalog
- [`feathers.md`](feathers.md) — Feathers' seams and characterization tests
- [`kent-beck.md`](kent-beck.md) — Beck's TDD (the testing foundation Metz builds on)
