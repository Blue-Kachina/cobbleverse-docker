### ROADMAP.md — Cobbleverse Docker Server

This roadmap breaks the work into clear, AI‑sized phases with crisp deliverables and acceptance criteria. It includes an inventory of the provided modpack resources to inform planning.

---

### Phase 0 — Inventory and Understanding (you are here)

- Goals
  - Catalog the modpack artifacts and overrides that will influence server setup.
  - Identify what is server‑relevant vs. client‑only.
- Inputs observed in repo
  - `.env.example`
    - `MODRINTH_URL=https://cdn.modrinth.com/data/Jkb29YJU/versions/DrJAo7Hk/COBBLEVERSE%201.6.mrpack`
    - `SERVER_WORLDNAME`, `SERVER_NAME`, `SERVER_MOTD`, `SERVER_ICON`, `ALLOW_FLIGHT`, `SPAWN_MONSTERS`
  - Dev resources folder
    - `.mrpack`: `resources\dev\COBBLEVERSE 1.6.mrpack`
    - Unzipped contents: `resources\dev\unzipped` (expanded for visibility)
      - `modrinth.index.json` (2,500+ lines) including:
        - Many `mods/...jar` entries with `env.client`/`env.server` flags
        - Resource packs referenced in the modpack index:
          - `resourcepacks/Fresh Moves.zip`
          - `resourcepacks/PokeDiscs.zip`
      - Overrides present under `overrides\...`:
        - `overrides\config\...` (extensive JSON/TOML/props for server/client mods)
        - `overrides\datapacks\extra\COBBLEVERSE-Sinnoh-DP.zip` (datapack to be enabled for world)
        - `overrides\resourcepacks\COBBLEVERSE Soundtrack.zip` (client resource pack; optionally distributed)
        - `overrides\shaderpacks\Shaders - HIGH QUALITY\...` and `Shaders - STANDARD\...` (client‑only)
- Assumptions
  - We will use the `itzg/minecraft-server` image with Modrinth modpack install via `MODRINTH_URL` (supported by the image).
  - The image will handle downloading and installing the Modrinth pack and applying overrides to the server directory. Client‑only content (shaderpacks, most resource pack behavior) will not affect headless server execution but may be used for client distribution.
- Acceptance criteria
  - Inventory documented (above). Open questions captured for later phases.

Open questions to confirm later
- Are any mods in `modrinth.index.json` marked client‑only that the server image won’t automatically exclude? If so, we need an exclusion/cleanup pass.
- Do we want the server to offer a resource pack automatically via `server.properties` (`resource-pack`, `resource-pack-prompt`, `require-resource-pack`)? If yes, we must host the pack(s) at a stable URL.

---

### Phase 1 — Baseline Docker Scaffolding

- Tasks
  - Create `docker-compose.yml` with:
    - Image: `itzg/minecraft-server:latest`
    - Volumes: `./data:/data` (persistent world and config), optional `./backups:/backups`
    - Ports: `25565:25565`
    - Env file: `.env`
    - Memory limits per `.env` and host capacity (recommend 6–8 GB for Cobblemon‑heavy packs)
    - `EULA=TRUE`
    - `TYPE=FABRIC` or `TYPE=QUILT` (match the pack; Cobbleverse 1.6 appears Fabric)
    - `USE_AIKAR_FLAGS=true` or JVM tuning vars
  - Ensure `.gitignore` excludes `data`, `backups`, and local dev resources.
- Deliverables
  - `docker-compose.yml`
  - Updated `README.md` quickstart with compose usage and memory guidance
- Acceptance criteria
  - `docker-compose up -d` starts a vanilla (no modpack yet) container without errors on a clean environment.

---

### Phase 2 — Modpack Acquisition via Modrinth

- Tasks
  - Wire `.env` to include working `MODRINTH_URL` (already present in `.env.example`).
  - Configure `itzg/minecraft-server` variables:
    - `MODRINTH_URL` — as provided
    - `USE_MODPACK_CACHE=true` — speed up rebuilds
    - `REMOVE_OLD_MODS=true` — keep `mods` clean across updates
    - `OVERRIDE_SERVER_PROPERTIES=true` — ensure env‑driven properties apply
  - Bring server up and allow first‑run installer to fetch the modpack.
  - Validate installer logs: all `mods` downloaded; no hash mismatches.
- Deliverables
  - Confirmed successful Modrinth install in logs; populated `/data/mods` and `/data/config`.
- Acceptance criteria
  - First run completes without fatal errors; server reaches “Done” state.

---

### Phase 3 — Apply and Verify Overrides

- Tasks
  - Verify that `overrides\config\...` files are applied into `/data/config`.
  - Verify datapack install for the selected world:
    - Ensure `overrides\datapacks\extra\COBBLEVERSE-Sinnoh-DP.zip` is present in `/data/world/datapacks` for `SERVER_WORLDNAME`.
    - Run `/datapack list` in console or use logs to confirm it loads.
  - Resource packs:
    - `overrides\resourcepacks\COBBLEVERSE Soundtrack.zip` and indexed packs (`Fresh Moves.zip`, `PokeDiscs.zip`) are client‑side.
    - Decide whether to auto‑offer a pack via `server.properties`:
      - `resource-pack` URL to a hosted `.zip`
      - `require-resource-pack=true` (optional)
      - `resource-pack-prompt="Cobbleverse soundtrack and UI assets"` (optional)
  - Shaderpacks are client‑only; do nothing server‑side.
- Deliverables
  - Validation notes/screenshots/log excerpts showing configs applied and datapack enabled.
- Acceptance criteria
  - All overrides relevant to the server are present under `/data` and effective; world starts with datapack active.

---

### Phase 4 — Client‑Only Mod Curation and Compliance

- Tasks
  - Inspect `modrinth.index.json` for any entries where `env.server` is not `required` (client‑only).
  - Confirm the itzg installer excludes those from server `mods`; if not, define exclusions:
    - Use environment/installer features (e.g., `MODRINTH_EXCLUDE_FILES`, if supported) or post‑install cleanup step via `INIT_MEMORY`, `ENABLE_ROLLING_LOGS` and a startup script in `/data` (supported by image via `customization`/`init` directories).
  - Maintain a `docs/client-only-mods.md` list for transparency.
- Deliverables
  - Documented list of excluded client‑only files and method used to exclude.
- Acceptance criteria
  - No client‑only mod jars remain in `/data/mods`; server boots cleanly without client‑only errors.

---

### Phase 5 — Server Configuration and Policy

- Tasks
  - Map `.env` variables to server properties via `itzg` mapping:
    - `SERVER_WORLDNAME`, `SERVER_NAME`, `SERVER_MOTD`, `ALLOW_FLIGHT`, `SPAWN_MONSTERS`, optional `DIFFICULTY`, `VIEW_DISTANCE`, `SIMULATION_DISTANCE`, `ENABLE_COMMAND_BLOCK`, `ONLINE_MODE`, `WHITE_LIST`, `ENABLE_STATUS`
  - Set icon: download `SERVER_ICON` to `/data/server-icon.png` during init (or let image handle if supported).
  - Define ops/whitelist:
    - Provide `OPS` and `WHITELIST` envs or mount JSON lists (`ops.json`, `whitelist.json`).
  - Gamerules and pack activation commands scripted into a one‑time `init` script (e.g., enable datapack, set keepInventory if desired).
- Deliverables
  - Updated `.env` with chosen values
  - Optional init scripts for one‑time setup
- Acceptance criteria
  - On fresh start, the server reflects configured properties, with ops/whitelist applied.

---

### Phase 6 — Performance and Stability Tuning

- Tasks
  - Memory and GC:
    - Allocate 6–8 GB (`MEMORY=8G`) based on host capacity.
    - Enable `USE_AIKAR_FLAGS=true` or custom `JVM_OPTS` (G1GC, region size tuning).
  - Tick/performance mods included in pack (e.g., ModernFix, Sodium, etc.) are already configured via overrides; verify key configs:
    - Examples seen: `overrides\config\modernfix-mixins.properties`, `sodium-options.json`, `entityculling.json`, etc.
  - Server view/simulation distances and mob caps set for expected player count.
  - Crash handling:
    - Enable `RESTART_ON_CRASH=true` and `MAX_TICK_TIME=-1` only if appropriate for the pack (test first!).
- Deliverables
  - Finalized `.env` with memory/GC/tick settings, and rationale in `docs/performance-notes.md`.
- Acceptance criteria
  - Load tests for 2–5 concurrent players show stable TPS and memory behavior for 30–60 minutes.

---

### Phase 7 — Backups, Updates, and Operations

- Tasks
  - Backups:
    - Enable image backup features (`ENABLE_ROLLING_LOGS`, `BACKUP_INTERVAL`, or external cron/compose sidecar using `itzg/mc-backup`).
    - Store backups under `./backups` with rotation policy.
  - Updates:
    - Pin `MODRINTH_URL` to specific version (already 1.6) and document update procedure (test on a staging world, then promote).
    - Set `STOP_SERVER_ANNOUNCE_DELAY` for graceful restarts via RCON.
  - Monitoring and access:
    - Enable `RCON_PASSWORD` and use `itzg/mc-monitor` or Prometheus exporter sidecar.
- Deliverables
  - Backup schedule, update checklist, monitoring notes
- Acceptance criteria
  - Able to restore a backup to a fresh `data` directory and successfully start the server.

---

### Phase 8 — Security, Networking, and Productionization

- Tasks
  - Networking: expose `25565/tcp`; if behind a reverse proxy or DDoS layer, document configuration.
  - Security: run under a non‑root UID/GID (supported by image via `UID`/`GID`), restrict file permissions on `data`/`backups`.
  - Timezone and logging: set `TZ`, centralize logs, confirm log rotation.
- Deliverables
  - Documented deploy profile (standalone host vs. VPS vs. home lab)
- Acceptance criteria
  - External clients can reliably join; logs and access controls meet expectations.

---

### Phase 9 — QA and Test Matrix

- Tasks
  - First‑boot smoke test: world generation with datapack active.
  - Player join/leave; Cobblemon functions (spawns, battles); travel; shops/economy (if configured).
  - Resource pack prompt (if enabled) and hash verification.
  - Save/restart cycle integrity; verify no config resets.
- Deliverables
  - `docs/test-matrix.md` with pass/fail results and issues.
- Acceptance criteria
  - All critical gameplay loops function; zero crash on typical actions.

---

### Phase 10 — Documentation and Handoff

- Tasks
  - Produce `README.md` production quickstart, troubleshooting, and update guide.
  - Document overrides mapping and any customizations made from defaults.
- Deliverables
  - Final docs; versioned `compose` and `.env.example`
- Acceptance criteria
  - Another operator can set up the server from scratch using the repo with minimal assistance.

---

### Appendix — Overrides and Resource Notes (from inventory)

- Server‑relevant
  - `overrides\config\...` (numerous files like `cobblemon\main.json`, `safepastures.json`, `repurposed_structures.json`, `playerxp.json`, etc.)
  - `overrides\datapacks\extra\COBBLEVERSE-Sinnoh-DP.zip`
- Client‑side (inform player distribution)
  - `overrides\resourcepacks\COBBLEVERSE Soundtrack.zip`
  - Shaderpacks under `overrides\shaderpacks\Shaders - STANDARD` and `Shaders - HIGH QUALITY`
  - Resourcepacks referenced by the modpack index:
    - `Fresh Moves.zip`
    - `PokeDiscs.zip`

Notes
- The Modrinth index lists many mod jars with both `client` and `server` marked `required` (e.g., `entity_model_features_1.21-fabric-3.0.1.jar`, `SafePastures-1.1.0+1.21.1.jar`). We will still validate server boot logs for any accidental client‑only inclusions.

---

### Definition of Done (for this roadmap)
- This ROADMAP.md reflects the complete set of tasks needed to bring up a fully functional Cobbleverse server using the supplied modpack and overrides.
