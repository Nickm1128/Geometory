# Galaxy S24 Validation Profile

Last certified: 2026-07-19 (`M1-P00-T05`).

The physical Galaxy S24 is the authoritative M1 Android device. The dedicated
AVD reproduces its screen geometry and OS-level test settings closely enough for
repeatable automation, but it does not replace physical-device checks for
Samsung cutouts, rounded corners, haptics, refresh behavior, or lifecycle quirks.

The machine-readable, non-identifying profile is
`tools/device_profiles/galaxy_s24_primary.json`. Do not add an ADB serial,
Android ID, account, phone number, Wi-Fi address, or another unique identifier
to that file, documentation, logs, screenshots, or task evidence.

## Authoritative Physical Profile

| Field | Certified value |
|---|---:|
| Repository alias | `primary_galaxy_s24` |
| Device family/model | Samsung Galaxy S24 / SM-S921U |
| OS | Android 16 / API 36 |
| ABI | arm64-v8a |
| Portrait pixels | 1080 x 2340 |
| Hardware / active density | 480 / 420 dpi |
| Font scale | 1.0 |
| Top cutout-safe inset | 103 px |
| Visible bottom navigation inset | 126 px |
| Left/right safe inset | 0 px |
| Physical / app-content corner radius | 108 / 95 px |
| Navigation | Three-button (`navigation_mode=0`) |
| Reported refresh modes | 10, 24, 30, 48, 60, 80, 120 Hz |

The cutout bounds observed in portrait were `[511, 0, 569, 103]`. Safe-area,
navigation, density, font-scale, corner, and refresh facts came from live Android
display/window/settings inspection; the tracked record contains only reusable
layout facts. Re-measure them after an OS update, navigation-mode change,
display-zoom change, or screen-resolution change.

## Dedicated Emulator

The project-owned AVD is `Geometory_Galaxy_S24_API36`:

- API 36 Google Play x86_64 image;
- 1080 x 2340 portrait viewport at 420 dpi;
- font scale 1.0;
- four CPU cores and 4096 MB RAM;
- 6 GB data partition;
- software three-button navigation;
- device frame disabled; and
- cold-boot-first validation with no captured emulator frame.

Create or repair only this AVD:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/ensure_geometory_avd.ps1 -Mode Ensure
```

Verify its files without launching:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/ensure_geometory_avd.ps1 -Mode Verify
```

Verify, boot, and enforce runtime display/navigation settings:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/ensure_geometory_avd.ps1 -Mode Verify -Launch
```

The tool confines edits to this named AVD and refuses to rewrite its
configuration while it is running. It does not modify another AVD.

## 2026-07-19 Evidence

Static configuration and a clean runtime boot both passed. Runtime inspection
reported Android 16/API 36, x86_64, boot complete, 1080 x 2340, 420 dpi, font
scale 1.0, and navigation mode 0. The physical device and emulator had each
previously launched the isolated QA package during the same P00 run; T06 owns
the package-contract evidence.

## Known Fidelity Boundaries

- The emulator is 60 Hz by default and does not reproduce the phone's adaptive
  120 Hz modes.
- Generic emulator cutout and rounded-corner geometry is not authoritative.
- Emulator vibration is not Samsung haptic certification.
- Pixel comparison across Android/emulator/Windows renderers is not valid; P05
  uses structural review across platforms and canonical goldens only within the
  declared Windows/OpenGL/Godot environment.
