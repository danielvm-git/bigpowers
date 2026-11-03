import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { parsePost } from "./frontmatter.js";
import { toHtml } from "./markdown.js";
import { escapeHtml, render } from "./template.js";

const TEMPLATES = path.join(path.dirname(fileURLToPath(import.meta.url)), "../templates");

// Builds the site: index.html and posts/<slug>.html from contentDir/*.md. Drafts are skipped.
// Returns the written paths, relative to outDir.
export function build({ contentDir, outDir, site }) {
  const posts = loadPosts(contentDir);
  const written = [];
  const write = (rel, html) => {
    fs.mkdirSync(path.dirname(path.join(outDir, rel)), { recursive: true });
    fs.writeFileSync(path.join(outDir, rel), html);
    written.push(rel);
  };
  const page = template("page.html");
  for (const post of posts) {
    write(`posts/${post.slug}.html`, render(page, {
      siteTitle: site.title, title: post.title, date: post.date,
      tags: post.tags.length ? `<p class="tags">Tags: ${escapeHtml(post.tags.join(", "))}</p>` : "",
      body: toHtml(post.body),
    }));
  }
  const items = posts.map((p) =>
    `<li><a href="posts/${p.slug}.html">${escapeHtml(p.title)}</a> <time>${p.date}</time></li>`).join("\n");
  write("index.html", render(template("index.html"), { siteTitle: site.title, items }));
  return written;
}

// Published posts, newest first; posts on the same date sort by title.
export function loadPosts(contentDir) {
  return fs.readdirSync(contentDir)
    .filter((f) => f.endsWith(".md"))
    .map((f) => ({ slug: f.slice(0, -3), ...parsePost(fs.readFileSync(path.join(contentDir, f), "utf8")) }))
    .filter((p) => !p.draft)
    .sort((a, b) => (a.date === b.date ? a.title.localeCompare(b.title) : a.date < b.date ? 1 : -1));
}

export function template(name) {
  return fs.readFileSync(path.join(TEMPLATES, name), "utf8");
}
