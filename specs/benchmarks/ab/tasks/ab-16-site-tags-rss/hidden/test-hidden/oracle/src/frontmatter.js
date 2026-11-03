// Splits a post into front matter fields and the Markdown body.
// Front matter lines are `key: value`; `tags` is a comma-separated list; `draft` is true/false.
export function parsePost(text) {
  const m = /^---\n([\s\S]*?)\n---\n?([\s\S]*)$/.exec(text.replace(/\r\n/g, "\n"));
  if (!m) throw new Error("post has no front matter");
  const fields = {};
  for (const line of m[1].split("\n")) {
    const at = line.indexOf(":");
    if (at === -1) continue;
    fields[line.slice(0, at).trim()] = line.slice(at + 1).trim();
  }
  return {
    title: fields.title || "Untitled",
    date: fields.date,
    summary: fields.summary || null,
    tags: fields.tags ? fields.tags.split(",").map((t) => t.trim()).filter(Boolean) : [],
    draft: fields.draft === "true",
    body: m[2],
  };
}
