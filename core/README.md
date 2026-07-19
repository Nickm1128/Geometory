# Core Contracts

This directory defines the engine-agnostic contracts for Geometory's headless
game logic. Runtime GDScript lives in `godot/scripts/core` so Godot can load it;
P01–P04 progressively enforce these subsystem boundaries and add runners/tools.

## Subsystems

- `match_state`: serializable state models.
- `rules_engine`: command validation and turn resolution.
- `economy`: income, allocation, research, military spawn queues.
- `combat`: wall and stack combat resolution.
- `pathing`: axial hex navigation and queued paths.
- `fog_of_war`: observable-state filtering.
- `bot_api`: bot policy interfaces and command emission.
- `simulation_runner`: headless match execution and metrics.
- `contracts`: command and replay notation specs.

## Rule

Core code must not depend on scenes, UI controls, camera nodes, input events, or rendering resources.
