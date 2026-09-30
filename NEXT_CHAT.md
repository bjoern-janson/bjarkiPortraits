# Next-chat handoff

This file is the continuation point for the next bjarkiPortraits session.

## Current repository state

- Repository: `bjoern-janson/bjarkiPortraits`
- Current source: **v0.1.47-clean**
- Runtime/source checkpoint before handoff-only documentation commits: `e0aef4ef99b57eaac0163a92e4e37227c4cb915a`
- Companion UI repository: `bjoern-janson/bjarkiUI`
- Companion current source: **v0.2.20-ultralight**
- Companion runtime/source checkpoint before documentation: `6bfb30f185c9c95634b4be8e02c416e3c567e833`

Do not reconstruct old PortraitTimersForever architecture. Continue from the current secure/readable two-plane engine.

## Current architectural invariants

- One conceptual priority should map to one actual secure lane whenever possible.
- Exact readable evidence outranks approximation when readable.
- Secure exact AuraContainer filtering is used when relation/secret rules permit it.
- Semantic fallback is allowed only when exact identity is unavailable and the metadata signature is explicitly justified.
- Inaccessible or secret state is never silently treated as false/absent.
- Same name/icon is not enough to claim same spell identity.
- Same gameplay mechanic *is* grounds for putting verified alternate/NPC/Forever IDs into the same exact family.
- High-frequency unit events must stay scoped to owned unit tokens; do not reintroduce global `UNIT_AURA`, `UNIT_TARGET`, `UNIT_FLAGS`, etc.
- Do not use `unitAuraUpdateInfo.isFullUpdate`; older PTF builds hit secret-boolean taint there.
- Structural destroy/rebuild remains combat-safe.

## v0.1.47 source checkpoint

- Utility/Welcoming Campfire now has one winner contract: the readable Campfire surface can suppress secure Utility only after a complete readable Utility-family election proves Campfire is the AuraInstanceID winner.
- Control 310 excludes every Stun 320 spell ID; the prior 34-ID exact-lane overlap is gone.
- PLAYER_TARGET_CHANGED owns the player's outer target refresh; UNIT_TARGET now handles only target/focus-derived ToT/FoT rebinding.
- UNIT_AURA no longer triggers observed-pet classification. Pet foundations refresh only on referent/relation changes and only for the affected observed token.
- Observed pet classification prefers positive UnitIsOtherPlayersPet evidence and performs at most one creature-family lookup per classification.
- Empty target/focus/derived hosts stay pre-created for combat safety but their aura policy is dormant until UnitExists is readable and true.
- Secret-value ordering was hardened in direct Campfire/duration/pet-texture paths.
- Do **not** begin the large spell-equivalence expansion until this checkpoint has a live pass.
- Next architectural candidate after that pass: consolidate 44 per-host AuraContainers into filter-string cohorts/AuraSlots; keep it separate from this correctness checkpoint.

## Current priority spine

Higher numbers visually outrank lower numbers.

```text
1    Small friendly harmful fallback
10   Plainsrunning
20   Boosted Rest
30   Campfire Nearby
50   Travel Utility
59   Righteous Fury
60   Paladin Auras + Demon Skin/Armor + Stoneskin + Healing Stream
70   Blood Pact
80   Scrolls
90   BaselineClass + Camp Benefits
110  Well Fed
120  Thorns
130  Elemental Shields
150  Self State + Frost Armor semantic band
160  Mobility
170  Lone Wolf
180  Hunter's Mark
190  DoTs
200  low debuffs
210  Seals
220  Slows + Chilled semantic band
230  Weakened Soul
238  generic priority debuff
240  Forbearance
241  Resurrection Sickness
242  Honorless Target
250  Power Word: Shield
260  Food / Drink / Cannibalize / Evocation
261  Innervate
270  Utility / Rapid Regeneration / Welcoming Campfire
279  Blizzard Important
280  Offensive
288  External Defensive
289  Big Defensive
290  Defensive
300  Roots
309  Blizzard Crowd Control
310  explicit Control
320  Stuns
330  Immunities
```

There are currently 44 implementation lanes.

## Recent live findings that matter

### Welcoming Campfire

Two live aura IDs were directly observed via
`C_UnitAuras.GetAuraDataBySpellName("player", "Welcoming Campfire", "HELPFUL")`
at different campfires:

- `1229739`
- `1289723`

Both are 60-second Welcoming Campfire auras.

Current implementation:

- both IDs are in `buffs_welcoming_campfire`;
- Welcoming Campfire is Utility priority 270;
- Utility and Welcoming Campfire are merged into **one secure priority-270 AuraSlot**;
- the special readable Campfire witness remains for Forever compatibility;
- while that readable witness is rendering, the secure Utility slot is suppressed so two cooldown widgets cannot stack.

This was the v0.1.44 double-timer repair.

### Camp Benefits / Well Fed

- Camp Benefits `1229741` is now part of **BaselineClass at 90**, not its own lane.
- BaselineClass unions `buffs_class_baseline` and `buffs_camp_benefits`, so Camp Benefits participates in the same readable newest-application/refresh election.
- Well Fed is priority **110**, directly above the Class Buff band and below Thorns.
- Low-level Well Fed `1248406` (+1 Stamina variant observed live) was added to the Well Fed family.

### Frost Armor / Chilled NPC mechanism

Live observations:

- Scarlet Initiate Frost Armor: `12544` out of combat.
- Its Chilled proc: `6136`.
- Exact identity becomes unavailable in combat.
- Current secure metadata-signature fallback for hostile NPCs has live-passed for both Frost Armor and Chilled.

Do not broaden semantic identity casually; prefer adding exact alternate IDs where they are actually exposed.

### NPC Frostbolt coverage

The Slows family currently contains ordinary player Frostbolt ranks plus these Forever/NPC variants:

- `21369`
- `350025`
- `420526`
- `1303226`

The anomalous `406680` variant was deliberately excluded because its published movement-speed effect did not match ordinary Frostbolt semantics.

The motivating live case was **Windfury Sorceress** casting Frostbolt where the slow did not initially show.

## Next major task: exhaustive mechanical-equivalence taxonomy audit

The user explicitly wants the addon to stop discovering equivalent NPC/Forever IDs one screenshot at a time.

Target policy:

```text
tracked mechanic
  -> player ranks
  -> NPC ranks
  -> creature/script variants
  -> Forever-specific variants
  -> alternate applied-aura IDs
```

Add an ID to an existing exact family only when its **applied gameplay mechanic is equivalent**, not merely because its name/icon matches.

### Recommended workflow

1. Inventory every exact family in `Spells.lua` (currently 43 categories).
2. Establish a reproducible current-Forever spell-data source before mutating taxonomy.
   - Client DB2 / wago.tools current 1.60.x data was identified as a promising route in the prior chat, but the ingest/audit was **not completed**.
3. For each tracked seed ID, derive the relevant effect/aura signature:
   - aura type;
   - duration where semantically relevant;
   - movement modifier / root / stun / periodic damage / stat modifier / immunity / etc.;
   - helpful vs harmful;
   - applied-aura identity if different from cast spell.
4. Enumerate alternate IDs with the same mechanic.
5. Classify candidates:
   - **exact-equivalent** -> add to existing family;
   - **mechanically different** -> exclude, even if same name;
   - **unknown/ambiguous** -> leave out and record for live verification.
6. Keep an audit ledger in the repo rather than silently adding hundreds of IDs. Suggested columns:
   - family;
   - seed ID;
   - candidate ID;
   - source/name;
   - effect signature;
   - disposition;
   - reason/evidence.
7. Prefer data-only `Spells.lua` changes. Do not create new semantic lanes for variants that can simply join an existing exact family.
8. After each large batch, run duplicate-family and priority-lane audits before shipping.

The first full family to use as a calibration case should be **Frostbolt/Slows**, since it already has confirmed player/NPC variants and one known anomalous same-name exclusion.

## Live-tested performance state

bjarkiPortraits:

- high-frequency `UNIT_AURA`, `UNIT_FACTION`, `UNIT_FLAGS`, `UNIT_CONNECTION`, and `UNIT_TARGET` handling is scoped with `RegisterUnitEvent` to the five owned portrait tokens;
- a dense Booty Bay live check after that change no longer reproduced the earlier reported lag.

Companion bjarkiUI v0.2.19:

- other players' combat pets now use stock green health bars via positive `UnitIsOtherPlayersPet` evidence plus the local-pet path;
- global `UNIT_TARGET`, `UNIT_DISPLAYPOWER`, and `UNIT_NAME_UPDATE` subscriptions were replaced with unit-scoped subscriptions to the six unit tokens bjarkiUI paints.

## Implemented but not yet explicitly live-confirmed after the latest build

Treat these as tests to perform, not as established facts:

- v0.1.44: double Utility/Campfire cooldown should be gone after merging priority 270 to one secure slot.
- v0.1.45: Windfury Sorceress / equivalent NPC Frostbolt slow should now render through the expanded Slows family.
- v0.1.46: Camp Benefits should behave exactly like a Class Buff at priority 90 and join BaselineClass recency.
- bjarkiUI v0.2.18/v0.2.19: pre-engagement target/focus red threat ring attenuation has not yet been explicitly confirmed after the pair-state fix.
- bjarkiUI v0.2.19: universal green health bars for other players' pets have not yet been explicitly confirmed.
- bjarkiUI v0.2.19: populated-city hitching should be rechecked after scoping the remaining noisy UNIT_* presentation events.

## Things not to casually change

- accepted ToT/FoT portrait/timer optical offsets;
- portrait crop/zoom;
- pet portrait foundations;
- timer decimal behavior;
- class-health color treatment;
- existing Frost Armor/Chilled semantic fallback;
- priority numbers outside an explicit user request;
- event scoping/performance protections.

## Useful live-debug tools

- `/bp test`: synthetic rendering surface only.
- `/bp debug`: relation/readability/admission/winner state.
- For unknown visible auras, direct client dumps such as:
  `/dump C_UnitAuras.GetAuraDataBySpellName("player", "Aura Name", "HELPFUL")`
  have been more reliable than assuming public spell IDs.

## First message for the next chat

A good continuation prompt is:

> Read NEXT_CHAT.md and current Spells.lua/Priority.lua/AuraEngine.lua first. Continue the exhaustive mechanical-equivalence taxonomy audit, starting with Frostbolt/Slows as the calibration family. Do not mutate the taxonomy until the data-source/equivalence rule is explicit and auditable.
