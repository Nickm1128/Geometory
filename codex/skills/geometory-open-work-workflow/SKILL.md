---
name: geometory-open-work-workflow
description: "Resume, coordinate, and close autonomous Geometory milestone work in C:\\Users\\milin\\Documents\\Geometory. Use when continuing substantial work from repository state, selecting the next tracked task, handling blockers, updating phase checkboxes/evidence, running hygiene, managing context handoffs, or creating permitted Git checkpoints."
---

# Geometory Open Work Workflow

Treat the repository trackers as execution state. Keep one coordinating agent responsible for trackers, paid calls, Git checkpoints, and integration.

## Resume

1. Read `AGENTS.md`.
2. Run `tools/sync_codex_skills.ps1 -Mode Check`.
3. Read `docs/open_work/INDEX.md`, `MILESTONE_1_PLAN.md`, and only the active phase's four files.
4. Run `tools/check_work_state.ps1 -Mode Resume`.
5. Fetch without pulling; inspect status, recent log, and relevant diff.
6. Reconcile any dirty files with the recorded current task. Open a blocker instead of resetting uncertain work.
7. Load only task-relevant authority docs and code, then resume from the latest phase note.

## Execute

- Work the current eligible task or the next dependency-safe task in `TASKS.md`.
- A blocked or partial task stays `[ ]`. Mark `[x]` immediately only after implementation, required validation, evidence, and affected docs are complete.
- Append concise evidence and cross-phase consequences to `NOTES.md`; update the exact next action in `INDEX.md`.
- Delegate bounded, disjoint work when useful. Subagents return changes/evidence; the coordinator owns integration and tracker state.

## Run Autonomously For Long Sessions

- Treat an explicit new user prompt to begin or continue milestone work as clearing a report/acknowledgement-only handoff in `INDEX.md`. It does not clear a recorded blocker, paid-call boundary, destructive ambiguity, or Git divergence.
- Work one tracker task through implementation, evidence, documentation, validation, and its atomic commit before switching tasks. Do not accumulate unchecked bookkeeping for later reconciliation.
- Make reversible, authority-backed implementation choices without asking routine questions. Record durable choices; ask only when missing authority would materially change product behavior or external state.
- Use fresh bounded subagents for independent audits or disjoint implementation slices when context grows. Give them repository paths and task scope, not a conversation summary; the coordinator alone integrates, edits trackers, commits, tags, pushes, promotes profiles, or makes paid calls.
- At a context boundary, finish the smallest safe slice, update the exact next action, and create the permitted checkpoint before rehydrating from sources. Never use context pressure as a reason to weaken validation or mark partial work complete.
- If CI fails, inspect the actual failing step/log, reproduce the narrow failure locally when possible, fix it under the current task ID, and require a green rerun. Never silence or relax a gate merely to make CI green.
- Honor explicit user report boundaries after updating durable state. Do not start the next implementation task until the requested report or acknowledgement occurs.

## Handle Blockers

- Record the blocker in `BLOCKERS.md` with owner, scope, affected IDs, exact question/failure, safe fallback, fallback authority, and safe parallel work.
- Apply only preapproved fallbacks. Continue eligible work and batch nonurgent user questions.
- Never guess through Git divergence, destructive ambiguity, missing paid authorization, unknown spend, or unowned dirty changes.

## Close Tasks And Phases

1. Run the task's specified checks.
2. Update its evidence and checkbox in the same change.
3. Run `tools/check_work_state.ps1 -Mode TaskClose -TaskId <id>`.
4. Commit one task ID per atomic commit.
5. At phase end, move the phase to `Hygiene`, pass the non-publication gates, complete the hygiene log, and commit the validated closeout state with the final phase-task ID.
6. Create the immutable annotated phase tag at that closeout commit and push the milestone branch plus tag. Never move a published tag.
7. Record the verified publication evidence, check the final task/gates, mark the phase `Complete`, activate the next phase, commit that transition with the same final task ID, and push the branch.
8. Fetch without pulling, verify the remote refs, then run `tools/check_work_state.ps1 -Mode PhaseClose -PhaseId <id>`.

The phase tag intentionally marks the validated implementation/hygiene commit; the later branch-only transition records that immutable tag and remote evidence without making a commit claim its own hash.

At context boundaries, checkpoint trackers, notes, blockers, validation, and next action. Rehydrate from disk rather than relying on earlier conversation memory.
