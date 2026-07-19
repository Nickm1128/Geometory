class_name ConfigLoader
extends RefCounted

static func load_json(path: String) -> Dictionary:
  if not FileAccess.file_exists(path):
    push_error("Missing JSON file: %s" % path)
    return {}
  var text := FileAccess.get_file_as_string(path)
  var parsed = JSON.parse_string(text)
  if typeof(parsed) != TYPE_DICTIONARY:
    push_error("Invalid JSON dictionary: %s" % path)
    return {}
  return parsed

static func load_all() -> Dictionary:
  return {
    "rules": load_json("res://data/rules/default_rules.json"),
    "map": load_json("res://data/maps/alpha_handcrafted.map.json"),
    "bot": load_json("res://data/bots/baseline_rule_bot.json")
  }
