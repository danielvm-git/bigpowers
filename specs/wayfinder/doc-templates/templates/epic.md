<!-- wayfinder resolution artifact — T24 (epic-template), closed -->
<!-- THIN WRAPPER, not a duplicate — same treatment tasks.md gave *-tasks.yaml (T19) and
     workflow-recipe.md gave specs/workflows/*.yaml (T23). The existing epic.yaml schema
     doesn't change; this reconciles it with T1's OKF envelope doctrine. Delivery-group
     artifact (T4:34, KEEP), same group as story.md/tasks.md — pure-YAML,
     collaboratively-authored-during-planning (via plan-work/plan-release), not a
     machine-derived data record the way execution-status.yaml is. -->
<!-- STRUCTURAL NOTE: like tasks.md/workflow-recipe.md, this template's body is a single fenced
     YAML block with no H1/H2 prose sections — intentional, same reasoning: an epic capsule is
     a flat record (id/title/wsjf/bcps/stories[]), not a document with sections to organize. -->
<!-- Closes the one fog-list gap this audit found: epic.yaml was the sole Delivery-group
     document (T4:34) with neither a ticket nor a template, while its siblings story.md (T12)
     and tasks.md (T19) both got both. -->

---
okf_kind: epic
okf_version: "1.0"
generated_by: "{skill:plan-release | skill:elaborate-spec | human}"
generated_at: {YYYY-MM-DDTHH:MM:SSZ}
epic_id: {eNN}
---

```yaml
id: {eNN}
title: "{Epic title}"
wsjf: {n.n}
bcps: {epic-level total — MUST equal the sum of every story's bcp: below, never hand-stamped independently}
capsule_dir: epics/{eNN-slug}
mode: capsule
status: {todo | in_progress | done}
depends_on: [{eNN, ...} | []]
source: |
  {Where this epic came from — a wayfinding session, a red-teamed /audit-plan verdict, a user
  ask. Prose, not a data record.}
note: >
  {Optional — WSJF rationale, scope notes, cross-references to sibling/later epics. Prose.}
stories:
  - id: {eNNsYY}
    bcp: {n}
    status: {todo | in_progress | done}
    title: "{Story title}"
    spec: {eNNsYY-slug}.md
    tasks: {eNNsYY}-tasks.yaml
    ac: |
      GIVEN {precondition}
      WHEN  {this story lands}
      THEN  {observable outcome}
```

{Repeat the `stories:` entry once per story. `id`/`bcp`/`status`/`title` are required per story;
`spec`/`tasks` name the two sibling files that MUST both exist before the epic starts — see the
guardrail below.}

<!-- GUARDRAIL (found the hard way, this audit round): every story listed above MUST have both
     a matching spec: `.md` file and tasks: `.yaml` file in the same capsule directory BEFORE
     the epic starts — confirmed as the real, repo-wide convention (≈158:159 pairing across
     specs/epics/archive/), and it is a CRITICAL-severity finding under
     scripts/lib/plan-consistency-check.sh (`No story spec .md files in capsule`, `tasks.yaml
     for $sid without matching story spec .md`) — run that script against the capsule directory
     before considering an epic ready to build. Per-story `bcp:` (singular key, confirmed as
     the real convention across every other live epic.yaml — not an inconsistency with
     tasks.yaml's story-level `bcps:` to "fix") must sum to the epic-level `bcps:` total;
     neither is ever hand-stamped independently of the other (constitution B9). -->
