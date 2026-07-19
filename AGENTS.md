# Geometory Agent Contract

This repository is the durable source of truth for Geometory work. Do not rely on conversation history to know what is active or complete.

## Resume Before Acting

1. Inspect `git status --short --branch`, `git log -5 --oneline --decorate`, and the configured remotes. Fetch remote refs, but never pull or resolve divergence automatically.
2. Run `tools/sync_codex_skills.ps1 -Mode Check` when that tool exists. During P00, an absent sync tool is tracked work rather than permission to improvise a different workflow.
3. Read the canonical `geometory-open-work-workflow` skill, then `docs/open_work/INDEX.md` and `docs/open_work/MILESTONE_1_PLAN.md`.
4. Read the active phase's `REQUIREMENTS.md`, `TASKS.md`, `EXIT_GATES.md`, and `NOTES.md`.
5. Run `tools/check_work_state.ps1 -Mode Resume`.
6. Load only the authority documents and code needed for the current task. Continue from the exact next action in `INDEX.md` and the latest phase note.

## Document Authority

- `docs/vision.md`: product vision and six pillars.
- `docs/ASSUMPTIONS.md`: locked and open product decisions.
- `docs/game_rules.md`: gameplay behavior.
- `docs/technical_design.md`: architecture and subsystem ownership.
- `docs/ui_ux_guidelines.md`: mobile interaction and visual requirements.
- `docs/bot_design.md`: bot behavior and fairness.
- `docs/simulation_training_loop.md`: simulation and AI-assisted evaluation.
- `docs/open_work/`: execution state, evidence, blockers, and handoffs. It must not silently redefine the authorities above.

When a task changes durable behavior, update the appropriate authority document and link that decision from phase notes.

## Task Discipline

- Only the coordinating agent edits open-work trackers, promotes bot profiles, makes paid model calls, or performs Git publication actions. Subagents return evidence to the coordinator.
- Work on one dependency-safe task at a time. A later-phase task may run early only when its task entry says `Can run early: Yes` and all dependencies pass.
- Keep a task unchecked while it is partial or blocked. Mark `[x]` only after implementation, required validation, evidence, and affected documentation are complete.
- Update task evidence, phase notes, blockers, the run log, and `INDEX.md` immediately at a boundary; never batch-reconcile them at phase end.
- Use stable IDs exactly as documented. Do not renumber published task, requirement, gate, or blocker IDs.
- Treat `NOTES.md` and `RUN_LOG.md` as append-only. Correct an old entry with a new dated entry.

## Blockers And Context Boundaries

Record a blocker immediately in `docs/open_work/BLOCKERS.md`, leave affected work unchecked, and continue eligible work. Stop only the affected lane unless every safe lane is blocked.

Before yielding, compaction, or handing work to a fresh agent, record:

- the current task and status;
- files changed and decisions made;
- validations run and their exact results;
- unresolved risks or blockers;
- the next executable action.

Fresh agents must rebuild context from repository sources using the resume sequence above.

## Validation And Hygiene

- Run the smallest relevant validation during implementation and the phase's full exit-gate suite before closure.
- Root `data/` is authoritative. If it changes, synchronize `godot/data/` and prove byte parity.
- UI work requires deterministic fixture evidence plus device or emulator checks specified by the active phase.
- Bot work must use fog-filtered observable state and normal validated commands.
- Generated APKs, screenshots, replays, reports, secrets, and model transport artifacts stay in ignored artifact locations.
- After every phase, execute `docs/open_work/hygiene/CHECKLIST.md`, append the result to its log, close remediation tasks, and only then activate the next phase.

## Git Safety

- Milestone 1 work belongs on `milestone/m1-vertical-slice` after the protected `m1-baseline` tag.
- Use an atomic task commit whose subject contains exactly one task ID. Push at context checkpoints and after hygiene passes.
- Publish immutable annotated phase tags `m1-p00` through `m1-p06`; use `-r1`, `-r2`, and so on if a completed phase is reopened.
- Never force-push, move a published tag, merge to `main`, pull through divergence, discard unknown work, or expose credentials.

## Completion

A phase is complete only when all of its tasks and gates are checked, its hygiene record passes, its notes and authorities agree, its task commits are present, and its immutable phase tag exists. Milestone 1 additionally requires every milestone acceptance condition in `MILESTONE_1_PLAN.md`.
