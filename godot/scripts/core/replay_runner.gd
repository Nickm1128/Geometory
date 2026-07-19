class_name ReplayRunner
extends RefCounted

const GameCoreScript = preload("res://scripts/core/game_core.gd")

static func reconstruct(record: Dictionary, rules: Dictionary, map_config: Dictionary) -> Dictionary:
  var envelope := _validate_envelope(record)
  if not bool(envelope["ok"]):
    return envelope
  var setup: Dictionary = record["setup"]
  var core = GameCoreScript.new()
  core.setup(rules, map_config, int(setup["seed"]))
  var initial: Dictionary = core.snapshot()
  if String(setup["ruleset_id"]) != String(initial["ruleset_id"]) or String(setup["ruleset_sha256"]) != String(initial["ruleset_sha256"]) or String(setup["map_id"]) != String(initial["map_id"]) or String(setup["map_sha256"]) != String(initial["map_sha256"]):
    return _failure("stale_config", "replay setup does not match loaded rules or map")
  if setup["rng_streams"] != initial["rng_streams"] or setup["research_schedule_generation_version"] != initial["research_schedule_generation_version"] or setup["research_schedule"] != initial["research_schedule"] or setup["players"] != _player_setup(initial["players"]):
    return _failure("stale_config", "replay deterministic setup does not match loaded configuration")
  var step_states: Array = []
  for index in range(record["steps"].size()):
    var step: Variant = record["steps"][index]
    if typeof(step) != TYPE_DICTIONARY or typeof(step.get("command")) != TYPE_DICTIONARY or typeof(step.get("state_hash")) != TYPE_STRING:
      return _failure("truncated_record", "replay step is incomplete", index)
    var result: Dictionary = core.apply_command(step["command"])
    if not bool(result.get("ok", false)):
      return _failure("illegal_command", String(result.get("code", "rejected_command")), index)
    var actual_hash := core.canonical_state_hash()
    if actual_hash != String(step["state_hash"]):
      return _failure("step_hash_mismatch", "replay step hash does not match", index)
    step_states.append(core.snapshot())
  var final: Dictionary = record["final"]
  var final_hash := core.canonical_state_hash()
  if final_hash != String(final["state_hash"]):
    return _failure("final_hash_mismatch", "replay final hash does not match")
  var state: Dictionary = core.snapshot()
  var is_draw := bool(state["game_over"]) and String(state["winner"]).is_empty()
  if String(final["winner"]) != String(state["winner"]) or bool(final["is_draw"]) != is_draw:
    return _failure("final_outcome_mismatch", "replay winner or draw state does not match")
  return {"ok": true, "code": "", "message": "", "state": state, "step_states": step_states, "final_hash": final_hash}

static func _validate_envelope(record: Dictionary) -> Dictionary:
  if String(record.get("format", "")) != "GMTY1" or int(record.get("format_version", 0)) != 1:
    return _failure("unsupported_version", "replay format or version is unsupported")
  if typeof(record.get("setup")) != TYPE_DICTIONARY or typeof(record.get("steps")) != TYPE_ARRAY or typeof(record.get("final")) != TYPE_DICTIONARY:
    return _failure("truncated_record", "replay envelope is incomplete")
  var setup: Dictionary = record["setup"]
  for field in ["ruleset_id", "ruleset_sha256", "map_id", "map_sha256", "seed", "rng_streams", "research_schedule_generation_version", "research_schedule", "players"]:
    if not setup.has(field):
      return _failure("truncated_record", "replay setup is missing %s" % field)
  var final: Dictionary = record["final"]
  for field in ["state_hash", "winner", "is_draw"]:
    if not final.has(field):
      return _failure("truncated_record", "replay final section is missing %s" % field)
  return {"ok": true, "code": "", "message": ""}

static func _player_setup(players: Dictionary) -> Dictionary:
  var result := {}
  for player_id in players.keys():
    var player: Dictionary = players[player_id]
    result[player_id] = {"id": player.get("id", player_id), "is_bot": bool(player.get("is_bot", false))}
  return result

static func _failure(code: String, message: String, step_index: int = -1) -> Dictionary:
  var result := {"ok": false, "code": code, "message": message}
  if step_index >= 0:
    result["step_index"] = step_index
  return result
