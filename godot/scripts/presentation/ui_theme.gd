class_name GeometoryPresentationTheme
extends RefCounted

const BACKGROUND := Color("#050B12")
const BACKGROUND_ALT := Color("#07121C")
const SURFACE := Color("#0A1621", 0.94)
const SURFACE_RAISED := Color("#0E2030", 0.96)
const SURFACE_SOFT := Color("#102536", 0.86)
const BORDER := Color("#31536A", 0.78)
const BORDER_SOFT := Color("#20384C", 0.62)
const GRID := Color("#BDEFFF", 0.20)
const GRID_FAINT := Color("#87B9CB", 0.08)
const TEXT := Color("#F4FBFF")
const TEXT_MUTED := Color("#AFC8D7")
const TEXT_DIM := Color("#6F8798")
const ACCENT := Color("#35C7FF")
const ACCENT_SOFT := Color("#35C7FF", 0.26)
const WARN := Color("#F6D36B")
const DANGER := Color("#FF5A66")
const SUCCESS := Color("#70F2A4")
const FOG := Color("#050A10", 0.76)
const NEUTRAL := Color("#303A4A")
const TILE_DARK := Color("#101A25")
const TILE_INNER := Color("#172634")
const PANEL_RADIUS := 16.0
const BUTTON_RADIUS := 13.0
const TOUCH_TARGET := 56.0
const CAMERA_RESPONSE := 12.0
const CAMERA_RESPONSE_REDUCED := 20.0
const CAMERA_FRICTION := 2200.0
const INTRO_DURATION_MS := 900.0
const PATH_DRAW_MS := 260.0
const BANNER_MS := 900.0

static func dp(value: float, scale: float) -> int:
  return int(round(value * scale))

static func font_size(value: int, scale: float) -> int:
  return max(10, int(round(float(value) * scale)))

static func panel_style(fill: Color, border: Color, scale: float, radius: float = PANEL_RADIUS, border_width: int = 1) -> StyleBoxFlat:
  var style := StyleBoxFlat.new()
  style.bg_color = fill
  style.border_color = border
  style.set_border_width_all(border_width)
  style.set_corner_radius_all(dp(radius, scale))
  style.content_margin_left = dp(12, scale)
  style.content_margin_right = dp(12, scale)
  style.content_margin_top = dp(10, scale)
  style.content_margin_bottom = dp(10, scale)
  return style

static func button_style(primary: bool, active: bool, disabled: bool, scale: float) -> StyleBoxFlat:
  var style := StyleBoxFlat.new()
  if primary:
    style.bg_color = ACCENT
    style.border_color = Color("#A9EBFF", 0.72)
  else:
    style.bg_color = SURFACE_SOFT
    style.border_color = BORDER
  if active:
    style.bg_color = style.bg_color.lightened(0.10)
    style.border_color = style.border_color.lightened(0.18)
  if disabled:
    style.bg_color = Color("#0A131C", 0.82)
    style.border_color = Color("#243646", 0.54)
  style.set_border_width_all(1)
  style.set_corner_radius_all(dp(BUTTON_RADIUS, scale))
  style.content_margin_left = dp(12, scale)
  style.content_margin_right = dp(12, scale)
  style.content_margin_top = dp(10, scale)
  style.content_margin_bottom = dp(10, scale)
  return style

static func chip_style(fill: Color, border: Color, scale: float) -> StyleBoxFlat:
  var style := StyleBoxFlat.new()
  style.bg_color = fill
  style.border_color = border
  style.set_border_width_all(1)
  style.set_corner_radius_all(dp(999, scale))
  style.content_margin_left = dp(9, scale)
  style.content_margin_right = dp(9, scale)
  style.content_margin_top = dp(4, scale)
  style.content_margin_bottom = dp(4, scale)
  return style