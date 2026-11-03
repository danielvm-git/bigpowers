import test from "node:test";
import assert from "node:assert";
import { getItem, createItem, updateStock, resetInventory } from "../src/inventory.js";

test.beforeEach(() => {
  resetInventory();
});

test("gets an existing item with stock and available counts", () => {
  const item = getItem("ITEM-101");
  assert.strictEqual(item.id, "ITEM-101");
  assert.strictEqual(item.stock, 10);
  assert.strictEqual(item.available, 10);
});

test("throws error when getting non-existent item", () => {
  assert.throws(() => getItem("UNKNOWN"), { message: "item not found: UNKNOWN" });
});

test("creates a new item", () => {
  const item = createItem("ITEM-999", "Desk Mat", 15);
  assert.strictEqual(item.id, "ITEM-999");
  assert.strictEqual(item.stock, 15);
  assert.strictEqual(item.available, 15);
});

test("updates stock by delta", () => {
  const item = updateStock("ITEM-102", 3);
  assert.strictEqual(item.stock, 8);
  assert.strictEqual(item.available, 8);
});
