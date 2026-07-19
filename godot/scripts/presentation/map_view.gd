class_name GeometoryMapView
extends Control

const HexUtils = preload("res://scripts/core/hex_utils.gd")
const UiTheme = preload("res://scripts/presentation/ui_theme.gd")
const NEUTRAL = "neutral"

signal tile_tapped(tile_id: String)

var core
var player_id = "P1"
var selected_stack_id = ""
var pending_path: Array[String] = []
var show_paths = true
var reduce_motion = false
var visual_diagnostics = false
var visible_tiles: Dictionary = {}
var hex_radius = 18.0
var zoom = 1.0
var target_zoom = 1.0
var pan = Vector2.ZERO
var target_pan = Vector2.ZERO
var pan_velocity = Vector2.ZERO
var board_rect = Rect2(Vector2.ZERO, Vector2.ZERO)
var dragging = false
var drag_last = Vector2.ZERO
var drag_last_msec = 0
var touch_start = Vector2.ZERO
var touch_moved = false
var fit_pending = false
var active_touches: Dictionary = {}
var pinch_active = false
var pinch_start_distance = 0.0
var pinch_start_zoom = 1.0
var last_pinch_center = Vector2.ZERO
var tile_ids: Array[String] = []
var tile_world_positions: Dictionary = {}
var tile_centers: Dictionary = {}
var tile_polygons: Dictionary = {}
var tile_inner_polygons: Dictionary = {}
var world_min = Vector2.ZERO
var world_max = Vector2.ZERO
var geometry_dirty = true
var screen_geometry_signature = ""
var intro_start_msec = -1
var pending_path_key = ""
var pending_path_start_msec = -1
var selected_start_msec = -1
var confirm_flash_msec = -1
var layer_flags = {
  "tiles": true,
  "fog": true,
  "walls": true,
  "queued_paths": true,
  "pending_path": true,
  "selection": true,
  "stacks": true,
  "texture": true
}

func _ready() -> void:
  mouse_filter = Control.MOUSE_FILTER_STOP
  clip_contents = true
  set_process(true)
  if board_rect.size == Vector2.ZERO:
    board_rect = Rect2(Vector2.ZERO, size)
  _request_fit()

func _process(delta: float) -> void:
  _apply_camera_inertia(delta)
  _smooth_camera(delta)
  if intro_start_msec >= 0 or pending_path_start_msec >= 0 or selected_start_msec >= 0 or confirm_flash_msec >= 0 or visual_diagnostics:
    queue_redraw()

func _notification(what: int) -> void:
  if what == NOTIFICATION_RESIZED:
    if board_rect.size == Vector2.ZERO:
      board_rect = Rect2(Vector2.ZERO, size)
    _request_fit()
    queue_redraw()

func set_core(new_core) -> void:
  core = new_core
  geometry_dirty = true
  refresh_visibility()
  _request_fit()
  queue_redraw()

func set_board_rect(rect: Rect2) -> void:
  var changed = rect.position.distance_to(board_rect.position) > 0.5 or rect.size.distance_to(board_rect.size) > 0.5
  board_rect = rect
  if changed:
    _request_fit()
  queue_redraw()

func set_presentation_state(stack_id: String, path: Array[String], paths_visible: bool) -> void:
  if selected_stack_id != stack_id:
    selected_start_msec = Time.get_ticks_msec() if stack_id != "" else -1
  selected_stack_id = stack_id
  var next_key = _path_key(path)
  if pending_path_key != next_key:
    pending_path_start_msec = Time.get_ticks_msec() if not path.is_empty() else -1
    pending_path_key = next_key
  pending_path = path.duplicate()
  show_paths = paths_visible
  queue_redraw()

func set_selection(stack_id: String, path: Array[String]) -> void:
  set_presentation_state(stack_id, path, show_paths)

func set_visual_options(reduced: bool, diagnostics_visible: bool) -> void:
  reduce_motion = reduced
  visual_diagnostics = diagnostics_visible
  if reduce_motion:
    intro_start_msec = -1
  queue_redraw()

func play_intro(enabled: bool = true) -> void:
  intro_start_msec = Time.get_ticks_msec() if enabled and not reduce_motion else -1
  queue_redraw()

func play_confirm_flash() -> void:
  if reduce_motion:
    return
  confirm_flash_msec = Time.get_ticks_msec()
  queue_redraw()

func refresh_visibility() -> void:
  if core == null:
    visible_tiles = {}
    return
  visible_tiles = core.visible_tile_ids(player_id)

func get_debug_layout() -> Dictionary:
  refresh_visibility()
  _ensure_screen_geometry()
  return {
    "hex_radius": hex_radius,
    "board_rect": board_rect,
    "pan": pan,
    "target_pan": target_pan,
    "zoom": zoom,
    "target_zoom": target_zoom,
    "pan_velocity": pan_velocity,
    "pan_bounds": _debug_pan_bounds(),
    "visible_tile_count": visible_tiles.size(),
    "selected_stack_id": selected_stack_id,
    "pending_path_count": pending_path.size(),
    "show_paths": show_paths,
    "path_focus_mode": "selected" if selected_stack_id != "" else "all",
    "queued_path_count": _queued_path_count(),
    "render_quality": "layered_cached",
    "tile_geometry_count": tile_ids.size(),
    "screen_geometry_count": tile_centers.size(),
    "intro_progress": _intro_progress(),
    "fog_layer_visible": bool(layer_flags["fog"]),
    "wall_layer_visible": bool(layer_flags["walls"]),
    "queued_path_layer_visible": bool(layer_flags["queued_paths"]),
    "pending_path_layer_visible": bool(layer_flags["pending_path"]),
    "selection_layer_visible": bool(layer_flags["selection"]),
    "visual_diagnostics": visual_diagnostics
  }

func debug_simulate_drag(delta: Vector2) -> void:
  target_pan += delta
  pan_velocity = delta * 18.0
  _clamp_target_pan()
  queue_redraw()

func debug_simulate_zoom(factor: float, pivot: Vector2) -> void:
  _set_zoom(target_zoom * factor, pivot)

func debug_simulate_pinch_zoom(factor: float, pivot: Vector2) -> void:
  pinch_active = true
  _set_zoom(target_zoom * factor, pivot)
  pinch_active = false
  touch_moved = true

func _draw() -> void:
  _draw_background()
  if core == null:
    return
  visible_tiles = core.visible_tile_ids(player_id)
  _ensure_screen_geometry()
  var state = core.snapshot()
  if bool(layer_flags["tiles"]):
    for tile_id in tile_ids:
      _draw_tile(tile_id, state["tiles"][tile_id])
  if bool(layer_flags["walls"]):
    for wall in state["walls"].values():
      _draw_wall(wall)
  if bool(layer_flags["queued_paths"]):
    _draw_queued_paths()
  if bool(layer_flags["pending_path"]):
    _draw_pending_path()
  if bool(layer_flags["selection"]):
    _draw_selected_tile_glow()
  if bool(layer_flags["stacks"]):
    for stack in state["stacks"].values():
      _draw_stack(stack)
  _draw_confirm_flash()
  if visual_diagnostics:
    _draw_visual_diagnostics()

func _gui_input(event: InputEvent) -> void:
  if core == null:
    return
  if event is InputEventMouseButton:
    _handle_mouse_button(event as InputEventMouseButton)
  elif event is InputEventMouseMotion and dragging:
    var motion = event as InputEventMouseMotion
    _drag_by(motion.position - drag_last, motion.position)
    accept_event()
  elif event is InputEventScreenTouch:
    _handle_screen_touch(event as InputEventScreenTouch)
  elif event is InputEventScreenDrag:
    _handle_screen_drag(event as InputEventScreenDrag)

func _handle_mouse_button(mouse_event: InputEventMouseButton) -> void:
  if not board_rect.has_point(mouse_event.position) and not dragging:
    return
  if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP and mouse_event.pressed:
    _set_zoom(target_zoom * 1.13, mouse_event.position)
    accept_event()
  elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse_event.pressed:
    _set_zoom(target_zoom / 1.13, mouse_event.position)
    accept_event()
  elif mouse_event.button_index == MOUSE_BUTTON_LEFT:
    if mouse_event.pressed:
      dragging = true
      drag_last = mouse_event.position
      drag_last_msec = Time.get_ticks_msec()
      touch_start = mouse_event.position
      touch_moved = false
      pan_velocity = Vector2.ZERO
    else:
      dragging = false
      if not touch_moved:
        _emit_tile_at(mouse_event.position)
    accept_event()

func _handle_screen_touch(touch: InputEventScreenTouch) -> void:
  if touch.pressed:
    if not board_rect.has_point(touch.position) and not dragging:
      return
    active_touches[touch.index] = touch.position
    if active_touches.size() >= 2:
      _start_pinch()
      dragging = false
      touch_moved = true
      pan_velocity = Vector2.ZERO
    else:
      dragging = true
      drag_last = touch.position
      drag_last_msec = Time.get_ticks_msec()
      touch_start = touch.position
      touch_moved = false
      pan_velocity = Vector2.ZERO
  else:
    active_touches.erase(touch.index)
    if pinch_active:
      pinch_active = false
      touch_moved = true
    elif dragging:
      dragging = false
      if not touch_moved:
        _emit_tile_at(touch.position)
    if active_touches.is_empty():
      dragging = false
  accept_event()

func _handle_screen_drag(drag: InputEventScreenDrag) -> void:
  if active_touches.has(drag.index):
    active_touches[drag.index] = drag.position
  if active_touches.size() >= 2:
    _update_pinch()
    accept_event()
    return
  if not dragging:
    return
  _drag_by(drag.relative, drag.position)
  accept_event()

func _drag_by(delta: Vector2, position: Vector2) -> void:
  if delta.length() > 3.5:
    touch_moved = true
  target_pan += delta
  var now = Time.get_ticks_msec()
  var elapsed = max(0.016, float(now - drag_last_msec) / 1000.0)
  pan_velocity = delta / elapsed
  drag_last = position
  drag_last_msec = now
  _clamp_target_pan()
  queue_redraw()

func _start_pinch() -> void:
  var positions = active_touches.values()
  if positions.size() < 2:
    return
  pinch_start_distance = Vector2(positions[0]).distance_to(Vector2(positions[1]))
  pinch_start_zoom = target_zoom
  last_pinch_center = (Vector2(positions[0]) + Vector2(positions[1])) * 0.5
  pinch_active = true

func _update_pinch() -> void:
  var positions = active_touches.values()
  if positions.size() < 2 or pinch_start_distance <= 1.0:
    return
  var a = Vector2(positions[0])
  var b = Vector2(positions[1])
  var center = (a + b) * 0.5
  target_pan += center - last_pinch_center
  last_pinch_center = center
  var distance = a.distance_to(b)
  _set_zoom(pinch_start_zoom * distance / pinch_start_distance, center)
  touch_moved = true

func _apply_camera_inertia(delta: float) -> void:
  if dragging or pinch_active or pan_velocity.length() <= 1.0:
    return
  target_pan += pan_velocity * delta
  pan_velocity = pan_velocity.move_toward(Vector2.ZERO, UiTheme.CAMERA_FRICTION * delta)
  _clamp_target_pan()

func _smooth_camera(delta: float) -> void:
  _clamp_target_pan()
  var response = UiTheme.CAMERA_RESPONSE_REDUCED if reduce_motion else UiTheme.CAMERA_RESPONSE
  var amount = clamp(1.0 - exp(-response * delta), 0.0, 1.0)
  var moved = false
  if pan.distance_to(target_pan) > 0.05:
    pan = pan.lerp(target_pan, amount)
    moved = true
  else:
    pan = target_pan
  if abs(zoom - target_zoom) > 0.001:
    zoom = lerp(zoom, target_zoom, amount)
    moved = true
  else:
    zoom = target_zoom
  if moved:
    screen_geometry_signature = ""
    queue_redraw()

func _draw_background() -> void:
  draw_rect(Rect2(Vector2.ZERO, size), UiTheme.BACKGROUND, true)
  if board_rect.size == Vector2.ZERO:
    return
  draw_rect(board_rect, UiTheme.BACKGROUND_ALT, true)
  var horizon = Rect2(board_rect.position, Vector2(board_rect.size.x, board_rect.size.y * 0.42))
  draw_rect(horizon, Color("#0E2231", 0.45), true)
  var step = max(16.0, hex_radius * zoom * 1.5)
  var x = board_rect.position.x + fposmod(-target_pan.x, step)
  while x < board_rect.end.x:
    draw_line(Vector2(x, board_rect.position.y), Vector2(x, board_rect.end.y), UiTheme.GRID_FAINT, 1.0, true)
    x += step
  var y = board_rect.position.y + fposmod(-target_pan.y, step)
  while y < board_rect.end.y:
    draw_line(Vector2(board_rect.position.x, y), Vector2(board_rect.end.x, y), UiTheme.GRID_FAINT, 1.0, true)
    y += step
  if bool(layer_flags["texture"]):
    _draw_grain(board_rect)
  draw_rect(board_rect, Color("#D9FAFF", 0.08), false, 1.0)

func _draw_grain(rect: Rect2) -> void:
  for i in range(72):
    var px = rect.position.x + _hash_unit("grain_x_%d" % i) * rect.size.x
    var py = rect.position.y + _hash_unit("grain_y_%d" % i) * rect.size.y
    var alpha = 0.018 + _hash_unit("grain_a_%d" % i) * 0.028
    draw_circle(Vector2(px, py), 0.8 + _hash_unit("grain_r_%d" % i) * 1.3, Color("#D6F7FF", alpha))

func _draw_tile(tile_id: String, tile: Dictionary) -> void:
  var center: Vector2 = tile_centers.get(tile_id, _tile_screen_position(tile_id))
  var points: PackedVector2Array = tile_polygons.get(tile_id, PackedVector2Array(HexUtils.polygon_points(center, hex_radius * zoom * 0.94)))
  var inner: PackedVector2Array = tile_inner_polygons.get(tile_id, PackedVector2Array(HexUtils.polygon_points(center, hex_radius * zoom * 0.68)))
  var is_visible = visible_tiles.has(tile_id)
  var owner = String(tile["controlled_by"]) if is_visible else "fog"
  var reveal = _tile_intro_alpha(tile_id)
  if reveal <= 0.02:
    return

  var fill = _tile_fill(owner, is_visible)
  fill.a *= reveal
  draw_colored_polygon(points, fill)

  var inner_fill = fill.lightened(0.06 if is_visible else 0.01)
  inner_fill.a *= 0.42
  draw_colored_polygon(inner, inner_fill)

  if is_visible and owner != NEUTRAL:
    var accent = _owner_color(owner)
    accent.a = 0.34 * reveal
    var accent_outline = PackedVector2Array(points)
    accent_outline.append(points[0])
    draw_polyline(accent_outline, accent, max(1.2, 1.6 * zoom), true)

  if is_visible:
    _draw_tile_texture(tile_id, center, reveal)
  elif bool(layer_flags["fog"]):
    var fog = UiTheme.FOG
    fog.a *= reveal
    draw_colored_polygon(points, fog)

  var line_color = UiTheme.GRID
  line_color.a = (0.20 if is_visible else 0.07) * reveal
  var outline = PackedVector2Array(points)
  outline.append(points[0])
  draw_polyline(outline, line_color, max(1.0, 1.12 * zoom), true)

  if String(tile.get("capital_owner", "")) != "" and is_visible:
    _draw_capital_marker(center, String(tile["capital_owner"]), reveal)

func _draw_tile_texture(tile_id: String, center: Vector2, reveal: float) -> void:
  var scratch = Color("#FFFFFF", 0.026 * reveal)
  var angle = _hash_unit(tile_id + "angle") * TAU
  var radius = hex_radius * zoom * (0.22 + _hash_unit(tile_id + "r") * 0.20)
  var a = center + Vector2(cos(angle), sin(angle)) * radius
  var b = center + Vector2(cos(angle + PI), sin(angle + PI)) * radius * 0.48
  draw_line(a, b, scratch, 1.0, true)

func _draw_capital_marker(center: Vector2, owner: String, reveal: float) -> void:
  var color = _owner_color(owner).lerp(UiTheme.WARN, 0.35)
  color.a = 0.94 * reveal
  draw_circle(center, max(3.5, 4.8 * zoom), Color("#FFF7CC", 0.92 * reveal))
  draw_arc(center, max(7.2, 8.4 * zoom), 0.0, TAU, 32, color, max(1.7, 2.0 * zoom), true)
  draw_arc(center, max(11.0, 12.8 * zoom), -PI * 0.15, PI * 0.85, 24, Color("#FFFFFF", 0.34 * reveal), max(1.0, 1.2 * zoom), true)

func _draw_wall(wall: Dictionary) -> void:
  if bool(wall["destroyed"]):
    return
  if not visible_tiles.has(wall["from"]) and not visible_tiles.has(wall["to"]):
    return
  var a = _tile_screen_position(String(wall["from"]))
  var b = _tile_screen_position(String(wall["to"]))
  var mid = (a + b) * 0.5
  var dir = (b - a).normalized()
  var normal = Vector2(-dir.y, dir.x)
  var length = hex_radius * zoom * 0.68
  var hp_ratio = clamp(float(wall["hp"]) / float(wall["max_hp"]), 0.0, 1.0)
  var color = UiTheme.WARN.lerp(UiTheme.DANGER, 1.0 - hp_ratio)
  var start = mid - normal * length * 0.5
  var end = mid + normal * length * 0.5
  draw_line(start, end, Color("#020508", 0.78), max(3.0, 5.0 * zoom), true)
  draw_line(start, end, color, max(2.0, 3.0 * zoom), true)
  draw_circle(start, max(1.8, 2.1 * zoom), color)
  draw_circle(end, max(1.8, 2.1 * zoom), color)

func _draw_selected_tile_glow() -> void:
  if selected_stack_id == "" or core == null:
    return
  var state = core.snapshot()
  if not state["stacks"].has(selected_stack_id):
    return
  var tile_id = String(state["stacks"][selected_stack_id]["tile_id"])
  if not visible_tiles.has(tile_id):
    return
  var center = _tile_screen_position(tile_id)
  var pulse = _selection_pulse()
  var points = HexUtils.polygon_points(center, hex_radius * zoom * (1.05 + 0.05 * pulse))
  draw_colored_polygon(points, Color("#FFFFFF", 0.10 + 0.06 * pulse))
  var outline = PackedVector2Array(points)
  outline.append(points[0])
  draw_polyline(outline, Color("#FFFFFF", 0.82), max(2.0, 2.8 * zoom), true)
  draw_arc(center, hex_radius * zoom * (0.72 + 0.08 * pulse), 0.0, TAU, 36, UiTheme.WARN, max(1.4, 1.8 * zoom), true)

func _draw_stack(stack: Dictionary) -> void:
  var tile_id = String(stack["tile_id"])
  if not visible_tiles.has(tile_id) and stack["owner"] != player_id:
    return
  var center = _tile_screen_position(tile_id)
  var owner = String(stack["owner"])
  var color = _owner_color(owner)
  var radius = max(5.0, hex_radius * zoom * 0.36)
  var is_selected = String(stack["id"]) == selected_stack_id
  var reveal = _tile_intro_alpha(tile_id)
  if reveal <= 0.02:
    return
  if is_selected:
    var pulse = _selection_pulse()
    draw_circle(center, radius + (7.0 + 3.0 * pulse) * zoom, Color("#FFFFFF", 0.10 + 0.04 * pulse))
    draw_arc(center, radius + 9.0 * zoom, 0.0, TAU, 42, Color("#FFFFFF", 0.95), max(2.0, 2.4 * zoom), true)
    draw_arc(center, radius + 14.0 * zoom, 0.0, TAU, 42, UiTheme.WARN, max(1.5, 1.9 * zoom), true)
  draw_circle(center + Vector2(0, 1.5 * zoom), radius + 2.0 * zoom, Color("#020508", 0.68 * reveal))
  draw_circle(center, radius, Color("#071019", 0.94 * reveal))
  draw_arc(center, radius + 2.0 * zoom, 0.0, TAU, 36, color, max(1.8, 2.4 * zoom), true)
  draw_arc(center, radius - 2.4 * zoom, -PI * 0.20, PI * 0.80, 24, Color("#FFFFFF", 0.16 * reveal), max(1.0, 1.2 * zoom), true)
  var soldiers = 0
  for cohort in stack["cohorts"]:
    soldiers += int(cohort["count"])
  _draw_centered_stack_text(str(soldiers), center, max(10.0, 12.0 * zoom), reveal)

func _draw_centered_stack_text(text: String, center: Vector2, font_size: float, alpha: float = 1.0) -> void:
  var font = ThemeDB.fallback_font
  var size_px = int(round(font_size))
  var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size_px)
  var ascent = font.get_ascent(size_px)
  var descent = font.get_descent(size_px)
  var baseline = center + Vector2(-text_size.x * 0.5, (ascent - descent) * 0.5)
  draw_string(font, baseline + Vector2(0.8, 0.8), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size_px, Color("#000000", 0.62 * alpha))
  draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size_px, Color("#FFFFFF", alpha))

func _draw_queued_paths() -> void:
  if not show_paths or core == null:
    return
  var state = core.snapshot()
  for stack_id in state["stacks"].keys():
    var stack: Dictionary = state["stacks"][stack_id]
    if String(stack["owner"]) != player_id:
      continue
    if selected_stack_id != "" and String(stack_id) != selected_stack_id:
      continue
    var waypoints: Array = stack.get("waypoints", [])
    if waypoints.is_empty():
      continue
    var points = PackedVector2Array()
    points.append(_tile_screen_position(String(stack["tile_id"])))
    for waypoint in waypoints:
      points.append(_tile_screen_position(String(waypoint)))
    var color = UiTheme.WARN if String(stack_id) == selected_stack_id else UiTheme.ACCENT
    color.a = 0.72 if String(stack_id) == selected_stack_id else 0.46
    _draw_path_points(points, color, max(1.4, 1.8 * zoom), false, 1.0)

func _draw_pending_path() -> void:
  if pending_path.is_empty() or selected_stack_id == "" or core == null:
    return
  var state = core.snapshot()
  if not state["stacks"].has(selected_stack_id):
    return
  var points = PackedVector2Array()
  points.append(_tile_screen_position(String(state["stacks"][selected_stack_id]["tile_id"])))
  for tile_id in pending_path:
    points.append(_tile_screen_position(tile_id))
  _draw_path_points(points, Color("#FFFFFF", 0.94), max(2.4, 3.1 * zoom), true, _pending_path_progress())

func _draw_path_points(points: PackedVector2Array, color: Color, width: float, emphasize_destination: bool, progress: float) -> void:
  if points.size() < 2:
    return
  var path_color = color
  path_color.a *= 0.35 + 0.65 * progress
  draw_polyline(points, Color("#020508", 0.50 * path_color.a), width + 2.0, true)
  draw_polyline(points, path_color, width, true)
  for i in range(1, points.size()):
    draw_circle(points[i], max(2.4, 3.2 * zoom), path_color)
  if emphasize_destination:
    var destination = points[points.size() - 1]
    var marker_scale = 0.75 + 0.25 * progress
    draw_circle(destination, max(5.0, 7.0 * zoom) * marker_scale, Color("#FFFFFF", 0.26 * progress))
    draw_arc(destination, max(8.0, 9.6 * zoom) * marker_scale, 0.0, TAU, 32, Color("#FFFFFF", 0.95 * progress), max(1.7, 2.1 * zoom), true)

func _draw_confirm_flash() -> void:
  if confirm_flash_msec < 0:
    return
  var elapsed = Time.get_ticks_msec() - confirm_flash_msec
  if elapsed > 380:
    confirm_flash_msec = -1
    return
  var alpha = 1.0 - float(elapsed) / 380.0
  draw_rect(board_rect, Color("#35C7FF", 0.10 * alpha), true)
  draw_rect(board_rect, Color("#A9EBFF", 0.32 * alpha), false, 2.0)

func _draw_visual_diagnostics() -> void:
  var font = ThemeDB.fallback_font
  var text = "zoom %.2f -> %.2f | pan %d,%d | tiles %d" % [zoom, target_zoom, int(pan.x), int(pan.y), tile_centers.size()]
  draw_string(font, board_rect.position + Vector2(8, 16), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color("#AFC8D7", 0.78))

func _emit_tile_at(local_pos: Vector2) -> void:
  if pinch_active or touch_moved or not board_rect.has_point(local_pos):
    return
  var tile_id = _screen_to_tile(local_pos)
  if tile_id != "":
    tile_tapped.emit(tile_id)

func _screen_to_tile(local_pos: Vector2) -> String:
  _ensure_screen_geometry()
  var best = ""
  var best_distance = 999999.0
  for tile_id in tile_ids:
    var distance = local_pos.distance_to(_tile_screen_position(tile_id))
    if distance < best_distance:
      best = tile_id
      best_distance = distance
  if best_distance <= max(14.0, hex_radius * zoom * 1.05):
    return best
  return ""

func _tile_screen_position(tile_id: String) -> Vector2:
  if tile_centers.has(tile_id):
    return tile_centers[tile_id]
  var world: Vector2 = tile_world_positions.get(tile_id, Vector2.ZERO)
  if world == Vector2.ZERO and not tile_world_positions.has(tile_id):
    var coord = HexUtils.parse_tile_id(tile_id)
    world = HexUtils.axial_to_pixel(coord, 1.0)
  return world * (hex_radius * zoom) + pan

func _set_zoom(new_zoom: float, pivot: Vector2) -> void:
  var before = (pivot - target_pan) / max(0.001, target_zoom)
  target_zoom = clamp(new_zoom, 0.72, 3.0)
  target_pan = pivot - before * target_zoom
  _clamp_target_pan()
  queue_redraw()

func _request_fit() -> void:
  if fit_pending or not is_inside_tree():
    return
  fit_pending = true
  call_deferred("_fit_board")

func _fit_board() -> void:
  fit_pending = false
  if core == null:
    return
  if board_rect.size.x <= 1.0 or board_rect.size.y <= 1.0:
    board_rect = Rect2(Vector2.ZERO, size)
  if board_rect.size.x <= 1.0 or board_rect.size.y <= 1.0:
    return
  _cache_world_geometry()
  if tile_ids.is_empty():
    return
  var span = world_max - world_min
  var usable = board_rect.size * 0.91
  var radius_x = usable.x / max(1.0, span.x)
  var radius_y = usable.y / max(1.0, span.y)
  hex_radius = clamp(min(radius_x, radius_y), 7.0, 35.0)
  zoom = 1.0
  target_zoom = 1.0
  var scaled_center = (world_min + world_max) * 0.5 * hex_radius
  pan = board_rect.position + board_rect.size * 0.5 - scaled_center
  target_pan = pan
  pan_velocity = Vector2.ZERO
  geometry_dirty = true
  _clamp_target_pan()
  queue_redraw()

func _cache_world_geometry() -> void:
  if core == null:
    return
  tile_ids = []
  tile_world_positions = {}
  var state = core.snapshot()
  world_min = Vector2(INF, INF)
  world_max = Vector2(-INF, -INF)
  for tile_id in state["tiles"].keys():
    var id = String(tile_id)
    var coord = HexUtils.parse_tile_id(id)
    var world = HexUtils.axial_to_pixel(coord, 1.0)
    tile_ids.append(id)
    tile_world_positions[id] = world
    world_min.x = min(world_min.x, world.x)
    world_min.y = min(world_min.y, world.y)
    world_max.x = max(world_max.x, world.x)
    world_max.y = max(world_max.y, world.y)
  tile_ids.sort()
  geometry_dirty = true

func _ensure_screen_geometry() -> void:
  if core == null:
    return
  if tile_ids.is_empty():
    _cache_world_geometry()
  var signature = "%d|%d|%d|%d|%d|%d" % [int(round(pan.x * 10.0)), int(round(pan.y * 10.0)), int(round(zoom * 1000.0)), int(round(hex_radius * 100.0)), tile_ids.size(), int(round(board_rect.size.x * 10.0))]
  if not geometry_dirty and signature == screen_geometry_signature:
    return
  tile_centers = {}
  tile_polygons = {}
  tile_inner_polygons = {}
  for tile_id in tile_ids:
    var center = Vector2(tile_world_positions[tile_id]) * (hex_radius * zoom) + pan
    tile_centers[tile_id] = center
    tile_polygons[tile_id] = PackedVector2Array(HexUtils.polygon_points(center, hex_radius * zoom * 0.94))
    tile_inner_polygons[tile_id] = PackedVector2Array(HexUtils.polygon_points(center, hex_radius * zoom * 0.68))
  screen_geometry_signature = signature
  geometry_dirty = false

func _clamp_target_pan() -> void:
  if tile_ids.is_empty() or board_rect.size == Vector2.ZERO:
    return
  var scale = hex_radius * target_zoom
  var min_s = world_min * scale
  var max_s = world_max * scale
  var pad = max(12.0, hex_radius * target_zoom)
  var content = (max_s - min_s) + Vector2(pad * 2.0, pad * 2.0)
  if content.x <= board_rect.size.x:
    target_pan.x = board_rect.position.x + board_rect.size.x * 0.5 - (min_s.x + max_s.x) * 0.5
  else:
    var min_pan_x = board_rect.end.x - pad - max_s.x
    var max_pan_x = board_rect.position.x + pad - min_s.x
    target_pan.x = clamp(target_pan.x, min_pan_x, max_pan_x)
  if content.y <= board_rect.size.y:
    target_pan.y = board_rect.position.y + board_rect.size.y * 0.5 - (min_s.y + max_s.y) * 0.5
  else:
    var min_pan_y = board_rect.end.y - pad - max_s.y
    var max_pan_y = board_rect.position.y + pad - min_s.y
    target_pan.y = clamp(target_pan.y, min_pan_y, max_pan_y)

func _debug_pan_bounds() -> Rect2:
  if tile_ids.is_empty():
    return Rect2(Vector2.ZERO, Vector2.ZERO)
  var scale = hex_radius * target_zoom
  return Rect2(world_min * scale + target_pan, (world_max - world_min) * scale)

func _queued_path_count() -> int:
  if core == null or not show_paths:
    return 0
  var count = 0
  var state = core.snapshot()
  for stack_id in state["stacks"].keys():
    var stack: Dictionary = state["stacks"][stack_id]
    if String(stack["owner"]) != player_id:
      continue
    if selected_stack_id != "" and String(stack_id) != selected_stack_id:
      continue
    if not stack.get("waypoints", []).is_empty():
      count += 1
  return count

func _owner_color(owner: String) -> Color:
  if core == null:
    return UiTheme.TEXT
  var state = core.snapshot()
  if state["players"].has(owner):
    return Color(String(state["players"][owner]["color"]))
  if owner == NEUTRAL:
    return UiTheme.NEUTRAL
  if owner == "fog":
    return UiTheme.FOG
  return UiTheme.TEXT

func _tile_fill(owner: String, is_visible: bool) -> Color:
  if not is_visible:
    return Color("#0B1119", 0.86)
  if owner == NEUTRAL:
    return UiTheme.NEUTRAL.lerp(UiTheme.TILE_INNER, 0.38)
  var owner_color = _owner_color(owner)
  return UiTheme.TILE_DARK.lerp(owner_color, 0.34)

func _tile_intro_alpha(tile_id: String) -> float:
  if reduce_motion or intro_start_msec < 0:
    return 1.0
  var elapsed = float(Time.get_ticks_msec() - intro_start_msec)
  var progress = clamp(elapsed / UiTheme.INTRO_DURATION_MS, 0.0, 1.0)
  var center: Vector2 = tile_centers.get(tile_id, board_rect.get_center())
  var x_order = 0.0 if board_rect.size.x <= 1.0 else clamp((center.x - board_rect.position.x) / board_rect.size.x, 0.0, 1.0)
  var y_order = 0.0 if board_rect.size.y <= 1.0 else clamp((center.y - board_rect.position.y) / board_rect.size.y, 0.0, 1.0)
  var order = clamp(x_order * 0.48 + y_order * 0.32 + _hash_unit(tile_id) * 0.20, 0.0, 1.0)
  return _smooth_step(clamp((progress - order * 0.56) / 0.44, 0.0, 1.0))

func _intro_progress() -> float:
  if reduce_motion or intro_start_msec < 0:
    return 1.0
  return clamp(float(Time.get_ticks_msec() - intro_start_msec) / UiTheme.INTRO_DURATION_MS, 0.0, 1.0)

func _pending_path_progress() -> float:
  if reduce_motion or pending_path_start_msec < 0:
    return 1.0
  return _smooth_step(clamp(float(Time.get_ticks_msec() - pending_path_start_msec) / UiTheme.PATH_DRAW_MS, 0.0, 1.0))

func _selection_pulse() -> float:
  if reduce_motion or selected_start_msec < 0:
    return 0.0
  return (sin(float(Time.get_ticks_msec() - selected_start_msec) / 180.0) + 1.0) * 0.5

func _path_key(path: Array[String]) -> String:
  var parts: Array[String] = []
  for tile_id in path:
    parts.append(tile_id)
  return "|".join(parts)

func _smooth_step(value: float) -> float:
  var t = clamp(value, 0.0, 1.0)
  return t * t * (3.0 - 2.0 * t)

func _hash_unit(text: String) -> float:
  var h = 2166136261
  for i in range(text.length()):
    h = int((h ^ text.unicode_at(i)) * 16777619) & 0x7fffffff
  return float(abs(h) % 10000) / 10000.0