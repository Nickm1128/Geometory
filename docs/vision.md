# Project Vision

Geometory is a clean, mobile-first Android strategy game about readable territorial decisions on a zoomable hex map. Matches should resolve in 10-20 minutes, reward expansion and invasion timing, and stay understandable on a phone screen.

## Pillars

1. Fast strategic clarity: each turn should produce a meaningful allocation or movement decision.
2. Territory matters: controlled tiles directly fund future turns and create pressure to expand early.
3. Macro fantasy, micro tactics: the board is one large micro hex grid visually grouped into large macro regions.
4. Mobile-first feel: tap targets, modal size, camera movement, and text density are designed for phones first.
5. Deterministic core: game state advances from seed plus serializable commands, enabling replay, bots, networking, and training.
6. Vertical-slice discipline: build one polished handcrafted map before expanding content or multiplayer.

## V1 Target

V1 is a local single-map prototype with one human player, at least one rule-based bot, economy/research/military allocation, fog of war, walls, queued soldier movement, tile control, combat, and a complete win/loss flow.

## Explicit Non-Goals For V1

- Full P2P Android networking.
- Procedural map generation.
- Multiple unit types.
- Advanced animation and audio systems.
- LLM-driven bot editing inside the game client.
