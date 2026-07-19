# Authoritative Game Rules

This document is the source of truth for V1 gameplay behavior. Constants live in `data/rules/default_rules.json` and should be read from configuration rather than hardcoded.

## Match Objective

Up to 6 players can exist in the architecture. V1 may ship with fewer. The winner is the last non-eliminated player.

A player is eliminated when an enemy controls that player's capital tile after combat and control resolution. All tiles controlled by the eliminated player transfer to the capital capturer.

## Board

- The board is one axial-coordinate micro hex grid.
- Macro regions are visual and data groupings over micro tiles.
- Each player starts with one home macro region.
- Each home region has one capital tile at its center.
- Neutral tiles exist between or around home regions to create early expansion pressure.
- MVP map `Alpha Medium` is a radius-6 axial board with 127 total tiles. P1 and P2 home regions are radius-2 around their capitals and contain 19 tiles each.

## Tile Ownership And Control

Each tile has:

- `home_owner`: original owner, or `neutral`.
- `controlled_by`: current controller, or `neutral`.
- `region_id`: macro grouping.
- optional wall edges around home-region perimeter.

V1 uses pass-through capture. A living stack changes `controlled_by` for every tile it successfully enters. If a player later moves over that tile again, they reclaim it.

## Fog Of War

A tile is visible to player P when any of these are true:

- P controls the tile.
- The tile borders a tile controlled by P.
- P has a living stack on the tile.

Bots receive the same observable state as a human player. Hidden tiles must not reveal enemy stack counts, destinations, wall damage, or combat details unless visible through the same rules.

## Turn Structure

V1 uses sequential player turns. On player P's turn:

1. Spawn soldiers purchased on P's previous turn at P's capital.
2. If P's capital is enemy-controlled, eliminate P before further action.
3. Add income to P's bank using controlled tiles and active economy bonus.
4. Allocation phase: P may spend banked money on Economy, Military, and Research.
5. Movement phase: P may add or replace queued waypoints for selected stacks.
6. Movement tick: P's living stacks advance at most 1 tile along their queued paths.
7. Resolve wall attacks, tile control, combat, and eliminations.
8. Advance to the next non-eliminated player.

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

Default V1 economy investment is temporary and non-compounding.

```text
economy_units = floor(economy_spend_cents / economy_bonus_unit_cost_cents)
next_turn_income_bonus_bps = min(economy_units * economy_bonus_bps_per_unit, economy_bonus_cap_bps)
```

When `economy.compounds` is true in config, the bonus is added to an accumulated player economy level instead of replacing the next-turn bonus. V1 should keep this off.

## Research Allocation

Research stacks across turns and affects future soldier cohorts only.

At match creation, generate a shared deterministic schedule:

```text
research_schedule[turn] = {
  health_bps_per_point,
  damage_bps_per_point
}
```

The schedule is sampled from the match seed and stored in match state/replay header.

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
- If a path is blocked by a living enemy, unresolved combat, or wall, the stack stops and waits for resolution.
- If a stack survives combat, its remaining waypoints stay queued.

## Walls

Walls are edge blockers, not units on tiles.

- Default wall HP: 1000.
- Enemy movement through a live wall edge is blocked.
- A stack whose next queued step crosses an enemy wall attacks that wall instead of moving through it.
- Wall damage uses the stack's deterministic combat damage roll.
- Destroyed walls are removed permanently.

## Combat

V1 combat is deterministic and modular.

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

All random values must come from deterministic seeded streams recorded or derivable from the match seed.
