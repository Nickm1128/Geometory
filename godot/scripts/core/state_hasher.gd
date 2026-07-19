class_name StateHasher
extends RefCounted

static func sha256(text: String) -> String:
  var context := HashingContext.new()
  context.start(HashingContext.HASH_SHA256)
  context.update(text.to_utf8_buffer())
  return context.finish().hex_encode()

static func canonical_json(value: Variant) -> String:
  match typeof(value):
    TYPE_NIL:
      return "null"
    TYPE_BOOL:
      return "true" if value else "false"
    TYPE_INT, TYPE_FLOAT, TYPE_STRING:
      return JSON.stringify(value)
    TYPE_ARRAY:
      var items: Array[String] = []
      for item in value:
        items.append(canonical_json(item))
      return "[" + ",".join(items) + "]"
    TYPE_DICTIONARY:
      var keys: Array = value.keys()
      keys.sort_custom(func(a, b): return String(a) < String(b))
      var entries: Array[String] = []
      for key in keys:
        entries.append(JSON.stringify(String(key)) + ":" + canonical_json(value[key]))
      return "{" + ",".join(entries) + "}"
    _:
      return JSON.stringify(str(value))
