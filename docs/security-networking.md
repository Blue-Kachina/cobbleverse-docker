# Security, Networking, and Productionization (Phase 8)

This guide helps you run the Cobbleverse server more securely and reliably on a home lab, VPS, or dedicated/hosted provider.

## Goals
- External clients can reliably join on TCP/25565
- The container runs as a non-root user with restricted file permissions
- Logs use your intended timezone and rotate predictably

## Networking

- Port: The default Minecraft Java port is 25565/TCP. docker-compose maps host 25565 to the container.
- Home network (router/NAT):
  - Forward port 25565/TCP on your router to the host’s LAN IP.
  - Consider a Dynamic DNS hostname (e.g., duckdns, Cloudflare DDNS) so players can connect via name.
- Cloud/VPS:
  - Open 25565/TCP in the provider firewall/security group (AWS SG, GCP VPC firewall, etc.).
  - Many providers block inbound by default; explicitly allow from 0.0.0.0/0 or a narrower IP set.
- Firewalls on the host:
  - Linux (ufw): `sudo ufw allow 25565/tcp`
  - Windows Defender Firewall: create an inbound rule for TCP 25565 to the Docker host
- Reverse proxy / DDoS protection:
  - Minecraft is a raw TCP protocol; do not place it behind an HTTP reverse proxy. If you proxy, use L4/TCP forwarding (HAProxy, NGINX stream, Traefik TCP) with a straight passthrough.
  - For DDoS protection, prefer a provider with L4 game filtering (e.g., OVH Game) or a Minecraft-aware TCP proxy (e.g., TCPShield). Configure them to forward to your host:25565.

## Security

- Non-root execution:
  - The itzg/minecraft-server image supports running as a non-root user via UID/GID env variables.
  - This repo’s docker-compose sets UID and GID from .env (defaults 1000:1000). Ensure the host user that owns `./data` and `./backups` matches these or is compatible.
- File permissions:
  - An init script (scripts/init/30-permissions.sh) sets restrictive permissions (770) on key directories when writable.
  - Keep repo (and .env) private. Your RCON password should never be committed to VCS.
- RCON:
  - RCON is powerful remote console access. It is enabled only when you set `RCON_PASSWORD` in .env.
  - We do NOT publish the RCON port in docker-compose. Use `docker compose exec mc mc-send-to-console` for local admin tasks, or carefully expose/bind RCON to trusted networks only.
- Online mode / whitelist:
  - Keep `ONLINE_MODE=true` unless you absolutely need offline mode.
  - Use `ENFORCE_WHITELIST=true` and populate `WHITELIST` for private servers.

## Timezone and Logging

- Timezone: Set `TZ` in .env (e.g., `TZ=UTC` or `TZ=America/New_York`). Compose passes this to both the server and backup sidecar.
- Log rotation: `ENABLE_ROLLING_LOGS=true` is enabled in compose. The itzg image rotates the console log output; Minecraft’s `logs/` will also roll by date.
- Centralization (optional):
  - You can ship container logs to a log collector (e.g., Docker logging driver, Loki, Fluent Bit). For simplicity, this repo keeps logs on disk under `./data/logs`.

## Production Profiles

- Standalone host/home lab: use this repo as-is, forward 25565/TCP, and keep regular backups (the sidecar handles this).
- VPS/dedicated:
  - Harden the OS: automatic security updates, firewall on default deny, open 25565/TCP.
  - Consider a provider with L4 game DDoS mitigation.
- Multi-server / proxy (advanced):
  - If you later introduce Bungee/Velocity or an L4 proxy, configure TCP passthrough; ensure keep-alives and timeouts suit Minecraft traffic.

## Verification Checklist

1) Connectivity:
- From another network, attempt to join `<your-hostname>:25565` in the Minecraft client.
- Or run: `mc-monitor status --host <host> --port 25565` (install itzg/mc-monitor locally).

2) Permissions:
- After starting the container, check that directories are not world-readable on Linux: `ls -ld data backups` -> mode should be `drwxrwx---` or similar.

3) Timezone and logs:
- Confirm timestamps in `data/logs/latest.log` reflect your `TZ`.

If anything fails, re-check .env (UID/GID/TZ), router/firewall rules, and container logs (`docker compose logs -f mc`).
