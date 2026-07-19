# MVP Phone Playtest Checklist

APK:

```text
C:\Users\milin\Documents\Geometory\exports\geometory-debug.apk
```

## Install

Connect an Android phone with USB debugging enabled, then run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/export_android_debug.ps1 -Install
```

If the APK is already exported, install directly:

```powershell
C:\Users\milin\AppData\Local\Android\Sdk\platform-tools\adb.exe install -r exports\geometory-debug.apk
```

## Smoke Test

1. Launch Geometory.
2. Tap `Quick Play`.
3. Tap `Start Match`.
4. In allocation, tap `Auto Balance` or `Confirm Balanced Spend`.
5. Tap your capital stack, tap a neutral tile, tap `Queue Move`, then `End Turn`.
6. Confirm the bot takes its turn automatically and control returns to you.
7. Queue movement toward the enemy home region; confirm wall hits show in the event text.
8. Continue until a capital is captured and the game-over screen appears.

## UI Checks

- Top HUD text remains readable.
- Bottom panel does not block core map interactions.
- Buttons are comfortable to tap.
- Hex selection feels forgiving.
- Fog, walls, stack counts, and path previews remain legible on the phone.
