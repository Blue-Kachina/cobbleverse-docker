#!/bin/sh
# Simple verifier that proves init hooks are being executed
# This script will log to stdout (visible in Docker Desktop / docker compose logs)
# and also write to /data/logs/init-hooks.log inside the container (persisted on host under ./data/logs).

set -eu

LOG_DIR="/data/logs"
LOG_FILE="$LOG_DIR/init-hooks.log"
mkdir -p "$LOG_DIR"

now() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

msg="[init:verify] $(now) init hooks are active; running $0 as $(id -u):$(id -g)"
echo "$msg"
# Also write to persistent log file
{
  echo "$msg"
  echo "[init:verify] $(now) ENV ICON=${ICON:-} SERVER_ICON=${SERVER_ICON:-}"
} >> "$LOG_FILE" 2>&1

exit 0
