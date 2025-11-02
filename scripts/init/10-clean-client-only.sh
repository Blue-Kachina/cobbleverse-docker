#!/bin/sh
# Phase 4 — Client-only mods cleanup
# This script runs inside the itzg/minecraft-server container on startup
# via the /data/init hook (mounted from ./scripts/init in docker-compose).
# It removes known client-only jars that can cause warnings or failures on a headless server.

set -eu

MODS_DIR="/data/mods"
[ -d "$MODS_DIR" ] || exit 0

# Known client-only or client-preference mods included by the pack.
# Adjust this list as needed for future pack updates.
CLIENT_ONLY_PATTERNS="
modmenu-*.jar
RoughlyEnoughItems-*.jar
sound-physics-remastered-*-fabric-*.jar
moreculling-fabric-*.jar
infinite-music-*.jar
MusicNotification-*.jar
Ping-Wheel-*.jar
particle-rain-*.jar
paginatedadvancements-*.jar
notenoughcrashes-*.jar
respackopts-*.jar
defaultoptions-*.jar
"

cleaned=0
for pattern in $CLIENT_ONLY_PATTERNS; do
  for file in "$MODS_DIR"/$pattern; do
    if [ -f "$file" ]; then
      echo "[init:client-clean] Removing client-only mod: $(basename "$file")"
      rm -f -- "$file"
      cleaned=$((cleaned+1))
    fi
  done
done

if [ "$cleaned" -gt 0 ]; then
  echo "[init:client-clean] Removed $cleaned client-only mod(s)."
else
  echo "[init:client-clean] No client-only mods found to remove."
fi
