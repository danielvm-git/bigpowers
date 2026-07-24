# Context Engineering — Write, Select, Compress, Isolate

**Provenance:** Synthesized from the bigpowers agent skills ecosystem.
Context engineering is the discipline of managing what an AI agent "sees"
in its context window — the text, code, and documentation available during
a single inference call. The four strategies below form a complete
framework for token-efficient agent operation.

---

## The Four Strategies

### 1. Write

**What:** Author content that is inherently token-efficient — short functions,
unique symbol names, headless tests, and documentation that doesn't restate
code.

**Why:** Every token the agent reads costs money and context-window space.
Writing for agents means writing for machines that parse greedily — they
don't skim, they consume linearly.

**How bigpowers applies it:**
- Skills are structured with progressive disclosure (frontmatter → summary → detail)
- Story specs follow a 20-section format so agents can jump to §17 (Acceptance criteria) directly
- Task verify commands are one-liners — no prose, just runnable bash
- CONVENTIONS.md mandates function sizes (4-20 lines) and file sizes (< 300 lines)

### 2. Select

**What:** Choose which content to include in context based on the task at hand.
Not everything needs to be in the window — only what's relevant to the current step.

**Why:** Context windows have finite capacity. Filling them with irrelevant
content crowds out the reasoning space the agent needs for the actual task.

**How bigpowers applies it:**
- `survey-context` reads state.yaml and selects the active epic/story — a 3-line scan, not a full codebase read
- `bts_map` provides PageRank-ranked file lists so agents open the most important files first
- `bts_compress` reduces large files to semantic skeletons before including them
- OKF bundles (e39) decompose large docs (CONVENTIONS.md, CLAUDE.md) into indexed concept pages

### 3. Compress

**What:** Reduce the token count of content without losing its semantic structure.
Summarize, skeletonize, deduplicate.

**Why:** Raw content is bloated. Compression preserves the meaning while cutting
the cost — often by 60-90%.

**How bigpowers applies it:**
- `bts_compress` pipes any text through `sqz` for semantic compression
- `rtk` (Rust Token Killer) compresses build/test/git output by 60-99%
- `edit-document` restructures documents for density without losing integrity
- `terse-mode` cuts communication token usage by ~75%

### 4. Isolate

**What:** Give each agent exactly the context it needs — no more — by
partitioning work into independent units with explicit handoffs.

**Why:** Agents don't need shared state to cooperate. They need clear
boundaries, explicit handoff contracts, and no hidden dependencies.

**How bigpowers applies it:**
- `dispatch-agents` fans out parallel tasks with disjoint file scopes
- `delegate-task` gives a subagent only the files relevant to its task
- `kickoff-branch` creates isolated worktrees so agents don't conflict
- `session-state` records decisions so the next agent can cold-start without replaying history
- `agent-locks.yaml` (e39) prevents two agents from touching the same file

---

## Effort Classification

Context engineering strategies vary in token cost and cognitive load. Skills
carry an `effort:` frontmatter field to help agents select the right skill
for their current context budget:

| effort | Meaning | Token cost | When to use |
|--------|---------|------------|-------------|
| `light` | Simple read-and-report | < 2K tokens | Quick status checks, context bootstrap |
| `standard` | Multi-step with verification | 2-10K tokens | Typical skill execution |
| `heavy` | Full workflow with subagents | > 10K tokens | Epic builds, multi-phase planning |

---

## See Also

- `CLAUDE.md` §Token Management — session-level context strategy
- `skills/session-state/SKILL.md` — context persistence across sessions
- `docs/references/bcp.md` — BCP sizing (effort classification's sibling concept)
- `skills/terse-mode/SKILL.md` — ultra-compressed communication mode

**Last synced:** 2026-07-24T18:42:59Z (from CLAUDE.md + PRINCIPLES.md)
