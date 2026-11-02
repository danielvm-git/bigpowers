const test = require('node:test');
const assert = require('node:assert');
const { slugify } = require('../src/slugify.js');

test('lowercases and joins words with dashes', () => {
  assert.strictEqual(slugify('Hello World'), 'hello-world');
});

test('strips accents', () => {
  assert.strictEqual(slugify('Crème Brûlée'), 'creme-brulee');
});

test('trims and collapses whitespace', () => {
  assert.strictEqual(slugify('  Trim   me  '), 'trim-me');
});

test('drops punctuation', () => {
  assert.strictEqual(slugify('Rock & Roll!'), 'rock-roll');
});
