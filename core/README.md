# Core Contracts

This directory defines the engine-agnostic organization for Geometory's headless game logic. Runtime code will initially live in `godot/scripts/core` so Godot can load it, but it must follow these subsystem boundaries.

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
