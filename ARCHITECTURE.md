# Architecture — bjarkiPortraits 0.1.220

**Current technical reference** for branch `feat/secondary-portrait-p1`, source version `0.1.220-daunting-growl-demoralizing-test` as of 2026-11-09. The original 0.1.178-and-earlier architecture chronology is preserved in [docs/ARCHITECTURE_HISTORY.md](docs/ARCHITECTURE_HISTORY.md); its old "current" statements and older tier levels must not be used as the current implementation.

## Module loading

Both `bjarkiPortraits.toc` and `bjarkiPortraits_Camelot.toc` load **13 runtime modules**, in this order:

1. `Spells.lua` — reviewed applied aura ID groupings. No guessing from spell names or icons.
2. `Core.lua` — runtime/defaults, guarded unit access, race lookup, portrait geometry and countdown formatting.
3. `StanceState.lua` — positively readable Warrior stances and supported form state.
4. `SharedEvidence.lua` — bounded positive-observation bus; never an oracle for hidden spell identity.
5. `EvidencePublisher.lua` — guarded event publication and derived-unit snapshots.
6. `Priority.lua` — immutable `R.TIERS`, exact/semantic lanes and derived spell-to-tier indexes.
7. `SecondaryPortrait.lua` — optional readable second-election, secondary race/art badge, conservative combat retention.
8. `NativeSecondProbe.lua` — secure native second-slot fallback for Player/Target/Focus.
9. `AuraEngine.lua` — host lifecycle, native primary containers, readable fallback, frame restoration.
10. `PetPortraits.lua` — confirmed pet-family and other observed pet identity artwork.
11. `PetSecondary.lua` — targeted pet-family secondary fallback, gated by native aura presence.
12. `Commands.lua` — user toggles and read-only diagnostics.
13. `Main.lua` — event routing, coalesced delayed refresh, native frame hooks.

**Load-order rule:** `Priority.lua` must load before `SecondaryPortrait.lua`. A real 0.1.188–0.1.189 regression built an empty secondary ranking table before the tiers existed; 0.1.190 fixed the TOCs and added lazy rank initialization. Do not regress it.

## Host model and native ownership

`R.TRACKED_UNITS`: `player`, `pet`, `target`, `focus`, `targettarget`, `focustarget`, `party1`–`party4`.

- Every tracked host uses the **same primary** `R.TIERS` selection policy.
- The addon overlays the native portrait only when an eligible effect/state is selected. Native Blizzard health/power/name/chrome and the configured base 3D/class portrait remain intact.
- The local `PetFrame` gets a full primary aura host with pet-family foundation artwork; it does **not** get a second circle.
- ToT/ToF receive primary auras only. Party support is for Blizzard's regular pooled `PartyFrame` member frames; no arbitrary raid/compact frames are hooked.
- Native parent/bounds are recorded, reparented safely where required, and restored at teardown. Target/focus changes, party pool reuse and disabling never authorize rendering on a prior unit.

## Priority and evidence model

`Spells.lua` defines exact source groups. `Priority.lua` creates **62 display lanes** as `exact` (reviewed spell-ID candidate sets) or `semantic` (Blizzard filters). Higher numeric level generally wins; code-table order is **not** numeric priority order. Equal-level but independent lanes may be ambiguous for a public election; don't invent tie resolution.

`R.TIER_BY_KEY` and `R.HELPFUL_TIER_BY_SPELL` are derived from the current tier table, with an overlap audit. The source category does not itself create an aura occurrence. A caster action, tooltip, name or spell-family guess is **not** evidence of a live applied aura.

- Native secure containers select actual eligible auras without revealing private aura identities to public Lua.
- Readable helpers can elect an exact current aura only when relation, occurrence, filter membership and relevant ordering are positively readable.
- Application-time recency is intentionally used for the three lanes `BaselineClass`, `Healing` and `StatusEffects` **only when sufficient readable start evidence exists**. Other native tie handling uses reverse aura-instance IDs and is not a general "last refreshed" order.
- Low-priority ID exclusions reduce promotion into broad semantic fallbacks. `SmallFriendlyHarmful` has `maxDuration=3599`, a deliberate protection against elevated hour-long Boosted Rest that also excludes some other long/permanent generic harmful auras.
- See [docs/PRIORITIES.md](docs/PRIORITIES.md) for the entire numeric table; `Priority.lua` and `Spells.lua` are authoritative if documentation ever drifts.

Recent classification checkpoint: `Demoralizing` **185** includes Daunting Growl `3146`, Decayed Strength `6951`, Curse of Weakness, Demo Shout/Roar/Screech. `StatusEffects` **253** includes Ice Claw `3130` and attack/cast/healing disruption; `BaselineClass` **90** includes class/world/Camp Benefits/mount auras; `Consumables` **81** includes Well Fed; `BottomHelpful` **0** includes Cozy Sleeping Bag Well-Rested `429959`.

## Secondary portrait pipeline (experimental)

The **main** presenter remains authoritative; secondary candidates must not weaken first-place selection.

1. `SecondaryPortrait.lua` attempts a **bounded complete** public `HELPFUL|INCLUDE_NAME_PLATE_ONLY` and `HARMFUL|INCLUDE_NAME_PLATE_ONLY` election (up to 48 items per polarity, with bounded native filter checks). A proven distinct runner-up draws on the secondary badge with its real current icon and countdown.
2. Source-backed static witnesses (for example Ghost or a readable stance/form) are ranked without inventing aura instances or cooldowns. A verified current timed positive may be retained through restricted reads only within the existing invalidation/expiry/identity rules.
3. When a public second cannot be proved, a **native** `CustomAuraContainer` for Player/Target/Focus sorts groups by `R.TIERS`. Its first cell is physically clipped and the second cell can render in the small circle. The addon neither reads private native button data nor claims a global secure API that returns the runner-up. A public `not-two-presentable` is **not proof of native absence**, so it is not a native-fallback veto.
4. If no actual runner-up is drawn, player-character units may show a verified race badge. For positively identified NPCs, no race is fabricated. `PetSecondary.lua` can draw observed Hunter/Warlock pet-family artwork on Target/Focus underneath real secondary art, only where native HELPFUL/HARMFUL presence groups draw it.

The native runner-up path is **not implemented for party1–4**: they use readable election plus verified race fallback. The local PetFrame, ToT and ToF do not have second circles.

### Native initialization, pooling and retarget safety

- New native second containers must call `SetUnit(validString)` and `SetEnabled(true)` after registering their groups. A fresh `CustomAuraContainer` does not start enabled. The same rule applies to pet-family presence containers.
- `SetUnit(nil)` is invalid in Forever's native aura API. On release, call `SetEnabled(false)` and only pool after successfully disabling. Re-enable to force a fresh parse even when the next owner uses the same `target` token.
- Target/Focus source swaps carry a positive current GUID when readable. Forced retarget refreshes call native `UpdateAllAuras` out of combat; if the old identity cannot safely be replaced or refreshed, hide instead of showing an old NPC's timed aura.
- Do not read, iterate or compare secure hidden aura contents to decide whether to show the clip. Native children are clipped by geometry; public readability is not secretly recovered by a screenshot or native button inspection.

## Exact secondary geometry

Source: `Core.SecondaryCirclePlacement(unit)` and `Core.SecondaryCircleGeometry(unit)`.

| Host | Secondary center anchor | Cell / rim / masked art | Totem atlas optical inset |
| --- | --- | --- | --- |
| Player | `TOPRIGHT (-10,+12)` | **50 / 41 / 30px** | `(+1.35,-2)` |
| Party1–4 | `TOPRIGHT (-10,+12)` | **40 / 33 / 24px** | `(+0.75,-1.5)` |
| Target and Focus | `TOPLEFT (+10,+12)` | **50 / 41 / 30px** | `(+1.35,-2)` |

All three secondary renderers share that policy. Icon artwork stays centered in the cell, behind `CircleMask` and the native `UI-HUD-UnitFrame-TotemFrame` bezel. The native clip width/first-cell offset are derived from the same 50px cell. The larger border avoids Target's combo-point column while preserving 30px (regular buff-size) full art. Blizzard's default spell artwork is preferred.

## Countdown and layout

`Core.GetCountdownFormatter` gives one decimal strictly below 10 seconds, truncated whole seconds from 10 to 60, and empty text after 60.000001 when available. `ApplyCountdownFormat` retains native fallback behavior if the formatter API is unavailable. `/bp decimals` and `/bp swipe` toggle the existing behavior.

`Core.ApplySecondaryCountdownFont` applies Blizzard's `GameFontNormalSmall` to the addon-owned secondary cooldown label, centers it on the icon and paints it white. This is separate from the larger per-unit primary countdown alignment in `AuraEngine.lua`. The pet-family fallback has no synthetic countdown. Avoid polling or arithmetic on secret countdown values.

## Events, security, diagnostics

`Main.lua` listens to login/world/combat-exit, target/focus, unit-aura/form and pet/group events. Work is scoped to tracked units and coalesced for delayed availability. Structural frame changes are deferred during combat. `SharedEvidence.lua` and `EvidencePublisher.lua` provide guarded positive observations to other suite consumers; they are **not** hidden identity or DR prediction sources.

`R.CanAccess`, `R.SafeBool`, `R.SafeString` and `R.ReadAuraField` distinguish **unknown/restricted** from **readable absent**. A failed restricted read must never be treated as a negative aura witness. There is no per-frame unrestricted Lua aura scan.

Read-only diagnostics include `/bp secondary debug <unit>`, `/bp layout <unit>`, `/bp geometry <unit>`, `/bp inspect <unit>`, `/bp stance <unit>` and `/bp audit`. Capture them **before** a manual refresh when debugging a disappearing icon.

## Maintenance and validation

Changes to classifications require a reviewed **applied aura ID**, correct polarity and one exact tier owner; update `Spells.lua` and the appropriate test without shifting unrelated priorities. A second-portrait layout change must keep `SecondaryPortrait`, `NativeSecondProbe` and `PetSecondary` synchronized through `Core`. Native changes must retain safe setup, pooling, GUID and combat contracts.

The [package workflow](.github/workflows/package-addon.yml) compiles code and executes all committed behavior scripts for Lua 5.1 and 5.4. It does **not** certify actual combat secrecy, native unit-frame layering or user-specific pixel scaling. See [docs/TESTING.md](docs/TESTING.md) and [KNOWN_ISSUES.md](KNOWN_ISSUES.md).
