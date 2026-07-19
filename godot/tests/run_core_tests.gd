extends SceneTree

const GameCoreScript := preload("res://scripts/core/game_core.gd")
const ConfigLoaderScript := preload("res://scripts/core/config_loader.gd")
const BaselineBotScript := preload("res://scripts/core/baseline_bot.gd")

var failures := 0

func _init() -> void:
  var configs: Dictionary = ConfigLoaderScript.load_all()
  _assert(configs["rules"].size() > 0, "rules config loads")
  _assert(configs["map"].size() > 0, "map config loads")
  _assert(configs["bot"].size() > 0, "bot config loads")

  var core := GameCoreScript.new()
  core.setup(configs["rules"], configs["map"], 12345)
  _test_map(core)
  _test_economy(core)
  _test_research_reproducibility(configs)
  _test_commands_and_path(core)
  _test_p01_contract_red_cases(configs)
  _test_movement_resolution_contracts(configs)
  _test_turn_cap_rng_and_hash_contracts(configs)
  _test_fog_observation_contract(configs)
  _test_bot(configs)
  _test_replay_reproducibility(configs)

  if failures == 0:
    print("All Geometory core tests passed.")
    quit(0)
  else:
    push_error("%d Geometory core test(s) failed." % failures)
    quit(1)

func _test_map(core) -> void:
  var state: Dictionary = core.snapshot()
  _assert(state["tiles"].size() == 127, "Alpha Medium has 127 tiles")
  _assert(_home_count(state, "P1") == 19, "P1 home has 19 tiles")
  _assert(_home_count(state, "P2") == 19, "P2 home has 19 tiles")
  _assert(state["players"]["P1"]["capital_tile_id"] == "T_-4_0", "P1 capital exists")
  _assert(state["players"]["P2"]["capital_tile_id"] == "T_4_0", "P2 capital exists")
  _assert(state["walls"].size() > 0, "home walls generated")
  for wall in state["walls"].values():
    var a: Dictionary = state["tiles"][wall["from"]]
    var b: Dictionary = state["tiles"][wall["to"]]
    _assert(a["home_owner"] != b["home_owner"], "wall is only on a home exit")

func _test_economy(core) -> void:
  var income: Dictionary = core.calculate_income("P1")
  _assert(int(income["base"]) == 1900, "P1 starts with $19.00 base income")
  _assert(core.get_bank("P1") == 2800, "P1 starting bank includes first income")
  var result: Dictionary = core.apply_command({
    "type": "allocate_resources",
    "player_id": "P1",
    "turn": core.snapshot()["turn"],
    "phase": "allocation",
    "economy_cents": 300,
    "military_cents": 600,
    "research_cents": 300,
    "client_sequence": 1
  })
  _assert(result["ok"], "allocation command succeeds")
  var state: Dictionary = core.snapshot()
  _assert(state["phase"] == "movement", "allocation advances to movement")
  _assert(state["players"]["P1"]["pending_soldiers"] == 2, "military queues soldiers")
  _assert(state["players"]["P1"]["next_economy_bonus_bps"] == 150, "economy bonus is non-compounding next-turn bonus")

func _test_research_reproducibility(configs: Dictionary) -> void:
  var a = GameCoreScript.new()
  var b = GameCoreScript.new()
  a.setup(configs["rules"], configs["map"], 999)
  b.setup(configs["rules"], configs["map"], 999)
  _assert(a.snapshot()["research_schedule"] == b.snapshot()["research_schedule"], "same seed reproduces research schedule")

func _test_commands_and_path(core) -> void:
  var p1_stack: String = core.get_stack_at_tile_for_player("T_-4_0", "P1")
  var path: Array = core.find_path("T_-4_0", "T_-2_0")
  _assert(path.size() == 2, "pathfinder returns expected two-step path")
  var result: Dictionary = core.apply_command({
    "type": "queue_stack_path",
    "player_id": "P1",
    "turn": core.snapshot()["turn"],
    "phase": "movement",
    "stack_id": p1_stack,
    "waypoints": ["T_-2_0"],
    "mode": "replace",
    "client_sequence": 2
  })
  _assert(result["ok"], "queue path command succeeds")
  _assert(core.snapshot()["stacks"][p1_stack]["waypoints"].size() == 2, "path queue persists")
  result = core.apply_command({
    "type": "end_phase",
    "player_id": "P1",
    "turn": core.snapshot()["turn"],
    "phase": "movement",
    "client_sequence": 3
  })
  _assert(result["ok"], "end turn succeeds")
  _assert(core.snapshot()["tiles"]["T_-3_0"]["controlled_by"] == "P1", "pass-through capture applies")

func _test_p01_contract_red_cases(configs: Dictionary) -> void:
  var rejected = GameCoreScript.new()
  rejected.setup(configs["rules"], configs["map"], 101)
  var before: Dictionary = rejected.snapshot()
  var result: Dictionary = rejected.apply_command({
    "type": "not_a_command",
    "player_id": "P1",
    "turn": 1,
    "phase": "allocation",
    "client_sequence": 1
  })
  var after: Dictionary = rejected.snapshot()
  _assert(not result["ok"], "contract: unknown command is rejected")
  _assert(after.get("accepted_command_history", []).is_empty(), "contract: rejected command never enters accepted history")
  _assert(after.get("command_history", []).is_empty(), "contract: rejected command never enters legacy command history")
  _assert(after.get("rejected_command_diagnostics", []).size() == 1, "contract: rejected command records one diagnostic")
  _assert(before["players"] == after["players"] and before["phase"] == after["phase"], "contract: rejected command leaves gameplay state unchanged")

  var turn_checked = GameCoreScript.new()
  turn_checked.setup(configs["rules"], configs["map"], 102)
  result = turn_checked.apply_command({
    "type": "allocate_resources",
    "player_id": "P1",
    "turn": 99,
    "phase": "allocation",
    "economy_cents": 0,
    "military_cents": 0,
    "research_cents": 0,
    "client_sequence": 1
  })
  _assert(not result["ok"], "contract: mismatched turn is rejected before mutation")

  var sequenced = GameCoreScript.new()
  sequenced.setup(configs["rules"], configs["map"], 103)
  sequenced.apply_command({"type": "allocate_resources", "player_id": "P1", "turn": 1, "phase": "allocation", "economy_cents": 0, "military_cents": 0, "research_cents": 0, "client_sequence": 7})
  var p1_stack: String = sequenced.get_stack_at_tile_for_player("T_-4_0", "P1")
  sequenced.apply_command({"type": "queue_stack_path", "player_id": "P1", "turn": 1, "phase": "movement", "stack_id": p1_stack, "waypoints": ["T_-3_0"], "mode": "replace", "client_sequence": 8})
  result = sequenced.apply_command({"type": "queue_stack_path", "player_id": "P1", "turn": 1, "phase": "movement", "stack_id": p1_stack, "waypoints": ["T_-2_0"], "mode": "replace", "client_sequence": 8})
  _assert(not result["ok"], "contract: duplicate accepted source sequence is rejected")
  result = sequenced.apply_command({"type": "queue_stack_path", "player_id": "P1", "turn": 1, "phase": "movement", "stack_id": p1_stack, "waypoints": ["T_-2_0"], "mode": "invalid", "client_sequence": 9})
  _assert(not result["ok"] and result["code"] == "invalid_path_mode", "contract: invalid path mode is diagnosed before mutation")
  result = sequenced.apply_command({"type": "queue_stack_path", "player_id": "P1", "turn": 1, "phase": "movement", "stack_id": p1_stack, "waypoints": ["missing_tile"], "mode": "replace", "client_sequence": 9})
  _assert(not result["ok"] and result["code"] == "invalid_waypoint", "contract: unknown waypoint is diagnosed before mutation")
  result = sequenced.apply_command({"type": "queue_stack_path", "player_id": "P1", "turn": 1, "phase": "movement", "stack_id": p1_stack, "waypoints": ["T_-2_0"], "mode": "replace", "client_sequence": 9})
  _assert(result["ok"], "contract: rejected sequence is reusable because it was never accepted")

  var fog = GameCoreScript.new()
  fog.setup(configs["rules"], configs["map"], 104)
  var p2_stack: String = fog.get_stack_at_tile_for_player("T_4_0", "P2")
  fog.state["stacks"][p2_stack]["tile_id"] = "T_-3_0"
  fog.state["stacks"][p2_stack]["waypoints"] = ["T_3_0"]
  var observed: Dictionary = fog.observable_state("P1")
  var enemy: Dictionary = observed["stacks"][p2_stack]
  _assert(enemy.has("strength_band"), "contract: visible enemy exposes a strength band")
  _assert(not enemy.has("soldiers") and not enemy.has("health") and not enemy.has("expected_damage") and not enemy.has("waypoints"), "contract: visible enemy excludes exact strength and queued path")

  var hashed_a = GameCoreScript.new()
  var hashed_b = GameCoreScript.new()
  hashed_a.setup(configs["rules"], configs["map"], 105)
  hashed_b.setup(configs["rules"], configs["map"], 105)
  _assert(hashed_a.has_method("canonical_state_hash"), "contract: core exposes canonical SHA-256 state hash")
  if hashed_a.has_method("canonical_state_hash") and hashed_b.has_method("canonical_state_hash"):
    _assert(hashed_a.call("canonical_state_hash") == hashed_b.call("canonical_state_hash"), "contract: equal setups have equal canonical hashes")

func _test_movement_resolution_contracts(configs: Dictionary) -> void:
  var invalid_edge = GameCoreScript.new()
  invalid_edge.setup(configs["rules"], configs["map"], 201)
  var invalid_stack: String = invalid_edge.get_stack_at_tile_for_player("T_-4_0", "P1")
  invalid_edge.state["stacks"][invalid_stack]["tile_id"] = "T_-2_0"
  invalid_edge.state["stacks"][invalid_stack]["waypoints"] = ["T_0_0"]
  invalid_edge.call("_resolve_player_movement", "P1")
  _assert(invalid_edge.state["stacks"][invalid_stack]["tile_id"] == "T_-2_0", "contract: non-adjacent edge never executes")
  _assert(invalid_edge.state["stacks"][invalid_stack]["waypoints"] == ["T_0_0"], "contract: invalid edge stops and retains queue")
  _assert(_has_event(invalid_edge.snapshot()["replay_events"], "movement_blocked"), "contract: invalid edge emits stable blocked event")

  var merged = GameCoreScript.new()
  merged.setup(configs["rules"], configs["map"], 202)
  var template: Dictionary = merged.state["stacks"][merged.get_stack_at_tile_for_player("T_-4_0", "P1")].duplicate(true)
  template["id"] = "S_A"
  template["tile_id"] = "T_-3_0"
  template["waypoints"] = ["T_-2_0"]
  merged.state["stacks"]["S_A"] = template
  var absorbed: Dictionary = template.duplicate(true)
  absorbed["id"] = "S_B"
  absorbed["waypoints"] = ["T_-1_0"]
  merged.state["stacks"]["S_B"] = absorbed
  merged.call("_merge_same_owner_stacks")
  _assert(merged.state["stacks"].has("S_A") and not merged.state["stacks"].has("S_B"), "contract: lowest friendly stack ID absorbs deterministically")
  _assert(merged.state["stacks"]["S_A"]["waypoints"].is_empty(), "contract: merged friendly queues are cleared")
  _assert(_has_event(merged.snapshot()["replay_events"], "friendly_stacks_merged"), "contract: friendly merge emits stable event")

  var combat = GameCoreScript.new()
  combat.setup(configs["rules"], configs["map"], 203)
  var p1_stack: String = combat.get_stack_at_tile_for_player("T_-4_0", "P1")
  combat.state["stacks"][p1_stack]["tile_id"] = "T_4_0"
  for cohort in combat.state["stacks"][p1_stack]["cohorts"]:
    cohort["count"] = 5
    cohort["max_health_per_soldier"] = 20000
    cohort["current_total_health"] = 100000
    cohort["damage_mean_per_soldier"] = 20000
  combat.call("_resolve_all_combats")
  _assert(combat.state["tiles"]["T_4_0"]["controlled_by"] == "P2", "contract: combat does not apply control before post-resolution step")
  _assert(_has_combat_defender(combat.snapshot()["replay_events"], "P2"), "contract: current controller resolves as defender")
  combat.call("_apply_post_resolution_control")
  _assert(combat.state["tiles"]["T_4_0"]["controlled_by"] == "P1", "contract: surviving combatant receives control after combat")

func _test_turn_cap_rng_and_hash_contracts(configs: Dictionary) -> void:
  var hash_core = GameCoreScript.new()
  hash_core.setup(configs["rules"], configs["map"], 301)
  var before_hash: String = hash_core.canonical_state_hash()
  hash_core.apply_command({"type": "invalid", "player_id": "P1", "turn": 1, "phase": "allocation", "client_sequence": 1})
  _assert(before_hash == hash_core.canonical_state_hash(), "contract: rejected diagnostics do not alter canonical hash")
  _assert(hash_core.canonical_state_hash().length() == 64, "contract: canonical hash is SHA-256 hex")
  _assert(hash_core.state["rng_streams"].has("research") and hash_core.state["rng_streams"].has("combat") and hash_core.state["rng_streams"].has("bot"), "contract: owned research combat and bot streams are recorded")

  var capped = GameCoreScript.new()
  capped.setup(configs["rules"], configs["map"], 302)
  var sequences := {"P1": 1, "P2": 1}
  while not capped.state["game_over"]:
    var player_id: String = capped.state["active_player"]
    var sequence: int = sequences[player_id]
    var allocation = capped.apply_command({"type": "allocate_resources", "player_id": player_id, "turn": capped.state["turn"], "phase": "allocation", "economy_cents": 0, "military_cents": 0, "research_cents": 0, "client_sequence": sequence})
    _assert(allocation["ok"], "contract: zero allocation is accepted before turn cap")
    sequences[player_id] = sequence + 1
    sequence = sequences[player_id]
    var ending = capped.apply_command({"type": "end_phase", "player_id": player_id, "turn": capped.state["turn"], "phase": "movement", "client_sequence": sequence})
    _assert(ending["ok"], "contract: end phase resolves before turn cap")
    sequences[player_id] = sequence + 1
  _assert(capped.state["turn"] == 80 and capped.state["winner"] == "", "contract: unresolved player-turn 80 ends as draw without turn 81")
  _assert(_has_draw_end(capped.snapshot()["replay_events"]), "contract: turn-cap draw emits a stable match-ended event")

func _test_bot(configs: Dictionary) -> void:
  var core = GameCoreScript.new()
  core.setup(configs["rules"], configs["map"], 777)
  core.apply_command({
    "type": "allocate_resources",
    "player_id": "P1",
    "turn": core.snapshot()["turn"],
    "phase": "allocation",
    "economy_cents": 0,
    "military_cents": 0,
    "research_cents": 0,
    "client_sequence": 1
  })
  core.apply_command({
    "type": "end_phase",
    "player_id": "P1",
    "turn": core.snapshot()["turn"],
    "phase": "movement",
    "client_sequence": 2
  })
  var bot = BaselineBotScript.new()
  bot.setup(configs["bot"])
  var commands: Array = bot.call("build_turn_commands", core.observable_state("P2"))
  _assert(commands.size() >= 2, "bot emits allocation and end commands")
  for command in commands:
    var result: Dictionary = core.apply_command(command)
    _assert(result["ok"], "bot command is valid: %s" % command["type"])

func _test_fog_observation_contract(configs: Dictionary) -> void:
  var fog = GameCoreScript.new()
  fog.setup(configs["rules"], configs["map"], 401)
  fog.state["players"]["P2"]["bank_cents"] = 987654
  fog.state["players"]["P2"]["research_health_bps"] = 7654
  fog.state["replay_events"].append({"type": "allocation_applied", "player_id": "P2", "secret": "hidden"})
  var p2_stack: String = fog.get_stack_at_tile_for_player("T_4_0", "P2")
  var p2_wall := ""
  for wall_id in fog.state["walls"].keys():
    var wall: Dictionary = fog.state["walls"][wall_id]
    if wall["owner"] == "P2":
      p2_wall = String(wall_id)
      break
  var hidden: Dictionary = fog.observable_state("P1")
  _assert(not hidden.has("players") and not hidden.has("rejected_command_diagnostics"), "contract: bot snapshot has no private player collection or diagnostics")
  _assert(not hidden["stacks"].has(p2_stack), "contract: hidden enemy position is absent")
  _assert(not hidden["walls"].has(p2_wall), "contract: hidden enemy wall state is absent")
  _assert(not _has_event_for_player(hidden["visible_events"], "allocation_applied", "P2"), "contract: hidden enemy economy event is absent")

  fog.state["stacks"][p2_stack]["tile_id"] = "T_-3_0"
  fog.state["stacks"][p2_stack]["waypoints"] = ["T_3_0"]
  var visible: Dictionary = fog.observable_state("P1")
  var enemy: Dictionary = visible["stacks"][p2_stack]
  _assert(enemy.has("strength_band") and not enemy.has("cohorts") and not enemy.has("waypoints"), "contract: visible enemy exposes only strength band without private cohort/path data")
  _assert(visible["player"]["bank_cents"] != 987654 and visible["player"]["research_health_bps"] != 7654, "contract: enemy economy and research are absent from own bot state")

func _test_replay_reproducibility(configs: Dictionary) -> void:
  var a = GameCoreScript.new()
  var b = GameCoreScript.new()
  a.setup(configs["rules"], configs["map"], 321)
  b.setup(configs["rules"], configs["map"], 321)
  var command := {
    "type": "allocate_resources",
    "player_id": "P1",
    "turn": 1,
    "phase": "allocation",
    "economy_cents": 300,
    "military_cents": 600,
    "research_cents": 300,
    "client_sequence": 1
  }
  a.apply_command(command)
  b.apply_command(command)
  _assert(a.snapshot()["players"]["P1"] == b.snapshot()["players"]["P1"], "same seed and command reproduces state")

func _home_count(state: Dictionary, player_id: String) -> int:
  var count := 0
  for tile in state["tiles"].values():
    if tile["home_owner"] == player_id:
      count += 1
  return count

func _has_event(events: Array, event_type: String) -> bool:
  for event in events:
    if String(event.get("type", "")) == event_type:
      return true
  return false

func _has_combat_defender(events: Array, defender: String) -> bool:
  for event in events:
    if String(event.get("type", "")) == "combat_exchange" and String(event.get("defender", "")) == defender:
      return true
  return false

func _has_draw_end(events: Array) -> bool:
  for event in events:
    if String(event.get("type", "")) == "match_ended" and String(event.get("winner", "")) == "" and String(event.get("reason", "")) == "turn_cap_draw":
      return true
  return false

func _has_event_for_player(events: Array, event_type: String, player_id: String) -> bool:
  for event in events:
    if String(event.get("type", "")) == event_type and String(event.get("player_id", "")) == player_id:
      return true
  return false

func _assert(condition: bool, message: String) -> void:
  if condition:
    print("PASS: %s" % message)
  else:
    failures += 1
    push_error("FAIL: %s" % message)
