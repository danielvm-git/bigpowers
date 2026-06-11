
# Elaborate Spec

Turn a rough idea into a clear specification through focused dialogue. No code is written during this skill — the output is shared understanding and a refined problem statement.

> **HARD GATE** — Do NOT proceed with planning or implementation until the problem space is clearly understood. Success criteria, actors, and scope must be explicit before drafting a plan.

## Process

### 1. Listen first

Let the user describe their idea in their own words. Do not interrupt or redirect. Take notes on:
- The core problem they're trying to solve
- Who is affected (actors)
- What success looks like to them
- Any constraints they've already identified

### 2. Ask clarifying questions

Ask one question at a time. Work through these areas:

**Problem clarity**
- What is the current behavior (or lack of behavior) that prompted this?
- Who experiences this problem? How often?
- What's the cost of not solving it?

**Solution boundaries**
- What is explicitly IN scope?
- What is explicitly OUT of scope?
- Are there existing solutions (internal or external) this replaces or integrates with?

**Success criteria**
- How will you know this is done?
- What does the happy path look like end-to-end?
- What are the key failure modes to handle?

**Constraints**
- Any performance requirements?
- Any compatibility constraints (existing APIs, data formats)?
- Any non-negotiable implementation decisions already made?

### 2.5. Multiple Interpretations (HARD GATE)

> **HARD GATE** — If the request admits ≥2 valid interpretations, do NOT guess. You must list them and ask the user to choose before proceeding. Proceeding with unresolved ambiguity is a failure of integrity.

Present the options clearly:
> "I see two ways to read this:
> 1. [Interpretation A] — my recommendation because [reason]
> 2. [Interpretation B]
> Which is closer to what you mean?"

### 3. Surface hidden assumptions

Once the user has answered the main questions, probe for assumptions:
- "You mentioned X — does that mean Y is also true?"
- "What happens when Z fails?"
- "Is this for internal users, external users, or both?"

### 4. Synthesize and confirm

Summarize your understanding in 3–5 bullet points aligned with [countable-story-format.md](file:///Users/danielvm/Developer/bigpowers/countable-story-format.md):
- The problem (feeds into §1 Business narrative)
- The solution and main flow (feeds into §5)
- The key constraints and alternative flows (feeds into §6)
- The success criteria (feeds into §17 Gherkin)
- What's out of scope (feeds into §18)

Ask: "Is this an accurate summary? Anything missing or wrong?"

### 5. Suggest next skill

Once the spec is clear, recommend the next step:
- If domain model needs work → `model-domain`
- If ready to plan → `plan-release` (creates epic capsules with `epic.yaml` + story `.md` + `-tasks.yaml`) then `plan-work` per story
- If a spike is needed first → `spike-prototype`
- If architecture decisions are needed → `deepen-architecture` or `grill-me`
- If the plan depends on a specific library or API → `grill-me` in docs mode
