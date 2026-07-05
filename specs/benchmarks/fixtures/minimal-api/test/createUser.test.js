// story: e42s02
// Happy-path test for createUser. Additional test files can be added by
// golden story agents — the node:test runner discovers all test/*.test.js files.

const test = require('node:test');
const assert = require('node:assert');
const { createUser } = require('../src/createUser.js');

test('createUser returns a user object with expected fields', () => {
  const input = { name: 'Alice', email: 'alice@example.com' };
  const user = createUser(input);

  assert.strictEqual(user.name, 'Alice');
  assert.strictEqual(user.email, 'alice@example.com');
  assert.ok(typeof user.id === 'string' && user.id.startsWith('user_'),
    'id should be a string starting with user_');
  assert.ok(typeof user.createdAt === 'string',
    'createdAt should be an ISO timestamp string');
});

test('createUser throws on missing name', () => {
  assert.throws(
    () => createUser({ email: 'a@b.c' }),
    { name: 'TypeError', message: /name/ }
  );
});

test('createUser throws on missing email', () => {
  assert.throws(
    () => createUser({ name: 'Bob' }),
    { name: 'TypeError', message: /email/ }
  );
});

test('createUser throws on non-object input', () => {
  assert.throws(
    () => createUser(null),
    { name: 'TypeError' }
  );
});
