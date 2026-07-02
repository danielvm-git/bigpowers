# Good and Bad Tests

## Good Tests

**Integration-style**: Test through real interfaces, not mocks of internal parts.

```typescript
// GOOD: Tests observable behavior
test("user can checkout with valid cart", async () => {
  const cart = createCart();
  cart.add(product);
  const result = await checkout(cart, paymentMethod);
  expect(result.status).toBe("confirmed");
});
```

Characteristics:

- Tests behavior users/callers care about
- Uses public API only
- Survives internal refactors
- Describes WHAT, not HOW
- One logical assertion per test

## Bad Tests

**Implementation-detail tests**: Coupled to internal structure.

```typescript
// BAD: Tests implementation details
test("checkout calls paymentService.process", async () => {
  const mockPayment = jest.mock(paymentService);
  await checkout(cart, payment);
  expect(mockPayment.process).toHaveBeenCalledWith(cart.total);
});
```

Red flags:

- Mocking internal collaborators
- Testing private methods
- Asserting on call counts/order
- Test breaks when refactoring without behavior change
- Test name describes HOW not WHAT
- Verifying through external means instead of interface

```typescript
// BAD: Bypasses interface to verify
test("createUser saves to database", async () => {
  await createUser({ name: "Alice" });
  const row = await db.query("SELECT * FROM users WHERE name = ?", ["Alice"]);
  expect(row).toBeDefined();
});

// GOOD: Verifies through interface
test("createUser makes user retrievable", async () => {
  const user = await createUser({ name: "Alice" });
  const retrieved = await getUser(user.id);
  expect(retrieved.name).toBe("Alice");
});
```

## Clean Test Heuristics (Uncle Bob, Ch 17)

Apply these specific heuristics to maintain a high-quality suite:

- **T1: Insufficient Tests**: A test suite should test everything that could possibly break. Don't stop at "it seems to work."
- **T4: Ignored Tests**: Never ignore a test without documenting the ambiguity. An ignored test is a silent warning of a gap in understanding.
- **T5: Test Boundary Conditions**: Most bugs happen at the edges. Test the exact boundaries (e.g., empty strings, max integers, off-by-one indices).
- **T6: Exhaustively Test Near Bugs**: Bugs congregate. If you find one, there are likely others nearby; test that area thoroughly.
- **T9: Tests Should Be Fast**: Slow tests don't get run. Keep them fast so they remain part of the core developer loop.
