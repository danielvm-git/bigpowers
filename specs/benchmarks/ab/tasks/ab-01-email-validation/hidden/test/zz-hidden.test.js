const test = require('node:test');
const assert = require('node:assert');
const { createUser } = require('../src/createUser.js');

const invalid = ['bob', 'a@', '@b.co', 'a@b', 'a@b.', 'a@.co', 'a@@b.co', 'a@b..co', 'a b@c.co@d.co'];
const valid = ['a@b.co', 'first.last@sub.example.org', 'x+tag@mail.example.com'];

for (const email of invalid) {
  test(`hidden: rejects ${JSON.stringify(email)}`, () => {
    assert.throws(() => createUser({ name: 'A', email }), { name: 'TypeError', message: /email/i });
  });
}

for (const email of valid) {
  test(`hidden: accepts ${JSON.stringify(email)}`, () => {
    const user = createUser({ name: 'A', email });
    assert.strictEqual(user.email, email);
    assert.ok(user.id.startsWith('user_'));
  });
}

test('hidden: still rejects missing name', () => {
  assert.throws(() => createUser({ email: 'a@b.co' }), { name: 'TypeError', message: /name/ });
});
