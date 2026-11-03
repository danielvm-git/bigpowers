export function escapeHtml(text) {
  return String(text).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
}

// {{name}} inserts an escaped value, {{{name}}} inserts raw HTML.
export function render(template, vars) {
  return template
    .replace(/\{\{\{(\w+)\}\}\}/g, (_, k) => String(vars[k] ?? ""))
    .replace(/\{\{(\w+)\}\}/g, (_, k) => escapeHtml(vars[k] ?? ""));
}
