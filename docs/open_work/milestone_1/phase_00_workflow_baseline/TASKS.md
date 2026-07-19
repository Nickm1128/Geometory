# M1-P00 Tasks — Workflow, Baseline, And Tooling

- [x] `M1-P00-T01` Protect the audited prototype baseline in Git.
  - Dependencies: None
  - Can run early: No
  - Definition of done: audit untracked project files for secrets, generated output, and large binaries; commit the intended prototype to `main`; push `origin/main`; create immutable annotated tag `m1-baseline`; create and switch to `milestone/m1-vertical-slice`.
  - Evidence: Commit `4b7dc89` is shared by `main`, `origin/main`, and annotated tag `m1-baseline`; branch `milestone/m1-vertical-slice` is active.

- [x] `M1-P00-T02` Install the documentation operating system and read-only work-state linter.
  - Dependencies: M1-P00-T01
  - Can run early: No
  - Definition of done: create `AGENTS.md`, the documentation authority map, M1 index/plan/blocker/run/hygiene files, all seven four-file phase sets, and `tools/check_work_state.ps1`; prove `Resume` and `Audit` modes report state without modifying tracked files.
  - Evidence: `AGENTS.md`, `docs/README.md`, the complete `docs/open_work/` tree, and `tools/check_work_state.ps1`; both `-Mode Resume` and `-Mode Audit` passed on 2026-07-19 after parsing 50 tasks and 50 gates with zero warnings.

- [x] `M1-P00-T03` Create, validate, synchronize, and forward-test all five canonical Geometory skills.
  - Dependencies: M1-P00-T02
  - Can run early: No
  - Definition of done: version the two migrated and three new skill packages under `codex/skills`; generate compliant `agents/openai.yaml`; add the managed manifest and safe `Check|Apply` sync tool; run skill-creator validation; synchronize user-level mirrors; forward-test each skill in fresh context and record results.
  - Evidence: Five canonical packages and `codex/skills/manifest.json`; skill-creator `quick_validate.py` passed for all five; `tools/sync_codex_skills.ps1 -Mode Apply|Check` produced exact SHA-256 inventory parity while backing up only differing managed packages; fresh contexts passed project/validation routing, open-work resume, bot safety refusal, and remediated visual-QA capability-boundary tests on 2026-07-19.

- [x] `M1-P00-T04` Upgrade and certify the local/CI Godot and Android toolchain.
  - Dependencies: M1-P00-T01
  - Can run early: Yes
  - Definition of done: install Godot 4.6.3 and matching export templates while retaining 4.5.1 rollback; configure SDK 36/Java; add pinned lightweight GitHub Actions checks for tracker/docs, data parity, core, and UI smoke suites; update tooling/workflow authority; export and inspect an API-36 APK with min SDK 24 and no unnecessary normal-app network permission.
  - Evidence: Official Godot `4.6.3.stable.official.7d41c59c4`, its managed executable/archive/template hashes, Android SDK/build tools 36, command-line tools 20.0, ADB 36.0.0, and Android Studio JBR 21 are recorded in `tools/toolchain.json`; pinned lookup, PowerShell/JSON/YAML parsing, data parity, core tests, and the 360x800/393x852/480x960 UI matrix passed on 2026-07-19. `.github/workflows/validate.yml` uses the official verified Linux archive. Exported normal APK SHA-256 `a9b6808d7e29644b49d6cdfd9c646a6fd9fc976fea47845c2b75ef2ce9cc61e8` reports min SDK 24, target/compile SDK 36, arm64-v8a plus x86_64, only `VIBRATE`, and no tests or visual-QA resources.

- [x] `M1-P00-T05` Record and reproduce the Galaxy S24 validation profile.
  - Dependencies: M1-P00-T01
  - Can run early: Yes
  - Definition of done: document the non-identifying Android 16/API 36, 1080x2340, density 420, font scale 1.0, top/bottom insets, navigation mode, refresh capability, and rounded-corner evidence; create `Geometory_Galaxy_S24_API36` with API 36 Google Play x86_64, 1080x2340, density 420, 4 cores, 4096 MB RAM, portrait/no-frame capture, and three-button navigation; boot and verify it without altering other project AVDs.
  - Evidence: `docs/device_validation_profile.md` and alias-only profile SHA-256 `fda1cadcee962c096b3a2f1e6175d0aefb68f9627256f8e76983f5766166ceca` record Android 16/API 36, 1080x2340, active density 420, font scale 1.0, top 103 px/bottom 126 px insets, three-button navigation, rounded-corner provenance, and refresh modes without a device serial. `tools/ensure_geometory_avd.ps1 -Mode Verify -Launch` booted `Geometory_Galaxy_S24_API36`; runtime checks returned boot complete, Android 16/API 36, Google Play x86_64, 1080x2340 at 420 dpi, font 1.0, navigation mode 0, with its static 4-core/4096-MB/no-frame/portrait configuration verified on 2026-07-19.

- [ ] `M1-P00-T06` Establish the deterministic visual-QA foundation and isolated QA Android package.
  - Dependencies: M1-P00-T04, M1-P00-T05
  - Can run early: No
  - Definition of done: add a versioned scenario catalog and deterministic request/ready contract; create separate `com.milin.geometory.qa` export with QA-only feature gates and no hooks in normal builds; provide direct launch/capture tooling and ignored artifact layout; launch the QA package on the emulator and phone.
  - Evidence: Pending.

- [ ] `M1-P00-T07` Reconcile P00 documentation and close phase hygiene.
  - Dependencies: M1-P00-T02, M1-P00-T03, M1-P00-T04, M1-P00-T05, M1-P00-T06
  - Can run early: No
  - Definition of done: correct stale README, roadmap, assumptions, tooling, workflow, version, and minimum-SDK statements; archive starter notes according to the approved repository policy; pass all P00 exit gates and hygiene items; commit the phase checkpoint, publish annotated tag `m1-p00`, push branch/tag, and activate P01 without merging `main`.
  - Evidence: Pending.
