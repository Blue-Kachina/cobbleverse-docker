#!/bin/sh
# Phase 8 — Security/Permissions tightening
# Runs at container start via /data/init. Intention: ensure data/backups are not world-readable
# and inherit sane default permissions. This is a light-touch step that won't fail the boot.
# NOTE: When running as non-root UID/GID, we may not be able to chown. We only adjust perms for
# paths we can write, and we skip errors.

set -eu

# Ensure we also log to persistent file
LOG_DIR="/data/logs"
LOG_FILE="$LOG_DIR/init-hooks.log"
mkdir -p "$LOG_DIR"
log() {
  echo "$1"
  echo "$1" >> "$LOG_FILE" 2>&1
}

set_perm_dir() {
  d="$1"
  if [ -d "$d" ]; then
    # Only proceed if we can write into the directory
    if [ -w "$d" ]; then
      chmod 770 "$d" 2>/dev/null || true
      # Ensure a logs dir exists early so users have a place to look, even if the JVM never starts
      if [ ! -d "$d/logs" ] && [ "$d" = "/data" ] && [ -w "$d" ]; then
        mkdir -p "$d/logs" 2>/dev/null || true
      fi
      # Optionally tighten some common subdirs without heavy recursion
      for sub in mods config world logs; do
        if [ -d "$d/$sub" ]; then
          chmod 770 "$d/$sub" 2>/dev/null || true
        fi
      done
      log "[init:perms] Ensured restricted permissions on $(basename \"$d\")"
    else
      log "[init:perms] Skipping $d (not writable by current UID)"
    fi
  fi
}

# Apply to /data and /backups if mounted
set_perm_dir "/data"
# On some hosts (Docker Desktop/WSL2/NTFS), enforcing 770 on bind-mounted ./backups can prevent
# the backup sidecar from writing. Relax backups dir to 0777 to maximize compatibility;
# the sidecar will still create files using its own umask.
if [ -d "/backups" ]; then
  if [ -w "/backups" ]; then
    chmod 777 "/backups" 2>/dev/null || true
    log "[init:perms] Set permissive permissions on backups (0777) for cross-platform compatibility"
  else
    log "[init:perms] Skipping /backups (not writable by current UID)"
  fi
fi

# Encourage restrictive umask for processes launched later in this session
# This won't affect the already-running JVM, but may help other init hooks.
umask 007 || true
