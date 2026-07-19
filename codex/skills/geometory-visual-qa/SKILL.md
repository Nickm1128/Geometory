---
name: geometory-visual-qa
description: "Run deterministic visual, layout, safe-area, touch, screenshot, emulator, and physical-device validation for Geometory. Use for UI changes, presentation refactors, visual fixtures, screenshot baselines, Android capture passes, Galaxy S24 certification, or any phase gate that changes what players see or touch."
---

# Geometory Visual QA

## Start

1. Read the active phase requirements/gates and `docs/workflows/visual_qa.md`.
2. Resolve the pinned engine with `tools/find_godot.ps1 -RequirePinned`; run `run_core_tests.gd`, `run_ui_smoke_tests.gd`, and `run_visual_qa_contract_tests.gd` headlessly before interpreting screenshots.
3. Use cataloged scenario IDs from `godot/visual_qa/scenarios.json`; do not navigate through unrelated gameplay to reach a state.

## Capability Boundary

- P00 provides the schema/handshake, QA-only package, matched AVD, and `tools/capture_visual_qa.ps1` for one named Android scenario at a time. Inspect its request, ready marker, manifest, screenshot, and log together.
- The P00 `safe_area_profile` value identifies the requested profile and records the live result; deterministic safe-area injection is P05 work until the workflow explicitly says it is implemented.
- Desktop matrices, contact sheets, structural geometry reports, approved goldens, diffs, and heatmaps are deliverables of `M1-P05-T06`. If their documented commands are absent, leave that work unchecked; never imply that a single Android capture supplied them.

## Validate

- For an ordinary UI task, capture affected scenarios plus `main_menu`, `allocation_default`, and `movement_pending_path`.
- For substantial layout/touch work, run the desktop matrix and the dedicated Galaxy S24 emulator.
- For safe-area work and phase exits, also run the physical S24; it is authoritative over the generic emulator.
- Inspect the complete contact sheet, structural report, relevant diff heatmaps, and logs. A successful command alone is insufficient.
- Before Android capture, verify the Python dependency declared by the visual-QA workflow and ensure no immersive education, picture-in-picture, or other overlay window can obscure the app.
- Treat cross-platform images as review evidence. Apply pixel thresholds only to matching engine, renderer, font, viewport, scale, and safe-area profiles.

## Baselines And Evidence

- Never approve a baseline implicitly. Require the explicit approval switch, task ID, reason, green structural checks, and a recorded contact-sheet review.
- Keep device/emulator captures and raw logs under ignored `artifacts/visual_qa`; track only approved canonical desktop baselines.
- Record manifest and artifact paths plus findings in the active phase notes/gate.
- Fail on script errors, crashes, ANRs, clipped critical text, unsafe controls, illegal overlap, or touch targets below the documented minimum.
- Keep contract success distinct from visual certification. If a foundation-phase capture launches and handshakes correctly but reveals a later-phase layout defect, record and route the defect to its owning task without calling the image visually approved or weakening a gate that already requires visual quality.
