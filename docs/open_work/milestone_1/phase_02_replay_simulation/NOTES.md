# M1-P02 Notes — Replay, Simulation, Resume, And Evidence

Append-only. No implementation entries yet.

## 2026-07-19 - Activation boundary

- Status: Active after remote-verified immutable P01 tag `m1-p01`.
- Inherited guarantees: strict serializable accepted-command history, canonical hashes, explicit RNG metadata, and fog-safe bot observation are the replay boundary.
- Exact next action: M1-P02-T01 authority reconciliation and focused GMTY1 serialization/parser red tests.

## 2026-07-19 - M1-P02-T01 GMTY1 serialization contract

- Status: Complete. `core/contracts/replay.md` defines the version-1 envelope; `ReplayCodec` emits canonical stable-key JSON and parses a typed/normalized envelope containing setup, accepted command steps, and final outcome/hash.
- Red/green evidence: the focused test first failed at the missing codec preload, then passed round-trip stability, setup/step/final fields, preserved integer command sequence, and malformed JSON diagnostics under pinned Godot 4.6.3.
- Exact next action: M1-P02-T02 production reconstruction and corrupt-record diagnostics.
