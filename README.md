# Geometory

Geometory is a mobile-first Android turn-based strategy game prototype built in Godot. The target vertical slice is a 10-20 minute hex-territory match with economy allocation, research, military spawning, fog of war, walls, queued soldier movement, deterministic combat, and rule-based bot opponents.

## Current Scaffold

- `docs/` contains the authoritative design foundation for Phase 1.
- `data/` contains tunable rules, map, and bot configuration stubs.
- `godot/data/` contains synced runtime copies that Godot can load as `res://data`.
- `core/` documents the headless simulation contracts and subsystem boundaries.
- `godot/` is the Godot project shell for scenes, UI, input, and rendering.
- `tools/` is reserved for replay export, balancing, and bot-training automation.
- `tests/` is reserved for headless rules, simulation, and bot validation tests.

## MVP Playtest Path

The current MVP target is a guided 1v1 Quick Play match: human P1 versus Baseline Bot P2 on Alpha Medium. Open `godot/` in Godot or run the helper scripts once the Godot executable path is known.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_core_tests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools/export_android_debug.ps1 -Install
```

If no phone is connected through ADB, omit `-Install`; the APK is written to `exports/geometory-debug.apk`.

Use `docs/mvp_playtest_checklist.md` for the first phone validation pass.

## Architecture Rule

Core game rules must stay independent from rendering, input, scene tree lifecycle, and Android UI. Godot scenes call into deterministic core services; they do not own the rules.

## Tooling Status

See `docs/tooling_inventory.md`. At scaffold time, the Android SDK is present under the user profile, Java/keytool are available, but Godot and Godot Android export templates are not visible from PATH/common locations.

After editing root `data/`, run `tools/sync_godot_data.ps1` so the Godot project receives exportable runtime data.
"# Geometory" 
