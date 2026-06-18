---
name: map-codebase
description: "\"Derives the tech-stack doc from scratch by scanning the codebase — analyzes stack, architecture, and gray areas (error handling, API shapes) and persists findings into specs/tech-architecture/tech-stack.md. Run when the tech doc doesn't exist yet; use survey-context to consume it once it does.\""
model: sonnet
---


# Map Codebase

Perform a deep architectural and structural analysis of the codebase. Unlike `survey-context` which identifies "where we are", `map-codebase` identifies "what we are dealing with" and "how things are done".

> **Use this vs survey-context:** `map-codebase` BUILDS the tech-stack doc by scanning the codebase from scratch. `survey-context` READS existing specs/tech-architecture docs without re-deriving them. Run `map-codebase` when `specs/tech-architecture/tech-stack.md` doesn't exist yet; run `survey-context` when it does.

> **HARD GATE** — Cold analysis only. Do NOT assume architectural patterns without reading the code. If the codebase structure surprises you, call out the delta.

## Process

### 1. Identify Core Stack & Dependencies
- Scan `package.json`, `Cargo.toml`, `requirements.txt`, etc.
- Identify primary framework, runtime, and critical libraries (ORM, Auth, State, UI).
- Note version constraints and any deprecated or unusual dependencies.

### 2. Map High-Level Architecture
- Identify the entry points (CLI, Web, API).
- Map the primary data flow (e.g., Controller → Service → Repository).
- Identify where business logic lives vs. where I/O lives.
- Look for established patterns (e.g., hexagonal, layered, feature-folders).

### 3. Analyze "Gray Areas" (The "How")
Search for patterns and anti-patterns in these categories:
- **Error Handling:** Are exceptions caught early or bubbled? Is there a global error handler? Are error messages structured?
- **API Shapes:** Is it REST, GraphQL, or RPC? What is the casing (camelCase, snake_case)? How are responses structured?
- **Type Safety:** Is it strictly typed? Are there many `any` or `unsafe` blocks? Are interfaces used for DIP?
- **Observability:** Is there structured logging? Are there health checks? Where do logs go?
- **Testing:** What is the test coverage strategy? Are mocks used? Where do tests live?

### 4. Identify Planning "Signals"
Look for signals that will influence upcoming plans:
- **Consistency Gaps:** "Half the project uses async/await, the other half uses Promises."
- **Debt Hotspots:** "The `AuthManager` is 1500 lines and handles both JWT and session logic."
- **Integration Points:** "We need to talk to the Stripe API, but there's no wrapper yet."
- **Conventions:** "The team always uses functional components over classes."

### 5. Persist to specs/tech-architecture/tech-stack.md
Compile all findings into `specs/tech-architecture/tech-stack.md`. This file serves as the project's "Long-Term Memory".

```markdown
# Project Context

## Stack
- [Framework/Language]
- [Key Libraries]

## Architecture
- [Pattern Description]
- [Data Flow]

## Conventions (Observed)
- [Error Handling Pattern]
- [API Design]
- [Type System]

## Signals / Active Considerations
- [Gap 1]
- [Hotspot 2]
```

## When to Use
- When first joining a project.
- Before a major refactor or architectural change.
- When `survey-context` reveals a lack of domain knowledge.
- To refresh `specs/tech-architecture/tech-stack.md` after significant changes.
