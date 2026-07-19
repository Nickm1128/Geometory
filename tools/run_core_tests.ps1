param(
  [string]$GodotPath = ""
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot

if (-not $GodotPath) {
  $found = & (Join-Path $PSScriptRoot "find_godot.ps1") 2>$null | Select-Object -First 1
  if ($found) {
    $GodotPath = $found
  }
}

if (-not $GodotPath -or -not (Test-Path $GodotPath)) {
  throw "Godot executable not found. Pass -GodotPath 'C:\path\to\Godot.exe'."
}

& $GodotPath --headless --path (Join-Path $repoRoot "godot") --script "res://tests/run_core_tests.gd"
