# GMTY1 Replay Notation

`GMTY1` is the first compact text notation for Geometory matches. It is designed for debugging, replay comparison, and AI-assisted bot review.

## Header

```text
GMTY1 seed=18374 rules=default@hash map=alpha@hash players=P1:human,P2:bot/base
```

Required fields:

- `seed`
- `rules`
- `map`
- `players`

Optional fields:

- `godot_version`
- `core_version`
- `created_at`

## Research Schedule

```text
SCHED H=200,400,100 D=200,100,300
```

Values are basis points per research point by turn index.

## Turn Lines

Income:

```text
T1 P1 INC base=1200 bonus=0 bank=1200
```

Allocation:

```text
T1 P1 ALLOC E=300 M=600 R=300
```

Movement command:

```text
T1 P1 MOVE stack=S12 path=A3>B3>C3 mode=append
```

Spawn:

```text
T2 P1 SPAWN soldiers=2 tile=CAP1 h=10200 d=10100
```

Event summary:

```text
T2 P1 EVT cap tile=B3 by=P1 wall=W17 hp=820
T2 P1 EVT combat tile=C3 win=P1 loss=P2 p1hp=450 p2hp=0
```

End:

```text
END winner=P1 turns=18 elim=P2@T18
```

## Rules

- Prefer stable IDs over coordinates when both exist.
- Use cents for money and basis points for multipliers.
- Keep lines append-only during simulation.
- Do not include hidden information in player-visible replay views during a live match.
- Full omniscient replay logs are allowed after match end and for training artifacts.
