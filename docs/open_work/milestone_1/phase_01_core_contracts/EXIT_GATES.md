# M1-P01 Exit Gates — Deterministic Core Contracts

- [ ] `M1-P01-G01` The same setup and accepted command sequence produces the same canonical hash in repeated runs.
  - Evidence: Reopened by fresh source review: repeated hash output is recorded, but the documented RNG descriptor tuple/combat key is incomplete. Revalidate after T04 repair.
- [ ] `M1-P01-G02` No invalid or rejected command enters replay history or changes gameplay state.
  - Evidence: Reopened by fresh source review: rejected non-serializable commands stay out of accepted history and hash scope, but raw rejected diagnostics can make state non-serializable. Revalidate after T02 repair.
- [x] `M1-P01-G03` Movement cannot execute a non-adjacent edge, and friendly merges clear both queues with a stable event.
  - Evidence: Pinned core contracts pass for retained invalid-edge queues plus `movement_blocked`, stable lowest-ID merge selection, cleared merged queues, and `friendly_stacks_merged`.
- [ ] `M1-P01-G04` Fog and bot-observation tests prove private enemy data is absent.
  - Evidence: Reopened by fresh source review: combat-event projection is safe, but `income_added` forwards an unprojected nested dictionary. Revalidate after T05 repair.
- [ ] `M1-P01-G05` Turn 80, combat/control order, capital capture, and deterministic draw behavior pass focused tests.
  - Evidence: Reopened by fresh source review: the focused cases pass, but deterministic combat's documented RNG derivation/key scope is incomplete. Revalidate after T04 repair.
- [ ] `M1-P01-G06` All core suites pass twice with identical hashes and no engine errors.
  - Evidence: Reopened pending the repaired T02/T04/T05 full-suite repetitions.
- [ ] `M1-P01-G07` A fresh substantive source-level review verifies every checked P01 task and gate against authority, implementation, and tests; all findings are resolved or the owning task is reopened; P01 hygiene passes; and immutable tag `m1-p01` is published.
  - Evidence: Pending.
