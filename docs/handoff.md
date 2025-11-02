# Handoff and Runbook (Phase 10)

Date: 2025-11-01
Audience: New operators who need to stand up and run the Cobbleverse server with minimal assistance.

## 0) What you’re getting
- Dockerized Cobbleverse (Fabric) Minecraft server based on itzg/minecraft-server
- Automated Modrinth pack install (COBBLEVERSE 1.6)
- Init hooks for client-only mod cleanup, server icon, and permissions hardening
- Backups sidecar with retention
- Clear environment-driven configuration

## 1) Prerequisites
- Docker + Docker Compose
- 8 GB free RAM recommended (server uses 8G by default; adjust in .env)
- Port 25565/TCP reachable from your players (router/VPS firewall)

## 2) First-time setup (Production Quickstart)
1. Clone repo and enter folder
2. Copy env file and edit values
   - Windows PowerShell: `Copy-Item .env.example .env`
   - Linux/macOS: `cp .env.example .env`
3. Edit .env:
   - SERVER_WORLDNAME=YOUR_WORLD
   - SERVER_NAME/MOTD to taste
   - Ensure MODRINTH_MODPACK points to COBBLEVERSE 1.6 (already set)
   - MEMORY=8G (or adjust)
   - Optional: OPS/WHITELIST, TZ, UID/GID
4. Start server: `docker compose up -d`
5. Watch logs: `docker compose logs -f mc`
   - First boot downloads mods, applies overrides; expect several minutes.
6. Verify reachability from a client (host:25565)

## 3) Day-2 operations
- Logs: `docker compose logs -f mc` and `data/logs/latest.log`
- Console command: `docker compose exec mc mc-send-to-console "/say hello"`
- Backups: Daily tar archives in ./backups (interval/retention in .env)
- Safe restart: `docker compose restart mc` (players see a short announce if STOP_SERVER_ANNOUNCE_DELAY is set)

## 4) Restore from backup (summary)
- Stop: `docker compose down`
- Move `data` aside and extract a chosen archive into a fresh `data`
- Start: `docker compose up -d`
- Detailed steps: see docs/operations.md (Restore procedure)

## 5) Updates (modpack or config)
- Stage changes in a copy or with a new SERVER_WORLDNAME
- Update .env (MODRINTH_MODPACK) or compose labels as needed
- Announce, backup, `docker compose up -d`, watch logs
- Roll back by restoring last good backup if needed
- Detailed guide: docs/operations.md

## 6) Security & networking quick checks
- Non-root: compose passes UID/GID (defaults 1000:1000)
- Permissions tightened by init script (770 on data/backups where possible)
- Open/forward TCP 25565 only; keep RCON disabled unless needed
- More details: docs/security-networking.md

## 7) Troubleshooting quick list
- Modrinth didn’t run: ensure .env exists and MODRINTH_MODPACK is set; restart once
- Idle restarts: ensure ENABLE_AUTOPAUSE/ENABLE_AUTOSTOP are false (already set in compose)
- Datapack not active: use RCON_CMDS_STARTUP or run `/datapack enable "file/COBBLEVERSE-Sinnoh-DP.zip"` then `/reload`
- Crashes/lag: reduce SIMULATION_DISTANCE first; see docs/performance-notes.md

## 8) What changed from defaults (our customizations)
- scripts/init/10-clean-client-only.sh removes known client-only jars
- scripts/init/20-server-icon.sh pulls SERVER_ICON when defined
- scripts/init/30-permissions.sh tightens directory permissions
- docker-compose.yml includes mc-backup sidecar and operational envs

## 9) References
- README.md (phase guides and usage)
- docs/operations.md (backups, updates, monitoring)
- docs/performance-notes.md
- docs/security-networking.md
- docs/client-only-mods.md
- docs/overrides-map.md