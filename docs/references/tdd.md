# TDD Patterns: F.I.R.S.T Test Design & Integration

**Purpose:** Document Test-Driven Development patterns and F.I.R.S.T principles as they apply in Bigpowers orchestration.

---

## F.I.R.S.T: The Five Principles

### F — Fast
**Principle:** Tests run in milliseconds, not seconds  
**Why:** Feedback loop stays tight; developers run them constantly  
**Bigpowers Integration:** Every verify: command must complete in <10 seconds

**Check:**
```bash
# Time the verify command
time npm test -- UserService.test.ts
# Good: < 5 seconds
# Acceptable: < 10 seconds
# Bad: > 30 seconds (breaks flow)
```

### I — Independent
**Principle:** Tests don't depend on each other; no ordering required  
**Why:** Failures are isolated; easy to debug  
**Bigpowers Integration:** Each step in PLAN.md can run standalone

**Check:**
```bash
# Run tests in random order
npm test -- --randomize

# Bad: Test A fails if run after Test B
# Good: Tests pass in any order
```

### R — Repeatable
**Principle:** Tests pass consistently in any environment (local, CI, staging)  
**Why:** "Works on my machine" is not acceptable  
**Bigpowers Integration:** Every verify: command must work in CI/CD

**Check:**
```bash
# Test in fresh Docker container (represents CI)
docker run -it node:18 bash -c "git clone repo && npm test"
```

### S — Self-Validating
**Principle:** Tests have clear PASS/FAIL; no manual interpretation  
**Why:** Developers don't wonder "does this count as passing?"  
**Bigpowers Integration:** Every verify: command must produce exit code 0 or non-zero

**Check:**
```bash
# Good: Clear pass/fail
npm test && echo "✅ PASS" || echo "❌ FAIL"

# Bad: Ambiguous
npm test
# (requires human to read output and decide)
```

### T — Timely
**Principle:** Tests written before or during code (not after)  
**Why:** Coding against tests guides design  
**Bigpowers Integration:** TDD workflow: RED → GREEN → REFACTOR

**Check:**
```bash
# Red: Test fails before code
npm test  # ❌ FAIL (UserService not defined)

# Green: Minimal code to pass
# (write UserService with minimal implementation)
npm test  # ✅ PASS

# Refactor: Improve without breaking test
# (refactor UserService; re-run test)
npm test  # ✅ PASS (still)
```

---

## TDD Workflow in Bigpowers: RED → GREEN → REFACTOR

### Step 1: Write Failing Test (RED)

```typescript
// UserService.test.ts
describe('UserService', () => {
  it('should create a user with email and name', () => {
    const service = new UserService();
    const user = service.create({ email: 'a@b.com', name: 'Alice' });
    expect(user.email).toBe('a@b.com');
    expect(user.name).toBe('Alice');
  });
});
```

**Run:** `npm test -- UserService.test.ts`  
**Result:** ❌ FAIL (UserService not defined)

### Step 2: Write Minimal Code (GREEN)

```typescript
// UserService.ts
export class UserService {
  create(data: { email: string; name: string }) {
    return { id: 1, email: data.email, name: data.name };
  }
}
```

**Run:** `npm test -- UserService.test.ts`  
**Result:** ✅ PASS

### Step 3: Refactor (REFACTOR)

```typescript
// UserService.ts (improved)
export class UserService {
  private nextId = 1;

  create(data: { email: string; name: string }) {
    if (!data.email.includes('@')) {
      throw new Error('Invalid email');
    }
    return { id: this.nextId++, email: data.email, name: data.name };
  }
}
```

**Run:** `npm test -- UserService.test.ts`  
**Result:** ✅ PASS (tests still pass after improvement)

---

## Test Mandates (from v1.16.0)

### Mandate 1: T4 — No Ignored Tests Without Ambiguity Note

**Rule:** If you ignore a test, document WHY  
**Enforcement:** audit-code checklist item

```javascript
// ❌ BAD: No reason
it.skip('should handle concurrent requests', () => {
  // ...
});

// ✅ GOOD: Clear reason
it.skip('should handle concurrent requests', () => {
  // SKIPPED: Race condition in test harness (timing sensitive)
  // TODO: Fix flakiness via proper synchronization (GitHub issue #456)
  // ...
});
```

### Mandate 2: T5 — Boundary Conditions Must Be Tested

**Rule:** Test edges, not just happy paths  
**Enforcement:** develop-tdd checklist item

```javascript
// ❌ BAD: Only happy path
describe('UserService', () => {
  it('should create a user', () => {
    const user = service.create({ email: 'a@b.com', name: 'Alice' });
    expect(user).toBeDefined();
  });
});

// ✅ GOOD: Happy path + boundaries
describe('UserService', () => {
  it('should create a user with valid data', () => {
    const user = service.create({ email: 'a@b.com', name: 'Alice' });
    expect(user).toBeDefined();
  });

  it('should reject empty email', () => {
    expect(() => service.create({ email: '', name: 'Alice' })).toThrow();
  });

  it('should reject invalid email format', () => {
    expect(() => service.create({ email: 'not-an-email', name: 'Alice' })).toThrow();
  });

  it('should reject empty name', () => {
    expect(() => service.create({ email: 'a@b.com', name: '' })).toThrow();
  });

  it('should accept long names', () => {
    const longName = 'A'.repeat(500);
    const user = service.create({ email: 'a@b.com', name: longName });
    expect(user.name.length).toBe(500);
  });
});
```

### Mandate 3: T8 — Test Public Interfaces Only

**Rule:** Test behavior, not implementation  
**Enforcement:** audit-code checklist item

```javascript
// ❌ BAD: Testing internals
it('should set _isActive to true', () => {
  const user = new User('Alice');
  expect(user._isActive).toBe(true);
});

// ✅ GOOD: Testing behavior
it('should report that user is active', () => {
  const user = new User('Alice');
  expect(user.isActive()).toBe(true);
});
```

---

## Test Coverage Requirements

**Minimum:** ≥95% coverage for production code  
**Measured by:** npm test -- --coverage  
**Definition:** Lines, branches, functions, statements all ≥95%

```bash
verify: npm test -- --coverage --collectCoverageFrom='src/**/*.ts' && \
        npx nyc check-coverage --lines 95 --branches 95 --functions 95 --statements 95 && \
        echo "✅ Coverage ≥95%"
```

---

## Integration with Bigpowers Orchestration

### In Discover Phase
- No tests yet; just understand the domain

### In Elaborate Phase
- Discuss test strategy (which parts need tests, which don't)
- Lock decisions about mocking vs. integration tests

### In Plan Phase
- Plan includes test steps
- Every code step has a verify: npm test command

### In Build Phase (TDD Loop)
```
For each step:
  1. RED: Write failing test
  2. GREEN: Write minimal code to pass
  3. REFACTOR: Improve code
  4. VERIFY: Run full test suite
  5. Move to next step
```

### In Verify Phase
- Run full test suite
- Measure coverage
- Check all tests pass (no flakes)

---

## Common Anti-Patterns

### ❌ Mock Everything (Mockitis)

```javascript
// BAD: Mocking entire database
const mockDb = {
  query: jest.fn().mockResolvedValue([{ id: 1 }])
};

// Real world: Database behaves differently
// Test passes locally, fails in prod
```

**Fix:** Use test database (Docker-based)

### ❌ Big Test (Magic Assertion)

```javascript
// BAD: 100-line test that tests many things
it('should work', () => {
  // setup (50 lines)
  // action (20 lines)
  // 100 assertions checking everything
});

// When it fails, what broke? No idea.
```

**Fix:** One assertion per test (or one concept)

### ❌ Brittle Test (Implementation Detail)

```javascript
// BAD: Brittle to refactoring
expect(database.callCount).toBe(2);

// Good refactoring: Reduce to 1 call
// Test breaks even though behavior is better
```

**Fix:** Test behavior, not implementation

---

## See Also

- orchestration.md — Where does TDD fit in the 6-phase loop?
- develop-tdd (SKILL.md) — Test-first implementation skill
- verify: cd /Users/danielvm/Developer/skills && npm test -- --coverage 2>/dev/null | grep "Lines"
