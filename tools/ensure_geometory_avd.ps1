param(
  [ValidateSet("Ensure", "Verify")]
  [string]$Mode = "Verify",
  [string]$SdkRoot = "",
  [string]$AvdName = "Geometory_Galaxy_S24_API36",
  [switch]$Launch,
  [int]$BootTimeoutSeconds = 240
)

$ErrorActionPreference = "Stop"
if (-not $SdkRoot) {
  $SdkRoot = if ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } elseif ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { Join-Path $env:LOCALAPPDATA "Android\Sdk" }
}
$SdkRoot = [System.IO.Path]::GetFullPath($SdkRoot).TrimEnd("\")
$androidStudioJava = "C:\Program Files\Android\Android Studio\jbr"
$javaRoot = if (Test-Path -LiteralPath (Join-Path $androidStudioJava "bin\java.exe")) { $androidStudioJava } elseif ($env:JAVA_HOME) { $env:JAVA_HOME } else { "" }
$env:ANDROID_HOME = $SdkRoot
$env:ANDROID_SDK_ROOT = $SdkRoot
$env:JAVA_HOME = $javaRoot

$avdManager = Get-ChildItem -LiteralPath (Join-Path $SdkRoot "cmdline-tools") -Recurse -Filter "avdmanager.bat" -File -ErrorAction SilentlyContinue | Sort-Object FullName -Descending | Select-Object -First 1 -ExpandProperty FullName
$emulator = Join-Path $SdkRoot "emulator\emulator.exe"
$adb = Join-Path $SdkRoot "platform-tools\adb.exe"
$systemImageDirectory = Join-Path $SdkRoot "system-images\android-36\google_apis_playstore\x86_64"
foreach ($required in @($avdManager, $emulator, $adb, $systemImageDirectory, (Join-Path $javaRoot "bin\java.exe"))) {
  if (-not $required -or -not (Test-Path -LiteralPath $required)) {
    throw "Missing Android prerequisite: $required. Install command-line tools with tools/install_android_command_line_tools.ps1 -AcceptLicense."
  }
}

$avdRoot = [System.IO.Path]::GetFullPath((Join-Path $env:USERPROFILE ".android\avd")).TrimEnd("\")
$avdDirectory = Join-Path $avdRoot "$AvdName.avd"
$avdPointer = Join-Path $avdRoot "$AvdName.ini"
$configPath = Join-Path $avdDirectory "config.ini"
foreach ($candidate in @($avdDirectory, $avdPointer, $configPath)) {
  $resolved = [System.IO.Path]::GetFullPath($candidate)
  if (-not $resolved.StartsWith($avdRoot + "\", [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Resolved AVD path escaped the expected AVD root: $resolved"
  }
}

function Get-RunningAvdSerial {
  $deviceLines = & $adb devices | Select-String '^emulator-[0-9]+\s+device$'
  foreach ($line in $deviceLines) {
    $candidateSerial = ($line.Line -split '\s+')[0]
    $runningName = (& $adb -s $candidateSerial emu avd name 2>$null | Select-Object -First 1).Trim()
    if ($runningName -eq $AvdName) {
      return $candidateSerial
    }
  }
  return ""
}

function Get-BootCompleted {
  param([string]$Serial)
  $previousPreference = $ErrorActionPreference
  $ErrorActionPreference = "SilentlyContinue"
  $output = (& $adb -s $Serial shell getprop sys.boot_completed 2>$null) -join ""
  $ErrorActionPreference = $previousPreference
  return $output.Trim()
}

function Set-IniValue {
  param([string[]]$Lines, [string]$Key, [string]$Value)
  $escapedKey = [regex]::Escape($Key)
  $replacement = "$Key=$Value"
  $found = $false
  $result = foreach ($line in $Lines) {
    if ($line -match "^\s*$escapedKey\s*=") {
      $found = $true
      $replacement
    } else {
      $line
    }
  }
  if (-not $found) {
    $result += $replacement
  }
  return [string[]]$result
}

$exists = (Test-Path -LiteralPath $configPath) -and (Test-Path -LiteralPath $avdPointer)
if (-not $exists -and $Mode -eq "Verify") {
  throw "AVD $AvdName does not exist. Run this script with -Mode Ensure."
}
if (-not $exists) {
  New-Item -ItemType Directory -Path $avdRoot -Force | Out-Null
  "no" | & $avdManager create avd --name $AvdName --package "system-images;android-36;google_apis_playstore;x86_64" --device "medium_phone"
  if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $configPath)) {
    throw "avdmanager failed to create $AvdName."
  }
}

$expected = [ordered]@{
  "AvdId" = $AvdName
  "PlayStore.enabled" = "true"
  "abi.type" = "x86_64"
  "avd.ini.displayname" = "Geometory Galaxy S24 API 36"
  "disk.dataPartition.size" = "6G"
  "fastboot.forceColdBoot" = "yes"
  "fastboot.forceFastBoot" = "no"
  "hw.cpu.arch" = "x86_64"
  "hw.cpu.ncore" = "4"
  "hw.device.manufacturer" = "Generic"
  "hw.device.name" = "medium_phone"
  "hw.gpu.enabled" = "yes"
  "hw.gpu.mode" = "auto"
  "hw.initialOrientation" = "portrait"
  "hw.keyboard" = "yes"
  "hw.lcd.density" = "420"
  "hw.lcd.height" = "2340"
  "hw.lcd.width" = "1080"
  "hw.mainKeys" = "no"
  "hw.ramSize" = "4096"
  "image.sysdir.1" = "system-images\android-36\google_apis_playstore\x86_64\"
  "showDeviceFrame" = "no"
  "skin.name" = "1080x2340"
  "skin.path" = "1080x2340"
  "tag.display" = "Google Play"
  "tag.id" = "google_apis_playstore"
  "target" = "android-36"
  "vm.heapSize" = "384"
}

$lines = [string[]](Get-Content -LiteralPath $configPath)
$mismatches = @()
foreach ($entry in $expected.GetEnumerator()) {
  $actualLine = $lines | Where-Object { $_ -match ("^\s*" + [regex]::Escape($entry.Key) + "\s*=") } | Select-Object -First 1
  $actual = if ($actualLine) { ($actualLine -split '=', 2)[1].Trim() } else { "<missing>" }
  if ($actual -ne $entry.Value) {
    $mismatches += "$($entry.Key): expected '$($entry.Value)', received '$actual'"
  }
}
if ($mismatches.Count -gt 0 -and $Mode -eq "Verify") {
  throw "AVD configuration mismatch:`n$($mismatches -join "`n")"
}
if ($mismatches.Count -gt 0) {
  $runningSerial = Get-RunningAvdSerial
  if ($runningSerial) {
    throw "Refusing to edit AVD configuration while $AvdName is running as $runningSerial. Stop it and retry."
  }
  foreach ($entry in $expected.GetEnumerator()) {
    $lines = Set-IniValue -Lines $lines -Key $entry.Key -Value $entry.Value
  }
  [System.IO.File]::WriteAllLines($configPath, $lines, [System.Text.UTF8Encoding]::new($false))
}

if ($Launch) {
  $runningSerial = Get-RunningAvdSerial
  if (-not $runningSerial) {
    Start-Process -FilePath $emulator -ArgumentList @("-avd", $AvdName, "-no-boot-anim", "-no-snapshot-load", "-gpu", "auto", "-no-audio") -WindowStyle Hidden | Out-Null
    $deadline = (Get-Date).AddSeconds($BootTimeoutSeconds)
    while ((Get-Date) -lt $deadline -and -not $runningSerial) {
      Start-Sleep -Seconds 2
      $runningSerial = Get-RunningAvdSerial
    }
    if (-not $runningSerial) {
      throw "Timed out waiting for $AvdName to appear in ADB."
    }
  }
  $deadline = (Get-Date).AddSeconds($BootTimeoutSeconds)
  while ((Get-Date) -lt $deadline) {
    if ((Get-BootCompleted -Serial $runningSerial) -eq "1") {
      break
    }
    Start-Sleep -Seconds 2
  }
  if ((Get-BootCompleted -Serial $runningSerial) -ne "1") {
    throw "Timed out waiting for $AvdName to finish booting."
  }
  & $adb -s $runningSerial shell wm size 1080x2340 | Out-Null
  & $adb -s $runningSerial shell wm density 420 | Out-Null
  & $adb -s $runningSerial shell settings put system font_scale 1.0 | Out-Null
  & $adb -s $runningSerial shell settings put secure navigation_mode 0 | Out-Null
  & $adb -s $runningSerial shell cmd overlay enable-exclusive --category com.android.internal.systemui.navbar.threebutton 2>$null | Out-Null
  Write-Host "Running $AvdName as $runningSerial"
}

Write-Host "Verified AVD $AvdName"
Write-Host "  1080x2340, 420 dpi, API 36 Google Play x86_64, 4 cores, 4096 MB RAM"
Write-Host "  Emulator cutout shape and Samsung haptics are not authoritative; use the physical S24 for final certification."
