const test = require('node:test');
const assert = require('node:assert');
const { cartTotal } = require('../src/cart.js');

test('sums whole-number prices', () => {
  assert.strictEqual(cartTotal([{ price: 10, qty: 2 }, { price: 5, qty: 1 }]), 25);
});

test('applies a percentage discount', () => {
  assert.strictEqual(cartTotal([{ price: 10, qty: 2 }], 50), 10);
});

test('empty cart costs nothing', () => {
  assert.strictEqual(cartTotal([]), 0);
});
