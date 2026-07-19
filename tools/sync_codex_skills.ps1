param(
  [ValidateSet("Check", "Apply")]
  [string]$Mode = "Check",
  [string]$DestinationRoot = "",
  [string]$PythonPath = "python"
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$sourceRoot = Join-Path $repoRoot "codex\skills"
$manifestPath = Join-Path $sourceRoot "manifest.json"

if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
  throw "Managed-skill manifest not found: $manifestPath"
}

if (-not $DestinationRoot) {
  $configuredCodexRoot = [Environment]::GetEnvironmentVariable("CODEX_HOME")
  if ($configuredCodexRoot) {
    $DestinationRoot = Join-Path $configuredCodexRoot "skills"
  } else {
    $profileRoot = [Environment]::GetFolderPath("UserProfile")
    $DestinationRoot = Join-Path $profileRoot ".codex\skills"
  }
}

$sourceRoot = [System.IO.Path]::GetFullPath($sourceRoot)
$DestinationRoot = [System.IO.Path]::GetFullPath($DestinationRoot)
$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
if ([int]$manifest.schema_version -ne 1) {
  throw "Unsupported managed-skill manifest schema: $($manifest.schema_version)"
}

$validatorRoot = [Environment]::GetEnvironmentVariable("CODEX_HOME")
if (-not $validatorRoot) {
  $validatorRoot = Join-Path ([Environment]::GetFolderPath("UserProfile")) ".codex"
}
$validatorPath = Join-Path $validatorRoot "skills\.system\skill-creator\scripts\quick_validate.py"
if (-not (Test-Path -LiteralPath $validatorPath -PathType Leaf)) {
  throw "Skill validator not found: $validatorPath"
}

function Assert-ManagedName {
  param([string]$Name)
  if ($Name -notmatch '^[a-z0-9-]+$') {
    throw "Unsafe managed skill name: $Name"
  }
}

function Get-Inventory {
  param([string]$Root)
  if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
    return @()
  }
  $resolvedRoot = [System.IO.Path]::GetFullPath($Root).TrimEnd('\', '/')
  return @(
    Get-ChildItem -LiteralPath $resolvedRoot -Recurse -File |
      ForEach-Object {
        [pscustomobject]@{
          path = $_.FullName.Substring($resolvedRoot.Length).TrimStart('\', '/').Replace('\', '/')
          sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        }
      } |
      Sort-Object path
  )
}

function Test-SameInventory {
  param([string]$Left, [string]$Right)
  $leftJson = (Get-Inventory $Left | ConvertTo-Json -Compress)
  $rightJson = (Get-Inventory $Right | ConvertTo-Json -Compress)
  return $leftJson -eq $rightJson
}

function Assert-DirectChild {
  param([string]$ChildPath)
  $fullChild = [System.IO.Path]::GetFullPath($ChildPath)
  $parent = [System.IO.Path]::GetFullPath((Split-Path -Parent $fullChild)).TrimEnd('\', '/')
  $expected = $DestinationRoot.TrimEnd('\', '/')
  if ($parent -ne $expected) {
    throw "Refusing to manage a path outside the direct skill root: $fullChild"
  }
}

$validationFailed = $false
foreach ($skillNameValue in $manifest.managed_skills) {
  $skillName = [string]$skillNameValue
  Assert-ManagedName $skillName
  $sourcePath = Join-Path $sourceRoot $skillName
  if (-not (Test-Path -LiteralPath $sourcePath -PathType Container)) {
    Write-Error "Canonical skill missing: $sourcePath"
    $validationFailed = $true
    continue
  }
  & $PythonPath $validatorPath $sourcePath
  if ($LASTEXITCODE -ne 0) {
    Write-Error "Canonical skill failed validation: $skillName"
    $validationFailed = $true
  }
}
if ($validationFailed) {
  exit 2
}

if ($Mode -eq "Apply") {
  New-Item -ItemType Directory -Force -Path $DestinationRoot | Out-Null
  $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
  $backupRoot = Join-Path $DestinationRoot ".geometory-backups\$stamp"
  $stageRoot = Join-Path $DestinationRoot (".geometory-staging-" + [guid]::NewGuid().ToString("N"))
  New-Item -ItemType Directory -Force -Path $stageRoot | Out-Null

  try {
    foreach ($skillNameValue in $manifest.managed_skills) {
      $skillName = [string]$skillNameValue
      $sourcePath = Join-Path $sourceRoot $skillName
      $destinationPath = Join-Path $DestinationRoot $skillName
      Assert-DirectChild $destinationPath

      if ((Test-Path -LiteralPath $destinationPath) -and (Test-SameInventory $sourcePath $destinationPath)) {
        Write-Host "Skill already current: $skillName"
        continue
      }

      $stagedSkill = Join-Path $stageRoot $skillName
      Copy-Item -LiteralPath $sourcePath -Destination $stagedSkill -Recurse
      if (-not (Test-SameInventory $sourcePath $stagedSkill)) {
        throw "Staged skill verification failed: $skillName"
      }

      if (Test-Path -LiteralPath $destinationPath) {
        New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null
        $backupPath = Join-Path $backupRoot $skillName
        Move-Item -LiteralPath $destinationPath -Destination $backupPath
        Write-Host "Backed up previous installed skill: $backupPath"
      }

      Move-Item -LiteralPath $stagedSkill -Destination $destinationPath
      Write-Host "Installed managed skill: $skillName"
    }
  } finally {
    if (Test-Path -LiteralPath $stageRoot) {
      $stageFull = [System.IO.Path]::GetFullPath($stageRoot)
      $destinationPrefix = $DestinationRoot.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
      if (-not $stageFull.StartsWith($destinationPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to remove unexpected staging path: $stageFull"
      }
      Remove-Item -LiteralPath $stageFull -Recurse -Force
    }
  }
}

$drifted = @()
foreach ($skillNameValue in $manifest.managed_skills) {
  $skillName = [string]$skillNameValue
  $sourcePath = Join-Path $sourceRoot $skillName
  $destinationPath = Join-Path $DestinationRoot $skillName
  Assert-DirectChild $destinationPath
  if (-not (Test-Path -LiteralPath $destinationPath -PathType Container)) {
    $drifted += "$skillName (missing)"
  } elseif (-not (Test-SameInventory $sourcePath $destinationPath)) {
    $drifted += "$skillName (content drift)"
  }
}

if ($drifted.Count -gt 0) {
  Write-Error ("Managed skill drift: " + ($drifted -join ", "))
  exit 1
}

Write-Host "Managed skills are synchronized: $DestinationRoot"
exit 0
