# Tooling Inventory

Last certified: 2026-07-19 (`M1-P00-T04`).

`tools/toolchain.json` is the machine-readable authority for pinned versions,
download hashes, SDK levels, and the dedicated AVD name. This document explains
how those entries are used; do not update one without updating the other.

## Repository and Git

- Repository root: `C:\Users\milin\Documents\Geometory`
- Baseline: `main` and annotated tag `m1-baseline` at commit `4b7dc89`
- Milestone branch: `milestone/m1-vertical-slice`
- Remote: `origin` on GitHub

The repository is standalone. Never run Git operations against a parent
directory, merge the milestone branch to `main`, move a published tag, or
force-push as part of autonomous work.

## Godot

Milestone 1 is pinned to the official standard GDScript build of Godot 4.6.3:

- Console: `C:\Users\milin\Tools\Godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe`
- GUI: `C:\Users\milin\Tools\Godot\4.6.3\Godot_v4.6.3-stable_win64.exe`
- Templates: `%APPDATA%\Godot\export_templates\4.6.3.stable`
- Windows archive SHA-256:
  `e39986a178d585ce7ac198fb8de6ea436366dc0cc00e594810c2e3e104c04b90`
- Managed console executable SHA-256:
  `63b3b2208819714c9677fbfdd8217c5b7dee8ecf5f383502e826bc9e2227ff5a`
- Export-template SHA-256:
  `3fbe2c0e2dec9d537ab9ec97bcf8da91dcf23357fc51f67092dd068d839290a8`

The prior Godot 4.5.1 standard build remains under the user's Downloads folder
as a rollback tool. It is not a supported validation or export engine for M1.
`tools/find_godot.ps1 -RequirePinned` verifies and selects only the managed
4.6.3 console binary. It never executes broad candidates from Downloads or the
Desktop while resolving the pinned engine.

GitHub Actions downloads the official 4.6.3 Linux archive and verifies the
SHA-512 recorded in `tools/toolchain.json` before running any engine command.

## Android and Java

- SDK root default: `%LOCALAPPDATA%\Android\Sdk`
- Compile/target SDK: 36
- Minimum SDK: 24
- Build tools: 36.0.0
- Platform tools/ADB: 36.0.0-13206524
- Command-line tools: 20.0
- Emulator image: API 36 Google Play x86_64
- Java: Android Studio JetBrains Runtime 21.0.6
- Preferred Java root: `C:\Program Files\Android\Android Studio\jbr`

The export helper resolves `ANDROID_SDK_ROOT`, then `ANDROID_HOME`, then the
standard local SDK path. It similarly prefers Android Studio's JBR and falls
back to `JAVA_HOME`. It scopes those environment values to the current process;
permanent user environment changes are not required.

`tools/install_android_command_line_tools.ps1` is deliberately conservative:
it requires explicit license acceptance before installation, verifies the
official archive hash, and refuses to overwrite a different package at
`cmdline-tools\latest`.

## Android Export Presets

`godot/export_presets.cfg` defines the normal debug preset:

- `Android Debug`: package `com.milin.geometory`; excludes tests.

It exports arm64-v8a and x86_64, uses min SDK 24 and target/compile SDK 36
from the verified Godot 4.6.3 templates, disables Internet and network-state
permissions, and retains only the vibration permission required by runtime
haptics. `M1-P00-T06` adds the isolated QA preset and feature route. APKs are
generated under ignored `exports/`.

## Validation Commands

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/find_godot.ps1 -RequirePinned
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_core_tests.ps1
& $godot --headless --path godot --script res://tests/run_ui_smoke_tests.gd
powershell -NoProfile -ExecutionPolicy Bypass -File tools/export_android_debug.ps1
```

An APK is not certified merely because export succeeds. Follow
`docs/workflows/android_validation.md` to inspect SDK levels, architectures,
permissions, resource isolation, install/launch behavior, logs, and SHA-256.

## Continuous Integration

`.github/workflows/validate.yml` runs on `main`, `milestone/**`, pull requests,
and manual dispatch. It performs:

1. read-only work-state validation without assuming a workstation skill mirror;
2. canonical/runtime data-copy parity checks;
3. verified Godot 4.6.3 download and version reporting;
4. deterministic core tests; and
5. the three-size portrait UI smoke matrix.

CI is a clean-environment guard, not a substitute for emulator and physical
device validation.
