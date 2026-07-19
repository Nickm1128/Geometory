# Engineering Workflow

Use this workflow for feature work in Geometory.

## Start

1. Read `docs/ASSUMPTIONS.md`, `docs/game_rules.md`, and `docs/technical_design.md` for the affected area.
2. Inspect current files before editing.
3. Identify whether the change belongs in core simulation, presentation, data config, tools, or docs.
4. Update assumptions or rules docs before changing behavior.

## Implementation Order

1. Add or update config constants first.
2. Implement pure core behavior without UI dependencies.
3. Add headless tests or test notes.
4. Wire presentation/UI to core commands and events.
5. Validate mobile layout if UI changed.
6. Update roadmap or docs when scope shifts.

## Core Rules

- Keep rules deterministic.
- Use integer cents and basis points for economy math.
- Use seeded RNG streams for research, combat, and bot randomness.
- Do not let scenes own game rules.
- Commands are the boundary for human, bot, replay, and future network actions.

## Done Criteria

A change is complete when:

- behavior is documented or linked to existing rules
- constants are configurable where balance may change
- core logic can run headlessly or has a clear test path
- UI changes respect mobile touch and scaling guidelines
- generated artifacts are ignored or placed in documented artifact folders
