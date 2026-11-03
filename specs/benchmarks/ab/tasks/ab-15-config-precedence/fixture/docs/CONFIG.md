# Configuration

Settings come from four sources. A later source overrides an earlier one:

1. the built-in defaults (`src/defaults.js`)
2. the config file: `config.json` in the working folder, or the file named by `--config <path>`
   (`--config=<path>` works too). A relative path is relative to the working folder. A file named
   with `--config` that does not exist is an error: `config file not found: <path>`. A missing
   `config.json` is fine.
3. environment variables whose name starts with `APP_`
4. `--set <key>=<value>` on the command line, which can be repeated

Merging is per key: a source only changes the keys it sets.

## Keys

A key is a dotted path into the defaults, such as `db.port`. A key that is not in the defaults is an
error from any source: `unknown config key: <key>`.

## Environment variables

The variable name is `APP_` followed by the key, with `__` between levels. Variables without the
`APP_` prefix are ignored. See the examples.

## Types

A value takes the type of its default:

- numbers: whole numbers only, else `invalid number for <key>: <value>`
- booleans: `true`, `false`, `1` or `0`, in any letter case, else `invalid boolean for <key>: <value>`
- lists: comma-separated items, with spaces around each item removed
- strings: used as they are

Values in the config file are JSON and must already have the right type, else
`invalid type for <key>`.

## The result

`loadConfig({ argv, env, cwd })` returns the complete settings object. It is frozen, nested objects
included, so a caller cannot change it by accident.

## Examples

| Source | Setting | Result |
|---|---|---|
| env | `APP_DB__PORT=6543` | `db.port` is `6543` |
| env | `APP_DB__MAX_CONNECTIONS=50` | `db.maxConnections` is `50` |
| env | `APP_APP__DEBUG=TRUE` | `app.debug` is `true` |
| env | `APP_MAILER__RECIPIENTS=a@x.test, b@x.test` | `mailer.recipients` is `["a@x.test", "b@x.test"]` |
| env | `APP_LOG__LEVEL=` | `log.level` keeps its value from the file or the defaults |
| env | `PATH=/usr/bin` | ignored |
| env | `APP_DB__HOTS=x` | error: `unknown config key: db.hots` |
| flag | `--set db.host=db.internal` | `db.host` is `"db.internal"` |
| env + flag | `APP_DB__HOST=a` and `--set db.host=b` | `db.host` is `"b"` |
