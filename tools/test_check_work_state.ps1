$ErrorActionPreference = "Stop"
$checker = Join-Path $PSScriptRoot "check_work_state.ps1"
$repoRoot = Split-Path -Parent $PSScriptRoot
$canonicalIndex = Join-Path $repoRoot "docs/open_work/INDEX.md"
$hostExecutable = (Get-Process -Id $PID).Path

function Invoke-Checker([string[]]$Arguments) {
  $previousPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  $output = @(& $hostExecutable -NoProfile -ExecutionPolicy Bypass -File $checker @Arguments 2>&1)
  $childExitCode = $LASTEXITCODE
  $ErrorActionPreference = $previousPreference
  return [pscustomobject]@{
    ExitCode = $childExitCode
    Text = $output -join "`n"
  }
}

function Assert-OverrideFailure(
  [string]$Name,
  [string]$CanonicalText,
  [string]$OldText,
  [string]$NewText,
  [string]$ExpectedDiagnostic,
  [string]$FixturePath,
  [ValidateSet("All", "Last")]
  [string]$Occurrence = "All"
) {
  if (-not $CanonicalText.Contains($OldText)) {
    throw "$Name fixture could not find its exact source text: $OldText"
  }
  if ($Occurrence -eq "Last") {
    $position = $CanonicalText.LastIndexOf($OldText, [System.StringComparison]::Ordinal)
    $mutated = $CanonicalText.Substring(0, $position) + $NewText + $CanonicalText.Substring($position + $OldText.Length)
  } else {
    $mutated = $CanonicalText.Replace($OldText, $NewText)
  }
  [System.IO.File]::WriteAllText($FixturePath, $mutated, [System.Text.UTF8Encoding]::new($false))
  foreach ($mode in @("Resume", "Audit")) {
    $result = Invoke-Checker @("-Mode", $mode, "-SkipSkillMirror", "-IndexOverridePath", $FixturePath)
    if ($result.ExitCode -eq 0) {
      throw "$Name regression: malformed INDEX override passed $mode.`n$($result.Text)"
    }
    if ($result.Text -notmatch [regex]::Escape($ExpectedDiagnostic)) {
      throw "$Name failed $mode without the expected diagnostic '$ExpectedDiagnostic'.`n$($result.Text)"
    }
  }
  Write-Host "PASS: $Name is rejected by Resume and Audit with a targeted diagnostic."
}

foreach ($baselineMode in @("Resume", "Audit")) {
  $baseline = Invoke-Checker @("-Mode", $baselineMode, "-SkipSkillMirror")
  if ($baseline.ExitCode -ne 0 -or $baseline.Text -notmatch 'STRUCTURAL PASS') {
    throw "Canonical work-state $baselineMode did not pass before regressions.`n$($baseline.Text)"
  }
}
Write-Host "PASS: canonical structured INDEX contract is valid in Resume and Audit."

$requestedPhase = "M1-P00"
$phaseClose = Invoke-Checker @("-Mode", "PhaseClose", "-PhaseId", $requestedPhase, "-SkipSkillMirror")
foreach ($foreignPhase in @("M1-P01", "M1-P02", "M1-P03", "M1-P04", "M1-P05", "M1-P06")) {
  if ($phaseClose.Text -match ([regex]::Escape($foreignPhase) + " cannot close")) {
    throw "PhaseClose routing regression: requested $requestedPhase but validated $foreignPhase."
  }
}
if ($phaseClose.ExitCode -eq 0) {
  Write-Host "PASS: PhaseClose accepted the requested completed phase $requestedPhase."
} elseif ($phaseClose.Text -match ([regex]::Escape($requestedPhase) + " cannot close")) {
  Write-Host "PASS: PhaseClose failure diagnostics target the requested phase $requestedPhase."
} else {
  throw "PhaseClose failed without reporting the requested phase $requestedPhase.`n$($phaseClose.Text)"
}

$tempDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ("geometory-work-state-" + [guid]::NewGuid().ToString("N"))
$fixturePath = Join-Path $tempDirectory "INDEX.md"
$hygieneFixturePath = Join-Path $tempDirectory "HYGIENE_LOG.md"
[void](New-Item -ItemType Directory -Path $tempDirectory)
try {
  $canonicalText = [System.IO.File]::ReadAllText($canonicalIndex)
  $currentTaskMatch = [regex]::Match($canonicalText, '(?m)^current_task: "(?<value>M1-P\d{2}-T\d{2})"$')
  $continuationMatch = [regex]::Match($canonicalText, '(?m)^continuation_mode: "(?<value>autonomous|report_required|blocked|complete)"$')
  $workflowStateMatch = [regex]::Match($canonicalText, '(?m)^workflow_state: "(?<value>active|blocked|complete)"$')
  $exactActionMatch = [regex]::Match($canonicalText, '(?m)^exact_next_action: "(?<value>[^"\r\n]+)"$')
  if (-not $currentTaskMatch.Success -or -not $continuationMatch.Success -or -not $workflowStateMatch.Success -or -not $exactActionMatch.Success) { throw "Canonical INDEX frontmatter is not parseable by the regression fixture." }
  $currentTask = $currentTaskMatch.Groups['value'].Value
  $otherTask = if ($currentTask -ne 'M1-P00-T01') { 'M1-P00-T01' } else { 'M1-P00-T02' }
  $continuationMode = $continuationMatch.Groups['value'].Value
  $otherContinuationMode = if ($continuationMode -ne 'report_required') { 'report_required' } else { 'autonomous' }
  $liveTaskLine = '- Active coordinator task: `{0}`' -f $currentTask
  $resumeTaskLine = '- Current task: `{0}`' -f $currentTask
  $liveOtherTaskLine = '- Active coordinator task: `{0}`' -f $otherTask
  $resumeOtherTaskLine = '- Current task: `{0}`' -f $otherTask
  $continuationLine = '- Continuation mode: `{0}`' -f $continuationMode
  $otherContinuationLine = '- Continuation mode: `{0}`' -f $otherContinuationMode
  Assert-OverrideFailure "Live State task mismatch" $canonicalText $liveTaskLine $liveOtherTaskLine 'INDEX.md Live State task does not match' $fixturePath
  Assert-OverrideFailure "Resume Handoff task mismatch" $canonicalText $resumeTaskLine $resumeOtherTaskLine 'INDEX.md Resume Handoff task does not match' $fixturePath
  Assert-OverrideFailure "Live State stale suffix" $canonicalText $liveTaskLine ($liveTaskLine + ' (awaiting report)') 'INDEX.md Live State must contain exactly' $fixturePath
  Assert-OverrideFailure "Resume continuation mismatch" $canonicalText $continuationLine $otherContinuationLine 'INDEX.md Resume Handoff continuation mode' $fixturePath "Last"
  if ($workflowStateMatch.Groups['value'].Value -eq 'active') {
    $exactActionLine = $exactActionMatch.Value
    $staleActionLine = $exactActionLine.Replace($currentTask, $otherTask)
    Assert-OverrideFailure "Exact next-action task mismatch" $canonicalText $exactActionLine $staleActionLine 'INDEX.md exact_next_action must name current_task' $fixturePath
  }
  if ($continuationMode -eq 'autonomous') {
    $handoffLineMatch = [regex]::Match($canonicalText, '(?m)^- Exact handoff:.*$')
    if (-not $handoffLineMatch.Success) { throw "Canonical Resume Handoff has no Exact handoff line for the pause-language fixture." }
    Assert-OverrideFailure "Autonomous stale pause prose" $canonicalText $handoffLineMatch.Value ($handoffLineMatch.Value + ' Wait for user confirmation.') 'INDEX.md autonomous handoff contains' $fixturePath
  }

  $canonicalHygiene = [System.IO.File]::ReadAllText((Join-Path $repoRoot 'docs/open_work/hygiene/LOG.md'))
  $syntheticP01Hygiene = @"

## M1-P01 / checker-regression

- [x] ``HYG-01`` Tracker integrity. Evidence: fixture.
- [x] ``HYG-02`` Authority sync. Evidence: fixture.
- [x] ``HYG-03`` Repository organization. Evidence: fixture.
- [x] ``HYG-04`` Data integrity. Evidence: fixture.
- [x] ``HYG-05`` Validation. Evidence: fixture.
- [x] ``HYG-06`` Visual/device evidence. Evidence: fixture.
- [x] ``HYG-07`` Artifact and secret safety. Evidence: fixture.
- [x] ``HYG-08`` Git integrity. Evidence: fixture.
- [x] ``HYG-09`` Skill integrity. Evidence: fixture.
- [x] ``HYG-10`` Handoff quality. Evidence: fixture.
- Result: Pass.
"@
  [System.IO.File]::WriteAllText($hygieneFixturePath, $canonicalHygiene + $syntheticP01Hygiene, [System.Text.UTF8Encoding]::new($false))
  $phaseReviewGuard = Invoke-Checker @("-Mode", "PhaseClose", "-PhaseId", "M1-P01", "-SkipSkillMirror", "-HygieneOverridePath", $hygieneFixturePath)
  if ($phaseReviewGuard.ExitCode -eq 0 -or $phaseReviewGuard.Text -notmatch 'independent-review record') {
    throw "PhaseClose independent-review regression was not rejected with its targeted diagnostic.`n$($phaseReviewGuard.Text)"
  }
  Write-Host "PASS: P01+ PhaseClose rejects a passing hygiene entry without structured independent review."

  $syntheticIncompleteHygiene = $syntheticP01Hygiene.Replace('- [x] `HYG-10`', '- [ ] `HYG-10`').Replace('- Result: Pass.', "- Independent review: reviewer=fixture; ref=HEAD; scope=M1-P01; result=Pass; findings=None; resolutions=None`r`n- Result: Pass.")
  [System.IO.File]::WriteAllText($hygieneFixturePath, $canonicalHygiene + $syntheticIncompleteHygiene, [System.Text.UTF8Encoding]::new($false))
  $hygieneCompletionGuard = Invoke-Checker @("-Mode", "PhaseClose", "-PhaseId", "M1-P01", "-SkipSkillMirror", "-HygieneOverridePath", $hygieneFixturePath)
  if ($hygieneCompletionGuard.ExitCode -eq 0 -or $hygieneCompletionGuard.Text -notmatch 'all ten unique hygiene items') {
    throw "PhaseClose hygiene-completion regression was not rejected with its targeted diagnostic.`n$($hygieneCompletionGuard.Text)"
  }
  Write-Host "PASS: P01+ PhaseClose rejects a passing result with an unchecked hygiene item."

  $syntheticInvalidRefHygiene = $syntheticP01Hygiene.Replace('- Result: Pass.', "- Independent review: reviewer=fixture; ref=missing-review-ref; scope=M1-P01; result=Pass; findings=None; resolutions=None`r`n- Result: Pass.")
  [System.IO.File]::WriteAllText($hygieneFixturePath, $canonicalHygiene + $syntheticInvalidRefHygiene, [System.Text.UTF8Encoding]::new($false))
  $reviewRefGuard = Invoke-Checker @("-Mode", "PhaseClose", "-PhaseId", "M1-P01", "-SkipSkillMirror", "-HygieneOverridePath", $hygieneFixturePath)
  if ($reviewRefGuard.ExitCode -eq 0 -or $reviewRefGuard.Text -notmatch 'independent-review ref does not resolve') {
    throw "PhaseClose independent-review ref regression was not rejected with its targeted diagnostic.`n$($reviewRefGuard.Text)"
  }
  Write-Host "PASS: P01+ PhaseClose rejects a non-resolving independent-review ref."
} finally {
  if (Test-Path -LiteralPath $fixturePath -PathType Leaf) { Remove-Item -LiteralPath $fixturePath -Force }
  if (Test-Path -LiteralPath $hygieneFixturePath -PathType Leaf) { Remove-Item -LiteralPath $hygieneFixturePath -Force }
  if (Test-Path -LiteralPath $tempDirectory -PathType Container) { Remove-Item -LiteralPath $tempDirectory -Force }
}

Write-Host "PASS: work-state checker regressions completed."
exit 0
