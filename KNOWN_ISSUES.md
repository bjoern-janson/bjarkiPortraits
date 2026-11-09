# Known issues & verification status

**Scope:** development branch `feat/secondary-portrait-p1`, source `0.1.221-static-electricity-thorns-test`, 2026-11-09. This page is the **current** tracker. Earlier issues and intermediate fixes (including superseded 0.1.213 geometry) are retained in [docs/KNOWN_ISSUES_HISTORY.md](docs/KNOWN_ISSUES_HISTORY.md), not treated as open just because an old heading remains there.

## Open or requires further in-game verification

| Area | Current boundary / test still useful |
| --- | --- |
| **Secure runner-up ordering** | The native clipped-second-cell design is experimental. It does not expose the secure global first/second identity to Lua, and mixed semantic lanes, equal-ranked different owners, hidden auras and combat restrictions can still differ from a public model. Test two different exact tiers, same-tier auras and hostile combat in game. |
| **Hostile NPC / player secondaries** | Source tests exercise harmful NPC pairs, friendly player buffs, secure fallback and newly enabled native containers. The old Wendigo missing-badge and race-instead-of-runner-up paths were repaired in 0.1.217, but the exact same cases have not been exhaustively certified for all secrecy states in the client. |
| **Combat target swaps and pooled frames** | GUID transitions, native `UpdateAllAuras`, and `SetEnabled(false/true)` pooling are regression-tested, including same-token `target` swaps (0.1.215–0.1.216). Retest repeated fresh untagged NPCs and Target↔Focus changes, especially when combat prevents rebinding; an icon may intentionally disappear until a safe refresh. |
| **Party/raid boundaries** | Regular pooled `party1`–`party4` have primary auras and readable secondary/race badges. No native ranked-second ribbon for party; raid, raid-style compact frames and party pets remain out of scope. Verify joins/leaves, Edit Mode placeholders and party changes during combat. |
| **Unknown race / pet evidence** | Skyborne SD face art still requires a usable validated atlas; a blank low-resolution icon is deliberately rejected. Confirmed Hunter/Warlock pet-family art is available only with positive identity/presence; unknown NPC pets and wild beasts do not receive invented artwork. |
| **Visual calibration** | Full secondary `50/41/30` and compact party `40/33/24` cells/rims/art were last refined in 0.1.219; the user reported that this direction looks good. Pixel-perfect mask, atlas and timer alignment at every UI scale remains unverified. |
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
