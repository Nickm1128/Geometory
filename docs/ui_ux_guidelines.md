# Android Mobile UI/UX Guidelines

## Target Device And Layout

Primary test device: the alias-only Galaxy S24 profile in `docs/device_validation_profile.md`. Milestone 1 is portrait-first and must adapt to other Android aspect ratios.

Do not hardcode layout for one resolution. Production uses live Android safe-area
data, anchors, containers, scalable HUD panels, and persisted UI scale. QA may
inject a declared device profile; it must never replace live production insets.

## Screen Principles

- Keep the board visible as the main object at all times.
- Prefer bottom sheets over centered modals for frequent actions.
- Avoid dense tables and tiny icon-only controls.
- Put turn-critical information in persistent HUD regions.
- Make every touch target forgiving.

## Touch Targets

- Minimum target: 48 dp equivalent.
- Primary actions: at least 56 logical pixels; 64 is preferred where space allows.
- Maintain at least 8 dp spacing between adjacent critical actions.
- Hex selection should tolerate small finger offset and choose nearest valid tile.
- Long press should be optional, never required for core play.

## HUD Layout

Recommended portrait layout:

- Top status bar: active player, turn, bank, income preview, phase.
- Board center: map, selected stack highlights, fog, wall state, path preview.
- Bottom action panel: context actions for selected tile/stack.
- Allocation sheet: bottom sheet opened at start of allocation phase.
- Turn summary sheet: compact result log after movement/combat.

Main Menu, Continue Match, Review Last Match, Quick Play, How to Play, Settings,
allocation, movement, warnings, pause, turn summary, game over, and replay are
all player-facing Milestone 1 flows. A complete match must be understandable
without Dev Tools.

During play, the selected stack shows health/quality and the same visible enemy
strength context available on the board. Turn and combat summaries use real
events, while allocation/income changes, territory capture, wall damage or
breach, and victory/defeat each receive immediate, unambiguous feedback.

## Modal Rules

- Frequent panels should use bottom sheets, not full-screen blocking dialogs.
- Modal width should not exceed 92 percent of safe viewport width.
- Modal height should target 45-65 percent of viewport; only rules/help screens may exceed that.
- Every modal must have a clear close/confirm path and preserve context.
- Text should wrap naturally and avoid horizontal scrolling.

## Typography And Readability

- Use a purposeful readable font once assets are selected; do not rely on tiny default labels.
- Body text should remain readable on a phone at arm's length.
- Numeric stats should use tabular alignment or consistent width where possible.
- Prefer short labels: `Income`, `Bank`, `Research`, `Spawn Next`.

## Map Interaction

- Tap a stack or tile to select.
- Tap destination to preview or append path depending on current mode.
- Provide an obvious `Queue` or `Move` affordance for destination confirmation.
- Support queued waypoints visually with numbered markers or thin path segments.
- Pinch zoom and drag pan should feel smooth and should not trigger accidental commands.

## Visual Direction

Default Milestone 1 direction: clean strategic dark board with thin light grid lines and distinct player colors. A light theme can be added later if readability demands it.

Guidelines:

- Thin grid lines, stronger outlines only for selected/fog/frontline states.
- Distinct player colors tested for contrast and color-blind safety.
- Subtle gradient or vignette background, not busy texture.
- Fog should hide information clearly without making the board look broken.
- Walls should be readable at both macro and micro zoom levels.
- Macro-region boundaries/grouping must be visible enough to deliver the
  macro-fantasy pillar without obscuring micro-hex tactics.
- Ownership, selection, capital, threat, fog frontier, damage, and queued paths
  require non-color cues and readable zoom-level states.

## Accessibility Baseline

- Do not encode ownership by color only; include outline, pattern, or icon accents for selected/critical states.
- Avoid rapid flashing.
- Keep combat/result summaries available in text.
- Persist UI scales 1.00, 1.15, and 1.30, tips, and reduced-motion settings.
- Bundle the chosen font so deterministic fixtures do not depend on host fonts.

## Validation Checklist

Before marking UI work complete:

- Test portrait narrow and tall aspect ratios.
- Verify all bottom panels fit without covering critical selected tiles.
- Verify tap targets are reachable with one hand.
- Verify text does not clip at large UI scale.
- Verify fog/player colors remain readable over the chosen background.
- Render the required state directly through the versioned 26-scenario fixture
  catalog instead of navigating a whole match.
- Test critical screens at 360x800, 393x852, and 480x960 and at UI scales 1.00,
  1.15, and 1.30.
- Pass every required scenario on the dedicated API-36 emulator and physical
  Galaxy S24 with no safe-area violation, clipping, illegal overlap, undeclared
  ellipsis, crash, ANR, or script error.
- Pixel-compare only canonical 393x852 Windows/OpenGL/Godot-4.6.3 captures;
  review emulator/device captures structurally across platforms.
