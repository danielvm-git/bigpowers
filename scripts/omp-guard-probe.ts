// story: BUG-2026-11-03-guard-git-flag-normalize
// omp-guard-probe.ts — evaluate shell commands through the extension's guard,
// so the TypeScript rules can be held to the same fixture table as
// hooks/pre-tool-use.sh (scripts/test-guard-git-normalize.sh).
//
// Usage: echo '["git status", …]' | node scripts/omp-guard-probe.ts
// Prints a JSON array of "block" | "allow", one per input command.
//
// It calls evaluateBashCall(), the same pure function the tool_call handler
// calls — destructive argv rules AND the protected-branch/commit rules. Probing
// only dangerousGitCommand() compared one rule against a whole hook, which is
// how "git push --force-with-lease origin main" passed here and failed there.
//
// The branch context is fixed and synthetic so a verdict cannot depend on the
// machine: the shell side is run with GIT_BIGPOWERS_LAND unset by the harness.

import { readFileSync } from "node:fs";
import { evaluateBashCall } from "../extensions/omp-hooks.ts";

const source = readFileSync(new URL("../extensions/omp-hooks.ts", import.meta.url), "utf8");
const handlerStart = source.indexOf('pi.on("tool_call"');
if (handlerStart < 0) throw new Error("tool_call handler not found in extensions/omp-hooks.ts");
if (!source.slice(handlerStart).includes("evaluateBashCall(")) {
  throw new Error("tool_call handler does not call evaluateBashCall() — the guard is not wired");
}

const BRANCH = "fix/guard-git-normalize";
const commands = JSON.parse(readFileSync(0, "utf8")) as string[];
const verdicts = commands.map((command) =>
  evaluateBashCall(command, {
    landMode: false,
    hasRepo: true,
    branchFor: () => BRANCH,
  })
    ? "block"
    : "allow",
);
process.stdout.write(`${JSON.stringify(verdicts)}\n`);
