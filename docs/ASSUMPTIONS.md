# Assumptions And Decisions

This is the authority for durable product and technical decisions. Open-work
trackers record implementation status and evidence; they do not redefine these
choices. Revisit this file before changing behavior.

## Locked For Milestone 1

- Product scope: one polished local 1v1 match, human P1 versus a fair bot P2, on
  the handcrafted Alpha Medium map.
- Deferred scope: P2P, lobbies, accounts, servers, network synchronization,
  more than two active players, extra/procedural maps, multiple unit types,
  manual save slots, a replay library, unstacking, multi-select, and Play Store
  submission.
- Platform: Android-first and portrait-first, responsive across supported phone
  aspect ratios.
- Engine/toolchain: official standard Godot 4.6.3 with matching templates,
  Android min SDK 24, target/compile SDK 36, and Java 21.
- Packages: production `com.milin.geometory`; QA-only fixtures
  `com.milin.geometory.qa` behind the build-time `visual_qa` feature.
- Authoritative device: alias-only Galaxy S24 profile in
  `tools/device_profiles/galaxy_s24_primary.json`; never version its ADB serial
  or another unique identifier.
- Board model: one large axial micro-hex grid, visibly grouped into macro
  regions. Content remains one handcrafted map for M1.
- Alpha Medium: radius 6, 127 tiles, radius-2 home regions, capitals at
  `(-4, 0)` and `(4, 0)`, and five starting soldiers per capital.
- Turn meaning: `turn` is the global resolved player-turn ordinal. An unfinished
  match becomes a deterministic draw after player-turn 80 resolves.
- Tile capture: apply control after uncontested movement or after the surviving
  combatant is known; controller-first defender ordering remains stable.
- Friendly contact: compatible friendly stacks auto-merge cohorts, clear both
  queued paths, and emit an explanatory event.
- Economy: integer cents and basis points; economy investment is temporary and
  non-compounding by default.
- Research: cumulative future-cohort bonuses use a shared seeded schedule; the
  schedule and current configuration are public to both players and bots.
- Soldiers: cohort-based stacks preserve spawn quality and current health.
- Movement: active-player stacks advance at most one adjacent edge per own turn
  along queued paths; every executed edge is validated.
- Combat: deterministic seeded resolution with no unowned randomness.
- Walls: edge blockers start at 1000 HP and are permanently removed at zero.
- Capital capture: after resolution, an enemy-controlled capital eliminates its
  owner and transfers that player's controlled tiles to the capturer.
- Replay truth: only accepted commands enter history. Canonical state hashes and
  explicitly owned RNG streams establish deterministic reconstruction.
- Resume: persist atomically after every accepted command and reconstruct from
  setup plus commands, not by trusting a snapshot. Keep one active match and the
  latest completed replay; no manual slots/library.
- Bot fairness: bots receive a capability-limited observable snapshot under the
  same fog/strength rules as the player and submit ordinary validated commands.
- AI assistance: external Python tooling may propose allowlisted bot-profile
  leaf changes only. The Android app has no API key/model code; arbitrary
  AI-authored source changes are forbidden.
- Paid AI boundary: one proposal request per cycle, ambiguous timeouts are never
  retried automatically, and the fixed limits are $1.00/cycle and $10.00 total
  for M1. Only the coordinating agent may initiate paid calls or promote a bot.
- Visual direction: dark tactical, macro-region-readable, with non-color
  ownership cues and no theme toggle required for M1.
- UI settings: UI scale 1.00/1.15/1.30, tips, and reduced motion persist; live
  safe-area data is production authority and injectable profiles are QA-only.
- Tactical rendering: cached layered procedural rendering at the logical
  portrait viewport; subtle texture must not reduce fog/wall/path/ownership
  readability.
- Delivery: internal/debug `0.2.0-m1` normal and QA APKs must pass functional,
  lifecycle, manifest, visual, device, and performance gates. Subjective fun and
  feel is the only intentionally human sign-off.

Detailed phase thresholds and paid-provider controls remain authoritative in
`docs/open_work/MILESTONE_1_PLAN.md` and the owning phase requirements.

## Open Decisions

- How much configured combat variance feels fair during final balance work.
- Whether a later multiplayer ruleset replaces stable player-ID tie-breaking
  with an initiative system.
- How a post-M1 unstacking feature should distribute cohorts.
- Final bundled font, sound, and advanced motion production choices within the
  existing accessibility and deterministic-screenshot constraints.
