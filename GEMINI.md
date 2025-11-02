# Project Overview

This project is a Dockerized Cobbleverse modded Minecraft server. It uses the `itzg/minecraft-server` Docker image to simplify the setup and management of the server.

# Building and Running

The server is intended to be run using `docker-compose`.

```yaml
version: '3.8'
services:
  minecraft:
    image: itzg/minecraft-server
    ports:
      - "25565:25565"
    environment:
      EULA: "TRUE"
      TYPE: "CURSEFORGE"
      CF_SERVER_MOD: "https://www.curseforge.com/minecraft/modpacks/cobbleverse"
      MEMORY: "6G"
      # Environment variables from .env file will override these
      SERVER_NAME: "${SERVER_NAME}"
      MOTD: "${SERVER_MOTD}"
      DIFFICULTY: "${DIFFICULTY}"
      ALLOW_FLIGHT: "${ALLOW_FLIGHT}"
      SPAWN_MONSTERS: "${SPAWN_MONSTERS}"
    volumes:
      - ./data:/data
```

Once the `docker-compose.yml` and `.env` files are created, you can run the server with:

```bash
# Copy the example .env file
cp .env.example .env

# Start the server in detached mode
docker-compose up -d
```

# Development Conventions

Server configuration is managed through environment variables defined in the `.env` file. The `itzg/minecraft-server` image uses these variables to configure the Minecraft server properties.

Key environment variables include:
- `SERVER_NAME`: The name of the server displayed in the Minecraft client.
- `MOTD`: The message of the day for the server.
- `DIFFICULTY`: The game difficulty (e.g., `peaceful`, `easy`, `normal`, `hard`).
- `ALLOW_FLIGHT`: Whether to allow players to fly.
- `SPAWN_MONSTERS`: Whether monsters should spawn.
