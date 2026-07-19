class_name RngRules
extends RefCounted

static func deterministic_range(seed: int, streams: Dictionary, stream: String, operation_salt: String, min_value: int, max_value: int) -> int:
  var span := max_value - min_value + 1
  return min_value + int(abs(stream_hash(seed, streams, stream, operation_salt)) % span)

static func unit_random(seed: int, streams: Dictionary, turn: int, stream: String, salt: String) -> float:
  var value: int = abs(stream_hash(seed, streams, stream, "%s_%d" % [salt, turn])) % 1000000
  return float(value) / 1000000.0

static func stream_hash(seed: int, streams: Dictionary, stream: String, salt: String) -> int:
  var descriptor: Dictionary = streams.get(stream, {})
  var derivation_version := String(streams.get("derivation_version", ""))
  var stream_id := String(descriptor.get("stream_id", stream))
  var purpose := String(descriptor.get("purpose", ""))
  var stream_namespace := String(descriptor.get("salt_namespace", stream))
  var text := "%s|%s|%s|%s|%s" % [derivation_version, stream_id, purpose, stream_namespace, salt]
  var hash := 2166136261
  for i in range(text.length()):
    hash = int((hash ^ text.unicode_at(i)) * 16777619) & 0x7fffffff
  return int((hash ^ seed) * 1103515245 + 12345) & 0x7fffffff
