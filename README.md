# bjarkiPortraits

A native-styled portrait-aura addon for **WoW: Forever**, displaying the highest-priority eligible, positively observed aura or state on Blizzard's portrait regions.

**Experimental branch:** `0.1.215-well-rested-target-handoff-test` (2026-11-09), built on 0.1.178. The native second-aura ribbon now supports friendly and neutral Targets as a guarded fallback when public aura ranking fails, while preserving valid second-place auras, character-race underlays and pet-family fallbacks. No in-game commands or new settings.

## Install

Install the **`bjarkiPortraits`** folder in your game's `Interface/AddOns/` directory, with the thirteen `.lua` modules and both `.toc` manifests directly inside the folder. Enable the addon and `/reload`. Blizzard's in-game unit-frame settings still control whether ToT/ToF and regular party frames are visible.

## 0.1.215 — Well-Rested and native target-identity handoff

The *Cozy Sleeping Bag* **Well-Rested** aura (spell **429959**) is an
ordinary 2-hour helpful buff with 1–3 stacks (up to +3% XP). It joins
`buffs_bottom` and existing **BottomHelpful 0** exactly. The unrelated
passive Legacy talent **Well Rested 1225478** and hidden tracking
aura **429960** are intentionally excluded. No new priority tier.

The 0.1.214 untagged Elder Crag Boar screenshot showed a timed icon
in the secondary circle while its ordinary 3D main portrait remained.
The native second-ribbon code reused a `target` unit token across
retargets but did not receive `forceContainerRefresh`, unlike the main
AuraContainers. A timer from a previous target could therefore linger
without any independent positive witness on the newly targeted mob.
The yellow `8` is the mob level, not a countdown defect.

**Fix:** pass the existing forced-refresh signal into the native second
ribbon and track a safely readable current GUID for Target/Focus.
When the token still refers to a *different* actor, call the native
`UpdateAllAuras` out of combat, or fall back to a safe `SetUnit(nil)`
then `SetUnit(source)` rebind when necessary. A combat retarget or
secret GUID at a forced swap hides the old secondary viewport instead
of presenting stale art. Pooled reuse and player self-alias still
follow their positively checked source unit.

A complete public election returning `not-two-presentable` now
suppresses native second art, and a verified public second is
authoritative on hostile NPCs as well. Incomplete/unreadable evidence
can still use the existing native fallback after a safe refresh.
No private aura counts are inspected, and real readable two-aura
NPC portraits retain their existing public election and ranking.

Lua 5.1/5.4 regression tests cover the target-GUID transition,
forced refresh, combat deferral, secret-identity hiding, public absence,
and exact bottom-tier spell ownership. Live confirmation needed.

## 0.1.214 — unify placement, mount classification, white timers

All second-circle centers (Player, Target, Focus, party1–4) now share
TOPLEFT (+10,+12) against the native portrait. This also governs native
ranked-second ribbons, Target/Focus pet-family fallback and pooled reuse.
No second circles on ToT, ToF or PetFrame.

A reviewed exact-ID `buffs_mounts` set joins HELPFUL BaselineClass 90
alongside world/class/Camp Benefits auras, including both Classic 13819
and Forever 1279399 Summon Warhorse. Spell data—not a tooltip image or
private mount detection—grounds identities. No new tier.

Blizzard's Forever `AuraButtonArtTemplate.Duration` inherits
`GameFontNormalSmall`. Secondary cooldowns use that exact font size,
center the FontString on the icon, and apply white (1,1,1,1). Main
portrait labels retain their individually calibrated larger sizes,
but use white ink and retry initially unavailable layout only during
normal out-of-combat host refreshes. No additional timer math or polling.

**Live validation still required** for pixel alignment and mount priority.

## 0.1.213 — Target secondary clears combo-point column

A live screenshot showed a timed second portrait at the **top-right**
of TargetFrame's circular main portrait, obscuring the built-in combo
point cluster on the right. After enlarging second circles to a 44px
cell/36px rim in 0.1.203, the prior placement left too little
clearance. This is a spatial placement defect, not a spell-selection
or cooldown problem.

**New Target placement:** set the small circle's center to the
portrait's `TOPLEFT`, offset **+10px horizontal and +12px
vertical**. Raising the circle keeps its lower edge near the
portrait top, reducing interference with the left-side name/health
bar while moving it away from the entire right-hand combo-point
column. The position needs visual verification against the
player's actual UI scale and custom frame layout.

**All other placements are unchanged:** Player upper-left (+5,0),
party1–4 upper-left (+5,+2), Focus upper-right (−5,0).
ToT, ToF and PetFrame still have no second circle. No new
slash commands, settings or saved layout state.

The placement is defined exactly once in
`Core.SecondaryCirclePlacement(unit)` and used by all three
independent secondary presentations:

1. Readable-aura or race fallback badge
   (`SecondaryPortrait.CreateSecondaryPortrait`);
2. Native priority-ordered second-aura clip
   (`NativeSecondProbe.CreateNativeSecondProbe`), including
   reused pooled units and proven self-target binding;
3. Native aura-presence-gated Hunter/Warlock pet-family fallback
   (`PetSecondary.anchoredFrame`), including Target→Focus reuse.

The whole frame and native clip move together; icon circle
dimensions (44px cell/36px rim/31px art), native group clipping
distance, timer fonts, countdown logic, spell priority/election
and protected aura evidence remain exactly the same. Lua 5.1/5.4
tests assert the shared placement, no stale pooled Target
coordinates, unchanged Focus/Player/party positions, and pet
art alignment. **Live client validation remains required.**

## 0.1.212 — combat-flow attack speed vs raw damage reduction

Two screenshots and one explicit classification decision:

**Ice Claw** (3130; Magic, 6 seconds, 100% longer attack interval)
now joins `debuffs_attack_penalty`, whose single exact harmful
`StatusEffects` tier already has priority **253**. It affects
combat cadence in the same way as the attack-speed-reduction
component of Thunder Clap. It is NOT a movement snare, Dazed,
or a flat raw-damage reduction.

**Curse of Weakness** reduces **physical damage dealt** without
independently disrupting attack timing. All six positively verified
Warlock applied ranks (702, 1108, 6205, 7646, 11707, 11708) move
from `debuffs_other`/`StatusEffects` 253 into the existing
`debuffs_demoralizing`/`Demoralizing` **185** tier. The screenshot
reads **"Physical damage dealt is reduced by 5"** with about 64
seconds remaining, which specifically matches the 2-minute
Classic/Forever Staff of Horrors or NPC applied variant **8552**.
This variant is included too, together with positively identified
NPC Curse of Weakness effects 12741, 21007, 12493 and 18267.
The screenshot does not itself expose an auraInstanceID or spell ID;
8552 is an evidence-based variant match, not a claim of an actual
in-game spell-data read.

We preserve each aura's real spell icon, dispel polarity and
timing. There is **no new tier** or change to the numeric
priorities of any existing tier. Existing Demo Shout/Roar/Screech,
Thunder Clap and the other attack/casting/healing penalties
retain their earlier classifications. Neither an unidentified
curse nor a tooltip alone authorizes a synthetic aura. Both
regular and native second-portrait elections inherit these
exact-ID owners from `R.TIERS`.

Lua 5.1 and 5.4 regressions assert one exact owner per rank and
NPC variant, correct candidate filters, no duplicated IDs,
unchanged tier values, and the intended category distinction.
Secondary icon sizes, fonts, aura countdowns, class/world/Consumables
groups, protected reads, and no-command behavior are unchanged.
The client still needs visual verification to confirm its specific
observed occurrence maps to one of the listed applied IDs.

References:
[Forever Ice Claw 3130](https://www.wowhead.com/forever/spell=3130),
[Forever Curse of Weakness rank listing](https://www.foreverdb.app/en/forever/spells/702/curse-of-weakness),
[Classic Curse of Weakness 8552](https://www.wowhead.com/classic/spell=8552).

## 0.1.211 — Decayed Strength joins Demoralizing Shout

A live screenshot shows **Decayed Strength**, a five-minute Disease
reducing the target's Strength (−4 at the pictured level). Its
Classic/Forever applied aura spell ID is **6951**. It previously had
no exact portrait tier and could only appear through generic
harmful filtering. The user specifies that ordinary stat-reduction
debuffs belong with Demoralizing Shout, Roar and Screech, **not**
the higher `StatusEffects` group reserved for effects that more
substantially disrupt the flow of combat.

Added only **6951** to `Spells.lua`'s existing
`debuffs_demoralizing` set. The exact harmful `Demoralizing`
portrait tier already has numeric priority **185**, so it now
includes Decayed Strength without a new tier, special-case
renderer or changed numeric priority. `StatusEffects` retains
its existing priority **253** and categories. The unrelated
30-second spell ID 13528 is not included by this change.

Lua 5.1/5.4 regression tests assert the exact category,
native candidate filter, unique harmful tier owner, unchanged
Demoralizing Shout/Roar/Screech spells and exclusion from
StatusEffects. Primary/secondary art, cooldown formatting,
race/pet fallbacks, combat evidence policy and all other
spell classifications remain unchanged. No commands or
settings; exact live client selection is still unverified.

## 0.1.210 — secondary countdown font matches regular buffs

A live player-frame screenshot shows a timed secondary portrait with
large native countdown numerals obscuring its 31px inner artwork,
while the regular buff row underneath uses a smaller, more readable
duration font. The fix changes **font styling only**, not the actual
countdown or the portrait geometry.

Forever's Blizzard `AuraButtonArtTemplate.Duration` inherits
`GameFontNormalSmall`. Native aura duration captions can also use
`DEFAULT_AURA_DURATION_FONT` at runtime. The new
`R.ApplySecondaryCountdownFont` chooses the active Blizzard aura
duration font when it exists, falling back to `GameFontNormalSmall`,
and applies that font to the addon-owned
`Cooldown:GetCountdownFontString()` label. It never guesses the
font size from the portrait dimensions or reads protected aura time.

This applies to **both timed secondary renderers**:

- Readable second aura on Player, Target, Focus and party portraits
  (including compact party badges). A positive aura refresh also
  retries font styling if its native countdown label was not
  created until the first timed effect.
- The secured native second-aura ribbon for Player, Target and
  Focus. Its font is installed on each preallocated native button
  after its duration-cooldown receiver is assigned.

The static pet-family secondary has **no countdown**, so its
artwork and native presence-gate remain untouched. Likewise,
**primary portrait countdown fonts** retain the older per-unit
optical centering/compact reductions. Existing numeric formatting
(whole seconds and optional decimals only below ten), 60s cutoff,
countdown colors/text logic, ring/icon dimensions (44/36/31px),
compact dimensions (35/29/25px), native font pooling, aura
election and priority tiers are unchanged.

The font switch occurs only on the addon-owned, positively readable
FontString and outside combat lockdown. If the font API is
unavailable, the fallback leaves the prior font intact rather
than tainting a native frame. Lua 5.1/5.4 regressions cover both
secondary implementations, direct Blizzard font-object matching,
pool reuse/idempotence, unsafe combat reads and the unchanged
primary formatter. **Live typography still needs visual confirmation.**
No new settings or in-game commands.

## 0.1.209 — Magic Wings joins Walk on Air's Utility priority

User screenshot shows the **Magic Wings** slow-fall buff from the
Darkmoon Faire cannon. The corresponding Classic/Forever 18-second
applied aura is spell **24742** (not the separate, later-client
10-second Magic Wings 42867).

Added 24742 to the existing `buffs_utility` source set, alongside
Walk on Air **1259416** and **1308663**. All three are exact
helpful-aura candidates in the pre-existing `Utility` **priority 225**
native tier. This is **not** the lower `TravelUtility` 50 tier:
Walk on Air has always belonged to `Utility`.

The additional Magic Wings entry is the entire runtime change.
Neither slow-fall mechanics nor potion/Consumables 81, Aura UI,
rank ordering, secondary portrait sizing, timers, or any other
tier is altered. We do not infer aura IDs from inaccessible tooltip
data; the exact spell ID is source-backed, and 42867 remains
unclassified until there's evidence of the later variant in Forever.

Lua 5.1/5.4 regressions verify unique exact ownership, level 225,
both prior Walk on Air variants, native candidate filters, and
non-membership in unrelated slowing/travel/consumables tiers.
Live screenshot confirmation is still needed for the actual
portrait selection. No extra in-game commands.

## 0.1.208 — rename unified Elixirs tier to Consumables

The single priority **81** helpful aura group, created in 0.1.207,
is now named **`Consumables`** instead of `Elixirs`. The broader name
fits the already-merged elixir and Well Fed food categories and leaves
a natural conceptual home for **flasks** once their actual applied
aura IDs can be verified. No flask IDs have been guessed or added.

This is a **tier-key rename only**. The same exact native spell-ID
filter still unions `buffs_elixirs`, `buffs_well_fed`,
`buffs_minor_world` and `buffs_minor`. All existing elixirs,
23 Well Fed variants, Rat Familiar and Benevolence retain **81**.
Rat Familiar and Benevolence are not literally consumed; they
remain in the user-approved shared low-impact/provisions grouping
rather than being reclassified by assumption.

The old `Elixirs` tier key is **removed**, not retained as an alias,
so there is only **one** native priority-81 owner. World/class buffs
remain priority 90, and all other numeric tiers are unchanged.
Primary/secondary portraits, sizes, masks, cooldowns, race/pet
fallbacks, and the no-command workflow are unchanged.

Lua 5.1/5.4 regression tests verify the new key, old-key absence,
the full Well Fed/elixir/minor membership, native filter exclusions,
and no duplicate exact-tier ownership.

## 0.1.207 — merge Well Fed and minor buffs into Elixirs 81

**Decision:** The existing `Elixirs` exact helpful priority **81**
now owns elixir auras, all **23 Well Fed** variants, and minor helpful
buffs such as Rat Familiar (+2 Intellect) and Benevolence
(+4 health per 5 seconds). These are a **single native aura group**,
not three competing same-level native winners.

The old `WellFed` (110), `MinorHelpful` (6), and empty
`MinorHarmful` (6) portrait tiers have been retired. Their source
categories remain when useful for classifying observed effects:
`buffs_elixirs`, `buffs_well_fed`, `buffs_minor_world`, and
`buffs_minor` are unioned into `Elixirs`. The unused
`debuffs_minor` category was removed rather than retaining a
misleading empty native harmful slot. **No known negative effects
were moved**, and any future minor debuff needs its own evidence
and explicit user-approved placement.

All existing elixirs remain at **81**; Well Fed moves **110 → 81**
(including Raptor Punch and +1 Stamina), while Rat Familiar and
Benevolence move **6 → 81**. Major class and world buffs,
including all named Sayge's fortunes, stay at **90**.
The established priority above 110 (Thorns and higher combat
effects) remains untouched, as do Tracking, Gathering, and the
absolute-bottom informational tiers.

The full Well Fed and existing elixir source catalogs are preserved.
Exact IDs in the consolidated native filter and exclusion rules are
tested to avoid duplicated hostile-helpful fallback appearances.
No portrait geometry, timers, native second-slot behavior, or
in-game commands change. Lua 5.1/5.4 regressions verify category
membership, priority ownership, absence of retired tiers, and
no duplicate exact winners.

## 0.1.206 — dedicated very minor buff/debuff tier

The broad 0.1.205 world-buff consolidation over-promoted two negligible
passive effects: **Rat Familiar** (1296202, +2 Intellect) and
**Benevolence** (1292142, 4 health per 5 seconds for nearby party).
Neither should compete with significant world buffs or long-lived
class buffs at level 90.

A new matched pair of *exact, native-filtered* level-**6** tiers
serves low-impact auras, between the existing level-5 informational
group and level-9 PassiveSpeed:

- `MinorHelpful` at 6 contains Rat Familiar and Benevolence via
  `buffs_minor_world`, plus an empty `buffs_minor` category reserved
  for individually verified future examples.
- `MinorHarmful` at 6 uses an empty `debuffs_minor` source category
  for similarly negligible **verified debuffs**. It cannot currently
  select any effect. Do not move meaningful Deserter, Martyrdom or
  other harmful statuses simply to populate the slot.

Helpful and harmful polarity need distinct native slots but share the
same numerical priority. Both rat and Benevolence are removed from
`BaselineClass` 90, and remain excluded from the generic high-priority
`Important` and `HostileHelpful` fallbacks. **All explicitly
classified major world buffs, including the eight Sayge fortunes,
remain priority 90**. Existing class/camp buffs, bottom informational
effects, passive effects, regular debuffs, priorities, second-circle
size, portrait placement and cooldown behavior are unchanged.

Source-backed regressions check the level-6 pair, exact IDs,
classification uniqueness, generic-filter exclusion, retained
priority 90 for actual world buffs, and unchanged treatment of
Martyrdom/Deserter/Tricked or Treated. No settings or in-game
commands required.

## 0.1.205 — all identified world buffs share the class-buff priority

**Rule:** Visible world buffs belong in the existing helpful
`BaselineClass` tier at level **90**, *alongside* maintained class buffs
and Camp Benefits. They are not offensive-cooldown buffs merely because
their tooltip increases damage or haste, and must not steal the primary
portrait from higher-priority active combat states.

The source category `buffs_world` enumerates **27 verified spell IDs**
covering:

- All eight Sayge's Dark Fortunes (23735–23738, 23766–23769),
  including the 2-hour damage fortune 23768.
- Rallying Cry of the Dragonslayer (22888), Warchief's Blessing
  (16609), Might of Stormwind (460939/460940), Spirit of Zandalar
  (24425/355365), Songflower Serenade (15366).
- Dire Maul tribute: Fengus' Ferocity (22817), Mol'dar's Moxie
  (22818), and Slip'kik's Savvy (22820).
- Regional/seasonal effects: Traces of Silithyst (29534/1216566),
  Lordaeron's Blessing (30238), Resist Fire (15123), Ribbon Dance
  (29175), Boon of Blackfathom (430947/431111), Spark of Inspiration
  (438537), and Fervor of the Temple Explorer (446695).

Two pre-existing minor-world effects, Rat Familiar (1296202) and
Benevolence (1292142), were incorrectly owned by the 60-point
PaladinAura group. Those now share the same class-buff 90-point
category. The current negative-polarity **Blessing of Blackfathom**
(8733) already belongs to `BaselineClassHarmful` at 90; it remains
unchanged, rather than misclassified as a helpful buff. Existing
Camp Benefits (1229741) stays in the level-90 class-buff band.
**Welcoming Campfire** and its explicitly requested 257-point status
are unrelated and intentionally unchanged.

All world IDs are excluded from broad generic helpful categories,
including `Important` and `HostileHelpful`, to prevent promotion
when an exact aura filter is restricted. Forever also contains
hidden stat-effect *twins* of certain world buffs (1304452,
1304594, 1304678, 1304690, etc.); these are deliberately **not**
independently rendered as second portrait effects. Some Season of
Discovery-era spell rows remain in Forever's client: a spell record
does not prove the world event is currently available in-game.

No new tier or per-spell override, no priority shifts to healing,
immunities, slows, CC, or movement, and no changes to frames, sizing,
timers, or the native secondary. No in-game commands. Source-backed
Lua 5.1/5.4 tests assert exact ownership, all eight DMF fortune IDs,
native filters, generic exclusions, non-duplication, and unchanged
class and camp priorities.

Reference spell data:
[Forever Sayge Damage](https://www.wowhead.com/forever/spell=23768),
[Forever Might of Stormwind](https://www.wowhead.com/forever/spell=460939),
[Classic world buff catalog](https://www.warcrafttavern.com/wow-classic/guides/world-buffs),
[Forever hidden twins evidence](https://daybreakforever.com/discoveries/systems).

## 0.1.204 — make DMF and other second auras agree across Player/Target/Focus

A live side-by-side screenshot showed the *same* Bjoern Janson on
PlayerFrame and TargetFrame, with a fiery first-place buff and Sayge's
Dark Fortune of Damage as a visibly active second effect. The
player's small circle elected the purple fortune icon; Target's
small circle reverted to the character's race image. Focus shares
the same public-reader limitation and previously had **no** native
second-aura ribbon.

**Confirmed source gaps:**

1. `SecondaryPortrait.GetReadableSecondaryAura` always used the
   literal Target/Focus token for public index scans, exact-tier
   permissions, semantic native-filter checks and application-time
   ordering. Self auras can remain positively readable via `player`
   while the same aura on the `target` or `focus` token is
   relation-gated or temporarily unreadable.
2. The native grouped runner-up had supported `player` and `target`
   but not `focus`, so the Focus fallback was never attempted.

**Fix:** When WoW positively reports
`UnitIsUnit("target"/"focus","player") == true`, use `player` for
that portrait's *public aura evidence and filter checks* while
retaining the actual portrait's anchor, identity, and priority
policy. Neither matching names nor unknown/secret equality allow
this alias. Player `UNIT_AURA` updates also refresh only positively
verified self aliases, so a refreshed/removed second effect does not
leave stale artwork. Focus now has a separately anchored, same-policy
native runner-up fallback; when a self Target/Focus must use that
fallback, its native aura container binds to `player` only under
the same positive witness. Changing this native source while in
combat hides the overlay until a safe out-of-combat rebind, rather
than displaying the previous occupant's effects.

**Unchanged:** Sayge's Fortune's priority/classification, all
numeric tiers, first-place portraits, verified race and pet-family
fallbacks, secondary circle sizing (44px cell / 36px rim / 31px art),
timer formatting and zero-command workflow. Regression tests cover
a DMF-like semantic second on both self aliases, separate targets,
unreadable `UnitIsUnit`, Focus native initialization, and safe
combat source swaps on Lua 5.1/5.4.

**Limit:** Offline models establish the source behavior and identity
safety, not the exact live spell display. Focus adds an additional
native group ribbon when used; visually verify both self Focus and
ordinary other-unit Focus before considering it production-certified.

## 0.1.203 — enlarge the actual secondary circles

Live user feedback confirmed that 0.1.202 only enlarged the **artwork**
inside an unchanged outer rim, so the second circle still appeared tiny.
This pass scales the *entire* badge, not merely its interior:

| Component | 0.1.202 | 0.1.203 |
|---|---:|---:|
| Standard secondary cell / aperture | 37px | **44px** |
| Standard Totem-style circular rim | 30px | **36px** |
| Standard masked icon | 26px | **31px** |
| Compact party badge | 29px | **35px** |
| Compact party rim | 24px | **29px** |
| Compact party masked icon | 21px | **25px** |

The same scaled geometry applies to regular race/readable-aura
secondaries, the protected native ranked-second strip and the
aura-presence-gated Hunter/Warlock pet-family fallback. Native
container cell offsets and their clipped first aura also scale from
37px to 44px so the second effect remains correctly positioned.

The secondary badge **center stays at its accepted anchor point**;
main portraits, masking technique, circle layout, countdown font and
timing, priority tiers, aura selection, pet identity policy and
automatic no-command workflow are unchanged. The ring now actually
occupies more screen space: verify rested-Z/party leader clearance
and WoW UI-scale legibility in game. Offline tests lock the new cell,
rim, icon and native clipping geometry but cannot certify live pixels.

## 0.1.202 — enlarge secondary circle artwork

Visual-only sizing pass. Standard secondary portraits now show **26px
masked icon artwork instead of 22px** across three implementations:
native runner-up ribbon, targeted pet-family fallback and the normal
race/readable-aura circle. Compact party art grows **18 → 21px**.

The outer standard cell is still 37px with its 30px Blizzard Totem
rim; compact party badges stay 29px with 24px rims. All circle
positions, icon masks, countdown fonts and timing, native priority
ordering, aura filters and target/pet eligibility stay unchanged.

No commands or settings needed. Lua regression tests verify the new
dimensions and retained rims/masks; whether the additional detail
is readable beneath short countdown text still needs in-game review.

## 0.1.201 — friendly/neutral Target falls back to native second

A screenshot of **Chero Ironhammer** shows four helpful aura icons and
one harmful icon on Target, with a large shield-related primary portrait,
yet the small circle continues to show race-like artwork rather than a
second effect. The screenshot alone cannot establish the actor's exact
client hostility/identity state or prove that the debuff causes the
failure. The source does establish a coverage gap: `NativeSecondProbe`
required `hostile == true`. Even on targets where Blizzard's native
portrait can render several auras, a readable `hostile == false` was
forced to rely exclusively on `SecondaryPortrait.collectCurrentAuras`.
That public election fails closed if either helpful OR harmful indexing
is secret or incomplete, regardless of how many other buffs are visible.

**Fix:** After successful positive unit/relation/player-kind checks,
the same native priority-ordered two-cell ribbon is now available to
friendly and neutral Targets. For nonhostile units it becomes visible
**only when the existing public second was not verified** (race/hidden
fallback), and remains off when that reader positively elects an aura
or static form. Independent Ghost/form witnesses also suppress this
native substitute. Hostile Target behavior remains unchanged.

A confirmed target player retains valid race art underneath a native
second cell; nonplayer Targets hide stale race-like badge artwork.
Targeted Hunter/Warlock pets retain their native aura-presence-gated
family image below a real secondary. The main portrait, tier levels,
all spell classifications, cooldown policy and the current native
22px inner icon size are unchanged. No commands or settings.

Lua 5.1/5.4 regressions verify unknown relation/identity rejection,
mixed helpful/harmful public failure, friendly player race underlay,
friendly NPC no-race behavior, nonoverride of verified readable
selections, static-state precedence, and preservation of hostile
rendering. This is a **source-backed experimental fix**: native
clipping and the exact selected second icon still require live client
confirmation.

## 0.1.200 — confirmed pet-family fallback as a real secondary

A live screenshot shows a **Bird of Prey** (targeted Hunter pet)
with a higher-priority fiery aura in the large portrait, but no small
secondary circle. For positively identified Hunter and Warlock pets on
**Target and Focus**, the small circle now falls back to the pet's
verified family or demon-summon artwork rather than a fabricated race
tile. It uses the established `PetPortraits.lua` family classification,
including current player-pet evidence and a readable GUID, and never
substitutes a generic Growl icon for an unknown family.

**Presence rule:** The pet-family secondary is shown only when the pet
has **at least one currently active aura**. Two engine-native
`CustomAuraContainer` groups (`HELPFUL|INCLUDE_NAME_PLATE_ONLY`
and `HARMFUL|INCLUDE_NAME_PLATE_ONLY`, `maxFrameCount=1`) each own
a portrait-sized button whose visible art is the confirmed pet family.
Blizzard handles button assignment and removal inside its native
aura engine, including restricted auras. The addon does **not** read
a secret aura identity, count, duration or a protected native button.

- **Zero auras:** both native groups display no button, and no
  secondary circle is drawn for the completely naked pet.
- **One or more auras, without a readable runner-up:** the confirmed
  family icon appears as the small portrait, without a fabricated
  countdown.
- **Two eligible auras with a genuine runner-up:** the existing
  public/native second-aura presenter draws **above** pet-family art.
- **Wild beasts, totems, unknown pets and unreadable identities:** do
  not get guessed family artwork. Target/Focus pet handoffs revoke
  stale art immediately; changed family art is updated only at a
  safe out-of-combat boundary.

The existing main pet-family portrait, target/focus aura priorities,
race fallback for player characters, and other frames are unchanged.
No commands or toggles are added. Source-backed Lua regression tests
cover one/two/zero aura presence, Hunter and Warlock family art,
protected combat target swaps, stale GUID clearing, unknown pets,
wild creatures, totems, and Focus reuse. **Native rendering on live
Forever clients remains unverified for this build.**

## 0.1.199 — prevent PlayerFrame race fallback when a debuff arrives

**Observed:** A live PlayerFrame has a ~1.5-second blue harmful effect in
the large portrait and longer-lived auras in the normal buff/debuff row,
but the small circle falls back to race. This reproduces the same
public-data problem previously identified on hostile NPCs:
`SecondaryPortrait.GetReadableSecondaryAura` needs a complete current
index scan across both polarities. On a new harmful `UNIT_AURA` update,
the existing last-positive retention is correctly invalidated; if the
current list or filter is inaccessible, no second candidate can be
verified by ordinary Lua.

**Guarded native fallback:** Reuse the secure `NativeSecondProbe`
mechanism already tested for hostile Targets. PlayerFrame prepares
one native group strip on its first eligible **out-of-combat** update,
before incoming combat debuffs can restrict public aura reads.
Its fixed second-cell viewport sits at the **outer top-left** of the
Player portrait (same +5 pixel accepted offset). It remains hidden
as long as the existing readable second-aura or form election succeeds.
Only when the public reader falls back to a positively verified
**race** baseline may native rendering cover it with the second
engine-ordered aura. The race remains underneath when no second native
button exists.

**Guards:** The new fallback is *player-only*, requires positively
confirmed player/friendly identity and actual enabled frame,
and does not override independently presented Ghost or form/stance
states. Target hostile native rendering remains unchanged; Focus,
Party, Pet, ToT/ToF remain on prior systems. No primary-portrait,
priority, spell, art size, or timer formatting change.

**Tests:** `tests/native-second-probe.lua` exercises automatic
PlayerFrame prewarming, mirrored placement, transition from a
verified readable second to race during a secret combat debuff
update, recovery to the public second, static-state suppression,
combat-construction deferral and pooled frame cleanup. Native
secure button layout remains an **in-game verification boundary**:
these mocks do not claim to reproduce the secret live layout.
No new commands or settings are required.

## 0.1.198 — Far Sight family moved to absolute bottom

A live Farsen's Far Sight quest screenshot showed a viewpoint channel
(“Cannot move while using Farsen's Gift”) on the main portrait. Move
the *applied caster aura* (spell 1293681) to the existing exact
`BottomHelpful` tier, priority **0**. Also demote the three class
viewpoint channels from `Tracking` (priority 3) to the same bottom
helpful tier: Shaman Far Sight **6196**, Hunter Eagle Eye **6197**, and
Warlock Eye of Kilrogg **126**.

The existing helpful bottom lane and all numeric levels remain
unchanged; this only changes four explicit ID memberships in
`Spells.lua`. No other tracking/sensing effects (including Mind
Vision and Sentry Totem) are moved. Every affected spell remains
excluded from the native broad `Important` and hostile-helpful
fallbacks, so it cannot be promoted above combat buffs. There are
no duplicate exact-tier owners, and the native secondary group
generator uses the same updated priority table.

Regression tests verify IDs, level 0, helpful polarity, tracking
exclusion, native filters, exact-tier disjointness, and that the
preexisting Gathering/Tracking priorities are unchanged.
No in-game commands or new settings are needed. Live verification
of a particular quest's aura instance still depends on readable
client data and native filter availability.

## 0.1.197 — native second for opposite-faction players

**Observed screenshot:** A selected opposite-faction player has multiple
native aura icons under the Target frame, but the small circle still
displays the Undead race tile, and the large portrait shows its native
3D fallback. The 0.1.196 secure native ribbon only admitted
`isPlayer=false` hostile NPCs. All hostile players were therefore
still routed through the older public-only reader, where restricted
auras often cannot establish the runner-up.

**Change:** The same native group strip is now eligible for positively
identified hostile players on `target`, as well as hostile NPCs.
It still requires a readable hostile relation and readable
`UnitIsPlayer`/GUID identity; unknown and friendly units fail closed.
The native strip keeps the unchanged priority groups, sorts and native
aura countdowns. No additional app-level enumeration of protected
opponent auras is required.

**Race fallback:** For hostile *players*, the existing verified race
badge remains underneath the secure viewport. When Blizzard lays out
a second eligible aura, its own native button covers the race; if
there is no second eligible aura, the race remains as intended.
For hostile NPCs, the earlier empty/no-race behavior is preserved.

The experiment still has no commands and requires no settings. The
primary portrait, player/party/Focus/ToT behavior, numeric priorities,
geometry and current 22px native secondary icon size remain unchanged.
Native semantic overlaps and actual enemy-player rendering need live
verification. The separate icon-size improvement is deliberately
deferred until this behavior is checked.

## 0.1.196 — automatic native secondary; no in-game setup

No `/bp native2 on`, `/bp native2 status`, or other in-game
setup is required. With the addon installed, simply target a hostile
NPC out of combat: `AuraEngine.UpdateHost` recognizes the NPC, then
creates the native ribbon on demand. It remains available as you
enter combat or switch targets. If the first eligible target appears
*during* combat, setup is deferred until an ordinary out-of-combat
refresh; no manual retry is needed.

The old `nativeSecondProbe` saved toggle is ignored. The existing
`secondaryPortrait` and global addon enabled preferences remain
respected. On other unit types, established readable election and
race fallbacks remain unchanged.

**Workflow preference:** Features should work automatically with
sensible defaults. Avoid new slash commands for enabling, configuration
or normal testing. Existing diagnostic commands are optional
troubleshooting tools, not required setup.

The native ribbon still requires live client verification of sorting,
clipping and exact runner-up identity. The 0.1.195 instructions below
are historical.

## 0.1.195 — experimental secure-native second-place ribbon

**Reason for the experiment:** A real Kobold with two debuff icons and a
working primary portrait returned `reason=inaccessible-index` with
`hostile=true player=false playerReadable=true nativeHarm=true writes=0`.
The addon is blocked before any Lua top-two ranking: Blizzard's native
portrait can process the auras, while `C_UnitAuras.GetAuraDataByIndex`
is unreadable. More public-reader permission relaxations would be
irrelevant to that failure.

**New mechanism (opt-in):** One separate `CustomAuraContainer` on Target
contains native `AddAuraGroup` groups ordered by the existing
`R.TIERS` priority levels (`layoutIndex`), each with
`maxFrameCount=2` and the *same native filters and sorting*. The
native engine lays out its buttons in that order. A fixed 37-pixel
noninteractive clip window hides the first cell and permits the second
cell to display its own 22-pixel masked icon, native countdown, and
Totem-style 30-pixel border. No protected button state, aura ID, or
secret container width is read by addon Lua. This is a **visual
projection** of a native-ordered strip, not a secret-data extractor.

Historical 0.1.195 instructions used explicit `/bp native2`
commands. **Superseded by 0.1.196:** simply target a hostile NPC
out of combat to initialize the ribbon automatically.

- **Only Target hostile NPCs** can display the prototype. No player,
  party, pet, Focus or ToT/ToF behavior changes. In 0.1.196 it
  initializes automatically when first needed out of combat.
- It adds no priority tiers or spell categories. Known exact IDs are
  made disjoint across exact groups; both generic fallbacks explicitly
  exclude known exact IDs, and the harmful generic also excludes
  priority debuffs to reduce double-presentation.
- **Outstanding feasibility tests:** Native group flow across 63
  separate priorities, correct fixed-window clipping, same-lane second
  aura, potential semantic-filter overlap/deduplication, protected
  frame visibility during combat, and construction performance.
  Static Ghost/form winners are not represented in this NPC-only probe.
- This opt-in proof is **not** yet a production replacement for
  `SecondaryPortrait.lua`. The native primary remains fully intact,
  and disabling the probe frees the added view without changing priorities.

Source evidence: Forever
[CustomAuraContainer](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_AuraContainer/Blizzard_CustomAuraContainer.lua)
exposes `AddAuraGroup` with `layoutIndex`, `maxFrameCount`, and
native sorted flow; [AuraContainerGroups](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_AuraContainer/Blizzard_AuraContainerGroups.lua)
assigns the group's first N current aura frames under secure ownership.
The Lua inbound-shape regression
`tests/native-second-probe.lua` verifies the proposed wiring, **not**
the live secure frame layout or actual second-place identity.

## 0.1.194: harmful NPC election from current public evidence

A live Kobold Tunneler Target screenshot again showed two Blizzard debuff
icons and a main portrait aura, but no secondary circle. Those native
pixels do not prove that both aura identities are available to addon Lua.

Two independent source gates were unnecessarily stronger than the
secondary reader's existing evidence requirements:

1. Hostile NPCs previously needed the **separate HELPFUL-only helper**
   to finish and elect its own helpful winner *before* the secondary
   reader attempted its own full helpful-and-harmful snapshot. That
   helper can be inconclusive even when a complete current union
   proves a **harmful primary** above the helpful effects. Positively
   identified non-player Target/Focus NPCs can now run that independent
   full read directly. Hostile players still require the stricter
   independently verified first-place presenter.
2. The final main harmful native slot check required a directly
   readable `IsEnabled()`. When that native getter is protected,
   the addon can now use its own `_bjarkiAppliedShown == true`,
   recorded only after successful native `SetEnabled` **and**
   `SetShown` calls. A known false or missing previous state still
   fails closed, and the current candidate's exact public identity,
   filter, rank and native container must all independently match.

The real-tier hostile NPC regression verifies both routes and their
negative controls on Lua 5.1 and 5.4. This does **not** reveal secure
native winner identities or bypass an unreadable current aura list.
If this client hides the harmful identities, the NPC secondary stays
hidden. To diagnose the actual remaining gate, target the NPC and run
`/bp secondary debug target` in its current visible state.

## 0.1.193: combat continuity and last-drop diagnostics

Entering combat still returned a visible player's secondary portrait to the
race icon in the live 0.1.192 screenshot even while the native aura icons
remained visible. No client `secondReason` was supplied, so this screenshot
does not establish whether the blocker was secrecy, a native write failure,
or an aura event.

This test build repairs three **independently reproducible code paths**:

1. `UNIT_AURA` previously marked the last positive secondary stale on *every*
   event. It now preserves the candidate only when a guarded public event
   delta proves **solely the removal of unrelated aura-instance IDs**.
   Full updates, additions, updates, secret/unknown payloads, removal of
   either the primary or secondary instance, and expiry still invalidate.
2. Native tier `SetEnabled` / `SetShown` calls are skipped on unchanged,
   previously successful container states; explicitly forced refreshes and
   actual state changes are still executed. This avoids redundant combat
   writes while preserving main portrait behavior and failure guards.
3. If a new complete election positively identifies the **same** timed
   second aura during combat, reuse the existing texture and cooldown rather
   than rewriting them through possibly protected frame APIs. Its current
   instance, spell, tier, existing expiry, unit identity, and mutation
   boundary must still pass.

The existing `/bp secondary debug player` command now reports
`auraEvent` and, if a previous aura badge fell back to race, a
`lastDrop` line with its exact stored failure reason, previous spell,
event dirty state and native write-failure count. This records evidence
for a future live report without inspecting protected auras in chat.

Lua 5.1/5.4 mock tests cover unrelated removal retention, relevant
primary removal invalidation, new aura invalidation, unchanged-combat
no-write behavior, and protected native setter avoidance. **This remains
a live-client test build**, not a guarantee of a secondary where the
current aura information is truly secret.

## 0.1.192: combat Boosted Rest and NPC harmful projection

In the screenshots, Boosted Rest (1229451) is the primary portrait
out of combat but should become **secondary** if a higher-priority effect
takes first place. The prior secondary reader admitted this self/friendly
HARMFUL status only when Ghost was the primary. It now also admits the
currently readable, verified occurrence during ordinary combat; its
level **0** and required ordinary HARMFUL membership are unchanged.
If the current list or identity is genuinely secret, this change does
not fabricate a secondary portrait.

The hostile NPC harmful path no longer insists on broad exact-ID permission
when an independently enabled native generic harmful container exists.
It still requires the current public aura lists, a positively identified NPC,
a proven native first-place harmful slot, and ranked second occurrence.
Hostile players receive no new privilege, and no private native winner
is read. Both changes have regression cases; live combat rendering still
needs confirmation against 0.1.192.

## Confirmed 0.1.188–0.1.189 secondary regression (fixed in 0.1.190)

**Root cause, reproduced with the actual addon source and the game's manifest order:** `SecondaryPortrait.lua` constructed the sorted `rankTiers` list at **module load**, before `Priority.lua` had populated `R.TIERS`. This initialized a permanently **empty** rank list on the live client, regardless of how many buffs were visible. Consequently `secondReason=not-two-presentable` and race fallback were inevitable after v0.1.188, even though prior offline tests passed (they loaded `Priority.lua` first).

Both manifests now load **`Priority.lua` before `SecondaryPortrait.lua`**, and the secondary ranking table is **lazily cached from the populated source** (with an explicit `tiers-not-ready` failure rather than silently treating every spell as unranked). The original production-order reproduction changes from `second=nil reason=not-two-presentable` to `second=1126 reason=verified-readable` for Thorns (120) + Mark of the Wild (90). `tests/secondary-load-order.lua` tests both manifest orders and the deliberately broken order, so this cannot silently regress. All numeric tier levels and the native primary portrait are unchanged.

## Ghost as the main state; lower harmful auras as the secondary (0.1.191)

A **positively presented** Ghost is a static primary at its existing Immunity-relative frame level, rather than a reason to suppress the secondary circle. If a complete current public harmful aura list contains Boosted Rest (spell **1229451**, priority **0**), it can be shown in the small circle under Ghost, with its real timer. Other existing priority-0 harmful effects remain in their original lane. Duplicate Ghost debuffs (8326, 9036, 1278162) are not counted as additional effects when the static main Ghost presenter already owns them.

The exact lower harmful aura still needs a readable current instance ID, matching native polarity membership, and an eligible friendly unit; an inaccessible spell cannot be guessed. A verified Ghost state alone returns the usual race fallback in the secondary circle. Equal-level native ties (e.g. Waiting to Resurrect at level 332) remain unproven rather than arbitrarily ranked. No primary portrait, numeric tier, or protected API permission has changed.

## Supported portraits

The **same one-aura priority engine** is used for **player, pet, target, focus, target-of-target, target-of-focus and regular party1–party4** (ten unit tokens). PetFrame retains its pet-family artwork as the baseline. Party portraits follow Blizzard's pooled frames and ignore Edit Mode placeholders; raid-style party/raid frames are not covered.

Native unit-frame chrome and spell icons remain the visual foundation. **The main portrait now falls back to Blizzard’s own class icon or 3D model**, according to the game setting. Verified player-race artwork appears in a **small Totem-style secondary circle** on Player, Target, Focus and regular party frames, anchored to the **outer top corners** (player/party upper-left; target/focus upper-right) and drawn **above** native frame artwork, away from rested-Z and party-leader indicators. **ToT, ToF and PetFrame have no secondary circle**; their main portrait aura systems remain unchanged. Where a complete public aura scan and native filter probes are readable, the circle can instead present the second-ranked **distinct** active aura with a native countdown. Unknown, partial, restricted, or indeterminate reads ordinarily fall back to race/hidden. During combat, an **already verified timed** second aura can remain visible if the new read becomes inaccessible without an aura mutation. This last-positive display is revoked on the first UNIT_AURA event without a successful re-election, at its known expiry, or when the unit identity changes. Skyborne still requires a verified face atlas. PetFrame retains one full primary aura system without a secondary circle.

**PetFrame icon edge cleanup (0.1.186):** The local 37px pet portrait uses a tighter `3/64` source-image crop (previously `1/64`) to keep a square spell-icon rim from peeking through the top of its round aperture. This applies to both pet-family fallback artwork and every aura layer via one shared function. The circular Blizzard bezel, portrait image position, and all other frame crops remain unchanged. Verify the visual result on different pets in game.

**NPC secondary debuffs (0.1.188–0.1.189):** Hostile NPCs on Target or Focus can now use the small circle when a complete, readable public aura snapshot contains two distinct, rankable harmful effects and the projected first-place native harmful slot is positively enabled. This covers categorized harmful effects such as Hamstring > Rend and, where higher semantic filters are readable, the existing generic harmful fallback. The NPC path requires positively proven **non-player** identity, complete helpful and harmful lists, and successful native slot writes. A lower-priority helpful aura no longer vetoes a harmful first-place effect; all present auras must still be ranked and the harmful native main slot positively enabled. It is **not** granted to hostile players, and does **not** read a forbidden native winner. A creature with fewer than two eligible auras (or unreadable data) has **no made-up race or creature icon**; its second circle remains hidden.

**Ordinary native-filter proof (0.1.189):** Some publicly readable auras lack the optional `isNameplateOnly` field. When that field and the per-instance native filter oracle cannot decide whether an aura belongs to a plain HELPFUL/HARMFUL exact lane, the secondary election uses one **bounded same-polarity public indexed scan** to establish matching current `auraInstanceID + spellId`. A positive ordinary filtered membership is sufficient; inaccessible, duplicate and contradictory identity stays unknown. This does **not** bypass combat secrecy or infer unseen auras. Use `/bp secondary debug player` or `/bp secondary debug target` for a concise two-line current election reason without refreshing the portrait.

## Current priority examples

- **Priority 0, absolute bottom:** Shiny Silver Coin (1321323) and viewpoint-only helpful effects Farsen's Far Sight (1293681), Shaman Far Sight (6196), Hunter Eagle Eye (6197), and Warlock Eye of Kilrogg (126) in `BottomHelpful`; Boosted Rest (1229451), Tricked or Treated (24755) and both harmful Tamed effects (19685/19686) remain in `BoostedRest`. Helpful/harmful retain their existing separate native slots at identical numeric priority.
- **Gathering 1:** Find Herbs, Find Minerals, Find Treasure. **Tracking 3:** sensing buffs, Sapta Sight, Hunting Kobolds. **Campfire Nearby 4** and **Violet Flames 5**.
- **Seal 210** includes Poised; **Offensive 280** includes Rushing Charge and Savagery; harmful **Control 310** includes Polymorph, while helpful **ControlHelpful 310** covers Frog Form.

See `Priority.lua` and `Spells.lua` for the complete, authoritative levels. Same-tier native order is reverse aura-instance ID; a refreshed buff does not always count as “last applied”. A 3,599-second native `SmallFriendlyHarmful` duration guard prevents Boosted Rest promotion, but also restricts other long/permanent generic harmful effects.

Use `/bp help` for commands, `/bp inspect <unit>` for eligible observed auras, `/bp layout <unit>` and `/bp pets debug pet` for presentation diagnostics. The `/bp secondary on|off` command controls the badge without changing the main portrait. `/bp layout player` reports `secondSpell`, `secondTier`, and `secondReason` for debugging fallback; v0.1.183 also reports the displayed hostile-main spell, tier, aura-instance identity and whether its helpful list completed. This helps distinguish blocked target reads from mismatched first-place evidence. `/bp test` still previews a **synthetic** icon for geometry checks. `/bp decimals` controls decimal countdowns strictly below ten seconds.

## Secondary aura prototype — bounded readable path

**[Design and acceptance plan](docs/SECONDARY_PORTRAIT_PLAN.md)** records the full objective and native API limitations. Version 0.1.180 adds a *conservative* public aura election, independent of the unchanged secure main portrait: complete helpful/harmful indexed lists (up to 48 entries each), verified occurrence IDs, native per-tier filter checks, and bounded probe work (192 per refresh). It understands same-tier native ID order, the three application-time tiers, exact/semantic priorities, and refuses ambiguous equal-level lanes or unavailable timing. It now runs on positively readable **friendly units** and on **targeted hostile units only when their complete public aura evidence and the independently displayed first-place portrait agree**. An independently proven stance/form may also be first when its rank exceeds every readable aura. The client can still withhold hostile aura data, so this does not guarantee a second icon in PvP or restricted combat. For known exact auras, their membership in a completed compatible native polarity scan can prove native eligibility without the extra `IsAuraFilteredOutByInstanceID` lookup; nameplate-only mismatches still require negative checks. Unclassified/semantic aura eligibility still requires the native filter oracle. The 0.1.182 fix preserves an explicitly readable **false** hostile relation as friendly, instead of treating it as unknown. In 0.1.184, the optional combat hold is labeled `secondReason=combat-positive-retained:<reason>` to distinguish last-positive evidence from a current election; it never guesses a new effect while aura data is secret. It falls back to race when any required evidence is absent. **Universal combat/hostile coverage is still not guaranteed; no secure global second-winner API has been discovered.** The NPC harmful projection is a bounded public-data prediction of the native first-place winner, **not direct access to the secure rendered primary**; if one is withheld, it fails closed. The synthetic `/bp test` remains distinct from live evidence.

### Static form / stance ordering (0.1.185)

A positively displayed Warrior stance or Druid form is a **static candidate at priority 149**, not an automatic first-place winner. When a stronger aura is first, the form can be the second portrait without a fabricated cooldown; if two auras are stronger, the true second aura remains second. When the form outranks every aura, the highest-ranked aura is second. For example, **Welcoming Campfire (257) → Battle Stance (149) → Camp Benefits (90)** shows Battle Stance in the small circle, not race or Camp Benefits. These are source/regression expectations, not yet confirmed for every live-client state.

## Documentation and tests

- [Architecture](ARCHITECTURE.md) — source ownership and chronological build changes, including v0.1.173–0.1.178 in section 35.
- [Known issues](KNOWN_ISSUES.md) — current live-verification boundaries and outstanding aura-order issues.
- [Package workflow](.github/workflows/package-addon.yml) — Lua 5.1/5.4 syntax checks, regression scripts, and an installable CI artifact.

This project uses event-driven/native aura systems and conservative evidence permissions, not an unrestricted Lua spell scan on every rendered frame.
