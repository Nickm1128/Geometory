class_name FogRules
extends RefCounted

static func strength_band(soldiers: int) -> String:
  if soldiers <= 2:
    return "tiny"
  if soldiers <= 5:
    return "small"
  if soldiers <= 10:
    return "medium"
  if soldiers <= 20:
    return "large"
  return "overwhelming"
