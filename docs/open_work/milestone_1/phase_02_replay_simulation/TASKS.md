# M1-P02 Tasks — Replay, Simulation, Resume, And Evidence

- [x] `M1-P02-T01` Specify and implement the lossless GMTY1 versioned serialization contract.
  - Dependencies: M1-P01-G07
  - Can run early: No
  - Definition of done: include rules/map IDs and hashes, seed, player/bot setup, research schedule or derivation contract, every accepted command field/sequence, step hashes, final hash, winner/draw, and format version; provide deterministic serializer/parser behavior.
  - Evidence: 2026-07-19 defined `core/contracts/replay.md` and added scene-free `ReplayCodec`. GMTY1 canonical JSON carries format/version, rules/map IDs and hashes, seed, RNG/research setup, player/bot setup, exact accepted commands and post-resolution step hashes, plus final hash/winner/draw. Parser normalizes integral JSON numbers back to GDScript integers and returns stable malformed/format/version/envelope diagnostics. Focused red test failed because the codec was absent; pinned Godot 4.6.3 post-implementation suite passes deterministic round-trip and malformed-input contracts.

- [ ] `M1-P02-T02` Reconstruct matches and diagnose corrupt or incompatible replay records.
  - Dependencies: M1-P02-T01
  - Can run early: No
  - Definition of done: replay accepted commands through the production validator/core; verify step/final hashes; return structured diagnostics for malformed, truncated, stale-config, unsupported-version, illegal-command, and mismatched-hash input.
  - Evidence: Pending.

- [ ] `M1-P02-T03` Build the rendered-free full-match runner, metrics, manifests, and CLI.
  - Dependencies: M1-P02-T02
  - Can run early: No
  - Definition of done: run production bot/core matches headlessly; emit deterministic JSON summary, compact replay, hashes, config/core versions, errors, timings, and the approved economy/territory/research/strength/wall/combat/idle/invalid metrics.
  - Evidence: Pending.

- [ ] `M1-P02-T04` Establish paired development/holdout seed suites and repeatability evidence.
  - Dependencies: M1-P02-T03
  - Can run early: No
  - Definition of done: version fixed development seeds and protected holdout inputs, support side-swapped pairings, run at least 200 matches, and prove representative repeated batches produce identical gameplay summaries and hashes.
  - Evidence: Pending.

- [ ] `M1-P02-T05` Add atomic command-log persistence and automatic match resume.
  - Dependencies: M1-P02-T02
  - Can run early: No
  - Definition of done: persist after every accepted command through temporary-file replacement; reconstruct rather than trust a snapshot; expose valid resume metadata; quarantine invalid records with a recoverable explanation; handle app/process restart.
  - Evidence: Pending.

- [ ] `M1-P02-T06` Add main-menu Continue and last-completed-replay lifecycle.
  - Dependencies: M1-P02-T05
  - Can run early: No
  - Definition of done: show `Continue Match` only for a valid unfinished record; retain the latest completed replay, clear active-match state on completion, and show `Review Last Match`; preserve one record of each kind only.
  - Evidence: Pending.

- [ ] `M1-P02-T07` Implement the player-facing replay inspector.
  - Dependencies: M1-P02-T02, M1-P02-T06
  - Can run early: No
  - Definition of done: reconstruct start/end and previous/next resolved player-turn views, board state, turn/event text, and postgame omniscient information; provide touch-safe exit/navigation and no live-state mutation.
  - Evidence: Pending.

- [ ] `M1-P02-T08` Complete replay/resume/simulation integration evidence and P02 hygiene.
  - Dependencies: M1-P02-T04, M1-P02-T07
  - Can run early: No
  - Definition of done: pass corruption, restart, full reconstruction, batch repeatability, and replay-UI checks; reconcile contracts/docs; pass exit gates/hygiene; publish `m1-p02` and activate P03.
  - Evidence: Pending.
