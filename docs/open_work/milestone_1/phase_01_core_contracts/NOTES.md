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
