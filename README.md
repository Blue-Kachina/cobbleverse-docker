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

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| SERVER_WORLDNAME | The name of your Minecraft world | YOUR_WORLDNAME_SHOULD_BE_ONE_WORD |
| SERVER_NAME | Server name shown in the server browser | Cobbleverse |
| SERVER_MOTD | Message of the day displayed under the server name | Welcome to Cobbleverse! |
| SERVER_ICON | URL to an image used as server icon. If ImageMagick is available, it will be converted to a 64x64 PNG automatically; otherwise provide a 64x64 PNG URL. | - |
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