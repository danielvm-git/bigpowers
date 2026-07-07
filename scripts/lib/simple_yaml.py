# story: e38s01
# simple_yaml.py — Custom lightweight YAML parser extracted from trace-matrix.py.
import re

def parse_simple_yaml(text: str) -> dict:
    """Parse flat and one-level-nested YAML including lists of objects."""
    root: dict = {}
    # Each stack entry: (indent, container, parent_dict, key_in_parent)
    stack: list = [(0, root, None, None)]
    skip_until_indent = None  # skip block scalar continuation lines (| and >)
    for i, raw in enumerate(text.splitlines()):
        stripped = raw.strip()
        if not stripped or stripped.startswith("#"):
            # Reset block-scalar skip on blank lines
            continue
        indent = len(raw) - len(raw.lstrip())
        
        # Skip block scalar continuation (| and > in YAML)
        if skip_until_indent is not None:
            if indent > skip_until_indent:
                continue
            else:
                skip_until_indent = None
        
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
                    item = {k: v}
                    container.append(item)
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
        
        # Detect block scalars (|, >, |- etc.)
        if val in ("|", ">", "|-", ">-", "|+", ">+"):
            if isinstance(container, list) and container:
                container[-1][key] = val  # store the marker
            elif isinstance(container, dict):
                container[key] = val
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
    return root


def _yaml_scalar(val: str):
    """Convert a YAML scalar string to Python type."""
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
