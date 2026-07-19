# Godot Project

Open this directory with the pinned Godot 4.6.3 build resolved by
`../tools/find_godot.ps1 -RequirePinned`.

## Boundaries

- Production scenes, UI, input, camera, rendering, motion, and haptics live here.
- Runtime core scripts live under `scripts/core` and remain headless-compatible.
- Presentation submits serializable commands and renders core state/events; it
  does not own gameplay rules.
- Balance constants come from synchronized `res://data`, never scene scripts.
- Root `../data/` is canonical. Run `../tools/sync_godot_data.ps1` from the
  repository root after changing it.

`scenes/main/Main.tscn` is the current playable prototype. P05 will extract its
large presentation script into reusable shell/HUD/sheet/modal/result/replay
components.

`visual_qa/VisualQaMain.tscn` is selected only by the `Android Visual QA` export
feature and package. The normal preset excludes all fixture resources and tests.

## Headless Checks

```powershell
$godot = powershell -NoProfile -ExecutionPolicy Bypass -File ..\tools\find_godot.ps1 -RequirePinned | Select-Object -First 1
& $godot --headless --path . --script res://tests/run_core_tests.gd
& $godot --headless --path . --script res://tests/run_ui_smoke_tests.gd
& $godot --headless --path . --script res://tests/run_visual_qa_contract_tests.gd
```
