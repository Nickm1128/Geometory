param(
  [string]$GodotPath = ""
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot

if (-not $GodotPath) {
  $found = & (Join-Path $PSScriptRoot "find_godot.ps1") -RequirePinned 2>$null | Select-Object -First 1
  if ($found) {
    $GodotPath = $found
  }
}

if (-not $GodotPath -or -not (Test-Path -LiteralPath $GodotPath -PathType Leaf)) {
  throw "Pinned Godot executable not found. Pass the 4.6.3 executable or install the version in tools/toolchain.json."
}

$toolchain = Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot "toolchain.json") | ConvertFrom-Json
$versionOutput = & $GodotPath --version 2>$null | Select-Object -First 1
if ([string]$versionOutput -notlike "$([string]$toolchain.godot.version).*") {
  throw "Godot $($toolchain.godot.version) is required; '$GodotPath' reports '$versionOutput'."
}

& $GodotPath --headless --path (Join-Path $repoRoot "godot") --script "res://tests/run_core_tests.gd"
if ($LASTEXITCODE -ne 0) {
  throw "Core tests failed with exit code $LASTEXITCODE."
}
