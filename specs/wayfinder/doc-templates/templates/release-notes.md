<!-- wayfinder resolution artifact — T9 (changelog-vs-release-notes), closed -->
<!-- ON THE SHELF: optional. Do not write one of these for every release — only when
     a release has something a reader genuinely needs to know beyond the mechanical
     changelog entry (breaking changes, migrations, deprecations, config changes).
     If this file doesn't exist for a version, semantic-release's default changelog
     entry is the release body. No gate requires this; no CI step generates it. -->
<!-- Composed from: big-docs/docs/release-notes/template_release-notes.md (TGDP). -->
<!-- {curly braces} mark fill-in points, following TGDP convention. -->

# Release notes — {Project Name} {vX.Y.Z}

{Release date — YYYY-MM-DD}

{Optional: one-paragraph summary. Only write this if the release needs framing beyond
the bullet list below — most releases don't.}

## New features

- **{Feature name}** — {what it does and why it matters to the reader, not how it's implemented}

## Requires action before or after upgrading

{This section is the reason this template exists — the changelog can't produce it.
Config changes, migrations, anything the reader must DO, not just know about.}

- **{Change name}** — {what to do, and what breaks if you don't}

## Improvements

- **{Improvement}** — {description}

## Bug fixes

- **{Fix}** — {description}

## Known issues

{Only if something shipped with a known gap or workaround. Omit the section if empty —
don't leave a placeholder "none" line.}

- **{Issue}** — {workaround, if any}

## Deprecations

{Only if something in this release is marked for removal. Omit if not applicable.}

- **{Deprecated feature}** — {what replaces it, and the removal timeline}

---

{This file, if present at `docs/release-notes/{vX.Y.Z}.md`, becomes the GitHub Release body for
that tag. Absent, the mechanical CHANGELOG.md entry is used as-is — no duplication either way.}
