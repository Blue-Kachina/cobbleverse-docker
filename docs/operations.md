# Operations: Backups, Updates, and Monitoring (Phase 7)

This document describes how backups are created and restored, how to safely update the server/modpack, and how to monitor the server.

Date: 2025-11-01

## Backups

This repository enables automated backups using a lightweight sidecar container (itzg/mc-backup). Backups are stored under ./backups on the host and rotated based on retention.

- Schedule: configurable via BACKUP_INTERVAL in .env (default 24h)
- Retention: configurable via BACKUP_PRUNE_DAYS in .env (default 14 days)
- Location: backups directory at the repository root (mounted to /backups in the backup sidecar)
- Content: the entire /data directory (world, configs, mods) is archived as tar files

You can also trigger on-demand backups by restarting the backup container or invoking a backup job inside it (see the mc-backup docs), but the daily schedule covers most needs.

### Verify backups are being created
1) Start the stack: docker compose up -d
2) After the first interval completes (or after forcing a run), list backups:
   - dir backups
   - You should see files like cobbleverse-server-data-YYYYmmdd-HHMMSS.tar.gz

### Restore procedure (Acceptance criteria)
To restore a backup into a fresh data directory:

1) Stop the server:
   - docker compose down
2) Move aside or remove current data (keep a copy just in case):
   - Rename data to data.bak-<timestamp>
3) Choose a backup archive from ./backups (latest is usually fine):
   - Example: cobbleverse-server-data-2025-10-31-230000.tar.gz
4) Extract it into a new, empty data directory:
   - mkdir data
   - On Linux/macOS: tar -xzvf backups/<archive> -C data --strip-components=1
   - On Windows (PowerShell):
     - Use tar if available: tar -xzf .\backups\<archive> -C .\data
5) Start the server:
   - docker compose up -d
6) Watch logs and confirm a normal startup:
   - docker compose logs -f mc

If the server reaches "Done" and your world loads, restore is successful.

## Updates

The modpack URL is pinned to a specific version (COBBLEVERSE 1.6). Follow a staged approach to update:

1) Staging world/test:
   - Make a copy of the whole repo to a staging folder or use a separate compose project name.
   - Start the server with a test world (set SERVER_WORLDNAME to a throwaway value in staging .env).
   - Confirm startup completes, no critical errors, basic gameplay works.
2) Promote:
   - Schedule downtime and notify players.
   - Back up production (wait for the next scheduled backup or make a manual backup).
   - Update MODRINTH_MODPACK/MODRINTH_URL to the new .mrpack URL or bump version variables if applicable.
   - Optionally set STOP_SERVER_ANNOUNCE_DELAY=30 (or more) to allow a graceful in-game countdown.
   - docker compose up -d to apply changes. The itzg image will download and install updated content.
3) Post-update:
   - Verify logs, ensure world opens, check for missing/extra mods.
   - If problems arise, stop and restore from the last known-good backup (see Restore procedure).

Notes:
- REMOVE_OLD_MODS=true keeps mods tidy across updates.
- USE_MODPACK_CACHE=true speeds up re-installation.

## Graceful restarts and announcements

The itzg/minecraft-server image can announce an impending stop to connected players when STOP_SERVER_ANNOUNCE_DELAY is set. This repository maps STOP_SERVER_ANNOUNCE_DELAY from .env (default 15). Use numeric seconds only (do not include a unit). Combine with RCON to perform scheduled messages if desired.

## Monitoring and access

Lightweight options:
- Enable RCON by setting RCON_PASSWORD in .env. This allows using mc-send-to-console and some monitoring tools.
- Optional healthcheck: docker-compose contains a commented healthcheck using mc-monitor.
- External tools:
  - itzg/mc-monitor: query status, latency, and basic player info.
  - Prometheus exporters (optional) can be added as sidecars if you need metrics scraping.

Security note: treat RCON_PASSWORD as a secret. Avoid committing real credentials to version control. Prefer injecting via environment or a secrets manager in production deployments.


## Startup commands (RCON) and gamerules

You can run one-time or recurring console commands automatically at server startup using the itzg/minecraft-server feature RCON_CMDS_STARTUP.

Requirements:
- Set a non-empty RCON_PASSWORD in .env
- Define RCON_CMDS_STARTUP in .env as a semicolon-separated list of commands
- docker-compose.yml passes this value through (already wired in this repo)

Examples:
- Keep inventory on death:
  - RCON_CMDS_STARTUP=/gamerule keepInventory true
- Enable a datapack and set gamerules:
  - RCON_CMDS_STARTUP=/datapack enable "file/COBBLEVERSE-Sinnoh-DP.zip";/gamerule keepInventory true;/gamerule doImmediateRespawn true

Notes:
- Commands must start with a slash, just like in-game.
- They run after the server is up enough to accept console commands.
- Use semicolons to separate multiple commands; do not include newline characters.

## Server icon troubleshooting

The Minecraft server expects a 64x64 PNG at /data/server-icon.png.

This repo provides scripts/init/20-server-icon.sh which will (loaded from /data/container-init.d inside the container):
- Download the image from SERVER_ICON if set to an http(s) URL
- If ImageMagick is available in the container (magick or convert), convert any image (JPG, etc.) to a 64x64 PNG
- If ImageMagick is NOT available, the script will only save the file when the URL ends with .png; otherwise it logs a warning and does not overwrite the icon

How to get your icon working:
- Recommended: Provide a direct URL to a 64x64 PNG (SERVER_ICON=...) and optionally set SERVER_ICON_UPDATE=true once to refresh.
- Or install ImageMagick in the image variant you use so the script can convert JPGs to PNG.

Verify in logs:
- docker compose logs -f mc and look for lines starting with [init:icon]
- Examples:
  - Saved server icon as 64x64 PNG at server-icon.png (conversion succeeded)
  - WARN: Did not save icon because conversion tools are unavailable and the URL is not a PNG (supply a PNG URL or add ImageMagick)
