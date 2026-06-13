# Code Review: Checklist & Clean Code Heuristics

**Purpose:** Document code review standards and Clean Code heuristics for consistent quality assessment.

---

## Request-Review Checklist

### Functional Correctness
- [ ] Does the code implement the spec (from specs/epics/eNN-*.yaml)?
- [ ] Do all verify: commands pass?
- [ ] Are there edge cases not handled?
- [ ] Are there new risks introduced?

### Design & Architecture
- [ ] Does the code follow existing patterns?
- [ ] Is the module size reasonable (<300 lines)?
- [ ] Is the function size reasonable (4-20 lines)?
- [ ] Are dependencies minimal (Low coupling)?
- [ ] Is cohesion high (Related behavior together)?

### Code Quality (CONVENTIONS.md)
- [ ] No commented-out code (C5)
- [ ] No dead code (G9, F4)
- [ ] No `any` types (T2)
- [ ] Names are specific (Grep returns <5 results)
- [ ] Names are pronounceable
- [ ] Comments explain WHY, not WHAT

### Testing (F.I.R.S.T)
- [ ] Are tests Fast (complete in <10 seconds)?
- [ ] Are tests Independent (no ordering)?
- [ ] Are tests Repeatable (any environment)?
- [ ] Are tests Self-Validating (PASS/FAIL clear)?
- [ ] Are tests written Timely (TDD)?
- [ ] Is coverage ≥95%?

### Security
- [ ] No hardcoded secrets
- [ ] All auth uses strong algorithms
- [ ] SQL queries are parameterized
- [ ] Shell commands use execFile (not exec)
- [ ] Dependencies have slopcheck verdicts

### Boy Scout Rule
- [ ] Every touched file is cleaner than before
- [ ] No gratuitous refactoring (surgical only)

---

## Clean Code Heuristics (Chapter 17)

### G-Series: General

| Heuristic | Example | Fix |
|-----------|---------|-----|
| **G1: Multiple Languages** | Java + XML in one file | Separate concerns |
| **G2: Obvious Behavior** | Surprising side effects | Make intent clear |
| **G3: Boundary Conditions** | Off-by-one errors | Test edges |
| **G4: Overridden Safeties** | catch (Exception e) {} | Never swallow exceptions |
| **G5: Duplication** | Same logic copied 3x | Extract method (DRY) |
| **G6: Code at Wrong Level** | Config logic in domain code | Move to appropriate layer |
| **G7: Feature Envy** | Method calls many methods on other object | Move logic to that object |
| **G8: Dead Code** | Unreachable branches | Delete it |
| **G9: Vertical Separation** | Variable declared far from use | Declare near use |
| **G10: Inconsistency** | Inconsistent naming/formatting | Standardize |
| **G11: Clutter** | Unused variables, empty methods | Remove |
| **G12: Artificial Coupling** | Constants shared globally | Keep local |
| **G13: Feature Envy** | Method uses another class excessively | Move to that class |
| **G14: Selector Arguments** | if (flag) do X else do Y | Split into two methods |
| **G15: Obscured Intent** | Comments needed to understand | Refactor for clarity |
| **G16: Hidden Dependencies** | Magic numbers, implicit assumptions | Make explicit |
| **G17: Misplaced Responsibility** | Logic in wrong class | Move to right class |
| **G18: Inappropriate Static** | Utility functions as static methods | Use instances |
| **G19: Use Polymorphism** | Long if-else chains | Use polymorphism |
| **G20: Follow Conventions** | Different style from codebase | Match existing |
| **G21: Encapsulation** | Public fields exposed | Use getters/setters |
| **G22: Base Classes Depend on Derived** | Parent knows about children | Invert dependency |
| **G23: Too Much Information** | Classes with many public methods | Hide implementation |
| **G24: Dead Code** | Commented-out code blocks | Delete |
| **G25: Vertical Distance** | Related methods far apart | Keep together |
| **G26: Consistency** | Inconsistent usage patterns | Standardize |
| **G27: Boundary Conditions** | Off-by-one, edge cases | Test thoroughly |
| **G28: Conditions** | Negative conditions (`!isValid`) | Use positive (`isValid`) |
| **G29: Guard Clauses** | Deep nesting | Use early returns |
| **G30: Temporal Coupling** | Order dependency undocumented | Document or refactor |

---

## Function-Level Review (4-20 Line Rule)

**Question:** Is the function small enough to fit in a code review pane without scrolling?

```javascript
// ❌ BAD: 50 lines, needs scrolling
function processUser(data, config, db, logger) {
  // ... 50 lines of logic
}

// ✅ GOOD: 8 lines, one responsibility
function processUser(data, config, db, logger) {
  validateInput(data);
  const user = mapToModel(data);
  const saved = persistUser(user, db);
  logSuccess(saved, logger);
  return saved;
}
```

---

## Quality Score Calculation (request-review)

**Formula:** `100 × (total_items − must_fix − should_fix) / total_items`

**Categories:**
- **Must Fix (blocks merge):** Functional bug, security hole, architectural violation
- **Should Fix (nice-to-have):** Style issue, minor inefficiency, test coverage gap
- **Nice-to-Have (documentation):** Comment clarity, naming, explanation

**Example:**
```
Total items reviewed: 20
Must fix: 1 (hardcoded API key)
Should fix: 2 (naming inconsistency, test coverage gap)

Score: 100 × (20 − 1 − 2) / 20 = 100 × 17/20 = 85%

Threshold: 94% required → This fails, must fix the API key
```

**Thresholds:**
- 94-100%: APPROVED (merge ready)
- 90-93%: CONDITIONAL (fix should-fix items)
- <90%: REJECTED (fix must-fix items)

---

## Heuristic Lookup Table

| Code Smell | Heuristic | Fix |
|------------|-----------|-----|
| Function 50+ lines | G23 (Too Much Info) | Break into smaller functions |
| Commented-out code | C5, G24 (Dead Code) | Delete it |
| Magic numbers | G16 (Hidden Dependencies) | Extract named constant |
| Deep nesting | G29 (Guard Clauses) | Use early returns |
| Negative conditions | G28 (Conditions) | Use positive logic |
| Copy-pasted code | G5 (Duplication) | Extract method |
| `catch (Exception e) {}` | G4 (Overridden Safeties) | Never swallow exceptions |
| Inconsistent naming | G10 (Inconsistency) | Standardize |
| Comments explaining code | G15 (Obscured Intent) | Refactor for clarity |
| Long parameter lists | G14 (Selector Arguments) | Use objects, split methods |

---

## Review Workflow in Bigpowers

1. **Coder:** Runs `audit-code` (self-review)
2. **Coder:** Submits code to `request-review` (independent review)
3. **Reviewer:** Uses this checklist + heuristics
4. **Reviewer:** Computes quality score
5. **Score ≥94%?** Approve, merge  
6. **Score <94%?** Return to coder via `respond-review`
7. **Coder:** Fixes issues, re-submits

---

## See Also

- audit-code (SKILL.md) — Self-review checklist
- request-review (SKILL.md) — Independent second opinion
- CONVENTIONS.md — Mandatory rules
- verify: cd /Users/danielvm/Developer/skills && npm run audit-code
