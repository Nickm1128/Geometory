class_name TurnResolver
extends RefCounted

static func reaches_turn_cap(state: Dictionary, rules: Dictionary) -> bool:
  return int(state.get("turn", 0)) >= int(rules.get("match", {}).get("max_turns", 80))

static func next_active_player(current_player: String, human_player: String, bot_player: String, players: Dictionary) -> String:
  var next = bot_player if current_player == human_player else human_player
  if bool(players.get(next, {}).get("eliminated", false)):
    next = current_player
  return next
