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

import { readFileSync } from "node:fs";
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
