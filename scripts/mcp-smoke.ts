// story: e32s06
// Simulates OMP spawning bigpowers-mcp from the installed plugin root (#123).
// Verifies Node resolves @modelcontextprotocol/sdk from the root package graph
// and the server reaches its startup log line without module-not-found.

import { readFileSync } from "node:fs";
import { spawn } from "node:child_process";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = dirname(dirname(fileURLToPath(import.meta.url)));
const manifest = JSON.parse(readFileSync(join(repoRoot, ".mcp.json"), "utf8")) as {
  mcpServers?: Record<string, { args?: string[]; cwd?: string }>;
};
const server = manifest.mcpServers?.["bigpowers-mcp"];
if (!server) throw new Error("bigpowers-mcp entry missing from .mcp.json");

const entry = join(repoRoot, "bigpowers-mcp/build/index.js");
const started = await new Promise<{ ok: boolean; detail: string }>((resolve) => {
  const child = spawn("node", [entry], {
    cwd: repoRoot,
    stdio: ["ignore", "pipe", "pipe"],
    env: { ...process.env, OMP_PLUGIN_ROOT: repoRoot },
  });

  let stderr = "";
  const timer = setTimeout(() => {
    child.kill("SIGTERM");
    resolve({ ok: false, detail: `timeout waiting for startup (stderr: ${stderr.trim()})` });
  }, 5000);

  child.stderr.on("data", (chunk: Buffer) => {
    stderr += chunk.toString();
    if (stderr.includes("bigpowers-mcp started")) {
      clearTimeout(timer);
      child.kill("SIGTERM");
      resolve({ ok: true, detail: "bigpowers-mcp started" });
    }
  });

  child.on("exit", (code, signal) => {
    if (stderr.includes("ERR_MODULE_NOT_FOUND")) {
      clearTimeout(timer);
      resolve({ ok: false, detail: stderr.trim() });
      return;
    }
    if (signal === "SIGTERM" && stderr.includes("bigpowers-mcp started")) return;
    clearTimeout(timer);
    resolve({
      ok: false,
      detail: `exit code=${code ?? "null"} signal=${signal ?? "null"} stderr=${stderr.trim()}`,
    });
  });
});

if (!started.ok) {
  throw new Error(started.detail);
}

console.log(
  JSON.stringify({
    pluginRoot: repoRoot,
    entry,
    ompPluginRootInManifest: server.cwd?.includes("OMP_PLUGIN_ROOT") ?? false,
    startup: started.detail,
  }),
);
