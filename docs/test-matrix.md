# QA and Test Matrix (Phase 9)

Purpose: Provide a repeatable checklist to validate a fresh deployment and ongoing updates. Record pass/fail and issues with links to logs or screenshots.

Date: 2025-11-01

How to use
- For each test case, run the steps and mark Result as PASS/FAIL/N.A.
- Capture evidence: latest.log excerpts, console output, or screenshots. Link them in the Notes.
- File issues or follow-ups under an Issues section below.

Environment prerequisites
- Server up via docker-compose with this repo
- Optional: RCON_PASSWORD set if you plan to use console helpers
- For resource pack tests: a hosted resource-pack URL configured in server.properties (optional)

Smoke and helper scripts
- Linux/macOS: RUN_CONTAINER=1 ./scripts/smoke.sh
- Windows (PowerShell): scripts/smoke.ps1 -RunContainer

Core test areas

1) First-boot and datapack activation
- Preconditions: Clean ./data directory (or new SERVER_WORLDNAME)
- Steps:
  - docker compose up -d
  - docker compose logs -f mc and wait for "Done" without fatal errors
  - Verify datapack presence under /data/<WORLD>/datapacks
  - Console: /datapack list enabled (use mc-send-to-console helper)
- Expected:
  - World generates
  - COBBLEVERSE-Sinnoh-DP.zip shows as enabled
- Result: [ ] PASS  [ ] FAIL
- Evidence/Notes:

2) Player join/leave lifecycle
- Steps:
  - Join from a client matching the pack version
  - Observe join/leave in console/logs
- Expected:
  - No authentication/compat errors (unless ONLINE_MODE=false)
  - No unusual warnings; player spawns correctly
- Result: [ ] PASS  [ ] FAIL
- Evidence/Notes:

3) Cobblemon basics (critical gameplay loop)
- Steps:
  - Explore for wild spawns (verify spawn frequency)
  - Initiate a battle and finish it
  - Capture a Pokemon
- Expected:
  - Spawns occur naturally in suitable biomes
  - Battles run to completion without crashes
  - Capture UI and outcomes function
- Result: [ ] PASS  [ ] FAIL
- Evidence/Notes:

4) World travel and dimension access
- Steps:
  - Overworld exploration (generate new chunks)
  - Optional: Nether/End access if your policy allows
- Expected:
  - No chunk gen crashes; TPS stable
  - Portals and dimension data save/load correctly
- Result: [ ] PASS  [ ] FAIL
- Evidence/Notes:

5) Economy/shops (if configured)
- Steps:
  - Use shop/economy commands or NPCs per your configuration
- Expected:
  - Currency balance changes persist across relog
  - Shop interactions complete without errors
- Result: [ ] PASS  [ ] FAIL [ ] N.A.
- Evidence/Notes:

6) Resource pack prompt and hash verification (optional)
- Preconditions: Server configured with resource-pack, resource-pack-sha1, and optional prompt/require settings
- Steps:
  - Connect from a clean client profile without the pack cached
  - Accept the prompt to download
- Expected:
  - Client downloads the pack; hash matches; pack applies
  - If require-resource-pack=true, client refused on decline
- Result: [ ] PASS  [ ] FAIL [ ] N.A.
- Evidence/Notes:

7) Save/restart cycle integrity
- Steps:
  - Perform gameplay actions that change world and player state (inventory, positions)
  - docker compose restart mc (or stop/start)
  - Rejoin and verify state
- Expected:
  - No config resets under /data/config
  - World/player state intact; no chunk corruption
- Result: [ ] PASS  [ ] FAIL
- Evidence/Notes:

8) Logs and crash-free typical actions
- Steps:
  - 30–60 minutes of typical play (explore, battle, build)
  - Monitor docker compose logs -f mc
- Expected:
  - No crashes; rare warnings only; TPS ~19–20
- Result: [ ] PASS  [ ] FAIL
- Evidence/Notes:

9) Backup/restore spot-check (optional, if backups enabled)
- Steps:
  - Wait for a backup to appear in ./backups
  - Test restore to a staging data directory per docs/operations.md
- Expected:
  - Restored world boots normally
- Result: [ ] PASS  [ ] FAIL [ ] N.A.
- Evidence/Notes:

Operational checks
- Permissions tightening ran (see [init:perms] in logs) [ ] PASS [ ] FAIL [ ] N.A.
- Non-root UID/GID in effect [ ] PASS [ ] FAIL
- Timezone TZ reflected in log timestamps [ ] PASS [ ] FAIL

Recording results
- Create a dated subsection below for each test run and copy the checklist with your PASS/FAIL marks and links to evidence.

Run log 2025-11-01 (example)
- Overall: [ ] PASS [ ] FAIL
- Notes: Initial smoke test only; awaiting multiplayer validation.

Issues and follow-ups
- Track any failures or flaky behaviors here with links to logs and proposed remediation steps.
