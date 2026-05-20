# Plan: v1.12.0 (Compliance Auditor Stabilization)

## Context
Complete the Gherkin benchmark definitions and harden the Agentic Auditor harness for stable model-judged compliance verification.

## Steps

1. **Complete Benchmarks**: Create remaining Gherkin feature files for Akita, Karpathy, Pocock, BMAD, and Superpowers.
2. **Harden Auditor**: Add a file-based cache to `audit-compliance.sh` to prevent redundant API calls for consistent evidence.
3. **Refine Prompts**: Update judgment prompts to be more context-aware, reducing "ModelNotFound" or "QuotaExhausted" scenarios by optimizing input size.
4. **Integration**: Add a `npm run compliance` command in `package.json` that triggers the full audit loop.
5. **Validation**: Run full audit harness against all benchmarks to establish a stable "Red" baseline for future remediation.

## Out of Scope
- Fixing the actual compliance gaps (these will be v1.13.0+).

## Risks
- **Model Availability**: Continued quota exhaustion.
  - *Mitigation*: Emphasize local/offline binary fallback.
- **Ambiguity**: Benchmark features may be too generic.
  - *Mitigation*: Iterative refinement of Gherkin steps based on initial judge feedback.
