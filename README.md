# Docker Cobbleverse Server

A streamlined solution for running a Cobbleverse modded Minecraft server using Docker. 
It manages the timely installation of the mods/packs prior to world generation.
Has auto-backup capabilities too

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
   - Optionally set `MEMORY=8G` (you can use other values, but I think it has to be at least 6G) depending on your host; default is 8G in compose
   - Optionally set `RCON_PASSWORD`.  Without it, backups won't work.  The startup RCON commands can't be used without it either
   - Optionally set `OPS=`.  I like making sure that at very least my own account will have op rights

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
- Place shell scripts in scripts\init on the host. They are mounted into the container at /container-init.d.
- On container start, our compose entrypoint executes every executable script in /container-init.d in alphanumeric order before handing off to the base image's /start. This ensures scripts run exactly once even if /data/container-init.d becomes empty or invisible during the modpack install phase.
- You will see lines like "[compose:init] running /container-init.d/00-verify-init.sh" and any echo output from your scripts in Docker Desktop logs or via `docker compose logs -f mc`.
- A helper script 00-verify-init.sh is included; it also writes a persistent log to ./data/logs/init-hooks.log.
- Note: The host folder ./data/container-init.d (or ./data/init.d) may appear empty — that is expected, because scripts live in ./scripts/init and are bind-mounted into /container-init.d at runtime.

### Troubleshooting init scripts
- To verify the container sees them, run: `docker compose exec mc ls -l /container-init.d`. If it's empty, ensure your host scripts are in `./scripts/init`, recreate the container (`docker compose up -d --force-recreate`), and confirm they are executable.
- If ./data/init.d is empty on the host: this is normal; the scripts are in ./scripts/init on the host.
- Ensure scripts are executable. The compose file sets permissions on container start, but on Windows/WSL git may drop +x. You can also run `git update-index --chmod=+x scripts/init/*.sh`.
- init-hooks.log is created only after a container start when scripts exist. If it’s missing, restart: `docker compose restart mc` (or `up -d` after stopping).
- You will also see diagnostic lines added by compose entrypoint:
  - "[compose:init] listing /container-init.d"
  - "[compose:init] found N .sh files in /container-init.d"
  - "[compose:init] running <path>" for each script executed before handing off to the base image.

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