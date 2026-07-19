$ErrorActionPreference = "SilentlyContinue"

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
