#!/usr/bin/env node
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { createContext, registerTools } from "./tools/index.js";
async function main() {
    const ctx = createContext();
    const server = new McpServer({
        name: "bigpowers-mcp",
        version: "0.1.0",
    });
    registerTools(server, ctx);
    const transport = new StdioServerTransport();
    await server.connect(transport);
    console.error("bigpowers-mcp started");
}
main().catch((err) => {
    console.error("Fatal error:", err);
    process.exit(1);
});
//# sourceMappingURL=index.js.map