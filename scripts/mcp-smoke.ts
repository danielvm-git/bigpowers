// story: e32s06
// Spawns bigpowers-mcp from the shipped .mcp.json the way each host expands it
// (#123, #168). Verifies Node resolves @modelcontextprotocol/sdk from the root
// package graph and the server reaches its startup log line without
// module-not-found, whether or not the host injects OMP_PLUGIN_ROOT.

import { readFileSync } from "node:fs";
import { spawn } from "node:child_process";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = dirname(dirname(fileURLToPath(import.meta.url)));
const manifest = JSON.parse(readFileSync(join(repoRoot, ".mcp.json"), "utf8")) as {
  mcpServers?: Record<string, { args?: string[]; cwd?: string }>;
};
const server = manifest.mcpServers?.["bigpowers-mcp"];
if (!server) throw new Error("bigpowers-mcp entry missing from .mcp.json");

// POSIX ${VAR} / ${VAR:-default}; an unset ${VAR} stays literal (omp and Claude Code both do this).
function expand(value: string, env: Record<string, string | undefined>): string {
  return value.replace(/\$\{([^}:]+)(?::-([^}]*))?\}/g, (whole, name: string, fallback?: string) => {
    const v = env[name];
    if (v !== undefined && (fallback === undefined || v !== "")) return v;
    return fallback ?? whole;
  });
}

// omp injects OMP_PLUGIN_ROOT and honours cwd; Claude Code project scope sets
// neither and spawns from the project root.
const { OMP_PLUGIN_ROOT: _ambient, ...baseEnv } = process.env;
const hosts = [
  { name: "omp", env: { ...baseEnv, OMP_PLUGIN_ROOT: repoRoot }, honoursCwd: true },
  { name: "claude-code", env: baseEnv, honoursCwd: false },
];

function startServer(entry: string, cwd: string, env: NodeJS.ProcessEnv): Promise<{ ok: boolean; detail: string }> {
  return new Promise((done) => {
    const child = spawn("node", [entry], { cwd, stdio: ["ignore", "pipe", "pipe"], env });

    let stderr = "";
    const timer = setTimeout(() => {
      child.kill("SIGTERM");
      done({ ok: false, detail: `timeout waiting for startup (stderr: ${stderr.trim()})` });
    }, 5000);

    child.stderr.on("data", (chunk: Buffer) => {
      stderr += chunk.toString();
      if (stderr.includes("bigpowers-mcp started")) {
        clearTimeout(timer);
        child.kill("SIGTERM");
        done({ ok: true, detail: "bigpowers-mcp started" });
      }
    });

    child.on("exit", (code, signal) => {
      if (signal === "SIGTERM" && stderr.includes("bigpowers-mcp started")) return;
      clearTimeout(timer);
      done({ ok: false, detail: `exit code=${code ?? "null"} signal=${signal ?? "null"} stderr=${stderr.trim()}` });
    });
  });
}

const results = [];
for (const host of hosts) {
  const cwd = host.honoursCwd && server.cwd ? resolve(repoRoot, expand(server.cwd, host.env)) : repoRoot;
  const entry = resolve(cwd, expand(server.args?.[0] ?? "", host.env));
  const started = await startServer(entry, cwd, host.env);
  if (!started.ok) throw new Error(`[${host.name}] ${entry}: ${started.detail}`);
  results.push({ host: host.name, entry, startup: started.detail });
}

console.log(JSON.stringify({ pluginRoot: repoRoot, results }));
