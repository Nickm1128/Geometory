# Godot Project

Open this folder as the Godot project once the local Godot executable path is known.

## Rules

- Scenes, UI, input, camera, rendering, and animation live here.
- Runtime core scripts live under `scripts/core` but must avoid scene dependencies.
- Presentation scripts submit commands to core services and render events/state.
- Do not put balance constants in scene scripts; load synced runtime data from `res://data`.
- Root `data/` remains the source of truth. Run `../tools/sync_godot_data.ps1` from the repo root after changing it.

## Initial Scene Shell

`scenes/main/Main.tscn` exists only so the project opens cleanly. It is not a gameplay implementation yet.
