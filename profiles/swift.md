# Stack Profile: Swift

Opt-in conventions fragment for `seed-conventions`. Core bigpowers skills stay language-agnostic.

## Commands (defaults — override in interview)

| Action | Command |
|--------|---------|
| Test | `swift test` |
| Lint | `swiftlint` (if `.swiftlint.yml` exists) |
| Build | `swift build` |

## Architecture

- Prefer MVVM: View → ViewModel → Model/Service
- Protocol-oriented seams for testability

## Conventions

- Use `struct` for value types; `class` only when reference semantics required
- Async: `async/await`; avoid callback pyramids
- Naming: Swift API Design Guidelines (camelCase, clarity at call site)

## Never

- Never force-unwrap (`!`) in production paths without documented invariant
- Never commit `DerivedData/` or `.build/`


<!-- story: e10s01 -->
