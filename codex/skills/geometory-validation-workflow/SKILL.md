---
name: geometory-validation-workflow
description: "Validate, test, export, or certify Geometory work in C:\\Users\\milin\\Documents\\Geometory, including deterministic core behavior, replay/resume, simulation, bot fairness, Godot UI, visual scenarios, Android manifests, emulator/device behavior, and phase-exit evidence."
---

# Geometory Validation Workflow

## Start

1. Read the active task and exit gates.
2. Inspect `docs/tooling_inventory.md` and `docs/workflows/engineering_workflow.md`.
3. Route presentation/device work to `docs/workflows/visual_qa.md`, bot/simulation/AI work to `docs/bot_design.md` plus `docs/simulation_training_loop.md`, Android packaging to `docs/workflows/android_validation.md`, and core/replay work to the active contracts plus `docs/technical_design.md`.
4. Record the exact tool/engine version and target used.

## Validation Order

1. Check canonical/runtime data parity.
2. Run focused tests for the changed subsystem.
3. Run the full headless core suite; repeat deterministic/hash-sensitive suites when required.
4. Run UI smoke tests for presentation changes.
5. Use `$geometory-visual-qa` for rendered UI/device evidence.
6. Use `$geometory-bot-training-workflow` for bot, simulation, or AI-loop evidence.
7. Export and inspect Android artifacts when the task affects packaging or a phase gate.

## Required Properties

- Same setup and accepted commands yield identical state hashes.
- Invalid commands do not enter replay history.
- Bots see only the documented observable state.
- Replay reconstructs the recorded outcome and hash.
- UI passes supported portrait sizes, safe areas, scale settings, touch targets, and drag/pinch protection.
- Android evidence records build path/hash, manifest SDK/permissions/architectures, install target, launch result, and relevant log errors.

Do not check a task or gate merely because a command exited successfully. Record what was exercised, the result, and artifact/evidence location in the active phase files.
