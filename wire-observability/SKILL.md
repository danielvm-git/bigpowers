---
name: wire-observability
model: sonnet
description: Add structured JSON logging, observability commands, and idempotent setup scripts to a project. Use when a project needs production-readiness instrumentation, when user wants structured logging, or as a production-readiness gate at any phase of development.
---

# Wire Observability
> **HARD GATE** — **HARD GATE** — Observability is not optional. Before shipping, verify: structured logging is in place, key metrics are instrumented, error cases emit signals. 'We'll add metrics later' becomes 'never.'


Add structured logging, observability commands, and idempotent setup scripts. Can be invoked at any phase — recommended at the end of the first working slice, before the first deploy.

## What this sets up

1. **Structured JSON logging** — machine-readable logs for debugging and observability
2. **Observability commands** — how to check the system's health documented in CLAUDE.md
3. **Idempotent setup scripts** — scripts that can be run repeatedly without side effects

## Process

### 1. Assess current state

Check what's already in place:
- Is there a logging library? (pino, winston, structlog, zap, slog, etc.)
- Is logging JSON or plain text?
- Is there a health check endpoint or command?
- Are there setup scripts? Are they idempotent?

### 2. Add structured JSON logging

**For user-facing CLI output:** plain text is fine.
**For everything else:** structured JSON.

Structured log entry format:
```json
{
  "level": "info",
  "timestamp": "2025-01-15T10:23:45.123Z",
  "message": "User created",
  "userId": "usr_abc123",
  "requestId": "req_xyz789"
}
```

Guidelines:
- Include `level`, `timestamp`, `message` in every entry
- Add context fields relevant to the operation (userId, requestId, traceId)
- Log at boundaries: HTTP requests in/out, DB queries, external API calls, background job start/end
- Log errors with stack traces: `logger.error({ err, context }, "Operation failed")`
- **Never log secrets, passwords, tokens, or PII**

### 3. Document observability commands in CLAUDE.md

Add an "Observability" section to the project's CLAUDE.md:

```markdown
## Observability

| What | Command |
|------|---------|
| View logs | `<log tail command>` |
| Health check | `<health check command>` |
| Check DB connection | `<db ping command>` |
| View metrics | `<metrics command>` |
```

### 4. Write idempotent setup scripts

An idempotent script can be run multiple times and always produces the same result (no errors on re-run).

Pattern: check if the thing already exists before creating it.

```bash
#!/usr/bin/env bash
set -euo pipefail

# Idempotent: only create if not exists
if ! psql -c "SELECT 1 FROM pg_database WHERE datname = 'myapp'" | grep -q 1; then
  createdb myapp
  echo "Database created"
else
  echo "Database already exists, skipping"
fi
```

Place setup scripts in `scripts/setup.sh` (or language-appropriate equivalent). Document the command in CLAUDE.md under Commands.

### 5. Verify

- [ ] Run the app and confirm JSON logs appear in the correct format
- [ ] Run `scripts/setup.sh` twice — second run should produce no errors
- [ ] Health check command returns success
- [ ] No sensitive data in log output
