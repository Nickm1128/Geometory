# M1-P00 Notes — Workflow, Baseline, And Tooling

Append dated findings and decisions. Link durable product changes to the relevant authority document.

## 2026-07-19 — M1-P00-T01

- Status: Complete.
- Finding: the initial Git history tracked only `README.md`; the intended prototype source was present as untracked files.
- Decision: preserve the exact prototype as a standalone baseline before milestone edits.
- Evidence: commit `4b7dc89`, `origin/main`, and annotated tag `m1-baseline`; milestone branch `milestone/m1-vertical-slice`.
- Cross-phase impact: all later comparisons and rollback use `m1-baseline`; `main` is not merged without user authority.

## 2026-07-19 — M1-P00-T02

- Status: Complete.
- Finding: no repository-level agent contract, open-work tracker, phase evidence sets, blocker register, hygiene record, or state linter existed.
- Decision: repository documents are canonical; conversation state is disposable and must be rebuilt through `AGENTS.md` plus `INDEX.md`.
- Validation: `tools/check_work_state.ps1 -Mode Resume` and `-Mode Audit` both passed with 50 parsed tasks, 50 parsed gates, zero blockers, and zero warnings.
- Cross-phase impact: all later work must use stable IDs, immediate checkbox/evidence updates, and phase hygiene.
- Exact next action: validate, synchronize, and fresh-context forward-test the five canonical skills under `M1-P00-T03`.
