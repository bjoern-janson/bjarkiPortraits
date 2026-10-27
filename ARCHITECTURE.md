# bjarkiPortraits architecture

**Pending evidence recovery (2026-10-27):** `0.1.156-fixes-test` retries retained derived snapshots when faction/flag events restore eligibility, including player-wide relation changes. Section 31 describes this event-routing repair.

**Priority handoff and derived evidence repairs (2026-10-27):** `0.1.155-fixes-test` keeps the generic helpful lane eligible above lower informational helpers and delivers later readable timing through bounded, coalesced derived snapshots. Section 30 describes these repairs; section 29 remains authoritative for spell classifications and numeric priorities.

**Priority scope correction (2026-10-27):** `0.1.154-priority-scope-correction-test` restores Roots 300, Slows 278 and Dazed 279 to their pre-overhaul levels. Their lowering in v0.1.153 was unauthorized. Will of the Forsaken (7744) is removed from all portrait aura categories because the user's direct Forever test observed **no applied buff**; a cast-only effect must not be invented as a visible immunity. Section 29 is authoritative and corrects erroneous conclusions in section 28.

**Previous priority consolidation (2026-10-27):** `0.1.153-priority-consolidation-test` merged requested aura categories and added guarded complete-aura elections for stuns and silences. It also introduced **unrequested root/slow reprioritization and an incorrect Will of the Forsaken aura assumption**, both corrected in section 29. The separate Pounce bleed remains a DoT. No new periodic polling or native-layout writes.

**Five-second decimal threshold restored (2026-10-26):** `0.1.152-five-second-decimals-test` restores one-decimal portrait aura countdowns below five seconds when `/bp decimals` is enabled (whole seconds at five and above). Both the native formatter breakpoint and compatibility fallback threshold are updated together. Section 27 supersedes the three-second policy in section 25.

**Low-priority informational tiers (2026-10-26):** `0.1.151-low-priority-tracking-status-test` restores explicitly requested gathering buffs, informational debuffs, and tracking/sensing buffs in three separate exact lanes immediately above the race-portrait foundation. No combat-priority changes. Section 26 supersedes the earlier exclusion-only tracking/Boosted Rest policy.

**v16 suite update (2026-10-22):** this addon receives release-version metadata only. Its behavior is byte-identical to v15 apart from that version string. The three timing repairs are in bjarkiCC Model/Observer. The full v16 suite passes 49 regression scripts and 28 runtime syntax checks on both Lua 5.1 and Lua 5.4; live-client findings below retain their existing status. The behavior described in architecture section 25 remains applicable.

This document tracks **bjarkiPortraits 0.1.156-fixes-test** (2026-10-27). Sections 1–28 are historical architecture and experiment notes; **section 29 corrects the unsolicited priority changes and the Will of the Forsaken aura assumption**. This reference does not claim undocumented guarantees about the WoW: Forever client.

The runtime is split into nine Lua modules, loaded in this order:

- `Spells.lua` — spell-ID category tables.
- `Core.lua` — settings, unit/portrait lookup, value-access helpers, relation checks, race artwork, timer formatting.
- `SharedEvidence.lua` — bounded shared bus for readable positive helpful-aura observations.
- `EvidencePublisher.lua` — guarded aura-event publication and derived-unit snapshots.
- `Priority.lua` — display lanes and priority levels.
- `AuraEngine.lua` — portrait hosts, secure aura containers, readable fallbacks, rendering, lifecycle.
- `PetPortraits.lua` — pet-family artwork under portrait aura layers.
- `Commands.lua` — `/bp` commands and debug output.
- `Main.lua` — event registration and refresh routing.

`ARCHITECTURE.md` is not loaded by the game.

## 1. What the addon displays

The addon uses the native portrait area of five unit frames:

- `player`
- `target`
- `focus`
- `targettarget`
- `focustarget`

The intent is to show one high-priority aura/state over each portrait while keeping Blizzard's surrounding frame art and unit data.

The local PetFrame and observed pet portraits can also receive pet-family foundation artwork. That artwork is separate from aura selection.

## 2. Spell data and display priorities

`Spells.lua` contains plain spell-ID membership tables. It does not perform runtime discovery.

`Priority.lua` converts those categories into ordered display lanes.

Two lane types are used:

- **exact lanes** — include explicit spell IDs;
- **semantic lanes** — use Blizzard aura-filter metadata such as crowd-control, important, defensive, duration, or dispel type.

Categories that are meant to compete at the same priority are unioned before the lane is built. This matters because a shared lane gives Blizzard one actual candidate election rather than two independent frames that happen to have the same numeric level.

Examples in the current build include:

- Plainsrunning + Elemental Blessing;
- Paladin aura + Warlock armor;
- baseline class buffs + camp benefits;
- Slows + Chilled exact IDs;
- Innervate + Druid Enrage;
- Utility + Welcoming Campfire;
- Faerie Fire/Curse-of-Weakness-style low debuffs + taunts.

Current nearby harmful priorities include:

- Demoralizing Shout/Roar: 185
- DoTs: 190
- low debuffs / taunts / Faerie Fire: 200
- Slows: 220
- Roots: 300
- Control: 310
- Stuns: 320
- Immunities: 330

The helpful `Divine Protection` aura uses its own tier 331, above Forbearance and the shared Immunity lane.
The helpful `Waiting to Resurrect` aura uses tier 332, above the state-derived Ghost frame.
Honorless Target uses helpful tier 257, above the Healing/HoT tier 255.

The numeric level is used as a portrait display priority, not as a general statement about spell strength.

## 3. Secure aura containers

Each portrait host creates Blizzard `CustomAuraContainer` instances for the configured lanes.

Exact lanes supply explicit spell-ID inclusion sets. Semantic lanes supply broader Blizzard candidate filters.

Within a lane, aura ordering uses:

- `AuraInstanceIDOnly`
- reverse sort direction

This lets the native aura container choose among candidates on that lane.

The addon does not run a general Lua loop every frame to update cooldowns. Cooldown progression and most aura-slot work are left to Blizzard widgets/containers.

## 4. Exact-filter availability

Forever does not expose every aura identity in every relation in the same way.

`Core.lua` therefore separates:

- whether a value can be read;
- whether the unit relation is readable;
- whether an exact helpful/harmful spell-ID filter is allowed for that relation;
- whether a spell family is explicitly known as NeverSecret.

`ExactFilterAllowed()` currently permits exact filtering through several paths, including:

- helpful auras on the player;
- helpful auras on positively identified controlled/group units;
- readable assist relation;
- selected lanes whose entire configured spell-ID family is known NeverSecret.

If the required relation value is unreadable, that path does not grant exact filtering.

## 5. Readable fallback paths

Some states use Lua-readable aura/state information when an exact secure lane is not available or when a more specific local election is useful.

Current examples include:

- baseline class-buff recency;
- hostile helpful aura handling;
- Slows on self/friendly units;
- Resurrection Sickness;
- Recently Bandaged;
- Boosted Rest;
- Welcoming Campfire;
- Ghost through `UnitIsGhost`.

These are separate paths rather than one universal scanner because they need different evidence and fallback behavior.

Most indexed scans are bounded and stop when the exposed aura stream terminates.

## 6. Portrait hosts and layering

A host records the native portrait, its original parent/points, the addon presentation layer, aura containers, cooldowns, and readable fallback frames.

For the larger player/target/focus frames, the addon creates a lower presentation layer and reparents the native portrait while preserving its geometry. Native frame chrome remains above the addon artwork.

The small ToT/FoT frames use separate geometry offsets:

- ToT icon: +2 X; timer centered with -1 Y
- FoT icon: +1 X; timer +1 X / -1 Y

The small-frame timer font is reduced by two points.

On destruction, containers are disabled/hidden, owned overlays are hidden, and the native portrait parent/points are restored when possible.

## 7. Lifecycle and combat

Structural frame changes are avoided while in combat.

If a rebuild or destruction is requested during combat, the addon records pending work and finishes it after `PLAYER_REGEN_ENABLED`.

The global `enabled` setting is checked at host-creation and refresh boundaries. When the addon is off, later target/focus/unit events should not recreate portrait hosts.

Pet artwork also checks the global enabled state.

This keeps `/bp off` from immediately restoring presentation through a later event.

## 8. Pet portrait foundations

`PetPortraits.lua` does not own aura containers.

It identifies local or observed Hunter/Warlock pets through the unit APIs and creature-family information available on the client, then chooses a family/summon texture when possible.

Observed pet textures live on the host's portrait layer. The local PetFrame uses a separate texture placed under the native border/chrome.

Pet art can be toggled independently with `/bp pets`, but the global addon-off state also hides it.

## 9. Timer presentation

Cooldowns use Blizzard's `CooldownFrameTemplate`.

Default timer behavior is:

- below 10 seconds: one decimal;
- 10 through 60 seconds: whole seconds;
- above 60 seconds: no numeric timer.

`/bp decimals` toggles the sub-10-second decimal behavior.

`/bp swipe` toggles the cooldown swipe.

The addon configures Blizzard's formatter rather than running its own per-frame countdown calculation.

## 10. Commands

Current commands include:

- `/bp on`
- `/bp off`
- `/bp player`
- `/bp target`
- `/bp focus`
- `/bp tot`
- `/bp fot`
- `/bp swipe`
- `/bp decimals`
- `/bp pets`
- `/bp test`
- `/bp debug`
- `/bp reset`

Test mode is primarily a presentation/geometry check.

Debug output exposes selected host state, relation/readability flags, and readable-election information.

## 11. Event model

`Main.lua` routes broad lifecycle events such as login/world entry, target/focus changes, death/ghost transitions, pet changes, and leaving combat.

High-frequency unit events are scoped to the five tracked tokens with `RegisterUnitEvent`.

`UNIT_TARGET` is registered only for target/focus because those are the outer units that can rebind ToT/FoT.

Ordinary `UNIT_AURA` refreshes the affected host without always forcing every secure container to rebuild; relation/referent changes can request a stronger refresh.

There is no addon-owned `OnUpdate` polling loop.

## 12. Protected and secret values

Forever can return secret or inaccessible values from aura/unit APIs.

The current implementation uses helpers such as:

- `IsSecret`
- `CanAccess`
- `SafeBool`
- `SafeString`
- `ReadAuraField`

before many comparisons or field reads.

Where exact identity is unavailable, the addon may keep a broader secure lane, use a narrower readable fallback, or show nothing, depending on the path.

These rules reflect the current code and observed client constraints; they should be rechecked when Blizzard changes the underlying APIs.

## 13. Practical maintenance rules

The current implementation is easiest to keep stable when:

- spell data stays in `Spells.lua`;
- display priority/election stays in `Priority.lua`;
- categories that truly share a priority also share one actual lane;
- new spell IDs are added by applied aura ID rather than display name alone;
- structural frame work remains out of combat;
- off-state checks remain present at every host/pet creation boundary;
- secret/inaccessible values are checked before comparison or arithmetic;
- docs and other non-runtime files remain outside the `.toc` load list.


## 14. Cleanup notes

The current build keeps the existing spell taxonomy, priority elections, access checks, lifecycle guards, and timer policy. A small cleanup pass removes unused wrappers and duplicate readable-frame setup, and avoids reading container enabled state during ordinary refreshes when that value is not used. These changes do not alter the configured spell ownership or lane order.


## 15. Bloodrage

Version 0.1.63 adds the Forever Warrior Bloodrage aura (spell ID 29131) to the
same priority-261 secure lane as Innervate and Druid Enrage. All three effects
therefore use one shared within-lane recency election rather than independent
equal-priority frames.


## 16. Immutable priority indexes and audit

Version 0.1.64 derives two immutable lookup indexes once from `R.TIERS`:
`TIER_BY_KEY` and `HELPFUL_TIER_BY_SPELL`. AuraEngine uses these indexes for
ordinary tier lookup while retaining the old linear scan as a defensive
load-order fallback. Priority levels, candidate filters, secure containers, and
winner election semantics are unchanged.

The same derivation records exact-lane membership and overlap diagnostics.
`/bp audit` reports version/enabled state, exact-lane counts, duplicate spell-ID
ownership if any, and bounded host/readability state. The command is read-only:
it does not rebuild, repair, refresh, or mutate presentation.


## 17. Evidence-boundary hardening

Version 0.1.65 tightens the runtime boundary between observation, warrant, and
presentation without changing the configured priority ladder.

- `UnitExists` is never truth-tested directly. Existence now has an explicit
  readable/UNKNOWN state, and exact-filter authorization fails closed when that
  witness is unavailable.
- hostility has an explicit tri-state evidence path. UNKNOWN relation state is
  retained for diagnostics instead of being represented as a negative fact.
- readable same-tier elections no longer synthesize `auraInstanceID = 0` when
  native ordering evidence is inaccessible. A single candidate remains
  displayable; multiple candidates require a readable ordering witness.
- baseline-buff recency likewise refuses an unresolved equal-time tie when the
  native instance ordering is unavailable.
- hostile readable selection suppresses the broader secure fallback only when
  the visible identity stream is complete and any same-tier winner is actually
  warranted.
- hiding a readable hostile fallback clears its cooldown as well as the icon, so
  stale presentation state cannot survive revocation.
- the bounded Lua aura scan budget is defined once as `AURA_SCAN_LIMIT`.

The operative rule is: **absence, identity, ordering, and relation are distinct
facts**. An inaccessible fact must not be converted into a convenient default
merely to keep presentation deterministic.


## 18. Level-30 beta aura coverage

Version 0.1.66 migrates the level-30 beta aura coverage into the current
runtime while preserving the newer evidence-boundary and Bloodrage work.

The migration adds 218 new exact spell IDs and two exact lanes:

- HealingOverTime: 255, helpful
- ClassAura: 295, helpful

The source coverage artifact contained 219 new IDs. Spell ID 29131 (Bloodrage)
was already owned by the current buffs_bloodrage category and shared
Innervate's priority-261 lane, so that ownership is preserved rather than
moving Bloodrage into ClassAura.

The migrated coverage is derived from static client/database evidence. It does
not establish live Forever aura visibility for every ID. Static membership is
treated as coverage data, not as a live-visibility guarantee.

The migration leaves the existing semantic lanes, readable fallbacks, secret
value guards, and priority-election mechanics unchanged.


## 19. Reported Battleground gaps

These are user-reported outcomes from recent Battleground sessions, recorded
2026-10-08. They are open validation items for 0.1.80-local: this source update
has not been exercised in a live client, so it does not establish that they are
fixed or identify a single root cause.

- Friendly and enemy Hunter/Warlock pet portraits fail or show incorrect
  artwork in Battlegrounds. Hunter pet artwork had worked outside a
  Battleground in an earlier report. Warlock pets have also been reported with
  an unexpected Growl icon.
- Opposing-faction aura display in Battlegrounds has category-level
  prioritization/eligibility failures. The reported expectations include
  Drink above DoTs and Honorless Target above healing-over-time effects; other
  examples are low-priority water utility or Leader of the Pack surfacing too
  high, and Blessing of Freedom, Stoneform, or Divine Protection not
  surfacing. Treat these as evidence about category election/eligibility, not
  as a list of isolated spell-ID patches. Water Breathing belongs near the
  bottom with other water utility.
- An enemy Healing Stream Totem was reported with a white portrait and no
  visible aura, where red hostile coloring and its aura were expected.
- ToT/FoT aura artwork was reported protruding past the small-frame border.
- Version 0.1.71 produced a secret-value error when testing
  `updateInfo.isFullUpdate` on Battleground entry. The current source adds
  guarded access around aura-update metadata, but this remains a live-client
  verification item.

When investigating these reports, preserve the separation between readable
identity/relation evidence, exact-filter authorization, native secure-lane
candidate election, and visible presentation. Do not infer that one layer is
working because another layer displays an icon.

## 20. Current committed source: 0.1.105-local (2026-10-12)

**Provenance:** Source is taken verbatim from `bjarkiPortraits-0.1.105-local.zip` (ZIP SHA-256 `662cf14dcf470d99557fd50eea3b4ae26d998807e8c1cb8d5159a814f4568cba`). Both matching manifests load exactly seven Lua modules: `Spells.lua`, `Core.lua`, `Priority.lua`, `AuraEngine.lua`, `PetPortraits.lua`, `Commands.lua`, and `Main.lua`. Old reports in `KNOWN_ISSUES.md` stay open until independently retested, regardless of whether newer source code changed the implicated path.

### 20.1. Timer geometry and accepted visual calibration

- Portrait hosts are `player`, `target`, `focus`, `targettarget` (ToT), and `focustarget` (ToF); a priority-selected aura or state is drawn over each portrait. The unit-frame geometry, including compact chrome, remains owned by Blizzard/bjarkiUI, not the timer engine.
- The tested 1920×1080 countdown comparison found the Player timer text about one physical pixel high relative to Target, while the ToT/ToF compact countdowns were about one pixel low. Optical centering must be checked against visible glyph bounds, not just text-region coordinates.
- `AuraEngine.lua` now uses the accepted **Player-only `offsetY = +0.5` UI units** relative to the large-frame timer path. Target and Focus keep their default timer placement. Compact ToT/ToF use `timerY = 0` (previously `-1`), with the compact `iconX = 1`, `iconY = 0`, and `timerX = 1` positions unchanged.
- The live-calibration `/bp timery` facility from the intermediate 0.1.104 test build was **removed entirely**. No calibration cache, temporary command, or speculative UI-scale threshold remains in 0.1.105. The final offset was judged from matching countdowns and pixel-row comparison, not a promise of perfect rendering on every scale.

### 20.2. Source ownership, privacy, and taint boundaries

- `Spells.lua` owns spell-ID/category membership; `Priority.lua` handles priority election/ordering; `AuraEngine.lua` owns visible portrait updates, cooldown text, and secure/readable aura paths; `Core.lua` owns shared state and safe value helpers; `PetPortraits.lua` handles pet portrait art; `Commands.lua` exposes supported diagnostics; `Main.lua` wires refresh events.
- Aura observation and display authorization are distinct: known spell IDs or readable information do not automatically authorize one to replace the native secure aura lane. The addon must preserve secure/protected client boundaries, treat secret results as UNKNOWN rather than false, and avoid inferring enemy class/pet identity from apparent artwork.
- ToT/ToF are reusable frame surfaces. On retarget/rebind, both visual state and selected aura must be checked against the **current referent**, not a previous unit. The border/portrait clipping concerns recorded in older versions remain separately documented.
- User feedback on conflicting spell priorities, missing opposing-faction auras, and pet rendering in Battlegrounds is not equivalent to a verified causal diagnosis. Keep category election, exact secure filter eligibility, relation/identity evidence, and native visibility separate when auditing.

### 20.3. Verification and next checks

- **Validated for this repository update:** nine ZIP members, matching `0.1.105-local` manifests, Lua parser success for all seven sources, absence of `/bp timery`, and exact Git blob hashes matching the packaged files.
- **Live visual evidence:** large and compact portrait timer alignment was checked in user screenshots at a 1920×1080 configuration; this is a scoped optical result, not a universal pixel guarantee or exhaustive taint/combat/dungeon/Battleground test.
- Preserve the verified timer geometry and spell priorities unless a new reproducible screenshot plus code-path observation warrants changing them. Prefer out-of-combat reversible experiments with one variable at a time; remove temporary calibration mechanisms before releasing an accepted build.

## 21. Current synchronized source: 0.1.106-local (2026-10-15)

### 21.1 Provenance and exact source scope

- Source: `bjarkiPortraits-0.1.106-local.zip`; archive SHA-256 `20f8c5465878fc6d9134ac79c7565b92f34aee5c2335abce6cd0a4f88484cc20`.
- The manifests declare seven modules in the same order: `Spells.lua`, `Core.lua`, `Priority.lua`, `AuraEngine.lua`, `PetPortraits.lua`, `Commands.lua`, `Main.lua`.
- Relative to `0.1.105-local`, only `Spells.lua`, `Core.lua`, `Priority.lua`, and the two manifests differ. The other four Lua modules are byte-identical to repository `main`. Treat this as a focused data/policy synchronization, not a new aura-engine release.

### 21.2 Tracking is now non-display, including broad fallbacks

- The `buffs_tracking` set remains a named spell-ID **denylist**, not a visible priority tier. `Priority.lua` removes its exact tracking/scouting lane.
- The hostile-helpful broad semantic lane explicitly sets `excludeSpellIDs=C.buffs_tracking`. The tracking set also enters the helpful explicit exclusion index for `Important`, `ExternalDef`, and `BigDef` fallbacks. This matters on hostile players, where an exact categorized identity may not be readable even though a broad helpful aura is visible.
- Covered examples include Track Humanoids, Track Beasts/Hidden/Undead/Elementals/Demons/Dragonkin/Giants, Find Herbs/Minerals/Treasure/Fish, Sense Demons/Undead, and other scouting/channel effects enumerated in `Spells.lua`.
- This is a **portrait-selection** policy. It does not cancel gameplay tracking buffs, suppress Blizzard's own buff frames, or authorize guessing hidden aura identities.

### 21.3 Hunter Trueshot Aura ranks and evidence discipline

- The class-aura category recognizes Forever ranks `1299346`, `1299348`, `19506`, `20905`, and `20906`. Earlier rank-1-only recognition could leave an otherwise important Trueshot Aura unclassified in the finite spell-ID mapping.
- The original field observation was a hostile Hunter portrait showing Track Humanoids over Trueshot Aura. Its cause could involve both insufficient exact rank coverage and a broad hostile-helpful fallback. The paired change addresses the explicit known mechanisms but **has not been exhaustively validated in an opposing-faction combat encounter**.
- A secret, unavailable, or relation-restricted identity must remain UNKNOWN; a heuristic display fallback must not pretend to identify a specific aura. Maintain the existing secure-host/readable-evidence split and the last-applied-within-a-lane rule only when the full readable election permits it.

### 21.4 Remaining verification

- Test a hostile Hunter with every observed Trueshot rank and tracking aura under combat restrictions; confirm that excluded tracking does not occupy the portrait, and separately verify Trueshot when its identity is actually available to the runtime.
- Check ToT/ToF recycled units, pet portraits in group content, safe combat event sequences, and timer/priority behavior without claiming a full taint proof from syntax checks or mocks.
- The `KNOWN_ISSUES.md` Battleground reports remain independent open client observations until reproduced or resolved with concrete runtime evidence.

## 22. Portrait countdown decimals: 0.1.107-local (2026-10-15)

This is a focused timer-only release. With the existing `/bp decimals` preference **on**, the portrait cooldown formatter displays one decimal below **5 seconds** (previously below 10), displays whole seconds from 5 through 60 seconds, and keeps its empty format above 60 seconds. With decimals **off**, all displayed countdowns remain whole seconds.

`Core.lua` updates both `C_StringUtil.CreateNumericRuleFormatter():SetBreakpoints` from threshold 10 to threshold 5 and the `Cooldown:SetCountdownMillisecondsThreshold` compatibility fallback from 10 to 5. The 60.000001 hidden-timer breakpoint, timer geometry, user setting, spell priorities, event hooks, and secure aura-container selection remain unchanged.

Both manifests now say `0.1.107-local`; the seven runtime modules and their load order are unchanged. The seven Lua sources passed Lua 5.4 syntax parsing, and a Lua mock test checked both formatter modes plus the 5-second/zero-threshold fallback. This is source-level validation, not in-game combat, visual, or taint certification.

## 23. Post-patch source synchronization: 0.1.130-form-state-test (2026-10-17)

This commit advances GitHub `main` directly from `0.1.107-local` to the **exact tested 0.1.130 ZIP source**, incorporating intermediate experimental revisions 0.1.108–0.1.129. There is no attempt to reconstruct the intermediate local-only commits. The 7 Lua modules and 2 TOCs match the accepted ZIP byte-for-byte. `bjarkiUI` is a separate repository and is not modified by this sync.

### 23.1 Secure selection, read permissions and lifecycle

- The five hosts remain Player, Target, Focus, Target-of-Target, and Focus-of-Target, using native CustomAuraContainer slots plus narrowly authorized readable presenters. Native aura access restrictions are not bypassed. Missing, secret, and erroring aura scans are distinct states; absent readable evidence must never be presented as a definite spell identification.
- Host construction now registers **only completed hosts**, and helper frames opt into the necessary addon layout restrictions. The partial-build error observed with Ghost and Silithid Pox was reproduced and repaired. Ghost and the sickness helpers returned in the live client; this does not certify every combat transition.
- Live opposite-faction investigations established that aura indexing can raise "Auras cannot be accessed when secret while tainted", while native containers continue their own guarded presentation. Unclassified harmful auras use a lower-priority **identity-blind** native fallback; they are not labelled Moonfire/CC without readable identification. A Moonfire-on-self omission was confirmed resolved by the user after moving that fallback above forms, without changing spell identities or permissions.
- A `UNIT_DISPLAYPOWER`-scoped independent hostile-player **Druid form-state presenter** handles times when permanent helpful auras are unidentifiable. It requires readable hostile-player identity, Druid class, alive state, and current power type: Energy -> Cat Form icon; Rage -> Bear-family icon; other/unknown -> no inferred icon. It has no fabricated duration and yields to higher-priority classified effects. It does not retain stale evidence across unit changes.
- Unidentified **permanent hostile helpful buffs** remain excluded from the generic fallback so that Find Minerals / tracking does not reappear by allowing unfiltered permanent buffs. This is independent of the Druid form-state witness.

### 23.2 Presenters, categories and priority contracts

- Exact and semantic categories are combined through `Priority.lua` with the latest `Spells.lua` membership, including completed rank families, elixir buffs above scrolls, and classified offensive cooldowns, DoTs and slows. Class and non-class spell identity is never inferred from an unavailable aura list.
- **Resurrection Sickness** is a distinct top-of-StatusEffects lane below Power Word: Shield; Silithid Pox and Pierce Armor are ordinary StatusEffects. **Dazed** has its own top-of-Slows lane below higher combat priorities. Existing roots, CC and immunities retain their stronger positions.
- **StatusEffects** remains above HoTs and below Power Word: Shield. Where a complete readable election is permitted, application-time recency elects the newest effect within a shared tier. Partial or restricted data fall back to Blizzard native display without inventing recency.
- Readable DoT presentation and an identity-blind hostile harmful fallback are available on large and compact frames. In restricted states the fallback cannot guarantee exact spell-specific priority; that is a security/data-availability boundary, not authorization to guess.

### 23.3 Presentation, timing and performance

- Post-patch portrait artwork, addon-owned circular masking, compact images and optical countdown placement were calibrated against a concentric-circle test icon on real screenshots; the native rings, unit-frame health/resource bars and UI Edit Mode coordinates remain owned by Blizzard or `bjarkiUI`.
- The `/bp test` command uses Blessing of Wisdom artwork as a visual alignment reference. The permanent production calibration is unchanged by toggling the test mode.
- Countdown display uses **whole seconds rounded DOWN** from 5 through 60 seconds, one decimal below 5 seconds when enabled, and hides portrait countdowns above 60 seconds. Actual aura expiration/duration is not shifted or truncated. Five-second decimals and the existing /bp toggle persist.
- Existing event-driven updates and scoped next-tick reconciliation remain; there is no permanent aura poller, cached hostile form identity, or DR-duration guess.

### 23.4 Verification and remaining limits

- The promotion payload consists of the 7 Lua modules and both manifest files from `bjarkiPortraits-0.1.130-form-state-test.zip`; each has a matching Git blob SHA. Local source testing reported **526 offline checks in 30 suites** and all 7 Lua modules passing syntax checks.
- The user's immediate live feedback for the form-state test was positive, but that does not demonstrate exhaustive Battleground, duel, pet, Focus, or taint correctness. Retain open historical observations in `KNOWN_ISSUES.md` until verified under the current client.
- Avoid retroactively claiming intermediate GitHub releases for local-only test builds. The exact source snapshot and this historical handoff are the provenance for `main`.

## 24. Potion-origin periodic damage coverage: 0.1.131-potion-dots-test (2026-10-17)

This synchronized release retains the exact nine runtime/manifest files of the distributed `bjarkiPortraits-0.1.131-potion-dots-test.zip`. It builds on the verified 0.1.130 form-state snapshot; no other aura selection, runtime geometry or timing logic was changed during this repository sync.

The Greater Discolored Healing Potion's applied **Rapid Poison (`1231579`)** and **Foul Disease (`1231580`)** belong to the ordinary **DoTs** lane at existing priority 190. They are periodic-damage debuffs; neither the potion's use effect nor its healing component is added as an aura candidate. Known higher-priority effects retain precedence and same-tier DoT election remains unchanged. No changes were made to icon placement, masks, crop, timer anchoring, five-second decimal threshold, whole-second truncation, native filters, the Ghost/Resurrection Sickness construction repair, or the guarded Druid form-state helper.

The local candidate passed the new focused checks and retained form-state tests and compiled as seven Lua modules. The larger historical test suite contains baseline-failing expectations on both the original .130 and candidate .131 sources; it must **not** be reported as fully passing. Live effects/priority, protected aura access and taint safety remain separately unverified. These two debuff IDs and local candidate lineage are now available on `main` with exact Git-blob parity.

## 25. Verified v15 source synchronization: 0.1.149-foundation-v15-fixes-test (2026-10-22)

### 25.1 Source scope and preservation

The nine Lua modules and both TOCs are copied byte-for-byte from the verified v15 suite. This advances the repository from `0.1.131-potion-dots-test` and includes accepted intermediate local changes. Relative to the shipped v14 Portraits source, v15 changes only the version in `Core.lua` and the two manifests; the v15 behavioral repairs are in the separate `bjarkiCC` addon.

The repository's Rapid Poison (`1231579`) and Foul Disease (`1231580`) DoT coverage remains present. The guarded Druid form-state presenter and existing portrait calibration remain in place; `PetPortraits.lua` is byte-identical to the previous repository version. Historical observations in `KNOWN_ISSUES.md` remain open unless separately verified.

### 25.2 Current presentation and selection

- An addon-owned race foundation sits above the native portrait and below aura/status layers. Classic race art uses the existing character-create sprite sheet with one-eighth-width tiles. Skyborne uses a validated native atlas; unavailable or ineligible identity clears the owned artwork and leaves the native portrait available.
- With `/bp decimals` enabled, countdowns show one decimal strictly below **3 seconds**, whole seconds rounded down from 3 through 60 seconds, and no numeric timer above 60 seconds. The compatibility threshold follows the same three-second policy.
- Cosmetic transformations, tracking, profession-only effects, and Boosted Rest are exclusion-only data. The old visible Cosmetic and Boosted Rest lanes are removed. Broad fallbacks receive the corresponding exclusions; the readable harmful check suppresses a fallback only when every observed entry is excluded and the bounded scan completes. Inaccessible identities do not become inferred exclusions.
- Air Bubbles IDs `17775` and `18733` join the existing travel-utility category. Existing combat stat, movement, and water-breathing effects retain their separate categories.

### 25.3 Shared positive evidence and recovery

`SharedEvidence.lua` installs or connects to the same compatible, bounded bus used by `bjarkiCC`. It accepts a closed schema of readable positive helpful-aura observations; securely rendered artwork and inferred identities are not evidence. Portraits remains usable independently of CC.

`EvidencePublisher.lua` publishes guarded added-aura observations for hostile player recipients. Target-of-target and focus-of-target binding snapshots inspect a fixed cooldown-aura shortlist and are first sightings, never new-application claims. Readable positives publish immediately even if another query is unavailable. Unavailable snapshots retain event-driven retry work; a completed snapshot, including an empty one, consumes the request. Queued work rereads the live unit, and disabling the addon cancels recovery. Existing one-shot refresh scheduling handles the work without a permanent aura poller.

Both manifests load the bus and publisher after `Core.lua`. The packaging workflow stages all nine modules and both manifests so its output matches that load list. `/bp audit` includes shared-evidence counters; enable/reset queues derived snapshots.

### 25.4 Verification boundary

The accepted v15 suite evidence records **42/42 executable scripts** and **28/28 runtime syntax files** passing under ordinary Lua 5.4 with modeled WoW APIs. Portraits coverage includes the shared-bus cases and derived-snapshot recovery regressions. These are suite results, not 42 Portraits-only tests. They do not certify native secret propagation, secure execution or taint, rendered pixels, or client combat behavior. The existing live-client reports remain separate validation items.

## 26. Three exact informational tiers above race baseline: 0.1.151-low-priority-tracking-status-test (2026-10-26)

### 26.1 Desired priority contract

The race portrait remains the addon-owned visual foundation; these are actual native `CustomAuraContainer` exact lanes on every portrait host, with no new masks or full-frame replacements:

| Level | Lane | Included auras |
|---|---|---|
| 1 | `Gathering` (HELPFUL) | Find Herbs ranks 1/2 (`2383`, `8387`); Find Minerals ranks 1/2 (`2580`, `8388`) |
| 2 | `InformationalDebuffs` (HARMFUL) | Tricked or Treated (`24755`); Boosted Rest (`1229451`) |
| 3 | `Tracking` (HELPFUL) | The full remaining `buffs_tracking` set: Track Humanoids/Beasts/Hidden/Undead/Elementals/Demons/Dragonkin/Giants, Sense Demons/Undead, Find Treasure/Fish, Detect Invisibility, Beast Lore, Eye of Kilrogg, Mind Vision, Far Sight, Eagle Eye |

The former `CampfireNearby` and `CampfireNearbyHarmful` lanes move together from level 2 to level 4. The unclassified `HostileHelpful` semantic lane moves from 3 to 5, so all existing ambient/generic auras remain above the informational levels; every combat tier, including PassiveSpeed (9), Plainsrunning (10), and everything from TravelUtility (50) upward, retains its previous level. The ambient/generic relative order is unchanged.

`Spells.lua` splits four gathering IDs from the prior combined tracking denylist; no higher-priority IDs were added to the tracking tiers and pure cosmetic/profession auras remain excluded.

### 26.2 Secure and readable ownership

Each exact tier participates in the existing secure aura-slot sort, including native same-lane `AuraInstanceID` recency. Tracking and gathering IDs remain excluded from broad `Important` / `BigDef` / `ExternalDef` and `HostileHelpful` semantic fallbacks, **not** from their new explicit tiers. The two informational harmful IDs likewise remain excluded from `SmallFriendlyHarmful` and generic priority harmful fallbacks, which would otherwise promote them above genuine combat effects. Permanent unclassified hostile helpful auras remain excluded from the broad duration-filtered fallback; inaccessible identity is never treated as a known tracking spell.

On self/friendly harmful units, Forever may forbid exact harmful ID filtering even when readable aura data is available. The same `InformationalDebuffs` tier therefore receives one optional readable helper on each host, using the existing `updateReadableHarmfulTier` complete, same-tier election and ownership conditions. A missing, partial or secret harmful list never authorizes an inferred icon. Higher-priority helpful and harmful auras continue to win.

### 26.3 Regression and live-client boundary

GitHub Actions now syntax-compiles the nine shipped Lua modules plus `tests/low-priority.lua` under Lua 5.1 and Lua 5.4 and runs exact policy assertions: all gathering ranks, informational IDs, tracking/sensing coverage, exclusive membership, index ownership, strict tier ordering, semantic exclusions, and the guarded readable harmful helper wiring. The test file is **not** packaged as an addon module.

Offline checks do not certify whether each aura ID is actually exposed by the postlaunch Forever client, whether the native secure harmful filter allows those two auras on every relation, or whether the guarded readable fallback sees a complete harmful list in combat. Screenshot-level visual centering and mixed-faction visibility must still be checked in game.

## 27. Restore portrait decimals below five seconds: 0.1.152-five-second-decimals-test (2026-10-26)

- With `/bp decimals` **on**, portrait aura countdowns use the existing `%.1f` native numeric format strictly below **5 seconds**, and whole seconds rounded down at five through sixty seconds. Countdowns above the existing `60.000001` cutoff remain hidden as before.
- With `/bp decimals` **off**, all displayed portrait countdowns remain whole seconds. The saved preference and its default value are unchanged.
- `Core.lua` changes only the formatter's whole-second threshold from 3 to 5 and the compatibility `Cooldown:SetCountdownMillisecondsThreshold` value from 3 to 5. There is no cooldown-time reading, rescheduling, mask, priority, or aura-election change.
- `tests/decimal-threshold.lua` loads the real `Core.lua` code under modeled native APIs and checks decimals-on/off formatting, 4.9/5.0 and 60-second boundaries, successful native formatter application, and both compatibility fallback cases under Lua 5.1 and 5.4.
- This accompanies bjarkiUI's separate action-button `0.2.256` sub-five-second formatter update, without linking the addons or changing their independent runtime behavior.

## 28. Priority consolidation, stun/silence evidence and old-layout hierarchy: 0.1.153-priority-consolidation-test (2026-10-27)

### 28.1 Consolidated classifications

- Divine Protection `498/5573` joins `Immunity` (330) rather than occupying its own 331 lane. The former hostile readable Divine Protection witness remains **within Immunity's level** and now requires a complete, same-tier readable election before it can render. **Correction (section 29):** the previous claim that Will of the Forsaken `7744` supplies a usable Forever portrait aura was not supported. The user's live Forever test found no applied buff; v0.1.154 excludes `7744` from all exact portrait tiers. Stoneform joins `Defensive` (290). No separate racial-defensive tier.
- Reflection Field `1303458` is no longer in Immunity; it joins `Thorns` (120), as a reactive hostile-spell reflection rather than invulnerability. Free Action Potion `6615` moves to the **PhysicalImmunity display tier** (315) at the user's request; mechanically it protects against stun, snares and roots, **not direct physical damage**. Grounding Totem Effect `8178` and Voice of Truth `1310897` join a distinct `SpellImmunity` (316). Voice protects against silence/interrupt, not roots.
- Stuns (320) retain the existing 36 exact IDs, including Charge Stun `7922`, Intercept Stun `20253/20614/20615`, Cheap Shot `1833`, and Pounce `9005/9823/9827`. The separate long Pounce bleeds `9007/9824/9826` **remain DoTs (190)**. Missing stun display was a native/readable eligibility problem, not evidence that these IDs were absent. The new readable helper requires an entire complete, ordered harmful-aura election; unknown/secret observations never fabricate a stun.
- The new `InterruptSilence` harmful tier (306) contains reviewed silence auras `15487/18425/18469/24259/1330` alongside pre-existing interrupt IDs. Harmful generic Control excludes all stun, silence and interrupt members. A second complete-aura helper presents positive readable entries where native filtering is unavailable. **Interrupt cast success and school lockouts without an observable aura do not become fictional debuffs**; full opponent school-lock tracking is outside aura-portrait evidence.
- Nature's Grasp caster/self-buff ranks `16689/16810/16811/16812/16813/17329` remain `Utility` (225), not Roots. Their distinct applied proc-root IDs `19970–19975` remain Roots. Blink `1953/1236175` leaves Utility for `RootImmunity` (305), subject to actual aura visibility.
- OffensiveHarmful and Offensive helpful share level **280**. WoW requires separate HELPFUL/HARMFUL AuraContainers, so the two internal keys remain but no longer have different priorities. Ice Barrier ranks move from generic Healing to PowerWordShield (256); both actual absorb auras share that level. There is one `Wounds` harmful exact lane (230) for Weakened Soul, Recently Bandaged and Wandering Plague. The loose 15-second Weakened Soul approximation is removed.
- Remove signature-only guessed `ChilledSignature` (219) and `FrostArmorSignature` (150): exact eligible spells and complete readable elections still work, but an unobservable hostile aura is no longer classified from its vague duration/shape. The ordinary SelfState (150) lane remains, incorporating Lightning, Water and Earth Shields, as requested.
- Darkspear Islands Flag `1284560` and Welcoming Campfire `1229739/1289723` join Honorless Target (257). The special direct Campfire witness is retained at the new shared level and compares against the **entire** merged tier's native recency. Righteous Fury `25780` joins Plainsrunning (10).
- Tricked or Treated `24755` and Boosted Rest `1229451` join the existing `CampfireNearbyHarmful` level (4), rather than occupying a separate tier. Only one complete-readable nearby harmful helper is installed on each eligible portrait. Tracking (3) and Gathering (1) remain directly above the race foundation.

### 28.2 Priority layout reference and selection limits

The previous PvP layout screenshots prioritize: immunity and true control above interrupt/silence protection and interruptions; defense above offense; low-status auras and movement effects below stronger PvP information. This release preserves the existing numeric range rather than copying arbitrary 1–100 slider values. **Historical error, reversed in section 29:** v0.1.153 moved Roots to 218 and Slows/Dazed to 205/206 without a user request. Those are restored to 300/278/279. Utility moves from 270 to 225 because the user explicitly said its tier was too high; the harmful Offensive lane joins helpful Offensive at 280 as explicitly requested. Screenshot slider values were references, not authorization to rearrange unrelated tiers.

Overlapping aura IDs are removed from generic Control when their explicit Stun or InterruptSilence tier owns them. The exact tier lookup is unique per spell ID. Helpful and harmful AuraContainers at the same numeric level are still separate native widgets; on unreadable simultaneous cross-filter cases there is no guaranteed last-applied winner between those two filters. Complete readable helpers decline partial elections, and the broad fallback remains an unclassified last resort.

### 28.3 Verification and limitations

`tests/priority-overhaul.lua` loads actual `Spells.lua` and `Priority.lua` and checks 20 requested classification and merging decisions, tier rank relationships, all reviewed spell IDs, no overlapping exact ownership, and complete-evidence helper wiring. `tests/low-priority.lua` adapts to the merged nearby harmful tier; the existing five-second countdown tests remain unchanged. GitHub Actions compiles the nine runtime modules and all three regression scripts and executes them on Lua 5.1 and 5.4. No new timer loop, client CVar, full-frame replacement or saved layout override.

Forever may expose different applied stun/silence spell IDs or restrict target aura visibility. In particular, Classic Pounce has distinct short stun and long bleed effects, but a Forever build might package them differently; an unobservable stun cannot safely be inferred from a surviving bleed. Confirm Pounce stun, Charge/Intercept stun, successful school lockouts, Grounding and Voice of Truth in the live client before claiming all are rendered. Removing shape-only approximations trades speculative coverage for fewer false-positive classifications.

## 29. Correcting unauthorized priority changes and cast-only WotF: 0.1.154-priority-scope-correction-test (2026-10-27)

The user's explicitly enumerated adjustments in the previous turn were authoritative. The three separate rank changes introduced by v0.1.153 were not requested, and screenshots of earlier addon slider configurations did **not** authorize moving otherwise untouched categories. This release restores their original values:

| Tier | v0.1.152 (pre-overhaul) | v0.1.153 error | v0.1.154 (restored) |
| --- | ---: | ---: | ---: |
| `Roots` | 300 | 218 | **300** |
| `Slows` | 278 | 205 | **278** |
| `Dazed` | 279 | 206 | **279** |

Both readable helper fallback frame levels for Slows and Dazed are restored to 278 and 279. Roots again outrank Defensive 290 and Offensive 280, and RootImmunity 305 still outranks Roots. The explicit decision to lower the generic Utility tier from 270 to 225 and merge OffensiveHarmful 281 into Offensive 280 remains in effect. Every other retained tier matches its v0.1.152 numeric priority, except those two explicit changes; retired/merged tiers retain the user's requested categories.

**Will of the Forsaken:** `7744` was incorrectly added to `immunities` based on generic historical spell information. The user's direct Forever observation states that activating WotF provides **no visible applied buff**. This release removes ID 7744 from *all* displayed exact aura categories and their helpful-tier index. The top Immunity lane is for observed immunity auras, not for classifying a cast-only action by its effect. Divine Protection's inclusion in the Immunity lane remains the user's explicit instruction. Other pre-existing Immunity IDs are unchanged by this corrective patch.

`tests/priority-overhaul.lua` now asserts the restored hierarchy, excludes 7744 from every category and secure aura tier, and locks **all 55 retained pre-overhaul tier levels** to their original numbers except the explicitly requested Utility and OffensiveHarmful changes. This prevents future screenshot interpretation or unrelated cleanup from silently changing established priorities.

All remaining v0.1.153 classification merges, stun/silence complete-readable presentation checks, five-second timers and race-fallback behavior remain unchanged. Neither protected server aura visibility nor postlaunch immunities can be inferred from CI; further spell-ID changes must follow actual Forever observations rather than general Classic assumptions.


## 30. Priority handoff and derived timing corrections: 0.1.155-fixes-test (2026-10-27)

A complete, successfully presented readable helpful winner now suppresses `HostileHelpful` only when its exact tier reaches that generic lane's priority. Gathering (1), Tracking (3), and CampfireNearby (4) leave the generic lane (5) eligible. The known CampfireNearby IDs also join the generic exclusion set, preventing that broad native lane from promoting them above their own level. Exact memberships, numeric priorities, and the higher readable winner's same-tier ownership are unchanged. Partial elections and presentation failures still cannot suppress the native fallback.

Every relevant derived `UNIT_AURA` can now request the existing fixed nine-spell snapshot, including after a binding snapshot completed. Newly readable or corrected timing is published as a first sighting/correction (`newApplication=false`); explicit `addedAuras` positives retain their existing new-application signal. The publisher rereads the live unit/GUID when the coalesced callback executes. It still emits only readable positives, never removals from absence or failed queries.

Stable correction-only requests use the existing one-shot queue without a second forced native refresh, pet reclassification, or presentation pass. A pending availability retry retains full reconciliation. Any queued binding or visual request upgrades that token to full reconciliation, and later correction-only requests cannot cancel it. Repeated events coalesce to one pending callback and at most one nine-query shortlist pass per requested derived token. No per-aura retained history, polling timer, or new dependency is introduced; the shared bus and consumer identity rules are unchanged.

`tests/hostile-helpful-priority.lua` exercises actual `UpdateHost` ownership, relative priority, readable candidate exclusions, partial scans and presentation failures. `tests/derived-evidence.lua` exercises actual event dispatch and publication for delayed timing, full updates, explicit additions, rebinding, disable, partial lookups and burst bounds. The three existing scripts remain unchanged; CI syntax-checks and runs all five scripts on Lua 5.1 and Lua 5.4.

These are ordinary-Lua checks with modeled game APIs. Native rendering, restricted-value behavior, taint and frame-time cost still require in-game validation. The separate audit findings concerning failed access-check calls and failed native parent restoration are outside this two-bug repair.


## 31. Pending evidence recovery: 0.1.156-fixes-test (2026-10-27)

A derived binding snapshot that could not establish recipient eligibility already retained pending work. In 0.1.155, `UNIT_FACTION` and `UNIT_FLAGS` refreshed visual eligibility but omitted that work from their queued request. If the next aura event was removal, a readable positive could pass entirely unobserved.

The unit-state route now forwards its existing `snapshotNeeded[unit]` request for faction, flags and connection events. The player faction/flags route forwards the retained request for each tracked token because the player's relationship affects every recipient. Completed snapshots are not reopened by those events; only retained derived work is retried.

Recovery uses the existing one-shot queue and fixed nine-spell shortlist. Repeated events coalesce, partial lookups retain independent positives, the callback rechecks the live recipient GUID and eligibility, and snapshots remain first sightings/corrections (`newApplication=false`). A completed or empty successful pass consumes pending work. Disabling the addon before the callback cancels publication. No new history, timer loop, dependency, spell priority, aura ownership rule, or consumer behavior is introduced.

`tests/pending-evidence-recovery.lua` exercises both derived units, unit and player faction/flags, selective pending tokens, coalescing, ineligible retries, current identity, disable, partial/empty reads and the existing connection recovery path. All five previous test scripts remain unchanged; CI compiles and runs all six scripts on Lua 5.1 and Lua 5.4.

Verification uses ordinary Lua with modeled game APIs. Live faction/event ordering, secret values, rendering, taint and frame-time cost remain unverified. Existing conditional API-failure observations and consumer retention/identity limitations are outside this narrow repair.
