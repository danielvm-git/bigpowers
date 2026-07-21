<!-- wayfinder:grilling -->
# T9 — changelog-vs-release-notes

**Type:** Grilling (HITL) · **Status:** CLOSED · **Claim:** driver
**Blocks:** collision #2 from T7's priority-ordered list · **Blocked by:** T7 (closed)

## Question

`changelog/` and `release-notes/` are both vendored TGDP packs. Do they collide, and if so,
which survives — one, both, or a composition?

## Resolution

**Not a real duplication — two different documents that currently collapse into one because
bigpowers has no curation practice.** Verified against both TGDP templates + live bigpowers state:

- **`changelog/template_changelog.md`** — every section says "if you build your changelog from
  Git commits, this is added automatically." Mechanical, commit-linked. This is exactly what
  semantic-release already produces. bigpowers' `CHANGELOG.md` fulfills this template's job today,
  verbatim, machine-owned — confirmed already documented as "never hand-edited"
  ([CONVENTIONS.md:230](../../../../CONVENTIONS.md)).
- **`release-notes/template_release-notes.md`** — no such generation language anywhere. Pure
  curated prose, with two sections a commit scraper can never produce: **"Known issues"** and
  **"features requiring configuration updates."**
- **Checked live practice:** `gh release view v2.77.2` returns a body **identical** to the
  CHANGELOG.md entry for that tag — confirmed there is currently zero curation layer; "release
  notes" today just means "changelog, auto-pasted a second place."

**Decision (user-confirmed):** `CHANGELOG.md` stays exactly as-is — **no new template**, it's
tool-owned. `docs/release-notes/` gets a template but **stays on the shelf** — optional, no
mandatory-per-release discipline, no CI gate. Boundary rule: if a curated release-notes file exists
for a version, it becomes the GitHub Release body for that tag; otherwise the mechanical changelog
entry stands. Content never appears in three places doing the same job.

**Artifact:** [`templates/release-notes.md`](../templates/release-notes.md).