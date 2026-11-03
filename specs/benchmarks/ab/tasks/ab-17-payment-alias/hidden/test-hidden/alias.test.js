import test from "node:test";
import assert from "node:assert";
import { getAccount, resetAccounts } from "../src/accounts.js";
import { registerAlias, listAliases, resetAliases } from "../src/alias.js";

test.beforeEach(() => {
  resetAccounts();
  resetAliases();
});

test("registers valid email alias and lowercases it", () => {
  const alias = registerAlias("ACC-001", "email", "Ana.Lima@Example.COM");
  assert.strictEqual(alias.accountId, "ACC-001");
  assert.strictEqual(alias.type, "email");
  assert.strictEqual(alias.key, "ana.lima@example.com");

  const list = listAliases("ACC-001");
  assert.strictEqual(list.length, 1);
  assert.strictEqual(list[0].key, "ana.lima@example.com");
});

test("registers valid E.164 phone alias", () => {
  const alias = registerAlias("ACC-001", "phone", "+5511987654321");
  assert.strictEqual(alias.key, "+5511987654321");
});

test("registers valid UUID EVP random key", () => {
  const alias = registerAlias("ACC-001", "evp", "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d");
  assert.strictEqual(alias.type, "evp");
});

test("validates valid CPF check digits and rejects invalid CPF", () => {
  // Valid CPF: 52998224725
  const alias = registerAlias("ACC-001", "cpf", "52998224725");
  assert.strictEqual(alias.key, "52998224725");

  // Invalid check digit: 52998224724
  assert.throws(
    () => registerAlias("ACC-001", "cpf", "52998224724"),
    { message: /invalid cpf key/ }
  );

  // Repeated digits: 11111111111
  assert.throws(
    () => registerAlias("ACC-001", "cpf", "11111111111"),
    { message: /invalid cpf key/ }
  );
});

test("enforces personal account limit of 5 aliases", () => {
  registerAlias("ACC-001", "email", "k1@example.com");
  registerAlias("ACC-001", "email", "k2@example.com");
  registerAlias("ACC-001", "email", "k3@example.com");
  registerAlias("ACC-001", "email", "k4@example.com");
  registerAlias("ACC-001", "email", "k5@example.com");

  assert.throws(
    () => registerAlias("ACC-001", "email", "k6@example.com"),
    { message: /account quota exceeded/ }
  );
});

test("enforces business account allows more than 5 aliases", () => {
  for (let i = 1; i <= 6; i++) {
    registerAlias("ACC-002", "email", `biz${i}@tech.com`);
  }
  assert.strictEqual(listAliases("ACC-002").length, 6);
});

test("rejects duplicate alias across accounts", () => {
  registerAlias("ACC-001", "email", "shared@example.com");

  assert.throws(
    () => registerAlias("ACC-002", "email", "shared@example.com"),
    { message: /alias already registered/ }
  );
});
