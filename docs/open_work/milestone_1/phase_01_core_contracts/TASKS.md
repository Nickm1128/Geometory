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

- [ ] `M1-P01-T03` Correct movement-edge validation, friendly merges, combat ordering, and post-resolution control.
  - Dependencies: M1-P01-T01, M1-P01-T02
  - Can run early: No
  - Definition of done: validate every executed adjacent edge; stop at invalid/walled edges; merge friendly cohorts deterministically, clear both queues, and emit an event; resolve controller-first defender combat before applying surviving control and capital transfer.
  - Evidence: Pending.

- [ ] `M1-P01-T04` Add the turn cap, owned RNG streams, and canonical SHA-256 state hashes.
  - Dependencies: M1-P01-T02, M1-P01-T03
  - Can run early: No
  - Definition of done: resolve an unfinished match as a deterministic draw after player-turn 80; isolate deterministic research/combat/bot streams; canonicalize all gameplay-relevant state and prove repeated hashes.
  - Evidence: Pending.

- [ ] `M1-P01-T05` Replace direct bot core access with the fog-safe observable snapshot contract.
  - Dependencies: M1-P01-T01, M1-P01-T02
  - Can run early: No
  - Definition of done: expose full own data and only player-visible enemy/tile/wall/event data; remove `GameCore` access from bot policy; add explicit tests for hidden queues, economy, research, positions, wall damage, and strength.
  - Evidence: Pending.

- [ ] `M1-P01-T06` Extract modular core responsibilities behind the preserved `GameCore` facade.
  - Dependencies: M1-P01-T02, M1-P01-T03, M1-P01-T04, M1-P01-T05
  - Can run early: No
  - Definition of done: separate command validation, movement, combat, fog/observation, hashing/RNG, and turn resolution without scene-tree dependencies or public behavior regression.
  - Evidence: Pending.

- [ ] `M1-P01-T07` Complete deterministic regression evidence and P01 hygiene.
  - Dependencies: M1-P01-T06
  - Can run early: No
  - Definition of done: cover invalid commands, income/research, walls, casualties, capture/elimination/draw, merge queues, adjacency, fog, and repeated seeds; run suites twice with identical hashes; pass exit gates/hygiene; publish `m1-p01` and activate P02.
  - Evidence: Pending.
