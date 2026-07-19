class_name CommandRules
extends RefCounted

static func missing_common_field(command: Dictionary) -> String:
  for key in ["type", "player_id", "turn", "phase", "client_sequence"]:
    if not command.has(key):
      return key
  return ""

static func is_valid_path_mode(mode: Variant) -> bool:
  return typeof(mode) == TYPE_STRING and String(mode) in ["append", "replace"]
