---
name: elaborate-spec
description: Refine a rough idea into a clear, detailed specification through dialogue. Does not produce code. Use when user has a vague idea, wants to think through a feature before planning, or needs to turn "I want X" into a concrete spec.
---

# Elaborate Spec

Turn a rough idea into a clear specification through focused dialogue. No code is written during this skill — the output is shared understanding and a refined problem statement.

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

### 3. Surface hidden assumptions

Once the user has answered the main questions, probe for assumptions:
- "You mentioned X — does that mean Y is also true?"
- "What happens when Z fails?"
- "Is this for internal users, external users, or both?"

### 4. Synthesize and confirm

Summarize your understanding in 3–5 bullet points:
- The problem
- The solution
- The key constraints
- The success criteria
- What's out of scope

Ask: "Is this an accurate summary? Anything missing or wrong?"

### 5. Suggest next skill

Once the spec is clear, recommend the next step:
- If domain model needs work → `model-domain`
- If ready to plan → `plan-release` then `plan-work` per story
- If a spike is needed first → `spike-prototype`
- If architecture decisions are needed → `deepen-architecture` or `grill-me`
- If the plan depends on a specific library or API → `grill-me` in docs mode
