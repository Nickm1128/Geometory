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

static func visible_tile_ids(state: Dictionary, player_id: String, neighbors_for_tile: Callable) -> Dictionary:
  var visible := {}
  for tile_id in state.get("tiles", {}).keys():
    var tile: Dictionary = state["tiles"][tile_id]
    if tile.get("controlled_by", "") != player_id:
      continue
    visible[tile_id] = true
    for neighbor_id in neighbors_for_tile.call(tile_id):
      visible[neighbor_id] = true
  for stack in state.get("stacks", {}).values():
    if stack.get("owner", "") == player_id:
      visible[stack.get("tile_id", "")] = true
  return visible

static func observable_state(state: Dictionary, rules: Dictionary, player_id: String, neighbors_for_tile: Callable) -> Dictionary:
  if not state.get("players", {}).has(player_id):
    return {}
  var visible := visible_tile_ids(state, player_id, neighbors_for_tile)
  var tiles := {}
  for tile_id in visible.keys():
    if state["tiles"].has(tile_id):
      tiles[tile_id] = state["tiles"][tile_id].duplicate(true)
  var stacks := {}
  for stack_id in state.get("stacks", {}).keys():
    var stack: Dictionary = state["stacks"][stack_id]
    if stack.get("owner", "") == player_id:
      stacks[stack_id] = stack.duplicate(true)
    elif visible.has(stack.get("tile_id", "")):
      stacks[stack_id] = _observable_enemy_stack(stack)
  var walls := {}
  for wall_id in state.get("walls", {}).keys():
    var wall: Dictionary = state["walls"][wall_id]
    if visible.has(wall.get("from", "")) or visible.has(wall.get("to", "")):
      walls[wall_id] = wall.duplicate(true)
  return {
    "seed": state.get("seed"),
    "turn": state.get("turn"),
    "active_player": state.get("active_player"),
    "phase": state.get("phase"),
    "player_id": player_id,
    "player": state["players"][player_id].duplicate(true),
    "tiles": tiles,
    "walls": walls,
    "stacks": stacks,
    "research_schedule": state.get("research_schedule", []).duplicate(true),
    "public_rules": rules.duplicate(true),
    "visible_events": _visible_events(state, player_id, visible)
  }

static func _observable_enemy_stack(stack: Dictionary) -> Dictionary:
  return {"id": stack["id"], "owner": stack["owner"], "tile_id": stack["tile_id"], "strength_band": strength_band(_stack_soldier_count(stack))}

static func _visible_events(state: Dictionary, player_id: String, visible: Dictionary) -> Array:
  var result: Array = []
  for event in state.get("replay_events", []):
    var is_visible := false
    if String(event.get("player_id", "")) == player_id:
      is_visible = true
    elif event.has("tile_id") and visible.has(String(event["tile_id"])):
      is_visible = true
    elif event.has("wall_id") and state.get("walls", {}).has(String(event["wall_id"])):
      var wall: Dictionary = state["walls"][String(event["wall_id"])]
      is_visible = visible.has(String(wall["from"])) or visible.has(String(wall["to"]))
    if is_visible:
      var projected := project_visible_event(event)
      if not projected.is_empty():
        result.append(projected)
  return result

static func _stack_soldier_count(stack: Dictionary) -> int:
  var total := 0
  for cohort in stack.get("cohorts", []):
    total += int(cohort.get("count", 0))
  return total
