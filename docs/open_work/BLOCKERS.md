# Milestone 1 Blockers

Record a blocker as soon as it prevents an affected task. Keep blocked tasks unchecked and continue dependency-safe work.

## Open Blockers

None.

## Resolved Blockers

### B-001 — Physical S24 is not visible to Windows or ADB

- Status: Resolved
- Owner: Environment
- Opened: 2026-07-19
- Resolved: 2026-07-19
- Affected IDs: `M1-P00-T07`, `M1-P00-G05`, `HYG-06`
- Exact question or failure: After the final P00 QA rebuild, Windows reported zero present Android/Samsung USB devices and ADB reported one ready emulator but zero physical targets, so the current QA hash could not receive an alias-only phone launch/ready handshake.
- Safe fallback: P00 remained active; emulator evidence was not substituted for phone evidence while other T07 lanes continued.
- Fallback authority: `docs/device_validation_profile.md`, `docs/workflows/android_validation.md`, and `M1-P00-G05`.
- Eligible parallel work: Completed before resolution: T07 authority reconciliation, local validation, Git checkpoints, and GitHub Actions validation.
- Evidence: Physical artifact `artifacts/visual_qa/20260719_131542/movement_pending_path` records alias `primary_galaxy_s24`, QA APK SHA-256 `291f9a8f840dc01edd9770c8e27528ae2a8907cec166aed734258d5b499cdeb3`, matching nonce/build, 1080x2340 viewport, live safe area, and passed overlay/window/fatal-log checks without storing a serial.
- Resolution: The reconnected authorized phone accepted the current QA build and completed the deterministic request/ready/capture contract successfully.

## Entry Template

### B-NNN — Short description

- Status: Open
- Owner: User | Environment | Implementation | External
- Opened: YYYY-MM-DD
- Resolved: Pending
- Affected IDs: `M1-P00-T00`
- Exact question or failure: State the missing decision or reproducible failure.
- Safe fallback: State a reversible fallback, or `None`.
- Fallback authority: Link the document or approval that permits it, or `None`.
- Eligible parallel work: List dependency-safe task IDs, or `None`.
- Evidence: Command output, file, artifact, or pending user response.
- Resolution: Pending.
