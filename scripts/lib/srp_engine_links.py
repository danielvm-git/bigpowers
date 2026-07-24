"""Pi adapter link rewriting for srp-engine."""
from __future__ import annotations

import os

from link_utils import EXTERNAL_RE, LINK_RE, strip_code_spans


def rewrite_links_for_pi(body, name):
    """Repoint relative links so they resolve from .pi/skills/<name>/."""
    out_dir = os.path.join(".pi", "skills", name)
    shadow = strip_code_spans(body)

    def repl(m):
        text, raw_target = m.group(1), m.group(2).strip()
        if EXTERNAL_RE.match(raw_target) or raw_target.startswith(('#', '/')):
            return m.group(0)
        if '#' in raw_target:
            path_part, fragment = raw_target.split('#', 1)
            frag_suffix = '#' + fragment
        else:
            path_part, frag_suffix = raw_target, ''
        resolved = os.path.normpath(os.path.join("skills", name, path_part))
        if resolved.startswith(".."):
            return m.group(0)
        new_target = os.path.relpath(resolved, out_dir).replace(os.sep, '/') + frag_suffix
        return f"[{text}]({new_target})"

    return (
        LINK_RE.sub(repl, shadow).replace(shadow, body)
        if shadow == body
        else _apply_repl_on_real(body, shadow, name, out_dir)
    )


def _apply_repl_on_real(body, shadow, name, out_dir):
    """Apply link rewrites to body using shadow to skip code spans."""
    result = []
    last = 0
    for m in LINK_RE.finditer(shadow):
        result.append(body[last:m.start()])
        text, raw_target = m.group(1), m.group(2).strip()
        if EXTERNAL_RE.match(raw_target) or raw_target.startswith(('#', '/')):
            result.append(body[m.start():m.end()])
        else:
            if '#' in raw_target:
                path_part, fragment = raw_target.split('#', 1)
                frag_suffix = '#' + fragment
            else:
                path_part, frag_suffix = raw_target, ''
            resolved = os.path.normpath(os.path.join("skills", name, path_part))
            if resolved.startswith(".."):
                result.append(body[m.start():m.end()])
            else:
                new_target = os.path.relpath(resolved, out_dir).replace(os.sep, '/') + frag_suffix
                result.append(f"[{text}]({new_target})")
        last = m.end()
    result.append(body[last:])
    return ''.join(result)
