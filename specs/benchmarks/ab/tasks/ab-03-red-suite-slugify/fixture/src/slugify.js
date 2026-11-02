/**
 * Turn a title into a URL slug.
 *
 * @param {string} title
 * @returns {string}
 */
function slugify(title) {
  return title.toLowerCase().replace(/\s+/g, '-');
}

module.exports = { slugify };
