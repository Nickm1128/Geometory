# M1-P01 Tasks — Deterministic Core Contracts

- [x] `M1-P01-T01` Lock command, turn, hashing, merge, control, and bot-observation contracts in authority docs and tests.
  - Dependencies: M1-P00-G07
  - Can run early: No
  - Definition of done: resolve the public research-schedule assumption; define global player-turn 80 draw semantics, source sequences, accepted/rejected histories, canonical serialization/hash fields, friendly merge behavior, and visible-strength policy; add failing contract tests before implementation.
  - Evidence: 2026-07-19 authority reconciliation locked 80-turn draw, public seeded research schedule, per-player accepted source sequences, stable merge semantics, canonical SHA-256 scope, and fogged enemy strength bands in assumptions/rules/design/contracts; baseline core suite passed, then focused red suite failed exactly 7 intended assertions (rejected-history/diagnostic, turn/sequence, fog strength/path, hash API) before implementation.

- [x] `M1-P01-T02` Centralize strict command validation and accepted-command history.
  - Dependencies: M1-P01-T01
  - Can run early: No
  - Definition of done: validate required keys/types, player, turn, phase, monotonic source sequence, allocation ranges/bank, stack ownership/liveness, waypoint IDs, append/replace mode, and duplicates; rejected commands produce diagnostics but never enter replay or mutate state.
  - Evidence: 2026-07-19 centralized pre-mutation validator now requires common/type-specific keys and types, current player/turn/phase, positive accepted-only per-player sequence, allocation/bank, live ownership, valid waypoint IDs, and valid mode; accepted commands are copied only after resolution and rejected diagnostics are stable. Focused assertions pass; full core suite retains exactly 3 intentional T04/T05 red assertions (hash and fog) with no engine errors.

- [x] `M1-P01-T03` Correct movement-edge validation, friendly merges, combat ordering, and post-resolution control.
  - Dependencies: M1-P01-T01, M1-P01-T02
  - Can run early: No
  - Definition of done: validate every executed adjacent edge; stop at invalid/walled edges; merge friendly cohorts deterministically, clear both queues, and emit an event; resolve controller-first defender combat before applying surviving control and capital transfer.
  - Evidence: 2026-07-19 movement revalidates each executed edge and preserves blocked queues with events; same-owner stacks merge into the stable destination, clear queues, and emit merge events; combat tiles resolve in stable order and control applies only after combat. Focused movement/combat assertions and full three-size UI smoke pass; core suite has only 3 intentional T04/T05 red assertions and no engine errors.

- [x] `M1-P01-T04` Add the turn cap, owned RNG streams, and canonical SHA-256 state hashes.
  - Dependencies: M1-P01-T02, M1-P01-T03
  - Can run early: No
  - Definition of done: resolve an unfinished match as a deterministic draw after player-turn 80; isolate deterministic research/combat/bot streams; canonicalize all gameplay-relevant state and prove repeated hashes.
  - Evidence: Reopened 2026-07-19 after fresh source review. Focused red tests then failed exactly for presentation-only player fields changing the hash, an unstructured research stream, and a missing schedule generation version. `StateHasher.gameplay_projection` now selects gameplay fields explicitly; state records immutable research/combat/bot stream descriptors under `fnv1a32_seed_mix_v1`, and the data-driven public schedule version is persisted. Two pinned Godot 4.6.3 full-core runs passed with the identical `DETERMINISM_HASH` `40659adccf14646a26b0173e2d063c132c66407c77559fd24242d7993291d2d8`; canonical/runtime data parity passed.

- [x] `M1-P01-T05` Replace direct bot core access with the fog-safe observable snapshot contract.
  - Dependencies: M1-P01-T01, M1-P01-T02
  - Can run early: No
  - Definition of done: expose full own data and only player-visible enemy/tile/wall/event data; remove `GameCore` access from bot policy; add explicit tests for hidden queues, economy, research, positions, wall damage, and strength.
  - Evidence: Reopened 2026-07-19 after fresh source review. An adversarial visible combat event initially leaked exact damage and nested enemy-strength/path fields. `FogRules.project_visible_event` now applies an allowlisted schema for every visible event (including own events), omitting unknown/nested fields, combat damage, and wall attack damage. The pinned core suite passes the recursive event-privacy assertion alongside existing fog contracts.

- [x] `M1-P01-T06` Extract modular core responsibilities behind the preserved `GameCore` facade.
  - Dependencies: M1-P01-T02, M1-P01-T03, M1-P01-T04, M1-P01-T05
  - Can run early: No
  - Definition of done: separate command validation, movement, combat, fog/observation, hashing/RNG, and turn resolution without scene-tree dependencies or public behavior regression.
  - Evidence: Reopened and completed 2026-07-19. `GameCore` is reduced to a 525-line facade: `CommandRules` owns validation; `MovementRules` owns movement/merge; `CombatRules` owns combat, damage, and control; `FogRules` owns observation; `StateHasher` owns canonical projection/serialization; new `RngRules` owns named-stream derivation; and `TurnResolver` owns turn start/end, cap, elimination, and draw decisions. Legacy duplicate command/combat/hash/RNG paths were removed. Pinned Godot 4.6.3 core tests and the 393x852/360x800/480x960 UI smoke matrix pass; root/runtime data parity passes.

- [ ] `M1-P01-T07` Complete deterministic regression evidence and P01 hygiene.
  - Dependencies: M1-P01-T06
  - Can run early: No
  - Definition of done: cover invalid and non-serializable commands, income/research, wall damage and destruction, casualty arithmetic, capture/elimination/draw, merge queues, adjacency, recursively projected fog/events, and repeated seeds; commission and resolve a fresh substantive review of every checked P01 task; run suites twice with identical hashes; pass exit gates/hygiene; publish `m1-p01`; activate P02; and continue without treating the phase boundary as a stop point while continuation mode is autonomous.
  - Evidence: Partial. Commit `efb3397` added capital-capture coverage; two pinned Godot 4.6.3 core runs passed with identical hash `0a69b09a884b4f794e83f5a6d72b0fe1350ddb4045866efeb5a05f689479ea4e`, three-size UI smoke passed, and GitHub Actions run `29700145449` is green. Fresh review then found unmet definitions of done in T04-T06 plus missing wall, casualty, malformed/non-serializable command, privacy-event, and stronger deterministic-combat coverage, so closeout remains incomplete.
