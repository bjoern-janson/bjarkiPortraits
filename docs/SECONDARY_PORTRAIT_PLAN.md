# Secondary portrait: two aura priorities + race identity

## 2026-11-08 — native two-cell flow experiment (0.1.195)

**New source-backed capability:** Forever's native `CustomAuraContainer`
allows multiple `AddAuraGroup` registrations within *one* container;
each group can use `maxFrameCount=2`, its own native exact/semantic
filter, the existing aura-instance sorting method, and a global
`layout.layoutIndex`. The secure `GetFlowLayoutGroupDescriptions`
sorts groups by that index and lays their current native buttons
sequentially. This differs materially from reading protected
`GetAuraDataByIndex` or trying to query a second winner directly.

**Candidate design:** Sort the existing 63 `R.TIERS` in descending
numeric priority, place them into one target-only native container, and
clip away the first native 37px cell. The next native button, if any,
is rendered at the secondary portrait position with its own secure
icon/cooldown. The fixed viewport never reads child geometry or
secret aura IDs. A source-backed inbound mock regression checks ordered
group options, exclusion of overlapping *exact* categories, clipping
and target-only visibility. The exact spell-ID audit currently finds
1,557 unique IDs and **zero overlaps between exact tiers**.

**Remaining blockers:** Group membership can overlap across native
semantic categories, and generic fallbacks must explicitly exclude
known exact IDs. These are corrected for known exact/generic overlaps
in the prototype; all semantic overlaps, live anchor offsets,
native protected visibility, and initialization cost remain unverified.
The existing large primary stack is unchanged. The native strip is
disabled unless `/bp native2 on` is selected outside combat, and is
currently scoped to hostile non-player TARGET only; there is no
unconditional promise of global top-two accuracy yet.

This is a test of a **supported secure rendering interface**, not
permission to read private winner tables. We should inspect live
artwork and same-tier/different-tier cases before considering a
production refactor. Keep fail-closed normal fallback and no secret
value processing in addon Lua.

---

**Status:** P1/P2 readable prototype through v0.1.191; verified static Ghost can lead Boosted Rest without duplicate aura; universal secure cross-tier runner-up remains unavailable  
**Baseline:** `0.1.178-bottom-harmful-consolidation-test` (2026-11-08).  
**Proposed next development milestone:** `0.1.179-secondary-portrait-prototype` (working name, not a release).  
**Source of visual direction:** 2026-11-08 in-game player-frame comparison: a tiny Blizzard Shaman Totem-like circular ring at the top corner of the main portrait.

## Follow-up 0.1.191: Ghost is a static main state, not a secondary-election veto (2026-11-08)

**Observed:** A deceased player, also selected as Target, has the existing Ghost portrait in the large circle and two native debuff icons, including **Boosted Rest**, but the small circle shows the race. The live command reports `secondReason=static-ghost-witness`. Unlike the 0.1.188–0.1.189 load-order defect, this is a direct early-return gate inside the new second-aura reader.

**Resolution:** Preserve `AuraEngine.updateGhostState` and its frame ownership unchanged. Require `_ghostActive=true` with `_ghostSource=unit-state` and a readable positive current `UnitIsGhost`, or `_ghostSource=aura` backed by its existing positively presented Ghost aura. Treat the main Ghost as a static first-place candidate at **Immunity + 2 = 332 presentation level** (this is the current helper's frame level, **not** a new numeric aura tier). When the complete public indexed aura union contains a known lower effect, elect the highest eligible lower aura as the secondary. For harmful `BoostedRest` (priority 0), a verified Ghost main permits this *public* positive to be considered even where native harmful identity filters are relation-gated; the exact current occurrence and normal harmful-filter membership must still be positively readable.

**Occurrence deduplication:** The three `Ghost` harmful IDs (8326, 9036, 1278162) describe the same already presented state. Exclude them from the second-place candidate list whenever the static Ghost presenter is proven. Do not let one Ghost display consume both portrait circles. If Ghost is the only effect, preserve the usual race fallback. If an aura at or above the Ghost presenter's frame level competes for first, do **not** assume a tie-break or fabricate a second icon. Waiting to Resurrect at 332 is an explicit tie case.

**Tests:** The existing `Spells.lua`/`Priority.lua` model now verifies Ghost + Boosted Rest = `verified-ghost-then-aura` with Boosted Rest at 0, current aura-instance identity, proper cooldown and no duplicate Ghost. Reversed Ghost variants, missing Ghost aura but positive unit state, unproven Ghost, missing Boosted Rest instance ID, Ghost-only and exact-priority tie are negative cases. A second test drives the real `R.UpdateHost` path and verifies that the original main Ghost frame stays shown while the second uses the Boosted Rest texture; removing the buff must clear the badge. No polling, private aura access, new priority number or native main changes.

**Remaining limitation:** When Forever restricts the current harmful aura or filtered membership, `GetReadableSecondaryAura` remains conservative; this change does not guarantee secret aura tracking in combat. Live-client verification is still needed with Ghost and Boosted Rest on player and friendly target.

---

## Follow-up 0.1.190: priority initialization order — confirmed live regression (2026-11-08)

**Observation:** The user provided `/bp secondary debug player` and `target`, both with `mode=race` and `secondReason=not-two-presentable` while visibly carrying multiple buffs. The relation fields were positively friendly; `hList=false` describes only the hostile-helper path and is normal for friendly units, not evidence of an empty normal aura list.

**Confirmed source cause:** In 0.1.188, the ranking code was optimized to iterate `rankTiers` sorted by numeric priority. It created this cache **at SecondaryPortrait.lua file load** from `R.TIERS or {}`. Both packaged `.toc` manifests load `SecondaryPortrait.lua` before `Priority.lua`. Thus `R.TIERS` was `nil` when the cache was constructed, leaving it empty permanently and explaining the universal race fallback. Existing tests manually loaded `Priority.lua` first, falsely validating a load order the live client never used.

**Repair:** In both TOCs, move `SecondaryPortrait.lua` to immediately **after** `Priority.lua` and **before** `AuraEngine.lua`. Also make the sorted list a *single lazy cache* built at the first actual ranking call **after** `R.TIERS` is populated; invalidate it only when the source table identity is replaced. If tiers are still unavailable, fail with a specific `tiers-not-ready` reason, never a fake `not-two-presentable`. All original spell sets, numeric priorities, host and native filtering stay intact.

**Regression proof:** Using the same real `Spells.lua/Core.lua/SecondaryPortrait.lua/Priority.lua` order as the old manifest, a 0.1.189 model with publicly readable Thorns (467) and Mark of the Wild (1126) returned **`second=nil, reason=not-two-presentable`** even though `#R.TIERS=63` after load. The corrected source, with the deliberately reversed order, returns **Mark of the Wild (1126), verified-readable**. New `tests/secondary-load-order.lua` checks both manifests and exercises both production and reversed init orders; it also tests temporary tier-table absence/restoration and real priority 120 > 90. CI runs it on Lua 5.1 and 5.4. This is source/fixture verification, **not yet a Forever live display certification**.

**Remaining boundary:** Combat secrecy and native/private first-place winner uncertainty are independent limitations. Do not bypass their existing fail-closed controls. The 0.1.190 change should fix ordinary multi-buff fallback caused by the cache; if a new failure occurs, the now-populated ranking table will finally allow the intended real filters to run, revealing a meaningful next `secondReason`.

---

## Follow-up 0.1.189: public exact membership proof; NPC mixed-aura ranking (2026-11-08)

**Live feedback:** After 0.1.188, a friendly target and the player showed race fallback, and a hostile NPC with two harmful icons still lacked a secondary badge. These screenshots do **not** expose the actual `secondReason` and cannot establish a single shared runtime cause.

**Confirmed independent flaw:** The readable top-two algorithm obtains a complete `HELPFUL|INCLUDE_NAME_PLATE_ONLY` / `HARMFUL|INCLUDE_NAME_PLATE_ONLY` public list. For ordinary HELPFUL/HARMFUL exact lanes it then required an optional `isNameplateOnly=false` field, or `IsAuraFilteredOutByInstanceID`, which may be inaccessible to untrusted addon Lua. Neither is necessary to prove **positive membership** if the same current `auraInstanceID + spellId` is also visible in the **plain native polarity** list. Version 0.1.189 performs at most **one extra 48-entry public scan per polarity per election**, and only when an exact candidate's optional field is unavailable. Repeated IDs, contradictory spell identity, filter errors or nonterminating scans cannot authorize absent entries. A positive match can authorize that one exact candidate; an incomplete scan cannot prove its absence. This does not create a secure global runner-up or bypass secrets.

**NPC gate correction:** An NPC can carry low-level beneficial effects and still have a harmful aura as its highest-priority presentation. Requiring a totally empty HELPFUL list was unnecessary. The updated NPC path requires *both complete polarities*, positive non-player identity and native harmful permission, then ranks the full candidate union. It permits the harmful-first projection only when the highest projected effect is actually harmful and its native slot is enabled; if a helpful effect leads and lacks a verified primary, the badge remains hidden. Hostile players are unchanged.

**Diagnostics:** `/bp secondary debug target` and `/bp secondary debug player` emit two short non-mutating lines: current badge mode, selected ID/tier, `secondReason`, and saved relation/player/helpful-list/native-write flags. Unlike the long `/bp layout` output, they remain readable in the game chat window. No protected native aura button is read by the command.

**Tests and boundary:** Regression tests show 0.1.188 fails the ordinary-filter proof fixture and 0.1.189 passes it. Other fixtures cover nameplate-only denial, duplicate IDs, inaccessible ordinary filters, mixed NPC with a stronger harmful primary, and a genuinely higher helpful primary that stays fail-closed. Existing priority numbers and the native main portrait are untouched. If live `secondReason` still indicates `inaccessible-index`, `hostile-list-unreadable`, `native-filter-unreadable` or a secret-value restriction, the correct next step is to identify which evidence is missing; do not display an unverified or stale second aura.

---

## Follow-up 0.1.188: harmful-only hostile NPCs (2026-11-08)

**Live counterexample:** A Kobold Tunneler has a timed harmful aura on its main Target portrait and two debuff icons below, yet lacks the small secondary portrait. Hostile targets previously required the special `_hostileActive` **helpful** main-aura presenter or an independently proven form. That condition excludes even a readable hostile NPC whose actual main aura is harmful. NPCs also have no race fallback, so the whole badge vanishes.

**Implementation:** A dedicated Target/Focus path accepts **only positively proven non-player hostile units**, requiring `_playerReadable=true` and `_isPlayer=false`, readable hostile relation, a complete public helpful list containing **zero** helpful auras, a complete harmful indexed list with current distinct occurrence identities, native exact harmful permission, and no write failures. After ranking all publicly readable candidates, the projected first harmful owner must be an existing exact spell-ID tier or the native `SmallFriendlyHarmful` fallback with its same public filter. Its corresponding current native container must be **positively enabled**; no private winner is inspected. The second distinct candidate can then occupy the small circle. If any gate fails, or fewer than two effects remain, the badge stays hidden (no invented NPC race).

**Ranking improvement:** `R.TIERS` is consulted in descending numeric priority in the secondary reader; once a known higher tier is proven, a lower semantic tier cannot change that candidate's owner and need not consume a second restricted API probe. For `SmallFriendlyHarmful`, its identical `HARMFUL|INCLUDE_NAME_PLATE_ONLY` indexed source plus verified duration/exclusions avoids a redundant native identity call. All higher semantic filters must still be positively excluded or inspected. No spell classification, numeric priority, native main portrait, polling loop or additional aura container stack was added.

**Important evidence boundary:** This is a bounded **public projection**, not direct confirmation of the secure native main winner. It is intentionally *not* extended to hostile players (where secret/private aura states are common), unreadable NPC identities, NPCs with mixed helpful/harmful aura lists lacking a verified first place, or underdocumented semantic primary effects. Actual NPC visibility in combat and any discrepancies between the public projection and private secure frame must still be tested in Forever. `/bp layout target` emits `secondReason=npc-readable-harmful-projection` when the path succeeds.

**Regression:** `tests/secondary-npc-harmful.lua` covers categorized different-tier and same-tier effects, generic harmful filter proof, semantic secrecy, disabled native slot, unproven identity, hostile-player exclusion, mixed lists, missing second, Focus and ToT exclusion. `tests/hostile-helpful-priority.lua` adds a *real `R.UpdateHost`* NPC fixture verifying the actual relation, current native slot and rank handoff. Release remains experimental and live verification is outstanding.

---

## Follow-up 0.1.185: rank observed forms instead of assuming they are first (2026-11-08)

**New live counterexample:** A level-9 Warrior out of combat has a timed flame aura on the large portrait, Camp Benefits visibly active, but the secondary displays race. The previous `GetReadableSecondaryAura` branch saw `_formStateActive`, insisted it must be the first portrait and returned `form-not-proven-primary` if any aura outranked the observed form. That is incorrect: native higher-priority auras can cover the static form. This is a source-confirmed false-negative path; the screenshot alone does not expose its `secondReason`.

**Fix:** Put each **positively proven current** Warrior stance / Druid form at its existing static portrait level `SelfState - 1 = 149`, beside independently ranked public auras. Do not add it to the native aura table or fabricate an aura instance ID.

- If the form outranks all auras, it is first and the strongest readable aura can be second (existing behavior).
- If one aura outranks the form, the **form is second** unless another aura outranks the form. For example, Welcoming Campfire (257) > Battle Stance (149) > Camp Benefits (90).
- If two independent auras outrank the form, those two auras occupy the circles. A form alone yields race fallback.
- A form **used as the secondary** uses the already positively drawn addon form icon (or a readable public spell icon), with **no countdown**. Permanent/static state never participates in timed combat-retention.
- Hostile first-place aura still requires matching spell, lane and aura-instance ID from the main engine. An unreadable/mismatched primary, missing form icon, unverifiable form state or tie remains a race/hidden fallback.

**Verification:** A new regression against the real `Spells.lua`/`Priority.lua` map covers form-first, form-second, form-third, no-aura fallback, unproven forms, missing texture and hostile-main agreement. An additional actual `R.UpdateHost` fixture tests that the own Warrior stance witness survives beneath a higher aura and is selected as the second portrait. The numeric priority table, race fallback, primary secure stack, ToT/ToF/pet opt-outs, combat restrictions and no-polling policy remain unchanged. Live verification still required.

---

## Follow-up 0.1.184: outer top corners and last-positive combat transition (2026-11-08)

Live screenshots showed the small badge colliding with the rested-Z and party-leader regions and switching back to the race when combat restricted the aura API. Badge orientation is now outward: player/party top-left, target/focus top-right, with a five-unit inset toward the portrait to prevent screen clipping. ToT/ToF and pet remain excluded.

**Combat policy:** when a previously displayed, verified, timed secondary aura becomes unreadable solely because a combat refresh cannot access the current list, retain that last positive only while the host is still eligible, combat is positively established, no UNIT_AURA event has invalidated the ranking, the original expiration has not elapsed, and (on target/focus/party) the current positively readable GUID matches. A single C_Timer.After callback revokes the evidence at expiry; a generation token prevents an older timer from clearing a new aura. The first actual aura-change event revokes the hold unless a complete current election succeeds. No polling, new tier, private winner read, or duplicated secure aura stack.

The diagnostic `secondReason=combat-positive-retained:<read failure>` identifies this temporary last-positive state. It is not evidence of a newly verified second-place aura during combat, and cannot guarantee permanent/secret effects. If the client conceals visibility, identity, native writes or the aura changes, race/hidden remains correct.

**Acceptance tests:** outer-corner mirroring on player/target/focus/party; held positive on sealed combat entry; first UNIT_AURA invalidation; one-shot expiration; generation-safe old timers; target GUID mismatch; no persistent cache for permanent auras; baseline player/target priority and ToT/ToF opt-outs unchanged. Live screenshots remain required.

---
## Follow-up 0.1.183: verified hostile-target and stance-first selection (2026-11-08)

The next live screenshot confirmed a working player secondary aura but exposed a missing target case with **Camp Benefits**. The 0.1.182 reader rejected every `host._hostileUnit=true` target before scanning, even though `AuraEngine.updateReadableHostile` already supports publicly readable hostile HELPFUL auras. Some targets additionally have a positively displayed Warrior/Druid form witness above their ordinary camp status.

The implementation now accepts a hostile-target *readable projection* only with strict current evidence: `host._hostileRelationReadable=true`, a completed and ordered native HELPFUL list from the existing main reader, plus a second complete helpful/harmful indexed scan. Exact helpful spell candidates can use that positively complete public source without claiming permission to change restricted secure exact filters. Unreadable semantic filters, incomplete instances, missing time or current unit identity still fail closed.

Two positive main-portrait paths are permitted:

1. **Readable aura main:** the existing higher-priority hostile helpful main helper must be active and authoritative, and the newly computed #1 aura must match its `spellID`, exact `tier.key`, and **aura-instance ID**. Only then may the indexed #2 appear.
2. **Static form main:** if the existing main form/stance icon has a positively proven current spell and every ranked public aura has a lower priority than the form's existing 149, then the highest ranked aura is the second portrait. No invented duration is attached to the static form.

Neither path creates a second native per-tier stack, reclassifies Camp Benefits (still BaselineClass 90), assumes hostile PvP buffs are readable, or changes the authoritative main portrait. **When the displayed first-place effect cannot be proven, the secondary stays race/hidden**. ToT/ToF and PetFrame still have no secondary circle.

New unit tests cover Camp Benefits below an authoritative hostile aura, Camp Benefits behind a verified stance, mismatched main identity, secret entries, higher aura blocking a static-first claim and missing relation evidence. The full `R.UpdateHost` integration regression checks that the existing hostile-main helper supplies the needed occurrence ID. Live target-specific verification remains pending; use `/bp layout target` to check `secondReason`, `hostileMain` and `hostileList`.

---

## Follow-up 0.1.182: preserve readable friendly relation (2026-11-08)

**Observed:** The live `/bp layout player` output says `assistReadable=true assist=true`, `secondary=race`, and `secondReason=relation-unreadable`. Source inspection identified a precise contradiction in `AuraEngine.lua`: `host._hostileUnit = hostileRelationReadable and hostileUnit or nil`. In Lua this expression converts the valid, readable **false** result (friendly) into **nil** (unknown). As a result, the very first gate of `GetReadableSecondaryAura` rejects all friendly hosts, so the prior exact-tier fixes could not take effect in game.

**Fix:** Assign `host._hostileUnit` through an explicit conditional: true for readable hostile, false for readable friendly, nil only when relation unavailable. Leave `R.HostileUnitState` and the native priority system intact. Expose `hostileReadable` and `hostile` in `/bp layout` alongside existing assist diagnostics. Add actual `R.UpdateHost` regression coverage for all three relation states and one friendly two-aura election. Keep ToT/ToF/PetFrame badge exclusions.

**Verification boundary:** Offline regression covers modeled APIs and source logic. Live in-game evidence of a second icon is **not yet established** after this correction; if the next `secondReason` differs, investigate that specific downstream gate rather than guessing. Do not bypass unreadable combat aura restrictions.

---

## Follow-up 0.1.181: exact-tier evidence and ToT/ToF opt-out (2026-11-08)

A second live report found the aura badge still falling back to race. Source inspection identified a **false-negative path**, not a proven singular live cause: 0.1.180 asks the native `IsAuraFilteredOutByInstanceID` oracle to approve every candidate, including an exact known helpful/harmful aura whose membership is already witnessed by a **completed indexed native polarity scan**. In restricted contexts the extra call may be unavailable even when the indexed record, current instance ID and applied spell ID are readable.

`SecondaryPortrait.lua` now uses this narrowly permitted proof for **exact lanes only**:

- The candidate has a readable current `auraInstanceID` and `spellId` from the completed `HELPFUL|INCLUDE_NAME_PLATE_ONLY` or `HARMFUL|INCLUDE_NAME_PLATE_ONLY` scan; it belongs to the configured exact tier's spell-ID set and is allowed by the current relation/owner rules.
- For a tier whose filter includes `INCLUDE_NAME_PLATE_ONLY`, the candidate is already a member of the exact same native-inclusive polarity and needs **no second identity-filter lookup**.
- For a plain `HELPFUL` or `HARMFUL` tier, the aura's `isNameplateOnly` must be **positively readable and false**. If the bit is unavailable, the addon still tries the native oracle; if neither can prove the result, it falls back to race. A positive nameplate-only bit explicitly **excludes** the candidate from that plain tier.
- Semantic categories (Important, Crowd Control, Big Defensive, etc.), ambiguous same-level lanes, inaccessible reads and all unknown-state cases **still require native evidence** or fail closed. No guessed icon, fabricated duration, polling loop or duplicate 62-lane stack is introduced.

The other user-requested adjustment is scope: **ToT and ToF no longer create, preview, reconcile or display any secondary badge**. Their original full priority main portraits remain unchanged. The secondary circle now belongs to Player, Target, Focus and the four regular party slots, **not PetFrame**.

The new `tests/secondary-real-tiers.lua` exercises actual `Spells.lua`/`Priority.lua` memberships (Mark of the Wild vs Thorns) with the extra native oracle **absent**; other tests cover inclusive-filter correctness, restricted semantic fallbacks, and ToT/ToF exclusion. Testable locally does not establish complete Forever in-game behavior. The next live diagnostic is `/bp layout player` with two known active buffs and `/bp test` off; inspect `secondReason` before further assumptions.

---

## Follow-up 0.1.180: upper-layer badge and guarded readable top two (2026-11-08)

The first live screenshot exposed a real P1 defect: the badge's original parent was the **low-strata aura layer**, so its bottom section could disappear behind Blizzard unit-frame art. This version moves the badge to an **independent UIParent overlay** whose strata is above the native unit frame. It is noninteractive and uses a small frame pool, preventing permanent root widgets from accumulating after recycled party slots. Its visibility is independently revoked when the real native unit frame hides.

P2 has a limited usable implementation for **complete, public, friendly-unit aura reads**. `SecondaryPortrait.lua` obtains bounded complete `HELPFUL|INCLUDE_NAME_PLATE_ONLY` and `HARMFUL|INCLUDE_NAME_PLATE_ONLY` snapshots via `C_UnitAuras.GetAuraDataByIndex`; validates accessible spell and aura-instance IDs; reuses the exact/semantic `Priority.lua` tiers; asks the *native* `IsAuraFilteredOutByInstanceID` oracle per candidate/tier; and sorts by tier level, same-tier reverse aura instance ID, or verified application start for the three recency tiers. Two distinct, unambiguous current candidates permit a real timed second icon. The entire election is **discarded**, with race/hidden fallback, on incomplete lists, unreadable filters, conflicting equal-level lanes, unavailable relevant timing, hostile relations, active static witnesses, failed frame writes or event-ineligible bindings. The code keeps a scan/probe budget (48 auras per polarity; 192 native filter probes per host update). There is no combat polling, no duplicated secure aura-tier stack and no secret-value read.

**Remaining limit:** this is a public-only election, not a fully secure proof of the *rendered* primary winner under every native/private aura condition. The supported secure API still does not expose a global runner-up, so hostile and secrecy-heavy combat generally fall back. The current build is for **live testing**, not a claim of universal two-aura coverage. New regressions test top-two different/same tier, semantic lane, stale expiry/identity, restricted filters, native-frame layering, popup-free hit testing and pooled frame reuse. Test the actual large/compact frames, combat, party swaps and 10s countdown before promotion.

---

## Prototype progress: 0.1.179-secondary-race-prototype (2026-11-08)

**P0 evidence / unresolved blocker.** Forever's [Blizzard_CustomAuraContainer.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_AuraContainer/Blizzard_CustomAuraContainer.lua) accepts fixed `AddAuraSlot` sort enums, then chooses **one** winner using `AuraContainerUtil.GetAuraSortComparator`. The supported inbound options do **not** allow an arbitrary custom rank comparator or an exclusion based on the winner of another tier. [Blizzard_AuraContainerSlots.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_AuraContainer/Blizzard_AuraContainerSlots.lua) retains candidate sets and their winner in the secure environment—not a public, untrusted combat-data channel. We cannot honestly elect a cross-tier global second while preserving primary semantics by reading those private fields or cloning 62 containers per badge. This is a **documented missing public mechanism**, not evidence that every possible future client feature is impossible.

**P1 prototype implementation.** `SecondaryPortrait.lua` creates a small, noninteractive, native Totem-style circular rim and mask on each eligible host except PetFrame. It mirrors toward the health bars and uses positively verified `ResolveRaceBaselineAtlas` identity. The large portrait no longer gets race-overlaid; when no aura wins, Blizzard’s native 3D/class-icon option is visible. The existing Skyborne fail-closed art rule is preserved. `/bp secondary on|off` enables/disables this circle; existing `/bp test` shows a deliberately **synthetic** secondary icon for screenshot calibration. The local pet keeps full primary aura priority and its pet-family foundation.

**P2 is not implemented.** There is *no global runner-up election*, live second aura or secondary countdown in 0.1.179. In ordinary play, the small circle shows only verified race identity (or hides). Do not represent it as a full two-aura release. In-game screenshots for Player/Target/Focus/ToT/ToF/party, UI scale and overlaps are still required before P1 is visually certified. The next real task is finding/validating a **supported secure top-two mechanism**; a less-complete readability-limited selection mode would need an explicit product decision.

**Regression:** `tests/secondary-portrait.lua` checks geometry, mirror, mask, native atlas UVs, teardown, recycled-unit clearing, toggle, test-only art and PetFrame exclusion. CI runs Lua 5.1 and 5.4 including the new script.

---

## 1. Product decision and scope

Preserve the current high-priority large portrait, and add **one small secondary circle** next to the top corner of each eligible Blizzard portrait. The secondary circle represents the **second-highest verified, distinct aura/state**. When no second eligible effect exists, it shows the unit's **verified race portrait** if one is available.

Race artwork is **never drawn inside the main portrait** by bjarkiPortraits after this feature. The main portrait returns to the **native Blizzard portrait**, including Blizzard's own class-icon-versus-3D-portrait option, whenever it has no eligible higher-priority aura/state.

The primary must not be weakened, delayed or misranked to make the secondary appear.

**Enabled units (current approved scope):** `player`, `target`, `focus`, `party1` through `party4` on the regular Blizzard party frames.  
**Excluded:** `targettarget` (ToT), `focustarget` (ToF), local `pet` and party-pet frames for this feature. PetFrame **retains** its full single-portrait aura priority engine and pet-family artwork. Raid-style party/raid frames are likewise out of scope; do not hook arbitrary CompactUnitFrames.

There should be no additional portrait-priority tier, no new spell-ID classification, no extra guessing about states, no global polling loop, no addon-config framework, and **no duplicate copy of every tier container for every host**.

## 2. Visible state contract

| Eligible effects | Main portrait | Small circle |
| --- | --- | --- |
| Zero | Native Blizzard portrait or configured class icon | Verified race portrait, else hidden |
| Exactly one | Highest-ranked effect (including eligible state witness) | Verified race portrait, else hidden |
| Two or more | Highest-ranked effect | **Second-highest verified, distinct effect** |
| Second effect unreadable / its rank unprovable | Unchanged trustworthy main portrait | Verified race if safe, else hidden |
| Unit absent, recycled, vehicle-bound, or Edit Mode placeholder | Restore/retain native content according to existing host lifecycle | Hidden; never retain the previous unit's icon |

“Race” here means the positive unit-race evidence and supported artwork of `Core.lua`; it is not an NPC-family, inferred faction, guessed race, or pet identity. In particular, the **Skyborne** art safety policy stays: use a verified face atlas or leave the badge hidden. **Never substitute Blood Elf artwork.**

**Race fallback is identity, not an aura.** It never displaces an eligible second aura, participates in rank comparisons, inherits an aura timer, or uses a spell-ID slot.

The existing priority numbers remain authoritative. Example: a stun (320) outranks a defensive (290), which outranks Offensive (280). Two effects from the same priority lane must also be eligible to occupy the two circles when their distinct identity and order are available. An unknown second winner is **not** a license to show an arbitrary lower-tier effect.

## 3. Geometry / visual language

Reference native Blizzard art: `Interface/AddOns/Blizzard_UnitFrame/Mainline/TotemFrame.xml` from `Gethe/wow-ui-source` `forever` uses **`UI-HUD-UnitFrame-TotemFrame`** for a 30 × 30 border, a 22 × 22 icon and a `CircleMask` inside a 37 × 37 template. **Use these as reference dimensions/art**, not the native interactive TotemButton itself.

- Draw an addon-owned non-clickable circle using Blizzard artwork, native spell icons and a circular icon mask; it must not inherit totem dismissal, cooldown state or callbacks.
- Proposed first pass: **30 × 30 rim / 22 × 22 image** on large portraits, scaled proportionally for compact ToT/ToF and party frames after screenshot measurements. These are **starting values, not accepted final calibration**.
- Anchor near the top edge **on the side facing the health bars**. Player / standard party portraits with bars extending right: upper-right. Target / focus portraits with bars extending left: upper-left. Verify the actual orientation of ToT/ToF from Blizzard templates instead of guessing from the unit-token name.
- Prefer fixed out-of-combat frame-template geometry or an explicit validated per-frame orientation map. Do not inspect secret health-bar fill geometry in combat to decide where the badge belongs.
- A small offset outside the existing portrait rim should visually connect the circles without obscuring the main portrait, bars, frame name, level, PvP/combat/rest indicators, party ready check, or target/focus buff rows.
- Use Blizzard's atlas UVs/texcoords as authoritative. Never overwrite them with generic icon cropping. Treat icon cropping and circle-mask alignment separately; retain existing native border and mask ownership.
- No new click region, drag handler, tooltip interception or action bindings. Optional secondary-aura tooltip can be investigated separately **only if it is safe and does not steal clicks**.
- Secondary aura cooldown uses the existing `/bp decimals` policy (**one decimal strictly below 10 seconds**), no invented duration for static witnesses. Badge numerals may need an outside/below-ring label due to size. Race badge has **no timer, swipe or glow**.
- The main portrait's current fonts, masks, timer positions, frame geometry and native interaction remain unchanged.

## 4. Election and evidence contract (hard part)

**Current implementation:** `AuraEngine.lua` creates a native `CustomAuraContainerTemplate` + `AddAuraSlot` **per priority tier per host**. Higher frame levels display over lower levels, supplemented by guarded readable and static-state witnesses. This produces **a visual winner**, not an accessible, globally ranked list of two winners. `Priority.lua` uses reverse `AuraInstanceIDOnly` inside native lanes; some complete readable tiers explicitly prefer verified application time.

The new secondary must preserve this **single source of priority truth**. Define a bounded election abstraction conceptually returning:

```text
SelectTwo(unit):
  first:  verified candidate or nil  (must agree with today's main winner)
  second: verified distinct candidate or nil
  proof:  authoritative source / readability / identity needed for each
```

Candidate identity must be a trustworthy current aura instance ID when available, or a positively established, non-fabricated state witness. Do not confuse a spell ID with an occurrence ID, and do not show the same occurrence twice because it appears through both native and readable paths.

Ordering: greater numeric priority wins; within one tier use the current source's documented native tie-break, or the complete readable application-time election **only when its evidence is sufficient**. Do not make “last applied” a promise for Tracking: aura refreshes can retain an instance ID.

**Feasibility gate before implementation:**

1. Inspect Blizzard's `CustomAuraContainer` / aura-slot native interfaces on the current Forever client. Determine whether two *distinct, globally ranked* candidates can be elected and presented securely **without querying secret data from addon Lua**. Prototype with two buffs from **the same tier** and two from different tiers.
2. Confirm that the main portrait winner can remain exactly equivalent to the existing engine while the second is selected. Include readable-helper/static-state cases, native exact lanes and semantic fallback lanes; distinguish current screenshots from true proof of candidates.
3. Keep native aura processing native. Prefer **one shared candidate/election mechanism** that can project first and second; do **not** create a duplicate 62-lane stack for secondary on every host just because the current implementation has per-tier containers.
4. When a global second winner cannot be proven under combat secrecy, **do not fake it** by taking the next-lowest visible lane, guessing cooldowns or reading forbidden button internals. Fall back to the race/empty badge while preserving the primary. If the native client fundamentally cannot provide the requested behavior, document that limitation and stop for a design decision rather than shipping a falsely described “second highest” icon.

State-derived Ghost/form/Warrior stance/resurrection witnesses must be ranked under the **existing** priority policy, not treated as incidental race art. A native container and its readable helper may refer to the same current aura: they must not consume both slots. No historic or retracted evidence may be silently promoted back to a current portrait.

## 5. Implementation boundaries

**`Priority.lua` / `Spells.lua`:** leave all exact IDs, numeric tiers and filters unchanged. Only add a *selection interface* if the client feasibility result proves it can be implemented without duplicate policy tables.

**`AuraEngine.lua`:** refactor presentation into a primary surface and optional secondary surface owned by one host. Introduce second-slot rendering/timer/mask, but keep the existing main portrait untouched until the election path is proven. Move `createRaceBaseline` / `updateRaceBaseline` artwork to the secondary-only fallback. Do not leave a hidden main race texture that can reappear during aura handoffs.

**`Core.lua`:** own badge geometry, safe race-art lookup and orientation by verified frame layout. Preserve `ResolveRaceBaselineAtlas` restrictions, including Skyborne. Respect native class-icon option instead of forcing a class atlas.

**`Main.lua`:** reuse existing bounded/event-driven unit refresh and pooled party-frame lifecycle. Do not add `OnUpdate` scans or periodic re-election. A party frame may be recycled after an aura event; check live identity before showing either portrait.

**`PetPortraits.lua`:** leave local PetFrame's one-portrait aura host and family foundation alone. Do not make the secondary race system classify demons/totems/pets as player races.

**`Commands.lua`:** extend `/bp inspect <unit>` / layout diagnostics with provenance for `first`, `second`, `badgeFallback` and evidence/access reason. If a user-facing toggle is necessary, prefer one simple `/bp secondary on|off`, off during prototype, on after live certification. Avoid a new options panel.

**Cleanup:** all badge textures, masks, cooldowns and slot assignments must be hidden/destroyed on host teardown, native portrait restoration, vehicle binding, party pool handoff, frame-scale changes or /reload. Never retain old unit GUIDs/icon textures in a recycled host.

## 6. Phased work (deliverables and exit criteria)

**P0 — Source and native feasibility spike (no user-facing feature)**  
Document actual native API primitives and guarded second-winner evidence. Produce executable test for (a) two distinct auras in different lanes, (b) two in one lane, (c) restricted hostile unit, (d) duplicate native/readable occurrence. **Exit:** a credible plan for exact top-two selection with bounded cost and preserved first winner, or an explicit blocker.

**P1 — Geometry/identity prototype**  
For `player`, `target`, `focus`: add a noninteractive secondary rim and verified race fallback. Remove race from the large portrait fallback; restore native class/3D portrait. Compare with the user screenshot. Check corner mirroring, artwork masking and countdown visibility at multiple UI scales. **Exit:** no visual collisions, stable native portrait ownership and safe Skyborne fallback.

**P2 — True second-winner presentation**  
Wire the shared, feasibility-proven election to both circles; ensure source identification, distinctness, priority correctness, same-tier ties and cleanup on expiration. **Exit:** native/readable cross-lane cases pass without guessing when access is restricted.

**P3 — Regular party-frame rollout**  
Extend to the four normal party frames via the existing host pool, with smaller artwork and independently measured anchors. **ToT and ToF are excluded by user choice for now**, along with PetFrame. **Exit:** combat-safe unit recycling, visibility, party swaps, Edit Mode, pet/vehicle handoff and frame-scale changes pass.

**P4 — Live verification and release**  
Use test mode and controlled in-game cases, not just Lua mocks. Once the primary is never regressed and two winners are credible across supported relations, enable the small badge by default. Update README/ARCHITECTURE/KNOWN_ISSUES and package. **Exit:** regression suite + live screenshots approved; document any client-imposed gaps.

## 7. Acceptance matrix / must-not-regress

- Native Blizzard character-model vs class-icon option remains respected on main when no aura is selected.
- Race artwork **only in secondary**; unknown/non-player race leaves the fallback hidden, never a guessed race icon.
- Zero, one, two, three-or-more effects elect correctly; when second is not provable, no bogus second.
- Distinct highest/second effects inside **one priority lane**, across two lanes and across native+readable sources; no duplicate aura instance on both circles.
- A 330 immunity / 320 stun / 280 offense example maintains numeric priority; exact lower-tier 0 status never jumps ahead on combat entry.
- Cast-only WotF and school-lockout assumptions remain absent; no fabricated duration for a state.
- Countdown placement and decimals below 10 seconds work independently in both circles, including nil/permanent durations.
- Player, Target, Focus orientation, compact ToT/ToF, party1–4, known races, Skyborne, pets, NPCs and unreadable identity all have appropriate fallback.
- Party member leave/join, frame pool reuse, vehicle swap, changing target/focus, corpse/ghost, combat lockdown, scale changes, disconnect/reconnect and /reload leave no stale icon.
- Primary remains clickable, context menus/targeting/health bars untouched; badge is noninteractive and cannot steal mouse.
- No per-frame periodic aura-scan, no duplicated full-tier stack; bounded work on existing lifecycle events; measure CPU/memory against `0.1.178` at 10 tracked units.
- All existing Lua 5.1 / 5.4 tests continue passing. Add new simulated tests and explicit **in-game** proofs; a static source check alone is insufficient.

## 8. Deliberately unresolved until prototype

- Can Forever's secure aura container provide a genuine second winner after global priority reconciliation across exact/semantic/readable tiers? **This determines feasibility.**
- How should a second verified static state with no timer be shown relative to a native aura in the same numeric tier?
- Exact compact badge rim/icon pixels and countdown placement require real screenshots; the Shaman border atlas is a visual starting point, not a mandated widget.
- On a target that is not positively a player, secondary fallback remains hidden rather than inventing a generic race or creature icon.

**Scope control:** this document records the agreed feature direction and technical acceptance tests. **0.1.178 has neither. Experimental 0.1.179 implements the race-only/test badge, but NOT the two-winner algorithm.** Do not silently change numeric priorities or rewrite the current native aura-election behavior while implementing visual scaffolding.
