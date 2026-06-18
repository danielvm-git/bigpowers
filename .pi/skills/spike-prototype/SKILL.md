---
name: spike-prototype
description: "Throw-away prototype for unknown problem spaces. Output is learning notes in specs/archive/spikes/SPIKE-<name>.md, not production code. Use when the domain or technology is unexplored, when estimates are impossible without experimentation, or when user says \"spike\", \"prototype\", or \"proof of concept\"."
model: sonnet
---


# Spike Prototype
> **HARD GATE** — **HARD GATE** — Spikes are time-boxed experiments, not shipping code. Results must be throwaway or clearly isolated. Do NOT merge a spike without a plan to integrate it or replace it with a proper implementation.


A spike is a time-boxed experiment to answer a specific question. The code is thrown away. The learning is kept in `specs/archive/spikes/SPIKE-<name>.md`.

**The spike produces learning, not code to ship.** If you find yourself cleaning up spike code for production, stop — run `plan-work` and `develop-tdd` instead with the insights you gained.

## When to spike

- The technology is unfamiliar (new library, API, infrastructure)
- The approach is uncertain (multiple solutions exist; none has been tried)
- Estimates are impossible without seeing how the thing actually behaves
- A key assumption needs to be validated before committing to a design

## Process

### 1. Define the question

Before writing a single line, state the question the spike must answer:

> "Can we [specific thing] using [specific approach] within [constraint]?"

Examples:
- "Can we stream large files from S3 to the client without buffering in memory?"
- "Does the Stripe webhook SDK handle signature verification correctly in our edge runtime?"
- "Can we achieve < 100ms p99 response time for the search endpoint with a naive Postgres full-text search?"

A spike with no question is just unplanned coding. Refuse to start if the question isn't clear.

### 2. Set a timebox

Agree on a timebox with the user: 30 minutes, 1 hour, 2 hours. When time is up, stop — even if the question isn't fully answered. Partial learning is still learning.

### 3. Experiment

Write the simplest code that could answer the question. Ignore:
- Error handling
- Test coverage
- Code quality
- Production concerns

Focus entirely on answering the question.

### 4. Write specs/archive/spikes/SPIKE-<name>.md

Save the learning to `specs/archive/spikes/SPIKE-<name>.md`. Create the `specs/` directory if it doesn't exist.

<spike-template>

# Spike: [name]

## Question

[The specific question this spike was answering]

## Result

[Answered / Partially answered / Not answered]

## Findings

[What you learned — concrete observations, not opinions]

## Evidence

[Code snippet, benchmark result, API response, or screenshot that proves the finding]

## Implications for the plan

[How this changes the approach, the design, or the estimate]

## What was NOT explored

[Known gaps — things the spike didn't validate]

## Recommendation

[Should we proceed with this approach? If yes, what does plan-work need to account for?]

</spike-template>

### 5. Delete the spike code

After writing the findings, delete or discard the spike code. It is not meant to ship.

### 6. Feed back into plan-work

The spike findings are the input to `plan-work`. Call `plan-work` next, informed by `specs/archive/spikes/SPIKE-<name>.md`.
