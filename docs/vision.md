# Project Vision

Geometory is a clean, mobile-first Android strategy game about readable
territorial decisions on a zoomable hex map. Matches should resolve in 10–20
minutes, reward expansion and invasion timing, and remain understandable on a
phone screen.

## Pillars

1. Fast strategic clarity: each turn produces a meaningful allocation or
   movement decision.
2. Territory matters: controlled tiles directly fund future turns and create
   pressure to expand early.
3. Macro fantasy, micro tactics: one micro-hex board is visibly grouped into
   consequential macro regions.
4. Mobile-first feel: touch targets, safe areas, modal size, camera movement,
   text density, motion, and haptics are designed for phones first.
5. Deterministic core: setup plus accepted serializable commands reproduces game
   state, enabling resume, replay, bots, simulation, training, and later
   networking.
6. Vertical-slice discipline: finish and certify one handcrafted map before
   expanding content or multiplayer.

## Milestone 1 Target

Deliver one polished local 1v1 Android match on Alpha Medium with complete
win/loss/draw behavior, automatic process-safe resume, player-facing last-match
replay review, a competent fair profile-driven bot, an external guarded
AI-assisted improvement loop, and the bulk of the intended aesthetics and UX.

The vertical slice must be deterministic and simulation-ready, understandable
without developer tools, reproducible on the matched emulator, and certified on
the physical Galaxy S24. The external AI loop may safely reject every candidate;
M1 requires a reproducible accept-or-reject cycle, not a successful promotion.

## Explicitly Deferred Until After Milestone 1

- P2P, lobbies, accounts, servers, and network synchronization
- more than two active players
- additional or procedural maps
- multiple unit types
- manual save slots and a replay library
- unstacking and multi-select
- runtime LLM opponents, credentials, or model code in the APK
- arbitrary AI-authored source changes
- Play Store submission
- advanced music, audio, and animation production
