---
description: Extract a DDD-style ubiquitous language glossary from the current conversation, flagging ambiguities and proposing canonical terms. Saves to specs/UBIQUITOUS_LANGUAGE_LATEST.md. Use when user wants to define domain terms, build a glossary, harden terminology, create a ubiquitous language, or mentions "domain model" or "DDD".
---


# Define Language

Extract and formalize domain terminology from the current conversation into a consistent glossary, saved to `specs/UBIQUITOUS_LANGUAGE_LATEST.md`.

**Distinct from `model-domain` and `deepen-architecture`:** Use this skill to produce a canonical glossary of terms (words and definitions). Use `model-domain` to stress-test a plan through an interview that resolves domain model decisions. Use `deepen-architecture` to find module-level refactoring opportunities in the codebase.

> **HARD GATE** — Ubiquitous language is NOT optional. Every term in the domain that could be misunderstood must be glossed. Ambiguity = rework.

## Process

1. **Scan the conversation** for domain-relevant nouns, verbs, and concepts
2. **Identify problems**:
   - Same word used for different concepts (ambiguity)
   - Different words used for the same concept (synonyms)
   - Vague or overloaded terms
3. **Propose a canonical glossary** with opinionated term choices
4. **Write to `specs/UBIQUITOUS_LANGUAGE_LATEST.md`** in the working directory using the format below
5. **Output a summary** inline in the conversation

## Output Format

Write a `specs/UBIQUITOUS_LANGUAGE_LATEST.md` file with this structure:

```md
# Ubiquitous Language

## Order lifecycle

| Term        | Definition                                              | Aliases to avoid      |
| ----------- | ------------------------------------------------------- | --------------------- |
| **Order**   | A customer's request to purchase one or more items      | Purchase, transaction |
| **Invoice** | A request for payment sent to a customer after delivery | Bill, payment request |

## People

| Term         | Definition                                  | Aliases to avoid       |
| ------------ | ------------------------------------------- | ---------------------- |
| **Customer** | A person or organization that places orders | Client, buyer, account |
| **User**     | An authentication identity in the system    | Login, account         |

## Relationships

- An **Invoice** belongs to exactly one **Customer**
- An **Order** produces one or more **Invoices**

## Example dialogue

> **Dev:** "When a **Customer** places an **Order**, do we create the **Invoice** immediately?"
> **Domain expert:** "No — an **Invoice** is only generated once a **Fulfillment** is confirmed."

## Flagged ambiguities

- "account" was used to mean both **Customer** and **User** — these are distinct concepts.
```

## Rules

- **Be opinionated.** When multiple words exist for the same concept, pick the best one and list the others as aliases to avoid.
- **Flag conflicts explicitly.** If a term is used ambiguously, call it out in "Flagged ambiguities" with a clear recommendation.
- **Only include terms relevant for domain experts.** Skip names of modules or classes unless they have domain meaning.
- **Keep definitions tight.** One sentence max. Define what it IS, not what it does.
- **Show relationships.** Use bold term names and express cardinality where obvious.
- **Group terms into multiple tables** when natural clusters emerge. One table is fine if terms are cohesive.
- **Write an example dialogue.** 3–5 exchanges between a dev and domain expert showing terms used precisely.

## Re-running

When invoked again in the same conversation:

1. Read the existing `specs/UBIQUITOUS_LANGUAGE_LATEST.md`
2. Incorporate any new terms from subsequent discussion
3. Update definitions if understanding has evolved
4. Re-flag any new ambiguities
5. Rewrite the example dialogue to incorporate new terms
