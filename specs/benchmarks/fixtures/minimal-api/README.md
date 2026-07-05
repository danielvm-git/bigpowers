# Minimal API Fixture (bigpowers e42s02)

Deterministic target repo for golden story G-01 (build cycle).

## Purpose

This fixture gives the agent-driven golden suite a stable, tiny Node.js
API to operate on. Running golden stories against the live bigpowers
repo would be slow, non-deterministic, and destructive. This fixture
provides a pinned baseline so pass@k scoring is meaningful.

## What's here

- `src/createUser.js` — One exported function. Zero dependencies.
- `test/createUser.test.js` — Happy-path + validation tests.
- `package.json` — Uses `node:test` (built-in). No `npm install` needed.

## Usage

```bash
cd specs/benchmarks/fixtures/minimal-api
npm test    # exits 0 on pristine fixture
```

## Failing-ready

The `node:test` runner discovers all `test/*.test.js` files. A golden
story agent can add a new test file asserting an unimplemented
validation rule, and `npm test` will discover and fail it — no wiring
changes needed.
