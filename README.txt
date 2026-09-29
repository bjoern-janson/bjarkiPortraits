bjarkiPortraits 0.1.23-clean

Fresh runtime. The established spell-ID catalog is retained as data, but the
portrait engine was rebuilt from an empty implementation.

Visual contract:
- Blizzard frame chrome stays untouched in its native layer.
- The native portrait and secure aura replacement share one deliberately lower
  layer, so the aura reads as the portrait rather than as a sticker over it.
- Blizzard's own portrait mask is reused directly.
- ToT/FoT use the same primitive as the large frames, with only their accepted
  optical icon/timer offsets.
- Pet foundations are target/focus/PetFrame presentation only; they never run
  on ToT/FoT and have no access to AuraContainer state.

Commands: /bp help

Current architecture note: version entries below preserve the development history and may describe the intended policy of an intermediate build. ARCHITECTURE.md describes the actual current v0.1.17 code paths and known residual risks.


v0.1.1-clean
- Fixes hostile helpful relation gating: exact helpful spell-ID tiers are never enabled on hostile players.
- Restores opposite-faction helpful aura support with a two-path design:
  readable hostile identities use the tracked whitelist directly; restricted identities fall back to Blizzard's secure HELPFUL stream.
- Keeps portrait geometry, masks, parents, strata, timer offsets, and pet portrait layout unchanged from v0.1.0-clean.
- /bp debug now reports hostilePlayer, exactHelpful, hostileReadable, hostileCount, and hostileSpell.


v0.1.2-clean
- Adds an exact readable fallback for Resurrection Sickness (15007) on self/friendly units when Forever relation-gates the secure harmful spell-ID filter.
- The secure exact ResSickness tier remains authoritative wherever it is legal.
- No portrait geometry, mask, parent, strata, timer, pet portrait, or hostile-helpful logic changed from v0.1.1-clean.


v0.1.3-clean
- Fixes the v0.1.2 ToT/FoT regression.
- Resurrection Sickness readable fallback surfaces are now created only for player/target/focus.
- Target-of-target and focus-target host construction is restored to the v0.1.1 structure.
- No portrait geometry, masks, strata, timer offsets, hostile-helpful logic, or spell priorities changed.


v0.1.7-clean
- Fixes the actual ToT/FoT disappearance mechanism: native small-frame portraits are no longer reparented or reanchored.
- ToT/FoT secure aura hosts are children of Blizzard's native derived unit frames.
- The native TextureFrame chrome is kept above the PTF priority stack and its original frame level is restored on teardown.
- Large player/target/focus portrait behavior and v0.1.1 hostile-aura policy are unchanged.
- Resurrection Sickness readable fallback remains limited to player/target/focus.


v0.1.7-clean
- ToT/FoT visual repair only: adds an addon-owned circular icon mask when the current client exposes no native PortraitMask.
- Clones Blizzard's existing ToT/FoT chrome texture into an addon-owned top overlay so the native ring sits visually above portrait auras.
- No native ToT/FoT portrait, chrome, parent, points, visibility, or frame level is mutated.
- Aura admission/priority logic is unchanged from v0.1.4.


v0.1.8-clean
- Restores BaselineClass same-tier recency: the most recently applied or refreshed
  readable class buff replaces older buffs in the same tier.
- Uses application time (expirationTime - duration) only when timing is readable
  for every competing BaselineClass aura; otherwise falls back to newest
  auraInstanceID across the complete tier.
- If aura identity/timing becomes restricted, the readable override abstains and
  the secure BaselineClass AuraContainer remains authoritative.
- No portrait geometry, ToT/FoT offsets, masks, parents, strata, chrome, pet
  portraits, hostile-helpful policy, or spell priorities changed from 0.1.7.



v0.1.9-clean
- Adds a narrow player-only readable exact fallback for Welcoming Campfire (1229739).
- Keeps the existing secure WelcomingCampfire tier underneath as fallback.
- Adds welcomingReadable / welcomingActive fields to /bp debug.
- No portrait geometry, ToT/FoT offsets, masks, parents, strata, pet portraits,
  hostile-helpful policy, BaselineClass recency, or priority levels changed.


v0.1.10-clean
- Adds Mage Blink (1953) and the Forever Blink variant (1236175) to the existing Utility buff tier.
- No priority, aura admission, portrait geometry, ToT/FoT, or pet portrait behavior changed.


v0.1.11-clean
- Moves Demon Skin ranks 1-2 and Demon Armor ranks 1-5 into the exact same priority lane as Paladin auras.
- The shared lane is one unioned secure AuraContainer candidate pool, so same-tier recency is resolved within one container rather than by sibling-frame ordering.
- Removes Demon Skin/Demon Armor from the higher SelfState category to avoid duplicate membership.
- No geometry, ToT/FoT, hostile-aura, readable-fallback, pet-portrait, or timer logic changed.


v0.1.12-clean
- Moves Cannibalize (20577/20578), Rapid Regeneration (1260270), and Evocation
  (12051) into the existing FoodDrink priority lane.
- Moves Innervate (29166) into its own lane exactly one priority step above
  FoodDrink (261 vs 260), still below Utility (270).
- Removes Rapid Regeneration from Utility and Evocation/Innervate from Offensive
  so each spell has one canonical priority assignment.
- No portrait geometry, ToT/FoT behavior, hostile handling, or recency logic changed.


v0.1.13-clean
- Adds additional Forever/NPC Chilled aura IDs to the existing Slows lane:
  12484, 15850, 18101, 20005, and 1296223.
- Keeps 6136 and 7321.
- No priority, rendering, geometry, or admission logic changed.


v0.1.14-clean
- Adds visible NPC/Forever Frost Armor IDs 12544 and 15784 to SelfState.
- Expands readable hostile helpful scanning from hostile players to hostile NPCs,
  while keeping the broad secure hostile HELPFUL fallback player-only.
- Adds a narrow readable Slows fallback on player/target/focus when Forever
  relation-gates the secure exact harmful spell-ID filter.
- This allows NPC-applied Chilled variants to display on friendly/self portraits.
- No portrait geometry, ToT/FoT offsets, priority levels, or timer presentation changed.


v0.1.15-clean
- Fixes cross-relation secure admission for NeverSecret exact auras.
- Frost Armor and Chilled now have dedicated same-priority secure fallback lanes
  containing only IDs Blizzard classifies NeverSecret on the current client.
- Removes the old unconditional hostile-helpful exact-tier disable; all exact
  relation decisions now go through ExactFilterAllowed.
- Readable out-of-combat fallbacks remain unchanged and still abstain when aura
  identity becomes inaccessible in combat.
- /bp debug now prints NeverSecret classification for the known Frost Armor and
  Chilled IDs.
- No portrait geometry, ToT/FoT placement, priority level, or timer changes.


v0.1.16-clean
- Replaces the ineffective NeverSecret exact fallbacks for NPC Frost Armor and
  Chilled after live testing proved all relevant IDs are combat-secret.
- Adds a secure non-identity Frost Armor signature for hostile NPCs:
  helpful Magic, <=30 min, stealable, non-player source. It is enabled only when
  the readable exact hostile-NPC path disappears.
- Adds a secure non-identity Chilled signature for the 12544 -> 6136 proc:
  harmful Magic, <=5.1 sec, nameplate-personal, non-player source. It is enabled
  only when exact/readable Slows identity is unavailable.
- No portrait geometry, priority levels, ToT/FoT behavior, or timer changes.


v0.1.17-clean
- Removes the isStealable=true requirement from the combat-safe hostile-NPC
  Frost Armor signature. Live testing proved the lane was enabled but 12544
  still failed the previous signature.
- Frost Armor fallback remains restricted to hostile NPCs with sealed readable
  identity, helpful Magic auras, <=30 minute duration, and non-player/pet source.
- Chilled combat signature is unchanged.
- No portrait geometry, priority levels, ToT/FoT behavior, or timer changes.


v0.1.18-clean
- Fixes the local PetFrame custom pet-family foundation draw order.
- The custom icon now renders below Blizzard's native BORDER chrome.

v0.1.19-clean
- Adds SmallFriendlyHarmful at priority 189 for readably assistable ToT/FoT.
- Adds assistReadable / assistable diagnostics.

v0.1.20-clean
- Welcoming Campfire now queries C_UnitAuras.GetPlayerAuraBySpellID(1229739) first.
- Adds welcomingDirect diagnostics.

v0.1.21-clean
- Moves Elemental Blessing (1259688 / 1270893) into the same priority-10 candidate pool as Plainsrunning.

v0.1.22-clean
- Adds Walk on Air (1259416 / 1308663) to Utility.


v0.1.23-clean
- Welcoming Campfire now uses HELPFUL|INCLUDE_NAME_PLATE_ONLY in both the secure lane and indexed readable fallback.
- Direct GetPlayerAuraBySpellID lookup no longer suppresses the indexed fallback when it returns no usable aura.
- Frost Armor, Chilled, and Weakened Soul semantic approximations are gated behind stronger exact/readable evidence instead of running in parallel everywhere.
- Rapid Regeneration (1260270) moves from FoodDrink to Utility.
- Forbearance, Resurrection Sickness, and Honorless Target now each have one canonical category assignment; the malformed cross-polarity Forbearance set is removed.
- UNIT_AURA no longer forces UpdateAllAuras on every enabled priority container; explicit full refresh is retained for target/focus/relation lifecycle changes where the unit token's referent or authorization can change.
- Portrait teardown/reparent restoration is deferred out of combat, including slash-command destruction paths.
- Readable overlays abstain rather than showing a stale previous icon if spell texture lookup fails.
- Warlock pet foundations now have name-based artwork fallbacks for Imp/Voidwalker/Succubus/Incubus/Felhunter/Infernal/Doomguard.
