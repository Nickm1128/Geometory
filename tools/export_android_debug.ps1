param(
  [string]$GodotPath = "",
  [ValidateSet("Android Debug", "Android Visual QA")]
  [string]$Preset = "Android Debug",
  [string]$Serial = "",
  [switch]$Install
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$godotProject = Join-Path $repoRoot "godot"
$exports = Join-Path $repoRoot "exports"
$apkName = if ($Preset -eq "Android Visual QA") { "geometory-qa-debug.apk" } else { "geometory-debug.apk" }
$apk = Join-Path $exports $apkName

if (-not $GodotPath) {
  $found = & (Join-Path $PSScriptRoot "find_godot.ps1") -RequirePinned 2>$null | Select-Object -First 1
  if ($found) {
    $GodotPath = $found
  }
}

if (-not $GodotPath -or -not (Test-Path -LiteralPath $GodotPath -PathType Leaf)) {
  throw "Pinned Godot executable not found. Pass -GodotPath or install the version in tools/toolchain.json."
}

$toolchain = Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot "toolchain.json") | ConvertFrom-Json
$versionOutput = & $GodotPath --version 2>$null | Select-Object -First 1
if ([string]$versionOutput -notlike "$([string]$toolchain.godot.version).*") {
  throw "Godot $($toolchain.godot.version) is required; '$GodotPath' reports '$versionOutput'."
}

$sdkRoot = if ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } elseif ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { Join-Path $env:LOCALAPPDATA "Android\Sdk" }
$androidStudioJava = "C:\Program Files\Android\Android Studio\jbr"
$javaRoot = if (Test-Path -LiteralPath (Join-Path $androidStudioJava "bin\java.exe")) { $androidStudioJava } elseif ($env:JAVA_HOME) { $env:JAVA_HOME } else { "" }
if (-not (Test-Path -LiteralPath $sdkRoot)) {
  throw "Android SDK not found at $sdkRoot."
}
if (-not (Test-Path -LiteralPath (Join-Path $javaRoot "bin\java.exe"))) {
  throw "Java runtime not found at $javaRoot."
}
$env:ANDROID_HOME = $sdkRoot
$env:ANDROID_SDK_ROOT = $sdkRoot
$env:JAVA_HOME = $javaRoot

New-Item -ItemType Directory -Force -Path $exports | Out-Null
& $GodotPath --headless --path $godotProject --export-debug $Preset $apk
if ($LASTEXITCODE -ne 0) {
  throw "Godot export failed with exit code $LASTEXITCODE."
}

if (-not (Test-Path $apk)) {
  throw "Export did not create APK: $apk"
}

Write-Host "Exported $apk"

if ($Install) {
  $adb = Join-Path $sdkRoot "platform-tools\adb.exe"
  if (-not (Test-Path $adb)) {
    throw "ADB not found at $adb"
  }
  $adbArgs = @()
  if ($Serial) {
    $adbArgs += @("-s", $Serial)
  }
  & $adb @adbArgs install -r $apk
  if ($LASTEXITCODE -ne 0) {
    throw "ADB install failed with exit code $LASTEXITCODE."
  }
}
