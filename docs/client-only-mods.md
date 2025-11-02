# Client-only mods (Phase 4)

Purpose: ensure the headless server does not load client-only or client-preference mods that can cause warnings, crashes, or unnecessary overhead.

This repository wires an init cleanup step that runs inside the container at startup and removes known client-only jars from /data/mods. The list is curated from the modpack's modrinth.index.json and common Fabric client-side utilities.

Cleanup mechanism
- docker-compose mounts ./scripts/init to /data/init in the container
- The itzg/minecraft-server image executes scripts placed in /data/init on each start (sorted by name)
- Our script: scripts/init/10-clean-client-only.sh
  - Matches and deletes files in /data/mods by glob patterns
  - Safe to run multiple times

Current removal list (patterns)
- modmenu-*.jar
- RoughlyEnoughItems-*.jar
- sound-physics-remastered-*-fabric-*.jar
- moreculling-fabric-*.jar
- infinite-music-*.jar
- MusicNotification-*.jar
- Ping-Wheel-*.jar
- particle-rain-*.jar
- paginatedadvancements-*.jar
- notenoughcrashes-*.jar
- respackopts-*.jar
- defaultoptions-*.jar

Why these?
- Intended for client UX, menus, or visuals (e.g., Mod Menu, REI, More Culling)
- Client-only audio/visual (Sound Physics Remastered, Infinite Music)
- Client convenience (Not Enough Crashes, Default Options, Respackopts)

Verifying compliance
1) Start or restart the container:
   - docker compose up -d
2) Inspect remaining server mods:
   - docker compose exec mc sh -lc 'ls -1 /data/mods'
3) Confirm server boots cleanly without client-only warnings:
   - docker compose logs -f mc | grep -i -E "client|Only run on client|Failed to load mod"

Adjusting the list
- If the modpack updates, update scripts/init/10-clean-client-only.sh patterns accordingly.
- You can add or remove patterns to match your policy.

Notes
- Some entries in modrinth.index.json include env flags for both client and server as "required" even when the mod is conceptually client-side; the server may still tolerate them, but we remove them to avoid risks and keep the server lean.
- The script only removes files if present; it will log a summary line.
