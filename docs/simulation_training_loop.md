# Simulation And Training Loop Design

## Purpose

The simulation layer enables fast bot matches, replay analysis, balance testing, and later AI-assisted bot rule improvement without launching the full rendered game.

## Headless Simulation Requirements

- Run without map rendering, UI, input, audio, or animation.
- Load rules, map, and bot profiles from data files.
- Advance state only through commands and deterministic rules.
- Emit compact replay notation and aggregate metrics.
- Support seeded batches for reproducible comparisons.

## Simulation Batch Flow

```text
rules + map + bot profiles + seed range
  -> create match
  -> each bot receives observable state
  -> bots emit commands
  -> rules engine validates and applies commands
  -> replay events and metrics are collected
  -> final summary is written
```

## Metrics

Initial metrics:

- winner
- turn count
- elapsed simulated turns per second
- player eliminations by turn
- income curve by player
- controlled tile count by player
- research bps by player
- soldier count and effective strength by player
- wall damage and breaches
- combat outcomes
- idle stack turns
- invalid command count

## Compact Replay Notation

The initial notation is `GMTY1`. It is line-based for easy diffing and compact AI review.

Example:

```text
GMTY1 seed=18374 rules=default@hash map=alpha@hash players=P1:human,P2:bot/base
SCHED H=200,400,100 D=200,100,300
T1 P1 INC base=1200 bonus=0 bank=1200
T1 P1 ALLOC E=300 M=600 R=300
T1 P1 MOVE stack=s12 path=A3>B3>C3
T1 P1 EVT cap tile=B3 by=P1 wall=W17 hp=820
T1 P2 INC base=1100 bonus=0 bank=1100
T1 P2 ALLOC E=200 M=700 R=200
T1 P2 MOVE stack=s21 path=Q4>P4>O4
T2 P1 SPAWN soldiers=2 tile=CAP1 q=h10200,d10100
END winner=P1 turns=18 elim=P2@T18
```

Notation rules are tracked in `core/contracts/replay_notation.md`.

## AI-Assisted Bot Loop

Later workflow with OpenRouter or another external AI system:

1. Run a baseline simulation batch.
2. Export compact replays plus metric summaries.
3. Send summaries to the AI model, not full hidden state dumps unless analyzing postgame omniscient logs intentionally.
4. Ask for rule/profile changes with clear constraints.
5. Convert proposals to structured candidate patches.
6. Validate schema, determinism, and safety.
7. Run comparison batches against the baseline.
8. Keep changes only if they improve target metrics or useful behavioral diversity.

## Acceptance Gate For Bot Changes

A bot profile or heuristic change should report:

- match count and seed range
- baseline win rates and candidate win rates
- average turn count
- invalid command delta
- behavioral diversity notes
- regressions or degenerate strategies observed

## Artifact Policy

Generated replays, batch reports, and AI proposals should go under ignored folders such as `artifacts/`, `reports/generated/`, or `replays/generated/`. Curated findings can be promoted into docs.
