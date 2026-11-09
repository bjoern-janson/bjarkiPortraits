## 2026-11-09 — 0.1.203 full secondary-circle enlargement (visual test pending)

The 0.1.202 icon artwork was enlarged 22→26px but the circle
itself stayed 37px cell / 30px rim; a real screenshot showed the
badge still visibly the same size. Corrected by scaling the
**whole standard secondary component** to 44px cell / 36px rim /
31px masked art across the normal, native and pet-family paths.
Compact party badges now measure 35px cell / 29px rim / 25px art.

Native first-cell clipping offsets and group layout width
automatically follow the enlarged cell. Center anchor, race/rested-Z
side selection, cooldown fonts/decimals, primary portrait, aura
priorities and no-command behavior are unchanged. Lua CI tests
cover the full rim rather than only the inner icon. Final WoW-client
clearance and legibility remain to be visually confirmed.

## 2026-11-09 — 0.1.202 secondary artwork enlarged

The native runner-up worked in live play, but 22px spell artwork could
be difficult to distinguish behind its countdown. Increase the masked
inner image in NativeSecondProbe, PetSecondary and SecondaryPortrait
to 26px, keeping the 37px cell, 30px rim, positions, time formatting
and complete aura priority policy unchanged. Compact party artwork
grows from 18 to 21px within its unchanged 29px cell / 24px rim.

Tests verify art geometry but not final live legibility. If timer
text still covers too much spell detail, a future typography-only
pass can adjust that separately without changing buff selection.

## 2026-11-09 — 0.1.201 target race fallback with mixed helpful/harmful auras

The live Chero Ironhammer screenshot shows the large Target portrait
occupied by a shield-themed state and four helpful plus one harmful
native aura icons, while its small secondary circle still displays
race-like artwork. Its actual in-game target relation, player
classification and `secondReason` are not provided; a protected
harmful index is a plausible explanation, **not a confirmed cause**.

The prior native group ribbon required hostile=true and could never
help friendly/neutral Targets. These units still depended on a
complete Lua-visible union of helpful and harmful aura indexes.
An inaccessible harmful aura rejects the whole public second-place
election even if the helpful ones are readable.

Version 0.1.201 admits positively classified, positively related
friendly/neutral Target units to the native runner-up as a
**fallback only** when the existing public secondary is race/hidden.
Verified public aura/form secondaries take precedence, Ghost/form
static presenters suppress the new substitution, hostile Targets
keep their prior behavior, and an unconfirmed/non-player target
never gets an invented race baseline. Existing pet-family art
remains beneath the true secondary when available.

This does not prove that Chero's specific target state is now fixed
or that the visible icons all qualify for the priority tiers.
No in-game commands are required. Await visual retest of
0.1.201 on the same type of friendly/neutral target.

## 2026-11-08 — 0.1.200 targeted pet secondary identity

**Live trigger:** A targeted Hunter pet (“Bird of Prey”) has a
high-priority fiery effect in its large portrait but no smaller
secondary. A non-player pet has no player race portrait, so the
earlier secondary fallback intentionally stayed hidden.

**Change:** Only positively classified Hunter/Warlock pet units on
Target/Focus can now show a verified family/summon image in the
second circle. The standard `PetPortraits` classifier supplies
the owner and family; `ResolveObservedPetSecondaryArt` requires a
readable current GUID and a real family image, refusing wild beasts,
totems, unknown pets, stale target identities and generic Growl.
No private aura spell identity or count is accessed.

**Naked-pet rule:** Two native helpful/harmful group frame providers,
each limited to one button, conditionally render the same family icon
when an aura exists. The family fallback is absent when both groups
have no assigned aura, even if the Target's normal 3D model exists.
The existing public/native second-aura systems render above this
fallback, so second-ranked aura artwork retains priority.

**Risks and verification:** Live Forever proof is still needed that
native `AddAuraGroup` frame providers hide unassigned preallocated
buttons and update both polarities correctly through combat/target
handoffs. Two simultaneous helpful/harmful groups may draw the same
ring twice, requiring cosmetic adjustment if visibly too bold.
Current system fails closed for an unrecognized pet family or secret
current GUID. No change to priorities, no new in-game commands.

## 2026-11-08 — 0.1.199 PlayerFrame secondary race on incoming debuff

**Live report:** On PlayerFrame, a newly received short harmful effect
(~1.5 seconds remaining) becomes the main portrait, yet the small
secondary returns to the race icon while other active auras are shown.
This screenshot does not expose the current Lua rejection reason.
The source does expose a structural gap: the existing secure
NativeSecondProbe covered hostile Target only; PlayerFrame still used
a complete public-only runner-up election which can fail after new
harmful `UNIT_AURA` updates when public identity is restricted.

**0.1.199 experiment:** Prepare native group ribbon for PlayerFrame
out of combat, with the second cell anchored at the outer upper-left
(+5 offset), matching the previous accepted badge location. Leave
the secure ribbon hidden while the existing public runner-up is
positively presented. If the public reader falls back to race,
present native cell #2 *over* that race without querying private
aura IDs. Require positively friendly player identity, visible
enabled frame and no independent Ghost/form state; all other
frames keep their current paths. Ensure player ribbon can be
initialized without commands on login or the next ordinary OOC
refresh and cannot be created inside combat.

**Verification:** Lua 5.1/5.4 source-backed mock tests cover states and
guardrails; client validation of two actual native aura buttons,
layout order, semantic duplicates and performance is still pending.
No changes to exact spell priorities, countdown thresholds, or
native icon dimensions. The earlier request to enlarge 22px icons
remains outstanding as a separate visual pass.

## 2026-11-08 — 0.1.197 hostile player race fallback despite visible auras

A screenshot of an opposite-faction player showed the race tile in the
small Target portrait while multiple aura icons were visible under the
native Target frame. The prior 0.1.196 native second prototype was
explicitly guarded by `isPlayer == false`; it could work on hostile
NPCs but **never** on hostile players. That exclusion, rather than
proven missing public aura data on this particular opponent, explains
why this screenshot never exercised the new native rendering path.

0.1.197 admits positively identified hostile players on Target to
the same automatic secure ribbon. The existing verified race fallback
remains *under* the native viewport for enemy players, so there is
still a baseline portrait if no second native candidate is drawn.
Hostile NPCs continue hiding their old empty badge. Friendly/unknown
targets, Focus, Player, Party, ToT/ToF and the primary portrait are
unchanged. The native runner-up is still experimental, and the screenshot
does not prove two *eligible*, distinct effects under the current tier
filters. Test the behavior visually without slash commands.

Icon enlargement is a separate, deferred task: current native button
size is 37 with a 22px inner icon and 30px border; timers can obscure
the artwork, as observed on Winter Wolf.

## 2026-11-08 — 0.1.196 no-command native2 handoff

The native aura-group ribbon now initializes automatically on the first
positively identified hostile NPC selected as Target **outside combat**.
No `/bp native2` command is needed or accepted. This prevents the native
group constructor's batch preallocation on ordinary login and friendly
targeting. If first encountered in combat, automatic construction waits
until the next normal out-of-combat host refresh, without polling.

Existing prior `nativeSecondProbe=false` saved settings are ignored;
the global enabled and normal `secondaryPortrait` settings remain
authoritative. Optional `/bp secondary debug target` remains available
for troubleshooting, not routine testing. There is still **no live
confirmation** of the native second-cell clipping or semantic overlap
correctness; this change concerns setup and initialization only.

## 2026-11-08: secure-group native2 prototype (0.1.195, live test pending)

The 0.1.194 Kobold debuff-only failure was confirmed as
`reason=inaccessible-index` from a complete public aura scan. The
fully native main portrait nevertheless renders one harmful aura.

The new **opt-in** `/bp native2 on` proof tests whether a single
native aura container with multiple priority-ordered `AddAuraGroup`
groups can securely lay out a top-two strip while the addon exposes
only cell two through a clip viewport. The experiment does **not**
query secret data or replace the primary system. `/bp native2 off`
reverts to the existing public runner-up.

Unverified: native group layout/overlap across semantic tiers,
first/second positioning, clip behavior in the live game, native
button visibility after a target swap, runtime frame construction
cost. Do not treat a compiled mock or published client source as
evidence that a second icon was shown. Target NPC only; original
secondary remains default. If the experiment shows a duplicated
primary or empty cell, report screenshot and `/bp native2 status`.

## 2026-11-08: confirmed NPC public-aura denial in 0.1.194

**Live paired observations:** A hostile Kobold with two debuff icons and a
working main portrait has no secondary circle; another hostile NPC with
a helpful buff *does* display a small secondary icon. The first target's
read-only `/bp secondary debug target` reports:

```
mode=hidden id=none tier=none reason=inaccessible-index
hostile=true player=false playerReadable=true assist=false
hList=false hCount=0 nativeHarm=true writes=0
auraEvent=changed-or-unreadable
lastDrop reason=not-two-presentable prior=19740
```

The **current** failure is `inaccessible-index` from
`SecondaryPortrait.collectCurrentAuras`: `GetAuraDataByIndex` either
throws or returns a value that fails `R.CanAccess` on one of the
inclusive HELPFUL/HARMFUL scans. The helper's `hList=false` with
`hCount=0` is consistent with inability to complete its helpful scan,
but the current diagnostics do **not** identify precisely which filter
and index denied access in the secondary reader. `nativeHarm=true`
and `writes=0` rule out the previously suspected broad exact-harmful
gate and native-write failure *on this pass*. The `lastDrop` row is
historical: spell 19740 (Blessing of Might) describes the previous
candidate, not a current proof for the Kobold.

The successful buff-bearing NPC case demonstrates that the secondary
presentation itself works under at least some readable hostile states;
it does not establish that a helpful buff *causes* read permission
(the units/combat/secret state may differ).

**Policy:** Do not interpret visible Blizzard debuff icons as Lua-readable
identity. Native `AuraContainer` can display a secret winner internally
while addon code cannot enumerate a complete globally ranked list.
The priority-preserving, public-evidence-only secondary reader must
continue to hide the NPC secondary if it cannot establish two distinct
current candidates. No further gate relaxation or cache-based fabricated
runner-up is authorized by this screenshot. Revisit only with an
established secure, native top-two presentation primitive or new
per-filter live evidence; keep 0.1.194 as current build for now.

## 2026-11-08: 0.1.194 hostile NPC has native debuffs but no secondary

Kobold Tunneler Target at level 6 shows two native debuff icons and one
timed main portrait aura, but the secondary circle remains absent
in the live 0.1.193 screenshot. The current `secondReason` is **unknown**
because no debug output accompanies this screenshot. Native icons do
not prove their identity/timing is exposed to addon Lua.

Two overly restrictive independent guards were corrected in the
experimental 0.1.194 branch: (1) a positively identified hostile NPC
need not pass the separate HELPFUL-only helper's election before
its own complete, public helpful+harmful runner-up election; (2) the
last successfully applied, addon-owned native harmful slot state can
positively establish enabled status when `IsEnabled()` is unreadable.
A known disabled state cannot. The same public-occurrence, filtered
membership, tier ordering, native first-place slot, and no-private-winner
requirements remain; hostile players are not relaxed.

This is **not yet an in-game confirmed fix**. If the NPC still has no
secondary, capture `/bp secondary debug target` while it is selected.
A failed complete read (`inaccessible-index` etc.) requires fresh
client evidence and cannot be bypassed safely.

## 2026-11-08: v0.1.193 combat race fallback (awaiting client retest)

Screenshot: player enters combat with a visible high-priority fire buff in
the main portrait, multiple native aura icons, and the secondary circle
returning to its race fallback. There was no live `secondReason` output,
so no specific in-game secrecy or native-frame failure is yet proven.

Source audit found three possible premature fallbacks: (1) every
`UNIT_AURA` previously dirtied the last positive, including an unrelated
removal-only delta; (2) repeated native SetEnabled/SetShown calls even when
their previously applied state was unchanged; and (3) re-writing a fully
confirmed identical secondary candidate instead of retaining its prior
countdown during combat. The experimental 0.1.193 branch corrects these
cases with guarded event delta evidence, unchanged-state write caching,
and exact same-instance retention. Any unverified aura addition/update,
missing/secret event payload, expiry, or failed native write still
fails closed. No primary tier level or icon positioning changed.

If the 0.1.193 build still shows the race icon, use
`/bp secondary debug player` while the failure is visible; the
`lastDrop` and `auraEvent` evidence can distinguish which guard
remains responsible without another guessed change.

## 2026-11-08: v0.1.192 screenshot follow-up (live verification pending)

- **Boosted Rest on entering combat:** The exact harmful relation gate
  excluded a current, positively readable Boosted Rest from the secondary
  election unless Ghost was primary. 0.1.192 removes that special dependency
  for a complete, public, verified friendly aura union. Native priority 0,
  first-place selection, and ordinary HARMFUL membership proof are unchanged.
  A genuinely inaccessible current combat snapshot still fails closed or
  uses the previously bounded, positive secondary hold; it is not treated as
  evidence of an aura.
- **NPC with two visible debuffs but no second circle:** A verified generic
  native harmful slot may now admit the hostile non-player projection even
  when broad exact harmful permission is unavailable. This does **not**
  demonstrate that combat aura identities or private native winner contents
  are readable on that creature; all final positive slot checks remain.
- **Status:** Source/model regressions are added, but this actual Forever
  combat transition and Rockhide Boar have not yet been retested in-game on
  0.1.192. Use `/bp secondary debug player` and
  `/bp secondary debug target` at the failure moment to distinguish
  `native-filter-unreadable`, `hostile-list-unreadable`,
  `npc-native-slot-unreadable`, and `not-two-presentable`.

# Known issues and bugs

**0.1.191 Ghost-first secondary aura (2026-11-08):** Live `/bp secondary debug player` while dead showed `secondReason=static-ghost-witness` despite Ghost owning the large portrait and Boosted Rest (42 minutes) appearing in the native debuff row. `SecondaryPortrait.GetReadableSecondaryAura` previously returned immediately on `_ghostActive`, preventing every lower effect from being considered. The new Ghost-first path requires the existing static main Ghost presenter to be positively established from a current `UnitIsGhost` witness or an observed Ghost aura, ranks it at the *existing* Immunity+2 presentation level, removes redundant Ghost aura IDs from the lower candidate list, and allows a **publicly readable** exact priority-0 Boosted Rest occurrence to become second. A Ghost-only unit shows the race/hidden fallback; missing identity or incomplete public aura data still fails closed. Ghost/Waiting-to-Resurrect equal-level ties remain unknown. No change to numerical aura tiers or native main portrait. `tests/secondary-ghost-state.lua` and `tests/secondary-ghost-real-host.lua` cover both real spell mappings and the actual `R.UpdateHost` path. Live-client behavior when harmful aura data becomes restricted remains to be verified.


**0.1.190 confirmed priority-initialization bug (2026-11-08):** The `/bp secondary debug player/target` result `secondReason=not-two-presentable` with multiple visible buffs exposed a real source/manifests mismatch. Beginning in v0.1.188, `SecondaryPortrait.lua` initialized a sorted `rankTiers` at file load, but both `.toc` manifests put **SecondaryPortrait.lua before Priority.lua**. The table was forever empty, and the scanner could never assign any aura to a tier. Prior tests unintentionally loaded Priority first, masking the defect; the earlier 0.1.189 filter checks therefore could not fix these live symptoms. Version 0.1.190 loads Priority before Secondary in both manifests **and** defers rank cache initialization until `R.TIERS` exists, with explicit `tiers-not-ready` diagnostics. Exact prior-order reproduction: old `second=nil / not-two-presentable`, fixed `second=1126 / verified-readable` for Mark of the Wild behind Thorns. Tests cover actual manifest ordering and the deliberately wrong runtime order. No aura priority/tier or secure main-portrait change. **Live client confirmation is still required**, especially under combat-restricted auras and NPC private aura evidence.


**0.1.189 filtered aura membership and mixed NPC projection (2026-11-08):** New screenshots show a friendly target and the player falling back to race, while a hostile NPC with two debuffs still has no second badge. Their exact live `secondReason` is unknown: screenshots alone cannot prove whether combat secrecy, missing optional fields, a native slot, or another gate caused each fallback. The code had two *reproducible* gaps. (1) For exact ordinary HELPFUL/HARMFUL lanes, an unavailable `isNameplateOnly` boolean plus inaccessible `IsAuraFilteredOutByInstanceID` wrongly rejected an otherwise positively visible aura. A bounded matching plain-polarity `GetAuraDataByIndex` membership scan now supplies proof of that exact **current occurrence**, with duplicate/mismatched IDs rejected and no polling. (2) NPC harmful projection previously required **zero helpful auras**, even when a harmless low-priority helpful buff could not displace the verified native harmful primary. Complete mixed public lists can now be ranked together, requiring a harmful first-place winner and an enabled native main slot; an unproven helpful first remains rejected. Hostile player safeguards, unseen semantic filters, combat secrecy and existing aura tiers remain unchanged. New `/bp secondary debug [player|target|focus|party1-4]` prints the last stored reason and eligibility in two short lines. **Live confirmation remains pending**; a new race/hidden fallback should be diagnosed rather than guessed.


**0.1.188 hostile NPC secondary harmful auras (2026-11-08):** A Kobold Tunneler screenshot showed two debuffs under Target and one timed harmful icon in the main portrait, but no small second circle. The previous secondary reader required a positively displayed hostile HELPFUL or form primary; hostile NPCs with harmful-only auras had neither and were excluded before ranking. This build adds an *NPC-only* harmful public projection for Target/Focus: positive non-player identity, readable hostile relation, a complete empty helpful list and complete harmful indexed list, permitted harmful exact filter, and an **enabled matching native harmful main tier**. Known higher-tier effects are ranked first; irrelevant lower semantic native-filter probes no longer veto them. Generic `SmallFriendlyHarmful` can also be the primary only if its same-filter public evidence and native slot enablement are positive. Hostile players and unproven NPC/mixed-polarity/secret-primary cases remain excluded. **This cannot directly verify a secure rendered primary**, so it is a controlled projection that still needs live testing. Unreadable or single-aura NPCs show no secondary icon (NPCs do not receive guessed race art). Use `/bp layout target` to inspect `secondReason`; `npc-readable-harmful-projection` indicates selection via the new path.


**0.1.187 Shiny Silver Coin bottom priority (2026-11-08):** The screenshot shows a 30-minute +30 Fishing **helpful** buff. The applied aura is spell `1321323`; `1321320` is the item-use/trigger spell and is not classified. To share **numeric level 0** with harmful Boosted Rest/Tricked or Treated/Tamed, `Priority.lua` has a minimal `BottomHelpful` native HELPFUL exact lane at 0 (a helpful aura cannot be put into the existing HARMFUL-filtered BoostedRest slot). `buffs_bottom` contains only the applied coin aura; the Important/HostileHelpful generic fallback exclusion prevents inappropriate promotion. Gathering 1 and every other numeric tier stay unchanged. The helpful and harmful bottom lanes can each have a candidate; simultaneous cross-polarity tie resolution remains native-container-dependent. The effect's live portrait visibility still needs checking on target/self after /reload.


**0.1.186 PetFrame source-icon rim cleanup (2026-11-08):** A screenshot of the player's Imp shows a straight top-edge fragment from a square spell icon inside the small circular pet portrait, while the same effect appears better cropped on Target. PetFrame is a 37px icon aperture; its previous `1/64` source crop removed less than a rendered pixel from each side. The shared `R.ApplyPortraitIconCrop` now uses `3/64` **only on local `pet`**, covering secure/readable pet aura icons and pet-family artwork without moving the Blizzard ring or mask. Player, Target, Focus, ToT/ToF and party icon crops remain unchanged. Source-level regressions confirm the values and both callers; whether this fully conceals every native spell-icon border still requires live visual testing.


**0.1.185 out-of-combat form ranking fix (2026-11-08):** A live Warrior screenshot showed the race badge even with a high-priority timed aura on the main portrait and Camp Benefits active. The secondary reader previously treated `host._formStateActive` as proof the form **must** be the primary and returned `form-not-proven-primary` whenever an aura outranked it. Now positively verified forms/stances compete at existing static priority **149**: stronger aura may be primary, form may be second (with no aura-instance ID or timer), or two stronger auras take the two slots. A form alone still falls back to race. On hostile units, an aura-first result requires the current main aura's exact spell/tier/instance to match; unknown form textures and incomplete evidence fail closed. In the concrete Welcoming Campfire 257 / Battle Stance 149 / Camp Benefits 90 ordering, **Battle Stance is second**. Offline regressions include actual spell priority tables and the real Warrior host-update path; live-client visual confirmation remains pending. The 0.1.178 `main` branch is unchanged.


**0.1.184 outer badge corners and combat transition (2026-11-08):** The secondary circle now sits at the upper-left of player/regular party portraits and the upper-right of target/focus portraits, away from rested-Z and party-leader UI. The slight 5-unit inset avoids clipping near screen edges. ToT/ToF and pet retain no secondary circle.
Entering combat can seal the complete aura list. When an **already verified timed** second aura becomes unreadable without a preceding UNIT_AURA event, the addon may retain that last positive until the first aura change, its known expiry (a one-shot timer), or a changed/unreadable GUID on nonplayer units. Permanent auras and unproven frame/identity conditions are never retained. This is *not* a universal in-combat runner-up election or a claim that the cached candidate remains exactly second. `/bp layout <unit>` shows `combat-positive-retained:<reason>` while held. Verify visually in the live game; normal combat aura-change events can still cause a race fallback.


**0.1.183 guarded hostile target second aura (2026-11-08):** Live player-side selection worked after the friendly-relation correction, but a target showing Camp Benefits and another camp-related buff still displayed an identity badge. The reader in 0.1.182 expressly returned `hostile-unavailable` for hostile targets and rejected all form witnesses. This update allows **only publicly complete target aura sets with verified first-place evidence**. A readable hostile main helper must agree in spell ID, tier, *and aura-instance ID* with the first-ranked public candidate; otherwise it fails closed. An already positively displayed Warrior/Druid form at existing priority 149 may instead be first when all public candidates rank lower, allowing Camp Benefits (90) to be second. The ordinary secure main portrait, race fallback, spell priorities and party/pet/ToT/ToF scope are unchanged. Additional `/bp layout target` fields report `hostileMain` and `hostileList`. If identity or evidence is hidden, the badge still falls back; **live confirmation of this specific target remains outstanding**.


**0.1.182 confirmed friendly-relation loss (2026-11-08):** Live `/bp layout player` reported `assistReadable=true assist=true` and `secondReason=relation-unreadable`. Source inspection found `host._hostileUnit = hostileRelationReadable and hostileUnit or nil` in `AuraEngine.UpdateHost`. In Lua, `false or nil` evaluates to `nil`, so *every readable friendly* hostile=false relation lost its value before `SecondaryPortrait.GetReadableSecondaryAura`. The fix explicitly assigns `false` when the relation is readable and reserves `nil` for unknown. Regression checks run through **real `R.UpdateHost`**, including friendly, hostile and inaccessible relation cases and a two-buff secondary election. `/bp layout` adds `hostileReadable` and `hostile` diagnostics. This removes the confirmed early rejection, but subsequent public-aura, semantic-filter, combat and visible icon cases still require live verification. Stable main remains 0.1.178.


**0.1.181 exact native-polarity proof and compact opt-out (2026-11-08):** The 0.1.180 readable election required a second `C_UnitAuras.IsAuraFilteredOutByInstanceID` call for every candidate, including already-known exact auras returned by a matching complete native scan. That extra call can be inaccessible to non-secure add-ons and force race fallback unnecessarily. v0.1.181 skips it **only** when exact spell membership, eligible unit relation, a compatible scanned polarity, and the non-nameplate-only bit are positively established; all semantic and unknown cases still fail closed. Separate Lua tests cover the real spell-tier maps and the restricted-oracle case. Secondary circles are now **disabled on ToT/ToF** as requested, while their original primary portrait engine remains. Native client behavior and the precise original live failure remain unconfirmed without `/bp layout player` evidence; test with two known buffs outside combat. The 0.1.178 `main` release remains unchanged.


**0.1.180 readable secondary aura and layering experiment (2026-11-08):** v0.1.179 placed the Totem-style circle below native frame artwork. v0.1.180 instead uses a noninteractive, pooled UIParent overlay with higher strata, anchored to the real portrait. A **complete readable** helpful/harmful aura snapshot may now elect a distinct second effect on a friendly unit, provided native filter and ordering evidence are all accessible. This is not a secure cross-tier native runner-up. Hostile, incomplete, inaccessible, ambiguous same-level, static-state, or failed-filter cases fall back to race/hidden. Native combat taint, exact live visual layering, scaling and true second-winner agreement remain **unverified in game**; `/bp layout player` reports the diagnostic reason. Main remains stable at 0.1.178.


**Experimental 0.1.179 secondary prototype:** verified race artwork now uses a noninteractive small circle; the large portrait falls back to Blizzard class/model artwork. There is **no genuine second-highest aura** yet. The current Forever native aura-slot API lacks a supported global second-winner selection across tiers, and an inaccessible winner must not be guessed. `/bp test` displays synthetic art for visual calibration only. See [the design plan](docs/SECONDARY_PORTRAIT_PLAN.md). Main's 0.1.178 runtime is unaffected.


**Current candidate: 0.1.178-bottom-harmful-consolidation-test (2026-11-08).** See [architecture section 35](ARCHITECTURE.md#35-pet-regular-party-frames-skyborne-safety-and-absolute-bottom-tier-0117301178-2026-11-07-to-2026-11-08) for the post-0.1.172 changes and [the planned secondary portrait](docs/SECONDARY_PORTRAIT_PLAN.md) for the next feature (not yet implemented). Prior sections retain historical caveats; no full live-client certification is claimed.

**Open: Tracking "last applied" behavior.** Same-tier native election uses reversed aura instance IDs, which do not necessarily change on a buff refresh. The portrait can continue to show an older effect after reapplication. Find Treasure was deliberately moved to Gathering (priority 1); tracking/sensing stays at priority 3. No general Tracking application-time correction has yet been implemented.

**Open: bottom-tier harmful combat visibility.** Boosted Rest (1229451), Tricked or Treated (24755), and Tamed (19685/19686) now share one exact harmful tier at **priority 0**. A generic harmful fallback at level 175 can otherwise overpromote identity-restricted auras. The native max-duration filter of 3,599 seconds preserves Boosted Rest suppression there but also excludes other hour-long/permanent harmful fallback effects. A live combat retest of the combined tier and collateral visibility remains pending.

**Open: PetFrame and party frame live behavior.** v0.1.174 gives the local pet the same full native aura-priority engine as player/target; v0.1.175 adds regular pooled party1–4. Simulated checks covered native binding, party recycle and restoration, but live combat/vehicle swap, pet identity, layout scales and aura access deserve verification. Raid-style party and party-pet portraits remain out of scope.

**Open: Skyborne artwork quality.** v0.1.176 excludes low-resolution Skyborne raceicon artwork that appeared as a blue gradient. The new validated square atlas may still be absent or contain unsuitable art; the intended safe behavior is Blizzard's native portrait, not a fabricated Blood Elf face. Confirm visually in-game.

**Planned, not implemented: secondary portrait.** The next feature would add a small Totem-style circle for the second distinct aura, falling back to race identity, and move race off the main portrait. This is an architectural feasibility project, **not** included in v0.1.178; see [the plan](docs/SECONDARY_PORTRAIT_PLAN.md). The current main race fallback has not yet been changed.

**Open: new launch aura coverage.** Sapta Sight, Hunting Kobolds, Violet Flames, Rushing Charge, Savagery, Tamed Strigid Screecher, both Poised applied variants, and the helpful Frog Form transformation have passed classification tests, not a complete in-game cross-relation audit. Frog Form requires a helpful exact Control lane at 310; it must not be mislabeled a harmful Polymorph aura.

**Resolved non-addon alarm:** ToT/ToF frames were initially disabled by an in-game setting, not by bjarkiPortraits. The setting must be enabled to see those frames.


**0.1.161 class aura repair (2026-11-02).** Portraits adds 157 applied spell IDs from the nine-class audit to existing priority tiers. These include intermediate ranks, Sniper Shot’s range buff, Combustion’s critical-strike buff (28682), and separate recipient effects such as Mana Tide (1325257). Friendly Target-of-Target and Focus-of-Target can recover a readable slow at priority 278 when native filtering is restricted. Current-build display and protected aura access still need an in-game check. The audit’s 14 qualified candidates remain open.

**Class aura repair (2026-11-01):** `0.1.160-class-aura-fixes-test` adds 131 reviewed applied aura/rank IDs across all nine classes. Distract is harmful status, Intimidation's pet preparation is helpful offense (separate from its target stun), and Riposte joins the existing disarm/control category. Mind Vision ranks 1/2 use a harmful tracking filter at the existing tracking priority of 3, with guarded readable recovery. All other existing exact ownership and all existing numeric tier levels are preserved. Source and native-filter regressions pass on Lua 5.1/5.4, including both helpful/harmful polarity and mixed cast/application cases. Primary spell definitions were checked against current Forever database pages; for any listed ID, the source lookup is `https://www.wowhead.com/forever/spell=ID`.

**0.1.160 verification boundary:** earlier live observations remain valid, including WotF removing control without an applied buff. The new exact entries and Mind Vision filter/recovery need current-build in-game visibility checks; missing prior entries did not prove native fallback invisibility. Unresolved applied IDs (including Combustion), uncertain older Druid Lacerate variants, and cast-only/hidden records were not inserted. Warrior stance state and the strict-below-ten-seconds portrait timer retain their existing behavior.

**Ten-second decimals (2026-10-31):** `0.1.159-ten-second-decimals-test` uses one decimal strictly below ten seconds with `/bp decimals` on, whole seconds at ten and above, and a matching compatibility threshold. Decimals off and the existing long-duration hiding rule are unchanged. This supersedes the five-second policy below; live-client verification remains pending.

**Warrior stance experiment (2026-10-31):** `0.1.158-stance-test` supports Battle (2457), Defensive (71), and Berserker (2458) through the existing static form-state presenter. The player's own stance uses the active shapeshift-form API, including positively identified self aliases. Other Warriors require a single readable, current exact stance aura; absent or restricted evidence leaves the stance unknown. Hidden stance auras may never be exposed by Forever for other players. On a non-Warrior, use `/bp stance target` while a targeted Warrior switches stances to inspect the available evidence. `UNIT_FORM_CHANGED` identifies a unit, not its new stance. Live cross-faction/combat behavior remains unverified. See architecture section 33.

**Audit repairs (2026-10-31):** `0.1.157-audit-fixes-test` addresses the reproduced Roots/Control fallback omission, Quitter promotion, first-match Waiting-to-Resurrect election, failed-access-check behavior and failed native portrait restoration. New behavioral regressions exercise those source paths. These repairs do not close historical live Battleground/rendering reports without client verification. WotF removes CC on use and has no applied buff, so it remains excluded. See architecture section 32.

**Correction (2026-10-27):** `0.1.154-priority-scope-correction-test` restores Roots 300, Slows 278 and Dazed 279. Their decrease in v0.1.153 was not requested. WotF (7744) is removed from all portrait aura categories: the user's direct Forever test observed no WotF buff, and a cast-only effect cannot be displayed as an invented immunity aura. Tests lock all retained pre-overhaul priority numbers except the two explicitly requested changes (Utility and OffensiveHarmful). No other spell classification from the consolidation is changed.

**Priority consolidation (2026-10-27):** `0.1.153-priority-consolidation-test` merges redundant tiers (Divine Protection, defensive racials, Weakened Soul/bandaging, shields, flags and informational debuffs), reclassifies reflection/Free Action/Voice/Grounding/Blink and adds a dedicated applied-stun and interrupt/silence readable election. The existing Charge, Intercept, Cheap Shot and Pounce stun IDs were already listed; missing live display may still reflect protected/absent aura evidence. The distinct Pounce bleed remains DoTs. Unverified shape-only Chilled/Frost Armor approximations are removed; true unreadable auras may now fall back more conservatively. Combat/taint and target/focus cross-faction visibility require Forever testing.

**Five-second decimals restored (2026-10-26):** `0.1.152-five-second-decimals-test` restores portrait aura countdown decimals strictly below five seconds with `/bp decimals` on; the whole-second rule starts at five and the native compatibility threshold matches. The older three-second policy is historical; live-client verification is still pending.

**Low-priority aura reintroduction (2026-10-26):** `0.1.151-low-priority-tracking-status-test` restores Find Herbs/Minerals, Tricked or Treated, Boosted Rest and all other tracking/sensing buffs as three visible exact tiers immediately above race portraits. Their semantic fallback exclusions remain, to prevent promotion above combat effects. Self/friendly informational debuffs also receive a guarded readable helper; actual Forever display in all client secrecy states still needs validation.

**v16 suite update (2026-10-22):** this addon receives release-version metadata only. Its behavior is byte-identical to v15 apart from that version string. The three timing repairs are in bjarkiCC Model/Observer. The full v16 suite passes 49 regression scripts and 28 runtime syntax checks on both Lua 5.1 and Lua 5.4; live-client findings below retain their existing status. The behavior described in architecture section 25 remains applicable.

Historical status recorded 2026-10-08 for **bjarkiPortraits 0.1.80-local**. Current candidate source is **0.1.172-frog-form-control-test** (2026-11-07); historical items below are not automatically closed by that update.

The items below reflect reports and screenshots from Battleground sessions.
They remain open until checked in the live client against this build. A report
describes a visible symptom; it does not by itself establish the failing code
path or root cause.

## Battleground pet portraits

- Hunter and Warlock pet portraits have been reported missing or incorrect
  for both friendly and enemy pets in Battlegrounds.
- Hunter pet artwork worked outside a Battleground in at least one earlier
  report, so that observation does not establish BG behavior.
- Warlock pets have also been reported with an unexpected Growl icon.

## Opposing-faction aura categories and priority

Aura display for opposing-faction units in Battlegrounds has been reported to
miss expected effects or choose the wrong category. Treat these as category
selection/eligibility reports, not a request for individual spell-ID patches.

Reported expected behavior and symptoms:

- Drink should rank above DoTs.
- Honorless Target should rank above healing-over-time effects.
- Water Breathing should be in a near-bottom water-utility tier alongside
  Endless Breathing and Aquatic Form.
- Leader of the Pack should not surface at a high priority.
- Blessing of Freedom, Stoneform, and Divine Protection have been reported
  missing from the expected display.
- An enemy Healing Stream Totem was shown with a white portrait and no aura;
  hostile red coloring and its aura were expected.

The priority table alone does not explain whether an effect was omitted from a
secure filter, unavailable through the hostile-unit API path, or lost during
the display election. Diagnose those stages separately before changing spell
membership.

## ToT/FoT border bleed

Aura artwork on Target-of-Target / Focus-of-Target has been reported peeking
past the small portrait border. The frames were later restored and visible;
the remaining report concerns clipping/layering.

## Secret aura-update metadata

Version 0.1.71 raised a Lua error on Battleground entry when addon code
boolean-tested the secret `updateInfo.isFullUpdate` field. The current source
has guarded aura-update metadata access, but this path has not been confirmed
in a live Battleground on 0.1.80-local.

## Verification boundary

No live WoW test has confirmed these reports fixed in 0.1.80-local. See
[`ARCHITECTURE.md`](ARCHITECTURE.md) for implementation boundaries and the
reported BG findings. Class-colored unit-frame failures are tracked in the
[bjarkiUI issue list](https://github.com/bjoern-janson/bjarkiUI/blob/main/KNOWN_ISSUES.md).

## Post-patch follow-up (0.1.130, 2026-10-17)

- The Ghost/Resurrection Sickness helper construction failure was observed and its repaired display confirmed in game. This does not establish that every aura reader behaves correctly through all client secrecy transitions.
- Enemy Moonfire on Player/self Target was reported working with the identity-blind native harmful fallback. During restricted reads, this fallback cannot identify the exact harmful spell or guarantee its category-specific priority.
- Opposite-faction stun / full-DR aura lockouts may temporarily make helpful aura indexing unavailable. A live probe observed readable DRUID + ENERGY/RAGE and led to the independent, guarded form-state presenter in 0.1.130. The user reported that candidate looked good. Extended CC transitions, temporary relationship restrictions, and other classes/forms still need coverage.
- Opposing-faction tracking suppression remains intentional. Permanent helpful buffs on hostile units are excluded from the broad fallback so tracking effects (e.g. Find Minerals) do not mask important auras; only verified current unit-state witnesses may present a form.
- The post-patch portrait geometry and timer centering were visually calibrated in normal client screenshots. Remaining image-specific clipping under unusual pet icons, BG pet portrait binding, and Focus recycled-unit behavior merit further live checks.
- The current countdown formatter truncates whole seconds rather than rounding nearest to match Blizzard's display at examples 29.8 and 22.8. The actual timing engine is unchanged.

## 0.1.131 potion debuff follow-up (2026-10-17)

- Rapid Poison (`1231579`) and Foul Disease (`1231580`) were added to the existing DoTs category for the Greater Discolored Healing Potion. Confirm both applied auras and their priority against overlapping status effects under actual Forever combat; offline checks do not establish active-aura readability or native-frame presentation in every PvP context.
- Retain earlier open Battleground, hostile secrecy, pet frame, and recycled Focus investigations. This scope does not constitute a live regression audit.
