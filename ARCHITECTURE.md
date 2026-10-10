# bjarkiPortraits architecture

Current architecture snapshot: **2026-10-10**, shipped runtime
**bjarkiPortraits 0.1.99-local**, alongside **bjarkiUI 0.2.105-local**.
This reference describes current source contracts, presentation ownership and
evidence limits. Chronological changes, live reports and investigation history
belong in [KNOWN_ISSUES.md](KNOWN_ISSUES.md). Source fixtures and isolated checks
are not proof of execution inside the live WoW: Forever VM.

## Runtime and scope

The addon has seven Lua modules, loaded in this order:

| Module | Responsibility |
| --- | --- |
| [Spells.lua](Spells.lua) | Applied spell-ID category tables |
| [Core.lua](Core.lua) | Settings, unit/portrait lookup, access and relation checks, timer formatting |
| [Priority.lua](Priority.lua) | Exact and semantic lanes, immutable indexes, membership audit |
| [AuraEngine.lua](AuraEngine.lua) | Native containers, readable elections, portrait presentation, host lifecycle |
| [PetPortraits.lua](PetPortraits.lua) | Pet-family and totem foundation artwork |
| [Commands.lua](Commands.lua) | Commands and diagnostics |
| [Main.lua](Main.lua) | Event registration and refresh routing |

The TOC [load order](bjarkiPortraits.toc) and
[Camelot variant](bjarkiPortraits_Camelot.toc) share these modules.
[Core.lua](Core.lua) initializes `BP.Runtime`, saved settings in
`BjarkiPortraitsDB`, and access helpers. Global and five per-unit switches,
pet foundations and decimals default on; swipe defaults off.

Aura hosts cover `player`, `target`, `focus`, `targettarget` (ToT) and
`focustarget` (FoT).
The local PetFrame has optional foundation artwork. It has no added pet aura
host. Pet artwork and aura selection have separate owners.

Across the addons, bjarkiUI owns frame placement, names, bar colors and frame
decoration, including ToT/FoT placement. bjarkiPortraits owns aura and foundation
artwork plus their countdowns; it follows the native portrait geometry inside
those frames. Blizzard retains unit bindings and the native small aura lists.

## Catalogue and priority lanes

[Spells.lua](Spells.lua) supplies static applied-aura spell-ID sets.
[Priority.lua](Priority.lua) unions categories that share a stream and numeric
priority into one lane before native construction. Each exact ID has one lane
owner; helpful and harmful dispositions remain separate. The derived
`TIER_BY_KEY`, `HELPFUL_TIER_BY_SPELL` and `TIER_AUDIT` indexes are built once
from these definitions. The current catalogue has **1,174 distinct IDs across
76 source categories, 51 disjoint exact lanes, no exact-owner overlaps,
and 10 semantic lanes**.

Higher numeric priorities appear above lower ones. The number specifies
presentation order; it does not measure spell strength, grant access, or prove
what the live client exposes. Native buttons and readable tier presenters use
priority + 1. The table names the current lane keys so they can be located
directly in [Priority.lua](Priority.lua); entries sharing a row remain separate
lanes unless the contents explicitly describe a union.

### Exact lanes

| Lane key | Priority | Current contents or relationship |
| --- | ---: | --- |
| Tracking | 0 | Find Herbs and Find Minerals |
| Cosmetic / BoostedRest | 1 | Helpful transformations, including Savory Deviate/Whimsyfin Delight; separate harmful camping cooldown |
| CampfireNearby | 2 | Nearby-campfire background state |
| PassiveSpeed | 9 | Agamaggan's Clutch, immediately below Plainsrunning |
| Plainsrunning | 10 | Plainsrunning and Elemental Blessing |
| TravelUtility | 50 | Water Breathing, Unending Breath, Water Walking, Aquatic Form and three applied Noggenfogger effects |
| PassiveDebuff / RighteousFury | 59 | Harmful Deserter/item Martyrdom; separate helpful Righteous Fury |
| PaladinAura | 60 | Paladin auras, Warlock armor, persistent support totem effects, Leader of the Pack, Rat Familiar and Benevolence |
| BloodPact | 70 | Blood Pact, four applied Furious Howl ranks, Vengeance, Iron Creed and Spirit Bond |
| Scrolls | 80 | Scroll buffs |
| BaselineClass | 90 | Baseline class buffs, Camp Benefits, Demonic Knowledge and Blessing of Blackfathom |
| WellFed | 110 | Well Fed buffs |
| Thorns | 120 | Thorns and five canonical Imp Fire Shield ranks |
| ElementalShield | 130 | Lightning Shield family |
| SelfState | 150 | Forms, Inner Fire, Frost Armor, Soul Link and Burning Shadow |
| BattlegroundFlag | 151 | Darkspear Islands Flag, above forms and Inner Fire |
| Mobility | 160 | Ghost Wolf/Cheetah families and established movement/stealth category |
| LoneWolf | 170 | Lone Wolf |
| HuntersMark | 180 | Hunter's Mark |
| Demoralizing | 185 | Demoralizing Shout/Roar and four applied pet Demoralizing Screech ranks |
| Consecration | 189 | Applied Forever damage-amplification aura, immediately below DoTs |
| DoTs | 190 | Explicit damage-over-time effects, including Ironspine's Poison Cloud 3815 |
| Seal | 210 | Paladin seals and Improved Stormstrike 1238931, one shared helpful election |
| Slows | 220 | Slows, exact Chilled IDs, Frost Trap Aura, Highland Venom, Crippling Poison, Frost Shock 12548 and Curse of Exhaustion |
| RecentlyBandaged | 229 | Separate harmful state |
| WeakenedSoul | 230 | Exact Weakened Soul |
| Forbearance | 240 | Forbearance and the existing Dazed member |
| ResSickness | 241 | Resurrection Sickness |
| Healing | 255 | Ordinary absorbs, HoTs, 17 historical First Aid channels and Mend Pet |
| PowerWordShield | 256 | Applied PW:S family and Transformative Cocoon's absorb |
| HonorlessTarget | 257 | Honorless Target, above ordinary Healing |
| FoodDrink | 260 | Food, Drink, Cannibalize, Evocation and Restoration |
| Innervate | 261 | Innervate, Druid Enrage, Bloodrage, resource recovery and living Quick and the Dead variants |
| Utility | 270 | Utility buffs and Welcoming Campfire, one shared election |
| StatusEffects | 279 | Faerie Fire's former low-debuff/taunt tier merged with casting/attack penalties, reduced healing received, Shark Attack and Muculent Rot; one shared harmful election |
| Offensive | 280 | Offensive cooldowns, Clearcasting/Preparation, Victorious, Sprint/Dash, Satchel Speed, Cocoon speed, Swift Wind and Battleground Speed/Berserking |
| OffensiveHarmful | 281 | Death Wish, above helpful offense and below defensive lanes |
| Defensive | 290 | Defensive buffs |
| RacialDefensive | 291 | Defensive racials, including Stoneform and Will of the Forsaken |
| Roots | 300 | 31 root-effect records and retained legacy cast/passive IDs 16979/18310/18313 |
| RootImmunity | 305 | Root immunity, Free Action, Voice of Truth's casting immunity and Grounding redirection |
| Control | 310 | Interrupts and non-stun crowd control; harmful Stun IDs excluded |
| PhysicalImmunity | 315 | Three Blessing of Protection ranks |
| Stun / HelpfulSelfStun | 320 | Separate harmful stuns, including both Goblin Mortar stun records, and currently helpful Cocoon self-stun |
| Immunity / ImmunityHarmful | 330 | Separate helpful and harmful immunity-priority lanes; helpful includes Reflection Field's spell reflection |
| DivineProtection | 331 | Separate helpful Divine Protection lane |
| WaitingToResurrect | 332 | Resurrection waiting and dead-only Quick and the Dead aura, above Ghost |

### Semantic lanes

Semantic lanes describe native metadata shapes or broad visibility fallbacks.
They cannot independently establish an exact spell identity.

| Lane key | Priority | Native filter or fallback shape |
| --- | ---: | --- |
| HostileHelpful | 3 | Helpful including nameplate-only auras on positively hostile units when a complete readable presenter has not rendered |
| SmallFriendlyHarmful | 4 | Harmful including nameplate-only auras on ToT/FoT when exact harmful filtering is unavailable; no inferred friendly identity required |
| Important | 85 | IMPORTANT helpful, excluding BIG_DEFENSIVE and EXTERNAL_DEFENSIVE |
| FrostArmorSignature | 150 | Magic helpful, duration at most 1800.1 seconds, not from player/pet; only positively hostile non-player units without a complete readable presenter |
| ChilledSignature | 219 | Magic harmful, duration at most 5.1 seconds, personal nameplate, not from player/pet; yields to exact Slows permission or an active readable Slows winner |
| WeakenedSoulFallback | 228 | Harmful at most 15.1 seconds, excluding DoT IDs and Magic/Curse/Disease/Poison/Bleed types; yields to exact Weakened Soul permission |
| PriorityDebuff | 238 | Native priority-aura harmful flag |
| ExternalDef | 288 | Native external-defensive helpful flag |
| BigDef | 289 | Native big-defensive helpful flag |
| CrowdControl | 309 | Native crowd-control harmful flag |

Important, ExternalDef and BigDef exclude explicitly classified helpful IDs;
PriorityDebuff and CrowdControl exclude explicitly classified harmful IDs.
Native exclusions apply only where identity matching is permitted. Restricted
relations can therefore retain an already classified aura in a broad lane.

ChilledSignature is an approximation below exact Slows 220, including the
exact Chilled IDs. When a mixed Slows set is eligible through one NeverSecret
member, the exact native button is one level above the semantic button. The
semantic fallback remains available if that public member is absent; scheduling
eligibility alone does not prove that the exact container has a candidate.

### Applied-record details and classification boundaries

StatusEffects 279 is the union of all 74 former LowDebuff IDs and all 44 former
CombatDebuff IDs. The entire Faerie Fire/curse/taunt tier moves from 200 to 279;
the old exact lanes are removed. These 118 IDs use one native container and one
complete-readable instance-order election per supported host. Faerie Fire and
Thunder Clap now compete within that same tier, just below Offensive 280.
There is no independent same-level overlay that can bypass this election.

The added part of that union includes Faerie Fire, ordinary Warlock curses,
taunts, Cursed Blood, Fevered Fatigue, Viper Sting, Drain Soul and Shadowburn's
death-item residual. Source categories remain separate for maintenance; they
do not construct independent priority owners. Selected applied-aura families
from the former combat-penalty lane are listed below:

| Family | Applied IDs |
| --- | --- |
| [Curse of Tongues](https://www.wowhead.com/forever/spell=1714/curse-of-tongues) | 1714, 11719 |
| [Mind-numbing Poison](https://www.wowhead.com/forever/spell=5760/mind-numbing-poison) | 5760, 8692, 11398 |
| [Sonic Blast](https://www.wowhead.com/forever/spell=1264478/sonic-blast) | 1264478, 1264479, 1264480, 1264481, 1264482 |
| [Carved Mind](https://www.wowhead.com/forever/spell=1302342/carved-mind) | 1302342 |
| [Warrior Thunder Clap](https://www.wowhead.com/forever/spell=6343/thunder-clap) | 6343, 8198, 8204, 8205, 11580, 11581 |
| [NPC Thunderclap](https://www.wowhead.com/forever/spell=8078/thunderclap) | 8078, 1213464 |
| [Dust Storm](https://www.wowhead.com/forever/spell=1316382/dust-storm) | 1316382 |
| [Mortal Strike](https://www.wowhead.com/forever/spell=12294/mortal-strike) | 12294, 21551, 21552, 21553 |
| [Veil of Shadow](https://www.wowhead.com/forever/spell=7068/veil-of-shadow) | 7068, 17820, 460755 |
| [Wound Poison](https://www.wowhead.com/forever/spell=13218/wound-poison) | 13218, 13222, 13223, 13224 |
| [Hex of Weakness](https://www.wowhead.com/forever/spell=9035/hex-of-weakness) | 9035, 19281, 19282, 19283, 19284, 19285 |
| [Dismember](https://www.wowhead.com/forever/spell=1264758/dismember) | 1264758, 1264927, 1264929, 1264930, 1264933 |
| [Shark Attack](https://www.wowhead.com/forever/spell=1323184/shark-attack) | 1323184 |
| [Muculent Rot](https://www.wowhead.com/forever/spell=1316387/muculent-rot) | 1316387 |

Wound Poison qualifies through flat healing-received reduction; Mortal Strike,
Hex and Dismember use percentage reduction. Veil of Shadow 7068/17820/460755
are matching 75% healing-reduction Curses with 15-second source durations.
Shark's direct-damage trigger, poison coatings, training spells and Carve Mind's
hidden proc wrapper do not identify applied target auras in this lane.
StatusEffects opts into per-aura NeverSecret scheduling, preserving eligibility
for Shark where the client positively allows it, including small hosts. This
opt-in does not prove that any member is currently NeverSecret.

The attack-penalty source category joins this same lane. Six warrior Thunder
Clap ranks apply attack-speed penalties; the two matching NPC Thunderclap
records also apply a movement slow. Dust Storm applies an attack-hit penalty.
Muculent Rot belongs to the serious world-debuff source category. Its current
record describes a 15% Spirit/Stamina reduction, while the supplied screenshot
says 35%; the sole current visible exact-name record is included without
claiming a cause for that quantity difference.

[Vengeance 20050](https://www.wowhead.com/forever/spell=20050/vengeance) is the
applied Paladin proc at BloodPact 70; its passive talent 20049 is excluded.
[Demoralizing Screech](https://www.wowhead.com/forever/spell=24423/demoralizing-screech)
24423/24577/24578/24579 shares Demoralizing 185 with Shout/Roar; the Learn Spell
record 24424 is excluded. [Fevered Fatigue 8139](https://www.wowhead.com/forever/spell=8139/fevered-fatigue)
is the applied Intellect/Spirit Disease at StatusEffects 279. Its current default
tooltip says 6/6, while the screenshot says 11/11; no scaling or beta-change
explanation has been established. Hidden proc drivers 11964/18847 are excluded.

[Agamaggan's Clutch 1293199](https://www.wowhead.com/forever/spell=1293199/agamaggans-clutch)
is PassiveSpeed 9, immediately below Plainsrunning 10. Its item-granted helpful
aura describes a 3% movement bonus in the Barrens, Thousand Needles, Razorfen
Kraul and Razorfen Downs. This minor passive does not join the active speed
cooldowns in Offensive 280.

[Cursed Blood 8267](https://www.wowhead.com/forever/spell=8267/cursed-blood)
was already catalogued and moves with the whole merged tier to StatusEffects
279. Its Curse disposition, ten-minute duration, icon and embedded Intellect
description match the dungeon report. The current page has conflicting amount
fields (the embedded description says 15; its rendered tooltip says 25), so no
scaling or beta-change explanation is claimed. The dummy record 8268 is excluded.

[Leader of the Pack 24932](https://www.wowhead.com/forever/spell=24932/leader-of-the-pack)
is the applied party aura; the retained passive talent record is 17007. Both
share PaladinAura 60, below BaselineClass 90 and forms in SelfState 150.
Previously, Leader shared BaselineClass's recency election with ordinary class
buffs. The new priority makes a complete readable Mark of the Wild or form
outrank it regardless of application order. This ranking choice does not prove
that every restricted dungeon/BG identity can use exact priorities.

Harmful Stun 320 includes the existing normal
[Goblin Mortar 13237](https://www.wowhead.com/forever/spell=13237/goblin-mortar)
and the separate self-area
[Goblin Mortar 13238](https://www.wowhead.com/forever/spell=13238/goblin-mortar).
Both records apply a three-second stun. The self-area record is the supported
backfire candidate; its connection to the server's failure branch is an
inference from the paired records, not a published server execution trace.
[Reload Explode 13239](https://www.wowhead.com/forever/spell=13239/reload-explode)
has damage and knockback without a persistent aura, so it is not added as a
portrait state. Crafting and Learn Spell records are also excluded.

[Reflection Field 1303458](https://www.wowhead.com/forever/spell=1303458/reflection-field)
shares helpful Immunity 330 for its spell-reflection protection. The current
record directly applies Reflect All Spells to protect nearby allies and
publishes no debuff flag. This is a source-based helpful classification, not a
live aura-disposition capture. The area-trigger cast 1303459 is excluded, and
its ten-second lifetime is not used as the duration of the applied aura.

[Poison Cloud 3815](https://www.wowhead.com/forever/spell=3815/poison-cloud)
belongs to DoTs 190 and the derived DoT exclusion. The applied Ironspine Poison
record ticks every five seconds for 45 seconds. Public source records establish
catalogue membership; screenshots without exposed IDs do not uniquely identify
an aura or certify its live visibility.

[Improved Stormstrike 1238931](https://www.wowhead.com/forever/spell=1238931/improved-stormstrike)
is a Seal 210 member. Its source category is unioned with paladin seals before
construction, giving one native election at that priority. The passive talent
1223031 is excluded. Battleground Speed
[23978](https://www.wowhead.com/forever/spell=23978/speed),
[1286345](https://www.wowhead.com/forever/spell=1286345/speed) and existing 23451
are Offensive 280 members; their records describe 100% movement speed for ten
seconds. Potion Speed 1309728 shares that lane; hidden rune visual 1286342 does
not. Applied Berserking 1286304/23505/24378 also stays in Offensive.

Healing includes Shadow Ward, Sacrifice, Ice Barrier, Fire Ward, Frost Ward and
Mana Shield. Contingency Plan wards and ambiguous custom/trinket records retain
their established classifications. Deserter's queue penalty remains below
combat effects. Item Martyrdom 1292749 is a harmful death-damage aura, distinct
from Priest talents and Waiting to Resurrect. Grounding shares the protection
priority but is spell redirection rather than root immunity. Death Wish's
separate harmful lane gives deterministic layering, not recency across helpful
and harmful streams. Cocoon's self-stun is currently helpful in the source data;
its absorb and speed are separate applied IDs. A disposition change requires
verified data rather than a speculative second owner for the same ID.

## Native containers and permission

Construction in [AuraEngine.lua](AuraEngine.lua) creates one Blizzard
CustomAuraContainer per configured lane on each host.
Exact lanes keep their static includeSpellIDs map. Semantic lanes use native
metadata filters, such as important, defensive, crowd-control, duration and
dispel type. Native candidates use AuraInstanceIDOnly with reverse direction.

[Core.lua](Core.lua) distinguishes readable positive evidence, readable
negative evidence and unknown values. Existence, relation, player identity,
secrecy and aura fields must be checked before comparison or indexing. A
readable GUID type can back up player identity; player control alone cannot
establish that a unit is a player. Unknown NeverSecret lookups fail closed
without caching unknown as a permanent negative.

Two addon checks answer different questions:

- ExactFilterAllowed requires positive readable existence and a permitted
  helpful/harmful relation, the helpful player-controlled/group exception, or an opted-in
  set whose members are all positively NeverSecret. It remains a conservative
  witness for the whole configured set.
- NativeExactContainerAllowed also permits an opted-in mixed set to run when
  existence is positively readable and at least one configured member is
  positively NeverSecret. This schedules the native container; it does not
  authorize Lua to read or classify every member.

The native predicate checks permission for each aura and rejects an
unfilterable aura whenever includeSpellIDs is present. A mixed Mobility lane
can therefore retain an eligible Ghost Wolf/Cheetah candidate while the native
predicate rejects its forbidden members. Unknown secrecy is not NeverSecret.

Slows now opts into this same per-aura scheduling rule. A public Frostbolt or
Frost Trap aura can therefore reach the native lane on self/friendly units
when its own current client policy is positively NeverSecret. The opt-in does
not change the lane's membership, priority 220, or native identity predicate.
StatusEffects retains this opt-in, including Shark Attack at priority 279.
No actual secrecy classification for those pictured auras was captured.

The opt-in also bounds the existing partial-readable ownership rule. A tier
can be eligible to run because of an absent NeverSecret member while rejecting
a different, directly readable contextual member. Broadening scheduling alone
can therefore hide a readable portrait without supplying a native replacement.
Native per-aura admission is not evidence of an active candidate or a complete election.

No native child icon, visibility, cooldown value or rendered winner is read
to infer an aura's identity.

The current reverified native source pin is Forever **1.60.1, build 70338**,
commit [943764493e6b16d63ded3ab304150d1f05e58b57](https://github.com/Gethe/wow-ui-source/commit/943764493e6b16d63ded3ab304150d1f05e58b57).
Its [candidate-filter implementation](https://github.com/Gethe/wow-ui-source/blob/943764493e6b16d63ded3ab304150d1f05e58b57/Interface/AddOns/Blizzard_AuraContainer/Blizzard_AuraContainerUtil.lua)
retains the earlier candidate helper's permission behavior. The fresh
[comparison from build 70291](https://github.com/Gethe/wow-ui-source/compare/9465cb273b5513495d8ecc12fbb19930dd6b8957...943764493e6b16d63ded3ab304150d1f05e58b57)
changes only `version.txt`; the inspected Lua, XML and generated API bodies
are unchanged. Native source contracts support the design; they do not
establish which protected values were supplied in an unrecorded live state.

## Readable election and recency

Baseline Class and Healing use the same application-time election algorithm
independently within their own lanes. The hostile helpful scan uses that same election when either is its highest category.
Other readable tier elections use native instance ordering.
Utility/Welcoming Campfire uses AuraInstanceIDOnly reverse ordering. On player,
readable direct lookups for Welcoming Campfire 1289723/1229739 join the same
complete indexed Utility election and are deduplicated by instance ID. A direct
witness cannot short-circuit the lane or outrank a newer Utility candidate.
Welcoming Campfire's expiration-minus-60 diagnostic timing is not its election
key.

Application-time evidence comes from a readable DurationObject:GetStartTime()
when available, then readable expirationTime minus duration. The event stream
does not supply synthetic chronology. UNIT_AURA refreshes the affected host
without inspecting updateInfo or maintaining an event-sequence tracker.

A readable replacement follows these rules:

1. Its indexed scan must observe a nil terminator within 80 entries and every
   competing spell identity must be accessible. An unidentified aura could belong to the tier.
2. One candidate is unambiguous even if timing or its instance ID is unavailable.
3. Multiple application-time candidates require every competing start time.
   The election finds the maximum start first.
4. Only a tie at that maximum needs readable instance IDs. An unresolved older
   tie cannot veto a strictly newer aura.
5. Unknown competing time, an unresolved highest-time tie, inaccessible
   identity or an incomplete scan relinquishes the readable replacement.

The hostile scanner chooses the highest category before applying within-tier
ordering. A refreshed Healing aura cannot outrank Power Word: Shield.
HELPFUL|INCLUDE_NAME_PLATE_ONLY includes ordinary helpful auras plus
nameplate-only auras, so ordinary Drink remains in the hostile scan.
The native [aura filter and sort definitions](https://github.com/Gethe/wow-ui-source/blob/943764493e6b16d63ded3ab304150d1f05e58b57/Interface/AddOns/Blizzard_FrameXMLUtil/AuraUtil.lua)
define this inclusion flag and instance ordering.

On player/target/focus, the complete-readable harmful-tier helper serves
Slows, Forbearance/Dazed, Resurrection Sickness, StatusEffects
(Faerie Fire, curses, taunts, casting/attack/healing penalties and serious world debuffs),
and harmful Death Wish.
It is used only when the conservative exact native filter is unavailable.
Each reader scans that lane's actual filter and membership, requires a complete
election, and produces at most one readable owner. Partial or inaccessible
streams cannot establish a winner in any of these lanes. Derived frames retain their
existing native paths and low-priority harmful fallback.

### Direct witnesses and state presenters

Some presenters use a directly readable exact witness rather than claiming a
complete multi-candidate election. They remain distinct from the complete tier
replacement contract:

| Presenter | Current rule |
| --- | --- |
| Boosted Rest 1229451 | Player/target/focus; direct harmful witness only when conservative exact filtering is unavailable |
| Recently Bandaged 11196 | Player/target/focus; direct harmful witness when conservative exact filtering is unavailable |
| Divine Protection | Player/target/focus; direct hostile helpful witness when neither exact native scheduling nor another readable owner can supply that tier |
| Waiting to Resurrect / dead-only speed | Player/target/focus; direct helpful set witness when exact native scheduling is unavailable and the tier has no readable owner |
| Ghost 8326 artwork | Player/target/focus; positive readable UnitIsGhost state, never inferred from dead state or a guessed aura identity |

ToT/FoT do not acquire the ordinary harmful/state helper surfaces. Their
existing shared helpful presenters and native harmful paths retain the small
frame lifecycle. A positive witness can authorize its own presentation without
claiming that the entire lane or private source was enumerated.

## Presentation ownership and fallback

A host records successfully displayed addon-owned tier presentations. A claim
is recorded only after a usable texture is obtained, SetTexture reports
readable success, the cooldown updates or clears successfully, and the frame
shows. Hiding clears the old texture and cooldown; a failed cooldown clear also
attempts the supported zero-duration reset while relinquishing ownership.
The [texture API contract](https://github.com/Gethe/wow-ui-source/blob/943764493e6b16d63ded3ab304150d1f05e58b57/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleTextureBaseAPIDocumentation.lua)
defines SetTexture's separate boolean success result.

For an elected aura, the presenter requests GetAuraDuration with the current
unit and a readable aura instance ID, then passes an accessible duration-object
handle directly to SetCooldownFromDurationObject. Protected timing contents
are left to the native widget. Each assignment uses clearIfZero so a zero
duration clears the previous timer, including a same-instance refresh. The
presentation lookup adds no election evidence and retains no duration object
across updates.

If that route is unavailable or fails, readable numeric timing remains a
fallback. It passes expirationTime minus duration, duration and a readable
positive finite timeMod to SetCooldown; an absent modifier uses the native
default of 1. A readable zero duration permits clearing. Unknown timing or a
supplied inaccessible/invalid modifier cannot authorize a timerless or
incorrect countdown, so the readable presentation relinquishes ownership.
The pinned [cooldown API](https://github.com/Gethe/wow-ui-source/blob/943764493e6b16d63ded3ab304150d1f05e58b57/Interface/AddOns/Blizzard_APIDocumentationGenerated/FrameAPICooldownDocumentation.lua)
and [native aura renderer](https://github.com/Gethe/wow-ui-source/blob/943764493e6b16d63ded3ab304150d1f05e58b57/Interface/AddOns/Blizzard_AuraContainer/Blizzard_CustomAuraButton.lua)
define these presentation methods; getter access and live execution remain
client-dependent.

A complete readable election that actually renders suppresses exactly its
native tier. Revocation immediately restores native scheduling eligibility.
Hostile, Baseline, Healing, Utility, Divine Protection and Waiting to Resurrect
consult the same active-owner state to prevent a duplicate readable presenter.

A partial hostile witness can display only if the native exact tier cannot
run. It cannot suppress a native exact owner or the broad hostile fallbacks.
Hostile Helpful and Frost Armor fallback suppression requires both a complete
election and successful rendering. Chilled Signature is suppressed by native
exact Slows permission or an active readable Slows winner, not by an empty or
failed scan.

Here, a complete readable scan covers the public indexed aura stream. Native
[managed containers](https://github.com/Gethe/wow-ui-source/blob/943764493e6b16d63ded3ab304150d1f05e58b57/Interface/AddOns/Blizzard_AuraContainer/Blizzard_ManagedAuraContainer.lua)
also support a separate
[private source](https://github.com/Gethe/wow-ui-source/blob/943764493e6b16d63ded3ab304150d1f05e58b57/Interface/AddOns/Blizzard_AuraContainer/Blizzard_AuraContainerSources.lua), which does not
signal UNIT_AURA. The public election is therefore not proof of a complete
native-source election. The current candidate API has no private-source
selector; a readable owner can suppress a private same-tier competitor or the
hostile-NPC Frost Armor fallback. This source-coverage limitation remains open;
it does not establish that any pictured player immunity uses the private source.

Readable tier replacements use tier priority + 1, matching the native button.
They do not gain an extra level to defeat their own native counterpart.
Ghost retains its separate UnitIsGhost state witness and Immunity + 2 level;
Waiting to Resurrect remains above it.

## Layout and timers

The native portrait and aura artwork share an addon-owned layer one strata
below the native frame artwork. Construction captures the original parent and
all points for restoration,
then reparents the portrait at its native first point and existing size. Aura
anchors use that point and size, with only the small-frame offsets below;
art uses full texture coordinates `(0, 1, 0, 1)`. Native portrait masks are
reused where available; no second ring or synthetic mask is added.

The pinned [frame contract](https://github.com/Gethe/wow-ui-source/blob/943764493e6b16d63ded3ab304150d1f05e58b57/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleFrameAPIDocumentation.lua)
permits secret native FrameStrata returns. Host creation
checks the parent-strata read for call success, accessibility and string type
before indexing the layer map or changing frame structure. Unavailable strata
postpones construction until an aura/state/token refresh, enabled foundation
update or explicit build can retry. The default MEDIUM strata applies only
when the method is absent, not when a return is secret or otherwise unusable.
This is a supported boundary, not evidence that the reported dungeon pet's
portrait parent returned secret strata.

Countdown placement uses the same setup for native aura buttons, readable
presenters and test frames:

- Player text: translate native anchors +1 X and +1 Y once per font string.
- Target/focus text: translate native anchors +1 X with no added Y offset.
  Large text uses AdjustPointsOffset and retains native size and anchor points.
- Both ToT/FoT icons: +1 X; timers +1 X and -1 Y relative to their icons.
- Small-frame timer font: two points smaller.

The accepted calibration uses the lowered target countdown as its reference.
Its final offsets above incorporate the player +1 Y and focus/small-frame -2 Y
adjustments relative to the preceding calibration. Repeated artwork and
matching countdown glyphs establish the relative placement difference; final pixel rendering still requires a client check.
Circle/icon geometry is retained. Reapplying decimals or swipe presentation
does not accumulate offsets or further reduce the small font.

The native CooldownFrameTemplate owns countdown progression. Its configuration
uses reverse countdown, parent frame level, no bling or edge, and the native
TempPortraitAlphaMask swipe texture. By default,
numbers have one decimal below 10 seconds, use whole seconds through 60, and
are hidden above 60. Swipe defaults off. Decimals and swipe remain configurable.
The preferred native NumericRuleFormatter owns this formatting. If it cannot
be applied, the native millisecond threshold retains the decimals preference;
that compatibility path does not guarantee the above-60-second cutoff.
The test-mode cooldown participates in the same presentation registry, so
changing either setting also updates a running test.

There is no addon-owned OnUpdate countdown or aura polling loop.

## Lifecycle and events

Structural construction, restoration and reparenting remain outside combat.
A combat request queues structural work for PLAYER_REGEN_ENABLED.
BuildAll still refreshes existing presentation in combat, so global/per-unit
re-enable does not require an unrelated later event. Reset applies default
swipe and decimal settings immediately to surviving cooldowns while rebuilding
is deferred.

Per-unit disable immediately refreshes existing presentation before any
stale-host return, including a test frame, while structural work stays queued.
Global off also prevents later unit events from creating new hosts.

[Main.lua](Main.lua) scopes UNIT_AURA, UNIT_FACTION, UNIT_FLAGS,
UNIT_CONNECTION, UNIT_PORTRAIT_UPDATE and UNIT_NAME_UPDATE to the five tracked
tokens, in RegisterUnitEvent groups of at most two tokens. UNIT_TARGET is
registered only for target/focus to refresh their derived tokens. Unit-aura
events refresh presentation; relation and token changes can additionally
force native container refresh.

Player UNIT_FLAGS and UNIT_FACTION invalidate all five hosts because native
identity filters depend on the player's UnitCanAssist relationship to every
unit. The same event refreshes observed foundations. Other unit relation
events remain scoped. This relation invalidation
does not change per-aura secrecy permission or establish live opposing-faction
priority behavior.

UNIT_PORTRAIT_UPDATE and UNIT_NAME_UPDATE update the corresponding independent
foundation. Existing-host updates neither construct frames nor scan auras.
When that host is missing and the addon and pet setting are enabled, the
foundation updater retries the existing guarded CreateHost path. A successful
creation publishes the host before its foundation callback, then receives one
normal Refresh to initialize native scheduling, readable auras or test mode.
The per-unit aura toggle still disables those aura/test owners independently
from pet artwork. The callback therefore does not recursively create hosts.
Combat requests queue the existing regen path; inaccessible strata still defers
construction. Routine aura updates of an existing host do not classify pets.

The native vehicle layout can reuse PlayerFrame and PetFrame without replacing
the objects. Player aura/test presentation requires public PlayerFrame.unit
equal to player; local foundation art requires public PetFrame.unit equal to
pet. A scoped native UnitFrame_SetUnit post-hook reconciles these owned layers
immediately after rebinding. Different or unavailable bindings relinquish the
overlay in place, without creating vehicle hosts or reparenting in combat.

Login and entering-world events build hosts and update foundations. Queued
structural work resumes at PLAYER_REGEN_ENABLED; normal combat deferral already
has this recovery path. Player death/alive/unghost events refresh the player.
Target/focus changes refresh both their outer and derived tokens plus observed
foundations. Local PetFrame updates use UNIT_PET for player,
UNIT_PORTRAIT_UPDATE for pet, and PET_BAR_UPDATE.

### Resource lifetime

With all five hosts available, 61 lanes create 305 native containers and 305 buttons
and 305 cooldowns. Readable/test presentation adds 55 cooldowns, for 360 per
complete build. These are source constructor counts, not measured client memory
or CPU time. Native slot frames and static data-provider-switch subscriptions
outlive host teardown; a completed manual rebuild allocates another set until
reload. Disabled dynamic aura subscriptions are released. Ordinary stable
refreshes reuse the existing structure. This retained resource cost remains a
separate optimization question rather than a proven frame-rate regression.

## Pet and totem foundations

[PetPortraits.lua](PetPortraits.lua) has no direct aura-container access. A positive
local-pet match selects the player's readable Hunter or Warlock class path.
For a local Hunter pet, artwork prefers a public family icon, then a local pet
action texture, then Growl 2649. Missing family information does not block those
local Hunter fallbacks.

Other-player-pet evidence or a readable Pet GUID establishes an observed pet;
a recognized family then selects Hunter or Warlock artwork. Observed Hunter
art prefers a public family icon, then Growl. A confirmed observed pet with an
unknown family retains native art rather than receiving a generic Hunter icon.
Warlock art, including the local class path, requires a recognized demon family
to select its public summon-spell texture.

The existing fallback also permits a positively player-controlled unit with a
recognized family. This can include a controlled beast or demon; it is not
proof of Hunter/Warlock ownership and is never expanded to family alone.

Family name and numeric ID are validated independently with CanAccess. One
sealed field does not discard the other readable field. Localized lookups cache
positive client family matches only; a missing or inaccessible lookup can be
retried on a later existing update event.

Observed foundations stay on the portrait host layer. Local PetFrame art stays
on BACKGROUND sublevel 1 below native BORDER chrome. Masks, pet events and
fallback textures retain their existing behavior.

Foundation texture assignment must return accessible boolean success before
the owned overlay is shown. A rejected assignment, inaccessible result or
assignment/show error hides stale art. A weak texture-keyed table records only
the last operation outcome for on-demand diagnosis; it retains no unit identity.

A classified totem foundation requires a readable native creature-type ID 11 or the
corresponding native localized type name. Only after that type evidence does
an exact readable unit name select a known totem's localized summon-spell art.
Canonical rank suffixes II through VI are accepted after that localized base
name, covering ranked summons such as Searing Totem III. Other trailing words,
partial names and malformed ranks do not match.
An unrecognized totem retains generic totem artwork; an unreadable type does
not authorize a totem foundation. Unit names, models and creature families
alone do not establish totem identity.

A separate static-art path accepts a readable native minion result, explicit
readable player and local/other-pet exclusions, and an exact localized summon
name. Readable non-totem types, Pet GUIDs and recognized pet families veto this
path. It does not infer a creature type or current aura, and missing names or
textures retain native artwork. Generic totem artwork still requires native
totem-type evidence. An otherwise indistinguishable minion sharing that exact
summon name can receive the same static art; this is a presentation rule, not
proof of its restricted type.

The localized name map caches public spell data only. Resolved summon IDs
leave a small pending list; only unavailable spell data is retried. No unit
identity or current aura is cached. The existing unit refreshes re-evaluate
the current actor, and higher-priority aura widgets remain above the
foundation. Flametongue's four applied support aura IDs are independently
included in the low support tier; summon artwork never establishes an aura.

## Commands and diagnostics

[Commands.lua](Commands.lua) supports both `/bp` and `/bjarkiportraits`.
Diagnostics observe current supported data without refreshing presentation,
constructing hosts, reading protected native winners or retaining aura
identities. Their on-demand reads do not form a polling loop.

| Command | Behavior |
| --- | --- |
| `/bp help` | Lists available commands; bare `/bp` also shows help |
| `/bp on` / `/bp off` | Enables/builds or disables/restores owned presentation, with combat-safe structural deferral |
| `/bp player`, `/bp target`, `/bp focus` | Toggles the corresponding host |
| `/bp tot`, `/bp fot` | Toggles the derived host; `targettarget` / `focustarget` are aliases |
| `/bp swipe`, `/bp decimals` | Toggles and immediately reapplies presentation to registered cooldowns |
| `/bp pets` | Toggles foundations; `status`, `on` and `off` are explicit options |
| `/bp test` | Toggles a ten-second Kidney Shot sample on enabled hosts using their normal geometry and timer configuration |
| `/bp inspect [player\|target\|focus\|tot\|fot]` | Defaults to target; bounded public aura/access snapshot |
| `/bp pets debug [pet\|target\|focus\|tot\|fot]` | Unit-specific compact foundation snapshot; without a unit, full diagnostic output for all five foundation tokens |
| `/bp debug` | Five-host relation/readability, election and active-presentation state |
| `/bp audit` | Runtime version/settings, exact membership/overlaps and five-host state |
| `/bp reset` | Restores defaults, rebuilds when permitted, and immediately reapplies timer settings |

### Pet and totem diagnostics

`/bp pets debug target` prints **three lines total**: version/settings header,
unit presentation summary, and unit access-state line. The summary reports
expected art, current overlay, host availability and the last texture operation
without refreshing the portrait first. Access information includes raw family
name/ID states, identity witnesses and the parent-strata boundary when an
observed host is absent. Unreadable GUID evidence is unknown rather than a
negative pet result.

`/bp pets debug` without a unit prints the full diagnostic form, including safe
resolved family name/ID values, identity secrecy and classification reason.
Actual unit family information can remain inaccessible even when public static
family definitions are available. Neither form proves what values were available
during a previous event or reconstructs a portrait after the unit has changed.

### Aura diagnostics

`/bp debug` includes Baseline and Healing timing evidence and active ownership.
`/bp audit` reports current catalogue counts without changing presentation.

`/bp inspect` reports exact-filter eligibility, cached readable presentation
state, and bounded public helpful/harmful scans. Each stream lists at most
12 accessible numeric spell IDs with catalogue priorities, counts inaccessible
identities, and distinguishes a nil-terminated scan from an API error or the
80-entry limit. Its policy line reports current NeverSecret policy for reference
IDs 6615, 2645, 1286304, 1229451, Evasion 5277, Shark Attack 1323184,
Frost Trap 13810 and Frostbolt 116. An ended public scan does not establish
private-source coverage.

Additional on-demand lines report the current Slows/StatusEffects reader state,
native scheduling eligibility, and known-spell query observations for those
three reported effects. These queries are diagnostic only: no new per-ID sweep
is added to UNIT_AURA or the rendering path. A positive direct lookup is not a
complete tier election; nil/no-values can mean absent, invisible or restricted.
Frostbolt's localized-name query can expose another applied rank without
assuming that rank 1 was cast. Spell-secrecy predictions do not prove that an
aura is present or identify an active instance's permission state.

On an indexed-scan API exception, inspect prints at most 160 characters of accessible error
text after stripping controls and chat markup delimiters. Inaccessible or
non-string errors are reported as unavailable without stringification.

## Live validation and open boundaries

The pictured Shark Attack warning matches harmful 1323184, already owned by
StatusEffects 279. Frost Trap's applied slow 13810 and the ordinary Frostbolt
ranks through rank 10 are also already catalogued. Slows' missing per-aura
scheduling opt-in is corrected, but the screenshot does not establish each
aura's live secrecy, native eligibility, timer access or competing portrait
winner. The Shark Attack report remains open. Capture `/bp inspect player`
while the harmful effect is present; use target/focus for the affected unit
when that is the failing surface.

Restricted opposing-faction helpful identities can leave only the broad native
fallback with descending instance ordering. A catalogue's intended numeric order
therefore does not prove general Battleground priority correctness. Native
metadata signatures cannot guarantee an exact identity, and a complete public
readable election does not cover the independent private native source.

Evasion 5277 already belongs to Defensive 290. Its reported absence on an
opposing player in the open world remains unresolved. A readable Evasion can
win through the existing hostile presenter, but the native exact-ID relation
predicate does not become permissive merely because a unit is outside an
instance or combat. No live NeverSecret policy or failure-path capture was
supplied for that screenshot. `/bp inspect target` now includes 5277 in its
on-demand policy line; this observation neither changes permission nor
enables a new rendering fallback.

Reported dungeon pet artwork remains **open for live confirmation**. The
October 10 screenshot shows a target named Bat with its native portrait and
no accompanying API-state diagnostic. Its target-of-target text identifies
what the Bat targets, not its owner. The earlier Warlock-pet report lost its
live state when the user left the dungeon; this new image is separate evidence.

The conditional missing-host recovery gap is repaired: if initial construction
was deferred and a later name/portrait update has sufficient access, the updater
now creates and initializes the host. Source fixtures reproduce that transition,
but the screenshot does not establish that it occurred. Inaccessible family
data, an unqualified pet witness and rejected texture operations remain distinct
boundaries. The fix does not guess family, owner, strata or spell identity.
If the portrait still fails, capture `/bp pets debug target` while that pet is
targeted; its three lines distinguish these paths without refreshing first.

Source contracts and isolated fixtures do not establish protected execution,
actual Battleground aura exposure, readable refresh timing for every spell,
pet-family availability or native mask attachment. Pet artwork,
opposing-faction priority, white totem outcomes and ToT/FoT clipping still need
live client validation. Keep chronological audit notes, screenshots and live
status in [KNOWN_ISSUES.md](KNOWN_ISSUES.md).
