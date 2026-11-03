#!/usr/bin/env bash
# story: e58s07
# ab-sandbox.sh — up|down|status for the A/B eval Docker sandbox.
#
# up      builds the pinned agent and proxy images, creates an internal network (no route to the
#         internet) plus a bridge only the proxy joins, and starts the proxy.
# down    stops the proxy and removes the networks. Images stay cached.
# status  exit 0 only when both images exist, both networks exist and the proxy is running.
set -euo pipefail

AGENT_IMAGE="bp-ab-agent:pi-1.5.0"
PROXY_IMAGE="bp-ab-proxy:tinyproxy-1"
PROXY_NAME="bp-ab-proxy"
INTERNAL_NET="bp-ab-internal"
EGRESS_NET="bp-ab-egress"
ASSETS="$(cd "$(dirname "${BASH_SOURCE[0]}")/lib/ab-sandbox" && pwd)"

die() { echo "ERROR: $*" >&2; exit 1; }

have_image() { docker image inspect "$1" >/dev/null 2>&1; }
have_net() { docker network inspect "$1" >/dev/null 2>&1; }
proxy_running() { [ "$(docker inspect -f '{{.State.Running}}' "$PROXY_NAME" 2>/dev/null)" = "true" ]; }

build() {
  echo "Building $AGENT_IMAGE"
  docker build -q -f "$ASSETS/agent.Dockerfile" -t "$AGENT_IMAGE" "$ASSETS" >/dev/null
  echo "Building $PROXY_IMAGE"
  docker build -q -f "$ASSETS/proxy.Dockerfile" -t "$PROXY_IMAGE" "$ASSETS" >/dev/null
}

ensure_networks() {
  have_net "$INTERNAL_NET" || docker network create --internal "$INTERNAL_NET" >/dev/null
  have_net "$EGRESS_NET" || docker network create "$EGRESS_NET" >/dev/null
}

wait_for_proxy() {
  local i
  for i in $(seq 1 30); do
    if docker exec "$PROXY_NAME" sh -c 'nc -z 127.0.0.1 8888' >/dev/null 2>&1; then
      echo "Proxy listening on $INTERNAL_NET:8888"
      return 0
    fi
    sleep 1
  done
  docker logs "$PROXY_NAME" >&2 || true
  die "proxy did not start listening"
}

cmd_up() {
  build
  ensure_networks
  # The proxy joins the internal network first, then the bridge: the agent side can only see it.
  docker rm -f "$PROXY_NAME" >/dev/null 2>&1 || true
  docker run -d --name "$PROXY_NAME" --network "$INTERNAL_NET" --restart unless-stopped \
    "$PROXY_IMAGE" >/dev/null
  docker network connect "$EGRESS_NET" "$PROXY_NAME"
  wait_for_proxy
  echo "Sandbox up: $AGENT_IMAGE on $INTERNAL_NET (internet only via $PROXY_NAME, allowlist: opencode.ai)"
}

cmd_down() {
  docker rm -f "$PROXY_NAME" >/dev/null 2>&1 || true
  docker network rm "$INTERNAL_NET" >/dev/null 2>&1 || true
  docker network rm "$EGRESS_NET" >/dev/null 2>&1 || true
  echo "Sandbox down (images kept)"
}

cmd_status() {
  local ok=0
  for image in "$AGENT_IMAGE" "$PROXY_IMAGE"; do
    if have_image "$image"; then echo "image    $image"; else echo "MISSING  $image"; ok=1; fi
  done
  for net in "$INTERNAL_NET" "$EGRESS_NET"; do
    if have_net "$net"; then echo "network  $net"; else echo "MISSING  $net"; ok=1; fi
  done
  if proxy_running; then echo "proxy    $PROXY_NAME running"; else echo "MISSING  $PROXY_NAME running"; ok=1; fi
  return "$ok"
}

case "${1:-status}" in
  up) cmd_up ;;
  down) cmd_down ;;
  status) cmd_status ;;
  *) die "usage: $(basename "$0") up|down|status" ;;
esac
