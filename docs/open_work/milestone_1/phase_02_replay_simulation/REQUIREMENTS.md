# M1-P02 Requirements — Replay, Simulation, Resume, And Evidence

- `M1-P02-R01` **Pillar 5 — Deterministic core:** GMTY1 plus setup metadata and accepted commands must reconstruct every resolved player-turn and final canonical hash.
- `M1-P02-R02` **Pillar 4 — Mobile-first feel:** unfinished matches resume automatically and the latest completed match has a readable, touch-friendly replay inspector.
- `M1-P02-R03` **Pillar 6 — Vertical-slice discipline:** simulation uses the production core/bot path and emits reproducible, versioned evidence without rendered scenes.
- `M1-P02-R04` **Safety and compatibility:** corrupt, truncated, hash-mismatched, and unsupported records fail safely without destroying recoverable data.
- `M1-P02-R05` **Scope boundary:** M1 provides one active-match record and one last-match replay, not manual save slots or a replay library.
