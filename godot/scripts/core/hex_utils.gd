class_name HexUtils
extends RefCounted

const DIRECTIONS: Array[Vector2i] = [
  Vector2i(1, 0),
  Vector2i(1, -1),
  Vector2i(0, -1),
  Vector2i(-1, 0),
  Vector2i(-1, 1),
  Vector2i(0, 1)
]

static func tile_id(q: int, r: int) -> String:
  return "T_%d_%d" % [q, r]

static func parse_tile_id(id: String) -> Vector2i:
  var parts := id.split("_")
  if parts.size() < 3:
    return Vector2i.ZERO
  return Vector2i(int(parts[1]), int(parts[2]))

static func distance(a: Vector2i, b: Vector2i) -> int:
  var dq := a.x - b.x
  var dr := a.y - b.y
  return int((abs(dq) + abs(dq + dr) + abs(dr)) / 2)

static func neighbors(coord: Vector2i) -> Array[Vector2i]:
  var result: Array[Vector2i] = []
  for direction in DIRECTIONS:
    result.append(coord + direction)
  return result

static func edge_id(a: String, b: String) -> String:
  if a < b:
    return "%s|%s" % [a, b]
  return "%s|%s" % [b, a]

static func axial_to_pixel(coord: Vector2i, radius: float) -> Vector2:
  var x := radius * sqrt(3.0) * (float(coord.x) + float(coord.y) / 2.0)
  var y := radius * 1.5 * float(coord.y)
  return Vector2(x, y)

static func polygon_points(center: Vector2, radius: float) -> PackedVector2Array:
  var points := PackedVector2Array()
  for i in range(6):
    var angle := deg_to_rad(60.0 * float(i) - 30.0)
    points.append(center + Vector2(cos(angle), sin(angle)) * radius)
  return points
