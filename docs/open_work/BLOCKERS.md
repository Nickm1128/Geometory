# Milestone 1 Blockers

Record a blocker as soon as it prevents an affected task. Keep blocked tasks unchecked and continue dependency-safe work.

## Open Blockers

### B-001 — Physical S24 is not visible to Windows or ADB

- Status: Open
- Owner: Environment
- Opened: 2026-07-19
- Resolved: Pending
- Affected IDs: `M1-P00-T07`, `M1-P00-G05`, `HYG-06`
- Exact question or failure: After the final P00 QA rebuild, Windows reported zero present Android/Samsung USB devices and ADB reported one ready emulator but zero physical targets, so the current QA hash cannot yet receive an alias-only phone launch/ready handshake.
- Safe fallback: Keep P00 active, accept no emulator substitution for phone evidence, and complete the documentation, local validation, Git checkpoint, and public-CI lanes while waiting for the phone to reconnect.
- Fallback authority: `docs/device_validation_profile.md`, `docs/workflows/android_validation.md`, and `M1-P00-G05`.
- Eligible parallel work: Non-device portions of `M1-P00-T07`, including the closeout commit, branch push, and GitHub Actions validation; no phase tag or P01 activation.
- Evidence: 2026-07-19 sanitized probe returned `WINDOWS_ANDROID_USB_PRESENT=0` and `ADB_EMULATOR_DEVICE=1`; no device identifier was emitted or stored.
- Resolution: Pending.

## Resolved Blockers

None.

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
