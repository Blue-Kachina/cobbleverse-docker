# Docker Cobbleverse Server

A streamlined solution for running a Cobbleverse modded Minecraft server using Docker. This project provides an easy way to set up and manage a Cobbleverse server while handling the complexity of mod management and server configuration.

## Features

- Easy server setup using Docker and docker-compose
- Automated mod management
- Configurable server settings via environment variables
- Persistent world data
- Based on the reliable `itzg/minecraft-server` image

## Prerequisites

- Docker
- Docker Compose
- At least 6GB of RAM available for the server
- Stable internet connection
- Port 25565 available (default Minecraft server port)

## Quick Start

1. Clone this repository:
   ```bash
   git clone [your-repository-url]
   cd [repository-name]
   ```

2. Copy the example environment file and configure it:
   ```bash
   cp .env.example .env
   ```

3. Edit the `.env` file with your preferred settings:
   - Set `SERVER_WORLDNAME` to your desired world name
   - Configure `SERVER_NAME` and `SERVER_MOTD` to personalize your server
   - Adjust other settings as needed
   - Optionally set `MEMORY=6G` (or 8G) depending on your host; default is 6G in compose
   - For Phase 1 (vanilla boot), keep `MODRINTH_MODPACK` commented or removed; enable it in Phase 2

4. Start the server:
   ```bash
   docker compose up -d
   ```

5. View logs and confirm startup:
   ```bash
   docker compose logs -f mc
   ```

If you see the server reach "Done" without errors, Phase 1 acceptance criteria are met.

## Phase 2 — Modpack Acquisition via Modrinth

1. Open .env and ensure the MODRINTH_MODPACK line is present and uncommented. The example value provided points to COBBLEVERSE 1.6.
2. Start (or restart) the server to trigger the installer:
   ```bash
   docker compose up -d
   ```
   - On first run with MODRINTH_MODPACK enabled, the container will download and install the modpack. This can take several minutes depending on your connection.
3. Tail logs and wait for completion:
   ```bash
   docker compose logs -f mc
   ```
   - Look for messages showing Modrinth pack download, mods installation, and server startup. With DEBUG enabled in compose you should see explicit Modrinth installer steps.
   - With the included settings, the installer will:
     - Cache downloads for faster rebuilds (USE_MODPACK_CACHE=true)
     - Remove outdated jars on updates (REMOVE_OLD_MODS=true)
     - Apply env-driven server.properties (OVERRIDE_SERVER_PROPERTIES=true)
4. Validate results:
   - /data/mods and /data/config should be populated inside the data directory.
   - Logs should reach the "Done" state without fatal errors.

If all of the above checks pass, Phase 2 acceptance criteria are met.

Troubleshooting Phase 2
- Verify your environment is being passed: docker compose config | grep -E "MODRINTH|DEBUG|MEMORY"
- Ensure .env exists in the repo root and includes MODRINTH_MODPACK=...mrpack
- Important: Modrinth installer output appears in container logs (docker compose logs), not in data/logs/latest.log. The latter is vanilla server only.
- After the first successful install, subsequent restarts may not show Modrinth-related messages; this is normal if mods are already present in data/mods.
- If you previously started vanilla without mods, restart once after enabling MODRINTH_MODPACK so the installer runs.
- Use the smoke script with container run enabled to auto-check for Modrinth activity:
  - Linux/macOS: RUN_CONTAINER=1 ./scripts/smoke.sh
  - Windows: ./scripts/smoke.ps1 -RunContainer
  - Note: The smoke scripts will only WARN about missing Modrinth messages if mods are not installed. If mods are present, they log this as INFO.
- If /data/mods remains empty, stop the container and check logs from a fresh start; consider removing any old data/mods content to let the installer repopulate.

## Phase 3 — Apply and Verify Overrides

The Modrinth installer applies the pack's overrides into the server's /data folder. In this phase, you'll verify configs and enable the included datapack for your world.

1) Verify config overrides applied
- After Phase 2 completes, check that /data/config contains many mod configs.
  - Example:
    - docker compose exec mc sh -lc "ls -1 /data/config | head -n 20"
- You should see numerous folders/files (e.g., cobblemon, safepastures, etc.). If empty, restart once and re-check logs for the Modrinth apply-overrides step.

2) Install the Cobbleverse datapack into your world
- The pack includes overrides/datapacks/extra/COBBLEVERSE-Sinnoh-DP.zip. Place it under your world datapacks directory so Minecraft will load it:
  - Replace WORLD with your SERVER_WORLDNAME from .env
  - docker compose exec mc sh -lc "mkdir -p /data/$SERVER_WORLDNAME/datapacks && cp -f /data/datapacks/extra/COBBLEVERSE-Sinnoh-DP.zip /data/$SERVER_WORLDNAME/datapacks/ 2>/dev/null || true"
  - If the above source path doesn't exist yet, the override may have been placed directly during install. Try copying from the root override location too:
    - docker compose exec mc sh -lc "test -f /data/$SERVER_WORLDNAME/datapacks/COBBLEVERSE-Sinnoh-DP.zip || cp -f /data/overrides/datapacks/extra/COBBLEVERSE-Sinnoh-DP.zip /data/$SERVER_WORLDNAME/datapacks/ 2>/dev/null || true"

Notes:
- Some modpack installers copy datapacks into /data/datapacks first; others place them directly into /data/<world>/datapacks after the world exists. The commands above handle either case by attempting both locations.

3) Confirm and enable the datapack
- Use the built-in console utility to run Minecraft commands:
  - List datapacks:
    - docker compose exec mc mc-send-to-console "/datapack list"
  - If the datapack appears but is disabled, enable it and reload:
    - docker compose exec mc mc-send-to-console "/datapack enable \"file/COBBLEVERSE-Sinnoh-DP.zip\""
    - docker compose exec mc mc-send-to-console "/reload"
  - List again to verify it's enabled:
    - docker compose exec mc mc-send-to-console "/datapack list enabled"

4) Resource packs are client-side
- The pack references resource packs (e.g., Fresh Moves.zip, PokeDiscs.zip) and includes "COBBLEVERSE Soundtrack.zip" under overrides/resourcepacks. These are for players' clients and do not need server-side changes in this phase. Optionally, you can host a resource pack and set resource-pack, require-resource-pack, and resource-pack-prompt in server.properties in a later phase.

Acceptance criteria:
- /data/config contains the expected override configs.
- COBBLEVERSE-Sinnoh-DP.zip is present under /data/<SERVER_WORLDNAME>/datapacks and shows as enabled in /datapack list.

## Phase 4 — Client-only Mod Curation and Compliance

This phase ensures the headless server does not attempt to load client-only UX/visual mods.

What we do automatically
- docker-compose mounts ./scripts/init to /data/init inside the container
- On startup, the itzg image runs scripts in that folder; our script removes known client-only jars
- See docs/client-only-mods.md for the current removal patterns and rationale

How to run/verify
1. Start (or restart) the container: docker compose up -d
2. Check logs for the init message: "[init:client-clean] Removed X client-only mod(s)." or "No client-only mods found to remove."
3. List server mods to confirm removals: docker compose exec mc sh -lc 'ls -1 /data/mods'

Acceptance criteria
- No client-only mod jars remain in /data/mods after startup
- Server boots cleanly without client-only warnings/errors

## Phase 5 — Server Configuration and Policy

In this phase we make the server reflect your desired identity and basic policies automatically.

What’s included
- Env-to-properties mapping via the itzg image (OVERRIDE_SERVER_PROPERTIES=true in compose)
- Server icon auto-download from SERVER_ICON into /data/server-icon.png (scripts/init/20-server-icon.sh)
- Support for ops and whitelist users through OPS and WHITELIST environment variables handled by the image

How to configure
1) Edit .env and set your values (examples provided in .env.example):
   - SERVER_WORLDNAME, SERVER_NAME, SERVER_MOTD (or MOTD)
   - ALLOW_FLIGHT, SPAWN_MONSTERS, DIFFICULTY, VIEW_DISTANCE, SIMULATION_DISTANCE
   - ENABLE_COMMAND_BLOCK, ONLINE_MODE
   - ENFORCE_WHITELIST=true (to require whitelist) and list players in WHITELIST
   - List operator players in OPS
   - SERVER_ICON with a 64x64 PNG URL; set SERVER_ICON_UPDATE=true to refresh on each start
2) Restart the container: docker compose up -d
3) Verify:
   - docker compose logs -f mc shows "[init:icon]" log line for icon handling
   - In data/server.properties, your values are present
   - If you set OPS/WHITELIST, those users appear in /data/ops.json and /data/whitelist.json

Optional gamerules and datapack commands
- The itzg image can run console commands at startup using RCON_CMDS_STARTUP. Example in your .env:
  RCON_CMDS_STARTUP=/datapack enable "file/COBBLEVERSE-Sinnoh-DP.zip";/gamerule keepInventory true
- Remove or comment it out after the first successful start if you want it one-time only.

Acceptance criteria
- On a fresh start, the server reflects configured properties and applies ops/whitelist.

## Phase 6 — Performance and Stability Tuning

Goal: Achieve stable 20 TPS and predictable memory behavior for typical player counts by tuning memory/GC, distances, and crash handling.

What we set by default
- MEMORY: Defaulted to 8G in docker-compose; override in .env if needed.
- USE_AIKAR_FLAGS: Enabled in docker-compose. These are generally safe for modded servers.
- JVM_OPTS: Exposed passthrough in compose. Leave empty unless you intend to replace Aikar flags with your own G1GC tuning.
- Distances: .env.example provides VIEW_DISTANCE and SIMULATION_DISTANCE defaults; adjust per player count and hardware.

Suggested starting points
- Player count 1–3: VIEW_DISTANCE=10, SIMULATION_DISTANCE=10
- Player count 4–8: VIEW_DISTANCE=8–10, SIMULATION_DISTANCE=6–10
- If you see TPS dips due to entity AI, lower SIMULATION_DISTANCE first.

Crash/Watchdog handling (use with care)
- You can optionally set RESTART_ON_CRASH=true in .env to let the container supervisor restart after a crash.
- MAX_TICK_TIME=-1 disables the server watchdog. Only do this after testing the pack; the watchdog can help catch deadlocks.

How to validate
1) Start the server: docker compose up -d; then watch logs: docker compose logs -f mc
2) Join with 2–5 clients and perform typical activities (explore, battle, build) for 30–60 minutes.
3) Monitor:
   - TPS via /forge tps or a tick profiler mod if available; otherwise watch console timings and lag messages.
   - Memory: Observe GC activity in logs; consider enabling verbose GC via JVM_OPTS if deep analysis is needed.
4) If TPS is unstable:
   - Lower SIMULATION_DISTANCE by 2 and retest.
   - Consider reducing VIEW_DISTANCE.
   - Ensure host has enough free RAM/CPU; avoid contention from other containers.

More detail and rationale: see docs/performance-notes.md

## Phase 7 — Backups, Updates, and Operations

What’s included
- Automated backups via a sidecar container (itzg/mc-backup) writing to ./backups with rotation
- Rolling logs, graceful stop announcements, and optional RCON for tooling
- An operations guide with restore procedure and update checklist

How to enable/configure
1) Edit .env and review Phase 7 variables (examples are provided):
   - BACKUP_INTERVAL=24h and BACKUP_PRUNE_DAYS=14 for daily backups with 14-day retention
   - STOP_SERVER_ANNOUNCE_DELAY=15s for graceful restarts
   - RCON_PASSWORD=your-strong-password to enable RCON features
2) Bring the stack up: docker compose up -d
3) Verify backups after the first interval:
   - Check the backups folder for timestamped tar.gz archives
4) To restore a backup:
   - Follow the step-by-step instructions in docs/operations.md (Restore procedure)

Monitoring
- Optional healthcheck using mc-monitor is pre-wired but commented in docker-compose. Uncomment to enable.
- With RCON_PASSWORD set, you can use mc-send-to-console and external tools that require RCON access.

More details: see docs/operations.md

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| SERVER_WORLDNAME | The name of your Minecraft world | YOUR_WORLDNAME_SHOULD_BE_ONE_WORD |
| SERVER_NAME | Server name shown in the server browser | Cobbleverse |
| SERVER_MOTD | Message of the day displayed under the server name | Welcome to Cobbleverse! |
| SERVER_ICON | URL to a 64x64 PNG used as server icon (auto-downloaded) | - |
| ALLOW_FLIGHT | Whether flying is allowed | true |
| SPAWN_MONSTERS | Whether monsters will spawn | false |
| DIFFICULTY | peaceful|easy|normal|hard | normal |
| VIEW_DISTANCE | Server-side view distance | 10 |
| SIMULATION_DISTANCE | Server-side simulation distance | 10 |
| ENABLE_COMMAND_BLOCK | Allow command blocks | false |
| ONLINE_MODE | Require authenticated accounts | true |
| ENFORCE_WHITELIST | Enforce whitelist | false |
| OPS | Comma-separated list of operator player names | - |
| WHITELIST | Comma-separated list of whitelisted player names | - |

Phase 6 variables
- MEMORY: JVM heap size for the server. Defaults to 8G via docker-compose; override in .env as needed.
- JVM_OPTS: Custom JVM options. Leave empty to use Aikar flags; set this to override with your own G1GC tuning.
- RESTART_ON_CRASH: If true, the container will restart the server after a crash.
- MAX_TICK_TIME: Server watchdog threshold in ms. Set to -1 to disable watchdog (use with caution).
 
 ### Important Notes

⚠️ **Modpack Sensitivity**: The Cobbleverse modpack requires precise configuration and timing. The server setup process includes:
- Proper mod installation and verification
- Removal of client-only mods
- Correct load order management
- Specific configuration file adjustments

## Smoke Tests

Run basic checks to ensure the setup is healthy.

- Quick doc with steps: docs/smoke-tests.md
- Windows (PowerShell):
  - scripts\smoke.ps1
  - Optionally start the container during the test: scripts\smoke.ps1 -RunContainer
- Linux/macOS (bash):
  - chmod +x scripts/smoke.sh && RUN_CONTAINER=1 ./scripts/smoke.sh

What we already validated in this repo snapshot:
- docker compose config: PASSED (compose syntax and env rendering OK)
- logs/latest.log: Shows a complete vanilla boot and then an automatic stop triggered via RCON after idling. This is consistent with the image's auto-stop/auto-pause features. We now explicitly disable those in docker-compose to prevent restart loops.

### Troubleshooting: Container keeps restarting when idle
If your container appears to restart on its own when no players are connected, check latest.log and compose settings:
- In data/logs/latest.log you may see:
  - "Server empty for 60 seconds, pausing"
  - Followed later by "[Rcon: Stopping the server]" and normal save/shutdown lines
- With restart: unless-stopped, Docker will immediately restart the container after the server exits, creating a loop.

Fix:
- Ensure these are set under services.mc.environment in docker-compose.yml:
  - ENABLE_AUTOPAUSE="false"
  - ENABLE_AUTOSTOP="false"
- Or, alternatively, keep auto features enabled but change the restart policy if you truly want the container to remain stopped after idle.

## Directory Structure


## Phase 8 — Security, Networking, and Productionization

Goal: Make the deployment safer and production-ready so external players can join reliably while keeping access controlled and logs sane.

What’s included in this repo
- Non-root container: docker-compose passes UID/GID from .env so the server runs without root privileges.
- Timezone: docker-compose passes TZ to both the server and the backup sidecar.
- Permissions hardening: scripts/init/30-permissions.sh sets restrictive permissions (770) on key directories when writable.
- Networking: Port 25565/TCP is published by default (ports: "25565:25565").

How to configure
1) Edit .env and set Phase 8 values:
   - TZ=UTC (or your region, e.g., TZ=America/New_York)
   - UID=1000 and GID=1000 (or values matching the host user/group that owns this repo directory)
   - Consider enabling ENFORCE_WHITELIST=true and setting WHITELIST for private servers
   - Set a strong RCON_PASSWORD if you need RCON; otherwise leave it empty (RCON remains disabled)
2) Ensure host/network allows inbound 25565/TCP:
   - Home lab: forward 25565/TCP on your router to the Docker host’s LAN IP
   - VPS/cloud: open 25565/TCP in provider firewall/security groups
   - Host firewall: allow 25565/TCP (e.g., ufw allow 25565/tcp on Linux)
3) Start/Restart:
   - docker compose up -d
   - Watch init logs for [init:perms] lines confirming permission tightening

Verification
- From an external network, connect via Minecraft client to <your-hostname>:25565
- Or run mc-monitor (local utility) to check status:
  - mc-monitor status --host <host> --port 25565
- Inspect permissions (Linux): ls -ld data backups -> should show drwxrwx--- (or similar)
- Confirm timestamps in data/logs/latest.log reflect your TZ

Notes
- We intentionally do NOT expose RCON by default. Use docker compose exec mc mc-send-to-console for local admin.
- For DDoS protection, use a provider with L4 game filtering or a Minecraft-aware TCP proxy. Use L4/TCP passthrough, not HTTP.

More details: see docs/security-networking.md


## Phase 9 — QA and Test Matrix

Goal: Validate that critical gameplay loops work end-to-end and the server remains stable through typical actions.

What’s included
- A structured checklist in docs/test-matrix.md to record PASS/FAIL and notes
- Pointers to existing smoke scripts (scripts/smoke.sh and scripts/smoke.ps1) for quick sanity checks

How to run
1) For a brand-new validation, start from a clean data directory or set a new SERVER_WORLDNAME in .env
2) Bring the server up and follow each test case in docs/test-matrix.md:
   - First boot and datapack activation
   - Player join/leave
   - Cobblemon gameplay basics (spawns, battles, capture)
   - World travel and dimension access
   - Economy/shops (if configured)
   - Resource pack prompt & SHA1 verification (if configured)
   - Save/restart cycle integrity
   - 30–60 minute typical play without crashes
3) Mark PASS/FAIL and link evidence (log excerpts/screenshots) directly in docs/test-matrix.md

Quick helpers
- Linux/macOS: RUN_CONTAINER=1 ./scripts/smoke.sh
- Windows (PowerShell): scripts/smoke.ps1 -RunContainer

Acceptance criteria
- All critical gameplay loops function
- Zero crashes during typical actions; only minor/expected warnings in logs


# Docker Cobbleverse Server

A streamlined solution for running a Cobbleverse modded Minecraft server using Docker. This project provides an easy way to set up and manage a Cobbleverse server while handling the complexity of mod management and server configuration.

## Features

- Easy server setup using Docker and docker-compose
- Automated mod management
- Configurable server settings via environment variables
- Persistent world data
- Based on the reliable `itzg/minecraft-server` image

## Prerequisites

- Docker
- Docker Compose
- At least 6GB of RAM available for the server
- Stable internet connection
- Port 25565 available (default Minecraft server port)

## Quick Start

1. Clone this repository:
   ```bash
   git clone [your-repository-url]
   cd [repository-name]
   ```

2. Copy the example environment file and configure it:
   ```bash
   cp .env.example .env
   ```

3. Edit the `.env` file with your preferred settings:
   - Set `SERVER_WORLDNAME` to your desired world name
   - Configure `SERVER_NAME` and `SERVER_MOTD` to personalize your server
   - Adjust other settings as needed
   - Optionally set `MEMORY=6G` (or 8G) depending on your host; default is 6G in compose
   - For Phase 1 (vanilla boot), keep `MODRINTH_MODPACK` commented or removed; enable it in Phase 2

4. Start the server:
   ```bash
   docker compose up -d
   ```

5. View logs and confirm startup:
   ```bash
   docker compose logs -f mc
   ```

If you see the server reach "Done" without errors, Phase 1 acceptance criteria are met.

## Phase 2 — Modpack Acquisition via Modrinth

1. Open .env and ensure the MODRINTH_MODPACK line is present and uncommented. The example value provided points to COBBLEVERSE 1.6.
2. Start (or restart) the server to trigger the installer:
   ```bash
   docker compose up -d
   ```
   - On first run with MODRINTH_MODPACK enabled, the container will download and install the modpack. This can take several minutes depending on your connection.
3. Tail logs and wait for completion:
   ```bash
   docker compose logs -f mc
   ```
   - Look for messages showing Modrinth pack download, mods installation, and server startup. With DEBUG enabled in compose you should see explicit Modrinth installer steps.
   - With the included settings, the installer will:
     - Cache downloads for faster rebuilds (USE_MODPACK_CACHE=true)
     - Remove outdated jars on updates (REMOVE_OLD_MODS=true)
     - Apply env-driven server.properties (OVERRIDE_SERVER_PROPERTIES=true)
4. Validate results:
   - /data/mods and /data/config should be populated inside the data directory.
   - Logs should reach the "Done" state without fatal errors.

If all of the above checks pass, Phase 2 acceptance criteria are met.

Troubleshooting Phase 2
- Verify your environment is being passed: docker compose config | grep -E "MODRINTH|DEBUG|MEMORY"
- Ensure .env exists in the repo root and includes MODRINTH_MODPACK=...mrpack
- Important: Modrinth installer output appears in container logs (docker compose logs), not in data/logs/latest.log. The latter is vanilla server only.
- After the first successful install, subsequent restarts may not show Modrinth-related messages; this is normal if mods are already present in data/mods.
- If you previously started vanilla without mods, restart once after enabling MODRINTH_MODPACK so the installer runs.
- Use the smoke script with container run enabled to auto-check for Modrinth activity:
  - Linux/macOS: RUN_CONTAINER=1 ./scripts/smoke.sh
  - Windows: ./scripts/smoke.ps1 -RunContainer
  - Note: The smoke scripts will only WARN about missing Modrinth messages if mods are not installed. If mods are present, they log this as INFO.
- If /data/mods remains empty, stop the container and check logs from a fresh start; consider removing any old data/mods content to let the installer repopulate.

## Phase 3 — Apply and Verify Overrides

The Modrinth installer applies the pack's overrides into the server's /data folder. In this phase, you'll verify configs and enable the included datapack for your world.

1) Verify config overrides applied
- After Phase 2 completes, check that /data/config contains many mod configs.
  - Example:
    - docker compose exec mc sh -lc "ls -1 /data/config | head -n 20"
- You should see numerous folders/files (e.g., cobblemon, safepastures, etc.). If empty, restart once and re-check logs for the Modrinth apply-overrides step.

2) Install the Cobbleverse datapack into your world
- The pack includes overrides/datapacks/extra/COBBLEVERSE-Sinnoh-DP.zip. Place it under your world datapacks directory so Minecraft will load it:
  - Replace WORLD with your SERVER_WORLDNAME from .env
  - docker compose exec mc sh -lc "mkdir -p /data/$SERVER_WORLDNAME/datapacks && cp -f /data/datapacks/extra/COBBLEVERSE-Sinnoh-DP.zip /data/$SERVER_WORLDNAME/datapacks/ 2>/dev/null || true"
  - If the above source path doesn't exist yet, the override may have been placed directly during install. Try copying from the root override location too:
    - docker compose exec mc sh -lc "test -f /data/$SERVER_WORLDNAME/datapacks/COBBLEVERSE-Sinnoh-DP.zip || cp -f /data/overrides/datapacks/extra/COBBLEVERSE-Sinnoh-DP.zip /data/$SERVER_WORLDNAME/datapacks/ 2>/dev/null || true"

Notes:
- Some modpack installers copy datapacks into /data/datapacks first; others place them directly into /data/<world>/datapacks after the world exists. The commands above handle either case by attempting both locations.

3) Confirm and enable the datapack
- Use the built-in console utility to run Minecraft commands:
  - List datapacks:
    - docker compose exec mc mc-send-to-console "/datapack list"
  - If the datapack appears but is disabled, enable it and reload:
    - docker compose exec mc mc-send-to-console "/datapack enable \"file/COBBLEVERSE-Sinnoh-DP.zip\""
    - docker compose exec mc mc-send-to-console "/reload"
  - List again to verify it's enabled:
    - docker compose exec mc mc-send-to-console "/datapack list enabled"

4) Resource packs are client-side
- The pack references resource packs (e.g., Fresh Moves.zip, PokeDiscs.zip) and includes "COBBLEVERSE Soundtrack.zip" under overrides/resourcepacks. These are for players' clients and do not need server-side changes in this phase. Optionally, you can host a resource pack and set resource-pack, require-resource-pack, and resource-pack-prompt in server.properties in a later phase.

Acceptance criteria:
- /data/config contains the expected override configs.
- COBBLEVERSE-Sinnoh-DP.zip is present under /data/<SERVER_WORLDNAME>/datapacks and shows as enabled in /datapack list.

## Phase 4 — Client-only Mod Curation and Compliance

This phase ensures the headless server does not attempt to load client-only UX/visual mods.

What we do automatically
- docker-compose mounts ./scripts/init to /data/init inside the container
- On startup, the itzg image runs scripts in that folder; our script removes known client-only jars
- See docs/client-only-mods.md for the current removal patterns and rationale

How to run/verify
1. Start (or restart) the container: docker compose up -d
2. Check logs for the init message: "[init:client-clean] Removed X client-only mod(s)." or "No client-only mods found to remove."
3. List server mods to confirm removals: docker compose exec mc sh -lc 'ls -1 /data/mods'

Acceptance criteria
- No client-only mod jars remain in /data/mods after startup
- Server boots cleanly without client-only warnings/errors

## Phase 5 — Server Configuration and Policy

In this phase we make the server reflect your desired identity and basic policies automatically.

What’s included
- Env-to-properties mapping via the itzg image (OVERRIDE_SERVER_PROPERTIES=true in compose)
- Server icon auto-download from SERVER_ICON into /data/server-icon.png (scripts/init/20-server-icon.sh)
- Support for ops and whitelist users through OPS and WHITELIST environment variables handled by the image

How to configure
1) Edit .env and set your values (examples provided in .env.example):
   - SERVER_WORLDNAME, SERVER_NAME, SERVER_MOTD (or MOTD)
   - ALLOW_FLIGHT, SPAWN_MONSTERS, DIFFICULTY, VIEW_DISTANCE, SIMULATION_DISTANCE
   - ENABLE_COMMAND_BLOCK, ONLINE_MODE
   - ENFORCE_WHITELIST=true (to require whitelist) and list players in WHITELIST
   - List operator players in OPS
   - SERVER_ICON with a 64x64 PNG URL; set SERVER_ICON_UPDATE=true to refresh on each start
2) Restart the container: docker compose up -d
3) Verify:
   - docker compose logs -f mc shows "[init:icon]" log line for icon handling
   - In data/server.properties, your values are present
   - If you set OPS/WHITELIST, those users appear in /data/ops.json and /data/whitelist.json

Optional gamerules and datapack commands
- The itzg image can run console commands at startup using RCON_CMDS_STARTUP. Example in your .env:
  RCON_CMDS_STARTUP=/datapack enable "file/COBBLEVERSE-Sinnoh-DP.zip";/gamerule keepInventory true
- Remove or comment it out after the first successful start if you want it one-time only.

Acceptance criteria
- On a fresh start, the server reflects configured properties and applies ops/whitelist.

## Phase 6 — Performance and Stability Tuning

Goal: Achieve stable 20 TPS and predictable memory behavior for typical player counts by tuning memory/GC, distances, and crash handling.

What we set by default
- MEMORY: Defaulted to 8G in docker-compose; override in .env if needed.
- USE_AIKAR_FLAGS: Enabled in docker-compose. These are generally safe for modded servers.
- JVM_OPTS: Exposed passthrough in compose. Leave empty unless you intend to replace Aikar flags with your own G1GC tuning.
- Distances: .env.example provides VIEW_DISTANCE and SIMULATION_DISTANCE defaults; adjust per player count and hardware.

Suggested starting points
- Player count 1–3: VIEW_DISTANCE=10, SIMULATION_DISTANCE=10
- Player count 4–8: VIEW_DISTANCE=8–10, SIMULATION_DISTANCE=6–10
- If you see TPS dips due to entity AI, lower SIMULATION_DISTANCE first.

Crash/Watchdog handling (use with care)
- You can optionally set RESTART_ON_CRASH=true in .env to let the container supervisor restart after a crash.
- MAX_TICK_TIME=-1 disables the server watchdog. Only do this after testing the pack; the watchdog can help catch deadlocks.

How to validate
1) Start the server: docker compose up -d; then watch logs: docker compose logs -f mc
2) Join with 2–5 clients and perform typical activities (explore, battle, build) for 30–60 minutes.
3) Monitor:
   - TPS via /forge tps or a tick profiler mod if available; otherwise watch console timings and lag messages.
   - Memory: Observe GC activity in logs; consider enabling verbose GC via JVM_OPTS if deep analysis is needed.
4) If TPS is unstable:
   - Lower SIMULATION_DISTANCE by 2 and retest.
   - Consider reducing VIEW_DISTANCE.
   - Ensure host has enough free RAM/CPU; avoid contention from other containers.

More detail and rationale: see docs/performance-notes.md

## Phase 7 — Backups, Updates, and Operations

What’s included
- Automated backups via a sidecar container (itzg/mc-backup) writing to ./backups with rotation
- Rolling logs, graceful stop announcements, and optional RCON for tooling
- An operations guide with restore procedure and update checklist

How to enable/configure
1) Edit .env and review Phase 7 variables (examples are provided):
   - BACKUP_INTERVAL=24h and BACKUP_PRUNE_DAYS=14 for daily backups with 14-day retention
   - STOP_SERVER_ANNOUNCE_DELAY=15s for graceful restarts
   - RCON_PASSWORD=your-strong-password to enable RCON features
2) Bring the stack up: docker compose up -d
3) Verify backups after the first interval:
   - Check the backups folder for timestamped tar.gz archives
4) To restore a backup:
   - Follow the step-by-step instructions in docs/operations.md (Restore procedure)

Monitoring
- Optional healthcheck using mc-monitor is pre-wired but commented in docker-compose. Uncomment to enable.
- With RCON_PASSWORD set, you can use mc-send-to-console and external tools that require RCON access.

More details: see docs/operations.md

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| SERVER_WORLDNAME | The name of your Minecraft world | YOUR_WORLDNAME_SHOULD_BE_ONE_WORD |
| SERVER_NAME | Server name shown in the server browser | Cobbleverse |
| SERVER_MOTD | Message of the day displayed under the server name | Welcome to Cobbleverse! |
| SERVER_ICON | URL to a 64x64 PNG used as server icon (auto-downloaded) | - |
| ALLOW_FLIGHT | Whether flying is allowed | true |
| SPAWN_MONSTERS | Whether monsters will spawn | false |
| DIFFICULTY | peaceful|easy|normal|hard | normal |
| VIEW_DISTANCE | Server-side view distance | 10 |
| SIMULATION_DISTANCE | Server-side simulation distance | 10 |
| ENABLE_COMMAND_BLOCK | Allow command blocks | false |
| ONLINE_MODE | Require authenticated accounts | true |
| ENFORCE_WHITELIST | Enforce whitelist | false |
| OPS | Comma-separated list of operator player names | - |
| WHITELIST | Comma-separated list of whitelisted player names | - |

Phase 6 variables
- MEMORY: JVM heap size for the server. Defaults to 8G via docker-compose; override in .env as needed.
- JVM_OPTS: Custom JVM options. Leave empty to use Aikar flags; set this to override with your own G1GC tuning.
- RESTART_ON_CRASH: If true, the container will restart the server after a crash.
- MAX_TICK_TIME: Server watchdog threshold in ms. Set to -1 to disable watchdog (use with caution).
 
 ### Important Notes

⚠️ **Modpack Sensitivity**: The Cobbleverse modpack requires precise configuration and timing. The server setup process includes:
- Proper mod installation and verification
- Removal of client-only mods
- Correct load order management
- Specific configuration file adjustments

## Smoke Tests

Run basic checks to ensure the setup is healthy.

- Quick doc with steps: docs/smoke-tests.md
- Windows (PowerShell):
  - scripts\smoke.ps1
  - Optionally start the container during the test: scripts\smoke.ps1 -RunContainer
- Linux/macOS (bash):
  - chmod +x scripts/smoke.sh && RUN_CONTAINER=1 ./scripts/smoke.sh

What we already validated in this repo snapshot:
- docker compose config: PASSED (compose syntax and env rendering OK)
- logs/latest.log: Shows a complete vanilla boot and then an automatic stop triggered via RCON after idling. This is consistent with the image's auto-stop/auto-pause features. We now explicitly disable those in docker-compose to prevent restart loops.

### Troubleshooting: Container keeps restarting when idle
If your container appears to restart on its own when no players are connected, check latest.log and compose settings:
- In data/logs/latest.log you may see:
  - "Server empty for 60 seconds, pausing"
  - Followed later by "[Rcon: Stopping the server]" and normal save/shutdown lines
- With restart: unless-stopped, Docker will immediately restart the container after the server exits, creating a loop.

Fix:
- Ensure these are set under services.mc.environment in docker-compose.yml:
  - ENABLE_AUTOPAUSE="false"
  - ENABLE_AUTOSTOP="false"
- Or, alternatively, keep auto features enabled but change the restart policy if you truly want the container to remain stopped after idle.

## Directory Structure


## Phase 8 — Security, Networking, and Productionization

Goal: Make the deployment safer and production-ready so external players can join reliably while keeping access controlled and logs sane.

What’s included in this repo
- Non-root container: docker-compose passes UID/GID from .env so the server runs without root privileges.
- Timezone: docker-compose passes TZ to both the server and the backup sidecar.
- Permissions hardening: scripts/init/30-permissions.sh sets restrictive permissions (770) on key directories when writable.
- Networking: Port 25565/TCP is published by default (ports: "25565:25565").

How to configure
1) Edit .env and set Phase 8 values:
   - TZ=UTC (or your region, e.g., TZ=America/New_York)
   - UID=1000 and GID=1000 (or values matching the host user/group that owns this repo directory)
   - Consider enabling ENFORCE_WHITELIST=true and setting WHITELIST for private servers
   - Set a strong RCON_PASSWORD if you need RCON; otherwise leave it empty (RCON remains disabled)
2) Ensure host/network allows inbound 25565/TCP:
   - Home lab: forward 25565/TCP on your router to the Docker host’s LAN IP
   - VPS/cloud: open 25565/TCP in provider firewall/security groups
   - Host firewall: allow 25565/TCP (e.g., ufw allow 25565/tcp on Linux)
3) Start/Restart:
   - docker compose up -d
   - Watch init logs for [init:perms] lines confirming permission tightening

Verification
- From an external network, connect via Minecraft client to <your-hostname>:25565
- Or run mc-monitor (local utility) to check status:
  - mc-monitor status --host <host> --port 25565
- Inspect permissions (Linux): ls -ld data backups -> should show drwxrwx--- (or similar)
- Confirm timestamps in data/logs/latest.log reflect your TZ

Notes
- We intentionally do NOT expose RCON by default. Use docker compose exec mc mc-send-to-console for local admin.
- For DDoS protection, use a provider with L4 game filtering or a Minecraft-aware TCP proxy. Use L4/TCP passthrough, not HTTP.

More details: see docs/security-networking.md


## Phase 9 — QA and Test Matrix

Goal: Validate that critical gameplay loops work end-to-end and the server remains stable through typical actions.

What’s included
- A structured checklist in docs/test-matrix.md to record PASS/FAIL and notes
- Pointers to existing smoke scripts (scripts/smoke.sh and scripts/smoke.ps1) for quick sanity checks

How to run
1) For a brand-new validation, start from a clean data directory or set a new SERVER_WORLDNAME in .env
2) Bring the server up and follow each test case in docs/test-matrix.md:
   - First boot and datapack activation
   - Player join/leave
   - Cobblemon gameplay basics (spawns, battles, capture)
   - World travel and dimension access
   - Economy/shops (if configured)
   - Resource pack prompt & SHA1 verification (if configured)
   - Save/restart cycle integrity
   - 30–60 minute typical play without crashes
3) Mark PASS/FAIL and link evidence (log excerpts/screenshots) directly in docs/test-matrix.md

Quick helpers
- Linux/macOS: RUN_CONTAINER=1 ./scripts/smoke.sh
- Windows (PowerShell): scripts/smoke.ps1 -RunContainer

Acceptance criteria
- All critical gameplay loops function
- Zero crashes during typical actions; only minor/expected warnings in logs

## Phase 10 — Documentation and Handoff

Goal: Ensure any new operator can set up and run the server from scratch with minimal assistance.

What’s included
- Handoff and Runbook: docs/handoff.md (Production Quickstart, daily ops, restore, updates, troubleshooting)
- Overrides Mapping: docs/overrides-map.md (how overrides land in /data, what is server-relevant, our customizations)
- Versioning: docker-compose.yml and .env.example include version/date headers and compose labels

Production Quickstart (TL;DR)
1) Copy env: `cp .env.example .env` (or `Copy-Item .env.example .env` on Windows)
2) Edit .env: set SERVER_WORLDNAME, MOTD/NAME, optional OPS/WHITELIST; keep MODRINTH_MODPACK as provided
3) Start: `docker compose up -d`
4) Watch: `docker compose logs -f mc` until Done
5) Join from client to host:25565

Troubleshooting & Updates
- See docs/handoff.md (section 7) and docs/operations.md for restore/update flows

Acceptance criteria
- Following docs/handoff.md, a new operator can stand up the server on a clean host without prior context
