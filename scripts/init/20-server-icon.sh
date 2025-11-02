#!/bin/sh
# Phase 5 — Server icon handling (simplified)
# Decision: rely entirely on itzg/minecraft-server's ICON handling.
# docker-compose maps ICON: "${SERVER_ICON:-}", so the base image will fetch/convert and place /data/server-icon.png.
# This script now only logs the effective icon and exits.

set -eu

TARGET="/data/server-icon.png"
ICON_VAL="${ICON:-}"
SERVER_ICON_VAL="${SERVER_ICON:-}"

if [ -n "$ICON_VAL" ]; then
  echo "[init:icon] ICON is set ($ICON_VAL); base image will manage $TARGET"
elif [ -n "$SERVER_ICON_VAL" ]; then
  echo "[init:icon] SERVER_ICON is set ($SERVER_ICON_VAL); compose maps it to ICON and the base image will manage $TARGET"
else
  echo "[init:icon] No icon configured; skipping (set SERVER_ICON to a URL to enable)"
fi

exit 0
