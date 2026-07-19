extends SceneTree

const VisualQaBootstrap := preload("res://visual_qa/visual_qa_bootstrap.gd")

var failures := 0

func _init() -> void:
  var catalog := _load_json("res://visual_qa/scenarios.json")
  var request_schema := _load_json("res://visual_qa/request.schema.json")
  var ready_schema := _load_json("res://visual_qa/ready.schema.json")
  _assert(not catalog.is_empty(), "visual QA catalog loads")
  _assert(not request_schema.is_empty(), "visual QA request schema loads")
  _assert(not ready_schema.is_empty(), "visual QA ready schema loads")
  if not catalog.is_empty():
    _assert(int(catalog.get("schema_version", 0)) == 1, "catalog schema version is 1")
    var scenarios: Array = catalog.get("scenarios", [])
    _assert(scenarios.size() == 26, "catalog reserves all 26 milestone scenarios")
    var ids: Dictionary = {}
    var implemented := 0
    for scenario in scenarios:
      var scenario_id := String(scenario.get("id", ""))
      _assert(scenario_id != "", "scenario has an ID")
      _assert(not ids.has(scenario_id), "scenario ID is unique: %s" % scenario_id)
      ids[scenario_id] = true
      if bool(scenario.get("implemented", false)):
        implemented += 1
    _assert(implemented == 16, "P00 harness implements 16 directly reachable scenarios")
  if not request_schema.is_empty():
    var required: Array = request_schema.get("required", [])
    for field in ["schema_version", "nonce", "scenario_id", "seed", "ui_scale", "safe_area_profile", "build_id"]:
      _assert(required.has(field), "request schema requires %s" % field)
    _assert(request_schema.get("additionalProperties", true) == false, "request schema rejects unknown fields")
  if not ready_schema.is_empty():
    var ready_required: Array = ready_schema.get("required", [])
    for field in ["schema_version", "nonce", "scenario_id", "success", "errors", "assertions", "seed", "ui_scale", "safe_area_profile", "build_id", "viewport", "safe_area", "state_hash"]:
      _assert(ready_required.has(field), "ready schema requires %s" % field)
    _assert(ready_schema.get("additionalProperties", true) == false, "ready schema rejects unknown fields")

  var bootstrap := VisualQaBootstrap.new()
  var hash_a: String = bootstrap.fixture_state_hash({
    "turn": 1,
    "phase": "movement",
    "command_history": [{"type": "queue_stack_path", "waypoints": ["T_1_0"], "client_sequence": 101}]
  })
  var hash_b: String = bootstrap.fixture_state_hash({
    "turn": 1,
    "phase": "movement",
    "command_history": [{"type": "queue_stack_path", "waypoints": ["T_1_0"], "client_sequence": 999999}]
  })
  var hash_changed: String = bootstrap.fixture_state_hash({
    "turn": 1,
    "phase": "movement",
    "command_history": [{"type": "queue_stack_path", "waypoints": ["T_2_0"], "client_sequence": 101}]
  })
  _assert(hash_a == hash_b, "fixture state hash normalizes volatile client sequences")
  _assert(hash_a != hash_changed, "fixture state hash retains semantic command content")
  bootstrap.free()

  if failures == 0:
    print("All Geometory visual QA contract tests passed.")
    quit(0)
  else:
    push_error("%d visual QA contract test(s) failed." % failures)
    quit(1)

func _load_json(path: String) -> Dictionary:
  var file := FileAccess.open(path, FileAccess.READ)
  if file == null:
    return {}
  var parsed = JSON.parse_string(file.get_as_text())
  if parsed is Dictionary:
    return parsed
  return {}

func _assert(condition: bool, message: String) -> void:
  if condition:
    print("PASS: %s" % message)
  else:
    failures += 1
    push_error("FAIL: %s" % message)
