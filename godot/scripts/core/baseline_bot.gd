class_name BaselineBot
extends RefCounted

const HexUtils = preload("res://scripts/core/hex_utils.gd")
const PHASE_ALLOCATION = "allocation"
const PHASE_MOVEMENT = "movement"
const NEUTRAL = "neutral"

var profile: Dictionary = {}
var next_client_sequence := 1

func setup(new_profile: Dictionary) -> void:
  profile = new_profile.duplicate(true)
  next_client_sequence = 1

func build_turn_commands(obs: Dictionary) -> Array[Dictionary]:
  var commands: Array[Dictionary] = []
  var player_id: String = String(obs["player_id"])
  if obs["phase"] == PHASE_ALLOCATION:
    commands.append(_allocation_command(obs))
  commands.append_array(_movement_commands(obs))
  commands.append({
    "type": "end_phase",
    "player_id": player_id,
    "turn": obs["turn"],
    "phase": PHASE_MOVEMENT,
    "client_sequence": _next_sequence()
  })
  return commands

func _allocation_command(obs: Dictionary) -> Dictionary:
  var player_id = String(obs["player_id"])
  var bank = int(obs["player"]["bank_cents"])
  var reserve = int(profile.get("allocation", {}).get("minimum_reserve_cents", 100))
  var spendable = max(0, bank - reserve)
  var turn = int(obs["turn"])
  var allocation = profile.get("allocation", {})
  var ew = float(allocation.get("stable_economy_weight", 0.2))
  var mw = float(allocation.get("stable_military_weight", 0.45))
  var rw = float(allocation.get("stable_research_weight", 0.35))
  if turn <= int(allocation.get("early_turn_count", 5)):
    ew = float(allocation.get("early_economy_weight", 0.25))
    mw = float(allocation.get("early_military_weight", 0.5))
    rw = float(allocation.get("early_research_weight", 0.25))
  var total = max(0.01, ew + mw + rw)
  var economy = _snap_to_100(int(spendable * ew / total))
  var military = _snap_to_100(int(spendable * mw / total))
  var research = _snap_to_100(max(0, spendable - economy - military))
  return {
    "type": "allocate_resources",
    "player_id": player_id,
    "turn": turn,
    "phase": PHASE_ALLOCATION,
    "economy_cents": economy,
    "military_cents": military,
    "research_cents": research,
    "client_sequence": _next_sequence()
  }

func _movement_commands(obs: Dictionary) -> Array[Dictionary]:
  var result: Array[Dictionary] = []
  var player_id = String(obs["player_id"])
  var stacks: Dictionary = obs["stacks"]
  var visible_tiles: Dictionary = obs["tiles"]
  for stack_id in stacks.keys():
    var stack: Dictionary = stacks[stack_id]
    if stack["owner"] != player_id:
      continue
    if stack.get("waypoints", []).size() > 0:
      continue
    var target = _choose_target(player_id, String(stack["tile_id"]), visible_tiles)
    if target == "":
      continue
    result.append({
      "type": "queue_stack_path",
      "player_id": player_id,
      "turn": obs["turn"],
      "phase": PHASE_MOVEMENT,
      "stack_id": stack_id,
      "waypoints": [target],
      "mode": "append",
      "client_sequence": _next_sequence()
    })
  return result

func _choose_target(player_id: String, from_tile: String, visible_tiles: Dictionary) -> String:
  var best_neutral = _nearest_tile(player_id, from_tile, visible_tiles, "neutral")
  if best_neutral != "":
    return best_neutral
  var best_enemy = _nearest_tile(player_id, from_tile, visible_tiles, "enemy")
  if best_enemy != "":
    return best_enemy
  return ""

func _nearest_tile(player_id: String, from_tile: String, tiles: Dictionary, mode: String) -> String:
  var from_coord = HexUtils.parse_tile_id(from_tile)
  var best = ""
  var best_distance = 999999
  for tile_id in tiles.keys():
    var tile: Dictionary = tiles[tile_id]
    var controlled_by = String(tile["controlled_by"])
    if mode == "neutral" and controlled_by != NEUTRAL:
      continue
    if mode == "enemy" and controlled_by == player_id:
      continue
    var distance = HexUtils.distance(from_coord, Vector2i(int(tile["q"]), int(tile["r"])))
    if distance < best_distance and distance > 0:
      best = String(tile_id)
      best_distance = distance
  return best

func _snap_to_100(value: int) -> int:
  return int(floor(float(value) / 100.0)) * 100

func _next_sequence() -> int:
  var value = next_client_sequence
  next_client_sequence += 1
  return value
