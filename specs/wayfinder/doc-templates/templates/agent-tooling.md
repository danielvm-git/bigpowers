<!-- wayfinder resolution artifact — T18 (agents-and-conventions), closed -->
<!-- EXTRACTED from bigpowers' live CLAUDE.md — ~250 lines of RTK/sqz/bts command tables that
     the real AGENTS.md template proves were never meant to live inline in the agent-bootstrap
     file. TGDP reference/ pack shape (tables: command/description/argument/example), per T13's
     established pattern for this kind of content. -->
<!-- CONDITIONAL, not universal: only populate this page if the project actually has these tools
     (or an equivalent token-economy toolchain) installed. Unlike AGENTS.md, this is not
     mandatory scaffolding for every project. -->
<!-- Wave 2, plain markdown, no OKF envelope. -->

# Agent Tooling Reference — {Project Name}

{One line: which token-economy tools this project uses and why, if any. Omit this whole page
from the site nav if the project has none.}

## {Tool name, e.g. RTK}

{One line: what it does and the golden rule for using it — e.g. "always prefix commands with X."}

| Command | Description | Example savings |
|---------|-------------|------------------|
| `{cmd}` | {what it filters/compacts} | {e.g. 90-99%} |

## {Tool name, e.g. sqz}

{Same shape — command table, plus any escape-hatch instructions (how to get raw/uncompressed
output when the filtered version is actively unhelpful).}

| Command | Description |
|---------|-------------|
| `{cmd}` | {what it does} |

## {Tool name, e.g. bts}

{Same shape.}

---

{This page is populated by whichever tool's own setup/install step, not hand-maintained —
keep it in sync with the tool's own documentation rather than re-describing its behavior from
memory.}
