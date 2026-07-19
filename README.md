# Geometory

Geometory is a mobile-first Android turn-based strategy game about fast,
readable territorial decisions on a zoomable hex map. Milestone 1 is one
polished 10–20 minute local match on the handcrafted Alpha Medium map: human
versus a fair bot, with deterministic rules, automatic resume, last-match
replay review, an external guarded AI-assisted bot-improvement workbench, and
the bulk of the intended aesthetics and UX.

P2P, lobbies, accounts, servers, network synchronization, additional maps,
more than two active players, and runtime LLM opponents are explicitly deferred
until after Milestone 1.

## Current Status

The original playable prototype is remotely recoverable from `main` and the
annotated `m1-baseline` tag. Milestone work stays on
`milestone/m1-vertical-slice` and is not merged to `main` without explicit user
approval.

Phase 00 established the autonomous documentation/tracker system, five
repository-canonical Codex skills, pinned Godot 4.6.3 and Android API 36
tooling, an alias-only Galaxy S24 profile with a matched API-36 AVD, CI checks,
and an isolated deterministic visual-fixture package. The existing prototype
mechanics still require the P01–P06 correctness, replay/resume, simulation, bot,
AI-workbench, UX, and certification work described in the milestone plan.

The live phase, current task, blockers, validation state, and exact next action
are authoritative in `docs/open_work/INDEX.md`; do not infer completion from
source presence alone.

## Repository Map

- `docs/` — product, gameplay, architecture, UX, bot, simulation, tooling, and
  device authorities.
- `docs/open_work/` — the active milestone plan, per-phase trackers, blockers,
  run log, and hygiene evidence.
- `data/` — canonical tunable rules, handcrafted map, and bot profile.
- `godot/data/` — synchronized runtime copies loadable through `res://data`.
- `godot/` — production project, core/presentation scripts, test runners, and
  QA-only fixture resources.
- `core/` — engine-agnostic command and replay contracts.
- `tools/` — validation, export, data synchronization, device, and visual-QA
  automation; later phases add simulation and bot-workbench tools.
- `codex/skills/` — versioned Geometory workflows mirrored into the user-level
  Codex skill directory.
- `tests/` — engine-agnostic test and fixture boundaries as they are added.
- `docs/archive/` — historical source material only, never current authority.

## Resume Autonomous Work

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/sync_codex_skills.ps1 -Mode Check
powershell -NoProfile -ExecutionPolicy Bypass -File tools/check_work_state.ps1 -Mode Resume
```

Then follow `AGENTS.md`, `docs/open_work/AUTONOMOUS_RUN.md`, and the exact handoff
in the active phase notes. Fetch and inspect Git state; never pull, reset,
force-push, move a tag, or merge `main` autonomously.

## Validate the Current Project

Resolve the verified engine and run the core/UI/fixture suites:

```powershell
$godot = powershell -NoProfile -ExecutionPolicy Bypass -File tools/find_godot.ps1 -RequirePinned | Select-Object -First 1
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_core_tests.ps1 -GodotPath $godot
& $godot --headless --path godot --script res://tests/run_ui_smoke_tests.gd
& $godot --headless --path godot --script res://tests/run_visual_qa_contract_tests.gd
```

After changing canonical root data, synchronize it and rerun parity validation:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/sync_godot_data.ps1
```

Export the normal API-36 debug APK:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/export_android_debug.ps1
```

The normal package is `com.milin.geometory`; the isolated fixture package is
`com.milin.geometory.qa`. Follow `docs/workflows/android_validation.md` and
`docs/workflows/visual_qa.md` before claiming an APK or screen is certified.
Generated APKs, screenshots, logs, replays, reports, and simulation output stay
in ignored artifact directories.

## Engineering Boundary

Core rules remain independent of rendering, input, scene-tree lifecycle,
Android UI, and external model services. Human input, bots, replay, and future
networking cross the core through serializable commands. The Android app never
contains model credentials, model code, or runtime LLM behavior.

See `AGENTS.md` for the autonomous operating contract and `docs/README.md` for
the documentation authority map.
