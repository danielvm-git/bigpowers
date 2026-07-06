# Martin Fowler: Refactoring and Code Smells

<!-- story: e35s02 -->

**Purpose:** Documents Martin Fowler's refactoring catalog and code-smell taxonomy — the shared vocabulary for improving code design without changing behavior — and how bigpowers skills embody these practices.

**Credit:** Martin Fowler. Key works: *Refactoring: Improving the Design of Existing Code* (1999, 2018), *Patterns of Enterprise Application Architecture* (2002).

---

## The Refactoring Catalog

Fowler cataloged dozens of named refactorings — small, behavior-preserving transformations that improve code structure. Each refactoring has a name, a motivation (the "why"), a mechanics section (the "how"), and examples. The catalog makes refactoring a teachable, repeatable skill instead of an intuitive art.

Key refactorings include:

| Refactoring | What it does |
|---|---|
| **Extract Method** | Pull a code fragment into a named method |
| **Inline Method** | Replace a method call with its body |
| **Move Method** | Move a method to the class where it's more relevant |
| **Extract Class** | Split a class doing too many things |
| **Replace Conditional with Polymorphism** | Replace type-based switch logic with subclasses |
| **Introduce Parameter Object** | Group related parameters into a single object |

---

## Code Smells

Fowler (building on Kent Beck's "smells" intuition) defined a taxonomy of code smells — surface indicators that point to deeper design problems. Each smell maps to one or more refactorings that address it.

| Smell | Problem signal | Refactoring |
|---|---|---|
| **Duplicated Code** | Same code structure in multiple places | Extract Method, Pull Up Method |
| **Long Method** | Method doing too many things | Extract Method |
| **Large Class** | Class with too many responsibilities | Extract Class |
| **Long Parameter List** | Methods with many parameters | Introduce Parameter Object |
| **Divergent Change** | One class changes for different reasons | Extract Class |
| **Shotgun Surgery** | One change touches many classes | Move Method, Move Field |
| **Feature Envy** | Method uses another class's data more than its own | Move Method |
| **Data Clumps** | Same group of fields appear together | Extract Class, Introduce Parameter Object |
| **Primitive Obsession** | Using primitives instead of small objects | Replace Data Value with Object |
| **Switch Statements** | Type-based conditional logic | Replace Conditional with Polymorphism |

---

## How bigpowers uses

| Fowler Concept | bigpowers Skill | How it's embodied |
|---|---|---|
| Extract Method | `plan-refactor` | Creates refactor plans with tiny commits, each a named refactoring |
| Code-smell taxonomy | `deepen-architecture` | Identifies deepening opportunities by detecting structural smells |
| Behavior-preserving transformations | `develop-tdd` | Red-green-refactor cycle ensures refactors don't change behavior |
| Extract Class / Move Method | `investigate-bug` | Uses seam identification and characterization tests for safe extraction |

---

## See Also

- [`kent-beck.md`](kent-beck.md) — Beck's TDD, XP, and Tidy First? (smells originated with Beck)
- [`feathers.md`](feathers.md) — Feathers' seams and characterization tests for legacy refactoring
- [`uncle-bob.md`](uncle-bob.md) — Martin's Clean Code and SOLID principles
- [`ousterhout.md`](ousterhout.md) — Ousterhout's deep modules philosophy
