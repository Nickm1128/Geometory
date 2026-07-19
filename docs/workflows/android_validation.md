# Android Validation Workflow

Use this workflow for every Android export, install, lifecycle check, or mobile
UI certification. The pinned versions are recorded in `tools/toolchain.json`
and summarized in `docs/tooling_inventory.md`.

## 1. Establish the Pinned Environment

```powershell
$godot = powershell -NoProfile -ExecutionPolicy Bypass -File tools/find_godot.ps1 -RequirePinned | Select-Object -First 1
& $godot --version
```

The version must begin with `4.6.3`. Matching templates must exist at
`%APPDATA%\Godot\export_templates\4.6.3.stable`. Use Android Studio's JBR 21
and the SDK packages declared in `tools/toolchain.json`.

Do not silently fall back to Godot 4.5.1, an unverified download, a different
template version, or an older Android platform.

## 2. Run Pre-export Validation

From the repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/check_work_state.ps1 -Mode Audit
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_core_tests.ps1 -GodotPath $godot
& $godot --headless --path godot --script res://tests/run_ui_smoke_tests.gd
```

Confirm that each canonical data file has the same SHA-256 as its copy under
`godot/data/` before exporting.

## 3. Export the Intended Package

Normal debug package:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/export_android_debug.ps1 -GodotPath $godot
```

QA-only package:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/export_android_debug.ps1 -GodotPath $godot -Preset "Android Visual QA"
```

Use `-Install` and optional `-Serial` only after confirming the intended ADB
target. Never record the physical phone serial in tracked files, logs, or task
evidence.

## 4. Inspect the APK, Not Just the Preset

Use `aapt2 dump badging`, `apkanalyzer manifest print`, or equivalent local SDK
tools against the generated APK. Record evidence for:

- package and version name;
- min SDK 24;
- target and compile SDK 36;
- arm64-v8a and x86_64 native libraries;
- requested permissions;
- SHA-256; and
- packaged-resource inventory.

The normal package must be `com.milin.geometory`, contain no `visual_qa` or test
resources, and request neither `android.permission.INTERNET` nor
`android.permission.ACCESS_NETWORK_STATE`. The QA package must be
`com.milin.geometory.qa`; it may contain the fixture harness but no test suite.

Warnings are evidence, not automatic failures. Record and classify each one;
do not suppress an unexplained manifest, signing, resource, or architecture
warning.

## 5. Install and Launch Safely

Before installation, list ADB targets and distinguish the dedicated emulator
from the physical phone. Use an explicit serial whenever more than one target is
connected. For the physical phone, capture and publish only the non-identifying
profile fields authorized in `tools/device_profiles/`.

Normal builds launch the production main scene. QA builds launch the fixture
scene only because the `visual_qa` export feature is present. A QA route in the
normal APK is a release-blocking defect.

For each target, verify:

- install/upgrade result and cold launch;
- focused package and expected activity;
- absence of crash, ANR, and app-scoped fatal log entries;
- portrait viewport and safe-area behavior;
- touch, pan, pinch, accidental-command prevention, and haptics when applicable;
- background/process restart behavior when the active phase implements it; and
- no unrelated overlay or picture-in-picture window in captured evidence.

Never dismiss, stop, identify, or capture an unrelated phone application merely
to obtain a clean screenshot. Reject the capture and retry after the user has
cleared the screen.

## 6. Visual-QA Evidence

Follow `docs/workflows/visual_qa.md` for deterministic fixture requests,
ready-marker validation, screenshots, manifests, assertions, and logs. A package
launch is not visual certification. During P00, only foundation/launch evidence
is required; the full device matrix and canonical golden review are P05 work.

Keep APKs, screenshots, logcat output, window dumps, contact sheets, and image
diffs under ignored artifact directories. Version only stable schemas, fixture
definitions, tools, approved canonical goldens, and concise task evidence.

## 7. Report

Record the engine/template versions, package, device alias, validation commands,
manifest facts, artifact path, hashes, warnings, failures, and disposition in the
active task and append-only phase notes. Update its checkbox immediately only
after the required evidence and affected authority documents are complete.
