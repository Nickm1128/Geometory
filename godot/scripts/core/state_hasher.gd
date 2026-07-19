class_name StateHasher
extends RefCounted

const PLAYER_FIELDS := ["id", "bank_cents", "research_health_bps", "research_damage_bps", "active_economy_bonus_bps", "next_economy_bonus_bps", "pending_soldiers", "capital_tile_id", "eliminated"]
const TILE_FIELDS := ["id", "q", "r", "region_id", "home_owner", "controlled_by", "capital_owner"]
const WALL_FIELDS := ["id", "owner", "from", "to", "hp", "max_hp", "destroyed"]
const STACK_FIELDS := ["id", "owner", "tile_id", "waypoints"]
const COHORT_FIELDS := ["cohort_id", "owner_id", "count", "spawn_turn", "max_health_per_soldier", "damage_mean_per_soldier", "damage_stddev_per_soldier", "current_total_health"]
const COMMON_COMMAND_FIELDS := ["type", "player_id", "turn", "phase", "client_sequence"]
const EVENT_FIELDS := {
  "income_added": ["type", "turn", "active_player", "player_id", "income", "bank_cents"],
  "allocation_applied": ["type", "turn", "active_player", "player_id", "economy_cents", "military_cents", "research_cents", "soldiers", "research_points", "next_bonus_bps"],
  "soldiers_spawned": ["type", "turn", "active_player", "player_id", "tile_id", "soldiers"],
  "path_queued": ["type", "turn", "active_player", "player_id", "stack_id", "waypoints"],
  "movement_blocked": ["type", "turn", "active_player", "stack_id", "player_id", "from", "to", "reason"],
  "stack_moved": ["type", "turn", "active_player", "stack_id", "player_id", "from", "to"],
  "wall_damaged": ["type", "turn", "active_player", "wall_id", "player_id", "damage", "hp"],
  "wall_destroyed": ["type", "turn", "active_player", "wall_id", "player_id", "damage"],
  "friendly_stacks_merged": ["type", "turn", "active_player", "owner", "tile_id", "destination_stack_id", "absorbed_stack_id"],
  "combat_exchange": ["type", "turn", "active_player", "tile_id", "attacker", "defender", "attacker_damage", "defender_damage"],
  "combat_resolved": ["type", "turn", "active_player", "tile_id", "winner", "previous_controller"],
  "tile_control_changed": ["type", "turn", "active_player", "tile_id", "from", "to"],
  "player_eliminated": ["type", "turn", "active_player", "player_id", "capturer_id"],
  "match_ended": ["type", "turn", "active_player", "winner", "turns", "reason"]
}

static func sha256(text: String) -> String:
  var context := HashingContext.new()
  context.start(HashingContext.HASH_SHA256)
  context.update(text.to_utf8_buffer())
  return context.finish().hex_encode()

static func canonical_json(value: Variant) -> String:
  match typeof(value):
    TYPE_NIL:
      return "null"
    TYPE_BOOL:
      return "true" if value else "false"
    TYPE_INT, TYPE_FLOAT, TYPE_STRING:
      return JSON.stringify(value)
    TYPE_ARRAY:
      var items: Array[String] = []
      for item in value:
        items.append(canonical_json(item))
      return "[" + ",".join(items) + "]"
    TYPE_DICTIONARY:
      var keys: Array = value.keys()
      keys.sort_custom(func(a, b): return String(a) < String(b))
      var entries: Array[String] = []
      for key in keys:
        entries.append(JSON.stringify(String(key)) + ":" + canonical_json(value[key]))
      return "{" + ",".join(entries) + "}"
    _:
      return JSON.stringify(str(value))

static func gameplay_projection(state: Dictionary) -> Dictionary:
  return {
    "schema_version": state.get("schema_version"),
    "seed": state.get("seed"),
    "ruleset_id": state.get("ruleset_id"),
    "ruleset_sha256": state.get("ruleset_sha256"),
    "map_id": state.get("map_id"),
    "map_sha256": state.get("map_sha256"),
    "rng_streams": state.get("rng_streams", {}).duplicate(true),
    "research_schedule_generation_version": state.get("research_schedule_generation_version"),
    "turn": state.get("turn"),
    "active_player": state.get("active_player"),
    "phase": state.get("phase"),
    "winner": state.get("winner"),
    "game_over": state.get("game_over"),
    "players": _project_records(state.get("players", {}), PLAYER_FIELDS),
    "tiles": _project_records(state.get("tiles", {}), TILE_FIELDS),
    "walls": _project_records(state.get("walls", {}), WALL_FIELDS),
    "stacks": _project_stacks(state.get("stacks", {})),
    "research_schedule": _project_records_array(state.get("research_schedule", []), ["health_bps_per_point", "damage_bps_per_point"]),
    "accepted_command_history": _project_commands(state.get("accepted_command_history", [])),
    "last_accepted_client_sequence": state.get("last_accepted_client_sequence", {}).duplicate(true),
    "replay_events": _project_events(state.get("replay_events", [])),
    "next_stack_index": state.get("next_stack_index"),
    "next_cohort_index": state.get("next_cohort_index")
  }

static func _pick(source: Dictionary, fields: Array) -> Dictionary:
  var result := {}
  for field in fields:
    if source.has(field):
      result[field] = source[field]
  return result

static func _project_records(records: Dictionary, fields: Array) -> Dictionary:
  var result := {}
  for record_id in records.keys():
    if typeof(records[record_id]) == TYPE_DICTIONARY:
      result[record_id] = _pick(records[record_id], fields)
  return result

static func _project_records_array(records: Array, fields: Array) -> Array:
  var result: Array = []
  for record in records:
    if typeof(record) == TYPE_DICTIONARY:
      result.append(_pick(record, fields))
  return result

static func _project_stacks(stacks: Dictionary) -> Dictionary:
  var result := {}
  for stack_id in stacks.keys():
    if typeof(stacks[stack_id]) != TYPE_DICTIONARY:
      continue
    var projected: Dictionary = _pick(stacks[stack_id], STACK_FIELDS)
    projected["cohorts"] = _project_records_array(stacks[stack_id].get("cohorts", []), COHORT_FIELDS)
    result[stack_id] = projected
  return result

static func _project_commands(commands: Array) -> Array:
  var result: Array = []
  for command in commands:
    if typeof(command) != TYPE_DICTIONARY:
      continue
    var fields: Array = COMMON_COMMAND_FIELDS.duplicate()
    match String(command.get("type", "")):
      "allocate_resources":
        fields.append_array(["economy_cents", "military_cents", "research_cents"])
      "queue_stack_path":
        fields.append_array(["stack_id", "waypoints", "mode"])
    result.append(_pick(command, fields))
  return result

static func _project_events(events: Array) -> Array:
  var result: Array = []
  for event in events:
    if typeof(event) != TYPE_DICTIONARY:
      continue
    var event_type := String(event.get("type", ""))
    result.append(_pick(event, EVENT_FIELDS.get(event_type, ["type", "turn", "active_player"])))
  return result
