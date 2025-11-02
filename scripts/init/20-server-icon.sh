#!/bin/sh
# Phase 5 — Server icon handling
# If SERVER_ICON is set to an http(s) URL, download it and ensure /data/server-icon.png is a 64x64 PNG.
# Runs on every container start; by default only downloads if missing.
# Set SERVER_ICON_UPDATE=true to force re-download each start.

set -eu

ICON_URL="${SERVER_ICON:-}"
FORCE_UPDATE="${SERVER_ICON_UPDATE:-}"
TARGET="/data/server-icon.png"

# If ICON env is set, let the base image handle downloading/conversion
if [ -n "${ICON:-}" ]; then
  echo "[init:icon] ICON env is set; deferring to base image for server icon handling"
  exit 0
fi

# No URL provided; exit quietly (but log for transparency)
if [ -z "$ICON_URL" ]; then
  echo "[init:icon] SERVER_ICON not set; skipping"
  exit 0
fi

# Determine icon source: local file (path or file://) or remote http(s)
SRC_MODE=""
SRC_PATH=""
case "$ICON_URL" in
  file://*)
    SRC_MODE="local"
    SRC_PATH="${ICON_URL#file://}"
    ;;
  /*|./*|../*)
    SRC_MODE="local"
    SRC_PATH="$ICON_URL"
    ;;
  http://*|https://*)
    SRC_MODE="remote"
    ;;
  *)
    echo "[init:icon] SERVER_ICON is not a recognized path or URL; skipping"
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

TMP_ICON=""
TMP_IS_TEMP=0
if [ "$SRC_MODE" = "remote" ]; then
  # Download to a temporary file first to allow conversion/validation
  TMP_ICON="$(mktemp /tmp/server-icon.XXXXXX || echo /tmp/server-icon.$$)"
  TMP_IS_TEMP=1
  if fetch "$ICON_URL" "$TMP_ICON"; then
    echo "[init:icon] Downloaded server icon to temporary file"
  else
    echo "[init:icon] WARN: failed to download SERVER_ICON from $ICON_URL" >&2
    rm -f "$TMP_ICON" 2>/dev/null || true
    exit 0
  fi
else
  # Local path; use directly
  if [ ! -f "$SRC_PATH" ]; then
    echo "[init:icon] WARN: local icon path not found: $SRC_PATH" >&2
    exit 0
  fi
  TMP_ICON="$SRC_PATH"
  echo "[init:icon] Using local icon: $SRC_PATH"
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
  if [ "$TMP_IS_TEMP" -eq 1 ]; then rm -f "$TMP_ICON" 2>/dev/null || true; fi
  exit 0
fi

# Helper: detect if a file is a PNG by magic bytes, independent of URL extension
is_png_by_magic() {
  sig="$(dd if="$1" bs=1 count=8 2>/dev/null | hexdump -v -e '8/1 "%02X"')" || sig=""
  [ "$sig" = "89504E470D0A1A0A" ]
}

# Fallbacks when conversion tools are unavailable
if is_png_by_magic "$TMP_ICON"; then
  # We cannot guarantee 64x64 without ImageMagick, but save as-is so at least PNG icons work
  cp -f "$TMP_ICON" "$TARGET"
  echo "[init:icon] Saved server icon from PNG content to $(basename "$TARGET")"
  if [ "$TMP_IS_TEMP" -eq 1 ]; then rm -f "$TMP_ICON" 2>/dev/null || true; fi
  exit 0
fi

# Final fallback: trust URL extension if .png
case "$ICON_URL" in
  *.png|*.PNG)
    mv -f "$TMP_ICON" "$TARGET"
    echo "[init:icon] Saved server icon (assumed PNG by URL) to $(basename "$TARGET")"
    ;;
  *)
    rm -f "$TMP_ICON" 2>/dev/null || true
    echo "[init:icon] WARN: Could not convert non-PNG icon (no ImageMagick). Provide a direct 64x64 PNG URL in SERVER_ICON or install ImageMagick (magick/convert) in the image."
    ;;
fi
