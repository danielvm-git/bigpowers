// story: e67s01
// scenario: SC-e67s01-P1-03
// kilocode plugin hook template — register tool guards (no dynamic eval).

export function register(ctx: { registerHook: (event: string, fn: Function) => void }) {
  const events = ["tool.execute.before", "tool.execute.after", "chat.message"] as const;
  for (const event of events) {
    ctx.registerHook(event, async (payload: { command?: string }) => {
      const cmd = payload?.command ?? "";
      if (/git push --force|reset --hard|rm -rf \//.test(cmd)) {
        return { decision: "block", reason: "BLOCKED: dangerous command pattern" };
      }
      return { decision: "allow" };
    });
  }
}
