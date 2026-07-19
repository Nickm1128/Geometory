# M1-P01 Exit Gates — Deterministic Core Contracts

- [x] `M1-P01-G01` The same setup and accepted command sequence produces the same canonical hash in repeated runs.
  - Evidence: Two pinned Godot 4.6.3 full-core runs on 2026-07-19 both emitted `DETERMINISM_HASH` `e390ad42e8508f6c8a0d8af894266e9150eacd7b0fa75e805e57a0ea39a79839`; fresh source review passed the repaired descriptor tuple and combat-key scope.
- [x] `M1-P01-G02` No invalid or rejected command enters replay history or changes gameplay state.
  - Evidence: Pinned contracts prove unknown/malformed/stale commands, including a `RefCounted` unknown field, stay out of accepted history and canonical hash scope; the remaining diagnostic projection is recursively serializable.
- [x] `M1-P01-G03` Movement cannot execute a non-adjacent edge, and friendly merges clear both queues with a stable event.
  - Evidence: Pinned core contracts pass for retained invalid-edge queues plus `movement_blocked`, stable lowest-ID merge selection, cleared merged queues, and `friendly_stacks_merged`.
- [x] `M1-P01-G04` Fog and bot-observation tests prove private enemy data is absent.
  - Evidence: Pinned recursive fog contracts prove hidden enemy data and nested combat/income private values are absent; fresh source review verified each projected event schema.
- [x] `M1-P01-G05` Turn 80, combat/control order, capital capture, and deterministic draw behavior pass focused tests.
  - Evidence: Pinned contracts pass controller-first combat, post-resolution control, capital elimination, player-turn-80 draw, stable draw event, wall damage/destruction, casualty rounding/removal, and repeated combat with documented cohort-key salts.
- [x] `M1-P01-G06` All core suites pass twice with identical hashes and no engine errors.
  - Evidence: Two pinned Godot 4.6.3 full-core runs passed without `ERROR` or `SCRIPT ERROR` and returned identical hash `e390ad42e8508f6c8a0d8af894266e9150eacd7b0fa75e805e57a0ea39a79839`. Three-size UI smoke and visual-QA contract suites also pass.
- [x] `M1-P01-G07` A fresh substantive source-level review verifies every checked P01 task and gate against authority, implementation, and tests; all findings are resolved or the owning task is reopened; P01 hygiene passes; and immutable tag `m1-p01` is published.
  - Evidence: `/root/p01_final_review` fresh source review at `a8629d3` found no remaining issue in T01-T06/G01-G06 after verifying the prior repair dispositions. P01 hygiene recorded Pass; annotated tag object `db945cd361632c0e48fba1ce16efa367a534dd44` resolves locally and at `origin` as immutable `m1-p01` on closeout commit `fe2eede`.
