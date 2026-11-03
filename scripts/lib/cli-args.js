// story: BUG-2026-11-03-cli-nontty-silent-noop
// cli-args.js — argument parsing for `bigpowers setup|install|update`.
//
// The installer used to ignore argv entirely and always prompt. With stdin at EOF
// (agent, CI, `| cat`) each @clack/prompts promise never settles, Node exits 0 and
// nothing is installed — a silent no-op that reports success.

'use strict';

// bin/bigpowers.js `require`s setup.js with the subcommand still in argv.
const SUBCOMMANDS = new Set(['setup', 'install', 'update']);

function parseArgs(argv) {
  const opts = { help: false, yes: false, uninstall: false, scope: null, tools: null };
  for (const arg of argv) {
    if (arg === '--help' || arg === '-h') opts.help = true;
    else if (arg === '--yes' || arg === '-y') opts.yes = true;
    else if (arg === '--uninstall') opts.uninstall = true;
    else if (arg === '--global') opts.scope = 'global';
    else if (arg === '--local') opts.scope = 'local';
    else if (arg.startsWith('--scope=')) opts.scope = arg.slice('--scope='.length);
    else if (arg.startsWith('--tools=')) {
      opts.tools = arg.slice('--tools='.length).split(',').map((s) => s.trim()).filter(Boolean);
    } else if (SUBCOMMANDS.has(arg)) continue;
    else throw new Error(`Unknown option '${arg}'. Run: bigpowers setup --help`);
  }
  if (opts.scope && opts.scope !== 'global' && opts.scope !== 'local') {
    throw new Error(`--scope must be 'global' or 'local', got '${opts.scope}'`);
  }
  return opts;
}

/** Usage text for `bigpowers setup --help`. */
function printSetupHelp() {
  console.log(`
bigpowers setup — link the skills into your agent runtimes

Usage:
  bigpowers setup                 Interactive menu (needs a TTY)
  bigpowers setup --yes [flags]   Non-interactive install
  bigpowers update                Fetch the latest release, then re-sync what is installed
  bigpowers setup --help

Flags:
  -y, --yes           Accept the resolved plan without prompting (required without a TTY)
      --tools=a,b     Runtimes to install (claude, pi, cursor, gemini, codex, …)
      --scope=global  ~/<tool>  — available in all projects (default)
      --scope=local   ./.<tool> — this project only
      --global        Shorthand for --scope=global
      --local         Shorthand for --scope=local
      --uninstall     Remove the symlinks instead of installing
  -h, --help          This message

Without a TTY and without --yes the command exits 2 instead of drawing a menu.
`);
}

module.exports = { parseArgs, printSetupHelp, SUBCOMMANDS };
