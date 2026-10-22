# Known issues and bugs

Historical status recorded 2026-10-08 for **bjarkiPortraits 0.1.80-local**. Current synchronized source is **0.1.149-foundation-v15-fixes-test** (2026-10-22); historical items below are not automatically closed by that update.

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
