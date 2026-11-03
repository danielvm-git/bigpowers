// story: BUG-2026-11-03-guard-git-flag-normalize
// story: BUG-2026-11-03-guard-normalize-branch-context
// omp-guard-probe.ts — evaluate shell commands through the extension's guard,
// so the TypeScript rules can be held to the same fixture table as
// hooks/pre-tool-use.sh (scripts/test-guard-git-normalize.sh).
//
// Usage: echo '[{"command":"git status","branch":"main"}, …]' | node scripts/omp-guard-probe.ts
// Prints a JSON array of "block" | "allow", one per input row.
//
// It calls evaluateBashCall(), the same pure function the tool_call handler
// calls — destructive argv rules AND the protected-branch/commit rules. Probing
// only dangerousGitCommand() compared one rule against a whole hook, which is
// how "git push --force-with-lease origin main" passed here and failed there.
//
// The branch context is supplied per row instead of fixed: protected-branch
// rules answer differently on `main` than on a feature branch, so a hardcoded
// branch made the table agree in one direction only and the gate went red the
// moment it ran on `main`. The harness gives the shell hook the same per-row
// branch (a throwaway repo checked out on it) and strips GIT_BIGPOWERS_LAND, so
// neither verdict can depend on the machine or the checked-out branch.

import { readFileSync } from "node:fs";
import { evaluateBashCall } from "../extensions/omp-hooks.ts";

const source = readFileSync(new URL("../extensions/omp-hooks.ts", import.meta.url), "utf8");
const handlerStart = source.indexOf('pi.on("tool_call"');
if (handlerStart < 0) throw new Error("tool_call handler not found in extensions/omp-hooks.ts");
if (!source.slice(handlerStart).includes("evaluateBashCall(")) {
  throw new Error("tool_call handler does not call evaluateBashCall() — the guard is not wired");
}

const DEFAULT_BRANCH = "fix/guard-git-normalize";
type Row = { command: string; branch?: string };

const input = JSON.parse(readFileSync(0, "utf8")) as Array<Row | string>;
const rows: Row[] = input.map((row) => (typeof row === "string" ? { command: row } : row));
const verdicts = rows.map((row) =>
  evaluateBashCall(row.command, {
    landMode: false,
    hasRepo: true,
    branchFor: () => row.branch ?? DEFAULT_BRANCH,
  })
    ? "block"
    : "allow",
);
process.stdout.write(`${JSON.stringify(verdicts)}\n`);
