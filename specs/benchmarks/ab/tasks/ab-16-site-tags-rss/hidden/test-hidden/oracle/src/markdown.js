import { escapeHtml } from "./template.js";

// A small Markdown subset: #, ## and ### headings, paragraphs, *em*, **strong** and `code`.
export function toHtml(markdown) {
  return blocks(markdown).map((block) => {
    const h = /^(#{1,3}) (.*)$/.exec(block);
    if (h) return `<h${h[1].length}>${inline(h[2])}</h${h[1].length}>`;
    return `<p>${inline(block.replace(/\n/g, " "))}</p>`;
  }).join("\n");
}

export function blocks(markdown) {
  return markdown.split(/\n\s*\n/).map((b) => b.trim()).filter(Boolean);
}

function inline(text) {
  return escapeHtml(text)
    .replace(/`([^`]+)`/g, "<code>$1</code>")
    .replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>")
    .replace(/\*([^*]+)\*/g, "<em>$1</em>");
}
