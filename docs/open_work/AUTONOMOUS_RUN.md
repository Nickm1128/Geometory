# Autonomous Milestone Run

Use this prompt to resume substantial work without relying on prior conversation
context:

> Continue Geometory Milestone 1 autonomously from repository state. Follow
> `AGENTS.md` and the Geometory open-work workflow, resume the structured current
> task in `docs/open_work/INDEX.md`, and treat the repository as authoritative.
> Complete dependency-safe work in order; update checkboxes and evidence
> immediately; record blockers and continue eligible parallel work; run every
> required validation, independent phase review, and hygiene gate; and create
> only permitted Git checkpoints. Task, commit, hygiene, tag, phase, context, and
> status-summary boundaries are nonterminal while `continuation_mode` is
> `autonomous`: report ordinary progress in commentary and continue. Send a final
> response only when Milestone 1 is complete, the user explicitly requests a
> report-required pause, or every dependency-safe lane is recorded as blocked on
> user input or an external state change.

Before using the prompt, ensure the working tree contains no unexplained edits
and the intended coordinator is the only agent authorized to update trackers or
publish Git state.

## Fresh GPT-5.6 Terra / Think High Thread

Create a new thread, select **GPT-5.6 Terra**, and set **Think: High** before
sending the following prompt. Model and reasoning selection are UI settings;
the prompt cannot change them.

> Continue Geometory Milestone 1 autonomously in
> `C:\Users\milin\Documents\Geometory`. This is explicit authorization to work
> through every remaining approved M1 task and phase, including implementation,
> validation, hygiene, task commits, permitted pushes, and immutable phase tags,
> without asking me to reauthorize ordinary task or phase transitions. Do not
> merely plan or review the work: begin executing the repository's exact current
> task now.
>
> Rebuild context only from repository state. Read `AGENTS.md`; check canonical
> skill synchronization; use the Geometory project-context, open-work,
> validation, visual-QA, and bot-training skills when their scopes apply; read
> `docs/open_work/INDEX.md`, `MILESTONE_1_PLAN.md`, and the active phase's four
> files; run `tools/check_work_state.ps1 -Mode Resume`; fetch without pulling;
> inspect branch, log, status, divergence, and task-relevant authority/code. The
> repository overrides any stale detail in this prompt. At this handoff, the
> expected branch is `milestone/m1-vertical-slice`, `m1-p00` is immutable and
> complete, P01 is active, `continuation_mode` is `autonomous`, and the expected
> current task is reopened `M1-P01-T04`; if audited repository state differs,
> follow the audited state and record the discrepancy.
>
> Correct the known premature-closeout findings before P01 can close. Start with
> focused failing tests for gameplay-only canonical hashing, documented RNG
> stream derivation/ownership, and schedule-version coverage. Then resolve the
> recursively unsafe visible-event projection, complete real responsibility
> extraction from the oversized `GameCore` facade instead of helper-only
> forwarding, remove duplicate/dead paths, and add the missing wall
> damage/destruction, casualty arithmetic, malformed/non-serializable command,
> event-privacy, and deterministic-combat coverage. Reconcile task evidence as
> the implementation changes; never preserve a checked task that fails its
> definition of done.
>
> Work one dependency-safe task through implementation, focused validation,
> affected authority/document updates, immediate tracker evidence, and its
> atomic single-task-ID commit before switching. Use fresh bounded subagents for
> independent source review or genuinely disjoint work when useful, while the
> coordinating agent alone edits trackers, integrates results, commits, tags,
> pushes, promotes bot profiles, or initiates paid calls. Record blockers
> immediately, leave affected tasks unchecked, and continue all eligible lanes.
> Make reversible authority-backed decisions without asking routine questions;
> promote durable product decisions to `docs/ASSUMPTIONS.md`.
>
> Green lint, CI, and tests are supporting evidence, not phase certification.
> Before every phase hygiene pass and tag, commission a fresh source-first review
> of every checked task, applicable requirement, exit gate, implementation, and
> test claim. Resolve every finding or reopen the owning task. Inspect actual CI
> logs before remediation and never weaken a gate to obtain green status. After
> a passing hygiene gate and permitted publication, activate and start the next
> phase immediately while continuation remains autonomous.
>
> Treat task completions, commits, pushes, CI results, hygiene passes, tags,
> phase summaries, context checkpoints, and my ordinary status/review questions
> as nonterminal. Put those updates in commentary and keep working. A status or
> review question adds to this run unless I explicitly say `pause`, `stop`,
> `wait`, replace the scope, or `report back before continuing`. Before sending
> any final response, rerun Resume and inspect `continuation_mode`. If it is
> `autonomous` and any dependency-safe action remains, a final response is
> premature: perform that action instead. A final response is allowed only when
> M1 is complete and remotely verified, I explicitly requested a report-required
> pause, or every dependency-safe lane has a recorded blocker requiring my input
> or external state change.
>
> Preserve all scope and safety boundaries. Keep P2P, lobbies, accounts,
> servers, additional maps/players/units, runtime LLMs, and every documented
> deferral out of M1. Never pull through divergence, discard unknown work,
> force-push, move a tag, merge to `main`, expose a device identifier or secret,
> or place an API key/model runtime in the APK. P04 paid calls remain limited by
> the dedicated capped credential, privacy rules, one-request-per-cycle rule,
> coordinator lock, and recorded microdollar budgets; missing or uncapped
> credentials and ambiguous spend block only that lane. Do not substitute mocked
> evidence for a live gate or emulator evidence for a required physical-device
> gate. Continue until one of the valid terminal conditions is genuinely true.
