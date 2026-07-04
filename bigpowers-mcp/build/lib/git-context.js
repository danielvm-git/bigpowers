// story: e32s04
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { GIT_SCOPE_DIRS } from "../config.js";
import { isSecretPath } from "./paths.js";
function inScope(filePath) {
    const norm = filePath.replace(/\\/g, "/");
    if (isSecretPath(norm))
        return false;
    return GIT_SCOPE_DIRS.some((d) => norm === d || norm.startsWith(`${d}/`));
}
function groupByDir(files) {
    const grouped = {};
    for (const f of files) {
        const parts = f.split("/");
        const dir = parts.length > 1 ? parts[0] : ".";
        if (!grouped[dir])
            grouped[dir] = [];
        grouped[dir].push(f);
    }
    return grouped;
}
function git(repoRoot, args) {
    return execFileSync("git", args, {
        cwd: repoRoot,
        encoding: "utf8",
        maxBuffer: 10 * 1024 * 1024,
    }).trim();
}
export function getGitContext(repoRoot, action) {
    if (action === "status") {
        const out = git(repoRoot, ["status", "--porcelain"]);
        const files = out
            .split("\n")
            .filter(Boolean)
            .map((line) => line.slice(3).trim())
            .filter(inScope);
        return { action, changed_files: groupByDir(files) };
    }
    if (action === "log") {
        const out = git(repoRoot, [
            "log",
            "-10",
            "--pretty=format:%H|%s",
            "--name-only",
            "--",
            ...GIT_SCOPE_DIRS,
        ]);
        const commits = [];
        let current = null;
        for (const line of out.split("\n")) {
            if (line.includes("|")) {
                if (current)
                    commits.push(current);
                const [hash, subject] = line.split("|");
                current = { hash, subject, files: [] };
            }
            else if (line.trim() && current && inScope(line.trim())) {
                current.files.push(line.trim());
            }
        }
        if (current)
            commits.push(current);
        return { action, changed_files: {}, commits };
    }
    const diffOut = git(repoRoot, ["diff", "--", ...GIT_SCOPE_DIRS]);
    const diffs = {};
    let currentFile = "";
    let buf = [];
    for (const line of diffOut.split("\n")) {
        if (line.startsWith("diff --git")) {
            if (currentFile && buf.length)
                diffs[currentFile] = buf.join("\n");
            const match = / b\/(.+)$/.exec(line);
            currentFile = match?.[1] ?? "";
            buf = [line];
        }
        else {
            buf.push(line);
        }
    }
    if (currentFile && buf.length && inScope(currentFile) && !isSecretPath(currentFile)) {
        diffs[currentFile] = buf.join("\n");
    }
    const changed = Object.keys(diffs);
    return { action, changed_files: groupByDir(changed), diffs };
}
export function isGitRepo(repoRoot) {
    return fs.existsSync(path.join(repoRoot, ".git"));
}
//# sourceMappingURL=git-context.js.map