// story: e45s26
// fixture: CWE-79 negative — MUST NOT be flagged (textContent auto-escapes)
function renderComment(el, userInput) {
  // SAFE: text-only assignment — no HTML parsing
  el.textContent = userInput;
}
