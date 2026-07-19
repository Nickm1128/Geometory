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

`client_sequence` is a positive integer stable per command source and helps
debug replay/network ordering. M1 has exactly one command source per player, so
it must be strictly greater than that player's last accepted sequence. A
rejected command never advances the sequence.

## Milestone 1 Commands

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

## Acceptance And History

Validation is all-or-nothing. A command is accepted only after required common
and type-specific fields, player, turn, phase, source sequence, ownership, and
target rules all pass. Accepted commands are deep-copied into ordered
`accepted_command_history`; rejected inputs append a structured diagnostic
(`command`, stable rejection code, and message) and do not mutate gameplay
state, accepted history, or accepted source-sequence state.

The replay command stream is `accepted_command_history` only. `client_sequence`
is replayed in accepted arrival order and never used to reorder commands.

## Explicitly Deferred Commands

These intents are outside Milestone 1 and are not committed gameplay contracts:

- split stack
- cancel queued path
- set rally behavior

Friendly auto-merge is a deterministic movement-resolution rule, not a player
command. Diplomacy, lobbies, and P2P synchronization are post-M1 systems and do
not belong to this gameplay-command contract.

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
