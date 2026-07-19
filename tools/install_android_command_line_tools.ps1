param(
  [string]$SdkRoot = "",
  [switch]$AcceptLicense
)

$ErrorActionPreference = "Stop"
$packageRevision = "20.0"
$archiveUrl = "https://dl.google.com/android/repository/commandlinetools-win-14742923_latest.zip"
$archiveSha256 = "cc610ccbe83faddb58e1aa68e8fc8743bb30aa5e83577eceb4cc168dae95f9ee"

if (-not $SdkRoot) {
  $SdkRoot = if ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } elseif ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { Join-Path $env:LOCALAPPDATA "Android\Sdk" }
}
$SdkRoot = [System.IO.Path]::GetFullPath($SdkRoot).TrimEnd("\")
$latest = Join-Path $SdkRoot "cmdline-tools\latest"
$sourceProperties = Join-Path $latest "source.properties"
if (Test-Path -LiteralPath $sourceProperties) {
  $revisionLine = Get-Content -LiteralPath $sourceProperties | Where-Object { $_ -like "Pkg.Revision=*" } | Select-Object -First 1
  if ($revisionLine -eq "Pkg.Revision=$packageRevision") {
    Write-Host "Android SDK command-line tools $packageRevision already installed at $latest"
    exit 0
  }
  throw "A different command-line tools package already owns $latest. Update it through Android Studio rather than overwriting it."
}
if (-not $AcceptLicense) {
  throw "Pass -AcceptLicense after reviewing the Android SDK license at https://developer.android.com/studio."
}

$archive = Join-Path $env:TEMP "commandlinetools-win-14742923_latest.zip"
if (-not (Test-Path -LiteralPath $archive)) {
  Invoke-WebRequest -UseBasicParsing -Uri $archiveUrl -OutFile $archive
}
$actualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $archive).Hash.ToLowerInvariant()
if ($actualHash -ne $archiveSha256) {
  throw "Command-line tools archive hash mismatch. Expected $archiveSha256, received $actualHash."
}

$cmdlineParent = Join-Path $SdkRoot "cmdline-tools"
$staged = Join-Path $cmdlineParent "cmdline-tools"
foreach ($candidate in @($cmdlineParent, $staged, $latest)) {
  $resolved = [System.IO.Path]::GetFullPath($candidate).TrimEnd("\")
  if (-not $resolved.StartsWith($SdkRoot + "\", [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Resolved command-line tools path escaped the Android SDK root: $resolved"
  }
}
if (Test-Path -LiteralPath $staged) {
  throw "Staging path already exists; inspect it before retrying: $staged"
}
New-Item -ItemType Directory -Path $cmdlineParent -Force | Out-Null
Expand-Archive -LiteralPath $archive -DestinationPath $cmdlineParent
Move-Item -LiteralPath $staged -Destination $latest
Write-Host "Installed Android SDK command-line tools $packageRevision at $latest"
