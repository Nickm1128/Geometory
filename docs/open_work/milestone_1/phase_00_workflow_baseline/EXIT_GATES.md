# M1-P00 Exit Gates — Workflow, Baseline, And Tooling

- [x] `M1-P00-G01` The untouched prototype is tracked, remotely recoverable at `m1-baseline`, and separated from milestone changes.
  - Evidence: `main`, `origin/main`, and immutable annotated tag `m1-baseline` resolve to audited prototype commit `4b7dc89`; all workflow and milestone changes are isolated on `milestone/m1-vertical-slice`.
- [x] `M1-P00-G02` Core tests, UI smoke tests, root/Godot data parity, and an inspected API-36 debug APK pass under Godot 4.6.3.
  - Evidence: On 2026-07-19, pinned Godot `4.6.3.stable.official.7d41c59c4` passed the core suite, UI smoke at 360x800/393x852/480x960, and visual-contract suite; all three data copies matched. Normal APK `36ee04e669f48eebf68041382e3827160232599bfe8dc3df542c5539c1b738ff` is min SDK 24, target/compile SDK 36, arm64-v8a plus x86_64, and only `VIBRATE`.
- [x] `M1-P00-G03` Every M1 phase has exactly `REQUIREMENTS.md`, `TASKS.md`, `EXIT_GATES.md`, and `NOTES.md`, and the work-state audit passes.
  - Evidence: The 2026-07-19 read-only audit parsed 50 tasks and 50 gates with zero warnings; all seven phase directories contain exactly the four required files, and the PhaseClose routing regression passes.
- [x] `M1-P00-G04` All five canonical skills validate, match their user-level mirrors, and pass fresh-context forward tests.
  - Evidence: Five skill-creator validations, SHA-256 mirror synchronization, and fresh-context project, validation, open-work, visual, and bot workflow tests passed on 2026-07-19.
- [x] `M1-P00-G05` The dedicated AVD boots with verified properties; phone and emulator each launch the QA package.
  - Evidence: The verified API-36 AVD and emulator artifact `artifacts/visual_qa/20260719_125340/allocation_staged` pass. Physical artifact `artifacts/visual_qa/20260719_131542/movement_pending_path` proves the current QA build (`291f9a8f840dc01edd9770c8e27528ae2a8907cec166aed734258d5b499cdeb3`) installed and completed a matching nonce/build ready contract on alias `primary_galaxy_s24`, with 1080x2340 viewport, live safe area, no overlay/unrelated window, and no fatal log finding.
- [x] `M1-P00-G06` The normal Android build contains neither QA hooks nor unnecessary Internet/network-state permissions.
  - Evidence: APK Analyzer found zero visual-QA/test assets in normal APK `36ee04e669f48eebf68041382e3827160232599bfe8dc3df542c5539c1b738ff`; its only requested permission is `android.permission.VIBRATE`, while the separate QA package contains fixture resources and no tests.
- [x] `M1-P00-G07` P00 hygiene passes, immutable tag `m1-p00` exists, and the milestone branch/tag are current on the remote.
  - Evidence: P00 hygiene is recorded Pass; closeout commit `153efbc` passed GitHub Actions run `29698512789`; annotated tag object `ff2981f18156f958c44568a5aebc97e82188bc4f` resolves to that commit and is published as `origin` tag `m1-p00`; the transition is pushed without merging `main`.
