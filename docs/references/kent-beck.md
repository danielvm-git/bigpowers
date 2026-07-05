# Kent Beck: XP, TDD, and Tidy First?

**Purpose:** Documents the intellectual origins Kent Beck contributed to software engineering — Extreme Programming (XP), Test-Driven Development (TDD / red-green-refactor), and the "Tidy First?" structural-change discipline — and how bigpowers skills embody these practices.

**Credit:** Kent Beck. Key works: *Extreme Programming Explained* (1999, 2004), *Test-Driven Development: By Example* (2002), *Tidy First?* (2023).

---

## Extreme Programming (XP)

Kent Beck created XP in the late 1990s as a lightweight, disciplined methodology. Its core practices — pair programming, continuous integration, small releases, simple design, and test-first programming — were radical departures from heavyweight waterfall processes. XP demonstrated that fast feedback loops, customer collaboration, and engineering discipline could coexist.

---

## Test-Driven Development (TDD)

TDD is the practice of writing a failing test before writing the production code that makes it pass, then refactoring both. The canonical cycle:

1. **Red** — Write a failing test that expresses the desired behavior.
2. **Green** — Write the minimum code to make the test pass.
3. **Refactor** — Improve the code's design while keeping the tests green.

Beck formalized TDD in *Test-Driven Development: By Example* (2002), demonstrating the pattern across money arithmetic, xUnit frameworks, and real-world patterns. The discipline ensures every line of production code exists to satisfy a test, reducing accidental complexity and providing a regression safety net.

---

## Tidy First? (2023)

Beck's later work addresses a persistent question: *when* should you refactor? "Tidy First?" argues that structural changes (renames, extractions, interface improvements) should be made *before* behavioral changes (new features, bug fixes), but only when the tidy pays for itself in reduced cognitive load for the upcoming behavioral work. If tidying doesn't have an immediate payoff, skip it.

Key distinctions:

| Change Type | Example | When to do it |
|---|---|---|
| **Structural (tidy)** | Rename variable, extract method, split module | Before behavioral work, if it reduces the cost of that work |
| **Behavioral** | Add feature, fix bug, change business rule | After (or independently of) tidying |

Beck's "coherent small steps" principle carries through: each tidy should be its own commit, separately reviewable.

---

## How bigpowers uses

| Beck Concept | bigpowers Skill | How it's embodied |
|---|---|---|
| Red-Green-Refactor | `develop-tdd` | Mandates red-green per task cycle with explicit refactor step |
| Tidy First? | `plan-refactor` | Creates a refactor plan before behavioral changes, with tiny commits |
| XP small releases | `release-branch` | Encodes small, reviewable feature branches |
| Fast feedback | `enforce-first` | Validates F.I.R.S.T criteria on every test suite before acceptance |
| Coherent small steps | `deepen-architecture` | Identifies deepening opportunities informed by tidy-first discipline |

---

## See Also

- [`uncle-bob.md`](uncle-bob.md) — Robert C. Martin's Clean Code and SOLID principles
- [`fowler.md`](fowler.md) — Martin Fowler's refactoring catalog and code smells
- [`feathers.md`](feathers.md) — Michael Feathers' Working Effectively with Legacy Code
- [`tdd.md`](tdd.md) — TDD reference (operational how-to)
- [`pragmatic-programmer.md`](pragmatic-programmer.md) — Hunt & Thomas' pragmatic practices
