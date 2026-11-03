import test from "node:test";
import assert from "node:assert";
import { getProductById, searchProducts } from "../src/catalog.js";

test("finds public product by ID", () => {
  const prod = getProductById("PROD-1");
  assert.strictEqual(prod.id, "PROD-1");
  assert.strictEqual(prod.name, "Standard Mug");
});

test("searches products matching query", () => {
  const result = searchProducts("Mug");
  assert.strictEqual(result.total, 1);
  assert.strictEqual(result.items[0].id, "PROD-1");
});
