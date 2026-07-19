# Visual QA Workflow

The deterministic fixture harness renders named states without manually traversing a match. It is compiled only into the `Android Visual QA` preset under package `com.milin.geometory.qa`; the normal preset excludes `res://visual_qa` resources and has no network permissions.

## Setup

Use the pinned toolchain from `tools/toolchain.json`. Create or verify the dedicated emulator with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/ensure_geometory_avd.ps1 -Mode Ensure -Launch
```

Install the capture runner's single pinned Python dependency once:

```powershell
python -m pip install --requirement tools/requirements-visual-qa.txt
```

The runner performs an exact-version preflight and stops with this command if the dependency is absent or drifts.

The emulator matches the primary device's 1080x2340 viewport and active 420 dpi density. Its generic cutout, rounded corners, haptics, and Samsung-specific system UI are not authoritative; the physical device remains the final certification target.

## Capture

Capture an implemented catalog scenario on the dedicated emulator:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/capture_visual_qa.ps1 -Scenario movement_pending_path
```

Pass `-Serial` to select a physical device when more than one ADB target is connected. The serial is used only at runtime and is never written to the artifact manifest or tracked device profile.

The runner exports and installs the QA APK, places a strict request in the app sandbox, launches the requested fixture, verifies the nonce-bearing ready marker, rejects Android's immersive-mode education overlay, unexpected focus, and unrelated visible windows such as picture-in-picture video, checks the app process for script errors/fatal exceptions/fatal signals plus package-specific ANRs, and captures a screenshot plus package-scoped logcat. Outputs live below ignored `artifacts/visual_qa/<timestamp>/<scenario>/` directories. It temporarily confirms the immersive-mode education prompt for capture and restores the target's prior setting afterward. It never force-stops unrelated user applications to manufacture a clean capture; dismiss such overlays on the target and rerun. Rejected overlay details are not written to artifacts.

The ready-marker timeout defaults to 90 seconds because a cold x86_64 emulator may spend nearly a minute initializing OpenGL and shader caches. The runner polls throughout and writes package-scoped diagnostics on timeout.

Explicit output directories must be new or empty so a failed retry cannot be
mistaken for earlier evidence. The runner waits for the selected target—not
merely any ADB target—to reconnect after export and removes its remote temporary
screenshot in cleanup paths.

## Contract

Requests contain schema version, nonce, scenario ID, seed, UI scale, safe-area profile, and APK build hash. Ready markers echo those fields and add viewport, live safe area, deterministic state hash, assertions, and errors. A screenshot is a valid **contract capture** only after its matching ready marker succeeds. P00 contract success is not visual certification; manifests explicitly keep `visual_certified` false until the P05 layout and aesthetic review.

Until P01 supplies the production canonical hash, match-backed fixtures hash a
sorted deep snapshot whose accepted-command history retains semantic fields but
normalizes the presentation-generated `client_sequence`. This prevents wall
clock values from changing an otherwise identical fixture while preserving
command type, phase, player, allocation, stack, path, and mode differences.

Every implemented fixture must honor the requested seed and UI scale; readiness
assertions fail before screenshot capture if either value drifts. Use
`-UiScale 1.30` when requesting the `settings_large_scale` fixture rather than
relying on hidden scenario-specific overrides.

Missing or malformed requests also produce a schema-valid failure marker with
sanitized placeholder echo fields and explicit errors. A capture runner must
still reject that marker because its nonce/build/scenario cannot match the
original request.

In P00, `safe_area_profile` is provenance carried through the handshake while `safe_area` always records the target's live measurement. Injectable profile behavior is intentionally deferred to P05. Selecting `galaxy_s24_primary` does not yet alter layout or simulate insets.

P00 implements the 16 states reachable through current presentation APIs and reserves all 26 Milestone 1 identifiers. Hard midgame, combat, result, and replay fixtures remain intentionally unimplemented until their underlying phase features exist.

The production APK contains the inert exported-project setting that selects the
QA main scene only when the build-time `visual_qa` feature exists. Normal export
has no such feature and packages zero QA scenes, scripts, schemas, or tests, so
there is no active or loadable QA route in `com.milin.geometory`.
