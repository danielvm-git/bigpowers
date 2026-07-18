#!/usr/bin/env python3
# story: e48s15
import os
import sys
import json
import glob
import subprocess
import yaml

# Ensure scripts/lib is on the path so link_utils resolves regardless of cwd.
_LIB_DIR = os.path.dirname(os.path.abspath(__file__))
if _LIB_DIR not in sys.path:
    sys.path.insert(0, _LIB_DIR)

from link_utils import LINK_RE, EXTERNAL_RE, strip_code_spans  # noqa: E402

def rewrite_links_for_pi(body, name):
    """Repoint relative links so they resolve from .pi/skills/<name>/.

    Sibling *.md content is inlined into the rendered SKILL.md body, but the
    links to those files (and to repo-root docs) still point at paths relative
    to the source dir, so they dangle in the rendered tree. Repoint them at
    the shipped source tree (skills/, profiles/, repo-root files) so links
    resolve in repo checkouts and npm installs alike. External, anchor, and
    absolute links pass through untouched.

    Code fences and inline code are skipped — links inside them are examples,
    not navigation targets.
    """
    out_dir = os.path.join(".pi", "skills", name)
    # Build a "shadow" copy with code spans blanked out so LINK_RE never
    # matches inside ``` blocks or inline `code`.
    shadow = strip_code_spans(body)

    def repl(m):
        # If this match falls inside a code span the shadow char is a space;
        # the real body char at that position is not a '[' — so LINK_RE won't
        # match in the shadow at all.  The sub() runs on the shadow but we
        # return the replacement for the real body using the captured groups.
        text, raw_target = m.group(1), m.group(2).strip()
        if EXTERNAL_RE.match(raw_target) or raw_target.startswith(('#', '/')):
            return m.group(0)
        # Split fragment before normpath to avoid mangling '#section/sub'.
        if '#' in raw_target:
            path_part, fragment = raw_target.split('#', 1)
            frag_suffix = '#' + fragment
        else:
            path_part, frag_suffix = raw_target, ''
        resolved = os.path.normpath(os.path.join("skills", name, path_part))
        if resolved.startswith(".."):
            return m.group(0)  # escapes repo root; leave untouched
        new_target = os.path.relpath(resolved, out_dir).replace(os.sep, '/') + frag_suffix
        return f"[{text}]({new_target})"

    return LINK_RE.sub(repl, shadow).replace(shadow, body) if shadow == body else _apply_repl_on_real(body, shadow, name, out_dir)


def _apply_repl_on_real(body, shadow, name, out_dir):
    """Apply link rewrites to *body* using *shadow* to skip code spans.

    Iterates LINK_RE matches on *shadow* (which has code spans blanked) and
    rebuilds body with only the matched positions replaced.
    """
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

def resolve_repo_root():
    lib_dir = os.path.dirname(os.path.abspath(__file__))
    # scripts/lib/srp-engine.py -> two levels up is REPO_ROOT
    repo_candidate = os.path.dirname(os.path.dirname(lib_dir))
    if os.path.isdir(os.path.join(repo_candidate, "skills")):
        return repo_candidate
    return os.path.dirname(lib_dir)

def parse_skill(skill_md_path):
    if not os.path.isfile(skill_md_path):
        print(f"Error: file not found {skill_md_path}", file=sys.stderr)
        sys.exit(1)

    skill_dir = os.path.dirname(skill_md_path)

    # Read file content
    with open(skill_md_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Split frontmatter and body
    parts = content.split('---')
    if len(parts) < 3:
        print(f"Error: invalid SKILL.md format in {skill_md_path}", file=sys.stderr)
        sys.exit(1)

    frontmatter_raw = parts[1]
    # The body of SKILL.md starts after the second '---'
    skill_body = '---'.join(parts[2:])

    try:
        frontmatter = yaml.safe_load(frontmatter_raw)
    except Exception as e:
        print(f"Error parsing YAML frontmatter in {skill_md_path}: {e}", file=sys.stderr)
        sys.exit(1)

    if not isinstance(frontmatter, dict):
        print(f"Error: frontmatter is not a dictionary in {skill_md_path}", file=sys.stderr)
        sys.exit(1)

    name = frontmatter.get('name', '')
    description = frontmatter.get('description', '')
    effort = frontmatter.get('effort', 'standard')
    model = frontmatter.get('model', '')

    # Compile the full body (including other *.md files in the directory)
    body = skill_body.strip()
    extra_files = glob.glob(os.path.join(skill_dir, "*.md"))
    # Filter out SKILL.md
    extra_files = [f for f in extra_files if os.path.basename(f) != "SKILL.md"]
    # Sort them by name (ASCII sorting as in LC_ALL=C sort)
    extra_files.sort()

    for extra_file in extra_files:
        with open(extra_file, 'r', encoding='utf-8') as f:
            extra_content = f.read()
        body += "\n\n---\n\n" + extra_content.strip()

    # Remove lines containing 'disable-model-invocation'
    body_lines = body.splitlines()
    body_lines = [line for line in body_lines if 'disable-model-invocation' not in line]
    body = '\n'.join(body_lines)

    return {
        'name': name,
        'description': description,
        'effort': effort,
        'model': model,
        'body': body
    }

def get_active_adapters(repo_root):
    targets_file = os.path.join(repo_root, "scripts", "targets.yaml")
    if not os.path.isfile(targets_file):
        return ["cursor", "gemini", "pi"]
    try:
        with open(targets_file, 'r', encoding='utf-8') as f:
            data = yaml.safe_load(f)
        adapters = []
        for target in data.get('targets', []):
            if target.get('skill') is not None:
                adapter = target['skill'].get('adapter')
                if adapter and adapter not in adapters:
                    adapters.append(adapter)
        return sorted(adapters)
    except Exception as e:
        print(f"Warning: error reading targets.yaml: {e}", file=sys.stderr)
        return ["cursor", "gemini", "pi"]

def iterate_skills(repo_root):
    skills_root = os.path.join(repo_root, "skills")
    if not os.path.isdir(skills_root):
        skills_root = repo_root
    
    skills = []
    for entry in os.listdir(skills_root):
        skill_dir = os.path.join(skills_root, entry)
        if os.path.isdir(skill_dir):
            skill_md = os.path.join(skill_dir, "SKILL.md")
            if os.path.isfile(skill_md):
                skills.append(skill_md)
    return sorted(skills)

def render_okf_concept(skill_data, okf_wiki_skills):
    name = skill_data['name']
    model = skill_data['model']
    effort = skill_data['effort']
    description = skill_data['description']
    
    os.makedirs(okf_wiki_skills, exist_ok=True)
    okf_file = os.path.join(okf_wiki_skills, f"{name}.md")
    
    phase = "utility"
    critical_path_skills = {
        "survey-context", "elaborate-spec", "model-domain", "define-language",
        "design-interface", "plan-work", "plan-release", "slice-tasks",
        "kickoff-branch", "develop-tdd", "verify-work", "audit-code",
        "commit-message", "release-branch", "security-review",
        "assess-impact", "investigate-bug", "validate-fix", "dispatch-agents",
        "request-review", "respond-review", "hook-commits", "guard-git",
        "wire-observability", "wire-ci", "smoke-test", "deploy", "enforce-first"
    }
    if name in critical_path_skills:
        phase = "critical-path"
        
    title = name.replace("-", " ").title()
    desc_escaped = description.replace("\\", "\\\\").replace('"', '\\"')
    
    lines = [
        "---",
        "okf_kind: concept",
        "type: Skill",
        f"id: {name}",
        f'title: "{title}"',
        f"name: {name}",
        "category: skills"
    ]
    if model:
        lines.append(f"model: {model}")
    lines.extend([
        f"effort: {effort}",
        f"phase: {phase}",
        f'description: "{desc_escaped}"',
        "references: []",
        "---",
        "",
        f"# {title}",
        "",
        f"**Phase:** {phase}"
    ])
    if model:
        lines.append(f"**Model:** {model}")
    lines.extend([
        f"**Effort:** {effort}",
        "",
        description,
        "",
        f"> Auto-generated by sync-skills.sh --okf (e39s04) from skills/{name}/SKILL.md"
    ])
    
    with open(okf_file, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines) + '\n')

def dispatch_to_adapter(skill_data, target, repo_root):
    adapter_path = os.path.join(repo_root, "scripts", "adapters", f"{target}.sh")
    if not os.path.isfile(adapter_path):
        print(f"Error: adapter not found: {adapter_path}", file=sys.stderr)
        sys.exit(1)

    # Pipe JSON to the adapter
    proc = subprocess.Popen(
        ['bash', adapter_path],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    stdout, stderr = proc.communicate(input=json.dumps(skill_data))

    if stdout:
        print(stdout, end="")
    if stderr:
        print(stderr, end="", file=sys.stderr)

    if proc.returncode != 0:
        print(f"Error: adapter {target} failed with exit code {proc.returncode}", file=sys.stderr)
        sys.exit(proc.returncode)

def main():
    repo_root = resolve_repo_root()

    if "--all" in sys.argv:
        okf_mode = "--okf" in sys.argv
        skills = iterate_skills(repo_root)
        adapters = get_active_adapters(repo_root)

        okf_wiki_skills = os.environ.get("OKF_WIKI_SKILLS", os.path.join(repo_root, "specs", "skills-wiki", "skills"))

        for skill_md in skills:
            skill_data = parse_skill(skill_md)
            if not skill_data['name']:
                continue

            for adapter in adapters:
                data = skill_data
                if adapter == "pi":
                    data = dict(skill_data)
                    data["body_pi_skill"] = rewrite_links_for_pi(skill_data['body'], skill_data['name'])
                dispatch_to_adapter(data, adapter, repo_root)

            if okf_mode:
                render_okf_concept(skill_data, okf_wiki_skills)
        return

    if len(sys.argv) < 2:
        print("Usage: srp-engine.py <path-to-SKILL.md> [--dry-run] [--target <target>]", file=sys.stderr)
        print("       srp-engine.py --all [--okf]", file=sys.stderr)
        sys.exit(1)

    skill_md_path = sys.argv[1]
    dry_run = "--dry-run" in sys.argv
    target = None

    if "--target" in sys.argv:
        try:
            target_idx = sys.argv.index("--target")
            target = sys.argv[target_idx + 1]
        except (ValueError, IndexError):
            print("Error: --target requires an argument", file=sys.stderr)
            sys.exit(1)

    skill_data = parse_skill(skill_md_path)

    if target == "pi":
        skill_data = dict(skill_data)
        skill_data["body_pi_skill"] = rewrite_links_for_pi(skill_data['body'], skill_data['name'])

    if dry_run or not target:
        print(json.dumps(skill_data, indent=2))
        return

    dispatch_to_adapter(skill_data, target, repo_root)

if __name__ == "__main__":
    main()
