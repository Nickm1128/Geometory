# Assumptions And Decisions

This file tracks design choices made to keep the first implementation deterministic and shippable. Revisit entries here before changing behavior.

## Locked For The First Vertical Slice

- Platform: Android-first, portrait-first, with responsive layout for other aspect ratios.
- Engine target: Godot 4.x with typed GDScript, unless the installed editor requires adjustment.
- Board model: one large axial-coordinate micro hex grid, visually grouped into macro regions.
- Map content: one handcrafted map first, described by data files.
- Tile capture: pass-through capture. A living stack claims every tile it successfully enters during movement.
- Economy math: integer cents for money and basis points for multipliers.
- Economy investment: non-compounding temporary income bonus by default, configurable for compounding later.
- Research: cumulative player bonuses, with per-point growth sampled from a shared seeded match schedule.
- Soldiers: cohort-based stacks preserve spawn quality and current health.
- Movement: active player's stacks advance one tile per own turn along queued paths.
- Combat: deterministic seeded resolution, no hidden non-seeded randomness.
- Walls: wall segments sit on blocked edges, start at 1000 HP, and are permanently removed when destroyed.
- Capital capture: if a player's capital tile is controlled by an enemy after resolution, that player is eliminated and their controlled tiles transfer to the capturer.
- Bots: bots receive only observable state under fog of war.
- Networking: actions are serializable commands, but networking is not implemented in V1.
- MVP match: 1v1 human versus Baseline Bot on Alpha Medium.
- Alpha Medium: radius-6 axial board, 127 tiles, home radius 2, P1 capital at `(-4, 0)`, P2 capital at `(4, 0)`, five starting soldiers per capital.
- MVP theme: dark tactical, with no theme toggle until after the first phone playtest.
- Tactical polish: higher-resolution map feel means cached layered procedural rendering at the existing logical portrait viewport, not increasing the logical UI coordinate resolution.
- Tactical texture: map texture stays subtle and procedural so it improves material feel without reducing fog, wall, path, or ownership readability.
- MVP delivery gate: installable Android debug APK.

## Open Decisions

- Whether research schedule is visible to players or only visible in rules/replay logs.
- How much combat randomness is fun before it feels unfair.
- Whether multi-way combat should use strict player-id order or a future initiative rule.
- How unstacking should distribute cohorts when the feature is implemented.
