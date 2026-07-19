# story: e38s01
# simple_yaml.py — Custom lightweight YAML parser extracted from trace-matrix.py.
import re

def parse_simple_yaml(text: str) -> dict:
    """Parse flat and one-level-nested YAML including lists of objects."""
    root: dict = {}
    # Each stack entry: (indent, container, parent_dict, key_in_parent)
    stack: list = [(0, root, None, None)]
    skip_until_indent = None  # indent of an active block scalar's key line
    block: dict = {}  # active block scalar: {'lines': [...], 'style': str, 'assign': fn}

    def flush_block():
        if block:
            block['assign'](_fold_block(block['lines'], block['style']))
            block.clear()

    for i, raw in enumerate(text.splitlines()):
        stripped = raw.strip()
        indent = len(raw) - len(raw.lstrip())

        # Inside a block scalar: capture continuation lines verbatim. Blank and
        # '#'-prefixed lines are literal content here, not comments.
        if skip_until_indent is not None:
            if not stripped or indent > skip_until_indent:
                if block:
                    block['lines'].append(raw)
                continue
            flush_block()
            skip_until_indent = None

        if not stripped or stripped.startswith("#"):
            continue
        
        # Pop stack until we're at the right nesting level
        # Don't pop list containers at same indent — sibling items stay in same list
        while len(stack) > 1:
            if indent < stack[-1][0]:
                stack.pop()
            elif indent == stack[-1][0]:
                # Same indent: pop dicts (moving to sibling key), keep lists (sibling items)
                if isinstance(stack[-1][1], list) and stripped.startswith("- "):
                    break  # stay in same list for next item
                elif isinstance(stack[-1][1], dict) and stripped.startswith("- "):
                    # dict at same indent with upcoming list item — convert to list
                    entry_container = stack[-1][1]
                    entry_parent = stack[-1][2]
                    entry_key = stack[-1][3]
                    if entry_parent is not None and entry_key is not None:
                        if not isinstance(entry_parent.get(entry_key), list):
                            entry_parent[entry_key] = []
                            stack[-1] = (stack[-1][0], entry_parent[entry_key], entry_parent, entry_key)
                            break
                    stack.pop()
                else:
                    stack.pop()  # other same-indent transitions
            else:
                break  # indent > stack indent — staying inside
        
        container = stack[-1][1]
        parent_dict = stack[-1][2]
        key_in_parent = stack[-1][3]
        
        # List item
        if stripped.startswith("- "):
            inner = stripped[2:]
            # Convert dict to list if needed (preserve original indent from dict push)
            if isinstance(container, dict) and parent_dict is not None and key_in_parent is not None:
                if not isinstance(parent_dict.get(key_in_parent), list):
                    orig_indent = stack[-1][0]
                    parent_dict[key_in_parent] = []
                    container = parent_dict[key_in_parent]
                    stack[-1] = (orig_indent, container, parent_dict, key_in_parent)
            
            if ":" in inner:
                k, _, v = inner.partition(":")
                k = k.strip()
                v = v.strip()
                # Detect block scalars in list items too
                if v in ("|", ">", "|-", ">-", "|+", ">+"):
                    item = {k: None}
                    container.append(item)
                    block.clear()
                    block.update(lines=[], style=v,
                                 assign=lambda s, _i=item, _k=k: _i.__setitem__(_k, s))
                    skip_until_indent = indent
                    continue
                item = {k: _yaml_scalar(v) if v else None}
                container.append(item)
                if v == "":
                    stack.append((indent, item, container, k))
            else:
                container.append(_yaml_scalar(inner))
            continue
        
        # Key: value
        if ":" not in stripped:
            continue
        key, _, val = stripped.partition(":")
        key = key.strip()
        val = val.strip()
        
        # Detect block scalars (|, >, |- etc.) and capture their folded content.
        if val in ("|", ">", "|-", ">-", "|+", ">+"):
            tgt = None
            if isinstance(container, list) and container:
                tgt = container[-1]
            elif isinstance(container, dict):
                tgt = container
            if tgt is not None:
                tgt[key] = None
                block.clear()
                block.update(lines=[], style=val,
                             assign=lambda s, _t=tgt, _k=key: _t.__setitem__(_k, s))
            skip_until_indent = indent
            continue
        
        if isinstance(container, list) and container:
            # Inside a list item dict
            container[-1][key] = _yaml_scalar(val) if val else None
            if val == "":
                nxt = {}
                container[-1][key] = nxt
                stack.append((indent, nxt, container[-1], key))
        elif isinstance(container, dict):
            if val == "":
                # Store as dict first; will convert to list if next line is "-"
                nxt = {}
                container[key] = nxt
                stack.append((indent, nxt, container, key))
            else:
                container[key] = _yaml_scalar(val)
    flush_block()
    return root


def _fold_block(raw_lines, style):
    """Fold a YAML block scalar (| literal / > folded) to match PyYAML."""
    # Strip the common leading indentation of the block's content lines.
    indents = [len(l) - len(l.lstrip()) for l in raw_lines if l.strip()]
    ci = min(indents) if indents else 0
    lines = [l[ci:] if len(l) >= ci else l.strip() for l in raw_lines]
    if style[0] == "|":  # literal: keep line breaks
        text = "\n".join(lines)
    else:  # folded: single break -> space, blank line -> newline
        parts, prev_blank = [], True
        for l in lines:
            if l == "":
                parts.append("\n")
                prev_blank = True
            else:
                if parts and not prev_blank:
                    parts.append(" ")
                parts.append(l)
                prev_blank = False
        text = "".join(parts)
    text = text.rstrip("\n")
    # Chomping indicator: '-' strip, default clip (single trailing newline).
    return text if style.endswith("-") else text + "\n"


def _yaml_scalar(val: str):
    """Convert a YAML scalar string to Python type."""
    stripped = val.strip()
    # Double-quoted scalar: unescape YAML escapes (\" and \\) like PyYAML, and
    # keep it a string (no bool/int coercion). Keeps the PyYAML-free fallback
    # byte-identical to PyYAML for quoted descriptions.
    if len(stripped) >= 2 and stripped[0] == '"' and stripped[-1] == '"':
        return stripped[1:-1].replace('\\"', '"').replace("\\\\", "\\")
    val = val.strip('"').strip("'")
    if val in ("true", "false"):
        return val == "true"
    if val in ("null", "~", ""):
        return None
    try:
        return int(val)
    except ValueError:
        try:
            return float(val)
        except ValueError:
            return val
