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

## 2026-07-19 — M1-P00-T03

- Status: Complete.
- Decision: `codex/skills/` is canonical and the five names in `manifest.json` are the complete managed set; user-level packages are generated mirrors, and differing managed copies are backed up without touching unmanaged skills.
- Validation: all five packages passed skill-creator validation and mirror inventory checks. Fresh agents correctly resumed the open task, routed a command-contract diagnostic to P01 without editing early, refused premature bot evaluation/paid work, and passed the patched P00/P05 visual capability boundary.
- Remediation: forward tests made the phase-publication sequence explicit, corrected the Android validation-document route, required dependency-aware bot refusal, and stopped the visual skill from implying that future P05 matrix/golden tooling already exists.
- Cross-phase impact: fresh agents can rebuild bounded context from repository state; P03/P04 and P05 workflows must continue to refuse nonexistent or dependency-blocked commands instead of inventing them.
- Exact next action: certify the installed Godot 4.6.3/API-36 toolchain and package evidence under `M1-P00-T04`.

## 2026-07-19 — M1-P00-T04

- Status: Complete.
- Decision: M1 local and CI validation is pinned to official Godot 4.6.3, verified downloads, matching templates, Android API 36/build tools 36.0.0, command-line tools 20.0, and Android Studio JBR 21; Godot 4.5.1 is rollback-only.
- Security remediation: pinned engine lookup now verifies only the managed console executable and its SHA-256. It does not execute broad candidates from Downloads or Desktop; core and export helpers independently reject a non-4.6.3 executable.
- Validation: work-state audit, script/JSON/YAML parsing, canonical/runtime data parity, core tests, and UI smoke tests at 360x800, 393x852, and 480x960 passed. The inspected normal APK is min SDK 24, target/compile SDK 36, arm64-v8a plus x86_64, requests only `VIBRATE`, and packages neither tests nor visual-QA resources.
- Warning disposition: Android `aapt2` reports the stock-template `themed_icon.xml` reference as missing. The ordinary/adaptive icon resources remain packaged and the warning is nonblocking for the debug foundation; final icon/manifest inspection remains required in P05/P06.
- Cross-phase impact: T06 owns the separate QA preset and feature route; P05/P06 must revisit launcher-icon polish and preserve the normal-package resource/permission boundary.
- Exact next action: verify and document the non-identifying Galaxy S24 profile and dedicated API-36 AVD under `M1-P00-T05`.

## 2026-07-19 — M1-P00-T05

- Status: Complete.
- Decision: tracked device evidence uses the stable alias `primary_galaxy_s24` and reusable layout/performance facts only. ADB serials and other unique identifiers are forbidden from tracked evidence.
- Physical profile: Android 16/API 36, 1080x2340, hardware/active density 480/420 dpi, font scale 1.0, 103 px top cutout-safe inset, 126 px visible navigation inset, three-button navigation, physical/app-content corner radii 108/95 px, and refresh modes through 120 Hz.
- Emulator validation: `Geometory_Galaxy_S24_API36` passed static verification and a live boot. Runtime inspection returned Android 16/API 36, x86_64, 1080x2340 at 420 dpi, font 1.0, and navigation mode 0; the owned configuration specifies Google Play, four cores, 4096 MB RAM, portrait, and no device frame.
- Fidelity boundary: emulator cutout, corners, haptics, and 60-Hz behavior are not substitutes for physical S24 certification.
- Cross-phase impact: P05 visual structure and P06 performance/lifecycle work must use the physical profile as authority while treating emulator-specific pixels as noncanonical.
- Exact next action: certify the deterministic 26-scenario contract foundation, separate QA package, and direct emulator/phone launch path under `M1-P00-T06`.

## 2026-07-19 — M1-P00-T06

- Status: Complete as a fixture/package contract foundation; visual certification remains explicitly pending P05.
- Architecture: the 26-ID catalog, strict request/ready schemas, QA wrapper scene, direct capture runner, and separate `com.milin.geometory.qa` package are versioned. Sixteen states reachable through current presentation APIs are implemented; combat/result/replay states remain reserved until their owning phases exist.
- Determinism remediation: production UI commands currently use millisecond client sequences. The QA hash now retains semantic accepted-command content while normalizing only that volatile transport field; five isolated runs of each representative match fixture produced one hash, and regression tests prove semantic path changes still alter the hash. P01 remains responsible for the production canonical state hash.
- Robustness remediation: fixture requests must actually apply their requested seed/scale; malformed or missing requests emit schema-valid failure markers; capture stops before screenshots on readiness failure; ADB target reconnect is retried by selected target; explicit output directories must be new/empty; and remote screenshot cleanup runs on failure.
- Package boundary: normal export has no `visual_qa` feature and contains zero QA scenes/scripts/schemas/tests. Its exported project metadata retains the inert feature-override selector, but the referenced scene is absent and cannot be loaded. The QA export alone enables the feature and packages the fixture.
- Device evidence: the current emulator export/install/ready/capture path passes overlay, unrelated-window, app-fatal-log, schema, echo, and assertion checks. Earlier alias-only physical evidence proves QA launch/readiness; its capture was rejected because an unrelated visible window was present, with no screenshot/log retained and no unrelated application altered.
- Visual finding for P05: the 1080x2340 allocation fixture at UI scale 1.15 shows severe horizontal compression in allocation controls, including vertically wrapped button text and unusable narrow controls. This is accepted evidence that the harness works, not a visual pass.
- Cross-phase impact: P05 must implement the remaining 10 fixtures, safe-area injection, semantic screen assertions, layout repair, canonical goldens, matrices, and visual certification. P06 must re-inspect both final package boundaries and manifests.
- Exact next action: reconcile all P00 authorities, archive the starter note, run phase hygiene/gates, publish immutable `m1-p00`, and activate P01 under `M1-P00-T07`.

## 2026-07-19 — M1-P00-T07 (closeout in progress)

- Status: In progress; authority reconciliation and local validation are complete, while public CI and current-build physical-device evidence remain open.
- Authority reconciliation: README, vision, assumptions, roadmap, rules, command contract, technical design, UI, bot, simulation, tooling, engineering/Android/visual workflows, and supporting directory READMEs now agree on expanded M1 and deferred networking. The unchanged starter note is archived as an exact Git rename under `docs/archive/` and explicitly nonauthoritative.
- Tracker remediation: fixed a PowerShell variable-name collision that made `PhaseClose -PhaseId M1-P00` inspect P06; `tools/test_check_work_state.ps1` now proves requested-phase diagnostics and returns exit zero on success, including in CI.
- Validation: pinned core, 360x800/393x852/480x960 UI smoke, visual-contract, tracker audit, skill synchronization, JSON/data parity, link, secret, large-file, and diff checks passed. Fresh normal/QA exports are min24/target36/compile36, arm64+x86_64, only `VIBRATE`, with isolated asset inventories; the normal APK hash is `36ee04e669f48eebf68041382e3827160232599bfe8dc3df542c5539c1b738ff`.
- Device evidence: current QA APK `2898bae83a6b6e0d4157d6001452a98137bae46cded779745d1a73972f0c974f` passed the emulator request/ready/capture contract at `artifacts/visual_qa/20260719_125340/allocation_staged`. `B-001` records that neither Windows nor ADB currently detects the physical phone, so final phone readiness remains unchecked without weakening the gate.
- Accepted later-phase debt: P01 owns core modularity/contracts; P05 owns allocation compression, presentation extraction, remaining fixtures, safe-area injection, macro-region styling, and visual goldens; P05/P06 own the stock-template themed-icon warning; P06 owns lifecycle, performance, final package, and subjective playtest certification.
- Exact next action: commit and push this reconciled T07 checkpoint to obtain public-CI evidence, then resolve `B-001`; do not tag P00 or activate P01 until both are green.
