# Bot Design

## Vocabulary

- Bot: in-game nonplayer opponent.
- AI: external LLM or analysis system used outside the game to improve bot rules.

## Design Goal

Bots should be competent under the same information limits as a human player. They should not inspect hidden tiles, enemy queues, exact hidden stack counts, or hidden wall HP.

## Bot Interface

A bot policy receives an observable state and emits serializable commands.

```text
BotPolicy.decide(observable_state, rules_config, bot_profile) -> CommandBatch
```

The command batch can include:

- allocation command
- movement queue commands
- end phase command

Friendly merging is automatic core resolution. Manual unstacking, split
commands, and multi-select are outside Milestone 1.

The rules engine validates bot commands the same way it validates human commands.

## Observable State

Observable state includes:

- visible tiles and known controllers
- own bank, research, pending soldiers, capital, and stacks
- visible enemy stacks with visible aggregate estimates
- visible wall segments and HP only if visible
- public rules and public match metadata
- visible replay/event history

Observable state excludes hidden enemy positions, hidden queues, hidden income, hidden exact research, and hidden wall damage.

## Milestone 1 Rule-Based Bot

The first bot should use a configurable heuristic profile from `data/bots/baseline_rule_bot.json`.

Policy stages:

1. Evaluate economy state: income, bank, controlled tile count, pending soldiers.
2. Evaluate visible threat: enemy distance to capital, enemy stacks near walls, contested frontier.
3. Allocate spend using weights for expansion, defense, military, research, and economy.
4. Move idle or queued stacks toward nearby neutral tiles, threatened walls, or visible enemy weak points.
5. Avoid suicidal attacks when estimated enemy strength is above configured threshold.

## Heuristic Inputs

Useful derived features:

- `income_per_turn`
- `visible_enemy_strength_near_capital`
- `neutral_tiles_reachable`
- `frontier_tile_count`
- `own_stack_strength_by_region`
- `wall_pressure_score`
- `capital_threat_distance`
- `known_enemy_capital_distance`

## Personality Parameters

Profile fields can adjust behavior without changing code:

- expansion bias
- defense bias
- attack bias
- research bias
- economy bias
- stack consolidation preference
- risk tolerance
- wall breaking priority
- minimum reserve cents

## Bot Fairness Rules

- Bots must use fog-filtered state only.
- Bots must submit normal commands.
- Bots must not modify state directly.
- Bots must not read compact replay logs beyond what a player could know during a match.
- Bot randomness must use seeded streams so simulations are reproducible.
- Attempted hidden-state access and invalid commands are hard evaluation
  failures, not merely metrics.
- The frozen prototype bot/profile remains immutable as the comparison opponent.

## Guarded External AI-Assisted Improvement

Milestone 1 includes an external Python champion/challenger workbench. It sends
only sanitized profile/schema values and generated development metrics and may
modify only allowlisted scalar or registered-toggle leaves in a candidate
profile based on the exact champion hash.

Model output cannot author or edit source, rules, maps, prompts, scripts,
trackers, or shell commands. It never receives secrets, source, device/personal
data, or holdout seeds/results. The Android app contains no model code or key.

Every candidate must pass schema, deterministic, tactical, fog, legality,
termination, side-bias, duration, development, and hidden-holdout gates before
the coordinating agent may promote it transactionally. Rejection and failure
leave champion bytes unchanged. Exact statistical thresholds and paid-call
controls are authoritative in the P03/P04 requirements and M1 plan.
