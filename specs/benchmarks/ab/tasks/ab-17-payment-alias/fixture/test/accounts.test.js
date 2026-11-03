import test from "node:test";
import assert from "node:assert";
import { getAccount, resetAccounts } from "../src/accounts.js";

test.beforeEach(() => {
  resetAccounts();
});

test("gets existing account by ID", () => {
  const acc = getAccount("ACC-001");
  assert.strictEqual(acc.id, "ACC-001");
  assert.strictEqual(acc.type, "personal");
});

test("throws error when account not found", () => {
  assert.throws(() => getAccount("NONEXISTENT"), { message: "account not found: NONEXISTENT" });
});
