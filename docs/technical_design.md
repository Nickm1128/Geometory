# Technical Design

## Engine Target

Milestone 1 is pinned to official standard Godot 4.6.3 with typed GDScript and matching export templates. `tools/toolchain.json` is the machine-readable version/hash authority; a different engine cannot silently substitute for validation or export.

## Directory Strategy

```text
Geometory/
  AGENTS.md  autonomous operating fallback
  codex/     repository-canonical project skills
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
- canonical state hashing and explicitly owned deterministic RNG streams

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
- audio and haptics presentation

Presentation submits serializable commands to the core and renders resulting state/events.

## Data Flow

```text
Input/UI -> Command -> Command Validator -> Rules Engine -> New Match State + Events -> Renderer/UI/Bot Logs
```

Bots use the same command path as humans:

```text
Match State -> Fog Filter -> Observable State -> Bot Policy -> Commands -> Validator
```

The bot receives a capability-limited snapshot, never the `GameCore` object.
Own stacks retain full data; visible enemies expose only ID, owner, tile, and a
public deterministic strength band (`tiny`, `small`, `medium`, `large`, or
`overwhelming`), never exact soldier/health/damage values, cohorts, queues,
economy, or research.

## State Model

The core state should be serializable as dictionaries/JSON-compatible data:

- `MatchState`: schema/version, seed, global player-turn ordinal, active player,
  phase, end state, ruleset ID/hash, map ID/hash, players, tiles, walls,
  stacks, research schedule/generation version, accepted-command history,
  rejected-command diagnostics, events, next-ID counters, and RNG-stream
  state/derivation metadata. Canonical serialization sorts all dictionary keys
  and stable-ID collections, includes every gameplay-relevant field plus
  accepted history/events, and excludes diagnostics/presentation fields so a
  rejected input cannot change its SHA-256 hash. M1 stream descriptors are
  immutable serializable values (`stream_id`, purpose, `salt_namespace`, and
  derivation version) for research, combat, and bot ownership; derivation uses
  `fnv1a32_seed_mix_v1` plus the match seed, never an unrecorded mutable PRNG.
  The hash builds an explicit gameplay projection, excluding player display and
  color fields and other presentation-only state rather than hashing the raw
  state dictionary.
- `PlayerState`: bank cents, research bps, pending soldiers, economy bonuses, capital tile, eliminated flag.
- `TileState`: axial coordinate, region ID, home owner, controller, terrain tags.
- `WallState`: edge endpoints, owner, current HP, max HP, destroyed flag.
- `StackState`: tile ID, owner, cohorts, waypoint queue.
- `CohortState`: count, spawn turn, per-soldier stats, current aggregate health.

## Command Model

Commands are the human, bot, replay, and future-network boundary. Initial command types are defined in `core/contracts/commands.md`.

Rules:

- Commands are intent, not results.
- Commands must include player ID, turn, phase, and stable target IDs.
- `client_sequence` is a positive integer, strictly increasing per player in
  M1's one-source-per-player model, and advances only after acceptance. It is
  validated with player, turn,
  phase, ownership, spend range, waypoint existence, path mode, and duplicate
  rules. Multi-waypoint destinations need not be adjacent at submission time;
  every edge actually executed by movement is revalidated for adjacency and
  legality during resolution.
- The rules engine validates the complete command before mutating state or
  recording history; rejected commands go only to diagnostics.
- Results are emitted as events and can be compacted for replay notation.

## Config Strategy

Use JSON for Milestone 1 rules, maps, bot profiles, schemas, and generated normalized evidence because it is easy to diff, load in Godot, and inspect from external tools.

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

Milestone 1 scene/component target:

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

The current prototype keeps most presentation behavior in one large script. P05
extracts reusable screen shell, HUD, sheet, modal, result, replay, and visual
state components while preserving the `GameCore` facade.

## Headless Testing

Headless tests run through the pinned engine:

```text
$godot = powershell -NoProfile -ExecutionPolicy Bypass -File tools/find_godot.ps1 -RequirePinned | Select-Object -First 1
& $godot --headless --path godot --script res://tests/run_core_tests.gd
```

## Save/Replay Format

Milestone 1 persists an active match atomically after every accepted command.
Resume reconstructs from seed, setup/config hashes, and accepted commands rather
than trusting a saved snapshot. On completion, the active record is cleared and
the latest completed replay is retained for player review. Debug snapshots may
exist as evidence but are never the source of determinism; there are no manual
save slots or replay library.

GMTY1 carries schema/version, setup, configuration hashes, all accepted command
types/sequences, and step/final hashes. Unsupported, corrupt, truncated, or stale
records fail safely and are quarantined with recoverable diagnostics.

## Networking Preparation

Do not implement networking in Milestone 1. P2P, lobbies, accounts, servers, and
network synchronization begin in Milestone 2 or later. Preserve that path by
ensuring:

- all player actions are serializable commands
- rules advance deterministically
- random streams are seeded
- command validation is centralized
- replay command logs are complete enough to reconstruct matches

## Android And Visual-QA Boundary

The production package is `com.milin.geometory`; the QA-only package is
`com.milin.geometory.qa`. Build-time `visual_qa` selects a wrapper main scene and
fixture resources that the normal preset excludes. Production scripts contain
no fixture route, and neither package contains tests or network permissions.

The fixture request/ready contract carries schema, nonce, scenario, seed, UI
scale, safe-area provenance, APK hash, viewport, live safe area, assertions,
errors, and deterministic state hash. P00 reserves 26 scenario IDs; P05 completes
and visually certifies them.
