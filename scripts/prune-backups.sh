#!/bin/sh
# prune-backups.sh
# Deletes oldest files in /backups when count exceeds BACKUP_MAX_BACKUPS
# Safe for repeated runs; no action when BACKUP_MAX_BACKUPS unset/zero

set -eu

MAX="${BACKUP_MAX_BACKUPS:-}"
if [ -z "$MAX" ] || [ "$MAX" = "0" ]; then
  echo "[prune] BACKUP_MAX_BACKUPS not set or zero; skipping prune"
  exit 0
fi

if [ ! -d "/backups" ]; then
  echo "[prune] /backups not mounted; skipping"
  exit 0
fi

# List regular files sorted by modification time NEWEST first
# BusyBox-compatible: use ls -1t and then trim to only files that exist
FILES=$(ls -1t /backups/* 2>/dev/null || true)
if [ -z "${FILES:-}" ]; then
  echo "[prune] No backup files found"
  exit 0
fi

# Count lines (each is a file path)
COUNT=$(printf "%s\n" "$FILES" | wc -l | tr -d ' ')
if [ "$COUNT" -le "$MAX" ]; then
  echo "[prune] Current files: $COUNT, max: $MAX; nothing to prune"
  exit 0
fi

TO_DELETE=$((COUNT - MAX))

echo "[prune] Pruning $TO_DELETE oldest backup(s) to enforce max $MAX (current $COUNT)"

# Oldest files are at the end of the ls -1t list; delete the last TO_DELETE entries
printf "%s\n" "$FILES" | tail -n "$TO_DELETE" | while IFS= read -r f; do
  if [ -f "$f" ]; then
    echo "[prune] Deleting $f"
    rm -f -- "$f" || echo "[prune] Failed to delete $f"
  fi
done

echo "[prune] Done"
