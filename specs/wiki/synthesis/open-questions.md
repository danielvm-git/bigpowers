# Open Questions

Synthesized from [[../../METHODOLOGY.md]] and spike learnings. Not authoritative — resolve via ADRs, STATE.md, or new spikes.

## Methodology lenses

[[../../METHODOLOGY.md]] defines STRIDE and Cost-of-Delay lenses toggled per release in STATE.md. **Open:** Which lenses should be active by default for bigpowers meta-development vs consumer projects?

## Context isolation and model routing

[[../../adr/0004-context-isolation.md|ADR-0004]] and [[../../adr/0006-model-routing.md|ADR-0006]] are accepted but implementation pending (v2.4.0). **Open:** How does `orchestrate-project` enforce file-passing and model tiers across Cursor, Claude Code, and Gemini CLI harnesses?

## Migration and foreign spec formats

[[../../SPIKE-migrate-spec.md]] — GSD, spec-kit, and BMAD artifacts can be transformed into bigpowers `specs/`. **Open:** Should `migrate-spec` create `specs/DECISION-LOG.md` for lightweight PRD decisions below ADR threshold?

## Verify phase maturity

[[../../SPIKE-verify-work.md]] — Multi-phase UAT gate design. **Open:** Benchmark coverage for verify-work vs manual UAT waiver protocol in STATE.md.

## Framework and audit spikes

- [[../../SPIKE-frameworks.md]] — Framework comparison learnings
- [[../../SPIKE-original-audit.md]] — Original audit harness design
- [[../../SPIKE-doc-review.md]] — Documentation review patterns

**Open:** Consolidate spike outcomes into ADRs where decisions hardened, archive the rest.

## Wiki layer (new)

- **Ingest cadence:** When to run `maintain-wiki ingest` vs relying on sync-only for solo projects?
- **Compliance snapshot:** `specs/audit/reports/` does not exist — should sync capture `npm run compliance` stdout to a report file for Dataview?

## v3.0.0 release

Per [[../../STATE.md#Pending]] — benchmark scoring at merge if required by release checklist. **Open:** Baseline number and waiver criteria for solo-local land.
