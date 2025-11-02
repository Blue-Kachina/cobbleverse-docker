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

4. Start the server:
   ```bash
   docker compose up -d
   ```

5. View logs and confirm startup:
   ```bash
   docker compose logs -f mc
   ```


## Configuration

### Init scripts (scripts/init)
- Place shell scripts in scripts\init on the host. They are mounted into the container at /data/init.d.
- On container start, every executable script in /data/init.d is run in alphanumeric order before the Minecraft server starts.
- You will see lines like "[init] running /data/init.d/00-verify-init.sh" and any echo output from your scripts in Docker Desktop logs or via docker compose logs -f mc.
- A helper script 00-verify-init.sh is included; it also writes a persistent log to ./data/logs/init-hooks.log.
- Note: The container’s /data/init or /data/container-init.d directories may appear empty in the host ./data folder if you are not mounting them directly; this is expected. Your scripts live in scripts\init on the host and are bind-mounted into /data/init.d at runtime.

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| SERVER_WORLDNAME | The name of your Minecraft world | YOUR_WORLDNAME_SHOULD_BE_ONE_WORD |
| SERVER_NAME | Server name shown in the server browser | Cobbleverse |
| SERVER_MOTD | Message of the day displayed under the server name | Welcome to Cobbleverse! |
| SERVER_ICON | Mapped to ICON for the base image to handle. Provide a URL to your icon (ideally a 64x64 PNG). The base image will place it at /data/server-icon.png. | - |
| RCON_CMDS_STARTUP | Semicolon-separated console commands to run at startup (requires RCON_PASSWORD) | - |
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

 ### Important Notes

⚠️ **Modpack Sensitivity**: The Cobbleverse modpack requires precise configuration and timing. The server setup process includes:
- Proper mod installation and verification
- Removal of client-only mods
- Correct load order management
- Specific configuration file adjustments