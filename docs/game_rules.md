# Authoritative Game Rules

This document is the source of truth for Milestone 1 gameplay behavior. Constants live in `data/rules/default_rules.json` and must be read from configuration rather than hardcoded. Open-work trackers distinguish intended rules from implementation still pending validation.

## Match Objective

Up to 6 players may remain representable in architecture, but Milestone 1 has exactly two active players: human P1 and bot P2. The winner is the last non-eliminated player; an unfinished match is a draw after global player-turn 80 resolves.

A player is eliminated when an enemy controls that player's capital tile after combat and control resolution. All tiles controlled by the eliminated player transfer to the capital capturer.

## Board

- The board is one axial-coordinate micro hex grid.
- Macro regions are visual and data groupings over micro tiles.
- Each player starts with one home macro region.
- Each home region has one capital tile at its center.
- Neutral tiles exist between or around home regions to create early expansion pressure.
- Milestone 1 map `Alpha Medium` is a radius-6 axial board with 127 total tiles. P1 and P2 home regions are radius-2 around their capitals and contain 19 tiles each.

## Tile Ownership And Control

Each tile has:

- `home_owner`: original owner, or `neutral`.
- `controlled_by`: current controller, or `neutral`.
- `region_id`: macro grouping.
- optional wall edges around home-region perimeter.

Milestone 1 uses pass-through capture. After uncontested movement, a living mover controls the destination tile. On a contested destination, control does not change until combat resolves; the surviving combatant controls it. If a player later moves over a tile again, they reclaim it after the same resolution rule.

## Fog Of War

A tile is visible to player P when any of these are true:

- P controls the tile.
- The tile borders a tile controlled by P.
- P has a living stack on the tile.

Bots receive the same observable state as a human player. Hidden tiles must not reveal enemy stack counts, destinations, wall damage, or combat details unless visible through the same rules.

## Turn Structure

Milestone 1 uses sequential player turns. `turn` is the global player-turn ordinal, not a round number or per-player counter. On player P's turn:

1. Spawn soldiers purchased on P's previous turn at P's capital.
2. If P's capital is enemy-controlled, eliminate P before further action.
3. Add income to P's bank using controlled tiles and active economy bonus.
4. Allocation phase: P may spend banked money on Economy, Military, and Research.
5. Movement phase: P may add or replace queued waypoints for selected stacks.
6. Movement tick: P's living stacks advance at most 1 tile along their queued paths.
7. Resolve wall attacks, uncontested movement control, combat, survivor control,
   and eliminations in that order.
8. Advance to the next non-eliminated player.

After the resolution work for player-turn 80, an unfinished match ends
immediately in a deterministic draw. It emits one `match_ended` event with an
empty winner, sets `game_over`, and does not begin player-turn 81.

## Money

Money is stored as integer cents. Display can show dollars.

Base income per own turn:

```text
own_home_income = controlled tiles where tile.home_owner == player: 100 cents each
foreign_or_neutral_income = controlled tiles where tile.home_owner != player: 50 cents each
base_income = own_home_income + foreign_or_neutral_income
final_income = floor(base_income * (10000 + active_economy_bonus_bps) / 10000)
```

## Economy Allocation

Default Milestone 1 economy investment is temporary and non-compounding.

```text
economy_units = floor(economy_spend_cents / economy_bonus_unit_cost_cents)
next_turn_income_bonus_bps = min(economy_units * economy_bonus_bps_per_unit, economy_bonus_cap_bps)
```

When `economy.compounds` is true in config, the bonus is added to an accumulated player economy level instead of replacing the next-turn bonus. Milestone 1 keeps this off.

## Research Allocation

Research stacks across turns and affects future soldier cohorts only.

At match creation, generate a shared deterministic schedule:

```text
research_schedule[turn] = {
  health_bps_per_point,
  damage_bps_per_point
}
```

The complete 80-entry, one-based schedule is sampled by the named `research`
RNG stream from the match seed and configured bounds, then stored with its
generation version in match setup/replay data. It is immutable for that match.
M1 uses `fnv1a32_seed_mix_v1`: each descriptor records its `stream_id`, purpose,
and `salt_namespace`; the descriptor plus operation salt is mixed with the match
seed, rather than advancing hidden PRNG state. Research owns
`research_schedule_v1` and samples `turn:<n>:health` and `turn:<n>:damage`;
combat owns `combat_roll_v1`; bot policy tiebreaks own `bot_policy_v1`.

The complete schedule, ruleset hash, configured bounds, and schedule generation
version are public information shown consistently to the player and exposed to
bots through their observable contract.

On allocation:

```text
research_points = floor(research_spend_cents / research_point_cost_cents)
player.research_health_bps += research_points * research_schedule[current_turn].health_bps_per_point
player.research_damage_bps += research_points * research_schedule[current_turn].damage_bps_per_point
```

A newly spawned soldier cohort uses the player's current cumulative research bps.

## Military Allocation

Military spend queues soldiers for the player's next own turn.

```text
queued_soldiers_next_turn = floor(military_spend_cents / soldier_cost_cents)
```

Queued soldiers spawn as one or more cohorts on the player's capital. If the capital is enemy-controlled at spawn time, the player is eliminated before spawning.

## Soldiers And Stacks

Base soldier stats:

- Health: 100.
- Mean damage per combat exchange: 100.
- Damage standard deviation: 10.

A stack contains cohorts. A cohort stores:

- `cohort_id`
- `owner_id`
- `count`
- `spawn_turn`
- `max_health_per_soldier`
- `damage_mean_per_soldier`
- `damage_stddev_per_soldier`
- `current_total_health`

Stack aggregate health is the sum of cohort health. Stack expected damage is the sum of cohort count multiplied by cohort damage mean. Weighted-average display stats can be derived from cohorts without losing simulation accuracy.

## Movement

- Each living stack may have a queue of waypoint tile IDs.
- During a movement tick, each active-player stack advances at most 1 tile toward the first waypoint.
- When a waypoint is reached, it is removed and the next waypoint becomes active.
- A live wall blocks its edge. Contact with a living enemy creates a contested
  destination for combat resolution; it does not grant control before survival
  is known.
- If a stack survives combat, its remaining waypoints stay queued.
- Every executed edge must still be adjacent and legal at resolution time; a stale queue can never jump an invalid edge.
- Friendly living stacks that meet automatically merge into the lexicographically
  lowest stack ID. Their cohorts retain stable cohort-ID order, all participating
  queues are discarded, the absorbed stack is removed, and one
  `friendly_stacks_merged` event records the destination and absorbed IDs.
  Milestone 1 does not support manual unstacking.

## Walls

Walls are edge blockers, not units on tiles.

- Default wall HP: 1000.
- Enemy movement through a live wall edge is blocked.
- A stack whose next queued step crosses an enemy wall attacks that wall instead of moving through it.
- Wall damage uses the stack's deterministic combat damage roll.
- Destroyed walls are removed permanently.

## Combat

Milestone 1 combat is deterministic and modular.

Resolution order:

1. Group opposing stacks by tile after movement.
2. Resolve wall attacks before unit-vs-unit combat.
3. On a contested tile, resolve pairwise battles by stable ordering: current tile controller first as defender, then lower player ID as tie-breaker.
4. Each battle runs combat exchanges until only one side remains or the configured exchange cap is reached.
5. Damage rolls use deterministic seeded RNG keyed by match seed, turn, tile, exchange index, attacker cohort IDs, and defender cohort IDs.
6. Damage is applied to front cohorts in deterministic cohort order, with overflow carrying to the next cohort.
7. After combat, a surviving stack controls the tile.

The combat module must expose a single entry point so alternate combat models can be tested without changing UI or bot code.

## Replay And Determinism

A match must be reproducible from:

- ruleset ID and hash
- map ID and hash
- match seed
- player/bot setup
- command history

Only fully validated, accepted commands enter accepted-command history; rejected
attempts append a diagnostic and never mutate gameplay state or accepted source
sequence. `client_sequence` is a positive integer strictly increasing per
player (M1 has one source per player), and advances only on acceptance. All
random values must come from explicitly owned deterministic streams recorded or
derivable from the match seed. Canonical SHA-256 state hashing verifies
reconstruction at declared steps and match end. Its serialization includes the
schema/version, ruleset/map IDs and hashes, seed/RNG derivation metadata, turn,
active player/phase/end state, players, tiles, walls, stacks/cohorts, research
schedule, accepted commands, replay events, and next-ID counters in sorted
stable-ID/key order; rejected diagnostics and presentation-only fields
(including player display names and colors) are excluded through an explicit
gameplay projection.
