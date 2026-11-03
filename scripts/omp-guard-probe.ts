// story: BUG-2026-11-03-guard-git-flag-normalize
// omp-guard-probe.ts — evaluate shell commands through the extension's git
// argv normalizer, so the TypeScript rules can be held to the same fixture
// table as hooks/pre-tool-use.sh (scripts/test-guard-git-normalize.sh).
//
// Usage: echo '["git status", …]' | node scripts/omp-guard-probe.ts
// Prints a JSON array of "block" | "allow", one per input command.
//
// The normalizer is exported rather than reached through the tool_call handler
// so the probe does not need a fake ExtensionAPI. That the handler actually
// calls it is asserted below, statically: an exported rule nobody calls would
// pass these fixtures and protect nothing.

import { readFileSync } from "node:fs";
import { dangerousGitCommand } from "../extensions/omp-hooks.ts";

const source = readFileSync(new URL("../extensions/omp-hooks.ts", import.meta.url), "utf8");
const handlerStart = source.indexOf('pi.on("tool_call"');
if (handlerStart < 0) throw new Error("tool_call handler not found in extensions/omp-hooks.ts");
if (!source.slice(handlerStart).includes("dangerousGitCommand(")) {
  throw new Error("tool_call handler does not call dangerousGitCommand() — the guard is not wired");
}

const commands = JSON.parse(readFileSync(0, "utf8")) as string[];
const verdicts = commands.map((command) => (dangerousGitCommand(command) ? "block" : "allow"));
process.stdout.write(`${JSON.stringify(verdicts)}\n`);
