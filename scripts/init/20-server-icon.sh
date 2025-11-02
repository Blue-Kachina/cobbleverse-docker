#!/bin/sh
# Phase 5 — Server icon handling
# If SERVER_ICON is set to an http(s) URL, download it to /data/server-icon.png
# Runs on every container start; by default only downloads if missing.
# Set SERVER_ICON_UPDATE=true to force re-download each start.

set -eu

ICON_URL="${SERVER_ICON:-}"
FORCE_UPDATE="${SERVER_ICON_UPDATE:-}"
TARGET="/data/server-icon.png"

# No URL provided; exit quietly
if [ -z "$ICON_URL" ]; then
  exit 0
fi

# Only handle http(s) URLs
case "$ICON_URL" in
  http://*|https://*) ;;
  *)
    echo "[init:icon] SERVER_ICON is not an http(s) URL; skipping"
    exit 0
    ;;
esac

need_download=0
if [ ! -f "$TARGET" ]; then
  need_download=1
elif [ "${FORCE_UPDATE:-}" = "true" ] || [ "${FORCE_UPDATE:-}" = "1" ]; then
  need_download=1
fi

if [ "$need_download" -eq 0 ]; then
  echo "[init:icon] server-icon.png exists; skipping download"
  exit 0
fi

# Try curl, then wget
fetch() {
  url="$1"
  out="$2"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$out"
    return $?
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$out" "$url"
    return $?
  else
    return 127
  fi
}

if fetch "$ICON_URL" "$TARGET"; then
  echo "[init:icon] Downloaded server icon to $(basename "$TARGET")"
else
  echo "[init:icon] WARN: failed to download SERVER_ICON from $ICON_URL" >&2
fi
