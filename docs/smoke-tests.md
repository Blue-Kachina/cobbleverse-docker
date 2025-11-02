# Smoke Tests for Cobbleverse Docker Server

Use these lightweight checks to verify the setup is healthy without doing a full gameplay QA.

Important: Modrinth installer output appears in the container logs (docker compose logs), not in data/logs/latest.log. The latest.log file only contains the Minecraft server's own log after it starts.

Prereqs
- Docker and Docker Compose installed
- This repository checked out locally
- Optional: .env populated (Phase 2+)

Quick checklist
1) Compose file validation
- Command: docker compose config
- Expect: no errors; rendered envs visible.

2) Container up (optional for quick read-only checks)
- Command: docker compose up -d
- Expect: container starts. First run with MODRINTH_MODPACK enabled can take many minutes.

3) Live log tail for success markers
- Command: docker compose logs -f mc
- Expect: look for lines similar to:
  - "[Server] Done" or "Done (X.Xs)! For help, type \"help\""
  - Modrinth installer activity (look for lines mentioning "Modrinth", "mrpack", or downloading mods)
  - Fabric loader initialized, datapacks discovery
  - Absence of "FATAL" / "Exception in server tick loop"

4) Data directory spot checks (no container required)
- Expect paths/files:
  - data/mods contains many .jar files
  - data/config contains folders like cobblemon, safepastures, etc.
  - data/world/datapacks includes COBBLEVERSE-Sinnoh-DP.zip (after you copy per README Phase 3)

5) Datapack enablement (after world exists and server is running)
- Commands:
  - docker compose exec mc mc-send-to-console "/datapack list"
  - If disabled: enable and reload per README Phase 3 instructions

Automation scripts
- scripts/smoke.sh (Linux/macOS)
- scripts/smoke.ps1 (Windows PowerShell)

These scripts perform checks 1, 3, and 4 automatically and exit non-zero if failures are detected. When container run is enabled, they also display if Modrinth activity was detected in logs and will warn if neither MODRINTH_MODPACK nor MODRINTH_URL are set.

Notes
- The first modpack install can be slow; prefer to wait until logs show the server has reached the "Done" state before running datapack checks.
- If you changed SERVER_WORLDNAME, ensure the datapack is copied under data/<WORLD>/datapacks as documented.
