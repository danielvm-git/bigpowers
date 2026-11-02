const test = require('node:test');
const assert = require('node:assert');
const { slugify } = require('../src/slugify.js');

const cases = {
  'Hello World': 'hello-world',
  'Crème Brûlée': 'creme-brulee',
  '  Trim   me  ': 'trim-me',
  'Rock & Roll!': 'rock-roll',
  'Ça va?': 'ca-va',
  'Déjà Vu 2': 'deja-vu-2',
  'a -- b': 'a-b',
  '___x___': 'x',
  'Already-a-slug': 'already-a-slug',
};

for (const [input, expected] of Object.entries(cases)) {
  test(`hidden: ${JSON.stringify(input)} -> ${expected}`, () => {
    assert.strictEqual(slugify(input), expected);
  });
}
