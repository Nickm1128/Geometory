extends Control

const GameCoreScript = preload("res://scripts/core/game_core.gd")
const ConfigLoaderScript = preload("res://scripts/core/config_loader.gd")
const BaselineBotScript = preload("res://scripts/core/baseline_bot.gd")
const MapViewScript = preload("res://scripts/presentation/map_view.gd")
const UiTheme = preload("res://scripts/presentation/ui_theme.gd")

const PHASE_ALLOCATION = "allocation"
const PHASE_MOVEMENT = "movement"
const MONEY_STEP_CENTS = 100
const RESERVE_CENTS = 100
const DEFAULT_UI_SCALE = 1.15

var configs: Dictionary = {}
var core
var bot
var map_view
var current_seed = 0
var selected_stack_id = ""
var selected_tile_id = ""
var pending_destination_tile_id = ""
var pending_path: Array[String] = []
var show_paths = true
var show_tips = true
var reduce_motion = false
var visual_diagnostics = false
var ui_scale = DEFAULT_UI_SCALE
var last_message = ""
var action_chips: Array[String] = []
var match_intro_pending = false
var menu_return_screen = "main"
var allocation_initialized_for_turn = -1
var allocation_cents: Dictionary = {"economy": 0, "military": 0, "research": 0}

var hud_phase_label: Label
var hud_money_label: Label
var tip_label: Label
var bottom_panel: PanelContainer
var bottom_box: VBoxContainer
var diagnostics_label: Label

func _ready() -> void:
  set_process(true)
  configs = ConfigLoaderScript.load_all()
  current_seed = int(Time.get_unix_time_from_system()) % 1000000
  show_main_menu()

func _process(_delta: float) -> void:
  _update_visual_diagnostics()

func _notification(what: int) -> void:
  if what == NOTIFICATION_RESIZED:
    _layout_match_screen()

func _clear() -> void:
  for child in get_children():
    remove_child(child)
    child.queue_free()
  map_view = null
  hud_phase_label = null
  hud_money_label = null
  tip_label = null
  bottom_panel = null
  bottom_box = null
  diagnostics_label = null

func show_main_menu() -> void:
  _clear()
  _add_background()
  var panel = _menu_panel()
  add_child(panel)
  panel.add_child(_label("GEOMETORY", 44, UiTheme.TEXT, HORIZONTAL_ALIGNMENT_CENTER))
  panel.add_child(_label("TACTICAL HEX COMMAND", 12, UiTheme.ACCENT, HORIZONTAL_ALIGNMENT_CENTER))
  panel.add_child(_label("Hold land. Breach walls. Take the capital.", 16, UiTheme.TEXT_MUTED, HORIZONTAL_ALIGNMENT_CENTER))
  panel.add_child(_spacer(18))
  panel.add_child(_button("Quick Play", Callable(self, "show_quick_play"), true))
  panel.add_child(_button("How To Play", Callable(self, "show_how_to_play_from_main")))
  panel.add_child(_button("Settings", Callable(self, "show_settings_from_main")))
  panel.add_child(_button("Dev Tools", Callable(self, "show_dev_tools")))

func show_quick_play() -> void:
  _clear()
  _add_background()
  var panel = _menu_panel()
  add_child(panel)
  panel.add_child(_label("Quick Play", 36, UiTheme.TEXT, HORIZONTAL_ALIGNMENT_CENTER))
  panel.add_child(_label("Alpha Medium | You vs Baseline Bot", 16, UiTheme.TEXT_MUTED, HORIZONTAL_ALIGNMENT_CENTER))
  panel.add_child(_label("Seed: %d" % current_seed, 16, UiTheme.WARN, HORIZONTAL_ALIGNMENT_CENTER))
  panel.add_child(_spacer(18))
  panel.add_child(_button("Start Match", Callable(self, "start_match"), true))
  panel.add_child(_button("Reroll Seed", Callable(self, "_reroll_seed")))
  panel.add_child(_button("Back", Callable(self, "show_main_menu")))

func show_how_to_play_from_main() -> void:
  menu_return_screen = "main"
  show_how_to_play()

func show_how_to_play_from_pause() -> void:
  menu_return_screen = "pause"
  show_how_to_play()

func show_how_to_play() -> void:
  _clear()
  _add_background()
  var panel = _menu_panel()
  add_child(panel)
  panel.add_child(_label("How To Play", 34, UiTheme.TEXT, HORIZONTAL_ALIGNMENT_CENTER))
  panel.add_child(_body("At the start of your turn, spend your bank across Economy, Military, and Research. Military spawns soldiers next turn at your capital. Tap a stack, then tap a destination to preview a path. Confirm Move queues the order. Capture neutral tiles, break enemy walls, and take the enemy capital."))
  panel.add_child(_button("Back", Callable(self, "_return_from_menu_page")))

func show_settings_from_main() -> void:
  menu_return_screen = "main"
  show_settings()

func show_settings_from_pause() -> void:
  menu_return_screen = "pause"
  show_settings()

func show_settings() -> void:
  _clear()
  _add_background()
  var panel = _menu_panel()
  add_child(panel)
  panel.add_child(_label("Settings", 34, UiTheme.TEXT, HORIZONTAL_ALIGNMENT_CENTER))
  panel.add_child(_button("UI Scale: %.2fx" % ui_scale, Callable(self, "_toggle_ui_scale")))
  panel.add_child(_button("Tips: %s" % ("On" if show_tips else "Off"), Callable(self, "_toggle_tips")))
  panel.add_child(_button("Reset Tips", Callable(self, "_reset_tips")))
  panel.add_child(_button("Reduce Motion: %s" % ("On" if reduce_motion else "Off"), Callable(self, "_toggle_reduce_motion")))
  panel.add_child(_button("Back", Callable(self, "_return_from_menu_page")))

func show_dev_tools() -> void:
  _clear()
  _add_background()
  var panel = _menu_panel()
  add_child(panel)
  panel.add_child(_label("Dev Tools", 34, UiTheme.TEXT, HORIZONTAL_ALIGNMENT_CENTER))
  panel.add_child(_body("MVP debug surface. Headless tests run with: godot --headless --path godot --script res://tests/run_core_tests.gd"))
  panel.add_child(_button("Visual Diagnostics: %s" % ("On" if visual_diagnostics else "Off"), Callable(self, "_toggle_visual_diagnostics")))
  panel.add_child(_button("Run Seed 12345", Callable(self, "_run_seed_12345")))
  panel.add_child(_button("Back", Callable(self, "show_main_menu")))

func start_match() -> void:
  core = GameCoreScript.new()
  core.setup(configs["rules"], configs["map"], current_seed)
  bot = BaselineBotScript.new()
  bot.setup(configs["bot"])
  _clear_movement_selection()
  show_paths = true
  allocation_initialized_for_turn = -1
  allocation_cents = {"economy": 0, "military": 0, "research": 0}
  action_chips = ["Alpha Medium online", "Seed %d" % current_seed]
  match_intro_pending = true
  last_message = "Allocate your first turn."
  show_match()

func show_match() -> void:
  _clear()
  _add_background()
  map_view = MapViewScript.new()
  map_view.name = "MapView"
  map_view.set_anchors_preset(Control.PRESET_FULL_RECT)
  map_view.tile_tapped.connect(_on_tile_tapped)
  add_child(map_view)
  map_view.set_visual_options(reduce_motion, visual_diagnostics)
  map_view.set_core(core)
  map_view.play_intro(match_intro_pending)
  match_intro_pending = false
  _build_hud()
  _build_bottom_panel()
  _run_bot_until_human()
  _refresh_match_ui()
  _show_turn_banner("YOUR TURN" if core.get_active_player() == "P1" else "BOT TURN")
  call_deferred("_layout_match_screen")

func _build_hud() -> void:
  var top = PanelContainer.new()
  top.name = "TopHud"
  top.set_anchors_preset(Control.PRESET_TOP_WIDE)
  top.add_theme_stylebox_override("panel", _panel_style(UiTheme.SURFACE, UiTheme.BORDER_SOFT))
  add_child(top)

  var row = HBoxContainer.new()
  row.name = "HudRow"
  row.add_theme_constant_override("separation", _dp(10))
  top.add_child(row)

  var text_box = VBoxContainer.new()
  text_box.name = "HudTextBox"
  text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  text_box.alignment = BoxContainer.ALIGNMENT_CENTER
  row.add_child(text_box)

  hud_phase_label = _label("", 16, UiTheme.TEXT, HORIZONTAL_ALIGNMENT_LEFT)
  hud_phase_label.name = "HudPhaseLabel"
  text_box.add_child(hud_phase_label)

  hud_money_label = _label("", 14, UiTheme.TEXT_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
  hud_money_label.name = "HudMoneyLabel"
  text_box.add_child(hud_money_label)

  var pause = _button("Pause", Callable(self, "show_pause"), false, 72)
  pause.name = "PauseButton"
  row.add_child(pause)

  tip_label = _label("", 12, UiTheme.WARN, HORIZONTAL_ALIGNMENT_CENTER)
  tip_label.name = "TipLabel"
  tip_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
  add_child(tip_label)

func _build_bottom_panel() -> void:
  bottom_panel = PanelContainer.new()
  bottom_panel.name = "BottomPanel"
  bottom_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
  bottom_panel.add_theme_stylebox_override("panel", _panel_style(UiTheme.SURFACE, UiTheme.BORDER))
  add_child(bottom_panel)

  var scroll = ScrollContainer.new()
  scroll.name = "BottomScroll"
  scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
  bottom_panel.add_child(scroll)

  bottom_box = VBoxContainer.new()
  bottom_box.name = "BottomBox"
  bottom_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  bottom_box.add_theme_constant_override("separation", _dp(7))
  scroll.add_child(bottom_box)

func _refresh_match_ui() -> void:
  if core == null:
    return
  if core.snapshot()["game_over"]:
    show_game_over()
    return
  _update_hud()
  if tip_label:
    tip_label.text = _phase_tip() if show_tips else ""
  if bottom_box:
    for child in bottom_box.get_children():
      bottom_box.remove_child(child)
      child.queue_free()
    if core.get_phase() == PHASE_ALLOCATION:
      _ensure_allocation_defaults()
      _build_allocation_controls(bottom_box)
    else:
      _build_movement_controls(bottom_box)
  if map_view:
    map_view.set_visual_options(reduce_motion, visual_diagnostics)
    map_view.set_presentation_state(selected_stack_id, pending_path, show_paths)
    map_view.queue_redraw()
  _sync_visual_diagnostics_control()
  _layout_match_screen()

func _update_hud() -> void:
  if hud_phase_label == null or hud_money_label == null:
    return
  var active = core.get_active_player()
  var income = core.calculate_income(active)
  var who = "You" if active == "P1" else "Bot"
  hud_phase_label.text = "T%d | %s | %s" % [core.snapshot()["turn"], who, _format_phase(core.get_phase())]
  hud_money_label.text = "Bank %s | Income +%s" % [core.money_text(core.get_bank(active)), core.money_text(income["final"])]

func _build_allocation_controls(box: VBoxContainer) -> void:
  var title = _label("Allocate This Turn", 19, UiTheme.TEXT, HORIZONTAL_ALIGNMENT_LEFT)
  title.name = "AllocationTitle"
  box.add_child(title)
  box.add_child(_body("Spend in $1 steps. Presets stage a plan; Confirm sends the command."))
  _build_action_chips(box)
  box.add_child(_build_spend_bar())

  var unspent = _label("Unspent: %s" % core.money_text(_allocation_unspent()), 13, UiTheme.WARN, HORIZONTAL_ALIGNMENT_LEFT)
  unspent.name = "AllocationUnspentLabel"
  box.add_child(unspent)

  var preset_row = HBoxContainer.new()
  preset_row.name = "AllocationPresetRow"
  preset_row.add_theme_constant_override("separation", _dp(7))
  box.add_child(preset_row)
  var auto = _button("Auto Balance", Callable(self, "_confirm_balanced_allocation"), false)
  auto.name = "AutoBalanceButton"
  preset_row.add_child(auto)
  var focus = _button("Focus Military", Callable(self, "_confirm_focus_military"), false)
  focus.name = "FocusMilitaryButton"
  preset_row.add_child(focus)

  box.add_child(_build_allocation_row("economy", "Economy", _economy_preview()))
  box.add_child(_build_allocation_row("military", "Military", _military_preview()))
  box.add_child(_build_allocation_row("research", "Research", _research_preview()))

  var confirm = _button("Confirm Allocation", Callable(self, "_confirm_staged_allocation"), true)
  confirm.name = "ConfirmAllocationButton"
  box.add_child(confirm)
  if last_message != "":
    var message = _label(last_message, 12, UiTheme.TEXT_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
    message.name = "AllocationMessageLabel"
    box.add_child(message)

func _build_allocation_row(category: String, title: String, preview: String) -> Control:
  var row = HBoxContainer.new()
  row.name = "Allocation%sRow" % title
  row.add_theme_constant_override("separation", _dp(7))

  var text_box = VBoxContainer.new()
  text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  row.add_child(text_box)

  var amount = _label("%s %s" % [title, core.money_text(int(allocation_cents[category]))], 14, UiTheme.TEXT, HORIZONTAL_ALIGNMENT_LEFT)
  amount.name = "Allocation%sAmount" % title
  text_box.add_child(amount)

  var details = _label(preview, 11, UiTheme.TEXT_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
  details.name = "Allocation%sPreview" % title
  text_box.add_child(details)

  var minus = _button("- $1", Callable(self, "_change_allocation").bind(category, -MONEY_STEP_CENTS), false, 48)
  minus.name = "Allocation%sMinus" % title
  minus.disabled = int(allocation_cents[category]) <= 0
  row.add_child(minus)

  var plus = _button("+ $1", Callable(self, "_change_allocation").bind(category, MONEY_STEP_CENTS), false, 48)
  plus.name = "Allocation%sPlus" % title
  plus.disabled = _allocation_unspent() < MONEY_STEP_CENTS
  row.add_child(plus)
  return row

func _build_movement_controls(box: VBoxContainer) -> void:
  var title = _label("Movement", 19, UiTheme.TEXT, HORIZONTAL_ALIGNMENT_LEFT)
  title.name = "MovementTitle"
  box.add_child(title)

  var guide = _body(_movement_guide_text())
  guide.name = "MovementGuideLabel"
  box.add_child(guide)
  _build_action_chips(box)

  var top_row = HBoxContainer.new()
  top_row.name = "MovementTopActionRow"
  top_row.add_theme_constant_override("separation", _dp(7))
  box.add_child(top_row)

  var paths_button = _button("Paths: %s" % ("On" if show_paths else "Off"), Callable(self, "_toggle_paths"), show_paths)
  paths_button.name = "PathToggleButton"
  top_row.add_child(paths_button)

  if selected_stack_id != "":
    var cancel = _button("Cancel Selection", Callable(self, "_cancel_selection"), false)
    cancel.name = "CancelSelectionButton"
    top_row.add_child(cancel)

  if selected_stack_id != "" and pending_path.is_empty():
    var waiting = _label("Pick a destination on the map.", 12, UiTheme.WARN, HORIZONTAL_ALIGNMENT_LEFT)
    waiting.name = "DestinationPromptLabel"
    box.add_child(waiting)

  var path_row = HBoxContainer.new()
  path_row.name = "MovementPathActionRow"
  path_row.add_theme_constant_override("separation", _dp(7))
  box.add_child(path_row)

  if not pending_path.is_empty():
    var confirm = _button("Confirm Move", Callable(self, "_confirm_selected_move"), true)
    confirm.name = "ConfirmMoveButton"
    path_row.add_child(confirm)

  if selected_stack_id != "":
    var clear_button = _button("Clear Path", Callable(self, "_clear_selected_path"), false)
    clear_button.name = "ClearPathButton"
    path_row.add_child(clear_button)

  var end_button = _button("End Turn", Callable(self, "_end_human_turn"), true)
  end_button.name = "EndTurnButton"
  box.add_child(end_button)

  if last_message != "":
    var message = _label(last_message, 12, UiTheme.TEXT_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
    message.name = "MovementMessageLabel"
    box.add_child(message)

func _movement_guide_text() -> String:
  if selected_stack_id == "":
    return "Tap a soldier tile to move them."
  if pending_path.is_empty():
    return "Select a destination tile."
  return "Confirm this move."

func _build_spend_bar() -> Control:
  var wrap = VBoxContainer.new()
  wrap.name = "AllocationSpendBarWrap"
  wrap.add_theme_constant_override("separation", _dp(4))
  var label = _label("Spend mix", 11, UiTheme.TEXT_DIM, HORIZONTAL_ALIGNMENT_LEFT)
  wrap.add_child(label)
  var row = HBoxContainer.new()
  row.name = "AllocationSpendBar"
  row.custom_minimum_size = Vector2(0, _dp(12))
  row.add_theme_constant_override("separation", _dp(3))
  wrap.add_child(row)
  var total = max(1, _allocation_spent())
  row.add_child(_spend_bar_segment("Economy", int(allocation_cents["economy"]), total, UiTheme.SUCCESS))
  row.add_child(_spend_bar_segment("Military", int(allocation_cents["military"]), total, UiTheme.ACCENT))
  row.add_child(_spend_bar_segment("Research", int(allocation_cents["research"]), total, UiTheme.WARN))
  return wrap

func _spend_bar_segment(segment_name: String, cents: int, total: int, color: Color) -> Control:
  var segment = ColorRect.new()
  segment.name = "Spend%sSegment" % segment_name
  segment.color = color if cents > 0 else Color("#122433", 0.72)
  segment.custom_minimum_size = Vector2(_dp(10), _dp(10))
  segment.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  segment.size_flags_stretch_ratio = max(0.08, float(cents) / float(total))
  return segment

func _build_action_chips(box: VBoxContainer) -> void:
  if action_chips.is_empty():
    return
  var row = HBoxContainer.new()
  row.name = "ActionChipsRow"
  row.add_theme_constant_override("separation", _dp(6))
  box.add_child(row)
  for i in range(min(3, action_chips.size())):
    row.add_child(_chip(action_chips[i], UiTheme.ACCENT_SOFT, UiTheme.BORDER_SOFT))

func _chip(text: String, fill: Color, border: Color) -> Control:
  var chip = PanelContainer.new()
  chip.add_theme_stylebox_override("panel", UiTheme.chip_style(fill, border, ui_scale))
  var label = _label(text, 10, UiTheme.TEXT_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
  chip.add_child(label)
  return chip

func _ensure_allocation_defaults() -> void:
  var turn = int(core.snapshot()["turn"])
  if allocation_initialized_for_turn == turn:
    return
  _set_allocation_from_weights(0.25, 0.50, 0.25)
  allocation_initialized_for_turn = turn

func _set_allocation_from_weights(economy_weight: float, military_weight: float, research_weight: float) -> void:
  var spendable = _allocation_spendable()
  var total = max(0.001, economy_weight + military_weight + research_weight)
  var economy = _snap_100(int(float(spendable) * economy_weight / total))
  var military = _snap_100(int(float(spendable) * military_weight / total))
  var research = _snap_100(max(0, spendable - economy - military))
  allocation_cents = {"economy": economy, "military": military, "research": research}

func _change_allocation(category: String, delta: int) -> void:
  if not allocation_cents.has(category):
    return
  var current = int(allocation_cents[category])
  var applied = delta
  if delta > 0:
    applied = min(delta, _allocation_unspent())
  else:
    applied = max(delta, -current)
  allocation_cents[category] = current + applied
  _refresh_match_ui()

func _confirm_staged_allocation() -> void:
  var result = core.apply_command({
    "type": "allocate_resources",
    "player_id": "P1",
    "turn": core.snapshot()["turn"],
    "phase": PHASE_ALLOCATION,
    "economy_cents": int(allocation_cents["economy"]),
    "military_cents": int(allocation_cents["military"]),
    "research_cents": int(allocation_cents["research"]),
    "client_sequence": Time.get_ticks_msec()
  })
  last_message = result["message"]
  if bool(result["ok"]):
    _haptic_tick(true)
    action_chips = [
      "E %s" % core.money_text(int(allocation_cents["economy"])),
      "M %s" % core.money_text(int(allocation_cents["military"])),
      "R %s" % core.money_text(int(allocation_cents["research"]))
    ]
    _show_turn_banner("MOVEMENT PHASE")
    allocation_initialized_for_turn = -1
    _clear_movement_selection()
  _refresh_match_ui()

func _confirm_balanced_allocation() -> void:
  _set_allocation_from_weights(0.25, 0.50, 0.25)
  _refresh_match_ui()

func _confirm_focus_military() -> void:
  _set_allocation_from_weights(0.10, 0.75, 0.15)
  _refresh_match_ui()

func _allocation_spendable() -> int:
  return _snap_100(max(0, core.get_bank("P1") - RESERVE_CENTS))

func _allocation_spent() -> int:
  return int(allocation_cents["economy"]) + int(allocation_cents["military"]) + int(allocation_cents["research"])

func _allocation_unspent() -> int:
  return max(0, core.get_bank("P1") - _allocation_spent())

func _economy_preview() -> String:
  var rules = core.rules["economy"]
  var units = int(floor(float(allocation_cents["economy"]) / float(rules["economy_bonus_unit_cost_cents"])))
  var bps = min(units * int(rules["economy_bonus_bps_per_unit"]), int(rules["economy_bonus_cap_bps"]))
  return "+%.1f%% income next turn" % (float(bps) / 100.0)

func _military_preview() -> String:
  var cost = int(core.rules["military"]["soldier_cost_cents"])
  var soldiers = int(floor(float(allocation_cents["military"]) / float(cost)))
  return "%d soldier%s spawn next own turn" % [soldiers, "" if soldiers == 1 else "s"]

func _research_preview() -> String:
  var cost = int(core.rules["research"]["research_point_cost_cents"])
  var points = int(floor(float(allocation_cents["research"]) / float(cost)))
  var schedule = core.snapshot()["research_schedule"][min(int(core.snapshot()["turn"]) - 1, core.snapshot()["research_schedule"].size() - 1)]
  var hp = points * int(schedule["health_bps_per_point"])
  var damage = points * int(schedule["damage_bps_per_point"])
  return "%d pt%s | +%.1f%% HP / +%.1f%% DMG" % [points, "" if points == 1 else "s", float(hp) / 100.0, float(damage) / 100.0]

func _reroll_seed() -> void:
  current_seed = int(Time.get_ticks_msec()) % 1000000
  show_quick_play()

func _toggle_ui_scale() -> void:
  if ui_scale < 1.07:
    ui_scale = 1.15
  elif ui_scale < 1.22:
    ui_scale = 1.30
  else:
    ui_scale = 1.00
  show_settings()

func _toggle_tips() -> void:
  show_tips = not show_tips
  show_settings()

func _reset_tips() -> void:
  show_tips = true
  show_settings()

func _toggle_reduce_motion() -> void:
  reduce_motion = not reduce_motion
  if map_view:
    map_view.set_visual_options(reduce_motion, visual_diagnostics)
  show_settings()

func _toggle_visual_diagnostics() -> void:
  visual_diagnostics = not visual_diagnostics
  if map_view:
    map_view.set_visual_options(reduce_motion, visual_diagnostics)
  show_dev_tools()

func _run_seed_12345() -> void:
  current_seed = 12345
  start_match()

func _return_from_menu_page() -> void:
  if menu_return_screen == "pause" and core != null:
    show_pause()
  else:
    show_main_menu()

func _on_tile_tapped(tile_id: String) -> void:
  if core == null or core.get_phase() != PHASE_MOVEMENT or core.get_active_player() != "P1":
    return
  selected_tile_id = tile_id
  var stack_id = core.get_stack_at_tile_for_player(tile_id, "P1")
  if stack_id != "":
    selected_stack_id = stack_id
    pending_destination_tile_id = ""
    pending_path = []
    last_message = "Selected stack."
    _haptic_tick(false)
  elif selected_stack_id != "":
    var stack_tile = String(core.snapshot()["stacks"][selected_stack_id]["tile_id"])
    pending_path = core.find_path(stack_tile, tile_id)
    pending_destination_tile_id = tile_id if not pending_path.is_empty() else ""
    if pending_path.is_empty():
      last_message = "No path to that tile."
    else:
      last_message = "Previewing %d step%s." % [pending_path.size(), "" if pending_path.size() == 1 else "s"]
      _haptic_tick(false)
  else:
    last_message = "Tap a soldier tile to move them."
  _refresh_match_ui()

func _confirm_selected_move() -> void:
  if selected_stack_id == "" or pending_path.is_empty():
    last_message = "Select a stack and destination first."
    _refresh_match_ui()
    return
  var destination = pending_destination_tile_id
  if destination == "":
    destination = String(pending_path[pending_path.size() - 1])
  var result = core.apply_command({
    "type": "queue_stack_path",
    "player_id": "P1",
    "turn": core.snapshot()["turn"],
    "phase": PHASE_MOVEMENT,
    "stack_id": selected_stack_id,
    "waypoints": [destination],
    "mode": "replace",
    "client_sequence": Time.get_ticks_msec()
  })
  last_message = "Move confirmed." if bool(result["ok"]) else result["message"]
  if bool(result["ok"]):
    _haptic_tick(true)
    if map_view:
      map_view.play_confirm_flash()
    action_chips = ["Move queued", "%d step%s" % [pending_path.size(), "" if pending_path.size() == 1 else "s"]]
    pending_destination_tile_id = ""
    pending_path = []
  _refresh_match_ui()

func _clear_selected_path() -> void:
  if selected_stack_id == "":
    last_message = "Select a stack first."
    _refresh_match_ui()
    return
  var result = core.apply_command({
    "type": "queue_stack_path",
    "player_id": "P1",
    "turn": core.snapshot()["turn"],
    "phase": PHASE_MOVEMENT,
    "stack_id": selected_stack_id,
    "waypoints": [],
    "mode": "replace",
    "client_sequence": Time.get_ticks_msec()
  })
  last_message = "Queued path cleared." if bool(result["ok"]) else result["message"]
  pending_destination_tile_id = ""
  pending_path = []
  _refresh_match_ui()

func _cancel_selection() -> void:
  _clear_movement_selection()
  last_message = "Selection canceled."
  _refresh_match_ui()

func _toggle_paths() -> void:
  show_paths = not show_paths
  _refresh_match_ui()

func _clear_movement_selection() -> void:
  selected_stack_id = ""
  selected_tile_id = ""
  pending_destination_tile_id = ""
  pending_path = []

func _wait_turn() -> void:
  last_message = "No new orders queued."
  _refresh_match_ui()

func _end_human_turn() -> void:
  if not pending_path.is_empty():
    _show_end_turn_confirm()
    return
  _perform_end_human_turn()

func _perform_end_human_turn() -> void:
  var result = core.apply_command({
    "type": "end_phase",
    "player_id": "P1",
    "turn": core.snapshot()["turn"],
    "phase": PHASE_MOVEMENT,
    "client_sequence": Time.get_ticks_msec()
  })
  _clear_movement_selection()
  _haptic_tick(true)
  last_message = result["message"]
  _run_bot_until_human()
  if core != null and not core.snapshot()["game_over"]:
    _show_turn_banner("YOUR TURN")
  _refresh_match_ui()

func _show_end_turn_confirm() -> void:
  if get_node_or_null("EndTurnConfirmOverlay") != null:
    return
  var overlay = ColorRect.new()
  overlay.name = "EndTurnConfirmOverlay"
  overlay.color = Color("#02070C", 0.72)
  overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
  add_child(overlay)

  var panel = PanelContainer.new()
  panel.name = "EndTurnConfirmPanel"
  panel.set_anchors_preset(Control.PRESET_CENTER)
  panel.custom_minimum_size = Vector2(_dp(310), _dp(210))
  panel.offset_left = -_dp(155)
  panel.offset_right = _dp(155)
  panel.offset_top = -_dp(105)
  panel.offset_bottom = _dp(105)
  panel.add_theme_stylebox_override("panel", _panel_style(Color("#0B1722", 0.98), Color("#F6D36B", 0.85)))
  overlay.add_child(panel)

  var box = VBoxContainer.new()
  box.alignment = BoxContainer.ALIGNMENT_CENTER
  box.add_theme_constant_override("separation", _dp(12))
  panel.add_child(box)
  var title = _label("Move not confirmed", 20, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
  title.name = "EndTurnConfirmTitle"
  box.add_child(title)
  var body = _label("End turn anyway?", 15, Color("#AFC8D7"), HORIZONTAL_ALIGNMENT_CENTER)
  body.name = "EndTurnConfirmBody"
  box.add_child(body)
  var back = _button("Go Back", Callable(self, "_dismiss_end_turn_confirm"), false)
  back.name = "GoBackButton"
  box.add_child(back)
  var end = _button("End Without Move", Callable(self, "_end_turn_without_pending_move"), true)
  end.name = "EndWithoutMoveButton"
  box.add_child(end)

func _dismiss_end_turn_confirm() -> void:
  var overlay = get_node_or_null("EndTurnConfirmOverlay")
  if overlay != null:
    overlay.queue_free()

func _end_turn_without_pending_move() -> void:
  _dismiss_end_turn_confirm()
  pending_destination_tile_id = ""
  pending_path = []
  _perform_end_human_turn()

func _run_bot_until_human() -> void:
  var safety = 0
  var bot_started = core != null and core.is_bot_turn()
  var before_events = core.snapshot()["replay_events"].size() if bot_started else 0
  var bot_command_count = 0
  while core != null and core.is_bot_turn() and not core.snapshot()["game_over"] and safety < 8:
    var commands = bot.build_turn_commands(core.observable_state("P2"))
    bot_command_count += commands.size()
    for command in commands:
      var result = core.apply_command(command)
      if not result["ok"]:
        last_message = "Bot skipped: %s" % result["message"]
        break
    safety += 1
  if bot_started and core != null:
    action_chips = _bot_action_chips(before_events, bot_command_count)

func _bot_action_chips(before_events: int, command_count: int) -> Array[String]:
  var chips: Array[String] = ["Bot resolved"]
  var moved = 0
  var captured = 0
  var wall_hits = 0
  var events: Array = core.snapshot()["replay_events"]
  for i in range(before_events, events.size()):
    var event: Dictionary = events[i]
    match String(event.get("type", "")):
      "stack_moved":
        moved += 1
      "tile_control_changed":
        captured += 1
      "wall_damaged", "wall_destroyed":
        wall_hits += 1
  if moved > 0:
    chips.append("%d move%s" % [moved, "" if moved == 1 else "s"])
  elif command_count > 0:
    chips.append("%d command%s" % [command_count, "" if command_count == 1 else "s"])
  if captured > 0:
    chips.append("%d capture%s" % [captured, "" if captured == 1 else "s"])
  if wall_hits > 0 and chips.size() < 3:
    chips.append("%d wall hit%s" % [wall_hits, "" if wall_hits == 1 else "s"])
  var result: Array[String] = []
  for i in range(min(3, chips.size())):
    result.append(chips[i])
  return result

func show_pause() -> void:
  if core == null:
    show_main_menu()
    return
  _clear()
  _add_background()
  var panel = _menu_panel()
  add_child(panel)
  panel.add_child(_label("Paused", 34, UiTheme.TEXT, HORIZONTAL_ALIGNMENT_CENTER))
  panel.add_child(_button("Resume", Callable(self, "show_match"), true))
  panel.add_child(_button("Restart Match", Callable(self, "start_match")))
  panel.add_child(_button("How To Play", Callable(self, "show_how_to_play_from_pause")))
  panel.add_child(_button("Settings", Callable(self, "show_settings_from_pause")))
  panel.add_child(_button("Exit To Main Menu", Callable(self, "show_main_menu")))

func show_game_over() -> void:
  _clear()
  _add_background()
  var panel = _menu_panel()
  add_child(panel)
  var winner = String(core.snapshot()["winner"])
  panel.add_child(_label("Victory" if winner == "P1" else "Defeat", 42, UiTheme.TEXT, HORIZONTAL_ALIGNMENT_CENTER))
  panel.add_child(_label("Winner: %s | Turns: %d" % [winner, core.snapshot()["turn"]], 18, UiTheme.WARN, HORIZONTAL_ALIGNMENT_CENTER))
  for line in core.get_top_replay_lines(5):
    panel.add_child(_label(line, 14, UiTheme.TEXT_MUTED, HORIZONTAL_ALIGNMENT_CENTER))
  panel.add_child(_button("Play Again", Callable(self, "start_match"), true))
  panel.add_child(_button("Main Menu", Callable(self, "show_main_menu")))

func _phase_tip() -> String:
  if core == null:
    return ""
  if core.get_phase() == PHASE_ALLOCATION:
    return "Tip: tune Economy, Military, and Research, then Confirm Allocation."
  return "Tip: select a stack, choose a destination, then Confirm Move."

func _layout_match_screen() -> void:
  if bottom_panel == null or map_view == null:
    return
  var view_size = get_viewport_rect().size
  if view_size.x <= 1.0 or view_size.y <= 1.0:
    view_size = size
  if view_size.x <= 1.0 or view_size.y <= 1.0:
    return

  var margin = _dp(10)
  var hud_height = _dp(74)
  var tip_height = _dp(24)
  var tip_gap = _dp(4)
  var bottom_height = _bottom_panel_height(view_size)

  var top: Control = get_node_or_null("TopHud")
  if top:
    top.offset_left = margin
    top.offset_right = -margin
    top.offset_top = margin
    top.offset_bottom = margin + hud_height

  if tip_label:
    tip_label.offset_left = margin
    tip_label.offset_right = -margin
    tip_label.offset_top = margin + hud_height + tip_gap
    tip_label.offset_bottom = margin + hud_height + tip_gap + tip_height

  bottom_panel.offset_left = margin
  bottom_panel.offset_right = -margin
  bottom_panel.offset_top = -(bottom_height + margin)
  bottom_panel.offset_bottom = -margin

  var board_top = margin + hud_height + tip_gap + tip_height + _dp(8)
  var board_bottom = view_size.y - bottom_height - margin - _dp(8)
  var board_height = max(_dp(120), board_bottom - board_top)
  var board_rect = Rect2(Vector2(margin, board_top), Vector2(max(_dp(120), view_size.x - margin * 2), board_height))
  if diagnostics_label:
    diagnostics_label.offset_left = margin
    diagnostics_label.offset_right = -margin
    diagnostics_label.offset_top = board_top
    diagnostics_label.offset_bottom = board_top + _dp(22)
  map_view.set_board_rect(board_rect)

func _bottom_panel_height(view_size: Vector2) -> int:
  if core != null and core.get_phase() == PHASE_ALLOCATION:
    return int(min(view_size.y * 0.56, float(_dp(430))))
  return int(min(view_size.y * 0.36, float(_dp(280))))

func _add_background() -> void:
  var bg = ColorRect.new()
  bg.name = "Background"
  bg.color = UiTheme.BACKGROUND
  bg.set_anchors_preset(Control.PRESET_FULL_RECT)
  add_child(bg)

func _menu_panel() -> VBoxContainer:
  var panel = VBoxContainer.new()
  panel.set_anchors_preset(Control.PRESET_FULL_RECT)
  panel.offset_left = _dp(28)
  panel.offset_right = -_dp(28)
  panel.offset_top = _dp(86)
  panel.offset_bottom = -_dp(64)
  panel.alignment = BoxContainer.ALIGNMENT_CENTER
  panel.add_theme_constant_override("separation", _dp(12))
  return panel

func _button(text: String, callback: Callable, primary: bool = false, min_width: int = 0) -> Button:
  var button = Button.new()
  button.text = text
  button.custom_minimum_size = Vector2(_dp(min_width), _dp(56))
  button.add_theme_font_size_override("font_size", _font_size(16))
  button.add_theme_stylebox_override("normal", _button_style(primary, false))
  button.add_theme_stylebox_override("hover", _button_style(primary, true))
  button.add_theme_stylebox_override("pressed", _button_style(primary, true))
  button.add_theme_stylebox_override("disabled", _button_style(false, false, true))
  button.pressed.connect(callback)
  return button

func _label(text: String, label_size: int, color: Color, align: HorizontalAlignment) -> Label:
  var label = Label.new()
  label.text = text
  label.horizontal_alignment = align
  label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  label.add_theme_font_size_override("font_size", _font_size(label_size))
  label.add_theme_color_override("font_color", color)
  return label

func _body(text: String) -> Label:
  return _label(text, 13, UiTheme.TEXT_MUTED, HORIZONTAL_ALIGNMENT_LEFT)

func _spacer(height: int) -> Control:
  var c = Control.new()
  c.custom_minimum_size = Vector2(1, _dp(height))
  return c

func _panel_style(fill: Color, border: Color) -> StyleBoxFlat:
  return UiTheme.panel_style(fill, border, ui_scale)

func _button_style(primary: bool, active: bool, disabled: bool = false) -> StyleBoxFlat:
  return UiTheme.button_style(primary, active, disabled, ui_scale)

func _show_turn_banner(text: String) -> void:
  if reduce_motion:
    return
  var existing = get_node_or_null("TurnBanner")
  if existing:
    existing.queue_free()
  var banner = PanelContainer.new()
  banner.name = "TurnBanner"
  banner.set_anchors_preset(Control.PRESET_TOP_WIDE)
  banner.offset_left = _dp(88)
  banner.offset_right = -_dp(88)
  banner.offset_top = _dp(116)
  banner.offset_bottom = _dp(154)
  banner.modulate.a = 0.0
  banner.add_theme_stylebox_override("panel", UiTheme.chip_style(Color("#102536", 0.92), UiTheme.ACCENT_SOFT, ui_scale))
  add_child(banner)
  var label = _label(text, 15, UiTheme.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
  label.name = "TurnBannerLabel"
  banner.add_child(label)
  var tween = create_tween()
  tween.tween_property(banner, "modulate:a", 1.0, 0.14)
  tween.tween_interval(0.62)
  tween.tween_property(banner, "modulate:a", 0.0, 0.22)
  tween.tween_callback(banner.queue_free)

func _sync_visual_diagnostics_control() -> void:
  if visual_diagnostics and diagnostics_label == null:
    diagnostics_label = _label("", 10, UiTheme.TEXT_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
    diagnostics_label.name = "VisualDiagnosticsLabel"
    diagnostics_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
    add_child(diagnostics_label)
  elif not visual_diagnostics and diagnostics_label != null:
    diagnostics_label.queue_free()
    diagnostics_label = null
  _update_visual_diagnostics()

func _update_visual_diagnostics() -> void:
  if diagnostics_label == null or map_view == null:
    return
  var layout: Dictionary = map_view.get_debug_layout()
  var current_pan: Vector2 = layout["pan"]
  diagnostics_label.text = "FPS %d | zoom %.2f -> %.2f | pan %d,%d | tiles %d" % [
    Engine.get_frames_per_second(),
    float(layout["zoom"]),
    float(layout["target_zoom"]),
    int(current_pan.x),
    int(current_pan.y),
    int(layout["screen_geometry_count"])
  ]

func _haptic_tick(strong: bool) -> void:
  if not OS.has_feature("android"):
    return
  Input.vibrate_handheld(26 if strong else 12)

func _format_phase(phase: String) -> String:
  if phase == PHASE_ALLOCATION:
    return "Allocation"
  if phase == PHASE_MOVEMENT:
    return "Movement"
  return phase.capitalize()

func _dp(value: float) -> int:
  return UiTheme.dp(value, ui_scale)

func _font_size(value: int) -> int:
  return UiTheme.font_size(value, ui_scale)

func _snap_100(value: int) -> int:
  return int(floor(float(value) / 100.0)) * 100
