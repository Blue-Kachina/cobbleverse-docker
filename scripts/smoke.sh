#!/usr/bin/env bash
set -euo pipefail

echo '== Cobbleverse Smoke Test (bash) =='

# 1) Compose validation
echo '-> Validating docker compose file...'
if docker compose config >/dev/null; then
  echo 'OK: docker compose config valid'
else
  echo 'FAIL: docker compose config invalid' >&2
  exit 1
fi

# 1b) Show key rendered environment values
echo '-> Rendering key env vars (from docker compose config):'
if docker compose config | grep -E "(MODRINTH|DEBUG|MEMORY)" -n --color=never; then
  :
else
  echo 'WARN: Unable to render env vars from compose config' >&2
fi

# Warn if neither MODRINTH_MODPACK nor MODRINTH_URL are set
env_render=$(docker compose config | sed -n '/environment:/,/^[^ ]/p') || true
if echo "$env_render" | grep -q 'MODRINTH_MODPACK: ""'; then
  modrinth_modpack_empty=1
else
  modrinth_modpack_empty=0
fi
if echo "$env_render" | grep -q 'MODRINTH_URL: ""'; then
  modrinth_url_empty=1
else
  modrinth_url_empty=0
fi
if [[ $modrinth_modpack_empty -eq 1 && $modrinth_url_empty -eq 1 ]]; then
  echo 'INFO: Neither MODRINTH_MODPACK nor MODRINTH_URL are set. Modrinth installer will NOT run.'
fi

# Establish repo/data paths early for later checks
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
mods="$repo_root/data/mods"
config="$repo_root/data/config"
world_dp="$repo_root/data/world/datapacks"
latest_log="$repo_root/data/logs/latest.log"

# Determine if mods already installed on host data dir
mods_installed=0
if [[ -d "$mods" ]]; then
  modCountEarly=$(ls -1 "$mods"/*.jar 2>/dev/null | wc -l | tr -d ' ')
  if [[ "${modCountEarly:-0}" -gt 0 ]]; then
    mods_installed=1
  fi
fi

# 2) Optional: run container if RUN_CONTAINER=1
echo "RUN_CONTAINER=${RUN_CONTAINER:-0}"
if [[ "${RUN_CONTAINER:-0}" == "1" ]]; then
  echo '-> Starting container (detached)...'
  docker compose up -d
  echo 'Container started. Waiting up to 60s for logs...'
  end=$((SECONDS+60))
  saw_done=0
  while (( SECONDS < end )); do
    sleep 5
    logs=$(docker compose logs --no-color mc 2>/dev/null || true)
    if echo "$logs" | grep -q 'Done ('; then
      echo 'OK: Server reached Done state'
      saw_done=1
      break
    fi
  done
  # Check for Modrinth/mrpack activity in container logs
  if docker compose logs --no-color mc 2>/dev/null | grep -Eiq 'modrinth|mrpack'; then
    echo 'OK: Detected Modrinth/mrpack activity in container logs'
  else
    if [[ $mods_installed -eq 1 ]]; then
      echo 'INFO: No Modrinth-related messages found in container logs this run (mods already present). This is expected on subsequent starts.'
    else
      echo 'WARN: No Modrinth-related messages found in container logs. If you expected modpack install, ensure MODRINTH_MODPACK is set in .env and restart.' >&2
    fi
  fi
fi

# 3) Data directory spot checks
ok=0
if [[ -d "$mods" ]]; then
  modCount=$(ls -1 "$mods"/*.jar 2>/dev/null | wc -l | tr -d ' ')
  if [[ "${modCount:-0}" -gt 0 ]]; then
    echo "OK: mods present ($modCount jars)"
  else
    echo 'WARN: data/mods exists but no jars found' >&2
    ok=1
  fi
else
  echo 'WARN: data/mods missing' >&2
  ok=1
fi

if [[ -d "$config" ]]; then
  cfgCount=$(ls -1 "$config" 2>/dev/null | wc -l | tr -d ' ')
  if [[ "${cfgCount:-0}" -gt 0 ]]; then
    echo "OK: config present ($cfgCount entries)"
  else
    echo 'WARN: data/config exists but is empty' >&2
    ok=1
  fi
else
  echo 'WARN: data/config missing' >&2
  ok=1
fi

if [[ -d "$world_dp" ]]; then
  if ls -1 "$world_dp"/COBBLEVERSE-Sinnoh-DP.zip >/dev/null 2>&1; then
    echo 'OK: COBBLEVERSE-Sinnoh-DP.zip present in world datapacks'
  else
    echo 'INFO: COBBLEVERSE-Sinnoh-DP.zip not found in world datapacks (may be expected before Phase 3 copy)'
  fi
else
  echo 'INFO: world datapacks folder not present yet'
fi

# 4) latest.log quick glance (if present)
if [[ -f "$latest_log" ]]; then
  if grep -q 'Done (' "$latest_log" 2>/dev/null; then
    echo 'OK: latest.log shows server reached Done state previously'
  fi
  echo 'INFO: Tail of data/logs/latest.log:'
  tail -n 20 "$latest_log" || true
else
  echo 'INFO: data/logs/latest.log not found yet'
fi

exit $ok
