# bjarkiPortraits architecture

This document describes **bjarkiPortraits 0.1.93-local**. It documents the
implementation and its evidence limits; it does not certify live WoW: Forever
Battleground behavior.

## Runtime and scope

The addon has seven Lua modules, loaded in this order:

| Module | Responsibility |
| --- | --- |
| Spells.lua | Applied spell-ID category tables |
| Core.lua | Settings, unit/portrait lookup, access and relation checks, timer formatting |
| Priority.lua | Exact and semantic lanes, immutable indexes, membership audit |
| AuraEngine.lua | Native containers, readable elections, portrait presentation, host lifecycle |
| PetPortraits.lua | Pet-family and totem foundation artwork |
| Commands.lua | Commands and diagnostics |
| Main.lua | Event registration and refresh routing |

Aura hosts cover player, target, focus, target-of-target and focus-of-target.
The local PetFrame has optional foundation artwork. It has no added pet aura
host. Pet artwork and aura selection have separate owners.

## Categories and priorities

Spells.lua contains static membership data. Exact categories in the same aura
stream that share a priority are unioned into one native lane, and every exact spell ID has one
lane owner. Priority.lua derives TIER_BY_KEY, HELPFUL_TIER_BY_SPELL and the
read-only membership audit from that table.

The low band is:

| Lane | Priority |
| --- | ---: |
| Tracking | 0 |
| Cosmetic transformations | 1 |
| Boosted Rest | 1 |
| Campfire Nearby | 2 |
| Hostile Helpful semantic fallback | 3 |
| Small Friendly Harmful semantic fallback | 4 |
| Plainsrunning / Elemental Blessing | 10 |

Tracking includes Find Herbs and Find Minerals. Cosmetic transformations are
one tier above it; Savory Deviate Delight and Savory Whimsyfin Delight share
that lane. Boosted Rest's camping cooldown shares the cosmetic/background
priority and no longer ties the Hostile Helpful fallback. Mobility 160 includes the established Ghost Wolf/Cheetah families
and the movement/stealth category.

Selected category relationships are:

| Lane | Contents or relationship | Priority |
| --- | --- | ---: |
| Travel Utility | Water Breathing, Unending Breath, Water Walking, Aquatic Form and the three applied Noggenfogger effects | 50 |
| Passive Debuff / Righteous Fury | Deserter and item Martyrdom are harmful; Righteous Fury remains helpful | 59 |
| Paladin Aura | Paladin auras, Warlock armor, persistent support totem effects, Rat Familiar and Benevolence | 60 |
| Blood Pact | Blood Pact, the four applied Furious Howl ranks, Iron Creed and Spirit Bond | 70 |
| Baseline Class | Baseline class buffs, Camp Benefits, Demonic Knowledge and Blessing of Blackfathom | 90 |
| Thorns | Thorns and all five canonical Imp Fire Shield ranks | 120 |
| Self State | Forms, Inner Fire and Soul Link | 150 |
| Battleground Flag | Darkspear Islands Flag, above forms and Inner Fire at 150 | 151 |
| Consecration | The applied Forever damage-amplification aura, immediately below DoTs | 189 |
| DoTs | Explicit damage-over-time effects | 190 |
| Low Debuff | Low debuffs, taunts and Cursed Blood | 200 |
| Slows | Slows, exact Chilled IDs, Frost Trap Aura and Highland Venom | 220 |
| Recently Bandaged | Separate harmful state | 229 |
| Forbearance | Forbearance and the existing Dazed member | 240 |
| Resurrection Sickness | Resurrection Sickness | 241 |
| Healing | Ordinary absorbs, HoTs, First Aid channels, Mend Pet | 255 |
| Power Word: Shield | Existing PW:S applied auras and Transformative Cocoon's absorb | 256 |
| Honorless Target | Above Healing | 257 |
| Food/Drink | Food, Drink, Cannibalize, Evocation and Restoration | 260 |
| Innervate | Innervate, Druid Enrage, Bloodrage, Improved Stormstrike, resource recovery and living The Quick and the Dead variants | 261 |
| Utility | Utility buffs and Welcoming Campfire | 270 |
| Combat Debuff | Casting-time penalties, reduced healing received and Shark Attack share one harmful election, immediately below offensive cooldowns | 279 |
| Offensive | Offensive cooldowns, Clearcasting/Preparation, Victorious, Sprint/Dash, Satchel Speed, Cocoon speed, Swift Wind and Battleground Berserking | 280 |
| Harmful Offensive | Death Wish; one level above helpful offense to separate simultaneous countdowns | 281 |
| Roots | Root effects and three retained legacy cast/passive records | 300 |
| Root Immunity | Root immunity, Free Action, Voice of Truth's casting immunity and Grounding spell redirection share this priority | 305 |
| Control / Stun | Separate disjoint exact lanes | 310 / 320 |
| Physical Immunity | Three Blessing of Protection ranks | 315 |
| Helpful Self-Stun | Cocoon's currently helpful self-stun, matching harmful Stun priority | 320 |
| Immunity | Helpful and harmful dispositions remain separate | 330 |
| Divine Protection | Separate helpful lane | 331 |
| Waiting to Resurrect / Ghost Speed | Resurrection waiting and the separate dead-only Quick and the Dead aura, above Ghost | 332 |

Healing contains the restored 17 historical First Aid channel IDs and the
existing Shadow Ward, Sacrifice, Ice Barrier, Fire Ward, Frost Ward and Mana
Shield families. The preceding Contingency Plan wards and ambiguous
custom/trinket records retain their existing classification.

The numeric priority controls presentation order. It does not express spell
strength or establish what a live client will expose.

CombatDebuff 279 unions casting penalties, healing reduction and environmental
danger into one exact harmful lane. They use one native instance-order election
when several are present. Current Forever
1.60.1 applied-aura records support these families:

| Family | Applied IDs |
| --- | --- |
| [Curse of Tongues](https://www.wowhead.com/forever/spell=1714/curse-of-tongues) | 1714, 11719 |
| [Mind-numbing Poison](https://www.wowhead.com/forever/spell=5760/mind-numbing-poison) | 5760, 8692, 11398 |
| [Sonic Blast](https://www.wowhead.com/forever/spell=1264478/sonic-blast) | 1264478, 1264479, 1264480, 1264481, 1264482 |
| [Carved Mind](https://www.wowhead.com/forever/spell=1302342/carved-mind) | 1302342 |
| [Mortal Strike](https://www.wowhead.com/forever/spell=12294/mortal-strike) | 12294, 21551, 21552, 21553 |
| [Wound Poison](https://www.wowhead.com/forever/spell=13218/wound-poison) | 13218, 13222, 13223, 13224 |
| [Hex of Weakness](https://www.wowhead.com/forever/spell=9035/hex-of-weakness) | 9035, 19281, 19282, 19283, 19284, 19285 |
| [Dismember](https://www.wowhead.com/forever/spell=1264758/dismember) | 1264758, 1264927, 1264929, 1264930, 1264933 |
| [Shark Attack](https://www.wowhead.com/forever/spell=1323184/shark-attack) | 1323184 |

Version 0.1.92 introduced the first 30 members at 279. Version 0.1.93 keeps
those priorities and moves Shark Attack from 241 into their shared lane.
The lane opts into the existing per-aura NeverSecret scheduling rule to retain
Shark's previous native eligibility, including small friendly hosts. A complete
readable harmful election still owns its tier; partial streams do not elect a
replacement. The public/private source-coverage limitation below still applies.

The catalog contains 1,155 distinct IDs in 51 disjoint exact lanes, plus 10
semantic lanes. The three additions in 0.1.93 are
[Highland Venom 1316489](https://www.wowhead.com/forever/spell=1316489/highland-venom),
[Blessing of Blackfathom 8733](https://www.wowhead.com/forever/spell=8733/blessing-of-blackfathom)
and [Berserking 1286304](https://www.wowhead.com/forever/spell=1286304/berserking).
Existing Berserking 23505/24378 remain helpful Offensive members. Shark Attack
and Boosted Rest are the only existing IDs whose numeric priorities change;
the other 1,150 retain their levels. Wound Poison
qualifies through flat healing-received reduction; Mortal Strike, Hex and
Dismember use percentage reduction. Poison coatings, training spells and
Carve Mind's hidden proc wrapper are not applied target auras in this lane.

Version 0.1.91 corrected 13 active non-root memberships using current Forever
1.60.1 records. Crippling Poison 3409/11201, Frost Shock 12548 and Curse of
Exhaustion 18223 move from Roots 300 to Slows 220. Tongues 1714/11719,
Viper Sting 3034/14279/14280, Drain Soul 1120/8288 and the Shadowburn
death-item residual 17877/18867 move to LowDebuff 200, following the existing
low-curse/drain/channel policy. No IDs are added or removed; the other 1,119
members retain their owners. Roots retains 31 current root-effect records and
legacy cast/passive IDs 16979/18310/18313. Lane definitions and semantic
exclusion sets are unchanged.

Deserter shares the low passive harmful lane so its long queue penalty does
not displace combat effects. Martyrdom here is the harmful item aura 1292749,
which deals damage on death; it is separate from Priest talents and Waiting to
Resurrect. Grounding's shared priority does not classify it as root immunity.

Version 0.1.85 retains all 1,120 IDs from 0.1.84 and adds five applied-aura IDs:
Soul Link, Demonic Knowledge and three Noggenfogger variants. Death Wish moves
to its harmful stream; Iron Creed moves to the existing minor-buff band.
Version 0.1.86 retains those 1,125 IDs and adds four applied-aura IDs:
[Victorious 402975](https://www.wowhead.com/forever/spell=402975/victorious),
[Spirit Bond 24529](https://www.wowhead.com/forever/spell=24529/spirit-bond),
[Spirit Bond 1310725](https://www.wowhead.com/forever/spell=1310725/spirit-bond), and
[Improved Stormstrike 1238931](https://www.wowhead.com/forever/spell=1238931/improved-stormstrike).
They use existing Offensive, Blood Pact and Innervate membership sets.
Version 0.1.88 retains those 1,129 IDs and adds
[Restoration 1286344](https://www.wowhead.com/forever/spell=1286344/restoration)
at FoodDrink 260,
[Burning Shadow 18789](https://www.wowhead.com/forever/spell=18789/burning-shadow)
at Self State 150, and the visible NPC
[Ice Block 27619](https://www.wowhead.com/forever/spell=27619/ice-block)
at Immunity 330. At that release the exact catalog contained 1,132 distinct IDs
in 50 disjoint exact lanes, plus 10 semantic lanes. Existing lane definitions
and priorities were unchanged. The harmful
offensive lane remains immediately above helpful offense and below defensive
lanes; it provides deterministic layering, not cross-disposition recency.

Preparation and the two new temporary speed effects share the existing
Clearcasting and Sprint/Dash priority at 280. They do not move the separate
Mobility 160 families. Cocoon's self-stun is currently marked Aura Is Buff in
the spell data; its absorb and speed have separate applied IDs. A later
helpful/harmful disposition change requires a verified data update, not a
second speculative lane for the same ID.

## Native containers and permission

Each host creates one Blizzard CustomAuraContainer per configured lane.
Exact lanes keep their static includeSpellIDs map. Semantic lanes use native
metadata filters, such as important, defensive, crowd-control, duration and
dispel type. Native candidates use AuraInstanceIDOnly with reverse direction.

Two addon checks answer different questions:

- ExactFilterAllowed requires positive readable existence and a permitted
  helpful/harmful relation, the helpful player/group exception, or an opted-in
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

The opt-in also bounds the existing partial-readable ownership rule. A tier
can be eligible to run because of an absent NeverSecret member while rejecting
a different, directly readable contextual member. Broadening scheduling alone
can therefore hide a readable portrait without supplying a native replacement.
Version 0.1.88 retains the previous scheduling and ownership policy. Native
per-aura admission is not evidence of an active candidate or a complete election.

Important, ExternalDef and BigDef exclude explicitly classified helpful IDs
where native identity matching is allowed. On restricted relations native
exclusions are ignored. These broad fallback lanes remain useful, but cannot
guarantee the exact taxonomy or exclude an already classified shield there.
The Frost Armor, Chilled and Weakened Soul signatures likewise describe
metadata shapes; they do not prove a spell's identity.

No native child icon, visibility, cooldown value or rendered winner is read
to infer an aura's identity.

These native rules follow the pinned Forever 1.60.1 / build 70245
[candidate-filter implementation](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_AuraContainer/Blizzard_AuraContainerUtil.lua).
The candidate helper is unchanged in the later
[build 70291 source](https://github.com/Gethe/wow-ui-source/commit/9465cb273b5513495d8ecc12fbb19930dd6b8957).

## Readable election and recency

Baseline Class and Healing share one application-time election. The hostile
helpful scan uses that same election when either is its highest category.
Other readable tier elections retain their existing native instance ordering;
Utility/Welcoming Campfire uses AuraInstanceIDOnly reverse ordering.

Application-time evidence comes from a readable DurationObject:GetStartTime()
when available, then readable expirationTime minus duration. The event stream
does not supply synthetic chronology. UNIT_AURA refreshes the affected host
without inspecting updateInfo or maintaining an event-sequence tracker.

A readable replacement follows these rules:

1. Its bounded indexed scan must terminate and every competing spell identity
   must be accessible. An unidentified aura could belong to the tier.
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
The native [aura filter and sort definitions](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_FrameXMLUtil/AuraUtil.lua)
define this inclusion flag and instance ordering.

On player/target/focus, the existing complete-readable harmful-tier helper
serves Slows, Forbearance/Dazed, Resurrection Sickness/Shark Attack,
casting/healing penalties and harmful Death Wish.
It is used only when the conservative exact native filter is unavailable.
Each reader scans that lane's actual filter and membership, requires a complete
election, and produces at most one readable owner. This replaces the old
15007-only Resurrection Sickness reader. Partial or inaccessible streams cannot
establish the winner of either expanded lane. Derived frames retain their
existing native paths and low-priority harmful fallback.

## Presentation ownership and fallback

A host records successfully displayed addon-owned tier presentations. A claim
is recorded only after a usable texture is obtained, SetTexture reports
readable success, the cooldown updates or clears successfully, and the frame
shows. Hiding clears the old texture and cooldown; a failed cooldown clear also
attempts the supported zero-duration reset while relinquishing ownership.
The [texture API contract](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleTextureBaseAPIDocumentation.lua)
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
The pinned [cooldown API](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_APIDocumentationGenerated/FrameAPICooldownDocumentation.lua)
and [native aura renderer](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_AuraContainer/Blizzard_CustomAuraButton.lua)
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
[managed containers](https://github.com/Gethe/wow-ui-source/blob/9465cb273b5513495d8ecc12fbb19930dd6b8957/Interface/AddOns/Blizzard_AuraContainer/Blizzard_ManagedAuraContainer.lua)
also support a separate
[private source](https://github.com/Gethe/wow-ui-source/blob/9465cb273b5513495d8ecc12fbb19930dd6b8957/Interface/AddOns/Blizzard_AuraContainer/Blizzard_AuraContainerSources.lua), which does not
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
below the native frame artwork. Reparenting retains the original portrait
points and size. Native portrait masks are reused where available; no second
ring or synthetic mask is added.

Build 70291 explicitly permits secret native FrameStrata returns. Host creation
checks the parent-strata read for call success, accessibility and string type
before indexing the layer map or changing frame structure. Unavailable strata
postpones construction until an existing refresh can retry.

Countdown placement uses the same setup for native aura buttons, readable
presenters and test frames:

- Player text: translate native anchors +1 X and +1 Y once per font string.
- Target/focus text: translate native anchors +1 X with no added Y offset.
  Large text uses AdjustPointsOffset and retains native size and anchor points.
- Both ToT/FoT icons: +1 X; timers +1 X and -1 Y relative to their icons.
- Small-frame timer font: two points smaller.

The 0.1.90 calibration uses the lowered target countdown as its reference.
From 0.1.89, player text moves up one UI unit; focus and both small timers move
down two. Repeated artwork and matching countdown glyphs establish the relative
placement difference; final pixel rendering still requires a client check.
Circle/icon geometry is retained. Reapplying decimals or swipe presentation
does not accumulate offsets or further reduce the small font.

The native CooldownFrameTemplate owns countdown progression. By default,
numbers have one decimal below 10 seconds, use whole seconds through 60, and
are hidden above 60. Swipe defaults off. Decimals and swipe remain configurable.
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

Main.lua scopes UNIT_AURA, UNIT_FACTION, UNIT_FLAGS, UNIT_CONNECTION and
UNIT_PORTRAIT_UPDATE registrations to the five tracked tokens. UNIT_TARGET is
registered only for target/focus to refresh their derived tokens. Unit-aura
events refresh presentation; relation and token changes can additionally
force native container refresh.

Player UNIT_FLAGS and UNIT_FACTION invalidate all five hosts because native
identity filters depend on the player's UnitCanAssist relationship to every
unit. The same event refreshes observed foundations. Other unit relation
events remain scoped. This corrects a missing invalidation path; it does not
change per-aura secrecy permission or prove opposing-faction priority fixed.

UNIT_PORTRAIT_UPDATE and UNIT_NAME_UPDATE refresh only the corresponding independent foundation,
without scanning auras. A successfully created late host initializes that
foundation once; routine aura updates of an existing host do not classify pets.

The native vehicle layout can reuse PlayerFrame and PetFrame without replacing
the objects. Player aura/test presentation requires public PlayerFrame.unit
equal to player; local foundation art requires public PetFrame.unit equal to
pet. A scoped native UnitFrame_SetUnit post-hook reconciles these owned layers
immediately after rebinding. Different or unavailable bindings relinquish the
overlay in place, without creating vehicle hosts or reparenting in combat.

With all five hosts available, 61 lanes create 305 native containers and 305 buttons
and 305 cooldowns. Readable/test presentation adds 55 cooldowns, for 360 per
complete build. These are source constructor counts, not measured client memory
or CPU time. Native slot frames and static data-provider-switch subscriptions
outlive host teardown; a completed manual rebuild allocates another set until
reload. Disabled dynamic aura subscriptions are released. Ordinary stable
refreshes reuse the existing structure. This retained resource cost remains a
separate optimization question rather than a proven frame-rate regression.

## Pet and totem foundations

PetPortraits.lua has no aura-container access. A positive local-pet match,
other-player-pet result or readable Pet GUID supplies pet evidence. A recognized
family then selects Hunter or Warlock artwork. An observed confirmed pet with
unavailable family information retains native art.

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

Commands include on/off, player/target/focus/tot/fot, swipe, decimals, pets,
test, inspect, debug, audit and reset. Both /bp and /bjarkiportraits are supported.

Debug reports relation/readability, election and active-presentation state,
including Baseline and Healing timing evidence. Audit reports version,
settings, lane membership/overlaps and host state without changing presentation.

The explicit pets debug command also reports identity secrecy, raw family
name/ID access states and the parent-strata boundary when an observed host is
missing. Unreadable GUID evidence is unknown, not a negative pet result. It
reports the expected icon and currently shown overlay without refreshing the
portrait first, so an absent overlay remains observable. These extra reads run
only on demand. `/bp pets debug target` (also pet/focus/tot/fot) provides two
compact unit-specific state/access lines after the version/settings header.

`/bp inspect [player|target|focus|tot|fot]` defaults to target. It reports current
exact-filter eligibility, cached readable presentation state, and bounded public
helpful/harmful scans. Each stream lists at most 12 accessible numeric spell IDs
with catalog priorities, counts inaccessible identities, and distinguishes an
ended scan from an error or the 80-entry limit. An ended public scan is not proof
of private-source coverage. A final line reports current NeverSecret policy for
the four diagnostic reference IDs. The command does not refresh presentation,
create hosts, inspect protected native candidates or retain aura identities.

## Live validation boundary

Source and isolated behavioral checks cannot establish protected execution,
actual Battleground aura exposure, readable refresh timing for each spell,
pet-family availability or native mask attachment. The reported pet artwork,
opposing-faction priority, white totem and ToT/FoT clipping outcomes still need
client validation. See [KNOWN_ISSUES.md](KNOWN_ISSUES.md).
