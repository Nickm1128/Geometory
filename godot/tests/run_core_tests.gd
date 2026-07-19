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
  var commands: Array = bot.call("build_turn_commands", core, "P2")
  _assert(commands.size() >= 2, "bot emits allocation and end commands")
  for command in commands:
    var result: Dictionary = core.apply_command(command)
    _assert(result["ok"], "bot command is valid: %s" % command["type"])

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

func _assert(condition: bool, message: String) -> void:
  if condition:
    print("PASS: %s" % message)
  else:
    failures += 1
    push_error("FAIL: %s" % message)
