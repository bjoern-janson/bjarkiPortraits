# Known issues and bugs

**Class aura repair (2026-11-01):** `0.1.160-class-aura-fixes-test` adds 131 reviewed applied aura/rank IDs across all nine classes. Distract is harmful status, Intimidation's pet preparation is helpful offense (separate from its target stun), and Riposte joins the existing disarm/control category. Mind Vision ranks 1/2 use a harmful tracking filter at the existing tracking priority of 3, with guarded readable recovery. All other existing exact ownership and all existing numeric tier levels are preserved. Source and native-filter regressions pass on Lua 5.1/5.4, including both helpful/harmful polarity and mixed cast/application cases. Primary spell definitions were checked against current Forever database pages; for any listed ID, the source lookup is `https://www.wowhead.com/forever/spell=ID`.

**Current verification boundary:** earlier live observations remain valid, including WotF removing control without an applied buff. The new exact entries and Mind Vision filter/recovery need current-build in-game visibility checks; missing prior entries did not prove native fallback invisibility. Unresolved applied IDs (including Combustion), uncertain older Druid Lacerate variants, and cast-only/hidden records were not inserted. Warrior stance state and the strict-below-ten-seconds portrait timer retain their existing behavior.

**Ten-second decimals (2026-10-31):** `0.1.159-ten-second-decimals-test` uses one decimal strictly below ten seconds with `/bp decimals` on, whole seconds at ten and above, and a matching compatibility threshold. Decimals off and the existing long-duration hiding rule are unchanged. This supersedes the five-second policy below; live-client verification remains pending.

**Warrior stance experiment (2026-10-31):** `0.1.158-stance-test` supports Battle (2457), Defensive (71), and Berserker (2458) through the existing static form-state presenter. The player's own stance uses the active shapeshift-form API, including positively identified self aliases. Other Warriors require a single readable, current exact stance aura; absent or restricted evidence leaves the stance unknown. Hidden stance auras may never be exposed by Forever for other players. On a non-Warrior, use `/bp stance target` while a targeted Warrior switches stances to inspect the available evidence. `UNIT_FORM_CHANGED` identifies a unit, not its new stance. Live cross-faction/combat behavior remains unverified. See architecture section 33.

**Audit repairs (2026-10-31):** `0.1.157-audit-fixes-test` addresses the reproduced Roots/Control fallback omission, Quitter promotion, first-match Waiting-to-Resurrect election, failed-access-check behavior and failed native portrait restoration. New behavioral regressions exercise those source paths. These repairs do not close historical live Battleground/rendering reports without client verification. WotF removes CC on use and has no applied buff, so it remains excluded. See architecture section 32.

**Correction (2026-10-27):** `0.1.154-priority-scope-correction-test` restores Roots 300, Slows 278 and Dazed 279. Their decrease in v0.1.153 was not requested. WotF (7744) is removed from all portrait aura categories: the user's direct Forever test observed no WotF buff, and a cast-only effect cannot be displayed as an invented immunity aura. Tests lock all retained pre-overhaul priority numbers except the two explicitly requested changes (Utility and OffensiveHarmful). No other spell classification from the consolidation is changed.

**Priority consolidation (2026-10-27):** `0.1.153-priority-consolidation-test` merges redundant tiers (Divine Protection, defensive racials, Weakened Soul/bandaging, shields, flags and informational debuffs), reclassifies reflection/Free Action/Voice/Grounding/Blink and adds a dedicated applied-stun and interrupt/silence readable election. The existing Charge, Intercept, Cheap Shot and Pounce stun IDs were already listed; missing live display may still reflect protected/absent aura evidence. The distinct Pounce bleed remains DoTs. Unverified shape-only Chilled/Frost Armor approximations are removed; true unreadable auras may now fall back more conservatively. Combat/taint and target/focus cross-faction visibility require Forever testing.

**Five-second decimals restored (2026-10-26):** `0.1.152-five-second-decimals-test` restores portrait aura countdown decimals strictly below five seconds with `/bp decimals` on; the whole-second rule starts at five and the native compatibility threshold matches. The older three-second policy is historical; live-client verification is still pending.

**Low-priority aura reintroduction (2026-10-26):** `0.1.151-low-priority-tracking-status-test` restores Find Herbs/Minerals, Tricked or Treated, Boosted Rest and all other tracking/sensing buffs as three visible exact tiers immediately above race portraits. Their semantic fallback exclusions remain, to prevent promotion above combat effects. Self/friendly informational debuffs also receive a guarded readable helper; actual Forever display in all client secrecy states still needs validation.

**v16 suite update (2026-10-22):** this addon receives release-version metadata only. Its behavior is byte-identical to v15 apart from that version string. The three timing repairs are in bjarkiCC Model/Observer. The full v16 suite passes 49 regression scripts and 28 runtime syntax checks on both Lua 5.1 and Lua 5.4; live-client findings below retain their existing status. The behavior described in architecture section 25 remains applicable.

Historical status recorded 2026-10-08 for **bjarkiPortraits 0.1.80-local**. Current candidate source is **0.1.160-class-aura-fixes-test** (2026-11-01); historical items below are not automatically closed by that update.

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
