#!/usr/bin/env bash
# story: e48s07
# publish-to-wiki.sh — publish OKF bundles to a .wiki.git repository
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HEADER="$ROOT/kernel/templates/wiki/header.md"
EPICS_SRC="$ROOT/specs/epics-wiki"
ADR_SRC="$ROOT/specs/adr-wiki"

usage() {
  echo "Usage: $0 [--dry-run]"
  echo "Publishes OKF concept bundles from specs/epics-wiki and specs/adr-wiki"
  echo "to the configured wiki git repository, rewriting links to wiki slug format."
  exit 0
}

wiki_slug_from_file() {
  local base
  base="$(basename "$1")"
  base="${base%.okf.md}"
  base="${base%.md}"
  echo "$base"
}

rewrite_links() {
  sed -E \
    -e 's/\]\(([^)]*)\.okf\.md\)/](\1)/g' \
    -e 's/\]\(([^)]*)\.md\)/](\1)/g' \
    -e 's/\]\(specs\/[^)]+\/([^/)]+)\)/](\1)/g'
}

stage_bundle() {
  local src="$1" section="$2" dest_root="$3"
  local slug dest_dir dest_file
  slug="$(wiki_slug_from_file "$src")"
  dest_dir="$dest_root/$section"
  dest_file="$dest_dir/${slug}.md"
  mkdir -p "$dest_dir"
  {
    if [[ -f "$HEADER" ]]; then cat "$HEADER"; echo ""; fi
    rewrite_links < "$src"
  } > "$dest_file"
  echo "$section/$slug.md"
}

collect_sources() {
  local dir="$1"
  if [[ -d "$dir" ]]; then
    find "$dir" -maxdepth 1 -name '*.okf.md' -type f | sort
  fi
}

publish_bundles() {
  local dest_root="$1"
  local -a pages=()
  local src

  rm -rf "$dest_root"
  mkdir -p "$dest_root"

  while IFS= read -r src; do
    [[ -n "$src" ]] || continue
    pages+=("$(stage_bundle "$src" "Epics" "$dest_root")")
  done < <(collect_sources "$EPICS_SRC")

  while IFS= read -r src; do
    [[ -n "$src" ]] || continue
    pages+=("$(stage_bundle "$src" "ADRs" "$dest_root")")
  done < <(collect_sources "$ADR_SRC")

  if [[ -f "$ROOT/kernel/templates/wiki/_Sidebar.md" ]]; then
    cp "$ROOT/kernel/templates/wiki/_Sidebar.md" "$dest_root/_Sidebar.md"
    pages+=("_Sidebar.md")
  fi

  printf '%s\n' "${pages[@]}"
}

push_to_wiki() {
  local staged_root="$1"
  local wiki_repo="${WIKI_REPO_URL:-}"
  local work_dir="${WIKI_WORK_DIR:-}"

  if [[ -z "$wiki_repo" ]]; then
    echo "publish-to-wiki: WIKI_REPO_URL is not set — skipping push" >&2
    return 0
  fi

  local clone_url="$wiki_repo"
  if [[ -n "${WIKI_PAT:-}" && "$wiki_repo" == https://* ]]; then
    clone_url="${wiki_repo/https:\/\//https://x-access-token:${WIKI_PAT}@}"
  fi

  if [[ -z "$work_dir" ]]; then
    work_dir="$(mktemp -d)"
    trap 'rm -rf "$work_dir"' EXIT
  fi

  if [[ -d "$work_dir/.git" ]]; then
    git -C "$work_dir" pull --rebase origin master 2>/dev/null || git -C "$work_dir" pull --rebase origin main
  else
    git clone "$clone_url" "$work_dir"
  fi

  rsync -a --delete "$staged_root/" "$work_dir/"
  git -C "$work_dir" add -A
  if git -C "$work_dir" diff --cached --quiet; then
    echo "publish-to-wiki: no wiki changes to push"
    return 0
  fi
  git -C "$work_dir" -c user.name="bigpowers-bot" -c user.email="bot@bigpowers.local" \
    commit -m "chore(wiki): sync OKF bundles from main"
  git -C "$work_dir" push origin HEAD
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
fi

DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
fi

STAGING="$(mktemp -d)"
trap 'rm -rf "$STAGING"' EXIT

mapfile -t PAGES < <(publish_bundles "$STAGING")
PAGE_COUNT="${#PAGES[@]}"

if [[ "$PAGE_COUNT" -eq 0 ]]; then
  echo "publish-to-wiki: no OKF bundles found under specs/epics-wiki or specs/adr-wiki" >&2
  exit 1
fi

echo "publish-to-wiki: pages: $PAGE_COUNT"
printf '  - %s\n' "${PAGES[@]}"

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "publish-to-wiki: dry-run complete (staged under $STAGING)"
  exit 0
fi

push_to_wiki "$STAGING"
