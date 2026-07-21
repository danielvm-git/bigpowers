<!-- wayfinder resolution artifact — T10 (glossary-collision), closed -->
<!-- This is the CONSUMER APP's own domain glossary — never bigpowers' own jargon (BCP, WSJF,
     OKF, epic, story...). That vocabulary is bigpowers-about-itself and stays out of every
     project this template is used for, same rule as the skill catalog (T4 ruling #1).
     GLOSSARY_LATEST.yaml (BCP/WSJF/OKF) is bigpowers' OWN instance of this exact template,
     applied to its own domain (software methodology) — not a second, separate glossary kind. -->
<!-- Composed from: define-language skill's existing output contract (richer than TGDP's flat
     table — expresses relationships, aliases-to-avoid, and a worked dialogue) + TGDP glossary/
     pack's {source} and cross-reference field, kept from GLOSSARY_LATEST.yaml's `related_terms`. -->

---
okf_kind: glossary
okf_version: "1.0"
generated_by: "skill:define-language"
generated_at: {YYYY-MM-DDTHH:MM:SSZ}
---

# Glossary — {Project Name}

{One-line intro: what domain this glossary covers and who it's for.}

## {Domain area 1 — e.g. "Order lifecycle"}

| Term | Definition | Aliases to avoid | Related terms |
|------|------------|-------------------|----------------|
| **{Term}** | {One sentence. What it IS, not what it does.} | {Synonyms this project deliberately avoids} | {[[cross-linked terms]]} |

{Group terms into multiple tables by natural domain cluster. One table is fine if terms are cohesive.}

## Relationships

- A **{Term}** {relationship verb, with cardinality} a **{Term}**.

## Example dialogue

{3–5 exchanges between a contributor and a domain expert, using terms precisely — this is what
makes ambiguity visible before it becomes a bug.}

> **Dev:** "{question using a term}"
> **Domain expert:** "{answer that sharpens or corrects the term's boundary}"

## Flagged ambiguities

{Terms that were used inconsistently before this glossary existed, and the resolution chosen.
Omit this section once resolved for a release; keep it during active domain modeling.}

- "{word}" was used to mean both **{Term A}** and **{Term B}** — these are distinct concepts.

---

{This glossary evolves with the domain model. Re-run whenever new terms surface in planning or
implementation — see the domain-modeling skill this template is generated from.}
