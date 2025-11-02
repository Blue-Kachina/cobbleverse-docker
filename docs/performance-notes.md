# Performance and Stability Notes (Phase 6)

This document explains the tuning choices we expose and recommend for the Cobbleverse server. It focuses on JVM memory/GC, tick distances, and crash handling. Use it as a reference when adjusting .env and docker-compose settings.

## Memory and GC

- Default MEMORY: 8G (set in docker-compose; override in .env)
  - Cobblemon-heavy packs benefit from 6–8G depending on world size, player count, and host memory.
  - Ensure the host has at least 2–4G free beyond the container allocation for OS and other services.
- Aikar flags: Enabled by default via USE_AIKAR_FLAGS=true in docker-compose.
  - These are a proven baseline for modded servers and use G1GC with sensible pause targets and region sizing.
- Custom JVM options (JVM_OPTS):
  - Leave empty unless you have a reason to replace Aikar flags.
  - Example G1GC set (commented in .env.example):
    -XX:+UseG1GC -XX:MaxGCPauseMillis=100 -XX:+UnlockExperimentalVMOptions 
    -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=16M 
    -XX:G1ReservePercent=20 -XX:InitiatingHeapOccupancyPercent=15 -XX:+ParallelRefProcEnabled
- GC observability:
  - For deep analysis, you can add verbose GC logging to JVM_OPTS, e.g., for Java 17+:
    -Xlog:gc*:stdout:time,uptime:filecount=5,filesize=10m

## View/Simulation Distances and Mob Caps

- Distances are the biggest lever to stabilize TPS when multiple players are online.
- Suggested starting points:
  - 1–3 players: VIEW_DISTANCE=10, SIMULATION_DISTANCE=10
  - 4–8 players: VIEW_DISTANCE=8–10, SIMULATION_DISTANCE=6–10
- If TPS dips under load, lower SIMULATION_DISTANCE first, then VIEW_DISTANCE.
- Mob caps may be configurable via mods; for vanilla-like behavior, consider reducing spawn caps when running many dimensions.

## Crash Handling and Watchdog

- RESTART_ON_CRASH=true lets the container supervisor bring the server back automatically after a crash.
- MAX_TICK_TIME controls the server watchdog (in ms); -1 disables it.
  - Use -1 with caution; the watchdog helps detect hung ticks/deadlocks.
  - A pattern that works for many modpacks: test with defaults first; only disable watchdog after verifying stability.

## Included Performance Mods and Overrides

The modpack already contains several performance-oriented mods (examples: ModernFix, Sodium on client, various culling/tweak mods). Their configs are applied via overrides during the Modrinth install.

- Verify presence of key configs under /data/config after Phase 2:
  - modernfix-mixins.properties
  - sodium-options.json (client-side reference)
  - entityculling.json
  - and many others under the overrides directory

## Validation Checklist

- Allocate memory:
  - MEMORY=8G in .env (adjust per host)
  - Confirm via logs that Aikar flags are active (itzg image prints JVM args on start)
- Run a 30–60 minute multiplayer session (2–5 players), performing typical activities.
- Monitor:
  - TPS using available commands/mods; watch for consistent 19–20 TPS.
  - GC behavior: sporadic, short pauses are expected; frequent long pauses indicate pressure.
  - latest.log for warnings, "Can't keep up!" messages, or crash reports.
- If instability appears:
  - Reduce SIMULATION_DISTANCE by 2 and retry
  - Reduce VIEW_DISTANCE by 2 if needed
  - Ensure host resource headroom (CPU steal, swap usage, and IO wait should be low)

## Rationale

- Memory and G1GC tuning reduces GC pauses that otherwise stall ticks.
- Lower distances reduce the number of ticking chunks/entities per player.
- Keeping the watchdog enabled during initial testing helps surface hangs early; automatic restart is a safety net but should not hide systemic issues.
