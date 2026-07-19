# Technical Design

## Engine Target

The project is scaffolded for Godot 4.x using typed GDScript. If the installed Godot version differs, update this document and `godot/project.godot` before implementation.

## Directory Strategy

```text
Geometory/
  docs/      design authority and workflows
  data/      rules, maps, bot configs, schemas over time
  core/      engine-agnostic contracts and subsystem boundaries
  godot/     Godot project, scenes, UI, input, rendering, runtime scripts
  tools/     replay export, balancing, bot training helpers
  tests/     headless validation specs and fixtures
```

Godot loads runtime scripts from `godot/scripts`. Core simulation scripts should live under `godot/scripts/core` and must avoid dependencies on `Node`, `Control`, scenes, camera, input, audio, or rendering. Root `core/` documents the same boundaries and can later hold shared schema generation or non-Godot simulation tools if needed.

## Layer Boundaries

### Core Simulation Layer

Owns:

- match state
- rules configuration
- command validation
- turn resolution
- economy/research/military math
- pathfinding
- fog of war queries
- combat
- wall rules
- bot observable-state API
- replay events

Must not own:

- screen size
- touch input
- Godot scene references
- animation timing
- camera state
- UI modal state
- Android export details

### Presentation Layer

Owns:

- map rendering
- camera zoom/pan
- tap selection and drag gestures
- movement previews
- HUD, allocation panels, modal sheets
- animation and visual feedback
- audio/haptics later

Presentation submits serializable commands to the core and renders resulting state/events.

## Data Flow

```text
Input/UI -> Command -> Command Validator -> Rules Engine -> New Match State + Events -> Renderer/UI/Bot Logs
```

Bots use the same command path as humans:

```text
Match State -> Fog Filter -> Observable State -> Bot Policy -> Commands -> Validator
```

## State Model

The core state should be serializable as dictionaries/JSON-compatible data:

- `MatchState`: seed, turn index, active player, phase, ruleset ID, map ID, players, tiles, walls, stacks, command/event history IDs.
- `PlayerState`: bank cents, research bps, pending soldiers, economy bonuses, capital tile, eliminated flag.
- `TileState`: axial coordinate, region ID, home owner, controller, terrain tags.
- `WallState`: edge endpoints, owner, current HP, max HP, destroyed flag.
- `StackState`: tile ID, owner, cohorts, waypoint queue.
- `CohortState`: count, spawn turn, per-soldier stats, current aggregate health.

## Command Model

Commands are the multiplayer and replay boundary. Initial command types are defined in `core/contracts/commands.md`.

Rules:

- Commands are intent, not results.
- Commands must include player ID, turn, phase, and stable target IDs.
- The rules engine validates legality against current state.
- Results are emitted as events and can be compacted for replay notation.

## Config Strategy

Use JSON for V1 rules, maps, and bot profiles because it is easy to diff, load in Godot, and inspect from external tools.

- Rules: `data/rules/default_rules.json`
- Map: `data/maps/alpha_handcrafted.map.json`
- Bot profile: `data/bots/baseline_rule_bot.json`

Root `data/` is the source of truth for external tools and design diffs. Because the Godot project is nested under `godot/`, runtime copies are synced into `godot/data/` so exported builds can load them as `res://data/...`.

After changing root data, run:

```text
powershell -NoProfile -ExecutionPolicy Bypass -File tools/sync_godot_data.ps1
```

Hardcoded constants are allowed only for schema defaults in tests; gameplay should read from config.

## Godot Scene Strategy

V1 scene tree target:

```text
Main.tscn
  GameRoot (Node)
    MapView (Node2D)
    Camera2D
    HudLayer (CanvasLayer)
      TopStatusBar
      BottomActionPanel
      AllocationSheet
      TurnSummarySheet
```

Scenes must not implement rules directly. They can cache visual state but must reconcile from core events.

## Headless Testing

Headless tests should run through Godot once the executable path is known:

```text
godot --headless --path godot --script res://tests/run_core_tests.gd
```

Until Godot is discoverable, tests can be documented and scaffolded but not executed locally.

## Save/Replay Format

V1 should save:

- full JSON state snapshots for debugging
- compact replay notation for analysis and AI review

A replay can be replayed from initial seed, map, ruleset, and commands. Snapshot saves are convenience artifacts, not the source of determinism.

## Networking Preparation

Do not implement networking in V1. Preserve the network path by ensuring:

- all player actions are serializable commands
- rules advance deterministically
- random streams are seeded
- command validation is centralized
- replay command logs are complete enough to reconstruct matches
