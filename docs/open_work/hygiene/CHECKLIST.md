# Phase Hygiene Checklist

Copy this checklist into `LOG.md` for each phase. Every item requires evidence. A failure creates a remediation task in the same phase; the next phase remains inactive.

- `HYG-01` Tracker integrity: phase state, current task, task/gate checkboxes, dependencies, blockers, and exact next action agree.
- `HYG-02` Authority sync: vision, assumptions, rules, technical design, UI, bot, simulation, roadmap, README, and tooling docs reflect durable changes.
- `HYG-03` Repository organization: ownership boundaries, naming, module size, links, dead/duplicate files, and root placement are reviewed.
- `HYG-04` Data integrity: root and Godot runtime data are byte-identical; schema/config changes are documented.
- `HYG-05` Validation: required targeted and full suites pass with exact commands, versions, results, and artifact references.
- `HYG-06` Visual/device evidence: required fixtures, layouts, emulator, and physical-device checks pass when the phase touches those surfaces; otherwise record N/A with reason.
- `HYG-07` Artifact and secret safety: generated output is ignored, no secret or personal device identifier is tracked, and no unexpected large file is staged.
- `HYG-08` Git integrity: changes are intentional, task commits contain stable IDs, remote refs are understood, and no unrelated user work is altered.
- `HYG-09` Skill integrity: canonical skills validate, the user-level mirror is synchronized, and forward tests required by the phase pass.
- `HYG-10` Handoff quality: notes contain decisions and cross-phase effects; `INDEX.md` names one exact executable next action.

Required result: all ten items pass, or are explicitly N/A where permitted, before the phase tag is published.
