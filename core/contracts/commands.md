# Command Contract

Commands are serializable player intents. They are the boundary for human input, bot decisions, replay, and future networking.

## Common Fields

Every command includes:

```json
{
  "type": "command_type",
  "player_id": "P1",
  "turn": 1,
  "phase": "allocation",
  "client_sequence": 12
}
```

`client_sequence` is stable per command source and helps debug replay/network ordering.

## V1 Commands

### AllocateResources

```json
{
  "type": "allocate_resources",
  "player_id": "P1",
  "turn": 1,
  "phase": "allocation",
  "economy_cents": 300,
  "military_cents": 600,
  "research_cents": 300,
  "client_sequence": 1
}
```

Validation:

- player is active
- phase is allocation
- all spends are non-negative integers
- total spend is less than or equal to bank

### QueueStackPath

```json
{
  "type": "queue_stack_path",
  "player_id": "P1",
  "turn": 1,
  "phase": "movement",
  "stack_id": "S12",
  "waypoints": ["A3", "B3", "C3"],
  "mode": "append",
  "client_sequence": 2
}
```

Validation:

- player owns stack
- stack is alive and visible to player
- phase is movement
- waypoints are known tile IDs
- mode is `append` or `replace`

### EndPhase

```json
{
  "type": "end_phase",
  "player_id": "P1",
  "turn": 1,
  "phase": "movement",
  "client_sequence": 3
}
```

Validation:

- player is active
- phase matches current phase

## Future Commands

Planned after V1 core is stable:

- split stack
- merge stacks
- cancel queued path
- set rally behavior
- request diplomacy or P2P lobby actions

## Events

Commands produce events. Events are facts, not intents. Examples:

- `income_added`
- `allocation_applied`
- `soldiers_queued`
- `soldiers_spawned`
- `stack_moved`
- `tile_control_changed`
- `wall_damaged`
- `wall_destroyed`
- `combat_resolved`
- `player_eliminated`
- `match_ended`
