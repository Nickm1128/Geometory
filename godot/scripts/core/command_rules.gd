class_name CommandRules
extends RefCounted

static func missing_common_field(command: Dictionary) -> String:
  for key in ["type", "player_id", "turn", "phase", "client_sequence"]:
    if not command.has(key):
      return key
  return ""

static func is_valid_path_mode(mode: Variant) -> bool:
  return typeof(mode) == TYPE_STRING and String(mode) in ["append", "replace"]

static func validate_command(state: Dictionary, command: Dictionary, stack_health: Callable) -> Dictionary:
  if state.get("game_over", false):
    return _failure("match_over", "match is over")
  var missing_field := missing_common_field(command)
  if not missing_field.is_empty():
    return _failure("missing_%s" % missing_field, "missing required field: %s" % missing_field)
  if typeof(command["type"]) != TYPE_STRING or String(command["type"]).is_empty():
    return _failure("invalid_type", "type must be a non-empty string")
  if typeof(command["player_id"]) != TYPE_STRING or not state.get("players", {}).has(command["player_id"]):
    return _failure("invalid_player", "player_id must name a known player")
  if typeof(command["turn"]) != TYPE_INT or int(command["turn"]) != int(state.get("turn", 0)):
    return _failure("wrong_turn", "command turn does not match current turn")
  if typeof(command["phase"]) != TYPE_STRING or String(command["phase"]) != String(state.get("phase", "")):
    return _failure("wrong_phase", "command phase does not match current phase")
  var player_id := String(command["player_id"])
  if player_id != String(state.get("active_player", "")):
    return _failure("inactive_player", "not active player")
  if typeof(command["client_sequence"]) != TYPE_INT or int(command["client_sequence"]) <= 0:
    return _failure("invalid_client_sequence", "client_sequence must be a positive integer")
  if int(command["client_sequence"]) <= int(state.get("last_accepted_client_sequence", {}).get(player_id, 0)):
    return _failure("stale_client_sequence", "client_sequence must increase after the last accepted command")
  match String(command["type"]):
    "allocate_resources":
      var total := 0
      for key in ["economy_cents", "military_cents", "research_cents"]:
        if not command.has(key) or typeof(command[key]) != TYPE_INT or int(command[key]) < 0:
          return _failure("invalid_%s" % key, "%s must be a non-negative integer" % key)
        total += int(command[key])
      if total > int(state["players"][player_id]["bank_cents"]):
        return _failure("spend_exceeds_bank", "spend exceeds bank")
    "queue_stack_path":
      if not command.has("stack_id") or typeof(command["stack_id"]) != TYPE_STRING or not state.get("stacks", {}).has(command["stack_id"]):
        return _failure("invalid_stack", "stack_id must name a living owned stack")
      var stack: Dictionary = state["stacks"][command["stack_id"]]
      if String(stack["owner"]) != player_id or int(stack_health.call(stack)) <= 0:
        return _failure("invalid_stack", "stack_id must name a living owned stack")
      if not command.has("mode") or not is_valid_path_mode(command["mode"]):
        return _failure("invalid_path_mode", "mode must be append or replace")
      if not command.has("waypoints") or typeof(command["waypoints"]) != TYPE_ARRAY:
        return _failure("invalid_waypoints", "waypoints must be an array")
      var seen := {}
      for waypoint in command["waypoints"]:
        if typeof(waypoint) != TYPE_STRING or not state.get("tiles", {}).has(waypoint):
          return _failure("invalid_waypoint", "each waypoint must name a known tile")
        if seen.has(waypoint):
          return _failure("duplicate_waypoint", "waypoints must not repeat a tile")
        seen[waypoint] = true
    "end_phase":
      pass
    _:
      return _failure("unknown_command", "unknown command")
  return {"ok": true, "code": "", "message": ""}

static func _failure(code: String, message: String) -> Dictionary:
  return {"ok": false, "code": code, "message": message}
