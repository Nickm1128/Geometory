# Engineering Workflow

`AGENTS.md` and the repository-canonical Geometory skills are the operating
authority. This page summarizes ordinary implementation flow; it does not
replace the active phase tracker or its exit gates.

## Resume

1. Read `AGENTS.md` and run `tools/sync_codex_skills.ps1 -Mode Check`.
2. Read the open-work skill, `docs/open_work/INDEX.md`, the M1 plan, and the
   active phase's four files.
3. Run `tools/check_work_state.ps1 -Mode Resume`.
4. Fetch—but do not pull—and inspect branch status, divergence, log, and diff.
5. Load only the authority/code needed for the current task and resume from the
   exact append-only notes handoff.

## Implement

1. Confirm the task ID, dependencies, early-run permission, definition of done,
   and evidence contract.
2. Update durable assumptions/rules before intentionally changing behavior.
3. Change configuration/contracts first, then pure core behavior, tests,
   presentation wiring, and task-relevant documentation.
4. Keep rules deterministic; use cents/basis points and explicitly owned seeded
   RNG streams. Scenes never own game rules.
5. Human, bot, replay, and future network actions cross the core as serializable
   validated commands. Only accepted commands enter replay history.
6. Keep generated artifacts ignored and stable evidence concise/versioned.

## Coordinate

- Only the coordinating agent edits trackers, commits, tags, pushes, promotes a
  bot, or initiates paid calls.
- Affected blocked tasks stay unchecked. Record the blocker and continue only
  dependency-safe work explicitly allowed to run early.
- Preserve unknown dirty work. Never reset, pull, overwrite, merge `main`, move
  a published tag, or force-push autonomously.
- At task/context/blocker boundaries, immediately update evidence, notes, run
  log, validation state, and the exact next action.
- Milestone authorization persists across task and phase boundaries. While
  `INDEX.md` says `continuation_mode: autonomous`, ordinary status/review
  questions are checkpoints: answer in commentary and continue. A final response
  is reserved for milestone completion, an explicit user pause, or every safe
  lane being recorded as blocked.

## Validate And Close

Run validation proportional to the task and the owning skill. At minimum:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/check_work_state.ps1 -Mode Audit
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_core_tests.ps1
```

UI, Android, visual, replay, simulation, bot, and AI changes also run their
phase-specific matrices and safety gates. A checkbox becomes `[x]` only after
implementation, required validation, evidence, and affected docs are complete.

Before phase hygiene/tagging, obtain a fresh source-first independent review of
all checked work against definitions, authorities, implementation, negative
cases, and test coverage. Record its reviewer/ref/scope/findings/resolutions.
Linters, green CI, and passing suites are evidence for that review, not a
replacement. Reopen and remediate any task that was over-credited.

Use one task ID per task commit. After every phase, complete the full hygiene
checklist and publish only the permitted immutable tag/checkpoint sequence. If
continuation remains autonomous, activate and begin the next approved phase
without waiting for another prompt.
