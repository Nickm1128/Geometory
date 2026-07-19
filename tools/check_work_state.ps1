param(
  [ValidateSet("Resume", "TaskClose", "PhaseClose", "Audit")]
  [string]$Mode = "Resume",
  [string]$TaskId = "",
  [string]$PhaseId = "",
  [switch]$SkipSkillMirror
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$workRoot = Join-Path $repoRoot "docs/open_work"
$indexPath = Join-Path $workRoot "INDEX.md"
$errors = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()
$allTasks = @{}
$allGates = @{}
$allRequirements = @{}
$phaseRecords = @{}

function Add-Error([string]$Message) {
  $script:errors.Add($Message)
}

function Add-Warning([string]$Message) {
  $script:warnings.Add($Message)
}

function Read-Text([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    Add-Error "Missing required file: $Path"
    return ""
  }
  return Get-Content -LiteralPath $Path -Raw
}

function Is-PendingEvidence([string]$Evidence) {
  return $Evidence.Trim() -match '^(Pending|None|TBD)\.?$'
}

function Get-IndexFrontmatter([string]$Text) {
  $values = @{}
  $match = [regex]::Match($Text, '(?s)\A---\r?\n(?<body>.*?)\r?\n---\r?\n')
  if (-not $match.Success) {
    Add-Error "INDEX.md must begin with YAML frontmatter."
    return $values
  }
  foreach ($line in ($match.Groups['body'].Value -split '\r?\n')) {
    if ($line -match '^(?<key>[a-z_]+):\s*(?<value>.*)$') {
      $value = $Matches['value'].Trim()
      if ($value.StartsWith('"') -and $value.EndsWith('"')) {
        $value = $value.Substring(1, $value.Length - 2)
      }
      $values[$Matches['key']] = $value
    } elseif ($line.Trim()) {
      Add-Error "INDEX.md contains unsupported frontmatter syntax: $line"
    }
  }
  return $values
}

function Get-RelativeDataFiles([string]$Root) {
  $result = @{}
  if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
    Add-Error "Missing data directory: $Root"
    return $result
  }
  foreach ($file in Get-ChildItem -LiteralPath $Root -File -Recurse) {
    $relative = $file.FullName.Substring($Root.Length).TrimStart('\', '/') -replace '\\', '/'
    $result[$relative] = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
  }
  return $result
}

$expectedRootFiles = @(
  "AGENTS.md",
  "docs/README.md",
  "docs/open_work/INDEX.md",
  "docs/open_work/MILESTONE_1_PLAN.md",
  "docs/open_work/BLOCKERS.md",
  "docs/open_work/RUN_LOG.md",
  "docs/open_work/AUTONOMOUS_RUN.md",
  "docs/open_work/hygiene/CHECKLIST.md",
  "docs/open_work/hygiene/LOG.md"
)
foreach ($relative in $expectedRootFiles) {
  $path = Join-Path $repoRoot $relative
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    Add-Error "Missing required operating file: $relative"
  }
}

$expectedPhases = [ordered]@{
  "M1-P00" = "phase_00_workflow_baseline"
  "M1-P01" = "phase_01_core_contracts"
  "M1-P02" = "phase_02_replay_simulation"
  "M1-P03" = "phase_03_baseline_bot"
  "M1-P04" = "phase_04_ai_bot_loop"
  "M1-P05" = "phase_05_ux_aesthetics"
  "M1-P06" = "phase_06_certification_closeout"
}
$requiredPhaseFiles = @("REQUIREMENTS.md", "TASKS.md", "EXIT_GATES.md", "NOTES.md")
$milestoneRoot = Join-Path $workRoot "milestone_1"

foreach ($entry in $expectedPhases.GetEnumerator()) {
  $phaseId = $entry.Key
  $phaseDir = Join-Path $milestoneRoot $entry.Value
  if (-not (Test-Path -LiteralPath $phaseDir -PathType Container)) {
    Add-Error "Missing phase directory: $($entry.Value)"
    continue
  }
  $actualNames = @(Get-ChildItem -LiteralPath $phaseDir -File | Select-Object -ExpandProperty Name)
  foreach ($requiredName in $requiredPhaseFiles) {
    if ($requiredName -notin $actualNames) {
      Add-Error "$phaseId is missing $requiredName."
    }
  }
  foreach ($actualName in $actualNames) {
    if ($actualName -notin $requiredPhaseFiles) {
      Add-Error "$phaseId contains unexpected phase file $actualName; phase directories must contain exactly four files."
    }
  }

  $requirementsText = Read-Text (Join-Path $phaseDir "REQUIREMENTS.md")
  $tasksText = Read-Text (Join-Path $phaseDir "TASKS.md")
  $gatesText = Read-Text (Join-Path $phaseDir "EXIT_GATES.md")
  [void](Read-Text (Join-Path $phaseDir "NOTES.md"))

  $requirementMatches = [regex]::Matches($requirementsText, '(?m)^- `(?<id>M1-P\d{2}-R\d{2})`\s+')
  $requirementIdLines = [regex]::Matches($requirementsText, '(?m)^- `M1-P\d{2}-R\d{2}`')
  if ($requirementMatches.Count -eq 0) {
    Add-Error "$phaseId has no requirement IDs."
  }
  if ($requirementMatches.Count -ne $requirementIdLines.Count) {
    Add-Error "$phaseId contains an unparseable requirement entry."
  }
  $requirementIds = @{}
  foreach ($match in $requirementMatches) {
    $id = $match.Groups['id'].Value
    if (-not $id.StartsWith($phaseId + "-")) { Add-Error "$id is in the wrong phase directory." }
    if ($requirementIds.ContainsKey($id)) { Add-Error "Duplicate requirement ID: $id" }
    $requirementIds[$id] = $true
    if ($allRequirements.ContainsKey($id)) { Add-Error "Duplicate requirement ID across phases: $id" }
    $allRequirements[$id] = $true
  }

  $taskPattern = '(?ms)^- \[(?<check>[ xX])\] `(?<id>M1-P\d{2}-T\d{2})` (?<title>[^\r\n]+)\r?\n  - Dependencies: (?<deps>[^\r\n]+)\r?\n  - Can run early: (?<early>Yes|No)\r?\n  - Definition of done: (?<done>[^\r\n]+)\r?\n  - Evidence: (?<evidence>[^\r\n]+)'
  $taskMatches = [regex]::Matches($tasksText, $taskPattern)
  $taskCheckboxLines = [regex]::Matches($tasksText, '(?m)^- \[[ xX]\] `M1-P\d{2}-T\d{2}`')
  if ($taskMatches.Count -eq 0) { Add-Error "$phaseId has no parseable tasks." }
  if ($taskMatches.Count -ne $taskCheckboxLines.Count) { Add-Error "$phaseId contains an unparseable task entry." }
  foreach ($match in $taskMatches) {
    $id = $match.Groups['id'].Value
    if (-not $id.StartsWith($phaseId + "-")) { Add-Error "$id is in the wrong phase directory." }
    if ($allTasks.ContainsKey($id)) {
      Add-Error "Duplicate task ID: $id"
      continue
    }
    $allTasks[$id] = [pscustomobject]@{
      Id = $id
      Phase = $phaseId
      Checked = $match.Groups['check'].Value -match '[xX]'
      Dependencies = $match.Groups['deps'].Value.Trim()
      CanRunEarly = $match.Groups['early'].Value -eq "Yes"
      Evidence = $match.Groups['evidence'].Value.Trim()
    }
  }

  $gatePattern = '(?ms)^- \[(?<check>[ xX])\] `(?<id>M1-P\d{2}-G\d{2})` (?<title>[^\r\n]+)\r?\n  - Evidence: (?<evidence>[^\r\n]+)'
  $gateMatches = [regex]::Matches($gatesText, $gatePattern)
  $gateCheckboxLines = [regex]::Matches($gatesText, '(?m)^- \[[ xX]\] `M1-P\d{2}-G\d{2}`')
  if ($gateMatches.Count -eq 0) { Add-Error "$phaseId has no parseable exit gates." }
  if ($gateMatches.Count -ne $gateCheckboxLines.Count) { Add-Error "$phaseId contains an unparseable exit-gate entry." }
  foreach ($match in $gateMatches) {
    $id = $match.Groups['id'].Value
    if (-not $id.StartsWith($phaseId + "-")) { Add-Error "$id is in the wrong phase directory." }
    if ($allGates.ContainsKey($id)) {
      Add-Error "Duplicate gate ID: $id"
      continue
    }
    $allGates[$id] = [pscustomobject]@{
      Id = $id
      Phase = $phaseId
      Checked = $match.Groups['check'].Value -match '[xX]'
      Evidence = $match.Groups['evidence'].Value.Trim()
    }
  }
  $phaseRecords[$phaseId] = [pscustomobject]@{
    Id = $phaseId
    Directory = $phaseDir
  }
}

foreach ($task in $allTasks.Values) {
  if ($task.Checked -and (Is-PendingEvidence $task.Evidence)) {
    Add-Error "$($task.Id) is checked but has pending evidence."
  }
  if ($task.Dependencies -ne "None") {
    foreach ($dependency in ($task.Dependencies -split ',' | ForEach-Object { $_.Trim() })) {
      $target = if ($allTasks.ContainsKey($dependency)) { $allTasks[$dependency] } elseif ($allGates.ContainsKey($dependency)) { $allGates[$dependency] } else { $null }
      if ($null -eq $target) {
        Add-Error "$($task.Id) references unknown dependency $dependency."
      } elseif ($task.Checked -and -not $target.Checked) {
        Add-Error "$($task.Id) is checked before dependency $dependency."
      }
    }
  }
}

# A task-only dependency cycle can never become executable. Gate dependencies
# are phase boundaries and are validated independently at phase close.
$visitState = @{}
function Visit-TaskDependency([string]$TaskId, [System.Collections.Generic.List[string]]$Path) {
  if ($visitState[$TaskId] -eq 2) { return }
  if ($visitState[$TaskId] -eq 1) {
    Add-Error ("Task dependency cycle: " + (($Path + $TaskId) -join " -> "))
    return
  }
  $visitState[$TaskId] = 1
  $nextPath = [System.Collections.Generic.List[string]]::new()
  foreach ($item in $Path) { $nextPath.Add($item) }
  $nextPath.Add($TaskId)
  $task = $allTasks[$TaskId]
  if ($task.Dependencies -ne "None") {
    foreach ($dependency in ($task.Dependencies -split ',' | ForEach-Object { $_.Trim() })) {
      if ($allTasks.ContainsKey($dependency)) { Visit-TaskDependency $dependency $nextPath }
    }
  }
  $visitState[$TaskId] = 2
}
foreach ($taskIdKey in $allTasks.Keys) {
  if (-not $visitState.ContainsKey($taskIdKey)) {
    Visit-TaskDependency $taskIdKey ([System.Collections.Generic.List[string]]::new())
  }
}
foreach ($gate in $allGates.Values) {
  if ($gate.Checked -and (Is-PendingEvidence $gate.Evidence)) {
    Add-Error "$($gate.Id) is checked but has pending evidence."
  }
}

$indexText = Read-Text $indexPath
$indexValues = Get-IndexFrontmatter $indexText
$requiredIndexKeys = @("schema_version", "milestone", "workflow_state", "active_phase", "current_task", "run_id", "exact_next_action", "last_completed_phase_tag", "last_checkpoint_ref", "last_green_validation")
foreach ($key in $requiredIndexKeys) {
  if (-not $indexValues.ContainsKey($key)) { Add-Error "INDEX.md frontmatter is missing $key." }
}
if ($indexValues['schema_version'] -ne '1') { Add-Error "INDEX.md schema_version must be 1." }
if ($indexValues['milestone'] -ne 'M1') { Add-Error "INDEX.md milestone must be M1." }
if ($indexValues['workflow_state'] -notin @('active', 'blocked', 'complete')) { Add-Error "Unsupported workflow_state in INDEX.md." }
if (-not $indexValues['run_id'] -or $indexValues['run_id'] -notmatch '^M1-RUN-\d{8}-\d{3}$') { Add-Error "INDEX.md run_id must match M1-RUN-YYYYMMDD-NNN." }
if (-not $indexValues['exact_next_action']) { Add-Error "INDEX.md exact_next_action must not be empty." }

$phaseStatusMatches = [regex]::Matches($indexText, '(?m)^\| `(?<id>M1-P\d{2})` \| (?<state>Planned|Ready|Active|Gate Review|Hygiene|Complete|Deferred) \|')
$phaseStatus = @{}
foreach ($match in $phaseStatusMatches) {
  $id = $match.Groups['id'].Value
  if ($phaseStatus.ContainsKey($id)) { Add-Error "INDEX.md repeats phase row $id." }
  $phaseStatus[$id] = $match.Groups['state'].Value
}
foreach ($phaseIdKey in $expectedPhases.Keys) {
  if (-not $phaseStatus.ContainsKey($phaseIdKey)) { Add-Error "INDEX.md is missing phase row $phaseIdKey." }
}
$livePhases = @($phaseStatus.GetEnumerator() | Where-Object { $_.Value -in @('Active', 'Gate Review', 'Hygiene') })
if ($livePhases.Count -gt 1) { Add-Error "Only one phase may be Active, Gate Review, or Hygiene." }
if ($indexValues['workflow_state'] -eq 'active' -and $livePhases.Count -ne 1) { Add-Error "An active workflow must have exactly one live phase row." }
if ($livePhases.Count -eq 1 -and $indexValues['active_phase'] -ne $livePhases[0].Key) { Add-Error "INDEX.md active_phase does not match its live phase row." }
if ($indexValues['active_phase'] -and -not $expectedPhases.Contains($indexValues['active_phase'])) { Add-Error "INDEX.md active_phase is unknown." }

$currentTaskId = $indexValues['current_task']
if ($indexValues['workflow_state'] -eq 'active') {
  if (-not $allTasks.ContainsKey($currentTaskId)) {
    Add-Error "INDEX.md current_task is missing or unknown: $currentTaskId"
  } else {
    $currentTask = $allTasks[$currentTaskId]
    if ($currentTask.Checked) { Add-Error "INDEX.md current_task $currentTaskId is already checked." }
    if ($currentTask.Dependencies -ne "None") {
      foreach ($dependency in ($currentTask.Dependencies -split ',' | ForEach-Object { $_.Trim() })) {
        $target = if ($allTasks.ContainsKey($dependency)) { $allTasks[$dependency] } elseif ($allGates.ContainsKey($dependency)) { $allGates[$dependency] } else { $null }
        if ($null -ne $target -and -not $target.Checked) { Add-Error "Current task $currentTaskId has incomplete dependency $dependency." }
      }
    }
    if ($currentTask.Phase -ne $indexValues['active_phase']) {
      if (-not $currentTask.CanRunEarly) {
        Add-Error "$currentTaskId is outside active phase and is not marked Can run early: Yes."
      }
      if ($currentTask.Dependencies -ne "None") {
        foreach ($dependency in ($currentTask.Dependencies -split ',' | ForEach-Object { $_.Trim() })) {
          $target = if ($allTasks.ContainsKey($dependency)) { $allTasks[$dependency] } elseif ($allGates.ContainsKey($dependency)) { $allGates[$dependency] } else { $null }
          if ($null -eq $target -or -not $target.Checked) { Add-Error "Early current task $currentTaskId has incomplete dependency $dependency." }
        }
      }
    }
  }
}

$blockerText = Read-Text (Join-Path $workRoot "BLOCKERS.md")
$liveBlockerText = ($blockerText -split '(?m)^## Entry Template')[0]
$blockerPattern = '(?ms)^### (?<id>B-\d{3})\s+—\s+(?<title>[^\r\n]+)\r?\n\r?\n- Status: (?<status>Open|Resolved)\r?\n- Owner: (?<owner>User|Environment|Implementation|External)\r?\n- Opened: (?<opened>[^\r\n]+)\r?\n- Resolved: (?<resolved>[^\r\n]+)\r?\n- Affected IDs: (?<affected>[^\r\n]+)\r?\n- Exact question or failure: (?<question>[^\r\n]+)\r?\n- Safe fallback: (?<fallback>[^\r\n]+)\r?\n- Fallback authority: (?<authority>[^\r\n]+)\r?\n- Eligible parallel work: (?<parallel>[^\r\n]+)\r?\n- Evidence: (?<evidence>[^\r\n]+)\r?\n- Resolution: (?<resolution>[^\r\n]+)'
$blockerMatches = [regex]::Matches($liveBlockerText, $blockerPattern)
$blockerHeadingMatches = [regex]::Matches($liveBlockerText, '(?m)^### (?<id>B-\d{3})\b')
if ($blockerMatches.Count -ne $blockerHeadingMatches.Count) { Add-Error "BLOCKERS.md contains an unparseable blocker entry." }
$blockerIds = @{}
$openBlockerCount = 0
foreach ($match in $blockerMatches) {
  $id = $match.Groups['id'].Value
  if ($blockerIds.ContainsKey($id)) { Add-Error "Duplicate blocker ID: $id" }
  $blockerIds[$id] = $true
  $status = $match.Groups['status'].Value
  if ($status -eq 'Open') { $openBlockerCount++ }
  $affectedRaw = $match.Groups['affected'].Value
  $affectedIds = [regex]::Matches($affectedRaw, '(M1-P\d{2}-(?:T|G|R)\d{2})') | ForEach-Object { $_.Groups[1].Value }
  if (@($affectedIds).Count -eq 0) { Add-Error "$id must name at least one affected requirement, task, or gate ID." }
  foreach ($affectedId in $affectedIds) {
    $known = $allTasks.ContainsKey($affectedId) -or $allGates.ContainsKey($affectedId) -or $allRequirements.ContainsKey($affectedId)
    if (-not $known) { Add-Error "$id references unknown affected ID $affectedId." }
    if ($status -eq 'Open' -and $allTasks.ContainsKey($affectedId) -and $allTasks[$affectedId].Checked) {
      Add-Error "$id is open but affected task $affectedId is checked."
    }
  }
  if ($status -eq 'Open') {
    if ($match.Groups['resolved'].Value -notmatch '^Pending\.?$') { Add-Error "$id is open but has a resolved date." }
    if ($match.Groups['resolution'].Value -notmatch '^Pending\.?$') { Add-Error "$id is open but has a resolution." }
  } else {
    if ($match.Groups['resolved'].Value -match '^Pending\.?$') { Add-Error "$id is resolved without a resolved date." }
    if ($match.Groups['resolution'].Value -match '^Pending\.?$') { Add-Error "$id is resolved without resolution evidence." }
  }
}
if ($indexValues['workflow_state'] -eq 'blocked' -and $openBlockerCount -eq 0) { Add-Error "Workflow is blocked but no open blocker entry exists." }

$rootData = Get-RelativeDataFiles (Join-Path $repoRoot "data")
$runtimeData = Get-RelativeDataFiles (Join-Path $repoRoot "godot/data")
foreach ($relative in $rootData.Keys) {
  if (-not $runtimeData.ContainsKey($relative)) {
    Add-Error "Godot runtime data is missing $relative."
  } elseif ($runtimeData[$relative] -ne $rootData[$relative]) {
    Add-Error "Root/Godot data differs: $relative"
  }
}
foreach ($relative in $runtimeData.Keys) {
  if ($relative -ne 'README.md' -and -not $rootData.ContainsKey($relative)) {
    Add-Error "Godot runtime data has unexpected file: $relative"
  }
}

$manifestPath = Join-Path $repoRoot "codex/skills/manifest.json"
if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
  try {
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    if ($manifest.schema_version -ne 1) { Add-Error "Skill manifest schema_version must be 1." }
    $skillNames = @($manifest.managed_skills)
    if ($skillNames.Count -ne 5 -or @($skillNames | Select-Object -Unique).Count -ne 5) { Add-Error "Skill manifest must list five unique managed skills." }
    foreach ($skillName in $skillNames) {
      $packageRoot = Join-Path (Join-Path $repoRoot "codex/skills") $skillName
      foreach ($requiredSkillFile in @("SKILL.md", "agents/openai.yaml")) {
        if (-not (Test-Path -LiteralPath (Join-Path $packageRoot $requiredSkillFile) -PathType Leaf)) { Add-Error "Skill $skillName is missing $requiredSkillFile." }
      }
    }
    if (-not $SkipSkillMirror) {
      $skillTaskComplete = $allTasks.ContainsKey('M1-P00-T03') -and $allTasks['M1-P00-T03'].Checked
      $destinationRoot = if ($env:CODEX_HOME) { Join-Path $env:CODEX_HOME 'skills' } else { Join-Path $env:USERPROFILE '.codex/skills' }
      foreach ($skillName in $skillNames) {
        $sourceRoot = Join-Path (Join-Path $repoRoot "codex/skills") $skillName
        $destination = Join-Path $destinationRoot $skillName
        if (-not (Test-Path -LiteralPath $destination -PathType Container)) {
          if ($skillTaskComplete) { Add-Error "Managed skill mirror is missing: $skillName" } else { Add-Warning "Managed skill mirror is not yet installed: $skillName" }
          continue
        }
        $sourceFiles = Get-ChildItem -LiteralPath $sourceRoot -File -Recurse
        foreach ($sourceFile in $sourceFiles) {
          $relative = $sourceFile.FullName.Substring($sourceRoot.Length).TrimStart('\', '/')
          $destinationFile = Join-Path $destination $relative
          $same = (Test-Path -LiteralPath $destinationFile -PathType Leaf) -and ((Get-FileHash $sourceFile.FullName -Algorithm SHA256).Hash -eq (Get-FileHash $destinationFile -Algorithm SHA256).Hash)
          if (-not $same) {
            if ($skillTaskComplete) { Add-Error "Managed skill mirror differs: $skillName/$relative" } else { Add-Warning "Managed skill mirror pending sync: $skillName/$relative" }
          }
        }
        $destinationFiles = @(Get-ChildItem -LiteralPath $destination -File -Recurse)
        foreach ($destinationFile in $destinationFiles) {
          $relative = $destinationFile.FullName.Substring($destination.Length).TrimStart('\', '/')
          if (-not (Test-Path -LiteralPath (Join-Path $sourceRoot $relative) -PathType Leaf)) {
            if ($skillTaskComplete) { Add-Error "Managed skill mirror has unexpected file: $skillName/$relative" } else { Add-Warning "Managed skill mirror cleanup pending: $skillName/$relative" }
          }
        }
      }
    }
  } catch {
    Add-Error "Invalid skill manifest: $($_.Exception.Message)"
  }
} elseif ($allTasks.ContainsKey('M1-P00-T03') -and $allTasks['M1-P00-T03'].Checked) {
  Add-Error "M1-P00-T03 is checked but codex/skills/manifest.json is missing."
} else {
  Add-Warning "Canonical skill manifest is pending M1-P00-T03."
}

$tracked = @(& git -C $repoRoot ls-files)
if ($LASTEXITCODE -ne 0) { Add-Error "Unable to inspect tracked files with Git." }
foreach ($path in $tracked) {
  if ($path -match '(^|/)(artifacts|exports|reports/generated|replays/generated)/' -or $path -match '\.(apk|aab|keystore|jks)$' -or $path -match '(^|/)\.env($|\.)') {
    Add-Error "Generated or sensitive-looking file is tracked: $path"
  }
}

$branch = (& git -C $repoRoot branch --show-current).Trim()
if ($indexValues['workflow_state'] -ne 'complete' -and $branch -ne 'milestone/m1-vertical-slice') {
  Add-Warning "Expected milestone/m1-vertical-slice, found $branch."
}
$subjects = @(& git -C $repoRoot log --all --format=%s)
foreach ($subject in $subjects) {
  $ids = @([regex]::Matches($subject, 'M1-P\d{2}-T\d{2}') | ForEach-Object { $_.Value } | Select-Object -Unique)
  if ($ids.Count -gt 1) { Add-Error "Commit subject contains more than one task ID: $subject" }
  if ($ids.Count -eq 1 -and -not $allTasks.ContainsKey($ids[0])) { Add-Error "Commit subject contains unknown task ID $($ids[0]): $subject" }
}
foreach ($task in $allTasks.Values | Where-Object { $_.Checked -and $_.Id -ne 'M1-P00-T01' }) {
  if (-not ($subjects -match [regex]::Escape($task.Id))) {
    $message = "$($task.Id) is checked but no Git commit subject contains its ID."
    if ($Mode -eq 'PhaseClose') { Add-Error $message } else { Add-Warning $message }
  }
}
foreach ($phaseRow in $phaseStatus.GetEnumerator() | Where-Object { $_.Value -eq 'Complete' }) {
  $phaseNumber = $phaseRow.Key.Substring(5, 2)
  $tagPattern = "^m1-p$phaseNumber(?:-r\d+)?$"
  $tags = @(& git -C $repoRoot tag --list)
  $matchingTags = @($tags | Where-Object { $_ -match $tagPattern })
  if ($matchingTags.Count -eq 0) { Add-Error "$($phaseRow.Key) is Complete but no immutable phase tag matches $tagPattern." }
  foreach ($matchingTag in $matchingTags) {
    $tagType = (& git -C $repoRoot cat-file -t "refs/tags/$matchingTag" 2>$null).Trim()
    if ($tagType -ne 'tag') { Add-Error "Phase tag $matchingTag must be annotated, not lightweight." }
    & git -C $repoRoot merge-base --is-ancestor "$matchingTag^{}" HEAD 2>$null
    if ($LASTEXITCODE -ne 0) { Add-Error "Phase tag $matchingTag is not an ancestor of the current milestone branch." }
  }
  foreach ($task in $allTasks.Values | Where-Object Phase -eq $phaseRow.Key) { if (-not $task.Checked) { Add-Error "$($phaseRow.Key) is Complete with unchecked task $($task.Id)." } }
  foreach ($gate in $allGates.Values | Where-Object Phase -eq $phaseRow.Key) { if (-not $gate.Checked) { Add-Error "$($phaseRow.Key) is Complete with unchecked gate $($gate.Id)." } }
}

if ($Mode -eq 'TaskClose') {
  if (-not $TaskId) { Add-Error "TaskClose requires -TaskId." }
  elseif (-not $allTasks.ContainsKey($TaskId)) { Add-Error "Unknown TaskId: $TaskId" }
  else {
    $targetTask = $allTasks[$TaskId]
    if (-not $targetTask.Checked) { Add-Error "$TaskId must be checked before TaskClose passes." }
    if (Is-PendingEvidence $targetTask.Evidence) { Add-Error "$TaskId must have non-pending evidence." }
  }
}

if ($Mode -eq 'PhaseClose') {
  if (-not $PhaseId) { Add-Error "PhaseClose requires -PhaseId." }
  elseif (-not $expectedPhases.Contains($PhaseId)) { Add-Error "Unknown PhaseId: $PhaseId" }
  else {
    foreach ($task in $allTasks.Values | Where-Object Phase -eq $PhaseId) { if (-not $task.Checked) { Add-Error "$PhaseId cannot close with unchecked task $($task.Id)." } }
    foreach ($gate in $allGates.Values | Where-Object Phase -eq $PhaseId) { if (-not $gate.Checked) { Add-Error "$PhaseId cannot close with unchecked gate $($gate.Id)." } }
    $hygieneText = Read-Text (Join-Path $workRoot "hygiene/LOG.md")
    if ($hygieneText -notmatch "(?ms)^## .*?$([regex]::Escape($PhaseId)).*?^- Result: Pass\b") { Add-Error "$PhaseId has no passing hygiene log entry." }
  }
}

Write-Host "Geometory work-state check: $Mode"
Write-Host "Branch: $branch"
Write-Host "Workflow: $($indexValues['workflow_state']); phase: $($indexValues['active_phase']); task: $($indexValues['current_task'])"
Write-Host "Parsed: $($allTasks.Count) tasks, $($allGates.Count) gates, $($blockerMatches.Count) recorded blockers ($openBlockerCount open)"
foreach ($warning in $warnings) { Write-Warning $warning }
if ($errors.Count -gt 0) {
  foreach ($errorMessage in $errors) { Write-Error $errorMessage }
  exit 1
}
Write-Host "PASS with $($warnings.Count) warning(s)."
exit 0
