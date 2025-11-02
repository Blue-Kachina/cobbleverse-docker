#!/bin/sh
# Phase 6 — Cobblemon spawn config export on first boot
# Purpose: Ensure Cobblemon exports its spawning config json files once, then disable the flag.
# Behavior:
#  - If /data/config/cobblemon/spawning already has files, set exportSpawnConfig=false and exit.
#  - Otherwise, set exportSpawnConfig=true in /data/config/cobblemon/main.json so first boot exports them.

set -eu

LOG_DIR="/data/logs"
LOG_FILE="$LOG_DIR/init-hooks.log"
mkdir -p "$LOG_DIR"
log() {
  echo "$1"
  echo "$1" >> "$LOG_FILE" 2>&1
}

CFG_DIR="/data/config/cobblemon"
CFG="$CFG_DIR/main.json"
SPAWN_DIR="$CFG_DIR/spawning"

# Describe intent
log "[init:cobblemon-spawns] Checking Cobblemon spawn export state"

# If config directory doesn't exist yet, just log and exit quietly.
if [ ! -d "$CFG_DIR" ]; then
  log "[init:cobblemon-spawns] $CFG_DIR not present yet; skipping (pack not installed yet?)"
  exit 0
fi

# Helper to set exportSpawnConfig using jq if present, else sed fallback
set_export_flag() {
  desired="$1" # true|false
  if [ ! -f "$CFG" ]; then
    log "[init:cobblemon-spawns] Config $CFG not found; skipping"
    return 0
  fi
  if command -v jq >/dev/null 2>&1; then
    tmp="$(mktemp)"
    if jq ".exportSpawnConfig = ${desired}" "$CFG" > "$tmp" 2>>"$LOG_FILE"; then
      mv "$tmp" "$CFG"
      log "[init:cobblemon-spawns] Set exportSpawnConfig=${desired} via jq"
      return 0
    else
      log "[init:cobblemon-spawns] jq failed to edit $CFG; falling back to sed"
      rm -f "$tmp" 2>/dev/null || true
    fi
  fi
  # sed fallback: replace true/false value; preserve commas/trailing content
  tmp="$CFG.tmp"
  if sed 's/\("exportSpawnConfig"[[:space:]]*:[[:space:]]*\)\(true\|false\)/\1'"${desired}"'/' "$CFG" > "$tmp" 2>>"$LOG_FILE"; then
    mv "$tmp" "$CFG"
    log "[init:cobblemon-spawns] Set exportSpawnConfig=${desired} via sed"
  else
    rm -f "$tmp" 2>/dev/null || true
    log "[init:cobblemon-spawns] Failed to modify $CFG"
    return 1
  fi
}

# Determine if spawning files already exist (any .json files inside spawning/)
if [ -d "$SPAWN_DIR" ] && ls -A "$SPAWN_DIR" >/dev/null 2>&1; then
  # Already exported previously; ensure flag is disabled
  set_export_flag false || true
  log "[init:cobblemon-spawns] Spawning config already present; ensured exportSpawnConfig=false"
  exit 0
fi

# No spawning files yet; enable export for the upcoming first boot
set_export_flag true || true
log "[init:cobblemon-spawns] Enabled exportSpawnConfig=true to export spawning config on next server start"

exit 0
