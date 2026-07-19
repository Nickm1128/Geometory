class_name ReplayCodec
extends RefCounted

const StateHasher = preload("res://scripts/core/state_hasher.gd")

const FORMAT := "GMTY1"
const FORMAT_VERSION := 1

static func from_match(state: Dictionary, final_state_hash: String) -> Dictionary:
  return {
    "format": FORMAT,
    "format_version": FORMAT_VERSION,
    "setup": _setup_projection(state),
    "steps": _steps_projection(state.get("accepted_command_history", [])),
    "final": {
      "state_hash": final_state_hash,
      "winner": state.get("winner", ""),
      "is_draw": bool(state.get("game_over", false)) and String(state.get("winner", "")).is_empty()
    }
  }

static func serialize(record: Dictionary) -> String:
  return StateHasher.canonical_json(record)

static func parse(text: String) -> Dictionary:
  var json := JSON.new()
  if json.parse(text) != OK:
    return _failure("malformed_json", "GMTY1 record is not valid JSON")
  if typeof(json.data) != TYPE_DICTIONARY:
    return _failure("invalid_envelope", "GMTY1 envelope must be an object")
  var record: Dictionary = _normalize_json(json.data)
  if String(record.get("format", "")) != FORMAT:
    return _failure("unsupported_format", "record format is not GMTY1")
  if typeof(record.get("format_version")) not in [TYPE_INT, TYPE_FLOAT] or int(record["format_version"]) != FORMAT_VERSION:
    return _failure("unsupported_version", "GMTY1 format version is unsupported")
  if typeof(record.get("setup")) != TYPE_DICTIONARY or typeof(record.get("steps")) != TYPE_ARRAY or typeof(record.get("final")) != TYPE_DICTIONARY:
    return _failure("invalid_envelope", "GMTY1 requires setup, steps, and final sections")
  return {"ok": true, "code": "", "message": "", "record": record}

static func _setup_projection(state: Dictionary) -> Dictionary:
  return {
    "ruleset_id": state.get("ruleset_id", ""),
    "ruleset_sha256": state.get("ruleset_sha256", ""),
    "map_id": state.get("map_id", ""),
    "map_sha256": state.get("map_sha256", ""),
    "seed": state.get("seed"),
    "rng_streams": state.get("rng_streams", {}).duplicate(true),
    "research_schedule_generation_version": state.get("research_schedule_generation_version", ""),
    "research_schedule": state.get("research_schedule", []).duplicate(true),
    "players": _player_setup(state.get("players", {}))
  }

static func _player_setup(players: Dictionary) -> Dictionary:
  var result := {}
  for player_id in players.keys():
    var player: Dictionary = players[player_id]
    result[player_id] = {"id": player.get("id", player_id), "is_bot": bool(player.get("is_bot", false))}
  return result

static func _steps_projection(history: Array) -> Array:
  var steps: Array = []
  for accepted in history:
    if typeof(accepted) != TYPE_DICTIONARY:
      continue
    var command: Dictionary = accepted.duplicate(true)
    var state_hash := String(command.get("state_hash", ""))
    command.erase("state_hash")
    steps.append({"command": command, "state_hash": state_hash})
  return steps

static func _failure(code: String, message: String) -> Dictionary:
  return {"ok": false, "code": code, "message": message}

static func _normalize_json(value: Variant) -> Variant:
  if typeof(value) == TYPE_FLOAT and floor(float(value)) == float(value):
    return int(value)
  if typeof(value) == TYPE_ARRAY:
    var result: Array = []
    for item in value:
      result.append(_normalize_json(item))
    return result
  if typeof(value) == TYPE_DICTIONARY:
    var result := {}
    for key in value.keys():
      result[String(key)] = _normalize_json(value[key])
    return result
  return value
