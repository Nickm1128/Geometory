# M1-P01 Notes — Deterministic Core Contracts

Append-only. No implementation entries yet.

## 2026-07-19 — Activation boundary

- Status: Active in tracker only; no P01 code, tests, or authority changes have begun.
- Inherited evidence: P00 is complete at immutable tag `m1-p00`, with green closeout CI and current emulator/physical Android contract evidence.
- Exact next action: after the requested user report and acknowledgement, begin `M1-P01-T01` by reconciling the command/turn/hash/merge/control/observation contracts and adding failing tests before implementation.

## 2026-07-19 — GPT-5.6 Terra handoff preparation

- Status: P01 behavior remains unimplemented; this boundary updates only repository-canonical execution skills and the fresh-thread handoff.
- Skill improvements: long-run work now distinguishes report-only pauses from real blockers, requires one task through evidence/commit before switching, directs fresh bounded subagents to rehydrate from repository sources, treats CI logs as authority, preserves red/green evidence, distinguishes visual contracts from certification, and keeps credential-blocked P04/P05 routing explicit.
- Validation required before handoff: all five canonical skills must pass `quick_validate.py`, synchronize exactly to user-level mirrors, and pass a fresh GPT-5.6 Terra / Think High resume forward-test without edits or external actions.
- Exact next action: use the prepared new-thread prompt as explicit authorization to begin `M1-P01-T01`, then proceed through dependency-safe M1 work until completion or every eligible lane is externally blocked.
- Forward-test result: PASS under a fresh `gpt-5.6-terra` agent with reasoning `high`. It ran the repository resume sequence read-only, identified `M1-P01-T01`, chose authority reconciliation plus deliberately failing contract tests before implementation, located the relevant core/config/test files, identified premature accepted-history recording, direct bot `GameCore` access, and missing canonical hashing, and reported no blocker. It also correctly refused implementation until the coordinator published these explained handoff edits.

## 2026-07-19 — M1-P01-T01 contract and red-test boundary

- Status: Complete. Authority now defines the one-based 80-turn draw, immutable public 80-entry research schedule, accepted-only per-player source sequence, canonical SHA-256 inclusion/exclusion, deterministic merge destination/event, and visible-enemy strength-band policy.
- Files changed: `docs/ASSUMPTIONS.md`, `docs/game_rules.md`, `docs/technical_design.md`, `docs/bot_design.md`, `core/contracts/commands.md`, and `godot/tests/run_core_tests.gd`.
- Validation: the pre-change pinned core suite passed. The post-change focused red suite failed with exactly seven intended contract assertions: rejected legacy history, rejected diagnostic, mismatched turn, duplicate sequence, missing strength band, leaked exact enemy/path values, and missing canonical hash API. No engine parse/crash errors occurred.
- Blockers or risks: none; the red suite is the intentional implementation boundary, not a phase gate result.
- Exact next action: implement `M1-P01-T02` centralized strict validation and accepted/rejected command recording until the command-related red assertions pass.

## 2026-07-19 — M1-P01-T02 strict-command boundary

- Status: Complete. `GameCore` now validates an entire command before mutation, stores only accepted deep copies in `accepted_command_history`, retains separate stable rejected diagnostics, and advances per-player source sequence only after acceptance.
- Files changed: `godot/scripts/core/game_core.gd`, `godot/scripts/core/baseline_bot.gd`, and `godot/tests/run_core_tests.gd`.
- Validation: focused command assertions pass for rejected legacy/accepted history separation, diagnostics, no gameplay mutation, turn, duplicate/reusable sequence, invalid path mode, and unknown waypoint. The pinned full suite has exactly three remaining intentional red assertions owned by T04/T05 (canonical hash and fogged enemy strength/path), with no parser/crash error.
- Blockers or risks: none. The bot now owns a monotonically increasing local command sequence; its direct `GameCore` parameter remains T05 work.
- Exact next action: implement `M1-P01-T03` movement-edge validation, deterministic friendly merges, combat/control ordering, and focused tests.

## 2026-07-19 — M1-P01-T03 movement/combat boundary

- Status: Complete. Movement now revalidates the executed hex edge, preserves an invalid/walled queue with a stable blocked event, and never captures before resolution. Friendly merge selects the stable destination, clears queues, orders cohorts, and emits a merge event. Combat/control runs in stable tile order and applies control after combat before elimination.
- Files changed: `godot/scripts/core/game_core.gd` and `godot/tests/run_core_tests.gd`.
- Validation: focused tests pass for non-adjacent-edge prevention, retained invalid queue/event, deterministic merge/queue-clear/event, controller-first defender, and post-combat control. Pinned three-size UI smoke passed. The core suite retains exactly three intended T04/T05 red assertions (hash and fog) with no engine errors.
- Blockers or risks: none.
- Exact next action: implement `M1-P01-T04` turn-cap draw behavior, owned RNG stream metadata, canonical SHA-256 hashing, and deterministic tests.

## 2026-07-19 — M1-P01-T04 deterministic hash/turn-cap boundary

- Status: Complete. State now records schema/config hashes and named RNG stream metadata; canonical stable-key serialization is hashed with SHA-256 and deliberately excludes rejected diagnostics. After resolving player-turn 80, an otherwise unfinished match emits one deterministic draw and does not start turn 81.
- Files changed: `godot/scripts/core/game_core.gd` and `godot/tests/run_core_tests.gd`.
- Validation: focused tests pass for equal SHA-256 hashes, rejected-diagnostic hash exclusion, 64-hex output, recorded research/combat/bot streams, and a complete 80-turn zero-allocation draw cycle. The core suite retains exactly two intentional T05 fog-observation red assertions, with no engine errors.
- Blockers or risks: none.
- Exact next action: implement `M1-P01-T05` fog-safe observable snapshots, remove direct `GameCore` access from bot policy, and prove private data is absent.

## 2026-07-19 — M1-P01-T05 fog-safe bot boundary

- Status: Complete. `BaselineBot` now accepts an observable value snapshot rather than `GameCore`; presentation obtains that snapshot from the core. Own stacks stay complete, while visible enemies carry only ID/owner/tile/strength band. The snapshot exposes no private player collection, diagnostics, hidden stack/wall data, or hidden enemy events.
- Files changed: `godot/scripts/core/game_core.gd`, `godot/scripts/core/baseline_bot.gd`, `godot/scripts/presentation/main.gd`, and `godot/tests/run_core_tests.gd`.
- Validation: pinned core suite passes all contracts, including dedicated fog tests for hidden positions, paths, economy, research, walls, and exact strength; no engine errors.
- Blockers or risks: none.
- Exact next action: implement `M1-P01-T06` modular responsibility extraction behind the preserved `GameCore` facade, then run focused regression tests.

## 2026-07-19 — M1-P01-T06 core-extraction boundary

- Status: Complete. `GameCore` remains the public deterministic facade, with scene-free `RefCounted` services owning command schema rules, movement-edge/cohort rules, controller-first combat selection, fog strength policy, canonical hashing, and turn progression decisions.
- Files changed: `godot/scripts/core/{command_rules,movement_rules,combat_rules,fog_rules,state_hasher,turn_resolver}.gd`, `godot/scripts/core/game_core.gd`, and `godot/scripts/core/README.md`.
- Validation: pinned core suite passes with no parser/engine errors; no extracted script extends `Node` or references scene/input/rendering APIs.
- Blockers or risks: none.
- Exact next action: complete `M1-P01-T07` full deterministic regression evidence, repeated hashes, P01 gates/hygiene, publication, and P02 activation.
