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
- Set `continuation_mode` to `autonomous` when that authorization is active.
  Task completion, commits, hygiene, tagging, and phase transition are
  nonterminal checkpoints. Report them in commentary and immediately continue
  the next dependency-safe action.
- Treat a status, review, explanation, or phase-count question as additive while
  work is active. Answer it and continue unless the user explicitly says to
  pause, stop, wait, replace scope, or report back before continuing; only then
  set `continuation_mode` to `report_required`.
- Work one tracker task through implementation, evidence, documentation, validation, and its atomic commit before switching tasks. Do not accumulate unchecked bookkeeping for later reconciliation.
- Make reversible, authority-backed implementation choices without asking routine questions. Record durable choices; ask only when missing authority would materially change product behavior or external state.
- Use fresh bounded subagents for independent audits or disjoint implementation slices when context grows. Give them repository paths and task scope, not a conversation summary; the coordinator alone integrates, edits trackers, commits, tags, pushes, promotes profiles, or makes paid calls.
- At a context boundary, finish the smallest safe slice, update the exact next action, and create the permitted checkpoint before rehydrating from sources. Never use context pressure as a reason to weaken validation or mark partial work complete.
- If CI fails, inspect the actual failing step/log, reproduce the narrow failure locally when possible, fix it under the current task ID, and require a green rerun. Never silence or relax a gate merely to make CI green.
- A final response is terminal. Before sending one, rerun Resume and inspect
  `continuation_mode`. Send a final response only when the milestone is complete,
  every eligible lane is recorded as blocked, or the user explicitly requested
  a pause and the mode is `report_required`. Otherwise use commentary and keep
  working.

## Handle Blockers

- Record the blocker in `BLOCKERS.md` with owner, scope, affected IDs, exact question/failure, safe fallback, fallback authority, and safe parallel work.
- Apply only preapproved fallbacks. Continue eligible work and batch nonurgent user questions.
- Never guess through Git divergence, destructive ambiguity, missing paid authorization, unknown spend, or unowned dirty changes.

## Close Tasks And Phases

1. Run the task's specified checks.
2. Update its evidence and checkbox in the same change.
3. Run `tools/check_work_state.ps1 -Mode TaskClose -TaskId <id>`.
4. Commit one task ID per atomic commit.
5. Before hygiene, commission a fresh, source-first, read-only review of every
   checked task, applicable requirement, exit gate, authority, implementation,
   and test surface. Record reviewer identity, reviewed ref, scope, findings,
   dispositions, and rerun evidence. If no fresh agent is available, record a
   named skeptical coordinator self-audit rather than skipping the review.
6. Treat tracker linters, green CI, and passing tests as inputs, not substitutes
   for this review. Reopen a checked task immediately when its definition of
   done is not substantively met, append a correction note, and remediate it in
   dependency order.
7. At phase end, move the phase to `Hygiene`, pass the non-publication gates, complete the hygiene log, and commit the validated closeout state with the final phase-task ID.
8. Create the immutable annotated phase tag at that closeout commit and push the milestone branch plus tag. Never move a published tag.
9. Record the verified publication evidence, check the final task/gates, mark the phase `Complete`, activate the next phase, commit that transition with the same final task ID, and push the branch.
10. Fetch without pulling, verify the remote refs, then run `tools/check_work_state.ps1 -Mode PhaseClose -PhaseId <id>`.
11. If `continuation_mode` is `autonomous`, start the next approved phase without
    waiting for a phase-completion prompt.

The phase tag intentionally marks the validated implementation/hygiene commit; the later branch-only transition records that immutable tag and remote evidence without making a commit claim its own hash.

At context boundaries, checkpoint trackers, notes, blockers, validation, and next action. Rehydrate from disk rather than relying on earlier conversation memory.
