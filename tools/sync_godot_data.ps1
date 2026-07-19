$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$source = Join-Path $repoRoot "data"
$target = Join-Path $repoRoot "godot\data"

if (-not (Test-Path $source)) {
  throw "Source data folder not found: $source"
}

New-Item -ItemType Directory -Force -Path $target | Out-Null
Get-ChildItem -Path $source -Directory | ForEach-Object {
  $dest = Join-Path $target $_.Name
  if (Test-Path $dest) {
    Remove-Item -LiteralPath $dest -Recurse -Force
  }
  Copy-Item -LiteralPath $_.FullName -Destination $dest -Recurse -Force
}

Write-Host "Synced data from $source to $target"
