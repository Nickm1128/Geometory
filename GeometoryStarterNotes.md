# Android Strategy Game — Organized Project Notes + Codex Starter Prompt

## 1) Core Game Concept

A fast, turn-based territorial strategy game for Android built in Godot, designed to finish in roughly **10–20 minutes**. The game combines:

* a **macro map** made of large hex regions
* a **micro map** inside each region, made of many smaller hex tiles
* **economic allocation** each turn
* **territory control and fog of war**
* **soldier movement, stacking, and combat**
* eventual **P2P multiplayer**
* **bot opponents** that can later be improved through an AI-assisted training loop

The high-level feel is something like **Risk meets a zoomable tactical hex game**, but with shorter match length, cleaner UX, and a stronger economy/research loop.

---

## 2) Design Pillars

These are the principles the project should optimize for.

### A. Short, readable matches

* Typical match length: **10–20 minutes**
* Turns should feel meaningful but not slow
* The player should be able to understand the board state quickly

### B. Two-level map fantasy

* The macro map gives a strategic overview
* Zooming into a region reveals tactical positioning at the tile level
* This should feel elegant rather than confusing

### C. Clear economy and territory incentives

* Owning land matters immediately
* Expanding into neutral territory matters early
* Raiding enemy land matters even before full invasion

### D. Mobile-first usability

* Clean inputs on a phone screen
* Minimal clutter
* Strong modal sizing and readable UI on different devices
* Special attention to Android, starting with a **Galaxy S24**, but the codebase should be prepared for other sizes/aspect ratios

### E. Strong technical foundation

* Code should be structured so gameplay logic is separable from rendering/UI
* This enables fast bot simulations without full scene rendering
* Project should be documented well enough for autonomous iteration by Codex

---

## 3) V1 Scope Recommendation

To get to a polished result quickly, the first pass should deliberately narrow scope.

### V1 should include

* Single playable map layout
* 2 to 4 players initially, with architecture allowing expansion to 6 later
* Local game flow and single-player matches against bots
* Macro/micro map structure
* Territory income
* Neutral exploration tiles
* Soldier spawning, movement queueing, stacking, walls, combat
* Fog of war
* Basic bot opponents
* Clean mobile UI
* Save/load match state if feasible

### V1 should NOT block on

* Full P2P networking
* Large content variety
* Many maps
* Fancy animation systems
* Complex unit types beyond the initial soldier unit

### Post-V1 / Phase 2

* Expand to full 6-player support
* More map shapes and generation options
* P2P multiplayer on Android
* Better audiovisual polish
* Deeper bot training loop with AI rule iteration

---

## 4) Organized Gameplay Spec

## 4.1 Match structure

* Turn-based game
* Up to **6 players** eventually
* Winner is the **last player standing**
* A match should resolve in **10–20 minutes**

## 4.2 Board structure

### Macro map

* A board of large hex regions
* Each region can belong to a player or be neutral/uncontested
* Initially, start with one handcrafted map rather than procedural generation
* The architecture should allow future support for different map shapes and layouts

### Micro map

* Each macro hex contains a **mini hex grid** of smaller tiles
* This is where soldiers are positioned and move
* Each player has a home region with a **capital tile** at its center
* At game start, a player's region begins fully under their control
* Their region is protected by **walls around the perimeter**

### Neutral tiles

* Some surrounding space should begin as uncontested territory
* These are intended to create an early expansion phase
* Neutral tiles generate **$0.50 per turn** when controlled

## 4.3 Territory control

* A player earns **$1.00 per turn** for each tile in their own territory under their control
* A player earns **$0.50 per turn** for enemy or neutral tiles they control
* A tile changes control when an enemy soldier **touches/occupies** it
* The tile remains under that player's control until the original owner touches it again with one of their own soldiers

### Clarification for implementation

For V1, Codex should pick one clean rule and document it clearly:

1. **Occupation model**: a tile flips control when an enemy unit ends movement on it
2. **Touch model**: a tile flips as soon as a unit passes through it

The current concept suggests a touch-based model, but an end-of-move occupation model may be easier to communicate and balance. If Codex sees a strong reason to choose one for V1, it should document the choice and keep the other as an optional ruleset.

## 4.4 Fog of war

Fog should hide everything except:

* tiles under your control
* tiles adjacent to tiles under your control
* optionally, tiles occupied by your own units

Bots must obey the same information limits as human players.

## 4.5 Turn economy allocation

At the **start of a player's turn** they receive income, then allocate resources across three buckets:

### Economy

* Gives a small multiplier to tile income for that turn cycle
* Current concept: **does not compound across turns**
* However, the system should be designed so this can be changed later

### Research

* Improves future soldier quality
* Research stacks across turns
* Affects soldier health and damage

### Military

* Spends money on soldiers that will **spawn next turn**
* Spawn location is the capital tile

### Recommended V1 formalization

Codex should define this using explicit formulas and constants in a config file.
Example starting direction:

* `economy_spend -> temporary income bonus next turn only`
* `research_spend -> cumulative research score`
* `military_spend -> soldier count queued for next turn`

The exact conversion constants should be centralized and easy to tune.

## 4.6 Soldiers

### Baseline soldier stats

* Base health: **100**
* Base average damage per combat turn: **100**
* Damage should include noise with standard deviation **10**

### Research scaling

* Soldier health and damage scale based on the player's research at the time the soldiers were spawned
* Because research accumulates over turns, different soldiers in the same stack may have different effective quality

### Stacking

* Multiple soldiers can occupy the same tile
* Stacking increases total health and total damage output
* If stacked soldiers have different research-quality levels, the group's effective stats should be a **weighted average based on the composition of the stack**

### Recommended data model

Instead of collapsing all units into one number immediately, store a stack as grouped cohorts:

* count
* spawn turn
* research-derived health multiplier
* research-derived damage multiplier
* current aggregate health for that cohort if needed

This will make weighted averages and future balancing easier.

## 4.7 Soldier movement

* Player taps a soldier/stack, then taps a destination tile
* Soldiers move **1 tile per turn**
* Movement path can be queued across multiple turns
* Player can specify **multiple destinations in order**
* This should support a “set it and forget it” style

### Pathing rule

For V1, movement should use a simple hex-grid pathfinder with:

* path preview
* persistent movement queue
* invalidation if path becomes impossible

## 4.8 Combat

* Combat happens when opposing soldiers occupy the same tile on a turn
* Soldiers deal damage each combat round/turn
* Damage includes random noise
* If soldiers cross paths incidentally, and survive, they continue along their queued path

### Clarification for V1

Because simultaneous crossing/path conflict can become tricky, Codex should choose and document one deterministic movement/combat resolution order, such as:

1. process all movement intents
2. resolve collisions on resulting tiles
3. resolve territory control updates
4. update walls if relevant

or

1. move units one step in initiative order
2. resolve combat immediately on contact

The key is that the logic must be deterministic and simulation-friendly.

## 4.9 Walls

* At the start of the game, each player's home territory is ringed by walls
* Enemy soldiers must destroy walls before entering further into the territory

### V1 recommendation

Treat walls as static defensive objects with:

* health
* tile position
* ownership
* blocking behavior

Walls can be attacked by adjacent enemy stacks. Codex should pick a simple first rule set and expose wall HP/damage in config.

## 4.10 Research noise across turns

The research growth effect should vary from turn to turn, but be fixed for all players within a match.

Example:

* turn 1 research bonus schedule might be +2% health, +2% damage
* turn 2 might be +4% health, +1% damage
* turn 3 might be +1% health, +3% damage

Important properties:

* sampled once at game start
* shared by all players in that match
* different between games

This is essentially a match-level tech climate / progression curve.

### V1 implementation suggestion

Generate a deterministic per-turn bonus table at match start using a seeded RNG.
Store it in match state so:

* replays are possible
* simulations are reproducible
* bots can reason about visible rules if that information is intended to be public

---

## 5) Key Ambiguities / Decisions to Lock Early

These are places where the concept is strong but the implementation needs precise choices.

1. **Macro-to-micro interaction**

   * Does the player zoom into one macro region at a time? Player has a smooth zoom with pinch and can zoom out to see the entire map or into a single tile.
   * Can soldiers move between macro regions only through specific border tiles? Soldiers can move over any tile unless an enemy soldier is present and they die.
   * Is the full board actually one large micro hex grid that is visually grouped into macro hexes? Yes

2. **Territory ownership update rule**

   * Flip on pass-through or only on ending movement? Flip on pass-through.

3. **Combat timing**

   * Simultaneous or sequential resolution? Sequential, but if the solders are stacked then they fight one-by-one until one of the two groups is destroyed.

4. **Stack representation**

   * Cohort-based vs fully aggregated stats cohort-based. I also want to be able to 'unstack' soldiers in which case they will disperse according to some logic. For example, unstacking soldiers means they'll have to split into smaller groups and expand outward onto more tiles. Since soldiers only move one tile per turn, this will be a gradual process, during which the soldiers will be grouped into smaller segments. I also want to be able to select multiple soldiers simultaneously, maybe their tile lights up, and then I can choose a tile for them to travel to, similar to drawing a selection box in a real time strategy game like Age of Empires II.

5. **Wall interaction**

   * Can ranged adjacency attack happen, or must a unit stop at the wall boundary? Unit stops at wall boundary, but walls have 1000 health and soldiers will attack it to get through. Once it's destroyed, it's gone forever.

6. **Spawn rule**

   * If capital tile is occupied/full/contested, what happens? That player loses and all of their territory goes to the player who controls their capital.

7. **Turn pacing for mobile**

   * One action phase per player, or smaller sub-phases? Two action phases. One allocates resources for the next turn, the second is moving troops.

Codex should explicitly document assumptions rather than silently choosing them.

---

## 6) Technical Architecture Goals

The project should be scaffolded so it can evolve safely and be worked on autonomously.

## 6.1 Core separation

The single most important architecture rule:

### Separate gameplay logic from presentation

There should be:

* a **pure game logic layer** that can run headlessly for tests and simulation
* a **Godot presentation layer** for rendering, input, camera, animations, and UI

This is crucial because:

* bot matches need to simulate fast
* AI-assisted bot training should not require launching full scenes
* debugging will be much easier

## 6.2 Suggested repo structure

```text
/project_root
  /docs
    vision.md
    game_rules.md
    tech_design.md
    ui_ux_guidelines.md
    roadmap.md
    bot_design.md
    simulation_loop.md
  /godot
    project.godot
    /scenes
    /scripts
    /assets
    /ui
  /core
    match_state
    rules_engine
    economy
    combat
    pathing
    fog_of_war
    bot_api
    simulation_runner
  /tools
    replay_export
    balancing_tools
    bot_training
  /tests
    core_logic_tests
    simulation_tests
    bot_tests
```

Whether Codex uses GDScript only, or a mixed setup, it should preserve this logical separation even if the directory names differ.

## 6.3 Documentation Codex should create early

Before building too much code, Codex should create:

1. **vision.md**

   * concise statement of the game's purpose and constraints

2. **game_rules.md**

   * authoritative rules and formulas

3. **tech_design.md**

   * scene structure, core systems, data flow, save format

4. **ui_ux_guidelines.md**

   * phone-first layout, modal sizing, HUD constraints, touch targets, font scaling

5. **bot_design.md**

   * bot interface, inputs, outputs, rule system, fog-of-war limits

6. **simulation_loop.md**

   * headless simulation design and AI-assisted rule iteration loop

7. **roadmap.md**

   * milestone plan from prototype to polished vertical slice

---

## 7) Mobile UX / Aesthetic Direction

## 7.1 Visual direction

Desired aesthetic:

* clean
* minimal
* strategic
* readable
* not noisy

Preferred look:

* thin lines
* distinct player colors
* primarily white or dark base
* possibly a subtle gradient background
* modern and crisp rather than gritty or ornate

## 7.2 UI priorities

* readable at phone size
* modals must not dominate too much of the screen
* touch targets must be comfortable
* camera zoom and panning must feel smooth
* important information should be visible without clutter

## 7.3 Specific mobile concerns to emphasize to Codex

* support Galaxy S24 first, but avoid hardcoding for one resolution
* use anchors/containers responsibly
* test multiple aspect ratios
* make overlays adaptive
* keep battle/economy/research information understandable in one glance
* avoid tiny fonts and overly dense panels

---

## 8) Multiplayer Direction

You want **P2P multiplayer on Android** eventually.

### Recommendation

Do **not** let networking define the first build.
Instead:

* design the core logic to be deterministic
* make all player actions serializable as commands
* make turn resolution reproducible from state + command history

That way, networking can be added later with much less pain.

Codex should still plan for multiplayer from day one by:

* defining a command/event model
* making state transitions deterministic
* keeping random generation seeded and recorded

---

## 9) Bots and AI-Assisted Training Loop

Important vocabulary distinction:

* **Bots** = in-game nonplayer opponents
* **AI** = external LLM-based systems used to improve bot rules or analyze game logs

## 9.1 Bot requirements

Bots should:

* only access information available to a real player in that role
* decide how to allocate money between economy, military, and research
* decide how to move units
* decide how to prioritize expansion, defense, attack, and wall pressure

## 9.2 Bot architecture recommendation

Bots should implement a stable interface such as:

* receive observable game state
* evaluate priorities
* emit actions/allocations/movement queues

A good first design is a **rule-based bot framework** where each bot has:

* heuristics
* thresholds
* priorities
* optional personality weights

Examples:

* expansion bias
* defense bias
* attack opportunism
* save-vs-spend tendency
* stack consolidation preference
* wall-breaking priority

## 9.3 AI-assisted rule evolution loop

The goal is to improve bots through repeated simulation and AI analysis.

### Proposed workflow

1. Define a current ruleset for one or more bots
2. Run many fast headless matches
3. Export results in a compact text format
4. Feed summaries to an AI model through OpenRouter chat completions
5. Ask the AI to propose:

   * rules to add
   * rules to remove
   * threshold changes
   * priority shifts
6. Validate proposed changes automatically
7. Run another simulation batch
8. Keep changes that measurably improve performance or diversity

## 9.4 Headless simulation requirement

This is essential.
The game logic must be runnable without launching the full rendered game.
That means:

* no UI dependency in core logic
* no scene tree dependency for rule resolution if avoidable
* deterministic simulation runner

## 9.5 Compact game notation

You want something like a chess PGN for analysis.

### Good direction

Create a compact text replay format that records:

* seed
* map ID
* players/bots
* turn-by-turn allocations
* movement orders
* combats
* territory swings
* winner

For example, a line-based or tokenized format:

```text
GAME seed=18374 map=alpha players=4
T1 P1 alloc E:3 M:4 R:3
T1 P1 move S12 A3>B3>C3
T1 P2 alloc E:5 M:3 R:2
T1 combat tile=D4 P1:stack8 vs P2:stack5 result=P1_hold
...
END winner=P3 turns=18
```

Codex should design this early because it helps with:

* debugging
* replay inspection
* AI analysis
* bot improvement

---

## 10) Implementation Strategy for Fast Progress

Codex should avoid trying to build the final game all at once.

### Milestone 1 — Documentation + scaffolding

* establish repo structure
* create docs
* create core state models
* create config/constants system
* define command model

### Milestone 2 — Headless playable logic

* implement turn loop
* economy/research/military allocation
* movement
* combat
* walls
* fog of war
* replay/export format
* basic tests

### Milestone 3 — Minimal Godot playable prototype

* render map
* tap/select/move flow
* simple HUD
* turn transitions
* one working match from start to finish

### Milestone 4 — Bot opponents

* baseline heuristic bots
* headless simulations
* logging and evaluation metrics

### Milestone 5 — Polish pass

* cleaner visuals
* better camera and touch input
* clearer modals and overlays
* balancing

### Milestone 6 — Networking and advanced AI loop

* command sync / multiplayer planning
* OpenRouter-driven bot rule refinement tools

---

## 11) Constraints and Guidance for Codex

These are important working instructions for the autonomous coding agent.

### Project hygiene

* create project-specific skills/documentation for recurring tasks
* inspect the repo and available tools before making assumptions
* take stock of Godot version, Android export capabilities, and any existing files first
* do not rush into feature coding before documenting architecture

### Conscientious engineering

* prefer simple, extensible systems over clever tightly-coupled ones
* keep constants configurable
* keep deterministic seeds where randomness matters
* document assumptions when the design is ambiguous
* build the simulation layer early

### Mobile care

* be attentive to screen sizing, aspect ratios, and modal sizing
* design for touch first
* make text legible and interactions forgiving

### Scope discipline

* prioritize a polished vertical slice over feature sprawl
* if a feature threatens timeline, create a placeholder hook and document the future plan

---

## 12) Open Questions Worth Iterating On Later

These do not need to be fully answered before Codex starts, but they should be tracked.

* Should economy spend affect only next turn or the whole match?
* Should tile capture happen on pass-through or occupation?
* How many micro tiles should exist inside one macro region?
* Should walls be rebuildable?
* Should there be only one unit type at first?
* How strong should early neutral expansion be relative to early military pressure?
* How many queued waypoints should a player be able to set?
* How much randomness in combat is fun versus frustrating?
* Should all players see the research growth schedule, or is it hidden?

---

# Final Prompt to Paste into Codex

You are helping me build a **mobile-first Android strategy game in Godot**. I already have Godot installed. I want you to act as an autonomous engineering/planning agent that first creates the right scaffolding, documentation, and project hygiene so you can then build toward a polished vertical slice quickly and safely.

Before coding heavily, do the following:

1. **Inspect the repo and available resources/tools first**. Take stock of what already exists, what Godot version is in use, what export/tooling is available, and how the project is currently organized.
2. **Create project-specific skills/docs/workflows** for this repo so future work stays organized and consistent.
3. **Document assumptions explicitly** whenever the design is ambiguous.
4. **Prioritize a polished vertical slice** over trying to finish every advanced feature immediately.
5. **Be especially careful about mobile UX**, screen sizing, modal sizing, touch targets, and layout scaling. My current phone is a **Galaxy S24**, but the UI should handle other Android sizes well.
6. **Separate core game logic from rendering/UI** so that game simulations and bot training can run headlessly without launching the full rendered game.

## Game concept

I want a **turn-based strategy game** with **10–20 minute matches**. The game is somewhat like Risk on a **hex-grid map**, with up to **6 players** eventually, and the winner is the **last player standing**.

There is a **macro map** made of large hex regions, and when players zoom in, they see a **micro map** made of many smaller hex tiles inside a region. We will start with **one handcrafted map**, but the architecture should support different map shapes later.

Each player's home region has a **capital tile** at the center. At the start of the game, players control all tiles in their own region, and their region is protected by **walls around the perimeter**. Opponents must destroy walls before advancing deeper into that territory.

## Economy and control rules

At the start of a player's turn, they earn money based on territory:

* **$1.00** for each tile of their own territory under their control
* **$0.50** for enemy or neutral tiles under their control

I want some **neutral/uncontested tiles** on the map at the start so players can expand early. These also produce **$0.50 per turn**.

Tile control changes when an enemy soldier touches or occupies a tile. If one of your own soldiers touches it again later, you reclaim it.

There should be **fog of war** that hides all tiles except:

* tiles under your control
* tiles bordering tiles under your control
* and optionally tiles occupied by your units if that makes implementation cleaner

## Turn allocation system

After receiving income, a player allocates money between:

* **Economy**
* **Military**
* **Research**

### Economy

Adds a small multiplier to tile income. My current idea is that this **does not compound across turns**, but I may want to change that later, so make it configurable.

### Research

Improves the quality of soldiers spawned in the future. This **does stack across turns**.

### Military

Buys soldiers that spawn **next turn** in the player's **capital tile**.

Please define the exact formulas and constants in config/data files so they are easy to rebalance.

## Soldiers

Base soldier stats:

* **100 health**
* **100 average damage per combat turn**
* damage should include random noise with **standard deviation 10**

Soldiers can stack on one tile. Stacking should multiply total health and damage. But because soldiers are affected by the player's research level when they are spawned, stacks may contain mixed-quality soldiers. Please represent this in a way that preserves correct weighted-average stack stats and remains simulation-friendly.

Players move soldiers by tapping/selecting them and then tapping a destination tile.

* Soldiers move **1 tile per turn**
* Their movement path should be remembered over multiple turns
* I want players to be able to set **multiple destinations in sequence**
* The system should support a “set it and forget it” style

If a soldier or stack encounters enemies along its path and survives, it should continue following its queued path.

## Combat

When opposing soldiers occupy the same tile, they fight. I want deterministic, simulation-friendly combat resolution rules. Please choose a clean first approach, document it, and keep the implementation modular.

## Research growth randomness

The growth of health/damage from research should vary across turns in a match, such as:

* +2% one turn
* +4% next turn
* +1% after that

This variation should:

* be generated at the **start of the match**
* be different from game to game
* affect all players equally within that game
* be reproducible through a seed

## Aesthetic direction

I want a **clean**, **minimal**, **strategic** look:

* thin lines
* distinct player colors
* primarily white or dark background
* maybe a subtle gradient
* readable and uncluttered on mobile

## Networking direction

I eventually want **P2P multiplayer on Android**, but do **not** let networking block the first polished playable version. Instead, architect the game so:

* commands/actions are serializable
* the core game logic is deterministic
* state transitions can be replayed from seed + command history

## Bots vs AI terminology

Going forward:

* **Bots** = in-game nonplayer opponents
* **AI** = LLM-based systems or external models used for analysis/training

## Bot design goal

I want competent in-game bots. Bots should only receive the information available to a real player under fog of war. They should make decisions about:

* economy/military/research allocation
* troop movement
* expansion vs defense vs attack priorities

Please design bots as a class/interface that accepts observable game state and emits decisions.

I want to start with **rule-based bots**, where the bot behavior is defined by heuristics, thresholds, and priorities.

## AI-assisted bot improvement loop

Later, I want to improve bot behavior with an AI-assisted loop using **OpenRouter chat completions**.

The intended loop is:

1. Run many fast simulated bot games using only the headless game logic
2. Export the results in a compact text format
3. Send summaries or replay-like logs to an AI model
4. Ask the AI to propose rule additions/removals/adjustments
5. Validate those changes automatically
6. Re-run simulations
7. Keep changes that improve performance or useful behavioral diversity

Please design the project so this loop is possible.

## Compact game notation

I also want a concise text representation of a match, similar in spirit to chess PGN, so the AI can review games efficiently. Please design an initial replay/log notation early.

## What I want you to produce first

Please do not jump straight into random feature coding. First produce a strong foundation.

### Phase 1 output

Create and/or scaffold:

* a concise project vision doc
* an authoritative game rules doc
* a technical design doc
* a UI/UX guidelines doc for Android/mobile
* a bot design doc
* a simulation/training-loop design doc
* a milestone roadmap
* an initial repo/file structure that reflects these systems

### Architecture requirements

Please structure the code so there is a clean separation between:

* **core game logic / simulation**
* **Godot scenes/UI/input/rendering**

The core logic should be testable headlessly.

### Working style requirements

* inspect first, then plan, then scaffold, then implement
* create reusable project skills/workflows where useful
* keep all important constants configurable
* prefer simple, extensible systems
* document ambiguous decisions rather than hiding them
* favor a polished vertical slice over feature sprawl

## Initial implementation target

Build toward a **playable single-map prototype** with:

* one match flow from start to finish
* economy/research/military allocation
* tile control
* fog of war
* walls
* soldier movement and queued paths
* combat
* at least one basic bot opponent
* clean mobile UI

When you begin, first summarize your understanding of the game, list the key design decisions that need to be locked, inspect the repo/resources, and then create the initial scaffolding/docs before major implementation.
