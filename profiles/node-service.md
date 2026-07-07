# Stack Profile: Node Service

Opt-in conventions fragment for `seed-conventions`.

## Commands

| Action | Command |
|--------|---------|
| Test | `npm test` |
| Lint | `npm run lint` |
| Build | `npm run build` (if applicable) |
| Run | `node dist/index.js` or `npm start` |

## Architecture

- Layered: routes → handlers → services → repositories
- Structured JSON logging (see `wire-observability`)

## Conventions

- ESM or CJS — match existing `package.json` `"type"`
- Environment via `process.env` validated at boot
- Integration tests hit HTTP with supertest or fetch

## Never

- Never log secrets or full auth tokens
- Never use `any` on public API types


<!-- story: e10s01 -->
