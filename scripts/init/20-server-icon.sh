#!/bin/sh
# Phase 5 — Server icon handling
# If SERVER_ICON is set to an http(s) URL, download it and ensure /data/server-icon.png is a 64x64 PNG.
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

# Download to a temporary file first to allow conversion/validation
TMP_ICON="$(mktemp /tmp/server-icon.XXXXXX || echo /tmp/server-icon.$$)"
if fetch "$ICON_URL" "$TMP_ICON"; then
  echo "[init:icon] Downloaded server icon to temporary file"
else
  echo "[init:icon] WARN: failed to download SERVER_ICON from $ICON_URL" >&2
  rm -f "$TMP_ICON" 2>/dev/null || true
  exit 0
fi

# Attempt to normalize to 64x64 PNG using ImageMagick if available
convert_ok=0
if command -v magick >/dev/null 2>&1; then
  if magick identify "$TMP_ICON" >/dev/null 2>&1; then
    if magick "$TMP_ICON" -resize 64x64\! -type TrueColor PNG:"$TARGET" >/dev/null 2>&1; then
      convert_ok=1
    fi
  fi
elif command -v convert >/dev/null 2>&1; then
  if convert "$TMP_ICON" -resize 64x64\! -type TrueColor PNG:"$TARGET" >/dev/null 2>&1; then
    convert_ok=1
  fi
fi

if [ "$convert_ok" -eq 1 ]; then
  echo "[init:icon] Saved server icon as 64x64 PNG at $(basename "$TARGET")"
  rm -f "$TMP_ICON" 2>/dev/null || true
  exit 0
fi

# Fallback: if URL appears to be a PNG, use it as-is; else warn and still copy
case "$ICON_URL" in
  *.png|*.PNG)
    mv -f "$TMP_ICON" "$TARGET"
    echo "[init:icon] Saved server icon (assumed PNG) to $(basename "$TARGET")"
    ;;
  *)
    mv -f "$TMP_ICON" "$TARGET"
    echo "[init:icon] NOTE: Saved icon without conversion. If the URL isn't a PNG, Minecraft may ignore it. Install ImageMagick in the image to enable auto-conversion."
    ;;
fi
