param(
  [Parameter(Mandatory = $true)]
  [string]$Scenario,
  [string]$Serial = "",
  [string]$OutputDir = "",
  [string]$GodotPath = "",
  [ValidateSet("live", "galaxy_s24_primary")]
  [string]$SafeAreaProfile = "live",
  [ValidateSet("1.0", "1.15", "1.30")]
  [string]$UiScale = "1.15",
  [int]$Seed = 12345,
  [int]$TimeoutSeconds = 90,
  [switch]$SkipExport,
  [switch]$SkipInstall
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$catalogPath = Join-Path $repoRoot "godot\visual_qa\scenarios.json"
$catalog = Get-Content -Raw -LiteralPath $catalogPath | ConvertFrom-Json
$scenarioRecord = $catalog.scenarios | Where-Object { $_.id -eq $Scenario } | Select-Object -First 1
if (-not $scenarioRecord) {
  throw "Unknown visual QA scenario '$Scenario'."
}
if (-not [bool]$scenarioRecord.implemented) {
  throw "Scenario '$Scenario' is reserved for a later phase and is not implemented yet."
}

$requirementsPath = Join-Path $PSScriptRoot "requirements-visual-qa.txt"
$requiredJsonSchemaVersion = "4.26.0"
$pythonDependencyProbe = @'
import importlib.metadata
import sys

required = sys.argv[1]
try:
    actual = importlib.metadata.version('jsonschema')
except importlib.metadata.PackageNotFoundError:
    raise SystemExit(2)
raise SystemExit(0 if actual == required else 3)
'@
& python -c $pythonDependencyProbe $requiredJsonSchemaVersion
if ($LASTEXITCODE -ne 0) {
  throw "Visual QA requires jsonschema==$requiredJsonSchemaVersion. Install the pinned dependency with: python -m pip install --requirement `"$requirementsPath`""
}

$sdkRoot = if ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } elseif ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { Join-Path $env:LOCALAPPDATA "Android\Sdk" }
$adb = Join-Path $sdkRoot "platform-tools\adb.exe"
if (-not (Test-Path -LiteralPath $adb)) {
  throw "ADB not found at $adb"
}

function Get-ConnectedSerials {
  return @(& $adb devices | Select-String '^\S+\s+device$' | ForEach-Object { ($_.Line -split '\s+')[0] })
}

function Wait-ConnectedSerials {
  param([int]$WaitSeconds = 15)
  $deadline = (Get-Date).AddSeconds($WaitSeconds)
  do {
    $connectedNow = @(Get-ConnectedSerials)
    if ($connectedNow.Count -gt 0) {
      return $connectedNow
    }
    Start-Sleep -Milliseconds 500
  } while ((Get-Date) -lt $deadline)
  return @()
}

function Wait-SerialConnected {
  param([string]$TargetSerial, [int]$WaitSeconds = 30)
  $deadline = (Get-Date).AddSeconds($WaitSeconds)
  do {
    if ($TargetSerial -in @(Get-ConnectedSerials)) {
      return $true
    }
    Start-Sleep -Milliseconds 500
  } while ((Get-Date) -lt $deadline)
  return $false
}

function Get-ReadyMarkerText {
  $previousPreference = $ErrorActionPreference
  $ErrorActionPreference = "SilentlyContinue"
  $candidate = (& $adb -s $Serial shell run-as $packageName cat files/visual_qa_ready.json 2>$null) -join "`n"
  $readExitCode = $LASTEXITCODE
  $ErrorActionPreference = $previousPreference
  if ($readExitCode -ne 0 -or -not $candidate.Trim().StartsWith("{")) {
    return ""
  }
  return $candidate.Trim()
}

if (-not $Serial) {
  $connected = @(Wait-ConnectedSerials)
  foreach ($candidate in $connected | Where-Object { $_ -like "emulator-*" }) {
    $avdName = (& $adb -s $candidate emu avd name 2>$null | Select-Object -First 1).Trim()
    if ($avdName -eq "Geometory_Galaxy_S24_API36") {
      $Serial = $candidate
      break
    }
  }
  if (-not $Serial -and $connected.Count -eq 1) {
    $Serial = $connected[0]
  }
  if (-not $Serial) {
    throw "Unable to choose an ADB target. Start the Geometory AVD or pass -Serial explicitly."
  }
}
if (-not (Wait-SerialConnected -TargetSerial $Serial)) {
  throw "ADB target is not connected: $Serial"
}

$apk = Join-Path $repoRoot "exports\geometory-qa-debug.apk"
if (-not $SkipExport) {
  $exportArgs = @{
    Preset = "Android Visual QA"
  }
  if ($GodotPath) {
    $exportArgs["GodotPath"] = $GodotPath
  }
  & (Join-Path $PSScriptRoot "export_android_debug.ps1") @exportArgs
  if ($LASTEXITCODE -ne 0) {
    throw "Visual QA export failed."
  }
}
if (-not (Test-Path -LiteralPath $apk)) {
  throw "Visual QA APK is missing: $apk"
}
$apkHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $apk).Hash.ToLowerInvariant()
if (-not (Wait-SerialConnected -TargetSerial $Serial -WaitSeconds 30)) {
  throw "ADB target did not return to the device state after export: $Serial"
}
if (-not $SkipInstall) {
  & $adb -s $Serial install -r $apk
  if ($LASTEXITCODE -ne 0) {
    throw "Visual QA APK installation failed."
  }
}

$packageName = "com.milin.geometory.qa"
$nonce = [guid]::NewGuid().ToString("N")
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
if (-not $OutputDir) {
  $OutputDir = Join-Path $repoRoot "artifacts\visual_qa\$stamp\$Scenario"
}
$OutputDir = [System.IO.Path]::GetFullPath($OutputDir)
$artifactRoot = [System.IO.Path]::GetFullPath((Join-Path $repoRoot "artifacts\visual_qa")).TrimEnd("\")
if (-not $OutputDir.StartsWith($artifactRoot + "\", [System.StringComparison]::OrdinalIgnoreCase)) {
  throw "Visual QA output must remain below $artifactRoot"
}
if (Test-Path -LiteralPath $OutputDir) {
  if (@(Get-ChildItem -LiteralPath $OutputDir -Force).Count -gt 0) {
    throw "Visual QA output directory must be new or empty: $OutputDir"
  }
}
else {
  New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

$request = [ordered]@{
  schema_version = 1
  nonce = $nonce
  scenario_id = $Scenario
  seed = $Seed
  ui_scale = [double]::Parse($UiScale, [System.Globalization.CultureInfo]::InvariantCulture)
  safe_area_profile = $SafeAreaProfile
  build_id = "sha256:$apkHash"
}
$requestPath = Join-Path $OutputDir "request.json"
[System.IO.File]::WriteAllText($requestPath, ($request | ConvertTo-Json -Depth 5), [System.Text.UTF8Encoding]::new($false))
$schemaValidator = Join-Path $PSScriptRoot "validate_json_schema.py"
$requestSchema = Join-Path $repoRoot "godot\visual_qa\request.schema.json"
$readySchema = Join-Path $repoRoot "godot\visual_qa\ready.schema.json"
& python $schemaValidator $requestSchema $requestPath
if ($LASTEXITCODE -ne 0) {
  throw "Generated visual QA request did not satisfy its schema."
}

$remoteRequest = "/data/local/tmp/geometory_visual_qa_request_$nonce.json"
$remoteScreen = "/data/local/tmp/geometory_visual_qa_$nonce.png"
$immersiveConfirmationOriginal = ((& $adb -s $Serial shell settings get secure immersive_mode_confirmations) -join "").Trim()
$restoreImmersiveConfirmation = $immersiveConfirmationOriginal -ne "confirmed"
try {
  if ($restoreImmersiveConfirmation) {
    & $adb -s $Serial shell settings put secure immersive_mode_confirmations confirmed | Out-Null
    if ($LASTEXITCODE -ne 0) {
      throw "Unable to suppress Android's immersive-mode education overlay on the QA target."
    }
  }

  & $adb -s $Serial shell am force-stop $packageName | Out-Null
  & $adb -s $Serial push $requestPath $remoteRequest | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to push visual QA request."
  }
  & $adb -s $Serial shell run-as $packageName mkdir -p files | Out-Null
  & $adb -s $Serial shell run-as $packageName cp $remoteRequest files/visual_qa_request.json | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to place request in the QA app sandbox. Confirm this is a debuggable QA build."
  }
  & $adb -s $Serial shell run-as $packageName rm -f files/visual_qa_ready.json 2>$null | Out-Null
  & $adb -s $Serial shell rm -f $remoteRequest | Out-Null
  & $adb -s $Serial logcat -c
  & $adb -s $Serial shell monkey -p $packageName -c android.intent.category.LAUNCHER 1 | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to launch the visual QA app."
  }

  $readyText = ""
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  while ((Get-Date) -lt $deadline) {
    $candidate = Get-ReadyMarkerText
    if ($candidate) {
      $readyText = $candidate
      break
    }
    Start-Sleep -Milliseconds 500
  }

  $readyPath = Join-Path $OutputDir "ready.json"
  $logPath = Join-Path $OutputDir "logcat.txt"
  $screenPath = Join-Path $OutputDir "screen.png"
  $globalLogText = (& $adb -s $Serial logcat -d -t 800) -join "`n"
  $escapedPackageForLog = [regex]::Escape($packageName)
  $packageSystemLogText = @(
    $globalLogText -split "`n" | Where-Object { $_ -match $escapedPackageForLog }
  ) -join "`n"
  $appPid = ((& $adb -s $Serial shell pidof $packageName) -join "").Trim()
  $appLogText = if ($appPid -match '^\d+$') {
    (& $adb -s $Serial logcat --pid=$appPid -d -t 800) -join "`n"
  }
  else {
    ""
  }
  $logText = @(
    "# QA application process log"
    $appLogText
    "# System log lines naming the QA package"
    $packageSystemLogText
  ) -join "`r`n"
  [System.IO.File]::WriteAllText($logPath, $logText, [System.Text.UTF8Encoding]::new($false))
  if (-not $readyText) {
    throw "Timed out waiting for the visual QA ready marker. Inspect $logPath"
  }
  [System.IO.File]::WriteAllText($readyPath, $readyText, [System.Text.UTF8Encoding]::new($false))
  & python $schemaValidator $readySchema $readyPath
  if ($LASTEXITCODE -ne 0) {
    throw "Visual QA ready marker did not satisfy its schema."
  }
  $ready = $readyText | ConvertFrom-Json
  if ($ready.nonce -ne $nonce -or $ready.scenario_id -ne $Scenario) {
    throw "Ready marker did not match the request nonce and scenario."
  }
  if ([int64]$ready.seed -ne $Seed) {
    throw "Ready marker seed did not match the request."
  }
  if ([double]$ready.ui_scale -ne [double]$request.ui_scale) {
    throw "Ready marker UI scale did not match the request."
  }
  if ($ready.safe_area_profile -ne $SafeAreaProfile) {
    throw "Ready marker safe-area profile did not match the request."
  }
  if ($ready.build_id -ne "sha256:$apkHash") {
    throw "Ready marker build ID did not match the exported APK."
  }
  if ([int]$ready.viewport.width -le 0 -or [int]$ready.viewport.height -le 0) {
    throw "Ready marker reported an invalid viewport."
  }
  if ($ready.state_hash -notmatch '^[0-9a-f]{64}$') {
    throw "Ready marker state hash is invalid."
  }
  $failedAssertions = @($ready.assertions.PSObject.Properties | Where-Object { -not [bool]$_.Value } | ForEach-Object { $_.Name })
  if ($failedAssertions.Count -gt 0) {
    throw "Ready marker contains failed assertions: $($failedAssertions -join ', ')"
  }
  if (-not [bool]$ready.success) {
    throw "Visual QA scenario failed before capture: $($ready.errors -join '; ')"
  }

  if (-not $appPid -or $appPid -notmatch '^\d+$') {
    throw "The QA application process is not running after its ready marker."
  }
  $fatalLogFindings = @()
  if ($appLogText -match '(?im)SCRIPT ERROR:|FATAL EXCEPTION:|Fatal signal \d+') {
    $fatalLogFindings += "app process logged a script error, fatal exception, or fatal signal"
  }
  if ($packageSystemLogText -match "(?im)ANR in $escapedPackageForLog|am_anr.*$escapedPackageForLog") {
    $fatalLogFindings += "ActivityManager logged an ANR for the QA package"
  }
  if ($fatalLogFindings.Count -gt 0) {
    throw "Visual QA fatal-log check failed: $($fatalLogFindings -join '; '). Inspect $logPath"
  }

  $windowState = (& $adb -s $Serial shell dumpsys window) -join "`n"
  if ($windowState -match 'mCurrentFocus=.*ImmersiveModeConfirmation') {
    throw "Android's immersive-mode education overlay obscures the fixture; capture rejected."
  }
  $escapedPackageName = [regex]::Escape($packageName)
  if ($windowState -notmatch "mCurrentFocus=.*$escapedPackageName/") {
    throw "An unexpected system or application window has focus; capture rejected."
  }
  $visibleWindowBlocks = [regex]::Matches(
    $windowState,
    '(?ms)^  Window #\d+ Window\{.*?(?=^  Window #\d+ Window\{|\z)'
  )
  $allowedBackgroundWindows = 'StatusBar|NavigationBar|Taskbar|ScreenDecorOverlay|ImageWallpaper|LayeredWallpaperService'
  $unexpectedVisibleWindowCount = @(
    $visibleWindowBlocks |
      Where-Object {
        $_.Value -match '(?m)^\s+isVisible=true\s*$' -and
        $_.Value -notmatch "(?m)^  Window #\d+ Window\{[^`r`n]*$escapedPackageName/" -and
        $_.Value -notmatch "(?m)^  Window #\d+ Window\{[^`r`n]*($allowedBackgroundWindows)"
      }
  ).Count
  if ($unexpectedVisibleWindowCount -gt 0) {
    throw "An unrelated visible window overlays the fixture; capture rejected without recording its application or content. Dismiss the overlay and rerun."
  }

  & $adb -s $Serial shell screencap -p $remoteScreen | Out-Null
  & $adb -s $Serial pull $remoteScreen $screenPath | Out-Null
  & $adb -s $Serial shell rm -f $remoteScreen | Out-Null
  if (-not (Test-Path -LiteralPath $screenPath)) {
    throw "Screenshot capture failed."
  }

  $targetKind = if ($Serial -like "emulator-*") { "emulator" } else { "physical_device" }
  $manifest = [ordered]@{
    schema_version = 1
    scenario_id = $Scenario
    nonce = $nonce
    captured_utc = (Get-Date).ToUniversalTime().ToString("o")
    target_kind = $targetKind
    target_alias = if ($targetKind -eq "emulator") { "Geometory_Galaxy_S24_API36" } else { "primary_galaxy_s24" }
    apk_sha256 = $apkHash
    request = "request.json"
    ready = "ready.json"
    screenshot = "screen.png"
    logcat = "logcat.txt"
    contract_success = [bool]$ready.success
    success = [bool]$ready.success
    system_overlay_check = "passed"
    visible_window_check = "passed"
    fatal_log_check = "passed"
    safe_area_behavior = "live_measurement_only; profile_injection_deferred_to_P05"
    visual_certified = $false
    visual_certification_note = "P00 validates fixture reachability and handshake integrity only; layout and aesthetics require P05 review."
  }
  [System.IO.File]::WriteAllText((Join-Path $OutputDir "manifest.json"), ($manifest | ConvertTo-Json -Depth 5), [System.Text.UTF8Encoding]::new($false))
  Write-Host "Captured visual QA contract scenario '$Scenario' to $OutputDir. Visual certification remains pending P05."
}
finally {
  $cleanupPreference = $ErrorActionPreference
  $ErrorActionPreference = "SilentlyContinue"
  if ($Serial -and $remoteScreen) {
    & $adb -s $Serial shell rm -f $remoteScreen 2>$null | Out-Null
  }
  $ErrorActionPreference = $cleanupPreference
  if ($restoreImmersiveConfirmation) {
    if ($immersiveConfirmationOriginal -and $immersiveConfirmationOriginal -ne "null") {
      & $adb -s $Serial shell settings put secure immersive_mode_confirmations $immersiveConfirmationOriginal | Out-Null
    }
    else {
      & $adb -s $Serial shell settings delete secure immersive_mode_confirmations | Out-Null
    }
  }
}
