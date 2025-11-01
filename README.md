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
   - For Phase 1 (vanilla boot), keep `MODRINTH_URL` commented or removed; enable it in Phase 2

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

1. Open .env and ensure the MODRINTH_URL line is present and uncommented. The example value provided points to COBBLEVERSE 1.6.
2. Start (or restart) the server to trigger the installer:
   ```bash
   docker compose up -d
   ```
   - On first run with MODRINTH_URL enabled, the container will download and install the modpack. This can take several minutes depending on your connection.
3. Tail logs and wait for completion:
   ```bash
   docker compose logs -f mc
   ```
   - Look for messages showing Modrinth pack download, mods installation, and server startup.
   - With the included settings, the installer will:
     - Cache downloads for faster rebuilds (USE_MODPACK_CACHE=true)
     - Remove outdated jars on updates (REMOVE_OLD_MODS=true)
     - Apply env-driven server.properties (OVERRIDE_SERVER_PROPERTIES=true)
4. Validate results:
   - /data/mods and /data/config should be populated inside the data directory.
   - Logs should reach the "Done" state without fatal errors.

If all of the above checks pass, Phase 2 acceptance criteria are met.

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| SERVER_WORLDNAME | The name of your Minecraft world | MY_COBBLEVERSE_WORLD |
| SERVER_NAME | Server name shown in the server browser | Cobbleverse |
| SERVER_MOTD | Message of the day displayed under the server name | - |
| SERVER_ICON | URL to the server icon image | - |
| ALLOW_FLIGHT | Whether flying is allowed | False |
| SPAWN_MONSTERS | Whether monsters will spawn | False |

### Important Notes

⚠️ **Modpack Sensitivity**: The Cobbleverse modpack requires precise configuration and timing. The server setup process includes:
- Proper mod installation and verification
- Removal of client-only mods
- Correct load order management
- Specific configuration file adjustments

## Directory Structure
