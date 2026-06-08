#!/usr/bin/env bash
# Read-only homelab container health sweep over SSH.
# Makes a single SSH round-trip and emits labeled, parseable blocks.
# Usage: sweep.sh [host]   (default: dockerhost-1)
#
# This script never mutates remote state. Every docker call is a query
# (ps / inspect / system df). Keep it that way.
set -uo pipefail

HOST="${1:-dockerhost-1}"

ssh -o ConnectTimeout=12 -o BatchMode=no "$HOST" 'bash -s' <<'REMOTE'
set -uo pipefail

echo "### HOST"
hostname 2>/dev/null
uptime 2>/dev/null

echo "### CONTAINERS"
# name|state|status|image  (State is running/exited/restarting/...; Status is the human string)
docker ps -a --format '{{.Names}}|{{.State}}|{{.Status}}|{{.Image}}' 2>/dev/null

echo "### HEALTH_UNHEALTHY"
docker ps --filter health=unhealthy --format '{{.Names}}' 2>/dev/null

echo "### RESTARTING"
docker ps --filter status=restarting --format '{{.Names}}' 2>/dev/null

echo "### RESTART_COUNTS"
# name|restartcount  — a climbing count between sweeps signals a crash loop.
for c in $(docker ps -aq 2>/dev/null); do
  name="$(docker inspect -f '{{.Name}}' "$c" 2>/dev/null | sed 's#^/##')"
  count="$(docker inspect -f '{{.RestartCount}}' "$c" 2>/dev/null)"
  printf '%s|%s\n' "$name" "$count"
done

echo "### DISK"
docker system df 2>/dev/null

echo "### END"
REMOTE

rc=$?
if [ $rc -ne 0 ]; then
  echo "### SSH_ERROR rc=$rc" >&2
fi
exit $rc
