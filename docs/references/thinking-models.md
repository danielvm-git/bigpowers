# Thinking Models: Extended Thinking & Reasoning Patterns

**Purpose:** Document when and how to use extended thinking (Claude's long reasoning capability) vs. fast thinking.

---

## Two-System Model

### System 1: Fast Thinking
**Cost:** 25-50K tokens input  
**Speed:** <30 seconds  
**Quality:** 3.5-4.0/5.0  
**Best For:** Routine tasks with clear patterns

**Examples:**
- Code review for style issues
- Parsing function behavior
- Mapping requirements to code
- Running verify: commands

### System 2: Extended Thinking (Slow Thinking)
**Cost:** 100-150K tokens input  
**Speed:** 1-3 minutes  
**Quality:** 4.5-5.0/5.0  
**Best For:** Novel problems, ambiguity, complex reasoning

**Examples:**
- Architectural decisions
- Root cause analysis (RCA)
- Design alternatives evaluation
- Security threat modeling

---

## When to Enable Extended Thinking

### ✅ DO USE Extended Thinking for:

1. **Strategic Decisions**
   - "Which architecture: monolith vs. microservices?"
   - "How should we structure the database schema?"
   - Cost: Spend 2 minutes thinking → avoid 2 weeks of rework

2. **Root Cause Analysis (RCA)**
   - "Why is this test flaky?"
   - "Why does this race condition happen?"
   - Narrow investigation → precise fix

3. **Trade-off Evaluation**
   - "What are the tradeoffs between caching strategies?"
   - "Security vs. performance: where's the right balance?"
   - Explicit reasoning > implicit guessing

4. **Novel Problems (New to the Codebase)**
   - "How do we add multi-tenancy?"
   - "How do we migrate to a new framework?"
   - Unknown unknowns require deep thinking

5. **Security & Compliance**
   - "Is this authentication flow secure?"
   - "What STRIDE threats apply here?"
   - Better to overspend tokens than ship a breach

### ❌ DON'T USE Extended Thinking for:

1. **Routine Tasks**
   - "Format this code"
   - "Run the tests"
   - Overhead > benefit

2. **Well-Documented Paths**
   - "Add a new route following our pattern"
   - "Write a unit test like the others"
   - Patterns are proven; no new thinking needed

3. **Parsing/Reading Code**
   - "What does this function do?"
   - "List the API endpoints"
   - Fast thinking sufficient

4. **Mechanical Transformations**
   - "Rename this variable"
   - "Add type annotations"
   - No thinking needed

---

## Extended Thinking Integration in Bigpowers

### In Elaborate-Spec (Phase 2)
```yaml
elaborate-spec:
  model: opus
  token_budget: 250000
  use_extended_thinking: true  # Strategic decisions need deep reasoning
  reasoning_time: 2-3 minutes
```

**Rationale:** Design decisions locked in Elaborate should be bulletproof

### In Assess-Impact (Phase 3)
```yaml
assess-impact:
  model: sonnet
  token_budget: 200000
  use_extended_thinking: true  # Trade-offs need explicit reasoning
  reasoning_time: 1-2 minutes
```

**Rationale:** Blast radius assessment benefits from thorough analysis

### In Investigate-Bug (Verify Phase)
```yaml
investigate-bug:
  model: sonnet
  token_budget: 200000
  use_extended_thinking: true  # RCA requires deep analysis
  reasoning_time: 2-5 minutes
```

**Rationale:** Find root cause once; avoid recurring bugs

### In Request-Review (Verify Phase)
```yaml
request-review:
  model: opus
  token_budget: 250000
  use_extended_thinking: false  # Code review is mostly pattern matching
  reasoning_time: <1 minute
```

**Rationale:** Quality checklist is well-defined; no strategic thinking needed

---

## Reasoning Budget

### Typical Project (Bigpowers 2.0)

| Phase | Skill | System | Tokens | Time |
|-------|-------|--------|--------|------|
| Discover | survey-context | 1 (Fast) | 100K | 30s |
| Discover | grill-me | 1 (Fast) | 200K | 1m |
| Elaborate | elaborate-spec | 2 (Thinking) | 150K | 2m |
| Plan | plan-work | 2 (Thinking) | 150K | 2m |
| Plan | assess-impact | 2 (Thinking) | 100K | 1m |
| Build | develop-tdd | 1 (Fast) | 200K | 3m |
| Verify | investigate-bug | 2 (Thinking) | 150K | 2m |
| Verify | request-review | 1 (Fast) | 200K | 2m |
| | **TOTAL** | | **1.15M** | **14m** |

**Token Cost Breakdown:**
- Fast thinking (System 1): 700K tokens × cost/model = ~$5
- Extended thinking (System 2): 450K tokens × cost/model = ~$12
- **Total project cost: ~$17** (vs. $25 without strategic thinking)

---

## Usage Example: RCA with Extended Thinking

**Without Extended Thinking:**
```
investigate-bug finds:
  ❌ Test flakes randomly
  → "Looks like race condition"
  → "Let's add a sleep(100ms)"
  → Flakiness reduced but not eliminated
  → Week of debugging ahead
```

**With Extended Thinking:**
```
investigate-bug with extended thinking:
  ✓ Deep analysis: "Why does race condition occur?"
    - Shared state between tests
    - Timing-dependent assertions
    - Missing synchronization primitive
  ✓ Root cause: "Semaphore never reset between tests"
  ✓ Fix: "Reset semaphore in beforeEach()"
  ✓ Verify: "Test runs 100x, zero flakes"
  → 5-minute deep thinking vs. 1-week of guessing
```

---

## When Model Escalates

**Escalation Rules:**

| Scenario | Current Model | Escalate To | Thinking |
|----------|---------------|-------------|----------|
| Task seems routine but hits novel problem | Haiku | Sonnet | + Extended |
| Sonnet unsure of design implications | Sonnet | Opus | + Extended |
| Reviewer finds security concern | Haiku | Opus | + Extended |
| RCA stuck after 2 hypotheses | Sonnet | Opus | + Extended |

---

## See Also

- model-profiles.md — Which model for each skill?
- orchestration.md — Where does thinking happen in 6 phases?
- elaborate-spec (SKILL.md) — Design decisions that need thinking
- investigate-bug (SKILL.md) — RCA workflow
- verify: grep -r "use_extended_thinking:" specs/ | wc -l
