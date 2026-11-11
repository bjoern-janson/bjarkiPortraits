# Known issues & verification status

**Recovery branch source: 0.1.252; the separate main branch remains at 0.1.248.** The verification set contains 35 regression scripts run under Lua 5.1 and 5.4; the package contains 15 runtime modules and both manifests. These checks exercise source behavior and distribution contents. They do not certify all live client behavior or establish that the addon is free of bugs. [Verification commands](docs/TESTING.md) · [Timer ownership and lifecycle](docs/TIMER_LIFECYCLE.md)

**0.1.252 combat event reduction (source-tested, live retest pending):** Player/Target `UNIT_FLAGS` now use non-forcing immediate and queued checks. Combat exit reconciles eligibility without unconditional native `UpdateAllAuras` on every unchanged aura container. Native state transitions, binding changes, explicit faction changes and failed-write recovery remain supported. The production-event regression is `tests/combat-transition-fastpath.lua`. This is not a live FPS claim.

**0.1.250 90-second countdown (source-tested, live retest pending):** The original 60-second inclusive cap was extended to 90 seconds inclusive across fixed digit cells, capped native fallback and the lightweight preallocated secondary timers. The formatter tests cover 60, 61, 89.99, 90, the next representable instant above 90, and long durations under both float models. No new timer states, font or priority changes.

**0.1.249 allocation reduction (source-tested, live FPS unmeasured):** Blizzard's custom native aura groups preallocate ten buttons per group. The newer portrait timer renderer previously attached six additional duration-text bindings and a hidden duration bar to every native-secondary backing button. The recovery build deliberately leaves these buttons on the native capped formatter, skipping extra binding allocation and repeat glyph retries. Tests cover default lightweight creation, reuse and formatter fallback. This changes potential timer allocations but does **not** prove actual measured FPS improvements, nor eliminate the original preallocation of native aura buttons. Check for any visual change in native-secondary number alignment.

**0.1.248 Water Breathing / Vigilant, live verification pending:** The displayed Water Breathing aura had **16 minutes remaining**, consistent with the 30-minute Draught of Water Breathing applied buff `7178`, not the 10-minute Shaman spell `131`. The addon previously ranked only `131` as TravelUtility 50; `7178` is now included and tested beneath Water Shield `408510`. Vigilant `1326064` has been added to BottomHelpful 0. Actual Target/Focus secondary selection can still be restricted by client aura-access rules, so a persistent race fallback should be captured via `/bp secondary debug target` and `/bp inspect target`.

**0.1.248 countdown policy (historical; superseded by 0.1.250):** The numeric display cap was restored to **60 seconds inclusive**, with exact binary64 and binary32 thresholds verified in the existing timer tests. Fixed-cell layout, fonts, native clock ownership and long-duration hide behavior are otherwise unchanged. Exact pixel display still requires an in-game check.

**0.1.247 initializer recovery, live verification pending:** Fixed portrait timers and deferred secondary construction remain enabled. A failed native button initializer is now retained as unfinished work; the secondary tree must not become ready until initialization succeeds. Completed allocations and mask/clock-registration receipts are retained so retry reuses the original icon, mask, border and cooldown. Regression coverage models Blizzard catching callback errors while registering the group, safe retry, combat interruption, pooled reuse and recipient changes. The audited failure was injected; it was not established as a cause of the reported live hitch.

**.246 forward timer repair, live verification pending:** Fixed portrait timers remain enabled. Native secondary groups preallocate ten buttons each; 62 groups therefore create 620 cooldowns and 3,720 fixed-digit bindings. Construction is now budgeted across deferred out-of-combat callbacks, with a fresh recipient refresh before showing the completed tree. Target-layout checks no longer force unchanged timer bindings to be rewritten. Tests model the actual ten-button native allocation and lifecycle interruptions; they do not measure live frame time. The .245 rollback was rejected and is not the current approach.

The 0.1.239 offline fixtures cover fractional lockout deadlines, duplicate reports, changing Target and Focus, and an unreadable aura list after an occurrence is removed. Live checks still needed include recipient swaps during an active Kick, overlapping lockouts and expiry in combat. [Code and tests](docs/CODE_MAP.md)

Portrait timer motion was still observed in .242. Version .243 replaces inline spacer text with separate fixed-position digit regions in the existing font, using the native aura duration object via `SetDurationBar` and the addon-owned bar's `GetTimerDuration`. Version .243 used tenths below ten, whole seconds through thirty, then hidden; **0.1.248 supersedes that limit with sixty seconds** while keeping the same rendering design. If fixed cells fail, only a verified capped formatter can show ordinary numbers. Offline checks cover the bridge and rendering policy; exact client typography, protected execution and the native getter retaining a live duration reference still require an in-game retest.

Combat-exit stutter was reported with .243 installed; its start date is uncertain. Version .244 removes a redundant full timer-presentation pass. A production-path model with one Target host (62 native and 27 helper clocks) observed 9,701 presentation setters before the change and zero for unchanged hidden clocks afterward. The model isolates presentation and does not measure the retained aura reconciliation or live frame time. In-game hitch improvement remains unverified.

The dated observations below come from earlier builds. [Earlier issue history](docs/KNOWN_ISSUES_HISTORY.md)

## Open or requires further in-game verification

**0.1.224 fear-expiry secondary disappearance (source-level partial repair, live retest pending):** A screenshot of a nearly defeated Coyote shows multiple ordinary debuff icons and a timed primary portrait but no small secondary, possibly after Fear expired. Individual applied aura IDs and the secondary diagnostic were not captured, so the exact reason cannot be established. The 0.1.222 native fallback introduced a confirmed code path that hid the whole hostile clip when the optional low-priority `HostileHelpful` group needed enabling in combat. The 0.1.224 fix leaves that group disabled while permitting established native harmful/exact groups to render, without doing a protected native write. A target GUID change or the unsafe reverse hostile→friendly transition still hides the clip. Retest Fear→remaining debuffs with `/bp secondary debug target` before switching targets.


**0.1.222 combat-entry double aura (source-level repair, live retest pending):** In 0.1.221 a PlayerFrame screenshot showed identical purple-paw artwork on both portraits after combat entry. Its aura spell/instance ID is not established by the picture. Review found the independent native HostileHelpful group was registered even on Player, allowing overlap with a higher Important/BigDef/ExternalDef semantic lane. Native group activation and filtering are now disjoint where permitted, while public ranking rejects duplicate spell identities. Passing Lua tests verify this safeguard, not the exact screenshot's underlying spell IDs.


| Area | Current boundary / test still useful |
| --- | --- |
| **Secure runner-up ordering** | The native clipped-second-cell design is experimental. It does not expose the secure global first/second identity to Lua, and mixed semantic lanes, equal-ranked different owners, hidden auras and combat restrictions can still differ from a public model. Test two different exact tiers, same-tier auras and hostile combat in game. |
| **Hostile NPC / player secondaries** | Source tests exercise harmful NPC pairs, friendly player buffs, secure fallback and newly enabled native containers. The old Wendigo missing-badge and race-instead-of-runner-up paths were repaired in 0.1.217, but the exact same cases have not been exhaustively certified for all secrecy states in the client. |
| **Combat target swaps and pooled frames** | GUID transitions, native `UpdateAllAuras`, and `SetEnabled(false/true)` pooling are regression-tested, including same-token `target` swaps (0.1.215–0.1.216). Retest repeated fresh untagged NPCs and Target↔Focus changes, especially when combat prevents rebinding; an icon may intentionally disappear until a safe refresh. |
| **Party/raid boundaries** | Regular pooled `party1`–`party4` have primary auras and readable secondary/race badges. No native ranked-second ribbon for party; raid, raid-style compact frames and party pets remain out of scope. Verify joins/leaves, Edit Mode placeholders and party changes during combat. |
| **Unknown race / pet evidence** | Skyborne SD face art still requires a usable validated atlas; a blank low-resolution icon is deliberately rejected. Confirmed Hunter/Warlock pet-family art is available only with positive identity/presence; unknown NPC pets and wild beasts do not receive invented artwork. |
| **Visual calibration** | Full secondary `50/41/30` and compact party `40/33/24` cell/rim/art sizes remain unchanged. Version 0.1.223 uses a modest 2/64 source-UV crop to remove straight square-icon edges from some primary/secondary auras; local PetFrame retains 3/64 and race atlases remain unmodified. Validate visually across different icon textures and UI scales. |
| **Same-tier refresh order** | Most native lanes use reverse aura-instance ID, which is not necessarily the last *refreshed* aura. `BaselineClass`, `Healing` and `StatusEffects` use readable application-time elections only when complete timing evidence exists. |
| **Long-duration generic harmful effects** | `SmallFriendlyHarmful` is capped at 3,599 seconds to avoid erroneously promoting Boosted Rest, which can exclude other unclassified long/permanent auras. Explicit exact tiers are unaffected. |

No item above warrants guessing restricted spell IDs, reading native secure button contents, or altering user-approved priority levels to make an icon appear.

## Source-repaired regressions (retain live checks where relevant)

| Version | Issue and source-level correction |
| --- | --- |
| **0.1.190** | Empty secondary rank cache caused by module load order; both manifests now load `Priority.lua` before `SecondaryPortrait.lua`. |
| **0.1.191–0.1.204** | Ghost/form ranking, guarded combat positive, NPC mixed harmful lists, native secure second-cell and player/Target/Focus alias coverage. The design remains experimental rather than universally verified. |
| **0.1.213–0.1.214** | Target badge moved clear of combo points; shared layout policy established. Later 0.1.217 mirroring **supersedes** the original Player/party side. |
| **0.1.215–0.1.216** | Same-token target change, GUID safety and invalid `SetUnit(nil)` pool resets; use disabled native containers and rebuild on reuse. |
| **0.1.217** | Newly created native containers now `SetEnabled(true)`, and public `not-two-presentable` no longer incorrectly vetoes a native runner-up. |
| **0.1.218–0.1.219** | Overshrunk 22px artwork corrected: 30px **art** with a 41px circular rim in a 50px normal cell; 24/33/40 compact. |
| **0.1.220** | Daunting Growl (3146) classified as flat Strength/Agility reduction in `Demoralizing` **185**, not `StatusEffects` **253**. |

These are **implemented and covered by source-level tests** (where applicable), not assertions that every prior screenshot has been replicated and cleared on the live server.

## Not bugs by design

- ToT, ToF and local PetFrame have **no secondary circle** (but their primary portrait auras remain supported).
- A single aura, an NPC without a valid race, or an unavailable/secret candidate does not authorize fabricating a second icon.
- A combat-protected target swap may hide a stale native second instead of presenting the previous target's art.
- A tooltip or a nameplate icon alone does not authorize a guessed applied aura ID.
- The main no-aura baseline remains Blizzard's chosen class icon / 3D portrait, **not** an addon-forced race icon.

## Capture useful diagnostics

Use `/bp secondary debug player`, `/bp secondary debug target` or `/bp secondary debug focus` **before** changing targets or reloading. Also capture `/bp layout target` and, when the public identity is readable, `/bp inspect target`. Screenshots should show the target name, both portrait circles and visible native buff/debuff row.

`/bp audit` checks duplicate exact-tier ownership and guarded host diagnostics. `/bp geometry target` checks frame bounds without changing layout. The complete reproducible matrix is in [docs/TESTING.md](docs/TESTING.md).

The absence of an icon is not, on its own, evidence that a private aura was absent. Read the election reason and the client's access boundary first.
