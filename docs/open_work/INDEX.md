---
schema_version: 2
milestone: "M1"
workflow_state: "active"
continuation_mode: "autonomous"
active_phase: "M1-P01"
current_task: "M1-P01-T06"
run_id: "M1-RUN-20260719-001"
exact_next_action: "Audit GameCore responsibility ownership, add focused extraction tests, and move real command, movement, combat, fog, hashing/RNG, and turn-resolution behavior out of the facade for M1-P01-T06."
last_completed_phase_tag: "m1-p00"
last_checkpoint_ref: "milestone/m1-vertical-slice"
last_green_validation: "Workflow checkpoint 48fbb83 passed GitHub Actions run 29702830233, including work-state regressions, data parity, pinned Godot 4.6.3 core, three-size UI smoke, and visual-contract tests; substantive review keeps T04-T06 reopened."
---

# Milestone 1 Work Index

## Live State

- Branch: `milestone/m1-vertical-slice`
- Protected baseline: `m1-baseline` at `4b7dc89`
- Earliest incomplete phase: `M1-P01`
- Active coordinator task: `M1-P01-T06`
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

- Current task: `M1-P01-T06`
- Continuation mode: `autonomous`
- Exact handoff: P00 remains complete at immutable tag `m1-p00`. Reopened T04
  and T05 are repaired with focused pinned-core evidence. Continue with T06:
  transfer substantive command, movement, combat, fog, hashing/RNG, and turn
  ownership out of `GameCore`, then remove duplicate/dead paths. There is no
  open blocker; work may proceed immediately.
