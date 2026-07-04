import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import type { SkillGraph } from "../lib/graph/types.js";
export interface ServerContext {
    repoRoot: string;
    graphPath: string;
    graph: SkillGraph;
}
export declare function createContext(): ServerContext;
export declare function registerTools(server: McpServer, ctx: ServerContext): void;
