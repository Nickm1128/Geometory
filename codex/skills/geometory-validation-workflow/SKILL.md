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

## Failure And Evidence Discipline

- Read test output for Godot script errors, crashes, and assertion failures even when the process exit code is zero.
- When a task calls for contract-first work, preserve red/green evidence: prove the new focused test fails for the intended reason before implementation, then passes afterward.
- For deterministic/hash gates, run the required suite twice and compare the recorded outputs or hashes rather than relying on two successful exit codes.
- For a remote CI failure, inspect the actual job step/log before editing. Reproduce the environment-sensitive boundary locally where practical and never weaken assertions to accommodate a runner.
- A documentation-only checkpoint may rely on the most recent green runtime suite only when no runtime/config/package input changed and the active gate permits it. Phase closure still requires the complete documented evidence set.
- A structural tracker pass, green CI run, or green aggregate suite proves only
  what it checks. Before phase closure, independently compare each checked
  definition of done and applicable requirement/gate with the actual ownership,
  data exposure, serialization, negative cases, and implementation boundaries.
- Privacy tests must recursively inspect every observable surface, including
  event histories and metadata, rather than checking only top-level keys.
- Serialization/determinism tests must reject or normalize unsupported and
  unknown input fields and prove gameplay hashes exclude presentation-only data.
- Reopen a checked task when substantive review finds missing behavior or
  evidence; never hide that remediation inside a later closeout task while the
  owning checkbox remains inaccurately complete.

Do not check a task or gate merely because a command exited successfully. Record what was exercised, the result, and artifact/evidence location in the active phase files.
