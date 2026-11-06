// story: e45s26
// fixture: CWE-79 positive — MUST be flagged as XSS
function renderComment(el, userInput) {
  // VULNERABLE: unsanitized HTML assignment
  el.innerHTML = userInput;
}
