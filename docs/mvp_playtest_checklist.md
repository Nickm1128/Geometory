# Milestone 1 Phone Playtest Checklist

This checklist evolves with the milestone. `docs/open_work/INDEX.md` determines
which flows are implemented; an unchecked future item is not a current defect
unless its owning phase is complete. P06 produces the final user-facing version.

## Build And Install

1. Resolve Godot 4.6.3 with `tools/find_godot.ps1 -RequirePinned`.
2. Run the work-state, data-parity, core, UI, and relevant visual/replay suites.
3. Export `exports/geometory-debug.apk` with
   `tools/export_android_debug.ps1`.
4. Inspect package `com.milin.geometory`: min SDK 24, target/compile SDK 36,
   arm64-v8a plus x86_64, no Internet/network-state permission, and no loadable
   QA/test resources.
5. List ADB targets and install with an explicit serial when more than one target
   is connected. Never copy the physical serial into tracked evidence.

## Current Prototype Smoke

- [ ] Cold-launch to the main menu without a crash, ANR, or script error.
- [ ] Start Quick Play on Alpha Medium.
- [ ] Allocate Economy/Military/Research and confirm the command.
- [ ] Select the capital stack, preview and confirm an adjacent path, and end the
  turn without an accidental command.
- [ ] Confirm the bot acts automatically and control returns to the player.
- [ ] Verify fog, ownership, walls, queued paths, stack strength, pan, and pinch
  remain understandable.
- [ ] Reach and understand a capital capture and game-over result.

## Final M1 Flow (P06)

- [ ] Win and lose complete human-versus-bot matches without Dev Tools.
- [ ] Background/process restart restores the exact unfinished match.
- [ ] Corrupt/incompatible resume data is quarantined with a recoverable message.
- [ ] Review Last Match supports start/end and previous/next resolved turn with
  board reconstruction, events, and postgame omniscient information.
- [ ] Continue Match, Quick Play, How to Play, Settings, allocation, movement,
  warnings, pause, summaries, results, and replay flows are clear.
- [ ] UI scales 1.00, 1.15, and 1.30 respect live safe areas with no clipping,
  illegal overlap, undeclared ellipsis, or subminimum critical target.
- [ ] Ten pans and ten pinches produce no accidental command; system bars,
  haptics, and three-button navigation behave correctly.
- [ ] Warm pan/zoom performance meets the P06 device gate and has no freeze over
  250 ms.
- [ ] Repeated matches, clean install, upgrade, cold launch, resume, replay, win,
  and loss paths all pass on the physical Galaxy S24.

The final subjective questions are whether the match is fun, pacing feels near
10–20 minutes, information is legible without explanation, and the intended
macro-region fantasy is actually visible.
