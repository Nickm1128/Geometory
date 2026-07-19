extends Node

const REQUEST_PATH := "user://visual_qa_request.json"
const READY_PATH := "user://visual_qa_ready.json"
const CATALOG_PATH := "res://visual_qa/scenarios.json"

var main_screen: Node

func _ready() -> void:
  call_deferred("_run")

func _run() -> void:
  var request_result := _read_json_object(REQUEST_PATH)
  if not request_result["ok"]:
    _write_ready({}, false, [request_result["error"]])
    return
  var request: Dictionary = request_result["value"]
  var validation_errors := _validate_request(request)
  if not validation_errors.is_empty():
    _write_ready(request, false, validation_errors)
    return

  var scenario_result := _find_scenario(String(request["scenario_id"]))
  if not scenario_result["ok"]:
    _write_ready(request, false, [scenario_result["error"]])
    return
  var scenario: Dictionary = scenario_result["value"]
  if not bool(scenario.get("implemented", false)):
    _write_ready(request, false, ["Scenario is cataloged but not implemented in the P00 fixture harness."])
    return

  main_screen.set("current_seed", int(request["seed"]))
  main_screen.set("ui_scale", float(request["ui_scale"]))
  main_screen.set("reduce_motion", true)
  main_screen.set("show_tips", false)
  var apply_error := await _apply_scenario(String(request["scenario_id"]))
  if apply_error != "":
    _write_ready(request, false, [apply_error])
    return
  for _frame in range(4):
    await get_tree().process_frame

  var assertions := _evaluate_assertions(scenario, request)
  _write_ready(request, assertions["errors"].is_empty(), assertions["errors"], assertions["results"])

func _apply_scenario(scenario_id: String) -> String:
  match scenario_id:
    "main_menu":
      main_screen.call("show_main_menu")
    "quick_play":
      main_screen.call("show_quick_play")
    "how_to_play":
      main_screen.call("show_how_to_play_from_main")
    "settings_default":
      main_screen.call("show_settings_from_main")
    "settings_large_scale":
      main_screen.call("show_settings_from_main")
    "dev_tools":
      main_screen.call("show_dev_tools")
    "allocation_default":
      main_screen.call("start_match")
    "allocation_staged":
      main_screen.call("start_match")
      await get_tree().process_frame
      main_screen.call("_confirm_focus_military")
    "movement_initial", "movement_selected", "movement_pending_path", "movement_confirmed", "movement_paths_off", "end_turn_warning":
      main_screen.call("start_match")
      await get_tree().process_frame
      main_screen.call("_confirm_staged_allocation")
      await get_tree().process_frame
      if scenario_id in ["movement_selected", "movement_pending_path", "movement_confirmed", "movement_paths_off", "end_turn_warning"]:
        main_screen.call("_on_tile_tapped", "T_-4_0")
        await get_tree().process_frame
      if scenario_id in ["movement_pending_path", "movement_confirmed", "movement_paths_off", "end_turn_warning"]:
        main_screen.call("_on_tile_tapped", "T_-2_0")
        await get_tree().process_frame
      if scenario_id in ["movement_confirmed", "movement_paths_off"]:
        main_screen.call("_confirm_selected_move")
        await get_tree().process_frame
      if scenario_id == "movement_paths_off":
        main_screen.call("_toggle_paths")
      elif scenario_id == "end_turn_warning":
        main_screen.call("_end_human_turn")
    "pause":
      main_screen.call("start_match")
      await get_tree().process_frame
      main_screen.call("show_pause")
    "pause_settings":
      main_screen.call("start_match")
      await get_tree().process_frame
      main_screen.call("show_pause")
      await get_tree().process_frame
      main_screen.call("show_settings_from_pause")
    _:
      return "Scenario is not implemented: %s" % scenario_id
  return ""

func _validate_request(request: Dictionary) -> Array[String]:
  var errors: Array[String] = []
  var required := ["schema_version", "nonce", "scenario_id", "seed", "ui_scale", "safe_area_profile", "build_id"]
  for key in request.keys():
    if not required.has(String(key)):
      errors.append("Unknown request field: %s" % key)
  for key in required:
    if not request.has(key):
      errors.append("Missing request field: %s" % key)
  if not errors.is_empty():
    return errors
  if not _is_json_integer(request["schema_version"]) or int(request["schema_version"]) != 1:
    errors.append("Unsupported request schema version.")
  if typeof(request["nonce"]) != TYPE_STRING or not _matches(String(request["nonce"]), "^[A-Za-z0-9_-]{8,64}$"):
    errors.append("Nonce must be 8-64 URL-safe identifier characters.")
  if typeof(request["scenario_id"]) != TYPE_STRING or String(request["scenario_id"]).is_empty() or String(request["scenario_id"]).length() > 64:
    errors.append("Scenario ID must be a non-empty string of at most 64 characters.")
  if not _is_json_integer(request["seed"]) or int(request["seed"]) < 0 or int(request["seed"]) > 2147483647:
    errors.append("Seed must be an integer between 0 and 2147483647.")
  if typeof(request["ui_scale"]) not in [TYPE_INT, TYPE_FLOAT] or float(request["ui_scale"]) not in [1.0, 1.15, 1.30]:
    errors.append("Unsupported UI scale.")
  if typeof(request["safe_area_profile"]) != TYPE_STRING or String(request["safe_area_profile"]) not in ["live", "galaxy_s24_primary"]:
    errors.append("Unsupported safe-area profile.")
  if typeof(request["build_id"]) != TYPE_STRING or not _matches(String(request["build_id"]), "^sha256:[0-9a-f]{64}$"):
    errors.append("Build ID must be a lowercase SHA-256 identifier.")
  return errors

func _find_scenario(scenario_id: String) -> Dictionary:
  var catalog_result := _read_json_object(CATALOG_PATH)
  if not catalog_result["ok"]:
    return catalog_result
  for candidate in catalog_result["value"].get("scenarios", []):
    if String(candidate.get("id", "")) == scenario_id:
      return {"ok": true, "value": candidate}
  return {"ok": false, "error": "Unknown visual QA scenario: %s" % scenario_id}

func _evaluate_assertions(scenario: Dictionary, request: Dictionary) -> Dictionary:
  var errors: Array[String] = []
  var results: Dictionary = {}
  var viewport_size := get_viewport().get_visible_rect().size
  results["main_in_tree"] = main_screen != null and main_screen.is_inside_tree()
  results["viewport_positive"] = viewport_size.x > 0.0 and viewport_size.y > 0.0
  results["seed_applied"] = int(main_screen.get("current_seed")) == int(request["seed"])
  results["ui_scale_applied"] = is_equal_approx(float(main_screen.get("ui_scale")), float(request["ui_scale"]))
  if not results["main_in_tree"]:
    errors.append("Main screen is not inside the scene tree.")
  if not results["viewport_positive"]:
    errors.append("Viewport dimensions are invalid.")
  if not results["seed_applied"]:
    errors.append("The requested seed was not applied to the fixture.")
  if not results["ui_scale_applied"]:
    errors.append("The requested UI scale was not applied to the fixture.")
  for node_name in scenario.get("required_nodes", []):
    var exists := _find_node(main_screen, String(node_name)) != null
    results["node:%s" % node_name] = exists
    if not exists:
      errors.append("Required node is missing: %s" % node_name)
  if String(scenario.get("id", "")) == "allocation_staged":
    var staged_allocation: Dictionary = main_screen.get("allocation_cents")
    var staged_is_distinct := (
      int(staged_allocation.get("military", 0)) > int(staged_allocation.get("economy", 0))
      and int(staged_allocation.get("research", 0)) > int(staged_allocation.get("economy", 0))
    )
    results["allocation_staged_is_distinct"] = staged_is_distinct
    if not staged_is_distinct:
      errors.append("Staged allocation did not differ from the default allocation.")
  return {"errors": errors, "results": results}

func _write_ready(request: Dictionary, success: bool, errors: Array, assertions: Dictionary = {}) -> void:
  var viewport := get_viewport().get_visible_rect()
  var safe_area := DisplayServer.get_display_safe_area()
  var nonce := String(request.get("nonce", ""))
  if not _matches(nonce, "^[A-Za-z0-9_-]{8,64}$"):
    nonce = "invalid00"
  var scenario_id := String(request.get("scenario_id", ""))
  if typeof(request.get("scenario_id", null)) != TYPE_STRING or scenario_id.is_empty() or scenario_id.length() > 64:
    scenario_id = "invalid_request"
  var seed := 0
  if _is_json_integer(request.get("seed", null)) and int(request["seed"]) >= 0 and int(request["seed"]) <= 2147483647:
    seed = int(request["seed"])
  var requested_scale = request.get("ui_scale", null)
  var ui_scale_value := 1.0
  if typeof(requested_scale) in [TYPE_INT, TYPE_FLOAT] and float(requested_scale) in [1.0, 1.15, 1.30]:
    ui_scale_value = float(requested_scale)
  var safe_area_profile := String(request.get("safe_area_profile", ""))
  if safe_area_profile not in ["live", "galaxy_s24_primary"]:
    safe_area_profile = "live"
  var build_id := String(request.get("build_id", ""))
  if not _matches(build_id, "^sha256:[0-9a-f]{64}$"):
    build_id = "sha256:%s" % "0".repeat(64)
  var hash_request := request.duplicate(true)
  hash_request["nonce"] = nonce
  hash_request["scenario_id"] = scenario_id
  hash_request["seed"] = seed
  hash_request["ui_scale"] = ui_scale_value
  hash_request["safe_area_profile"] = safe_area_profile
  hash_request["build_id"] = build_id
  var ready := {
    "schema_version": 1,
    "nonce": nonce,
    "scenario_id": scenario_id,
    "success": success,
    "errors": errors,
    "assertions": assertions,
    "seed": seed,
    "ui_scale": ui_scale_value,
    "safe_area_profile": safe_area_profile,
    "build_id": build_id,
    "viewport": _rect_to_dictionary(viewport),
    "safe_area": _rect_to_dictionary(safe_area),
    "state_hash": _current_state_hash(hash_request)
  }
  var file := FileAccess.open(READY_PATH, FileAccess.WRITE)
  if file == null:
    push_error("Unable to write visual QA ready marker.")
    return
  file.store_string(JSON.stringify(ready, "", true, false))
  file.close()
  print("VISUAL_QA_READY nonce=%s scenario=%s success=%s" % [ready["nonce"], ready["scenario_id"], success])

func _current_state_hash(request: Dictionary) -> String:
  var state_payload: Dictionary
  if main_screen != null and main_screen.get("core") != null:
    return fixture_state_hash(main_screen.get("core").snapshot())
  else:
    var child_names: Array[String] = []
    if main_screen != null:
      for child in main_screen.get_children():
        child_names.append(String(child.name))
    state_payload = {
      "scenario_id": String(request.get("scenario_id", "invalid")),
      "seed": int(request.get("seed", 0)) if typeof(request.get("seed", 0)) == TYPE_INT else 0,
      "ui_scale": float(request.get("ui_scale", 1.15)) if typeof(request.get("ui_scale", 1.15)) in [TYPE_INT, TYPE_FLOAT] else 1.15,
      "child_names": child_names
    }
  return _hash_payload(state_payload)

func fixture_state_hash(snapshot: Dictionary) -> String:
  var state_payload := snapshot.duplicate(true)
  var command_history: Array = state_payload.get("command_history", [])
  for index in range(command_history.size()):
    if command_history[index] is Dictionary:
      var command: Dictionary = command_history[index]
      command.erase("client_sequence")
      command_history[index] = command
  state_payload["command_history"] = command_history
  return _hash_payload(state_payload)

func _hash_payload(payload: Dictionary) -> String:
  var canonical := JSON.stringify(payload, "", true, false)
  var context := HashingContext.new()
  context.start(HashingContext.HASH_SHA256)
  context.update(canonical.to_utf8_buffer())
  return context.finish().hex_encode()

func _matches(value: String, pattern: String) -> bool:
  var expression := RegEx.new()
  if expression.compile(pattern) != OK:
    return false
  return expression.search(value) != null

func _is_json_integer(value) -> bool:
  if typeof(value) == TYPE_INT:
    return true
  if typeof(value) != TYPE_FLOAT:
    return false
  var numeric := float(value)
  return is_finite(numeric) and floor(numeric) == numeric

func _read_json_object(path: String) -> Dictionary:
  if not FileAccess.file_exists(path):
    return {"ok": false, "error": "JSON file is missing: %s" % path}
  var file := FileAccess.open(path, FileAccess.READ)
  if file == null:
    return {"ok": false, "error": "Unable to open JSON file: %s" % path}
  var parsed = JSON.parse_string(file.get_as_text())
  file.close()
  if not parsed is Dictionary:
    return {"ok": false, "error": "JSON root must be an object: %s" % path}
  return {"ok": true, "value": parsed}

func _find_node(root_node: Node, target_name: String) -> Node:
  if root_node == null or root_node.is_queued_for_deletion():
    return null
  if root_node.name == target_name:
    return root_node
  for child in root_node.get_children():
    var found := _find_node(child, target_name)
    if found != null:
      return found
  return null

func _rect_to_dictionary(rect) -> Dictionary:
  return {
    "x": int(rect.position.x),
    "y": int(rect.position.y),
    "width": int(rect.size.x),
    "height": int(rect.size.y)
  }
