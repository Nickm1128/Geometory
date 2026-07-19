# Milestone Roadmap

## Phase 1: Foundation And Scaffold

Deliverables:

- project vision doc
- authoritative rules doc
- technical design doc
- Android UI/UX guidelines
- bot design doc
- simulation/training-loop design doc
- milestone roadmap
- rules/map/bot config stubs
- Godot project shell
- project-specific Codex skills/workflows

Exit criteria:

- future implementation has clear file locations and rules authority
- constants are configurable
- known tooling gaps are documented

## Phase 2: Headless Core Prototype

Deliverables:

- load rules and map config
- create match state from seed
- command model and validator
- turn loop
- income/allocation/research/military math
- seeded research schedule
- axial hex pathing
- movement queues
- tile control
- fog query
- wall blocking/damage
- deterministic combat
- replay event emission
- basic headless tests

Exit criteria:

- a full bot-vs-bot match can finish headlessly from seed
- replay log can reproduce the same outcome
- MVP implementation includes a playable human-vs-bot path using the same core.

## Phase 3: Minimal Godot Playable

Deliverables:

- render handcrafted map
- camera pan/zoom
- tap select tile/stack
- path preview and queue command
- allocation bottom sheet
- turn transition flow
- fog rendering
- wall rendering
- combat/result summaries

Exit criteria:

- one human can complete a local match against a bot on Android-sized viewport
- Quick Play, How To Play, Settings, Dev Tools, Pause, and Game Over flows exist for phone playtesting.

## Phase 4: Bot Competence Pass

Deliverables:

- baseline rule bot
- bot profile config tuning
- simulation batch runner
- metrics report
- invalid command diagnostics

Exit criteria:

- bot expands, defends, attacks visible opportunities, and finishes matches without cheating

## Phase 5: Polish Vertical Slice

Deliverables:

- improved mobile layout
- stronger visual hierarchy
- map readability at zoom levels
- smoother input feedback
- balance pass
- save/replay inspection flow
- Android export validation

Exit criteria:

- prototype is stable and readable on Galaxy S24 and at least two additional aspect ratios

## Phase 6: Networking And AI Loop Preparation

Deliverables:

- command sync design for P2P
- replay compatibility tests
- OpenRouter proposal ingestion prototype outside the game client
- automated candidate validation harness

Exit criteria:

- networking and AI-assisted bot improvement can proceed without rewriting core rules
