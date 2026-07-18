#!/usr/bin/env python3
"""link_utils.py — shared Markdown link patterns used by srp-engine and check-skill-links.

Single source of truth for what constitutes a "link" so the rewriter and the
regression gate always agree on the definition.
"""
import re

# Matches standard Markdown links — with or without an optional title attribute.
#   [text](target)
#   [text](target "title")
# Group 1: link text, Group 2: raw target (may include URL fragment)
LINK_RE = re.compile(
    r'\[([^\]]*)\]\('       # [text](
    r'([^)\s"]+)'           # target (no spaces, no quotes)
    r'(?:\s+"[^"]*")?'      # optional title attribute: "title text"
    r'\s*\)'                # closing )
)

# Matches scheme-prefixed (non-relative) URLs that should never be rewritten
# or resolved as local file paths.
EXTERNAL_RE = re.compile(r'(?i)^(https?|ftp|file|mailto):')

# Detects machine-absolute paths that must not appear in skill docs.
# Covers macOS (/Users/), Linux (/home/), and Windows (C:\Users, D:\Users …).
MACHINE_PATH_RE = re.compile(r'file:///|/Users/|/home/|[A-Z]:\\Users')

# ---------------------------------------------------------------------------
# Markdown code-block stripping
# ---------------------------------------------------------------------------

# Fenced code block: ``` or ~~~ with optional language tag, any content, close fence.
_FENCED_BLOCK_RE = re.compile(r'(?m)^(`{3,}|~{3,})[^\n]*\n.*?\n\1\s*$', re.DOTALL)
# Inline code: `…` (single backtick, non-empty)
_INLINE_CODE_RE = re.compile(r'`[^`\n]+`')


def strip_code_spans(text: str) -> str:
    """Return *text* with fenced blocks and inline code replaced by blank space.

    Preserves original character positions so that any offset-based logic
    remains valid; only the link-matching content is neutralised.
    """
    def _blank(m: re.Match) -> str:
        return ' ' * len(m.group(0))

    text = _FENCED_BLOCK_RE.sub(_blank, text)
    text = _INLINE_CODE_RE.sub(_blank, text)
    return text
