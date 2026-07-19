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
- Turn meaning: `turn` is the one-based global player-turn ordinal. After the
  resolution work for player-turn 80, an unfinished match emits one
  `match_ended` draw event, sets `game_over`, leaves `winner` empty, and never
  starts player-turn 81.
- Tile capture: apply control after uncontested movement or after the surviving
  combatant is known; controller-first defender ordering remains stable.
- Friendly contact: living same-owner stacks on one tile auto-merge into the
  lexicographically lowest stack ID. Cohorts retain their existing stable
  cohort-ID order, every participating queue is discarded, the absorbed stack
  is removed, and one `friendly_stacks_merged` event names the destination and
  absorbed stack IDs.
- Economy: integer cents and basis points; economy investment is temporary and
  non-compounding by default.
- Research: at setup, the `research` RNG stream deterministically creates the
  complete 80-entry, one-based shared schedule from the match seed and current
  configured bounds. Every entry is `{health_bps_per_point,
  damage_bps_per_point}`; the complete schedule, ruleset hash, and schedule
  generation version are public to both players and bots and are retained in
  replay/setup data. Cumulative bonuses affect future cohorts only.
- Soldiers: cohort-based stacks preserve spawn quality and current health.
- Movement: active-player stacks advance at most one adjacent edge per own turn
  along queued paths; every executed edge is validated.
- Combat: deterministic seeded resolution with no unowned randomness.
- Walls: edge blockers start at 1000 HP and are permanently removed at zero.
- Capital capture: after resolution, an enemy-controlled capital eliminates its
  owner and transfers that player's controlled tiles to the capturer.
- Replay truth: only accepted commands enter history. Rejected inputs append a
  diagnostic only and never mutate gameplay state, source-sequence state, or
  canonical hash. `client_sequence` is a positive integer monotonically
  increasing per player (one command source per player in M1); it advances only
  when that player's command is accepted. Canonical state hashes and explicitly
  owned RNG streams establish deterministic reconstruction.
- Resume: persist atomically after every accepted command and reconstruct from
  setup plus commands, not by trusting a snapshot. Keep one active match and the
  latest completed replay; no manual slots/library.
- Bot fairness: bots receive a capability-limited observable snapshot under the
  same fog rules as the player and submit ordinary validated commands. Own
  stacks and economy are exact. A visible enemy stack exposes only its ID,
  owner, tile, and deterministic public strength band (`tiny`, `small`,
  `medium`, `large`, or `overwhelming`); it never exposes cohort data, exact
  soldiers/health/damage, queues, or intended destinations. Enemy economy,
  research, pending soldiers, hidden positions, hidden wall HP, and hidden
  events remain absent.
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
