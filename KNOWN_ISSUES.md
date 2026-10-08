# Known issues and bugs

Status recorded 2026-10-08 for **bjarkiPortraits 0.1.80-local**.

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
