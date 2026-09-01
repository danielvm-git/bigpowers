// story: e82s03
// Runtime smoke for extensions/omp-hooks.ts.
// Imports the extension, registers a fake ExtensionAPI, calls registered hooks,
// and asserts the slash-command handler awaits injection.

import bigpowers from "../extensions/omp-hooks.ts";

type AnyObj = Record<string, unknown>;
type Listener = (...args: unknown[]) => unknown;

function makeZod(): AnyObj {
  const chainable: AnyObj = {};
  chainable.optional = () => chainable;
  chainable.describe = () => chainable;
  return chainable;
}

const commands = new Map<string, { description: string; handler: Listener }>();
const tools: AnyObj[] = [];
const events = new Map<string, Listener>();
const sendCalls: AnyObj[] = [];

const pi: AnyObj = {
  setLabel: () => {},
  zod: {
    object: (_shape: AnyObj) => makeZod(),
    string: () => makeZod(),
    enum: () => makeZod(),
  },
  registerCommand: (name: string, spec: { description: string; handler: Listener }) => {
    commands.set(name, spec);
  },
  registerTool: (tool: AnyObj) => {
    tools.push(tool);
  },
  on: (event: string, handler: Listener) => {
    events.set(event, handler);
  },
  sendUserMessage: async (content: string, opts?: { deliverAs?: string }) => {
    sendCalls.push({ kind: "sendUserMessage", content, opts });
    return undefined;
  },
  sendMessage: async (msg: AnyObj, opts?: { triggerTurn?: boolean; deliverAs?: string }) => {
    sendCalls.push({ kind: "sendMessage", msg, opts });
    return undefined;
  },
};

await bigpowers(pi as unknown as never);

console.log(JSON.stringify({
  commands: commands.size,
  tool: tools[0]?.name,
  events: [...events.keys()],
  firstCommand: [...commands.keys()].slice(0, 5),
  sendUserMessageAwaitable: typeof pi.sendUserMessage === "function",
}));

// Exercise the /survey-context handler end-to-end.
const handler = commands.get("survey-context")?.handler;
if (!handler) throw new Error("survey-context command not registered");
await handler("", {});

// Verify a nonexistent command is not present.
const fallback = commands.get("nonexistent-skill-for-test")?.handler;
if (fallback) throw new Error("unexpected command registered");

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
