# Known issues and validation

Status recorded 2026-10-08 for **bjarkiPortraits 0.1.81-local**.

This build repairs confirmed source-level routing, readable election,
presentation ownership and lifecycle defects. Isolated behavioral checks do
not establish that the following Battleground reports are resolved.

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

## White totem portrait

An enemy Healing Stream Totem was reported with a white portrait and no visible
aura. This build does not establish the cause or verify that symptom fixed.
The native portrait/unit presentation and aura-exposure paths need observation
in the client.

## ToT/FoT border bleed

Aura artwork on target-of-target/focus-of-target has been reported peeking past
the small portrait border. The existing native masks, offsets, frame hierarchy
and chrome are preserved. Static inspection cannot establish successful mask
attachment or correct clipping; no geometry repair is claimed.

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
symptoms fixed in 0.1.81-local.

See [ARCHITECTURE.md](ARCHITECTURE.md) for the current implementation.
Class-colored unit-frame reports remain in the
[bjarkiUI issue list](https://github.com/bjoern-janson/bjarkiUI/blob/main/KNOWN_ISSUES.md).
