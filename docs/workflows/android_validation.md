# Android Validation Workflow

Use this workflow when validating Godot builds or mobile UI.

## Prerequisites

- Standard Godot executable path is known. For this MVP, use `C:\Users\milin\Downloads\Godot_v4.5.1-stable_win64\Godot_v4.5.1-stable_win64_console.exe`.
- Matching standard Godot export templates are installed.
- Android SDK path is configured in Godot or environment variables.
- A debug keystore exists or Godot can create one.
- Device or emulator is available through `adb`.

Detected SDK path at scaffold time:

```text
C:\Users\milin\AppData\Local\Android\Sdk
```

## UI Checks

1. Launch the project at phone-like portrait dimensions.
2. Verify top HUD, board, and bottom panels do not overlap critical interactions.
3. Check minimum touch target sizes for allocation buttons and map actions.
4. Test tap selection near hex edges.
5. Test pinch zoom and pan without accidental move commands.
6. Verify bottom sheets at small, tall, and wide aspect ratios.
7. Confirm fog, player colors, wall state, and path previews are readable.

## Export Checks

Use the CLI export path for Android debug builds:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/export_android_debug.ps1 -GodotPath "C:\Users\milin\Downloads\Godot_v4.5.1-stable_win64\Godot_v4.5.1-stable_win64_console.exe"
```

Record:

- Godot version
- export template version
- Android SDK path
- target device/emulator
- build output path
- install result
- relevant `adb logcat` errors

## Do Not Skip

- Real-device or emulator tap testing for UI changes.
- Safe-area and aspect-ratio checks.
- Headless deterministic simulation tests before UI-only debugging.
