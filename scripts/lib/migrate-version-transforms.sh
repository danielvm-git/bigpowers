#!/usr/bin/env bash
# story: e44s03
if [ -n "${MIGRATE_VERSION_TRANSFORMS_LOADED:-}" ]; then return 0; fi
MIGRATE_VERSION_TRANSFORMS_LOADED=1
apply_transform() {
  local mig_id="$1" action="$2" tjson="$3"

  case "$action" in
    convert_md_to_yaml)
      local src tgt hm unc_count arch
      src="$(echo "$tjson" | $PYTHON -c "import json,sys; print(json.load(sys.stdin).get('source',''))")"
      tgt="$(echo "$tjson" | $PYTHON -c "import json,sys; print(json.load(sys.stdin).get('target',''))")"
      arch="$(echo "$tjson" | $PYTHON -c "import json,sys; print(json.load(sys.stdin).get('archive_source','false'))" 2>/dev/null)" || arch="false"
      if [ ! -f "$REPO_ROOT/$src" ]; then
        log_skip "$action: source '$src' not found"
        SKIPPED+=("$action:$src"); return
      fi
      hm="$(echo "$tjson" | $PYTHON -c "import json,sys; print(json.dumps(json.load(sys.stdin).get('heuristic_map',{})))")"
      $PYTHON -c "
import json, re, yaml, sys, os
src = '$REPO_ROOT/$src'
tgt = '$REPO_ROOT/$tgt'
heuristic_map = json.loads('''$hm''')
content = open(src).read()
result = {}
for md_key, yaml_key in heuristic_map.items():
    pat = re.compile(r'^' + re.escape(md_key.rstrip(':')) + r'\\s*[:=]\\s*(.+)$', re.MULTILINE | re.IGNORECASE)
    m = pat.search(content)
    if m:
        val = m.group(1).strip()
        try: val = yaml.safe_load(val) or val
        except: pass
        parts = yaml_key.split('.')
        cur = result
        for p in parts[:-1]:
            if p not in cur or not isinstance(cur[p], dict):
                cur[p] = {}
            cur = cur[p]
        cur[parts[-1]] = val
os.makedirs(os.path.dirname(tgt), exist_ok=True)
with open(tgt, 'w') as f:
    yaml.safe_dump(result, f, sort_keys=False, allow_unicode=True, width=100)
"
      unc_count="$(echo "$tjson" | $PYTHON -c "import json,sys; print(len(json.load(sys.stdin).get('uncertainty',[])))")"
      UNCERTAINTY_COUNT=$((UNCERTAINTY_COUNT + unc_count))
      # Archive source file if requested
      if [ "$arch" = "true" ] || [ "$arch" = "True" ]; then
        local archive_dir="$REPO_ROOT/specs/archive"
        mkdir -p "$archive_dir"
        mv "$REPO_ROOT/$src" "$archive_dir/"
        log_done "$action: $src -> $tgt (source archived to specs/archive/)"
      else
        log_done "$action: $src -> $tgt"
      fi
      ;;

    rename_file)
      local src tgt
      src="$(echo "$tjson" | $PYTHON -c "import json,sys; print(json.load(sys.stdin).get('source',''))")"
      tgt="$(echo "$tjson" | $PYTHON -c "import json,sys; print(json.load(sys.stdin).get('target',''))")"
      if [ ! -e "$REPO_ROOT/$src" ]; then
        log_skip "$action: source '$src' not found — idempotent"
        SKIPPED+=("$action:$src"); return
      fi
      if [ -e "$REPO_ROOT/$tgt" ]; then
        log_skip "$action: target '$tgt' already exists — idempotent"
        SKIPPED+=("$action:$src"); return
      fi
      mkdir -p "$(dirname "$REPO_ROOT/$tgt")"
      mv "$REPO_ROOT/$src" "$REPO_ROOT/$tgt"
      log_done "$action: $src -> $tgt"
      ;;

    move_file)
      local src tgt
      src="$(echo "$tjson" | $PYTHON -c "import json,sys; print(json.load(sys.stdin).get('source',''))")"
      tgt="$(echo "$tjson" | $PYTHON -c "import json,sys; print(json.load(sys.stdin).get('target',''))")"
      if [ ! -e "$REPO_ROOT/$src" ]; then
        log_skip "$action: source '$src' not found"
        SKIPPED+=("$action:$src"); return
      fi
      if [ -e "$REPO_ROOT/$tgt" ]; then
        log_skip "$action: target '$tgt' already exists — idempotent"
        SKIPPED+=("$action:$src"); return
      fi
      mkdir -p "$(dirname "$REPO_ROOT/$tgt")"
      mv "$REPO_ROOT/$src" "$REPO_ROOT/$tgt"
      log_done "$action: $src -> $tgt"
      ;;

    delete_file)
      local path
      path="$(echo "$tjson" | $PYTHON -c "import json,sys; print(json.load(sys.stdin).get('path',''))")"
      if [ ! -e "$REPO_ROOT/$path" ]; then
        log_skip "$action: '$path' not found — idempotent"
        SKIPPED+=("$action:$path"); return
      fi
      rm -f "$REPO_ROOT/$path"
      log_done "$action: $path"
      ;;

    set_yaml_key)
      local file key val if_missing
      file="$(echo "$tjson" | $PYTHON -c "import json,sys; print(json.load(sys.stdin).get('file',''))")"
      key="$(echo "$tjson" | $PYTHON -c "import json,sys; d=json.load(sys.stdin); print(d.get('path') or d.get('key',''))")"
      val="$(echo "$tjson" | $PYTHON -c "import json,sys; print(json.load(sys.stdin).get('value',''))")"
      if_missing="$(echo "$tjson" | $PYTHON -c "import json,sys; print(json.load(sys.stdin).get('if_missing','false'))" 2>/dev/null)" || if_missing="false"
      if [ "$if_missing" = "true" ] || [ "$if_missing" = "True" ]; then
        if migrate_yaml_get "$REPO_ROOT/$file" "$key" >/dev/null 2>&1; then
          log_skip "$action: $file $key already set (if_missing=true) — idempotent"
          SKIPPED+=("$action:$key")
          return
        fi
      fi
      $PYTHON "$YAML_TOOLS" set "$REPO_ROOT/$file" "$key" "$val"
      log_done "$action: $file $key = $val"
      ;;

    rename_yaml_key)
      local file old_key new_key old_val
      file="$(echo "$tjson" | $PYTHON -c "import json,sys; print(json.load(sys.stdin).get('file',''))")"
      old_key="$(echo "$tjson" | $PYTHON -c "import json,sys; print(json.load(sys.stdin).get('old_key',''))")"
      new_key="$(echo "$tjson" | $PYTHON -c "import json,sys; print(json.load(sys.stdin).get('new_key',''))")"
      old_val="$(migrate_yaml_get "$REPO_ROOT/$file" "$old_key" 2>/dev/null)" || true
      if [ -z "${old_val:-}" ]; then
        log_skip "$action: key '$old_key' not found in $file"
        SKIPPED+=("$action:$old_key"); return
      fi
      $PYTHON "$YAML_TOOLS" set "$REPO_ROOT/$file" "$new_key" "$old_val"
      $PYTHON -c "
import yaml
data = yaml.safe_load(open('$REPO_ROOT/$file'))
parts = '$old_key'.split('.')
cur = data
for p in parts[:-1]:
    if not isinstance(cur, dict): break
    cur = cur.get(p, {})
if isinstance(cur, dict) and parts[-1] in cur:
    del cur[parts[-1]]
with open('$REPO_ROOT/$file', 'w') as f:
    yaml.safe_dump(data, f, sort_keys=False, allow_unicode=True, width=100)
" 2>/dev/null
      log_done "$action: $file $old_key -> $new_key = $old_val"
      ;;

    delete_yaml_key)
      local file key
      file="$(echo "$tjson" | $PYTHON -c "import json,sys; print(json.load(sys.stdin).get('file',''))")"
      key="$(echo "$tjson" | $PYTHON -c "import json,sys; d=json.load(sys.stdin); print(d.get('path') or d.get('key',''))")"
      if ! migrate_yaml_get "$REPO_ROOT/$file" "$key" >/dev/null 2>&1; then
        log_skip "$action: key '$key' not found in $file — idempotent"
        SKIPPED+=("$action:$key"); return
      fi
      $PYTHON -c "
import yaml
data = yaml.safe_load(open('$REPO_ROOT/$file'))
parts = '$key'.split('.')
cur = data
for p in parts[:-1]:
    if not isinstance(cur, dict): break
    cur = cur.get(p, {})
if isinstance(cur, dict) and parts[-1] in cur:
    del cur[parts[-1]]
with open('$REPO_ROOT/$file', 'w') as f:
    yaml.safe_dump(data, f, sort_keys=False, allow_unicode=True, width=100)
" 2>/dev/null
      log_done "$action: $file $key"
      ;;

    create_file_from_template)
      local src tgt subs inline_tmpl
      src="$(echo "$tjson" | $PYTHON -c "import json,sys; print(json.load(sys.stdin).get('source',''))")"
      tgt="$(echo "$tjson" | $PYTHON -c "import json,sys; print(json.load(sys.stdin).get('target',''))")"
      subs="$(echo "$tjson" | $PYTHON -c "import json,sys; print(json.dumps(json.load(sys.stdin).get('substitutions',{})))")"
      inline_tmpl="$(echo "$tjson" | $PYTHON -c "import json,sys; print(json.load(sys.stdin).get('template',''))")"
      if [ -e "$REPO_ROOT/$tgt" ]; then
        log_skip "$action: target '$tgt' already exists — idempotent"
        SKIPPED+=("$action:$tgt"); return
      fi
      mkdir -p "$(dirname "$REPO_ROOT/$tgt")"
      # Inline template (content embedded in OKF bundle)
      if [ -n "$inline_tmpl" ]; then
        echo "$inline_tmpl" > "$REPO_ROOT/$tgt"
        if [ "$subs" != "{}" ]; then
          $PYTHON -c "
import json
subs = json.loads('''$subs''')
content = open('$REPO_ROOT/$tgt').read()
for k, v in subs.items():
    content = content.replace(k, v)
with open('$REPO_ROOT/$tgt', 'w') as f:
    f.write(content)
" 2>/dev/null
        fi
        log_done "$action: inline template -> $tgt"
        return
      fi
      # File-based template resolution
      template_path=""
      if [ -n "$src" ]; then
        # Try source as relative path first, then as template name
        if [ -f "$REPO_ROOT/$src" ]; then
          template_path="$REPO_ROOT/$src"
        elif [ -f "$REPO_ROOT/specs/templates/${src##*/}" ]; then
          template_path="$REPO_ROOT/specs/templates/${src##*/}"
        fi
      fi
      if [ -z "$template_path" ] || [ ! -f "$template_path" ]; then
        log_skip "$action: template not found (src='$src')"
        SKIPPED+=("$action:$src"); return
      fi
      cp "$template_path" "$REPO_ROOT/$tgt"
      $PYTHON -c "
import json
subs = json.loads('''$subs''')
content = open('$REPO_ROOT/$tgt').read()
for k, v in subs.items():
    content = content.replace(k, v)
with open('$REPO_ROOT/$tgt', 'w') as f:
    f.write(content)
" 2>/dev/null
      log_done "$action: $src -> $tgt"
      ;;

    *)
      log_skip "$action: unknown transform type"
      SKIPPED+=("$action")
      ;;
  esac
}
