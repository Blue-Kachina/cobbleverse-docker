#!/bin/sh
# Phase 4 — Client-only mods cleanup (safety net)
# Runs before the modpack installer populates /data/mods. Primary filtering should be done by setting
# MODRINTH_EXCLUDE_FILES in .env so client-only mods are never installed. This script is a light safety net
# that removes any client-only jars that might slip through on subsequent starts when /data/mods exists.

set -eu

# Ensure we also log to persistent file
LOG_DIR="/data/logs"
LOG_FILE="$LOG_DIR/init-hooks.log"
mkdir -p "$LOG_DIR"
log() {
  # log to stdout and append to log file
  echo "$1"
  echo "$1" >> "$LOG_FILE" 2>&1
}

MODS_DIR="/data/mods"

# Always log start so users can see this hook ran
log "[init:client-clean] Starting client-only mods cleanup (mods dir: $MODS_DIR)"

# If mods directory is missing, log and exit instead of being silent
if [ ! -d "$MODS_DIR" ]; then
  log "[init:client-clean] Mods directory not present; nothing to clean. Skipping."
  exit 0
fi

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
      log "[init:client-clean] Removing client-only mod: $(basename \"$file\")"
      rm -f -- "$file"
      cleaned=$((cleaned+1))
    fi
  done
done

if [ "$cleaned" -gt 0 ]; then
  log "[init:client-clean] Removed $cleaned client-only mod(s)."
else
  log "[init:client-clean] No client-only mods found to remove."
fi
