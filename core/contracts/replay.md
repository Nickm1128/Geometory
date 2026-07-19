# GMTY1 Replay Contract

`GMTY1` is the Milestone 1 versioned, JSON-compatible match record. It is the
only replay/persistence authority; runtime snapshots, rejected diagnostics, and
presentation state are not serialized as replay authority.

## Envelope

```json
{
  "format": "GMTY1",
  "format_version": 1,
  "setup": {},
  "steps": [],
  "final": {}
}
```

- `setup` includes `ruleset_id`, `ruleset_sha256`, `map_id`, `map_sha256`,
  `seed`, deterministic RNG metadata, research schedule/version, and the
  serializable player/bot setup (`id` and `is_bot`).
- `steps` is accepted arrival order only. Every entry contains an exact accepted
  command (including its `client_sequence`) and the canonical state hash after
  that command resolves.
- `final` contains the final canonical state hash, `winner`, and `is_draw`.

The serializer uses canonical stable-key JSON. The parser accepts only an
object-shaped GMTY1 envelope with format version 1 and required object/array
sections; later replay reconstruction owns configuration compatibility,
command legality, and hash-mismatch diagnostics.
