// story: e82s03
// Runtime smoke for extensions/omp-hooks.ts.
// Imports the extension, registers a fake ExtensionAPI, and verifies the
// extension leaves commands to prompt templates while skill-tool injection works.
//
// Load-phase contract (BUG-2026-09-05, #119): pi installs throwing stubs for
// ACTION methods during extension loading and only binds real implementations
// after the factory returns. Registration methods are valid during load. This
// fake models that contract so a load-time action call (e.g. pi.setLabel())
// fails here exactly as it does in real pi, instead of silently passing.
// See pi 0.85.1 src/core/extensions/loader.ts (createExtensionRuntime).

import assert from "node:assert/strict";
import { spawnSync, execFileSync } from "node:child_process";
import { mkdtempSync, readFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import bigpowers from "../extensions/omp-hooks.ts";

type AnyObj = Record<string, unknown>;
type Listener = (...args: unknown[]) => unknown;

// pi's verbatim message when an action method is called during load.
const LOAD_PHASE_ERROR =
  "Extension runtime not initialized. Action methods cannot be called during extension loading.";

// True while the factory body runs. Action methods throw while this is set.
let loading = true;

const commands = new Map<string, { description: string; handler: Listener }>();
const tools: AnyObj[] = [];
const events = new Map<string, Listener>();
const sendCalls: AnyObj[] = [];

// Action method: rejects if invoked during the loading phase, like real pi.
function action<T extends Listener>(fn: T): T {
  return ((...args: unknown[]) => {
    if (loading) throw new Error(LOAD_PHASE_ERROR);
    return fn(...args);
  }) as T;
}

const pi: AnyObj = {
  // ----- Registration methods: valid during load -----
  registerCommand: (name: string, spec: { description: string; handler: Listener }) => {
    commands.set(name, spec);
  },
  registerTool: (tool: AnyObj) => {
    tools.push(tool);
  },
  registerShortcut: (_shortcut: string, _opts: AnyObj) => {},
  registerFlag: (_name: string, _opts: AnyObj) => {},
  on: (event: string, handler: Listener) => {
    events.set(event, handler);
  },
  // registerProvider() calls made in the factory are queued by real pi, not
  // thrown — model that as a permissive no-op.
  registerProvider: (..._args: unknown[]) => {},

  // ----- Action methods: throw if called during load -----
  setLabel: action((_entryId: string, _label?: string) => {}),
  setSessionName: action((_name: string) => {}),
  getSessionName: action(() => undefined),
  appendEntry: action((_customType: string, _data?: unknown) => {}),
  setModel: action(() => Promise.resolve(true)),
  getActiveTools: action(() => [] as string[]),
  getAllTools: action(() => [] as AnyObj[]),
  setActiveTools: action((_names: string[]) => {}),
  getCommands: action(() => [] as AnyObj[]),
  getThinkingLevel: action(() => "off"),
  setThinkingLevel: action((_level: string) => {}),
  sendUserMessage: action(async (content: string, opts?: { deliverAs?: string }) => {
    sendCalls.push({ kind: "sendUserMessage", content, opts });
    return undefined;
  }),
  sendMessage: action(async (msg: AnyObj, opts?: { triggerTurn?: boolean; deliverAs?: string }) => {
    sendCalls.push({ kind: "sendMessage", msg, opts });
    return undefined;
  }),
};

// Load the extension under the load-phase contract. A load-time action call
// throws here and fails the smoke test (RED), matching pi's startup abort.
await bigpowers(pi as unknown as never);

// Factory returned successfully: the runtime is now "bound". Action methods
// are callable from here on (handlers, tool executions).
loading = false;

// Exercise the registered hook in a child: inherited Git stderr must never
// write over Pi's editor, including when the working directory is not a repo.
if (process.env.BIGPOWERS_HOOK_SMOKE === "1") {
  const hook = events.get("tool_call");
  assert.ok(hook, "tool_call hook must be registered");
  const allowed = hook({ toolName: "bash", input: { command: "echo hello" } });
  assert.equal(allowed, undefined);
  const push = hook({ toolName: "bash", input: { command: "git push" } });
  if (process.env.BIGPOWERS_EXPECT_PROTECTED === "1") {
    assert.equal((push as { block?: boolean })?.block, true);
  } else {
    assert.equal(push, undefined);
  }
  process.exit(0);
}

const hookWorkspace = mkdtempSync(join(tmpdir(), "bigpowers-hook-"));
try {
  for (const repository of [false, true]) {
    if (repository) {
      const git = (args: string[]) => execFileSync("git", args, {
        cwd: hookWorkspace, stdio: "pipe",
      });
      git(["init", "--initial-branch=main"]);
      git(["-c", "user.name=Smoke", "-c", "user.email=smoke@example.invalid",
        "commit", "--allow-empty", "-m", "test"]);
    }
    const result = spawnSync(process.execPath, ["--disable-warning=MODULE_TYPELESS_PACKAGE_JSON", fileURLToPath(import.meta.url)], {
      cwd: hookWorkspace,
      env: { ...process.env, BIGPOWERS_HOOK_SMOKE: "1",
        BIGPOWERS_EXPECT_PROTECTED: repository ? "1" : "0" },
      encoding: "utf8",
    });
    assert.equal(result.status, 0, result.stderr);
    assert.equal(result.stderr, "", "Git hook must not leak stderr into Pi's terminal");
  }
} finally {
  rmSync(hookWorkspace, { recursive: true, force: true });
}

const packageManifest = JSON.parse(
  readFileSync(new URL("../package.json", import.meta.url), "utf8"),
) as { pi?: { prompts?: string[] } };
const promptTemplates = packageManifest.pi?.prompts ?? [];

if (commands.size !== 0) {
  throw new Error(`extension registered ${commands.size} duplicate workflow commands`);
}
if (!promptTemplates.includes("./.pi/prompts")) {
  throw new Error("package does not declare the canonical Pi prompt templates");
}

console.log(JSON.stringify({
  commands: commands.size,
  promptTemplates,
  tool: tools[0]?.name,
  events: [...events.keys()],
  sendUserMessageAwaitable: typeof pi.sendUserMessage === "function",
}));

// Test bigpowers_skill run path.
const skillTool = tools[0];
if (!skillTool?.execute) throw new Error("bigpowers_skill tool missing execute");
const runResult = await skillTool.execute(
  "call-1",
  { action: "run", skill: "verify-work", args: "ping" },
  new AbortController().signal,
  () => {},
  {},
);

console.log(JSON.stringify({
  sendCalls,
  runDetails: runResult.details,
}));
