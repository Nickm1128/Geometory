# M1-P01 Requirements — Deterministic Core Contracts

- `M1-P01-R01` **Pillar 5 — Deterministic core:** only fully validated commands may change state or enter replay history, and identical inputs must yield identical canonical hashes.
- `M1-P01-R02` **Pillars 1 and 2 — Strategic clarity and territory:** movement, merging, combat, tile control, capital capture, and the player-turn limit must resolve in documented stable order.
- `M1-P01-R03` **Bot fairness:** bots receive a capability-limited observable snapshot with no hidden enemy orders, economy, research, wall state, or exact strength beyond the player-visible contract.
- `M1-P01-R04` **Pillar 6 — Vertical-slice discipline:** subsystem extraction must preserve a small `GameCore` facade and keep the simulation independent of rendering, input, and scene lifecycle.
- `M1-P01-R05` **Configuration integrity:** public research schedule, global player-turn cap 80, economy units, and tunable behavior remain data-driven and documented.
