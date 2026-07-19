class_name MovementRules
extends RefCounted

static func executed_edge_is_valid(state: Dictionary, from_tile: String, to_tile: String, neighbors: Array) -> bool:
  return state.get("tiles", {}).has(to_tile) and neighbors.has(to_tile)

static func friendly_merge_destination(first_stack_id: String, second_stack_id: String) -> String:
  return first_stack_id if first_stack_id < second_stack_id else second_stack_id

static func cohort_id_order(cohort_id: String) -> int:
  if cohort_id.length() > 1 and cohort_id.substr(0, 1) == "C" and cohort_id.substr(1).is_valid_int():
    return int(cohort_id.substr(1))
  return 2147483647

static func resolve_player_movement(state: Dictionary, player_id: String, neighbors_for_tile: Callable, wall_blocking: Callable, attack_wall: Callable, emit_event: Callable) -> void:
  var stack_ids: Array = state.get("stacks", {}).keys()
  stack_ids.sort()
  for stack_id in stack_ids:
    if not state["stacks"].has(stack_id):
      continue
    var stack: Dictionary = state["stacks"][stack_id]
    if stack.get("owner", "") != player_id or stack.get("waypoints", []).is_empty():
      continue
    var from_tile := String(stack["tile_id"])
    var to_tile := String(stack["waypoints"][0])
    if not executed_edge_is_valid(state, from_tile, to_tile, neighbors_for_tile.call(from_tile)):
      emit_event.call("movement_blocked", {"stack_id": stack_id, "player_id": player_id, "from": from_tile, "to": to_tile, "reason": "invalid_edge"})
      continue
    var wall_id := "%s|%s" % [from_tile, to_tile] if from_tile < to_tile else "%s|%s" % [to_tile, from_tile]
    if wall_blocking.call(wall_id, player_id):
      attack_wall.call(stack_id, wall_id)
      continue
    stack["tile_id"] = to_tile
    stack["waypoints"].pop_front()
    emit_event.call("stack_moved", {"stack_id": stack_id, "player_id": player_id, "from": from_tile, "to": to_tile})

static func merge_same_owner_stacks(state: Dictionary, emit_event: Callable) -> void:
  var seen := {}
  var stack_ids: Array = state.get("stacks", {}).keys()
  stack_ids.sort()
  for stack_id in stack_ids:
    if not state["stacks"].has(stack_id):
      continue
    var stack: Dictionary = state["stacks"][stack_id]
    var key := "%s@%s" % [stack["owner"], stack["tile_id"]]
    if not seen.has(key):
      seen[key] = stack_id
      continue
    var target_id := String(seen[key])
    var target: Dictionary = state["stacks"][target_id]
    for cohort in stack["cohorts"]:
      target["cohorts"].append(cohort)
    target["cohorts"].sort_custom(func(a: Dictionary, b: Dictionary): return cohort_id_order(String(a["cohort_id"])) < cohort_id_order(String(b["cohort_id"])))
    target["waypoints"] = []
    state["stacks"].erase(stack_id)
    emit_event.call("friendly_stacks_merged", {"owner": target["owner"], "tile_id": target["tile_id"], "destination_stack_id": target_id, "absorbed_stack_id": stack_id})
