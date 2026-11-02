const test = require('node:test');
const assert = require('node:assert');
const { cartTotal } = require('../src/cart.js');

test('hidden: reported case — 3 x 8.99 with 10% off', () => {
  assert.strictEqual(cartTotal([{ price: 8.99, qty: 3 }], 10), 24.27);
});

test('hidden: cents survive without a discount', () => {
  assert.strictEqual(cartTotal([{ price: 19.99, qty: 1 }, { price: 5.01, qty: 2 }]), 30.01);
});

test('hidden: float noise is rounded to cents', () => {
  assert.strictEqual(cartTotal([{ price: 0.1, qty: 3 }]), 0.3);
});

test('hidden: prices below 0.50 are not lost', () => {
  assert.strictEqual(cartTotal([{ price: 0.49, qty: 4 }]), 1.96);
});

test('hidden: whole-number behaviour unchanged', () => {
  assert.strictEqual(cartTotal([{ price: 10, qty: 2 }], 50), 10);
  assert.strictEqual(cartTotal([]), 0);
});
