# Android Mobile UI/UX Guidelines

## Target Device And Layout

Primary test device: Galaxy S24. V1 is portrait-first and must adapt to other Android aspect ratios.

Do not hardcode layout for one resolution. Use anchors, containers, safe margins, and scalable HUD panels.

## Screen Principles

- Keep the board visible as the main object at all times.
- Prefer bottom sheets over centered modals for frequent actions.
- Avoid dense tables and tiny icon-only controls.
- Put turn-critical information in persistent HUD regions.
- Make every touch target forgiving.

## Touch Targets

- Minimum target: 48 dp equivalent.
- Preferred important action target: 56-64 dp equivalent.
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

Default V1 direction: clean strategic dark board with thin light grid lines and distinct player colors. A light theme can be added later if readability demands it.

Guidelines:

- Thin grid lines, stronger outlines only for selected/fog/frontline states.
- Distinct player colors tested for contrast and color-blind safety.
- Subtle gradient or vignette background, not busy texture.
- Fog should hide information clearly without making the board look broken.
- Walls should be readable at both macro and micro zoom levels.

## Accessibility Baseline

- Do not encode ownership by color only; include outline, pattern, or icon accents for selected/critical states.
- Avoid rapid flashing.
- Keep combat/result summaries available in text.
- Allow UI scale tuning later through settings.

## Validation Checklist

Before marking UI work complete:

- Test portrait narrow and tall aspect ratios.
- Verify all bottom panels fit without covering critical selected tiles.
- Verify tap targets are reachable with one hand.
- Verify text does not clip at large UI scale.
- Verify fog/player colors remain readable over the chosen background.
