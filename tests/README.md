# Tests

Testing is organized around the core-first architecture.

- `core_logic_tests`: economy, research, movement, fog, walls, combat.
- `simulation_tests`: deterministic match replays, seed reproducibility, full match completion.
- `bot_tests`: observable-state limits, command validity, heuristic behavior.

Once Godot is discoverable, headless tests should run without loading gameplay scenes.
