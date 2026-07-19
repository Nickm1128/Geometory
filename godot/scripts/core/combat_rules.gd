class_name CombatRules
extends RefCounted

static func defender_for(controller: String, live_owners: Array) -> String:
  if live_owners.has(controller):
    return controller
  var ordered: Array = live_owners.duplicate()
  ordered.sort()
  return String(ordered[0]) if not ordered.is_empty() else ""

static func attacker_for(defender: String, live_owners: Array) -> String:
  var ordered: Array = live_owners.duplicate()
  ordered.sort()
  for owner in ordered:
    if String(owner) != defender:
      return String(owner)
  return ""

static func resolve_all_combats(state: Dictionary, rules: Dictionary, roll_damage: Callable, emit_event: Callable) -> void:
  var tiles_to_owners := {}
  for stack in state.get("stacks", {}).values():
    var tile_id := String(stack["tile_id"])
    if not tiles_to_owners.has(tile_id):
      tiles_to_owners[tile_id] = {}
    tiles_to_owners[tile_id][stack["owner"]] = true
  var tile_ids: Array = tiles_to_owners.keys()
  tile_ids.sort()
  for tile_id in tile_ids:
    if tiles_to_owners[tile_id].keys().size() < 2:
      continue
    var exchange := 0
    while living_owners_on_tile(state, tile_id).size() > 1 and exchange < int(rules["combat"]["max_exchanges_per_tile_per_turn"]):
      var live_owners := living_owners_on_tile(state, tile_id)
      live_owners.sort()
      var defender := defender_for(String(state["tiles"][tile_id]["controlled_by"]), live_owners)
      var attacker := attacker_for(defender, live_owners)
      var defender_stack_id := stack_id_on_tile(state, tile_id, defender)
      var attacker_stack_id := stack_id_on_tile(state, tile_id, attacker)
      if defender_stack_id.is_empty() or attacker_stack_id.is_empty():
        break
      var attacker_stack: Dictionary = state["stacks"][attacker_stack_id]
      var defender_stack: Dictionary = state["stacks"][defender_stack_id]
      var operation_salt := combat_operation_salt(tile_id, exchange, attacker_stack, defender_stack)
      var attacker_damage := int(roll_damage.call(attacker_stack, "%s|attacker" % operation_salt))
      var defender_damage := int(roll_damage.call(defender_stack, "%s|defender" % operation_salt))
      apply_damage(state, defender_stack_id, attacker_damage)
      apply_damage(state, attacker_stack_id, defender_damage)
      emit_event.call("combat_exchange", {"tile_id": tile_id, "attacker": attacker_stack["owner"], "defender": defender_stack["owner"], "attacker_damage": attacker_damage, "defender_damage": defender_damage})
      exchange += 1
    var survivors := living_owners_on_tile(state, tile_id)
    if survivors.size() == 1:
      emit_event.call("combat_resolved", {"tile_id": tile_id, "winner": String(survivors[0]), "previous_controller": state["tiles"][tile_id]["controlled_by"]})

static func apply_post_resolution_control(state: Dictionary, emit_event: Callable) -> void:
  var tile_ids: Array = state.get("tiles", {}).keys()
  tile_ids.sort()
  for tile_id in tile_ids:
    var owners := living_owners_on_tile(state, tile_id)
    owners.sort()
    if owners.size() != 1:
      continue
    var controller := String(owners[0])
    var previous := String(state["tiles"][tile_id]["controlled_by"])
    if controller != previous:
      state["tiles"][tile_id]["controlled_by"] = controller
      emit_event.call("tile_control_changed", {"tile_id": tile_id, "from": previous, "to": controller})

static func apply_damage(state: Dictionary, stack_id: String, damage: int) -> void:
  if not state.get("stacks", {}).has(stack_id):
    return
  var stack: Dictionary = state["stacks"][stack_id]
  var remaining := damage
  for cohort in stack["cohorts"]:
    if remaining <= 0: break
    var health := int(cohort["current_total_health"])
    var applied: int = min(health, remaining)
    cohort["current_total_health"] = health - applied
    remaining -= applied
    cohort["count"] = int(ceil(float(cohort["current_total_health"]) / float(max(1, int(cohort["max_health_per_soldier"])))) )
  var alive: Array = []
  for cohort in stack["cohorts"]:
    if int(cohort["current_total_health"]) > 0 and int(cohort["count"]) > 0: alive.append(cohort)
  stack["cohorts"] = alive
  if alive.is_empty(): state["stacks"].erase(stack_id)

static func stack_id_on_tile(state: Dictionary, tile_id: String, owner: String) -> String:
  for stack_id in state.get("stacks", {}).keys():
    var stack: Dictionary = state["stacks"][stack_id]
    if stack["tile_id"] == tile_id and stack["owner"] == owner: return String(stack_id)
  return ""

static func living_owners_on_tile(state: Dictionary, tile_id: String) -> Array:
  var owners := {}
  for stack in state.get("stacks", {}).values():
    if stack["tile_id"] == tile_id and stack_health(stack) > 0: owners[stack["owner"]] = true
  return owners.keys()

static func stack_health(stack: Dictionary) -> int:
  var total := 0
  for cohort in stack.get("cohorts", []): total += int(cohort["current_total_health"])
  return total

static func combat_operation_salt(tile_id: String, exchange: int, attacker_stack: Dictionary, defender_stack: Dictionary) -> String:
  return "tile:%s|exchange:%d|attacker:%s|defender:%s" % [tile_id, exchange, _cohort_id_key(attacker_stack), _cohort_id_key(defender_stack)]

static func _cohort_id_key(stack: Dictionary) -> String:
  var cohort_ids: Array[String] = []
  for cohort in stack.get("cohorts", []):
    cohort_ids.append(String(cohort.get("cohort_id", "")))
  cohort_ids.sort()
  return ",".join(cohort_ids)
