class_name TurnResolver
extends RefCounted

static func reaches_turn_cap(state: Dictionary, rules: Dictionary) -> bool:
  return int(state.get("turn", 0)) >= int(rules.get("match", {}).get("max_turns", 80))

static func next_active_player(current_player: String, human_player: String, bot_player: String, players: Dictionary) -> String:
  var next = bot_player if current_player == human_player else human_player
  if bool(players.get(next, {}).get("eliminated", false)):
    next = current_player
  return next

static func resolve_end_phase(state: Dictionary, rules: Dictionary, player_id: String, human_player: String, bot_player: String, resolve_movement: Callable, merge_stacks: Callable, resolve_combats: Callable, apply_control: Callable, check_eliminations: Callable, begin_turn: Callable, end_draw: Callable) -> void:
  resolve_movement.call(player_id)
  merge_stacks.call()
  resolve_combats.call()
  apply_control.call()
  check_eliminations.call()
  if bool(state.get("game_over", false)):
    return
  if reaches_turn_cap(state, rules):
    end_draw.call()
    return
  var next := next_active_player(String(state.get("active_player", "")), human_player, bot_player, state.get("players", {}))
  state["turn"] = int(state.get("turn", 0)) + 1
  begin_turn.call(next)

static func begin_player_turn(state: Dictionary, player_id: String, allocation_phase: String, calculate_income: Callable, add_soldiers: Callable, eliminate_player: Callable, emit_event: Callable) -> void:
  state["active_player"] = player_id
  state["phase"] = allocation_phase
  var player: Dictionary = state["players"][player_id]
  if String(state["tiles"][player["capital_tile_id"]]["controlled_by"]) != player_id:
    eliminate_player.call(player_id, String(state["tiles"][player["capital_tile_id"]]["controlled_by"]))
    return
  var pending := int(player["pending_soldiers"])
  if pending > 0:
    add_soldiers.call(player_id, player["capital_tile_id"], pending)
    player["pending_soldiers"] = 0
    emit_event.call("soldiers_spawned", {"player_id": player_id, "tile_id": player["capital_tile_id"], "soldiers": pending})
  player["active_economy_bonus_bps"] = int(player["next_economy_bonus_bps"])
  player["next_economy_bonus_bps"] = 0
  var income: Dictionary = calculate_income.call(player_id)
  player["bank_cents"] = int(player["bank_cents"]) + int(income["final"])
  emit_event.call("income_added", {"player_id": player_id, "income": income, "bank_cents": player["bank_cents"]})

static func resolve_eliminations(state: Dictionary, player_ids: Array[String], neutral_owner: String, eliminate_player: Callable, emit_event: Callable) -> void:
  for player_id in player_ids:
    if bool(state["players"][player_id]["eliminated"]):
      continue
    var capital := String(state["players"][player_id]["capital_tile_id"])
    var controller := String(state["tiles"][capital]["controlled_by"])
    if controller != player_id and controller != neutral_owner:
      eliminate_player.call(player_id, controller)
  var alive: Array[String] = []
  for player_id in player_ids:
    if not bool(state["players"][player_id]["eliminated"]):
      alive.append(player_id)
  if alive.size() <= 1:
    state["game_over"] = true
    state["winner"] = alive[0] if alive.size() == 1 else ""
    emit_event.call("match_ended", {"winner": state["winner"], "turns": state["turn"]})

static func end_as_draw(state: Dictionary, emit_event: Callable) -> void:
  state["game_over"] = true
  state["winner"] = ""
  emit_event.call("match_ended", {"winner": "", "turns": state["turn"], "reason": "turn_cap_draw"})
