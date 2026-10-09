# Known issues and validation

Status recorded 2026-10-09 for **bjarkiPortraits 0.1.98-local**.

This build corrects native scheduling for public slow-aura exceptions and
extends on-demand inspection of Shark Attack and BG slows. The live Shark
Attack failure and the full reported slow-visibility failure remain open until
the affected unit's API state is captured. Earlier priority changes are retained.

## Shark Attack and Battleground slows in 0.1.98

| Reported effect | Existing applied record | Priority |
| --- | --- | --- |
| [Shark Attack](https://www.wowhead.com/forever/spell=1323184/shark-attack) | 1323184, matching the pictured harmful water-hazard warning | CombatDebuff 279 |
| [Frost Trap area slow](https://www.wowhead.com/forever/spell=13810/frost-trap) | 13810, the applied persistent area slow | Slows 220 |
| [Frostbolt](https://www.wowhead.com/forever/spell=116/frostbolt) | Ordinary ranks 1-10 and the four already listed variants directly apply their slows | Slows 220 |

Current Forever records support these mappings. This update changes no spell
IDs or exact spell priorities. The screenshot does not identify the competing timed
portrait aura, which is at 0.3 seconds, or expose its priority.

The Slows lane lacked the per-aura NeverSecret scheduling opt-in already used
by CombatDebuff. A source reproduction supplies a public Frostbolt, a contextual
Frost Trap and an inaccessible harmful identity. Native's actual predicate
admits the public slow, while the old addon scheduler disables its container
on self, friendly target and friendly ToT. Slows now opts into the same native
rule. The native predicate continues to reject each forbidden identity.

The integrated fixture passes all 13 cases; the frozen baseline fails the
three intended scheduling cases. The supplied NeverSecret value is a controlled
input, not a captured classification of the user's active Frostbolt. This
establishes the scheduler correction, not complete live BG slow visibility.

Review also reproduced simultaneous admission of a public exact slow and a
contextual Chilled approximation at the same native button level. Only the
semantic ChilledSignature moves from 220 to 219; exact Chilled IDs stay in
Slows 220. The exact button is configured above the approximation, while
the approximation remains available when a public member makes Slows eligible
but is absent. No other relative tier ordering changes.

Shark Attack already has the correct native scheduling opt-in. The ordinary
harmful-tier reader deliberately requires a complete readable election: one
inaccessible competing identity, a failed scan or unavailable ordering can
revoke the readable winner. Small derived frames retain their native paths.
Readable identity also needs usable native or readable timing before the
owned presenter can claim the lane. None of these boundaries is established
as the screenshot's failure cause, so the election and presentation contracts
remain unchanged.

`/bp inspect player` now adds the affected reader states, native eligibility,
base secrecy and known-spell observations for Shark Attack, Frost Trap and
Frostbolt. The Frostbolt name query can observe another rank when exposed.
Lookups run only on that command, without refreshing or painting the UI.
Nil/no-values does not distinguish absence, invisibility and secrecy; a
spell-secrecy prediction does not prove an active aura. Capture the full output
while the missing effect is present. For a failing target/focus portrait,
inspect that unit instead.

### Source verification for 0.1.98

| Check | Result |
| --- | --- |
| Native scheduling and permission preservation | 13/13 |
| Exact slow / semantic Chilled coexistence and absent-public-member controls | 6/6 |
| New inspection cases | 18/18 |
| Retained recent portrait/inspection cases | 14/14 |
| Retained unsafe-error cases | 3/3 |
| Lua syntax | All seven runtime modules compile |
| Catalogue | 1,172 IDs, 75 categories, 51 exact and 10 semantic lanes; no exact overlaps |
| Source scope | Seven intended files; other modules and bjarkiUI unchanged |

Root observed the intended failing cases before each behavioral correction.
The fixtures load actual addon sources and the pinned native permission helper
with modeled aura metadata and API boundaries. They do not reproduce the live
protected client or prove current spell-secrecy classifications.

The older a/b/c harness remains at 45/74 passing. Its 29 failing case names and
error strings are identical on the complete frozen 0.1.97 baseline
(`d6f537678ebde9c656ebba2184cd715e977d3822`) and the integrated 0.1.98 sources.
This broader run is not a clean acceptance gate. No historical case was removed
or weakened, and the source comparison found no additional failures.

<details>
<summary>Historical cases still failing on both complete versions</summary>

```text
retained-a: low_floor_shift_preserves_every_old_order_and_tie
retained-a: pws_mend_pet_and_existing_special_priorities_remain_distinct
retained-b: active_slows_suppresses_chilled_at_its_own_native_level
retained-b: aura_removal_revokes_healing_replacement
retained-b: baseline_irrelevant_older_tie_does_not_veto_newest_application
retained-b: baseline_single_candidate_needs_no_timing_or_instance_witness
retained-b: cooldown_clear_failure_revokes_readable_healing_owner
retained-b: cooldown_set_failure_revokes_readable_healing_owner
retained-b: equal_highest_time_and_identity_cannot_fabricate_a_winner
retained-b: healing_failed_texture_keeps_native_fallback
retained-b: healing_falls_back_from_sealed_duration_object_to_readable_fields
retained-b: healing_irrelevant_older_tie_does_not_veto_newest_application
retained-b: healing_prefers_readable_duration_object_start_time
retained-b: healing_refresh_with_same_instance_beats_newer_instance
retained-b: healing_resolves_only_the_highest_time_tie_by_instance_id
retained-b: healing_single_candidate_needs_no_timing_or_instance_witness
retained-b: inaccessible_aura_object_revokes_healing_replacement
retained-b: inaccessible_candidate_identity_revokes_healing_replacement
retained-b: incomplete_bounded_stream_revokes_healing_replacement
retained-b: missing_cooldown_reference_revokes_readable_healing_owner
retained-b: slows_empty_complete_scan_preserves_chilled_signature
retained-b: slows_texture_failure_preserves_chilled_signature
retained-b: slows_unresolved_election_preserves_chilled_signature
retained-b: unknown_competing_start_time_revokes_healing_replacement
retained-b: unresolved_highest_start_time_tie_revokes_healing_replacement
retained-b: utility_retains_native_instance_id_ordering
retained-c: local_hunter_and_warlock_foundations_preserve_existing_artwork
retained-c: per_unit_disable_hides_existing_presentation_in_combat
retained-c: per_unit_disable_hides_stale_host_before_combat_refresh_returns
```

</details>

## Requested aura priorities in 0.1.97

| Effect | Applied IDs | Current priority |
| --- | --- | --- |
| [Vengeance](https://www.wowhead.com/forever/spell=20050/vengeance) | 20050 | BloodPact 70, alongside Furious Howl |
| [Warrior Thunder Clap](https://www.wowhead.com/forever/spell=6343/thunder-clap) | 6343, 8198, 8204, 8205, 11580, 11581 | CombatDebuff 279 |
| [NPC Thunderclap](https://www.wowhead.com/forever/spell=8078/thunderclap) | 8078, 1213464 | CombatDebuff 279 |
| [Muculent Rot](https://www.wowhead.com/forever/spell=1316387/muculent-rot) | 1316387 | CombatDebuff 279 |
| [Dust Storm](https://www.wowhead.com/forever/spell=1316382/dust-storm) | 1316382 | CombatDebuff 279 |
| [Demoralizing Screech](https://www.wowhead.com/forever/spell=24423/demoralizing-screech) | 24423, 24577, 24578, 24579 | Demoralizing 185 |
| [Fevered Fatigue](https://www.wowhead.com/forever/spell=8139/fevered-fatigue) | 8139 | LowDebuff 200 |
| [Reflection Field](https://www.wowhead.com/forever/spell=1303458/reflection-field) | 1303458 | Helpful Immunity 330 |

Vengeance moves down from Offensive 280. The three previously listed warrior
Thunder Clap ranks move up from LowDebuff 200, and the two previously listed
Screech ranks move to Demoralizing 185. Eleven IDs are added, producing
1,172 distinct IDs across the same 51 exact and 10 semantic lanes, with no
overlapping exact owners. The other 1,155 existing IDs retain their exact
owners and priorities. Attack penalties have a distinct source category
unioned into the existing CombatDebuff lane, so no additional native widgets
are created.

The two NPC Thunderclap records have matching Nature-damage, attack-speed and
movement-slow descriptions; the screenshot does not distinguish their IDs.
All six canonical warrior ranks apply attack-speed penalties. Screech's four
applied pet ranks share the Shout/Roar category. Passive Vengeance 20049 and
Screech's Learn Spell 24424 are excluded.

Current public records and screenshots differ in two quantities: Muculent Rot
describes 15% Spirit/Stamina reduction while the image says 35%; Fevered
Fatigue's default tooltip describes 6/6 while the image says 11/11. Each has
one visible current exact-name aura, and Fevered Fatigue's source usage list
includes the pictured Mesa Buzzard. No explanation for either difference is
established. Their passive triggers 1316388 and 11964/18847 are
excluded. Selection uses the applied ID, not a parsed amount or aura name.

Reflection Field 1303458 directly applies spell reflection and describes
protection of nearby allies, supporting the helpful Immunity 330 category.
The screenshot does not expose its live aura disposition. The area-trigger
cast 1303459 is excluded; its ten-second lifetime is not the applied aura's
duration. The five-second Magic variant 10831 and the unrelated same-name
Agility effect Dust Storm 1269929 remain outside this screenshot addition.

## Evasion on an opposing open-world player

[Evasion 5277](https://www.wowhead.com/forever/spell=5277/evasion) already has one
owner, helpful Defensive 290. The current player record matches the pictured
50% dodge description. Neither catalogue absence nor a low numeric priority
explains this report. Source checks show that readable Evasion already wins
over a newer offensive aura, including the existing eligible partial-readable
path. These checks do not identify the screenshot's actual failure boundary.

The pinned native identity-filter predicate applies helpful/harmful relation
rules independently of combat or instance location. An opposing helpful aura
whose identity is unfilterable can be rejected by the exact-ID container in
the open world. A readable ID with unusable timing can also relinquish the
readable presenter. No live access, timing or NeverSecret policy capture was
supplied, so this build leaves the existing rendering and scheduling rules
intact rather than promoting a conditional explanation to a confirmed fix.

`/bp inspect target` now appends Evasion 5277 to its existing on-demand
NeverSecret reference line. It retains the same guarded API call and
yes/no/unknown output; it performs no presentation refresh. Capture the full
inspect output while the affected target still has Evasion active. `/bp debug`
can add the current selection/presentation state. A readable policy result is
one boundary observation, not proof that every other rendering prerequisite
was satisfied.

## Veil of Shadow in 0.1.96

Veil of Shadow 7068, 17820 and 460755 join the existing healing-reduction
category at CombatDebuff 279, immediately below Offensive 280. Current
Forever records give all three the screenshot's 75% healing-reduction Curse
tooltip and a 15-second duration. The crop's 12 seconds remaining cannot
distinguish the exact ID or caster. No name-based classification is added.

The catalog contains 1,161 distinct IDs with no overlapping exact owners.
All 1,158 pre-existing IDs retain their owners and priorities. This data-only
addition uses the existing lane and selection rules; portrait geometry and
countdown calibration are unchanged. The membership check does not certify
live visibility where client aura access is restricted.

## Poison Cloud in 0.1.95

Applied Poison Cloud 3815 joins DoTs 190 and its existing generic-fallback
exclusion. Ironspine's current abilities table lists this spell. It is a
harmful Poison aura with five-second periodic damage and a 45-second duration,
consistent with the screenshot's name, type, tick interval and 39 seconds
remaining. The live screenshot does not expose a spell ID, and its 99-damage
value differs from current public tooltip values; no exact numeric match or
reason for that discrepancy is claimed. Item, summon and shorter-duration
same-name effects are not added.

The catalog contains 1,158 distinct IDs with no overlapping exact owners.
All 1,157 pre-existing IDs retain their owners and priorities. Aura selection,
permissions, portrait geometry and countdown calibration are unchanged.

## Speed, Stormstrike and live diagnostics in 0.1.94

Applied Speed 23978 and 1286345 join the existing 23451 at Offensive 280,
sharing the requested Sprint/Dash priority. All three current records describe
100% movement speed for ten seconds. Hidden visual 1286342 is excluded, and
potion Speed 1309728 retains its existing membership. No Speed tooltip/ID was
supplied in this batch: the additions close verified catalog gaps but do not
prove the cause of the reported friendly display failure.

Improved Stormstrike 1238931 moves from Innervate 261 to Seal 210. Its distinct
source category joins the same native election as the paladin seals; there is
no second widget at that priority. The passive talent 1223031 is not added.
The catalog now has 1,157 distinct IDs, with 51 exact and 10 semantic lanes.
The other 1,154 existing IDs retain their exact owners and numeric levels.

Four .93 captures show exactHelpful=false, exactHarmful=true, no readable
hostile winner, and immediate scan=error with zero returned entries in both
streams. The four reference IDs (Free Action 6615, Ghost Wolf 2645, Berserking
1286304 and Boosted Rest 1229451) all report neverSecret=no. Thus the readable
scan cannot supply a category in those captures, and those reference IDs do
not qualify for a NeverSecret exception. Native broad fallback ordering remains.

The current GetAuraDataByIndex contract requires unit aura access, with a
documented error failure when that access precondition is not met. The capture
does not include the exception text, so it cannot uniquely establish the error's
cause. `/bp inspect target` now includes a bounded, sanitized accessible error
message; inaccessible error objects remain unprinted. This diagnostic change
does not broaden aura access or claim to repair restricted sorting.

The Earthbind Totem capture reports host=true, expected=false, last=none,
name=secret and type=secret/secret. Its minion witness and player/pet exclusions
pass. This establishes missing classification information in that state, rather
than an expected icon lost to a missing refresh or failed texture assignment.
UnitIsMinion also covers guardians, so it cannot alone authorize a generic
totem icon. The inspected native slot-based Totem APIs provide no arbitrary
target discriminator. The supported native model remains in this captured
state; further name aliases or refreshes do not address it.

## Battleground follow-up in 0.1.93

Highland Venom 1316489 joins Slows 220; Blessing of Blackfathom 8733 joins
BaselineClass 90; the applied Berserking variant 1286304 joins Offensive 280.
The screenshot does not distinguish the three equivalent Berserking IDs.
Highland Venom's current record shows a 15% damage penalty while the screenshot
shows 20%; its name, icon, Disease type and effect family match. Hidden visual
wrappers and Shark's direct-damage trigger are not added as portrait auras.

Shark Attack 1323184 moves from 241 into CombatDebuff 279, sharing the existing
casting/healing penalty election immediately below Offensive. Its previous
NeverSecret eligibility is retained through a scoped lane opt-in. An absent
NeverSecret member does not displace a complete readable harmful winner;
incomplete streams cannot produce a guessed replacement. The public/private
source-coverage limitation remains.

Boosted Rest 1229451 moves from 3 to 1, above Tracking and below the broad
HostileHelpful fallback. This removes their presentation-level tie. The XP
screenshot lacks a tooltip/ID; the current icon's sole spell association supports
Boosted Rest but does not prove its live identity.

Free Action 305, Ghost Wolf 160, class buffs 90 and paladin auras 60 already
have the requested numeric order. Restricted opposing-faction helpful identities
cannot enter exact spell-ID native filters. When no supported classified
presenter is available, the broad native fallback uses descending AuraInstanceID,
which can look like the last applied buff wins. The build retains that visibility
fallback; it does not claim general opposing-faction priority repair.
`/bp inspect target` reports the current public identities, catalog priorities
and access state without refreshing the failing presentation.

UNIT_NAME_UPDATE now retries the corresponding pet/totem foundation without
scanning auras. This repairs names arriving after targeting and same-token name
changes. Rejected or failed texture assignments hide previous artwork instead of
showing stale art. Both pictured totem names already resolve under public inputs.
Their screenshots do not establish a missing-name event or texture failure;
unavailable identity/family/host information can still require native artwork.
`/bp pets debug target` provides compact evidence without refreshing first.

The catalog has 1,155 distinct IDs and no overlapping exact owners. Apart from
Shark and Boosted Rest, all 1,150 existing numeric priorities are retained.
The accepted circle/countdown calibration and five-host widget counts are
unchanged.

## Casting and healing penalty priority in 0.1.92

CastHealingPenalty 279 sits directly below Offensive 280 and above Utility
270. Its 30 applied aura IDs cover Curse of Tongues, Mind-numbing Poison,
bat Sonic Blast, Carved Mind, Mortal Strike, Wound Poison, Hex of Weakness
and crocolisk Dismember. Ten existing IDs move from LowDebuff; 20 verified
applied ranks/effects are added. The other 1,122 existing IDs retain their
owners. The exact catalog has 1,152 distinct IDs and no overlapping owners.

The native lane covers all five existing aura hosts under the same permission
rules. Player/target/focus also use the existing complete-readable harmful
fallback when native exact filtering is unavailable. Partial or inaccessible
streams cannot establish a winner. Small derived hosts retain their existing
native-only harmful fallback. No new NeverSecret opt-in is introduced.

Thirteen isolated behavioral cases cover ordering, shared membership,
semantic exclusions, nameplate-only inclusion, readable/native ownership,
relation changes, removal, disable, test mode, rebinding and widget reuse.
Current public spell records establish the applied IDs and effects; neither
those records nor isolated tests prove live Battleground presentation.

## Lifecycle and catalog repairs in 0.1.91

Player UNIT_FLAGS/UNIT_FACTION now refresh all five aura hosts and observed
foundations, following the native identity-filter invalidation contract.
Previously only the player's host was refreshed even though UnitCanAssist
could change for every other unit. Per-aura permissions and the existing
NeverSecret opt-ins remain unchanged. This source repair does not prove the
Ice Block/Forbearance or other opposing-faction screenshots are resolved.

Existing presentation now refreshes on combat re-enable while structural work
remains deferred. Reset immediately applies default swipe/decimal options.
A late-created host initializes its foundation once, and native portrait-only
events retry or clear pet art without scanning auras. Player and local-pet
overlays relinquish presentation when native vehicle layout rebinds their
frames to another or unavailable unit. These fixes close demonstrated lifecycle
gaps; inaccessible family data can still leave native art in instances.

Thirteen non-root applied records leave Roots 300: Crippling Poison, one Frost
Shock variant and Curse of Exhaustion use Slows 220; Tongues, Viper Sting,
Drain Soul and Shadowburn's death-item residual use LowDebuff 200. The exact
1,132-ID universe and other 1,119 memberships are preserved. Current public
records were retrieved for 195 of the baseline's 200 IDs at priority 291 or above; IDs
5530/12798/19386/24132/24133 were unavailable and remain unchanged. The
932 IDs outside that semantic pass received structural checks, not a fresh effect-by-effect
validation. Current database records are not live aura-disposition captures.

## Resource lifetime

One complete five-host build constructs 305 native containers, 305 buttons and
360 cooldowns. Manual teardown disables dynamic subscriptions but does not
destroy native slot objects or their static data-provider-switch callbacks;
completed rebuilds retain another set until reload. This is a source-level
resource-lifetime limitation, without an in-game memory or performance estimate.

## Common countdown placement in 0.1.90

Matching countdowns in the latest screenshots expose a two-pixel Target/Focus
placement difference after their identical artwork is aligned. The target's
lowered position is retained as the calibration reference. Relative to 0.1.89,
player text moves up one UI unit and focus/ToT/FoT text moves down two.
Horizontal placement, icon geometry, fonts and duration handling are retained.
A normal addon reload recreates the widgets and applies the new offsets.
This is the accepted visual calibration; final appearance still needs a game check.

## Countdown, catalog and ranked totems in 0.1.88

Comparing matching countdown glyphs against the screenshot's gold portrait
rings shows player text about one pixel higher than target text. Player text
is lowered by one UI unit. The target/focus and small-frame offsets, fonts and
all portrait circles are retained. Offline checks cover the shared native,
readable and test presenters; final optical alignment needs the live client.

The current applied Restoration aura 1286344 joins FoodDrink 260, alongside
the existing Restoration variants. Burning Shadow 18789 joins forms/Self
State 150. Ice Block 27619 adds a visible NPC equivalent to Immunity 330;
player Ice Block 11958 was already present. These additions follow current
Forever spell records and do not establish the exact ID in a screenshot
without an exposed ID.

A friendly Battleground screenshot shows Searing Totem III. Its public summon
spell name is unranked, so the prior exact-name lookup could not select its
specific art. Localized name matching now accepts canonical II–VI rank suffixes.
All existing native-type or public-minion qualifications, player/pet exclusions,
access checks and native-art fallbacks remain. This repairs the ranked-name gap;
the screenshot does not establish which identity or host-construction inputs
the live client supplied. `/bp pets debug` remains useful if a totem still lacks
its expected icon.

## Battleground ordering remains unresolved in 0.1.88

Leader of the Pack remains Baseline Class 90, Forbearance remains 240, player
Ice Block remains Immunity 330 and Divine Protection remains 331. The current
native scheduling and readable ownership rules are unchanged in this build.

The addon's native scheduling opt-in is narrower than Blizzard's per-aura
NeverSecret admission rule. Removing that opt-in alone reproduced a regression:
an absent NeverSecret member could enable a mixed tier and make the partial
readable presenter yield, even though native filtering still rejected the
present readable member. No active native replacement was established. That
scheduling change is not included in this build.

The pictured player Ice Block's live secrecy policy is not established.
Divine Protection already has the existing opt-in, and its latest screenshot
shows zero seconds remaining, so neither a policy nor an expiry cause is
established for that report.

Both native and readable Forbearance stay below eligible immunity and defensive
lanes in isolated checks. An aura exposed only through a broad native fallback
may still lack its exact catalog priority. The remaining opposite-faction
reports require live exposure/filter evidence; the tier numbers alone do not
explain them.

## Public and private aura-source coverage

The public indexed scan can finish without covering the private source used
by native managed containers. Private aura updates also use a separate native
callback rather than UNIT_AURA. With a synthetic private competitor, isolated
execution reproduces suppression of a same-tier native owner or the hostile-NPC
Frost Armor signature by an otherwise complete public readable election.
BigDef and ExternalDef remain enabled. This proves a source-coverage gap; it
does not prove that the pictured Ice Block or Divine Protection is private.

The current native candidate API offers no private-source selector. Keeping
the broad NPC signature permanently enabled would change known public-aura
classification, while relinquishing all readable owners would lose the existing
application-time election. No general source-merging repair is included in
0.1.88; the current readable recency and native category policies are retained.

## Countdown alignment and dungeon pets in 0.1.87

A screenshot showing the same 6.6 countdown on all five frames supports moving
large-frame text +1 X and all countdowns +2 Y. The small text anchors become
(+1, +1); large text uses a native anchor translation. Circle positions and
font sizes are retained. The screenshot measures visible glyphs and asymmetric
artwork, not live frame coordinates; the final rendering still needs a client
check at the user's display scale.

A dungeon screenshot shows a native Crocolisk model instead of family artwork.
Replaying 0.1.83 through 0.1.86 with the same public and restricted family inputs
did not establish a version-specific cause. The existing missing-host strata
guard and unavailable-family fallback remain separate possible boundaries.
No dungeon-pet runtime repair is claimed in this build.

The pets debug command previously refreshed artwork before printing, erasing a
reproduced missing-refresh symptom. It now preserves the current overlay state
and reports raw family access, identity secrecy and missing-host strata access.
Run `/bp pets debug` while the failing dungeon pet is targeted to distinguish
missing family data, missing host construction and an expected icon whose
overlay was not refreshed. Restricted values remain unread and unprinted.

## Applied-aura additions in 0.1.86

Victorious 402975 joins Offensive 280. Spirit Bond 24529 and 1310725 join
Blood Pact 70. Improved Stormstrike 1238931 joins resource recovery/Innervate
261. These are catalog additions only: existing native permissions, timers,
priority lanes and artwork paths are unchanged. The applied IDs match the
current Forever spell records; no live run of this build has confirmed their
portrait presentation or availability in protected contexts.

## Catalog and artwork repairs in 0.1.85

Soul Link now occupies forms/Self State 150; Demonic Knowledge occupies
Baseline Class 90; Iron Creed moves to Blood Pact/Furious Howl 70. All three
applied Noggenfogger variants occupy Travel Utility 50. Death Wish uses its
harmful disposition at 281, immediately above helpful offense so their separate
countdown surfaces have a deterministic draw order. Player/target/focus can use
the existing complete-readable harmful fallback when exact native filtering is
unavailable. ToT/FoT retain their existing native permission boundary.

A new live screenshot still places Cocoon self-stun in the helpful bar.
Its helpful stun mapping is therefore retained; a patch-note description alone
does not justify moving it to the harmful stream.

Magma and Grounding already had summon mappings. The new minion-spell artwork
path covers unavailable creature type when every required public minion/name
and exclusion witness is available. The screenshots do not expose those inputs,
so their missing portraits still require a live check. `/bp pets debug` reports
the current artwork mode and readable qualification inputs.

ToT and FoT now use identical internal icon offsets. The ToT timer retains its
previous absolute position. Player artwork is unchanged after comparison with
the same icon in the target frame. These measured adjustments do not certify
native clipping at every display scale.

## Protected countdown presentation in 0.1.82

The readable presenter previously cleared protected numeric timing while still
claiming its tier, even when a usable native duration object was available.
This build transports the current elected aura's duration object to the native
cooldown widget. Same-instance refreshes and unit changes fetch current data;
a zero object clears the previous timer.

When object rendering is unavailable, numeric fallback preserves a readable
timeMod. Unknown timing or an inaccessible/invalid supplied modifier revokes
the readable presentation instead of suppressing the native tier with an
unsupported timer. Priority, application-time election, geometry and countdown
formatting retain their existing behavior.

These transitions are covered by actual-source tests with mocked native
boundaries. Restricted getter access, protected execution and visible native
countdown behavior still need in-client validation.

## Battleground pet portraits

Hunter and Warlock pet artwork has been reported missing or incorrect on
friendly and enemy units in Battlegrounds. Warlock pets have also been reported
with an unexpected Growl icon. Hunter artwork working outside a Battleground
does not establish its behavior inside one.

Family name and ID are now independently access-checked, and unsuccessful
localized-family lookups can be retried. The existing positive pet/control
witnesses and native-art fallback remain. Live family availability and artwork
selection still need verification.

## Opposing-faction aura categories and priority

Reported expectations include Drink above DoTs, Honorless Target above healing,
Water Breathing near the bottom with water/travel utility, and appropriate
visibility for Blessing of Freedom, Stoneform and Divine Protection. Leader of
the Pack has also been reported surfacing too high.

This build restores Tracking and Mobility routing, moves Water Breathing to
Travel Utility 50, restores historical First Aid coverage, places established
ordinary absorbs in Healing 255, and retains Power Word: Shield separately at
256. Healing/Baseline refresh recency uses readable application-time evidence.
The hostile scan includes ordinary and nameplate-only helpful auras, and native
fallbacks are retained when readable evidence or rendering fails.

These fixes do not prove that each expected aura is exposed in a Battleground.
When exact identity matching is restricted, native semantic exclusions are
ignored. A broad defensive/signature fallback can therefore differ from the
exact category taxonomy. Unknown application timing also leaves native
instance ordering in control instead of promising refresh recency.

## Friendly Forbearance and shared harmful lanes in 0.1.84

A friendly Battleground screenshot shows Forbearance beneath the target frame
without a portrait replacement. Source execution reproduces a gap when the
harmful stream is fully readable but native exact filtering is relation-gated.
The existing complete-readable harmful election now covers Forbearance/Dazed
and Resurrection Sickness/Shark Attack on player/target/focus. It revokes the
readable owner on an incomplete stream, unknown identity or failed rendering.
Native per-aura permission and the derived-frame paths remain unchanged.

Blessing of Protection now has a physical-immunity lane with the existing
NeverSecret eligibility opt-in. Divine Protection was already above Forbearance
through both its readable hostile path and permitted native lane. Its reported
zero-second screenshot does not establish which aura the client still supplied
at the update boundary. Live identity availability and expiry transitions
remain to be checked.

## Current Cocoon and ghost-speed records

Transformative Cocoon has separate applied IDs for speed 1301168, absorption
1316048 and self-stun 1301167. The current source marks the self-stun helpful;
it has its own helpful lane at Stun priority. A maintenance change to harmful
must be verified before changing its filter. The dead-only Quick and the Dead
1262229 joins the above-Ghost lane independently of its living variants. Its
current data tooltip differs from the older screenshot's movement percentage;
selection uses the exact aura ID, not tooltip text or inferred death state.

## Native frame-strata contract in build 70291

The updated native frame API explicitly allows secret FrameStrata returns.
Host construction now postpones all structural mutations when the parent's
strata read fails or is inaccessible, retrying through existing refreshes when
readable. The source-level guard and recovery are exercised offline; no live
post-maintenance protected-execution result is implied.

## Totem foundations and aura exposure

An enemy Healing Stream Totem was reported with a white portrait and no visible
aura. A later Flametongue Totem screenshot showed a native model and an aura
below the frame. Version 0.1.83 adds native-type-qualified totem foundations,
specific art for recognized localized totem names, and generic art for other
positively identified totems. Higher-priority auras retain ownership above it.
Flametongue's applied support auras are also included in the low support tier.

The screenshot alone does not identify the displayed aura. Live native type
availability, localized unit names and actual aura exposure remain separate
validation requirements; a foundation icon does not prove an aura is active.

## Waiting to Resurrect disposition

A 2026-10-08 screenshot places an icon titled Waiting to Resurrect beside the
harmful item Martyrdom aura, in the native harmful row. It does not expose the
spell ID or current aura filter. The existing helpful Waiting to Resurrect
lane (2584, 21989, 1234325), above Ghost, is retained pending an exact in-client
identity/disposition observation. Do not infer a connection to Martyrdom from
adjacent icons or replace a precise category with a name-based fallback.

## ToT/FoT border bleed

Aura artwork on target-of-target/focus-of-target has been reported peeking past
the small portrait border. Native masks, frame hierarchy and chrome are
preserved. Version 0.1.85 corrects the measured internal ToT offset, but static
inspection cannot establish successful mask attachment or correct clipping.
No border-clipping repair is claimed.

## Secret aura-update metadata

Version 0.1.71 raised an error when testing secret updateInfo.isFullUpdate on
Battleground entry. The current runtime removes that metadata inspection and
its disconnected sequence tracker entirely. UNIT_AURA now triggers the normal
refresh path directly. This removes the identified access path; broader
Battleground execution still needs live validation.

## Verification boundary

Live acceptance should include refresh-without-new-instance behavior, unknown
timing and identity, token changes, combat toggles, active test settings, pet
foundations and ToT/FoT clipping. No live WoW run has confirmed all reported
symptoms fixed in 0.1.91-local. The added spell IDs and priority changes are
source-confirmed; they still depend on the client exposing the corresponding
aura to an authorized selection path.

See [ARCHITECTURE.md](ARCHITECTURE.md) for the current implementation.
Class-colored unit-frame reports remain in the
[bjarkiUI issue list](https://github.com/bjoern-janson/bjarkiUI/blob/main/KNOWN_ISSUES.md).
