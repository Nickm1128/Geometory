# Simulation And Training Loop Design

## Purpose

The simulation layer enables fast bot matches, replay analysis, balance testing,
and Milestone 1's guarded bot-profile improvement without launching the full
rendered game. AI-authored gameplay rules or source are forbidden.

## Headless Simulation Requirements

- Run without map rendering, UI, input, audio, or animation.
- Load rules, map, and bot profiles from data files.
- Advance state only through commands and deterministic rules.
- Emit compact replay notation and aggregate metrics.
- Support seeded batches for reproducible comparisons.
- Use the exact production core and capability-limited bot interface.
- Write deterministic JSON metrics, compact replays, manifests, state/version
  hashes, timing, and explicit errors.
- Support fixed development and hidden-holdout seed sets with paired,
  side-swapped matches.

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

## Guarded Milestone 1 AI-Assisted Bot Loop

The external Python 3.11 CLI owns `propose`, `evaluate`, `promote`, and `cycle`.
The Android client never contains credentials or model code. The default is the
fixed `openai/gpt-5-mini` model through non-streaming OpenRouter Chat
Completions with strict structured
output with `provider.require_parameters=true` and
`provider.data_collection="deny"`, temperature 0.2, seed 12345, and 2,500
maximum output tokens; a user may
explicitly override the model through `OPENROUTER_MODEL`, never `auto`/`latest`.

One cycle makes exactly one paid proposal request. A retry is a new cycle and an
ambiguous timeout is never automatically retried. Integer-microdollar accounting
reserves conservative maximum cost before a call and reconciles returned usage
and generation statistics. Hard limits are $1.00/cycle and $10.00 total M1, with
a coordinator lock, a current-pricing lookup before conservative reservation,
and `OPENROUTER_API_KEY` referencing a dedicated server-capped key no greater
than $10.

The request may contain only sanitized profile values, schemas, and generated
development metrics. Never send source or source-bearing prompts, secrets,
device/personal data, or holdout seeds/results. A proposal may change only
allowlisted scalar or registered-toggle profile leaves against an exact champion
hash; it cannot alter source, rules, maps, prompts, scripts, trackers, or shell
commands.

Cycle flow:

1. Reserve the paid budget and obtain one strict-schema proposal.
2. Validate provider controls, privacy, exact base hash, allowlist, types, ranges,
   and normalized candidate bytes.
3. Run tactical/deterministic gates and 200 paired development seeds.
4. For a surviving candidate, run 500 separate paired hidden-holdout seeds.
5. Produce a deterministic evaluation report; reject without touching the
   champion, or have the coordinator-owned workflow automatically promote a
   fully passing candidate transactionally.
6. Synchronize runtime data, rerun full validation, and create the auditable task
   commit only after a passing promotion.

## Acceptance Gate For Bot Changes

A bot profile or heuristic change should report:

- match count and seed range
- baseline win rates and candidate win rates
- average turn count
- invalid command delta
- behavioral diversity notes
- regressions or degenerate strategies observed

Promotion also requires zero invalid/fog violations, at most 1% max-turn
matches, no more than five percentage points of side bias, median duration within
±20% of the champion, at least 55% candidate score in both suites, and a paired
bootstrap 95% lower bound above 50% in both. Exact P03 baseline-opponent gates
remain separately required.

## Artifact Policy

Raw/redacted transport data, replays, and bulk generated output stay ignored
under `artifacts/`, `reports/generated/`, or `replays/generated/`. Version only
normalized proposals, candidates, evaluation reports, generation IDs/hashes,
the integer cost ledger, and curated findings required for auditability. Missing
or uncapped credentials block only the live-call lane; mock evaluation and
preapproved P05 work can continue.
