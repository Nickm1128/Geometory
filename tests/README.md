# Tests

The pinned Godot suites currently live under `godot/tests/` so they can load
runtime scripts through `res://`. Root `tests/` is reserved for engine-agnostic
Python/shell fixtures introduced by replay, simulation, bot, and AI-workbench
phases.

Required test families grow in dependency order:

- P01: command, movement, merge/control/combat, draw, fog, hash, and RNG core
  contracts;
- P02: GMTY1 parser/reconstruction, corrupt records, persistence/resume, and
  rendered-free match batches;
- P03: tactical scenarios, legality/privacy, paired league, side bias, and
  bootstrap confidence;
- P04: mocked model/schema/privacy/cost/timeout/promotion safety;
- P05: 26 direct UI fixtures, size/scale matrices, structural device checks, and
  canonical same-environment image diffs; and
- P06: integrated Android lifecycle, interaction, performance, and release
  certification.

Tests and generated evidence are separate: stable fixtures/schemas belong in
source; bulk reports, logs, screenshots, replays, and APKs stay ignored.
