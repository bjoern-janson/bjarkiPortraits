# Known issues and validation

Status recorded 2026-10-09 for **bjarkiPortraits 0.1.86-local**.

This build repairs confirmed source-level routing, readable election,
presentation ownership and lifecycle defects. Isolated behavioral checks do
not establish that the following Battleground reports are resolved.

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
symptoms fixed in 0.1.86-local. The added spell IDs and priority changes are
source-confirmed; they still depend on the client exposing the corresponding
aura to an authorized selection path.

See [ARCHITECTURE.md](ARCHITECTURE.md) for the current implementation.
Class-colored unit-frame reports remain in the
[bjarkiUI issue list](https://github.com/bjoern-janson/bjarkiUI/blob/main/KNOWN_ISSUES.md).
