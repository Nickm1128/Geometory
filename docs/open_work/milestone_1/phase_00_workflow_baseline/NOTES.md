# M1-P00 Notes — Workflow, Baseline, And Tooling

Append dated findings and decisions. Link durable product changes to the relevant authority document.

## 2026-07-19 — M1-P00-T01

- Status: Complete.
- Finding: the initial Git history tracked only `README.md`; the intended prototype source was present as untracked files.
- Decision: preserve the exact prototype as a standalone baseline before milestone edits.
- Evidence: commit `4b7dc89`, `origin/main`, and annotated tag `m1-baseline`; milestone branch `milestone/m1-vertical-slice`.
- Cross-phase impact: all later comparisons and rollback use `m1-baseline`; `main` is not merged without user authority.

## 2026-07-19 — M1-P00-T02

- Status: Complete.
- Finding: no repository-level agent contract, open-work tracker, phase evidence sets, blocker register, hygiene record, or state linter existed.
- Decision: repository documents are canonical; conversation state is disposable and must be rebuilt through `AGENTS.md` plus `INDEX.md`.
- Validation: `tools/check_work_state.ps1 -Mode Resume` and `-Mode Audit` both passed with 50 parsed tasks, 50 parsed gates, zero blockers, and zero warnings.
- Cross-phase impact: all later work must use stable IDs, immediate checkbox/evidence updates, and phase hygiene.
- Exact next action: validate, synchronize, and fresh-context forward-test the five canonical skills under `M1-P00-T03`.

## 2026-07-19 — M1-P00-T03

- Status: Complete.
- Decision: `codex/skills/` is canonical and the five names in `manifest.json` are the complete managed set; user-level packages are generated mirrors, and differing managed copies are backed up without touching unmanaged skills.
- Validation: all five packages passed skill-creator validation and mirror inventory checks. Fresh agents correctly resumed the open task, routed a command-contract diagnostic to P01 without editing early, refused premature bot evaluation/paid work, and passed the patched P00/P05 visual capability boundary.
- Remediation: forward tests made the phase-publication sequence explicit, corrected the Android validation-document route, required dependency-aware bot refusal, and stopped the visual skill from implying that future P05 matrix/golden tooling already exists.
- Cross-phase impact: fresh agents can rebuild bounded context from repository state; P03/P04 and P05 workflows must continue to refuse nonexistent or dependency-blocked commands instead of inventing them.
- Exact next action: certify the installed Godot 4.6.3/API-36 toolchain and package evidence under `M1-P00-T04`.

## 2026-07-19 — M1-P00-T04

- Status: Complete.
- Decision: M1 local and CI validation is pinned to official Godot 4.6.3, verified downloads, matching templates, Android API 36/build tools 36.0.0, command-line tools 20.0, and Android Studio JBR 21; Godot 4.5.1 is rollback-only.
- Security remediation: pinned engine lookup now verifies only the managed console executable and its SHA-256. It does not execute broad candidates from Downloads or Desktop; core and export helpers independently reject a non-4.6.3 executable.
- Validation: work-state audit, script/JSON/YAML parsing, canonical/runtime data parity, core tests, and UI smoke tests at 360x800, 393x852, and 480x960 passed. The inspected normal APK is min SDK 24, target/compile SDK 36, arm64-v8a plus x86_64, requests only `VIBRATE`, and packages neither tests nor visual-QA resources.
- Warning disposition: Android `aapt2` reports the stock-template `themed_icon.xml` reference as missing. The ordinary/adaptive icon resources remain packaged and the warning is nonblocking for the debug foundation; final icon/manifest inspection remains required in P05/P06.
- Cross-phase impact: T06 owns the separate QA preset and feature route; P05/P06 must revisit launcher-icon polish and preserve the normal-package resource/permission boundary.
- Exact next action: verify and document the non-identifying Galaxy S24 profile and dedicated API-36 AVD under `M1-P00-T05`.
