---
name: geometory-project-context
description: "Use when working in C:\\Users\\milin\\Documents\\Geometory on the mobile-first Godot Android hex strategy game, including planning, implementing, reviewing, or documenting rules, architecture, bots, simulation, replay, persistence, mobile UI, tooling, or milestone work."
---

# Geometory Project Context

## Start

1. Read `AGENTS.md` and, when present, `docs/open_work/INDEX.md` plus the active phase files.
2. Inspect current files and Git state before editing.
3. Read `docs/ASSUMPTIONS.md`, `docs/game_rules.md`, and `docs/technical_design.md` for behavior or architecture work.
4. Also read `docs/ui_ux_guidelines.md` for presentation work, `docs/bot_design.md` for bot work, and `docs/simulation_training_loop.md` for replay/simulation work.

## Preserve The Architecture

- Keep the core deterministic, headless, serializable, and independent of scenes/input/rendering.
- Keep presentation responsible for UI, camera, interaction translation, animation, and haptics.
- Use commands for human and bot intent; use events/state for results.
- Store money as integer cents and multipliers as basis points.
- Use seeded, explicitly owned randomness.
- Give bots only player-equivalent observable state.
- Treat root `data/` as canonical and run `tools/sync_godot_data.ps1` after changes.
- Record ambiguous or changed product behavior in `docs/ASSUMPTIONS.md` and the active phase notes.

## Shape Changes Safely

- Take the current phase/task only from `docs/open_work/INDEX.md`; never encode or trust a stale phase from conversation context.
- For behavioral work, proceed contract-first: reconcile authority and interfaces, add a focused failing test, implement the smallest coherent slice, then run focused and required regression validation.
- Prefer extracting responsibilities behind stable facades over broad rewrites. Preserve `GameCore` callers while moving deterministic logic into independently testable modules.
- Verify that a documented command, fixture, runner, or capability exists before invoking or claiming it. A planned artifact is not an implemented one.

Deliver the polished 1v1 vertical slice before additional maps, players, units, or networking. P2P and runtime LLM behavior are outside Milestone 1.
