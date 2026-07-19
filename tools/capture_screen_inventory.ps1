param(
  [string]$OutputDir = "",
  [string]$AdbPath = "",
  [string]$PackageName = "com.milin.geometory",
  [switch]$Guided,
  [switch]$Launch
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
if (-not $OutputDir) {
  $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
  $OutputDir = Join-Path $repoRoot "artifacts\device\screen_inventory_$stamp"
}
if (-not $AdbPath) {
  $AdbPath = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
}
if (-not (Test-Path $AdbPath)) {
  throw "ADB not found at $AdbPath"
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

function Invoke-Adb {
  param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)
  & $AdbPath @Args
}

function Capture-Screen {
  param([string]$Name)
  $safeName = $Name -replace '[^a-zA-Z0-9_-]', '_'
  $remote = "/sdcard/geometory_$safeName.png"
  $local = Join-Path $OutputDir "$safeName.png"
  Invoke-Adb shell screencap -p $remote | Out-Null
  Invoke-Adb pull $remote $local | Out-Null
  Invoke-Adb shell rm $remote | Out-Null
  Write-Host "Captured $local"
}

function Wait-Step {
  param([string]$Instruction)
  if ($Guided) {
    Write-Host ""
    Write-Host $Instruction
    Read-Host "Press Enter to capture" | Out-Null
  } else {
    Start-Sleep -Milliseconds 900
  }
}

if ($Launch) {
  Invoke-Adb shell monkey -p $PackageName -c android.intent.category.LAUNCHER 1 | Out-Null
  Start-Sleep -Seconds 2
}

$steps = @(
  @{ Name = "01_main_menu"; Instruction = "Navigate to the Main Menu." },
  @{ Name = "02_quick_play_setup"; Instruction = "Open Quick Play setup." },
  @{ Name = "03_how_to_play_main"; Instruction = "Open How To Play from the main menu." },
  @{ Name = "04_settings_main"; Instruction = "Open Settings from the main menu." },
  @{ Name = "05_dev_tools"; Instruction = "Open Dev Tools from the main menu." },
  @{ Name = "06_match_allocation"; Instruction = "Start Quick Play and stop on Allocation." },
  @{ Name = "07_match_movement_initial"; Instruction = "Confirm Allocation and stop at initial Movement." },
  @{ Name = "08_match_movement_stack_selected"; Instruction = "Tap your starting soldier stack." },
  @{ Name = "09_match_movement_pending_confirm"; Instruction = "Tap a destination so Confirm Move is visible." },
  @{ Name = "10_match_unconfirmed_move_warning"; Instruction = "Tap End Turn with the pending move unconfirmed." },
  @{ Name = "11_pause_menu"; Instruction = "Dismiss warning if needed, then open Pause." },
  @{ Name = "12_pause_settings"; Instruction = "Open Settings from Pause." },
  @{ Name = "13_paths_off"; Instruction = "Return to Movement and toggle Paths Off." },
  @{ Name = "14_confirmed_path"; Instruction = "Toggle Paths On and confirm a movement path." }
)

foreach ($step in $steps) {
  Wait-Step $step.Instruction
  Capture-Screen $step.Name
}

Write-Host "Screenshot inventory saved to $OutputDir"