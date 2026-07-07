#!/usr/bin/env bash
# story: e45s20
# doc-fetch-cache.sh — ETag-revalidated fetch cache for Context7 / bts docs queries.
# Usage:
#   bash scripts/lib/doc-fetch-cache.sh get <cache-key>     # print cached body or empty
#   bash scripts/lib/doc-fetch-cache.sh put <key> <etag> <body-file>
#   bash scripts/lib/doc-fetch-cache.sh stale <cache-key>   # exit 0 if TTL expired
set -euo pipefail

CACHE_DIR="${DOC_CACHE_DIR:-.bigpowers/cache/docs}"
TTL_SEC="${DOC_CACHE_TTL:-300}"

mkdir -p "$CACHE_DIR"

_key_path() {
  local key="$1"
  local hash
  hash=$(printf '%s' "$key" | shasum -a 256 | awk '{print $1}')
  echo "$CACHE_DIR/${hash}"
}

cmd_get() {
  local key="$1" base etag_file body_file meta_file
  base="$(_key_path "$key")"
  body_file="${base}.body"
  etag_file="${base}.etag"
  meta_file="${base}.meta"

  [[ -f "$body_file" && -f "$meta_file" ]] || exit 1

  local cached_at now
  cached_at=$(grep '^cached_at=' "$meta_file" | cut -d= -f2)
  now=$(date +%s)
  if [[ -n "$cached_at" && $((now - cached_at)) -gt "$TTL_SEC" ]]; then
    exit 1
  fi

  cat "$body_file"
  [[ -f "$etag_file" ]] && printf 'ETAG:%s\n' "$(cat "$etag_file")" >&2
  exit 0
}

cmd_put() {
  local key="$1" etag="$2" body_file="$3" base
  base="$(_key_path "$key")"
  cp "$body_file" "${base}.body"
  printf '%s' "$etag" > "${base}.etag"
  printf 'cached_at=%s\nkey=%s\n' "$(date +%s)" "$key" > "${base}.meta"
}

cmd_stale() {
  local key="$1" base meta_file
  base="$(_key_path "$key")"
  meta_file="${base}.meta"
  [[ -f "$meta_file" ]] || exit 0
  local cached_at now
  cached_at=$(grep '^cached_at=' "$meta_file" | cut -d= -f2)
  now=$(date +%s)
  [[ $((now - cached_at)) -gt "$TTL_SEC" ]] && exit 0
  exit 1
}

case "${1:-}" in
  get)   cmd_get "${2:?key}" ;;
  put)   cmd_put "${2:?key}" "${3:?etag}" "${4:?body}" ;;
  stale) cmd_stale "${2:?key}" ;;
  *)
    echo "Usage: doc-fetch-cache.sh get|put|stale <key> [etag] [body-file]" >&2
    exit 2
    ;;
esac
