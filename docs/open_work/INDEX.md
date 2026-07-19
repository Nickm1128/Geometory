---
schema_version: 2
milestone: "M1"
workflow_state: "active"
continuation_mode: "autonomous"
active_phase: "M1-P01"
current_task: "M1-P01-T04"
run_id: "M1-RUN-20260719-001"
exact_next_action: "Add failing contract tests for gameplay-only canonical hashing and documented RNG stream derivation, then repair M1-P01-T04 before proceeding to the other reopened P01 tasks."
last_completed_phase_tag: "m1-p00"
last_checkpoint_ref: "milestone/m1-vertical-slice"
last_green_validation: "Workflow checkpoint 48fbb83 passed GitHub Actions run 29702830233, including work-state regressions, data parity, pinned Godot 4.6.3 core, three-size UI smoke, and visual-contract tests; substantive review keeps T04-T06 reopened."
---

# Milestone 1 Work Index

## Live State

- Branch: `milestone/m1-vertical-slice`
- Protected baseline: `m1-baseline` at `4b7dc89`
- Earliest incomplete phase: `M1-P01`
- Active coordinator task: `M1-P01-T04`
- Continuation mode: `autonomous`
- Open blockers: none

## Phase Status

| Phase | State | Purpose | Phase tag |
|---|---|---|---|
| `M1-P00` | Complete | Workflow, trustworthy baseline, and tooling | `m1-p00` |
| `M1-P01` | Active | Deterministic core correctness and modular contracts | Pending |
| `M1-P02` | Planned | Replay, simulation, resume, and evidence | Pending |
| `M1-P03` | Planned | Competent fair baseline bot | Pending |
| `M1-P04` | Planned | Guarded AI-assisted bot workbench | Pending |
| `M1-P05` | Planned | Mobile aesthetics and UX vertical slice | Pending |
| `M1-P06` | Planned | Integrated certification and milestone closeout | Pending |

Allowed phase states are `Planned`, `Ready`, `Active`, `Gate Review`, `Hygiene`, `Complete`, and `Deferred`. At most one phase may be `Active`, `Gate Review`, or `Hygiene`.

## Resume Handoff

- Current task: `M1-P01-T04`
- Continuation mode: `autonomous`
- Exact handoff: P00 remains complete at immutable tag `m1-p00`. P01 has green
  supporting test evidence, but a fresh source-level review found that three
  checked tasks did not satisfy their definitions of done. Start by writing
  red tests for gameplay-only canonical hashing and the documented RNG stream
  contract, then repair the implementation and continue the reopened work in
  dependency order. There is no open blocker; work may proceed immediately.
