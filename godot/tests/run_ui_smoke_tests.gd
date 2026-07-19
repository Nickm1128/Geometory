extends SceneTree

const MainScene := preload("res://scenes/main/Main.tscn")

var failures := 0

func _init() -> void:
  call_deferred("_run")

func _run() -> void:
  var sizes: Array[Vector2i] = [Vector2i(393, 852), Vector2i(360, 800), Vector2i(480, 960)]
  for test_size in sizes:
    await _run_size_case(test_size)

  if failures == 0:
    print("All Geometory UI smoke tests passed.")
    quit(0)
  else:
    push_error("%d Geometory UI smoke test(s) failed." % failures)
    quit(1)

func _run_size_case(test_size: Vector2i) -> void:
  print("UI smoke size: %sx%s" % [test_size.x, test_size.y])
  get_root().size = test_size
  DisplayServer.window_set_size(test_size)
  await process_frame

  var main = MainScene.instantiate()
  get_root().add_child(main)
  await process_frame
  main.call("start_match")
  await process_frame
  await process_frame
  await process_frame

  _assert(main.get("core") != null, "match core exists at %s" % _size_text(test_size))
  _assert(main.get("core").get_phase() == "allocation", "starts in allocation at %s" % _size_text(test_size))

  var map_view = _find_node(main, "MapView")
  _assert(map_view != null, "MapView exists at %s" % _size_text(test_size))
  if map_view != null:
    var layout: Dictionary = map_view.call("get_debug_layout")
    var rect: Rect2 = layout["board_rect"]
    _assert(float(layout["hex_radius"]) > 0.0, "MapView has positive hex radius at %s" % _size_text(test_size))
    _assert(rect.size.x > 0.0 and rect.size.y > 0.0, "MapView has positive board rect at %s" % _size_text(test_size))
    _assert(int(layout["visible_tile_count"]) > 0, "MapView has visible tiles at %s" % _size_text(test_size))
    _assert(bool(layout["show_paths"]), "paths default on at %s" % _size_text(test_size))
    _assert(String(layout["path_focus_mode"]) == "all", "path focus defaults to all at %s" % _size_text(test_size))
    _assert(String(layout["render_quality"]) == "layered_cached", "MapView uses layered cached render path at %s" % _size_text(test_size))
    _assert(int(layout["tile_geometry_count"]) > 0, "MapView caches tile geometry at %s" % _size_text(test_size))
    _assert(int(layout["screen_geometry_count"]) > 0, "MapView caches screen geometry at %s" % _size_text(test_size))
    _assert(bool(layout["fog_layer_visible"]), "fog layer is visible at %s" % _size_text(test_size))
    _assert(bool(layout["wall_layer_visible"]), "wall layer is visible at %s" % _size_text(test_size))
    _assert(bool(layout["queued_path_layer_visible"]), "queued path layer is enabled at %s" % _size_text(test_size))
    await _run_camera_case(map_view, test_size)

  var phase_label = _find_node(main, "HudPhaseLabel")
  var money_label = _find_node(main, "HudMoneyLabel")
  _assert(phase_label != null and String(phase_label.text) != "", "HUD phase text populated at %s" % _size_text(test_size))
  _assert(money_label != null and String(money_label.text) != "", "HUD money text populated at %s" % _size_text(test_size))

  _assert(_find_node(main, "AllocationEconomyRow") != null, "Economy allocation row exists at %s" % _size_text(test_size))
  _assert(_find_node(main, "AllocationMilitaryRow") != null, "Military allocation row exists at %s" % _size_text(test_size))
  _assert(_find_node(main, "AllocationResearchRow") != null, "Research allocation row exists at %s" % _size_text(test_size))
  _assert(_find_node(main, "AllocationSpendBar") != null, "Allocation spend bar exists at %s" % _size_text(test_size))
  _assert(_find_node(main, "ActionChipsRow") != null, "Action chips exist at %s" % _size_text(test_size))
  _assert(_find_node(main, "AutoBalanceButton") != null, "Auto Balance button exists at %s" % _size_text(test_size))
  _assert(_find_node(main, "FocusMilitaryButton") != null, "Focus Military button exists at %s" % _size_text(test_size))
  _assert(_find_node(main, "AllocationUnspentLabel") != null, "Unspent label exists at %s" % _size_text(test_size))

  var allocation_confirm = _find_node(main, "ConfirmAllocationButton")
  _assert(allocation_confirm != null, "Confirm Allocation button exists at %s" % _size_text(test_size))
  if allocation_confirm != null:
    _assert(allocation_confirm.custom_minimum_size.y >= 56.0 * float(main.get("ui_scale")) - 0.5, "Confirm Allocation touch target meets 56dp at %s" % _size_text(test_size))

  main.call("_confirm_staged_allocation")
  await process_frame
  await process_frame

  _assert(main.get("core").get_phase() == "movement", "confirm allocation enters movement at %s" % _size_text(test_size))
  _assert(_find_node(main, "MovementTitle") != null, "Movement title exists at %s" % _size_text(test_size))
  _assert(_find_node(main, "PathToggleButton") != null, "Path toggle button exists at %s" % _size_text(test_size))
  _assert(_find_node(main, "EndTurnButton") != null, "End Turn button exists at %s" % _size_text(test_size))
  _assert(_guide_text(main) == "Tap a soldier tile to move them.", "movement guide starts with soldier-tap instruction at %s" % _size_text(test_size))

  main.set("visual_diagnostics", true)
  main.call("_refresh_match_ui")
  await process_frame
  _assert(_find_node(main, "VisualDiagnosticsLabel") != null, "visual diagnostics label appears at %s" % _size_text(test_size))
  if map_view != null:
    _assert(bool(map_view.call("get_debug_layout")["visual_diagnostics"]), "MapView diagnostics state is set at %s" % _size_text(test_size))

  main.call("_toggle_paths")
  await process_frame
  _assert(not bool(main.get("show_paths")), "path toggle turns off at %s" % _size_text(test_size))
  if map_view != null:
    _assert(not bool(map_view.call("get_debug_layout")["show_paths"]), "MapView sees paths off at %s" % _size_text(test_size))
  main.call("_toggle_paths")
  await process_frame
  _assert(bool(main.get("show_paths")), "path toggle turns on at %s" % _size_text(test_size))

  var p1_stack: String = main.get("core").get_stack_at_tile_for_player("T_-4_0", "P1")
  _assert(p1_stack != "", "P1 starting stack exists at %s" % _size_text(test_size))

  main.call("_on_tile_tapped", "T_-4_0")
  await process_frame
  await process_frame
  _assert(String(main.get("selected_stack_id")) == p1_stack, "tap stack selects immediately at %s" % _size_text(test_size))
  _assert(Array(main.get("pending_path")).is_empty(), "selecting stack does not create pending path at %s" % _size_text(test_size))
  _assert(_guide_text(main) == "Select a destination tile.", "guide asks for destination after stack selection at %s" % _size_text(test_size))
  _assert(_find_node(main, "CancelSelectionButton") != null, "Cancel Selection appears at %s" % _size_text(test_size))
  if map_view != null:
    var selected_layout: Dictionary = map_view.call("get_debug_layout")
    _assert(String(selected_layout["selected_stack_id"]) == p1_stack, "MapView selected stack set at %s" % _size_text(test_size))
    _assert(String(selected_layout["path_focus_mode"]) == "selected", "selected stack focuses paths at %s" % _size_text(test_size))

  main.call("_on_tile_tapped", "T_-2_0")
  await process_frame
  await process_frame
  _assert(Array(main.get("pending_path")).size() > 0, "destination tap creates pending path at %s" % _size_text(test_size))
  _assert(String(main.get("pending_destination_tile_id")) == "T_-2_0", "pending destination is stored at %s" % _size_text(test_size))
  _assert(_guide_text(main) == "Confirm this move.", "guide asks to confirm after destination at %s" % _size_text(test_size))
  var move_confirm = _find_node(main, "ConfirmMoveButton")
  _assert(move_confirm != null, "Confirm Move appears after destination at %s" % _size_text(test_size))
  if move_confirm != null:
    _assert(move_confirm.custom_minimum_size.y >= 56.0 * float(main.get("ui_scale")) - 0.5, "Confirm Move touch target meets 56dp at %s" % _size_text(test_size))
  if map_view != null:
    var pending_layout: Dictionary = map_view.call("get_debug_layout")
    _assert(int(pending_layout["pending_path_count"]) > 0, "MapView has pending path at %s" % _size_text(test_size))

  main.call("_end_human_turn")
  await process_frame
  _assert(_find_node(main, "EndTurnConfirmOverlay") != null, "unconfirmed move opens end-turn warning at %s" % _size_text(test_size))
  _assert(_find_node(main, "GoBackButton") != null, "Go Back exists on warning at %s" % _size_text(test_size))
  _assert(_find_node(main, "EndWithoutMoveButton") != null, "End Without Move exists on warning at %s" % _size_text(test_size))
  main.call("_dismiss_end_turn_confirm")
  await process_frame
  _assert(_find_node(main, "EndTurnConfirmOverlay") == null, "Go Back dismisses warning at %s" % _size_text(test_size))
  _assert(main.get("core").get_phase() == "movement", "Go Back keeps movement phase at %s" % _size_text(test_size))

  main.call("_confirm_selected_move")
  await process_frame
  await process_frame
  var stack_state: Dictionary = main.get("core").snapshot()["stacks"][p1_stack]
  _assert(stack_state.get("waypoints", []).size() > 0, "Confirm Move queues stack path at %s" % _size_text(test_size))
  _assert(Array(main.get("pending_path")).is_empty(), "Confirm Move clears pending path at %s" % _size_text(test_size))
  if map_view != null:
    var queued_layout: Dictionary = map_view.call("get_debug_layout")
    _assert(int(queued_layout["queued_path_count"]) > 0, "MapView reports queued selected path at %s" % _size_text(test_size))

  main.call("_on_tile_tapped", "T_-1_0")
  await process_frame
  _assert(Array(main.get("pending_path")).size() > 0, "second destination creates unconfirmed path at %s" % _size_text(test_size))
  main.call("_end_human_turn")
  await process_frame
  _assert(_find_node(main, "EndTurnConfirmOverlay") != null, "second unconfirmed move opens warning at %s" % _size_text(test_size))
  main.call("_end_turn_without_pending_move")
  await process_frame
  await process_frame
  _assert(Array(main.get("pending_path")).is_empty(), "End Without Move clears pending path at %s" % _size_text(test_size))
  _assert(main.get("core").get_active_player() == "P1", "End Without Move returns to human after bot at %s" % _size_text(test_size))

  main.queue_free()
  await process_frame

func _run_camera_case(map_view: Node, test_size: Vector2i) -> void:
  var layout: Dictionary = map_view.call("get_debug_layout")
  var rect: Rect2 = layout["board_rect"]
  var pivot = rect.get_center()
  var zoom_before = float(layout["target_zoom"])
  map_view.call("debug_simulate_zoom", 1.5, pivot)
  await process_frame
  var zoomed: Dictionary = map_view.call("get_debug_layout")
  _assert(float(zoomed["target_zoom"]) > zoom_before, "debug zoom changes target zoom at %s" % _size_text(test_size))

  var pan_before: Vector2 = zoomed["target_pan"]
  map_view.call("debug_simulate_drag", Vector2(44, -22))
  await process_frame
  var dragged: Dictionary = map_view.call("get_debug_layout")
  var pan_after: Vector2 = dragged["target_pan"]
  _assert(pan_before.distance_to(pan_after) > 0.1, "debug drag changes target pan at %s" % _size_text(test_size))

  var pinch_before = float(dragged["target_zoom"])
  map_view.call("debug_simulate_pinch_zoom", 0.86, pivot)
  await process_frame
  var pinched: Dictionary = map_view.call("get_debug_layout")
  _assert(float(pinched["target_zoom"]) < pinch_before, "debug pinch changes target zoom at %s" % _size_text(test_size))

  var tap_counter = {"count": 0}
  map_view.connect("tile_tapped", func(_tile_id: String) -> void:
    tap_counter["count"] = int(tap_counter["count"]) + 1
  )
  var press = InputEventMouseButton.new()
  press.button_index = MOUSE_BUTTON_LEFT
  press.pressed = true
  press.position = pivot
  map_view.call("_handle_mouse_button", press)
  var motion = InputEventMouseMotion.new()
  motion.position = pivot + Vector2(52, 0)
  map_view.call("_gui_input", motion)
  var release = InputEventMouseButton.new()
  release.button_index = MOUSE_BUTTON_LEFT
  release.pressed = false
  release.position = motion.position
  map_view.call("_handle_mouse_button", release)
  await process_frame
  _assert(int(tap_counter["count"]) == 0, "mouse drag does not emit a tile tap at %s" % _size_text(test_size))

func _guide_text(main: Node) -> String:
  var guide = _find_node(main, "MovementGuideLabel")
  if guide == null:
    return ""
  return String(guide.text)

func _find_node(root_node: Node, target_name: String) -> Node:
  if root_node.is_queued_for_deletion():
    return null
  if root_node.name == target_name:
    return root_node
  for child in root_node.get_children():
    var found = _find_node(child, target_name)
    if found != null:
      return found
  return null

func _size_text(test_size: Vector2i) -> String:
  return "%sx%s" % [test_size.x, test_size.y]

func _assert(condition: bool, message: String) -> void:
  if condition:
    print("PASS: %s" % message)
  else:
    failures += 1
    push_error("FAIL: %s" % message)
