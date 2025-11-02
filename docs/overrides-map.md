# Overrides Mapping and Customizations (Phase 10)

Date: 2025-11-01

This document explains how the modpack’s overrides are applied to the running server and documents customizations we added in this repository compared to a default itzg/minecraft-server setup.

## How overrides are applied

- The Modrinth pack (COBBLEVERSE 1.6) contains an `overrides/` directory. During install, the itzg/minecraft-server Modrinth installer copies these into `/data`.
- Relevant locations after install:
  - `/data/config/...` — mod configuration files from `overrides/config/...`
  - `/data/datapacks/...` — pack-level datapacks; some installers place them here before a world exists
  - `/data/<WORLD>/datapacks/...` — world-specific datapacks; we copy/ensure the Cobbleverse datapack is present here
  - Client assets like `overrides/resourcepacks` and `overrides/shaderpacks` are copied into `/data` too but are not used by the headless server.

## Server-relevant vs client-only content

- Server-relevant:
  - `overrides/config/...` (many JSON/TOML/properties files: Cobblemon, SafePastures, PlayerXP, etc.)
  - `overrides/datapacks/extra/COBBLEVERSE-Sinnoh-DP.zip` (must be present in `/data/<WORLD>/datapacks` and enabled)
- Client-only (for player distribution only):
  - `overrides/resourcepacks/COBBLEVERSE Soundtrack.zip`
  - `overrides/shaderpacks/` (both STANDARD and HIGH QUALITY sets)
  - Resource packs referenced by `modrinth.index.json` (e.g., Fresh Moves.zip, PokeDiscs.zip)

## Our repository customizations

1) Init hooks executed by the container (mounted at `/data/init`):
- `scripts/init/10-clean-client-only.sh` removes known client-only jars from `/data/mods` on each start
- `scripts/init/20-server-icon.sh` downloads `SERVER_ICON` to `/data/server-icon.png` (optional)
- `scripts/init/30-permissions.sh` tightens permissions on `/data` and `/backups` when writable

2) Docker Compose additions:
- `mc-backup` sidecar (`itzg/mc-backup`) writes timestamped tar archives to `./backups` with retention
- Environment-driven tuning and operations variables exposed in `services.mc.environment`

3) Policy/config surfacing in `.env.example`:
- Common server properties, memory/GC toggles, backups schedule, timezone, UID/GID, RCON settings

## Verification steps

- After first install, confirm overrides present:
  - `docker compose exec mc sh -lc 'ls -1 /data/config | head -n 20'`
  - Check `/data/<WORLD>/datapacks/COBBLEVERSE-Sinnoh-DP.zip` exists, then enable via console if needed
    - `docker compose exec mc mc-send-to-console "/datapack list"`
- Confirm client-only cleanup ran (log lines starting with `[init:client-clean]`); list `/data/mods` to ensure no client-only jars remain

## Adjusting overrides/customizations

- If the pack updates, review `docs/client-only-mods.md` and adjust patterns in `scripts/init/10-clean-client-only.sh` accordingly
- To offer a resource pack from the server, host the pack at a URL and set `resource-pack`, `resource-pack-prompt`, and `require-resource-pack` via env mapping (see README Phase 3 notes)

## Notes

- Some entries in `modrinth.index.json` mark both `client` and `server` as required even for client-centric mods; we still remove known client-only jars to avoid headless issues and keep the server lean.
- The installer’s placement of datapacks can vary. Our README includes commands that copy the datapack to the world folder if needed and enable it.