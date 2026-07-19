param(
  [switch]$RequirePinned
)

$ErrorActionPreference = "SilentlyContinue"
$repoRoot = Split-Path -Parent $PSScriptRoot
$toolchainPath = Join-Path $PSScriptRoot "toolchain.json"
$pinnedVersion = "4.6.3"
$pinnedConsoleName = "Godot_v4.6.3-stable_win64_console.exe"
$pinnedConsoleSha256 = ""
if (Test-Path -LiteralPath $toolchainPath) {
  $toolchain = Get-Content -Raw -LiteralPath $toolchainPath | ConvertFrom-Json
  $pinnedVersion = [string]$toolchain.godot.version
  $pinnedConsoleName = [string]$toolchain.godot.console_executable
  $pinnedConsoleSha256 = [string]$toolchain.godot.console_executable_sha256
}

$managedPath = Join-Path $env:USERPROFILE "Tools\Godot\$pinnedVersion\$pinnedConsoleName"
if (Test-Path -LiteralPath $managedPath -PathType Leaf) {
  if ($pinnedConsoleSha256) {
    $actualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $managedPath).Hash.ToLowerInvariant()
    if ($actualHash -ne $pinnedConsoleSha256.ToLowerInvariant()) {
      Write-Host "Managed Godot binary hash mismatch at $managedPath."
      exit 1
    }
  }
  $managedVersion = & $managedPath --version 2>$null | Select-Object -First 1
  if ([string]$managedVersion -notlike "$pinnedVersion.*") {
    Write-Host "Managed Godot reports '$managedVersion'; expected $pinnedVersion."
    exit 1
  }
  Write-Output $managedPath
  exit 0
}

if ($RequirePinned) {
  Write-Host "Pinned Godot $pinnedVersion was not found at the managed path in tools/toolchain.json."
  exit 1
}

$candidates = @()
$commands = @("godot", "godot4", "godot_console", "godot4_console")
foreach ($command in $commands) {
  $found = Get-Command $command -ErrorAction SilentlyContinue
  if ($found) {
    $candidates += $found.Source
  }
}

$roots = @(
  "C:\Program Files\Godot",
  "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine",
  "C:\Program Files\Steam\steamapps\common\Godot Engine",
  "$env:LOCALAPPDATA\Programs",
  "$env:LOCALAPPDATA\Microsoft\WindowsApps",
  "$env:USERPROFILE\Downloads",
  "$env:USERPROFILE\Desktop"
) | Where-Object { $_ -and (Test-Path $_) }

foreach ($root in $roots) {
  Get-ChildItem -Path $root -Filter "Godot*.exe" -File -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
    $candidates += $_.FullName
  }
}

$candidates = $candidates | Select-Object -Unique | Sort-Object `
  @{ Expression = { $_ -match "mono" }; Ascending = $true }, `
  @{ Expression = { $_ -notmatch "console" }; Ascending = $true }, `
  @{ Expression = { $_ }; Ascending = $true }
if (-not $candidates -or $candidates.Count -eq 0) {
  Write-Host "No Godot executable found in PATH or common locations."
  exit 1
}

foreach ($candidate in $candidates) {
  Write-Output $candidate
}
