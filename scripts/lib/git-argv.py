#!/usr/bin/env python3
"""Normalize git argv before applying the guard-git deny rules (#184).

The old guard matched literal substrings, so `git -C repo reset --hard`,
`git reset -q --hard` and `git checkout -- .` all slipped through: the
destructive tokens are still there, only their position or a global flag
changed. Matching on the raw command string cannot see that.

This module tokenizes the command (quote-aware), finds every `git` invocation,
strips the global options that precede the subcommand (`-C <path>`,
`--no-pager`, `-c k=v`, `--git-dir=…`, …), and then decides on the
(subcommand, arguments) pair. `extensions/omp-hooks.ts` implements the same
rules in TypeScript; `scripts/test-guard-git-normalize.sh` fails if the two
disagree on any fixture row.

Rule table (keep in sync with the TS port):

  reset     block when any argument is --hard
  clean     block when any short flag carries `f` (-f, -fd, -fdx) or --force
  branch    block on -D, or on --delete together with --force/-f
  checkout  block on -f/--force, or on a `.` pathspec (with or without --)
  restore   block on --worktree, or on a `.` pathspec
  push      block on -f/--force/+refspec, unless --force-with-lease is given

CLI:  git-argv.py --command "<shell command>"   → prints `block: <reason>` or `allow`
Exit: 0 allow, 10 block, 2 usage error.
"""
from __future__ import annotations

import shlex
import sys

# Global options that consume the next token as their value.
VALUE_FLAGS = {
    "-C",
    "-c",
    "--exec-path",
    "--git-dir",
    "--work-tree",
    "--namespace",
    "--super-prefix",
    "--config-env",
}

# Global options that stand alone.
BARE_FLAGS = {
    "-p",
    "--paginate",
    "--no-pager",
    "--bare",
    "--no-replace-objects",
    "--literal-pathspecs",
    "--glob-pathspecs",
    "--icase-pathspecs",
    "--no-optional-locks",
    "--version",
    "--help",
}

# Command separators: the guard judges each git invocation on its own.
SEPARATORS = {";", "&&", "||", "|", "&", "(", ")", "\n"}


def tokenize(command: str) -> list[str]:
    """Quote-aware split. Bad quoting degrades to whitespace splitting, never to eval."""
    try:
        return shlex.split(command, comments=False, posix=True)
    except ValueError:
        return command.split()


def git_invocations(tokens: list[str]) -> list[tuple[str, list[str], int]]:
    """Yield (subcommand, args, index) for every git call in the token stream."""
    found: list[tuple[str, list[str], int]] = []
    i = 0
    while i < len(tokens):
        token = tokens[i]
        if token.rsplit("/", 1)[-1] != "git":
            i += 1
            continue
        start = i
        j = i + 1
        # Skip global options between `git` and the subcommand.
        while j < len(tokens):
            opt = tokens[j]
            if opt in SEPARATORS:
                break
            name = opt.split("=", 1)[0]
            if name in VALUE_FLAGS:
                j += 2 if "=" not in opt else 1
                continue
            if name in BARE_FLAGS or (opt.startswith("-") and not opt.startswith("--") and len(opt) > 1):
                j += 1
                continue
            break
        if j >= len(tokens) or tokens[j] in SEPARATORS:
            i = j + 1
            continue
        sub = tokens[j]
        args: list[str] = []
        k = j + 1
        while k < len(tokens) and tokens[k] not in SEPARATORS:
            args.append(tokens[k])
            k += 1
        found.append((sub, args, start))
        i = k
    return found


def _short_flag_has(args: list[str], letter: str) -> bool:
    for arg in args:
        if arg.startswith("-") and not arg.startswith("--") and letter in arg[1:]:
            return True
    return False


def classify_git(sub: str, args: list[str]) -> str | None:
    """Return a block reason, or None to allow."""
    if sub == "reset" and "--hard" in args:
        return "git reset --hard discards uncommitted work"
    if sub == "clean" and (_short_flag_has(args, "f") or "--force" in args):
        return "git clean -f deletes untracked files"
    if sub == "branch":
        forced = "-D" in args or ("--delete" in args and ("--force" in args or _short_flag_has(args, "f")))
        if forced:
            return "git branch -D deletes an unmerged branch"
    if sub == "checkout":
        if "-f" in args or "--force" in args:
            return "git checkout -f discards local changes"
        if "." in args:
            return "git checkout . discards local changes"
    if sub == "restore":
        if "--worktree" in args or "." in args:
            return "git restore discards local changes"
    if sub == "push":
        leased = any(a == "--force-with-lease" or a.startswith("--force-with-lease=") for a in args)
        forced = (
            "-f" in args
            or "--force" in args
            or any(a.startswith("+") and not a.startswith("++") for a in args)
        )
        if forced and not leased:
            return "force push rewrites remote history"
    return None


def classify(command: str) -> str | None:
    for sub, args, _idx in git_invocations(tokenize(command)):
        reason = classify_git(sub, args)
        if reason:
            return reason
    return None


def main(argv: list[str]) -> int:
    if len(argv) == 3 and argv[1] == "--command":
        reason = classify(argv[2])
        if reason:
            print(f"block: {reason}")
            return 10
        print("allow")
        return 0
    print(__doc__, file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
