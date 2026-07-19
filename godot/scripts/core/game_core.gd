class_name GameCore
extends RefCounted

const HexUtils = preload("res://scripts/core/hex_utils.gd")
const StateHasher = preload("res://scripts/core/state_hasher.gd")
const TurnResolver = preload("res://scripts/core/turn_resolver.gd")
const MovementRules = preload("res://scripts/core/movement_rules.gd")
const CombatRules = preload("res://scripts/core/combat_rules.gd")
const CommandRules = preload("res://scripts/core/command_rules.gd")
const FogRules = preload("res://scripts/core/fog_rules.gd")
const RngRules = preload("res://scripts/core/rng_rules.gd")

const PLAYER_HUMAN = "P1"
const PLAYER_BOT = "P2"
const NEUTRAL = "neutral"
const PHASE_ALLOCATION = "allocation"
const PHASE_MOVEMENT = "movement"

var rules: Dictionary = {}
var map_config: Dictionary = {}
var state: Dictionary = {}

func setup(new_rules: Dictionary, new_map_config: Dictionary, seed: int) -> void:
  rules = new_rules.duplicate(true)
  map_config = new_map_config.duplicate(true)
  state = {
    "schema_version": 1,
    "seed": seed,
    "turn": 1,
    "active_player": PLAYER_HUMAN,
    "phase": "setup",
    "winner": "",
    "game_over": false,
    "tiles": {},
    "walls": {},
    "players": {},
    "stacks": {},
    "research_schedule": [],
    "research_schedule_generation_version": String(rules.get("research", {}).get("schedule_generation_version", "research_schedule_v1")),
    "rng_streams": {
      "derivation_version": "fnv1a32_seed_mix_v1",
      "research": {"stream_id": "research", "purpose": "public_research_schedule", "salt_namespace": "research_schedule_v1"},
      "combat": {"stream_id": "combat", "purpose": "combat_damage_rolls", "salt_namespace": "combat_roll_v1"},
      "bot": {"stream_id": "bot", "purpose": "bot_policy_tiebreaks", "salt_namespace": "bot_policy_v1"}
    },
    "replay_events": [],
    "accepted_command_history": [],
    "rejected_command_diagnostics": [],
    "last_accepted_client_sequence": {PLAYER_HUMAN: 0, PLAYER_BOT: 0},
    "next_stack_index": 1,
    "next_cohort_index": 1
  }
  state["ruleset_id"] = String(rules.get("ruleset_id", "unknown"))
  state["ruleset_sha256"] = StateHasher.sha256(StateHasher.canonical_json(rules))
  state["map_id"] = String(map_config.get("map_id", "unknown"))
  state["map_sha256"] = StateHasher.sha256(StateHasher.canonical_json(map_config))
  _generate_research_schedule()
  _generate_alpha_medium_map()
  _create_players()
  _create_starting_stacks()
  _begin_player_turn(PLAYER_HUMAN)

func snapshot() -> Dictionary:
  return state.duplicate(true)

func canonical_state_hash() -> String:
  return StateHasher.sha256(StateHasher.canonical_json(StateHasher.gameplay_projection(state)))

func get_player_ids() -> Array[String]:
  return [PLAYER_HUMAN, PLAYER_BOT]

func is_human_turn() -> bool:
  return state.get("active_player", "") == PLAYER_HUMAN and not state.get("game_over", false)

func is_bot_turn() -> bool:
  return state.get("active_player", "") == PLAYER_BOT and not state.get("game_over", false)

func get_active_player() -> String:
  return state.get("active_player", PLAYER_HUMAN)

func get_phase() -> String:
  return state.get("phase", PHASE_ALLOCATION)

func get_bank(player_id: String) -> int:
  return int(state["players"][player_id]["bank_cents"])

func money_text(cents: int) -> String:
  return "$%.2f" % (float(cents) / 100.0)

func calculate_income(player_id: String) -> Dictionary:
  var own = 0
  var foreign = 0
  for tile in state["tiles"].values():
    if tile["controlled_by"] != player_id:
      continue
    if tile["home_owner"] == player_id:
      own += int(rules["income"]["own_home_tile_cents"])
    else:
      foreign += int(rules["income"]["foreign_or_neutral_tile_cents"])
  var base = own + foreign
  var bonus = int(state["players"][player_id].get("active_economy_bonus_bps", 0))
  var final_income = int(floor(float(base * (10000 + bonus)) / 10000.0))
  return {"own": own, "foreign": foreign, "base": base, "bonus_bps": bonus, "final": final_income}

func apply_command(command: Dictionary) -> Dictionary:
  var validation := _validate_command(command)
  if not bool(validation["ok"]):
    return _reject_command(command, String(validation["code"]), String(validation["message"]))
  var command_type: String = command["type"]
  var result: Dictionary = {}
  match command_type:
    "allocate_resources":
      result = _apply_allocate(command)
    "queue_stack_path":
      result = _apply_queue_path(command)
    "end_phase":
      result = _apply_end_phase(command)
    _:
      return _reject_command(command, "unknown_command", "unknown command")
  if not bool(result["ok"]):
    return _reject_command(command, "resolution_rejected", String(result["message"]))
  _accept_command(command)
  return result

func _validate_command(command: Dictionary) -> Dictionary:
  return CommandRules.validate_command(state, command, _stack_health)

func _accept_command(command: Dictionary) -> void:
  var accepted: Dictionary = command.duplicate(true)
  state["accepted_command_history"].append(accepted)
  state["last_accepted_client_sequence"][accepted["player_id"]] = accepted["client_sequence"]

func _reject_command(command: Dictionary, code: String, message: String) -> Dictionary:
  state["rejected_command_diagnostics"].append({
    "command": command.duplicate(true),
    "code": code,
    "message": message,
    "turn": state.get("turn", 0),
    "phase": state.get("phase", "")
  })
  return _command_result(false, message, code)

func visible_tile_ids(player_id: String) -> Dictionary:
  return FogRules.visible_tile_ids(state, player_id, get_neighbor_tile_ids)

func observable_state(player_id: String) -> Dictionary:
  return FogRules.observable_state(state, rules, player_id, get_neighbor_tile_ids)

func get_neighbor_tile_ids(tile_id: String) -> Array[String]:
  var coord = HexUtils.parse_tile_id(tile_id)
  var result: Array[String] = []
  for neighbor in HexUtils.neighbors(coord):
    var nid = HexUtils.tile_id(neighbor.x, neighbor.y)
    if state["tiles"].has(nid):
      result.append(nid)
  return result

func find_path(start_tile_id: String, end_tile_id: String) -> Array[String]:
  if start_tile_id == end_tile_id:
    return []
  if not state["tiles"].has(start_tile_id) or not state["tiles"].has(end_tile_id):
    return []
  var frontier: Array[String] = [start_tile_id]
  var came_from = {start_tile_id: ""}
  var cursor = 0
  while cursor < frontier.size():
    var current = frontier[cursor]
    cursor += 1
    if current == end_tile_id:
      break
    for next_id in get_neighbor_tile_ids(current):
      if came_from.has(next_id):
        continue
      came_from[next_id] = current
      frontier.append(next_id)
  if not came_from.has(end_tile_id):
    return []
  var path: Array[String] = []
  var cur = end_tile_id
  while cur != start_tile_id:
    path.push_front(cur)
    cur = String(came_from[cur])
  return path

func get_stack_at_tile_for_player(tile_id: String, player_id: String) -> String:
  for stack_id in state["stacks"].keys():
    var stack: Dictionary = state["stacks"][stack_id]
    if stack["tile_id"] == tile_id and stack["owner"] == player_id:
      return stack_id
  return ""

func get_top_replay_lines(count: int = 6) -> Array[String]:
  var lines: Array[String] = []
  var events: Array = state.get("replay_events", [])
  var start = max(0, events.size() - count)
  for i in range(start, events.size()):
    lines.append(_event_to_text(events[i]))
  return lines

func _apply_allocate(command: Dictionary) -> Dictionary:
  var player_id = String(command["player_id"])
  var economy = max(0, int(command.get("economy_cents", 0)))
  var military = max(0, int(command.get("military_cents", 0)))
  var research = max(0, int(command.get("research_cents", 0)))
  var total = economy + military + research
  var player: Dictionary = state["players"][player_id]
  if total > int(player["bank_cents"]):
    return _command_result(false, "spend exceeds bank")
  player["bank_cents"] = int(player["bank_cents"]) - total
  var economy_units = int(floor(float(economy) / float(rules["economy"]["economy_bonus_unit_cost_cents"])))
  var next_bonus = min(
    economy_units * int(rules["economy"]["economy_bonus_bps_per_unit"]),
    int(rules["economy"]["economy_bonus_cap_bps"])
  )
  if bool(rules["economy"].get("compounds", false)):
    player["next_economy_bonus_bps"] = int(player["next_economy_bonus_bps"]) + next_bonus
  else:
    player["next_economy_bonus_bps"] = next_bonus
  var research_points = int(floor(float(research) / float(rules["research"]["research_point_cost_cents"])))
  var schedule: Dictionary = state["research_schedule"][min(int(state["turn"]) - 1, state["research_schedule"].size() - 1)]
  player["research_health_bps"] = min(
    int(player["research_health_bps"]) + research_points * int(schedule["health_bps_per_point"]),
    int(rules["research"]["max_total_health_bonus_bps"])
  )
  player["research_damage_bps"] = min(
    int(player["research_damage_bps"]) + research_points * int(schedule["damage_bps_per_point"]),
    int(rules["research"]["max_total_damage_bonus_bps"])
  )
  var soldiers = int(floor(float(military) / float(rules["military"]["soldier_cost_cents"])))
  player["pending_soldiers"] = int(player["pending_soldiers"]) + soldiers
  _event("allocation_applied", {
    "player_id": player_id,
    "economy_cents": economy,
    "military_cents": military,
    "research_cents": research,
    "soldiers": soldiers,
    "research_points": research_points,
    "next_bonus_bps": player["next_economy_bonus_bps"]
  })
  state["phase"] = PHASE_MOVEMENT
  return _command_result(true, "allocation applied")

func _apply_queue_path(command: Dictionary) -> Dictionary:
  var player_id = String(command["player_id"])
  var stack_id = String(command.get("stack_id", ""))
  if not state["stacks"].has(stack_id):
    return _command_result(false, "missing stack")
  var stack: Dictionary = state["stacks"][stack_id]
  if stack["owner"] != player_id:
    return _command_result(false, "stack not owned")
  var mode = String(command.get("mode", "append"))
  var input_waypoints: Array = command.get("waypoints", [])
  var queue: Array = []
  if mode == "append":
    queue = stack.get("waypoints", []).duplicate()
  var current = String(stack["tile_id"])
  if queue.size() > 0:
    current = String(queue[queue.size() - 1])
  for waypoint in input_waypoints:
    var target = String(waypoint)
    var path = find_path(current, target)
    for step in path:
      queue.append(step)
    current = target
  var max_waypoints = int(rules["movement"]["path_queue_max_waypoints"])
  if queue.size() > max_waypoints:
    queue = queue.slice(0, max_waypoints)
  stack["waypoints"] = queue
  _event("path_queued", {"player_id": player_id, "stack_id": stack_id, "waypoints": queue.duplicate()})
  return _command_result(true, "path queued")

func _apply_end_phase(command: Dictionary) -> Dictionary:
  var player_id = String(command["player_id"])
  if state["phase"] == PHASE_ALLOCATION:
    state["phase"] = PHASE_MOVEMENT
    return _command_result(true, "movement phase")
  TurnResolver.resolve_end_phase(state, rules, player_id, PLAYER_HUMAN, PLAYER_BOT, _resolve_player_movement, _merge_same_owner_stacks, _resolve_all_combats, _apply_post_resolution_control, _check_eliminations, _begin_player_turn, _end_match_as_draw)
  return _command_result(true, "turn ended")

func _generate_research_schedule() -> void:
  state["research_schedule"] = []
  var turns = int(rules["research"].get("schedule_turns_to_generate", 80))
  for i in range(turns):
    var turn_index = i + 1
    var h = RngRules.deterministic_range(int(state["seed"]), state["rng_streams"], "research", "turn:%d:health" % turn_index, int(rules["research"]["health_bps_per_point_min"]), int(rules["research"]["health_bps_per_point_max"]))
    var d = RngRules.deterministic_range(int(state["seed"]), state["rng_streams"], "research", "turn:%d:damage" % turn_index, int(rules["research"]["damage_bps_per_point_min"]), int(rules["research"]["damage_bps_per_point_max"]))
    state["research_schedule"].append({"health_bps_per_point": h, "damage_bps_per_point": d})

func _generate_alpha_medium_map() -> void:
  var radius = int(map_config.get("board_radius", 6))
  var home_radius = int(map_config.get("home_radius", 2))
  var p1_center = Vector2i(-4, 0)
  var p2_center = Vector2i(4, 0)
  for region in map_config.get("regions", []):
    if region.get("home_owner", "") == PLAYER_HUMAN:
      p1_center = Vector2i(int(region["center"]["q"]), int(region["center"]["r"]))
    elif region.get("home_owner", "") == PLAYER_BOT:
      p2_center = Vector2i(int(region["center"]["q"]), int(region["center"]["r"]))
  for q in range(-radius, radius + 1):
    var r_min = max(-radius, -q - radius)
    var r_max = min(radius, -q + radius)
    for r in range(r_min, r_max + 1):
      var coord = Vector2i(q, r)
      var owner = NEUTRAL
      var region_id = "R_NEUTRAL_CENTER"
      if HexUtils.distance(coord, p1_center) <= home_radius:
        owner = PLAYER_HUMAN
        region_id = "R_HOME_P1"
      elif HexUtils.distance(coord, p2_center) <= home_radius:
        owner = PLAYER_BOT
        region_id = "R_HOME_P2"
      var id = HexUtils.tile_id(q, r)
      state["tiles"][id] = {
        "id": id,
        "q": q,
        "r": r,
        "region_id": region_id,
        "home_owner": owner,
        "controlled_by": owner,
        "capital_owner": ""
      }
  var p1_cap = HexUtils.tile_id(p1_center.x, p1_center.y)
  var p2_cap = HexUtils.tile_id(p2_center.x, p2_center.y)
  state["tiles"][p1_cap]["capital_owner"] = PLAYER_HUMAN
  state["tiles"][p2_cap]["capital_owner"] = PLAYER_BOT
  _generate_home_walls()

func _generate_home_walls() -> void:
  for tile_id in state["tiles"].keys():
    var tile: Dictionary = state["tiles"][tile_id]
    var owner = String(tile["home_owner"])
    if owner == NEUTRAL:
      continue
    for neighbor_id in get_neighbor_tile_ids(tile_id):
      var neighbor: Dictionary = state["tiles"][neighbor_id]
      if neighbor["home_owner"] == owner:
        continue
      var edge = HexUtils.edge_id(tile_id, neighbor_id)
      state["walls"][edge] = {
        "id": edge,
        "owner": owner,
        "from": tile_id,
        "to": neighbor_id,
        "hp": int(rules["walls"]["wall_max_health"]),
        "max_hp": int(rules["walls"]["wall_max_health"]),
        "destroyed": false
      }

func _create_players() -> void:
  var colors: Dictionary = rules.get("ui", {}).get("player_colors", {})
  for player_id in get_player_ids():
    var capital = ""
    for tile in state["tiles"].values():
      if tile["capital_owner"] == player_id:
        capital = String(tile["id"])
        break
    state["players"][player_id] = {
      "id": player_id,
      "display_name": "You" if player_id == PLAYER_HUMAN else "Bot",
      "is_bot": player_id == PLAYER_BOT,
      "color": String(colors.get(player_id, "#FFFFFF")),
      "bank_cents": int(rules["match"]["starting_bank_cents"]),
      "research_health_bps": 0,
      "research_damage_bps": 0,
      "active_economy_bonus_bps": 0,
      "next_economy_bonus_bps": 0,
      "pending_soldiers": 0,
      "capital_tile_id": capital,
      "eliminated": false
    }

func _create_starting_stacks() -> void:
  var count = int(rules["match"]["starting_soldiers_per_capital"])
  for player_id in get_player_ids():
    _add_soldiers_to_tile(player_id, state["players"][player_id]["capital_tile_id"], count)

func _begin_player_turn(player_id: String) -> void:
  TurnResolver.begin_player_turn(state, player_id, PHASE_ALLOCATION, calculate_income, _add_soldiers_to_tile, _eliminate_player, _event)

func _resolve_player_movement(player_id: String) -> void:
  MovementRules.resolve_player_movement(state, player_id, get_neighbor_tile_ids, _is_wall_blocking, _attack_wall, _event)

func _is_wall_blocking(wall_id: String, player_id: String) -> bool:
  if not state["walls"].has(wall_id):
    return false
  var wall: Dictionary = state["walls"][wall_id]
  return not bool(wall["destroyed"]) and wall["owner"] != player_id

func _attack_wall(stack_id: String, wall_id: String) -> void:
  var stack: Dictionary = state["stacks"][stack_id]
  var wall: Dictionary = state["walls"][wall_id]
  var damage = _roll_stack_damage(stack, "wall_%s_%s" % [stack_id, wall_id])
  wall["hp"] = max(0, int(wall["hp"]) - damage)
  if int(wall["hp"]) <= 0:
    wall["destroyed"] = true
    _event("wall_destroyed", {"wall_id": wall_id, "player_id": stack["owner"], "damage": damage})
  else:
    _event("wall_damaged", {"wall_id": wall_id, "player_id": stack["owner"], "damage": damage, "hp": wall["hp"]})

func _merge_same_owner_stacks() -> void:
  MovementRules.merge_same_owner_stacks(state, _event)

func _resolve_all_combats() -> void:
  CombatRules.resolve_all_combats(state, rules, _roll_stack_damage, _event)

func _apply_post_resolution_control() -> void:
  CombatRules.apply_post_resolution_control(state, _event)

func _check_eliminations() -> void:
  TurnResolver.resolve_eliminations(state, get_player_ids(), NEUTRAL, _eliminate_player, _event)

func _end_match_as_draw() -> void:
  TurnResolver.end_as_draw(state, _event)

func _eliminate_player(player_id: String, capturer_id: String) -> void:
  if bool(state["players"][player_id]["eliminated"]):
    return
  state["players"][player_id]["eliminated"] = true
  for tile in state["tiles"].values():
    if tile["controlled_by"] == player_id:
      tile["controlled_by"] = capturer_id
  var erase_ids: Array[String] = []
  for stack_id in state["stacks"].keys():
    if state["stacks"][stack_id]["owner"] == player_id:
      erase_ids.append(stack_id)
  for stack_id in erase_ids:
    state["stacks"].erase(stack_id)
  _event("player_eliminated", {"player_id": player_id, "capturer_id": capturer_id})

func _add_soldiers_to_tile(player_id: String, tile_id: String, count: int) -> void:
  if count <= 0:
    return
  var player: Dictionary = state["players"][player_id]
  var stack_id = get_stack_at_tile_for_player(tile_id, player_id)
  if stack_id == "":
    stack_id = "S%d" % int(state["next_stack_index"])
    state["next_stack_index"] = int(state["next_stack_index"]) + 1
    state["stacks"][stack_id] = {"id": stack_id, "owner": player_id, "tile_id": tile_id, "cohorts": [], "waypoints": []}
  var health = int(rules["soldier"]["base_health"]) * (10000 + int(player["research_health_bps"])) / 10000
  var damage = int(rules["soldier"]["base_damage_mean"]) * (10000 + int(player["research_damage_bps"])) / 10000
  var cohort_id = "C%d" % int(state["next_cohort_index"])
  state["next_cohort_index"] = int(state["next_cohort_index"]) + 1
  state["stacks"][stack_id]["cohorts"].append({
    "cohort_id": cohort_id,
    "owner_id": player_id,
    "count": count,
    "spawn_turn": state["turn"],
    "max_health_per_soldier": int(health),
    "damage_mean_per_soldier": int(damage),
    "damage_stddev_per_soldier": int(rules["soldier"]["base_damage_stddev"]),
    "current_total_health": int(health) * count
  })

func _public_stack(stack: Dictionary) -> Dictionary:
  return {
    "id": stack["id"],
    "owner": stack["owner"],
    "tile_id": stack["tile_id"],
    "soldiers": _stack_soldier_count(stack),
    "health": _stack_health(stack),
    "expected_damage": _stack_expected_damage(stack),
    "waypoints": stack.get("waypoints", []).duplicate()
  }

func _stack_soldier_count(stack: Dictionary) -> int:
  var total = 0
  for cohort in stack["cohorts"]:
    total += int(cohort["count"])
  return total

func _stack_health(stack: Dictionary) -> int:
  var total = 0
  for cohort in stack["cohorts"]:
    total += int(cohort["current_total_health"])
  return total

func _stack_expected_damage(stack: Dictionary) -> int:
  var total = 0
  for cohort in stack["cohorts"]:
    total += int(cohort["count"]) * int(cohort["damage_mean_per_soldier"])
  return total

func _roll_stack_damage(stack: Dictionary, salt: String) -> int:
  var mean = _stack_expected_damage(stack)
  var soldiers = max(1, _stack_soldier_count(stack))
  var stddev = int(rules["soldier"]["base_damage_stddev"]) * soldiers
  var noise = 0.0
  for i in range(6):
    noise += RngRules.unit_random(int(state["seed"]), state["rng_streams"], int(state["turn"]), "combat", "%s_%d" % [salt, i])
  noise = noise - 3.0
  return max(1, int(round(float(mean) + noise * float(stddev) / 2.0)))

func _event(type: String, payload: Dictionary) -> void:
  var event = payload.duplicate(true)
  event["type"] = type
  event["turn"] = state["turn"]
  event["active_player"] = state["active_player"]
  state["replay_events"].append(event)

func _event_to_text(event: Dictionary) -> String:
  match String(event.get("type", "")):
    "income_added":
      return "T%d %s income %s" % [event["turn"], event["player_id"], money_text(int(event["income"]["final"]))]
    "allocation_applied":
      return "T%d %s alloc E%s M%s R%s" % [event["turn"], event["player_id"], money_text(event["economy_cents"]), money_text(event["military_cents"]), money_text(event["research_cents"])]
    "stack_moved":
      return "T%d %s moved %s" % [event["turn"], event["player_id"], event["to"]]
    "wall_damaged":
      return "T%d wall hit hp %d" % [event["turn"], event["hp"]]
    "wall_destroyed":
      return "T%d wall breached" % event["turn"]
    "combat_resolved":
      return "T%d combat winner %s" % [event["turn"], event["winner"]]
    "player_eliminated":
      return "T%d %s eliminated" % [event["turn"], event["player_id"]]
    "match_ended":
      return "Winner %s on T%d" % [event["winner"], event["turn"]]
    _:
      return "T%d %s" % [event.get("turn", 0), event.get("type", "event")]

func _command_result(ok: bool, message: String, code: String = "") -> Dictionary:
  return {"ok": ok, "message": message, "code": code}

func bot_random_unit(salt: String) -> float:
  return RngRules.unit_random(int(state["seed"]), state["rng_streams"], int(state["turn"]), "bot", salt)
