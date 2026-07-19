# Tooling Inventory

Inspection date: 2026-04-25.

## Repository State

`C:\Users\milin\Documents\Geometory` initially contained only `GeometoryStarterNotes.md`. No `project.godot` file existed before scaffolding.

Git currently resolves to parent repository `C:\Users\milin`, which contains many unrelated changes outside this project. Treat `Geometory` as a standalone workspace and avoid parent-repo git operations unless explicitly requested.

## Godot

Detected after MVP implementation:

- Standard Godot 4.5.1 console: `C:\Users\milin\Downloads\Godot_v4.5.1-stable_win64\Godot_v4.5.1-stable_win64_console.exe`
- Standard Godot 4.5.1 GUI: `C:\Users\milin\Downloads\Godot_v4.5.1-stable_win64\Godot_v4.5.1-stable_win64.exe`
- Mono Godot 4.5.1 also exists under Downloads, but Android export should use the standard non-Mono binary for this GDScript-only MVP.

## Android Tooling

Detected:

- Java: `C:\Program Files\Microsoft\jdk-11.0.28.6-hotspot\bin\java.exe`
- Keytool: `C:\Program Files\Microsoft\jdk-11.0.28.6-hotspot\bin\keytool.exe`
- Android SDK directory: `C:\Users\milin\AppData\Local\Android\Sdk`
- SDK subfolders include build-tools, emulator, platform-tools, platforms, system-images, ndk, cmake, licenses.
- ADB: `C:\Users\milin\AppData\Local\Android\Sdk\platform-tools\adb.exe`, version 36.0.0-13206524.
- Installed build-tools: 34.0.0, 35.0.0, 36.0.0.
- Installed platforms: android-34, android-36.

Environment variables not set at inspection time:

- `ANDROID_HOME`
- `ANDROID_SDK_ROOT`

Action needed: set Android SDK env vars or configure paths inside Godot before Android export.

## Godot Export Templates

Detected/installed:

- Standard templates: `C:\Users\milin\AppData\Roaming\Godot\export_templates\4.5.1.stable`
- Mono templates: `C:\Users\milin\AppData\Roaming\Godot\export_templates\4.5.1.stable.mono`

The standard templates were needed because the Mono binary reports Android .NET export as experimental.

## Validation Implication

Headless tests and Android debug export now run with the standard Godot 4.5.1 console binary.

## MVP Helper Scripts

- Locate Godot: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/find_godot.ps1`
- Run core tests: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_core_tests.ps1 -GodotPath "C:\path\to\Godot.exe"`
- Export Android debug APK: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/export_android_debug.ps1 -GodotPath "C:\path\to\Godot.exe"`
- Export and install: add `-Install` if a phone/emulator is visible through ADB.

Latest successful export:

- `C:\Users\milin\Documents\Geometory\exports\geometory-debug.apk`
