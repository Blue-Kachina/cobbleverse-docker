param(
  [switch]$RunContainer
)

$ErrorActionPreference = 'Stop'

Write-Host '== Cobbleverse Smoke Test (PowerShell) =='

# 1) Compose validation
Write-Host '-> Validating docker compose file...'
try {
  docker compose config | Out-Null
  Write-Host 'OK: docker compose config valid'
} catch {
  Write-Error 'FAIL: docker compose config invalid'
  exit 1
}

# 1b) Show key rendered environment values
Write-Host '-> Rendering key env vars (from docker compose config):'
try {
  docker compose config | Select-String -Pattern 'MODRINTH|DEBUG|MEMORY' | ForEach-Object { $_.Line } | Write-Host
} catch {
  Write-Warning 'WARN: Unable to render env vars from compose config'
}

# Warn if neither MODRINTH_MODPACK nor MODRINTH_URL are set
$envRender = docker compose config | Select-String -Pattern '^\s+environment:' -Context 0,200 | ForEach-Object { $_.ToString() }
$modrinthModpackEmpty = ($envRender -match 'MODRINTH_MODPACK: ""')
$modrinthUrlEmpty = ($envRender -match 'MODRINTH_URL: ""')
if ($modrinthModpackEmpty -and $modrinthUrlEmpty) {
  Write-Host 'INFO: Neither MODRINTH_MODPACK nor MODRINTH_URL are set. Modrinth installer will NOT run.'
}

# 2) Optional: run container
if ($RunContainer) {
  Write-Host '-> Starting container (detached)...'
  docker compose up -d
  if ($LASTEXITCODE -ne 0) { Write-Error 'FAIL: docker compose up failed'; exit 1 }
  Write-Host 'Container started. Waiting up to 60s for logs...'
  $start = Get-Date
  while ((Get-Date) - $start -lt [TimeSpan]::FromSeconds(60)) {
    Start-Sleep -Seconds 5
    $logs = docker compose logs --no-color mc 2>$null
    if ($logs -match 'Done \(') { Write-Host 'OK: Server reached Done state'; break }
  }
  # Determine if mods already installed before checking for Modrinth logs
  $repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path | Split-Path -Parent
  $mods = Join-Path $repoRoot 'data\mods'
  $modsInstalled = $false
  if (Test-Path $mods) {
    $modCountEarly = (Get-ChildItem -Path $mods -Filter '*.jar' -ErrorAction SilentlyContinue | Measure-Object).Count
    if ($modCountEarly -gt 0) { $modsInstalled = $true }
  }
  # Check for Modrinth/mrpack activity
  $allLogs = docker compose logs --no-color mc 2>$null
  if ($allLogs -match '(?i)modrinth|mrpack') {
    Write-Host 'OK: Detected Modrinth/mrpack activity in container logs'
  } else {
    if ($modsInstalled) {
      Write-Host 'INFO: No Modrinth-related messages found in container logs this run (mods already present). This can be expected on subsequent starts.'
    } else {
      Write-Warning 'WARN: No Modrinth-related messages found in container logs. If you expected modpack install, ensure MODRINTH_MODPACK is set in .env and restart.'
    }
  }
}

# 3) Data directory spot checks
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path | Split-Path -Parent
$mods = Join-Path $repoRoot 'data\mods'
$config = Join-Path $repoRoot 'data\config'
$worldDp = Join-Path $repoRoot 'data\world\datapacks'

$ok = $true

if (Test-Path $mods) {
  $modCount = (Get-ChildItem -Path $mods -Filter '*.jar' -ErrorAction SilentlyContinue | Measure-Object).Count
  if ($modCount -gt 0) { Write-Host "OK: mods present ($modCount jars)" }
  else { Write-Warning 'WARN: data/mods exists but no jars found'; $ok = $false }
} else { Write-Warning 'WARN: data/mods missing'; $ok = $false }

if (Test-Path $config) {
  $cfgCount = (Get-ChildItem -Path $config -ErrorAction SilentlyContinue | Measure-Object).Count
  if ($cfgCount -gt 0) { Write-Host "OK: config present ($cfgCount entries)" }
  else { Write-Warning 'WARN: data/config exists but is empty'; $ok = $false }
} else { Write-Warning 'WARN: data/config missing'; $ok = $false }

if (Test-Path $worldDp) {
  $dp = Get-ChildItem -Path $worldDp -Filter 'COBBLEVERSE-Sinnoh-DP.zip' -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($dp) { Write-Host 'OK: COBBLEVERSE-Sinnoh-DP.zip present in world datapacks' }
  else { Write-Warning 'INFO: COBBLEVERSE-Sinnoh-DP.zip not found in world datapacks (may be expected before Phase 3 copy)'}
} else { Write-Host 'INFO: world datapacks folder not present yet' }

if (-not $ok) { exit 2 } else { exit 0 }
