param(
  [string]$GodotPath = "",
  [switch]$Install
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$godotProject = Join-Path $repoRoot "godot"
$exports = Join-Path $repoRoot "exports"
$apk = Join-Path $exports "geometory-debug.apk"

if (-not $GodotPath) {
  $found = & (Join-Path $PSScriptRoot "find_godot.ps1") 2>$null | Select-Object -First 1
  if ($found) {
    $GodotPath = $found
  }
}

if (-not $GodotPath -or -not (Test-Path $GodotPath)) {
  throw "Godot executable not found. Pass -GodotPath 'C:\path\to\Godot.exe'."
}

New-Item -ItemType Directory -Force -Path $exports | Out-Null
& $GodotPath --headless --path $godotProject --export-debug "Android Debug" $apk

if (-not (Test-Path $apk)) {
  throw "Export did not create APK: $apk"
}

Write-Host "Exported $apk"

if ($Install) {
  $adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
  if (-not (Test-Path $adb)) {
    throw "ADB not found at $adb"
  }
  & $adb install -r $apk
}
