
/**
 * Create a user object from input fields.
 *
 * @param {Object} input - User input fields
 * @param {string} input.name - User's name
 * @param {string} input.email - User's email
 * @returns {Object} User object with id, name, email, and createdAt
 */
function createUser(input) {
  if (!input || typeof input !== 'object') {
    throw new TypeError('input must be an object');
  }
  if (!input.name || typeof input.name !== 'string') {
    throw new TypeError('input.name must be a non-empty string');
  }
  if (!input.email || typeof input.email !== 'string') {
    throw new TypeError('input.email must be a non-empty string');
  }

  return {
    id: `user_${Date.now()}_${Math.random().toString(36).slice(2, 9)}`,
    name: input.name,
    email: input.email,
    createdAt: new Date().toISOString()
  };
}

module.exports = { createUser };
