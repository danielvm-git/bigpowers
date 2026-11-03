# Architecture

- `src/index.js` `start({ argv, env, cwd })` builds the settings once with `loadConfig` and hands
  them to every module. Modules never read files, `process.env` or `process.argv` themselves.
- `src/config.js` is the only module that reads configuration sources.
- `src/defaults.js` holds the built-in settings and defines which keys exist.
- Errors are thrown as `Error` with a one-line message; callers decide how to report them.
