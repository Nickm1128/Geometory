$ErrorActionPreference = "Stop"
$checker = Join-Path $PSScriptRoot "check_work_state.ps1"
$hostExecutable = (Get-Process -Id $PID).Path
$requestedPhase = "M1-P00"

$previousPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
$output = @(& $hostExecutable -NoProfile -ExecutionPolicy Bypass -File $checker -Mode PhaseClose -PhaseId $requestedPhase 2>&1)
$childExitCode = $LASTEXITCODE
$ErrorActionPreference = $previousPreference
$text = $output -join "`n"

foreach ($foreignPhase in @("M1-P01", "M1-P02", "M1-P03", "M1-P04", "M1-P05", "M1-P06")) {
  if ($text -match ([regex]::Escape($foreignPhase) + " cannot close")) {
    throw "PhaseClose routing regression: requested $requestedPhase but validated $foreignPhase."
  }
}

if ($childExitCode -eq 0) {
  Write-Host "PASS: PhaseClose accepted the requested completed phase $requestedPhase."
  exit 0
}

if ($text -notmatch ([regex]::Escape($requestedPhase) + " cannot close")) {
  throw "PhaseClose failed without reporting the requested phase $requestedPhase.`n$text"
}

Write-Host "PASS: PhaseClose failure diagnostics target the requested phase $requestedPhase."
exit 0
