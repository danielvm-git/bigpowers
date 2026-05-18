
# Grill with Docs

Like `grill-me`, but every challenge is grounded in real documentation. No assumption about a library's behavior goes unchecked.

**Why this matters:** AI agents hallucinate API methods, argument orders, and behaviors. This skill forces every assumption about external dependencies to be validated against the actual docs before code is written.

## Process

### 1. Identify the dependencies

From the plan or conversation, list:
- Every external library being used
- Every third-party API being called
- Every framework behavior being relied upon

Ask: "Which of these are you most confident about? Which are you less sure of?"

### 2. Fetch the relevant docs

For each dependency, fetch the actual documentation:

```
WebFetch the official docs for [library/API]
```

Prioritize:
- The API reference for the specific method being used
- The changelog for the version in use (breaking changes)
- Migration guides if upgrading from a previous version
- Known gotchas / FAQ sections

### 3. Challenge each assumption

For every assumption in the plan, find the corresponding doc section and ask:

- "Does the real API actually work this way? Show me the doc."
- "Is this method available in the version you're using?"
- "Does this argument order match the actual signature?"
- "Are there rate limits, quotas, or timeout behaviors that affect this design?"
- "Is this marked as deprecated in the current version?"

Ask one question at a time. For each challenge, cite the specific URL and section.

### 4. Surface hallucinations

When an assumption doesn't match the docs:

> "Your plan uses `library.doThing(a, b)` but the [docs](URL) show the signature is `doThing(config: {a, b})` with a config object. This will fail at runtime."

Document each discrepancy clearly.

### 5. Update the plan

For each confirmed discrepancy, recommend a concrete fix:
- Correct method signature
- Correct argument order
- Alternative approach that matches what the library actually supports
- Whether a spike (`spike-prototype`) is needed to validate a remaining uncertainty

### 6. Sign off

When all major assumptions have been validated against docs, report:
- Which assumptions were confirmed ✓
- Which were corrected ✗ + what the correct approach is
- Which remain uncertain → recommend `spike-prototype`
