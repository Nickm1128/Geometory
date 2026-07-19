class_name FogRules
extends RefCounted

const VISIBLE_EVENT_FIELDS := {
  "income_added": ["type", "turn", "active_player", "player_id", "income", "bank_cents"],
  "allocation_applied": ["type", "turn", "active_player", "player_id"],
  "soldiers_spawned": ["type", "turn", "active_player", "player_id", "tile_id"],
  "path_queued": ["type", "turn", "active_player", "player_id", "stack_id"],
  "movement_blocked": ["type", "turn", "active_player", "stack_id", "player_id", "from", "to", "reason"],
  "stack_moved": ["type", "turn", "active_player", "stack_id", "player_id", "from", "to"],
  "wall_damaged": ["type", "turn", "active_player", "wall_id", "player_id", "hp"],
  "wall_destroyed": ["type", "turn", "active_player", "wall_id", "player_id"],
  "friendly_stacks_merged": ["type", "turn", "active_player", "owner", "tile_id", "destination_stack_id", "absorbed_stack_id"],
  "combat_exchange": ["type", "turn", "active_player", "tile_id", "attacker", "defender"],
  "combat_resolved": ["type", "turn", "active_player", "tile_id", "winner", "previous_controller"],
  "tile_control_changed": ["type", "turn", "active_player", "tile_id", "from", "to"],
  "player_eliminated": ["type", "turn", "active_player", "player_id", "capturer_id"],
  "match_ended": ["type", "turn", "active_player", "winner", "turns", "reason"]
}

static func strength_band(soldiers: int) -> String:
  if soldiers <= 2:
    return "tiny"
  if soldiers <= 5:
    return "small"
  if soldiers <= 10:
    return "medium"
  if soldiers <= 20:
    return "large"
  return "overwhelming"

static func project_visible_event(event: Dictionary) -> Dictionary:
  var event_type := String(event.get("type", ""))
  if not VISIBLE_EVENT_FIELDS.has(event_type):
    return {}
  var result := {}
  for field in VISIBLE_EVENT_FIELDS[event_type]:
    if event.has(field):
      result[field] = event[field]
  return result
