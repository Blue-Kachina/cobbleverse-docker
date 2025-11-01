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

4. Start the server:
   ```bash
   docker-compose up -d
   ```

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
