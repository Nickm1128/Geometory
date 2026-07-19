---
name: geometory-bot-training-workflow
description: "Operate and validate Geometory deterministic bot simulations, tactical scenarios, champion/challenger evaluations, and the guarded OpenRouter proposal loop. Use for bot-profile changes, simulation batches, fairness checks, AI proposals, cost/privacy enforcement, candidate evaluation, or promotion decisions."
---

# Geometory Bot Training Workflow

## Prepare

1. Read the active phase files, `docs/bot_design.md`, `docs/simulation_training_loop.md`, and `docs/game_rules.md`.
2. Confirm root/runtime data parity and a clean deterministic core suite.
3. Use only the production core and fog-filtered bot interface; never duplicate rules in Python or presentation code.
4. Confirm the target phase, dependencies, and documented runner command are implemented. Before the P01 fog-safe interface and P02 runner exist, this skill is planning-only; stop rather than inventing a league, CLI, or fairness claim.

## Evaluate

- Run tactical scenarios before leagues.
- Use fixed paired seeds with sides swapped and keep development and holdout suites separate.
- Fail on invalid commands, hidden-state access, nondeterministic hashes, malformed artifacts, or turn-limit regressions.
- Record profiles/hashes, seed-suite hashes, engine/core versions, match counts, score, side bias, duration, confidence result, and errors.

## Use OpenRouter Safely

- Run mocked/offline paths before a paid proposal.
- Only the coordinator may initiate a paid call or promotion.
- Require the dedicated capped key, one request per cycle, local ledger reservation, strict JSON Schema, supported parameters, and data-collection denial.
- Send only sanitized profile values and generated metrics. Never send source, secrets, personal/device data, or holdout seeds/results.
- Candidate output may change only allowlisted bot-profile leaves against the exact champion hash. Never execute model-authored code, commands, or arbitrary patches.
- Treat an ambiguous timeout as spent and do not retry automatically.

## Promote

Promote only after every tactical, determinism, development, holdout, side-bias, duration, and budget gate passes. Update only the canonical active bot profile, sync runtime data, rerun full validation, record evidence, and create the permitted task commit. Rejected candidates must not alter champion state.

If credentials alone block the live P04 gate, record that blocker and continue only the P05 tasks explicitly marked eligible to run early. Keep P04 incomplete, preserve champion state, and never substitute a mocked cycle for the required live accept-or-reject evidence.
