import test from "node:test";
import assert from "node:assert";
import { getProductById, searchProducts } from "../src/catalog.js";

test("anonymous cannot get customer-tier or vip-tier products by ID", () => {
  assert.throws(
    () => getProductById("PROD-2", "anonymous"),
    { message: "product not found: PROD-2" }
  );
  assert.throws(
    () => getProductById("PROD-3", "anonymous"),
    { message: "product not found: PROD-3" }
  );
});

test("anti-oracle: getting restricted product throws 'not found', never 'forbidden'", () => {
  // Staff product requested by VIP: must say 'product not found'
  assert.throws(
    () => getProductById("PROD-4", "vip"),
    { message: "product not found: PROD-4" }
  );
});

test("vip role can view VIP and customer items", () => {
  const vipProd = getProductById("PROD-3", "vip");
  assert.strictEqual(vipProd.id, "PROD-3");
  assert.strictEqual(vipProd.name, "Gold Espresso Machine");

  const custProd = getProductById("PROD-2", "vip");
  assert.strictEqual(custProd.id, "PROD-2");
});

test("negative tag override: discontinued items are hidden from customers and VIPs", () => {
  // PROD-5 has minRole: customer, but tag: discontinued
  assert.throws(
    () => getProductById("PROD-5", "customer"),
    { message: "product not found: PROD-5" }
  );
  assert.throws(
    () => getProductById("PROD-5", "vip"),
    { message: "product not found: PROD-5" }
  );

  // Internal role can see discontinued item
  const prod = getProductById("PROD-5", "internal");
  assert.strictEqual(prod.id, "PROD-5");
});

test("search facets reflect only visible items for requesting role", () => {
  // Anonymous search in kitchen: only PROD-1 is visible
  const anonRes = searchProducts("", "kitchen", "anonymous");
  assert.strictEqual(anonRes.total, 1);
  assert.strictEqual(anonRes.facets.kitchen, 1);
  assert.strictEqual(anonRes.items[0].id, "PROD-1");

  // VIP search in kitchen: PROD-1, PROD-2, PROD-3 are visible (PROD-5 is discontinued)
  const vipRes = searchProducts("", "kitchen", "vip");
  assert.strictEqual(vipRes.total, 3);
  assert.strictEqual(vipRes.facets.kitchen, 3);

  // Internal search in kitchen: all 4 kitchen items visible (including discontinued)
  const staffRes = searchProducts("", "kitchen", "internal");
  assert.strictEqual(staffRes.total, 4);
  assert.strictEqual(staffRes.facets.kitchen, 4);
});
