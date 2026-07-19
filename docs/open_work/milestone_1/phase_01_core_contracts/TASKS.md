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
  - Evidence: Reopened and repaired 2026-07-19. Unsupported fields are rejected before acceptance, while `CommandRules.rejected_command_diagnostic` records only scalar common fields plus sorted field names. The pinned core suite proves a rejected `RefCounted` field neither mutates/hash-enters gameplay nor leaves any non-serializable MatchState value.

- [x] `M1-P01-T03` Correct movement-edge validation, friendly merges, combat ordering, and post-resolution control.
  - Dependencies: M1-P01-T01, M1-P01-T02
  - Can run early: No
  - Definition of done: validate every executed adjacent edge; stop at invalid/walled edges; merge friendly cohorts deterministically, clear both queues, and emit an event; resolve controller-first defender combat before applying surviving control and capital transfer.
  - Evidence: 2026-07-19 movement revalidates each executed edge and preserves blocked queues with events; same-owner stacks merge into the stable destination, clear queues, and emit merge events; combat tiles resolve in stable order and control applies only after combat. Focused movement/combat assertions and full three-size UI smoke pass; core suite has only 3 intentional T04/T05 red assertions and no engine errors.

- [x] `M1-P01-T04` Add the turn cap, owned RNG streams, and canonical SHA-256 state hashes.
  - Dependencies: M1-P01-T02, M1-P01-T03
  - Can run early: No
  - Definition of done: resolve an unfinished match as a deterministic draw after player-turn 80; isolate deterministic research/combat/bot streams; canonicalize all gameplay-relevant state and prove repeated hashes.
  - Evidence: Reopened and repaired 2026-07-19. `RngRules` now mixes derivation version, `stream_id`, purpose, salt namespace, operation salt, and match seed. Combat's operation salt includes tile, exchange, sorted attacker cohort IDs, and sorted defender cohort IDs. Pinned Godot 4.6.3 contracts prove descriptor changes separate streams, cohort identities change combat salts, and repeat seeded combat identically.

- [x] `M1-P01-T05` Replace direct bot core access with the fog-safe observable snapshot contract.
  - Dependencies: M1-P01-T01, M1-P01-T02
  - Can run early: No
  - Definition of done: expose full own data and only player-visible enemy/tile/wall/event data; remove `GameCore` access from bot policy; add explicit tests for hidden queues, economy, research, positions, wall damage, and strength.
  - Evidence: Reopened and repaired 2026-07-19. `income_added.income` now recursively projects only integer `own`, `foreign`, `base`, `bonus_bps`, and `final` values. Pinned Godot 4.6.3 contracts prove an adversarial nested private field cannot reach a visible income event.

- [x] `M1-P01-T06` Extract modular core responsibilities behind the preserved `GameCore` facade.
  - Dependencies: M1-P01-T02, M1-P01-T03, M1-P01-T04, M1-P01-T05
  - Can run early: No
  - Definition of done: separate command validation, movement, combat, fog/observation, hashing/RNG, and turn resolution without scene-tree dependencies or public behavior regression.
  - Evidence: Revalidated 2026-07-19 after repaired T04/T05 dependencies. `GameCore` remains a 525-line facade; all seven extracted services have real responsibility entry points and no scene-tree/input/rendering dependency. Pinned Godot 4.6.3 core suite passes with deterministic hash `e390ad42e8508f6c8a0d8af894266e9150eacd7b0fa75e805e57a0ea39a79839`.

- [x] `M1-P01-T07` Complete deterministic regression evidence and P01 hygiene.
  - Dependencies: M1-P01-T06
  - Can run early: No
  - Definition of done: cover invalid and non-serializable commands, income/research, wall damage and destruction, casualty arithmetic, capture/elimination/draw, merge queues, adjacency, recursively projected fog/events, and repeated seeds; commission and resolve a fresh substantive review of every checked P01 task; run suites twice with identical hashes; pass exit gates/hygiene; publish `m1-p01`; activate P02; and continue without treating the phase boundary as a stop point while continuation mode is autonomous.
  - Evidence: Complete 2026-07-19. Added and passed malformed/non-serializable diagnostics, wall, casualty, recursive event-privacy, and strengthened deterministic-combat coverage. Two pinned Godot 4.6.3 full-core runs produced identical `e390ad42e8508f6c8a0d8af894266e9150eacd7b0fa75e805e57a0ea39a79839`; three-size UI smoke, visual-QA contracts, parity, Audit, fresh review, and P01 hygiene passed. Immutable annotated `m1-p01` tag object `db945cd361632c0e48fba1ce16efa367a534dd44` is remote-verified and points to hygiene closeout `fe2eede`; P02 is active.
