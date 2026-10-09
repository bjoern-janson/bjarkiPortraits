# Known issues and validation

Status recorded 2026-10-09 for **bjarkiPortraits 0.1.89-local**.

This build repairs confirmed source-level routing, readable election,
presentation ownership and lifecycle defects. Isolated behavioral checks do
not establish that the following Battleground reports are resolved.

## Player and target timer placement in 0.1.89

The requested lower placement removes the remaining added upward offsets:
player moves down one UI unit and target moves down two from 0.1.88. Both now
use the native vertical anchor, with the existing horizontal translation.
Focus and derived-frame placement retain their previous settings. A normal
addon reload recreates the countdown widgets and applies the new offsets.
This is a requested visual adjustment; final appearance still needs a game check.

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
symptoms fixed in 0.1.89-local. The added spell IDs and priority changes are
source-confirmed; they still depend on the client exposing the corresponding
aura to an authorized selection path.

See [ARCHITECTURE.md](ARCHITECTURE.md) for the current implementation.
Class-colored unit-frame reports remain in the
[bjarkiUI issue list](https://github.com/bjoern-janson/bjarkiUI/blob/main/KNOWN_ISSUES.md).
