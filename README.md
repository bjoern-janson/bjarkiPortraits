# bjarkiPortraits

A native-styled portrait-aura addon for **WoW: Forever**, displaying the highest-priority eligible, positively observed aura or state on Blizzard's portrait regions.

**Experimental branch:** `0.1.183-target-evidence-test` (2026-11-08), built on 0.1.178. This is a **readable-aura test build**, not a guaranteed all-unit/all-combat two-winner implementation. Live client artwork, layering, native filter support and secrecy transitions need verification.

## Install

Install the **`bjarkiPortraits`** folder in your game's `Interface/AddOns/` directory, with the ten `.lua` modules and both `.toc` manifests directly inside the folder. Enable the addon and `/reload`. Blizzard's in-game unit-frame settings still control whether ToT/ToF and regular party frames are visible.

## Supported portraits

The **same one-aura priority engine** is used for **player, pet, target, focus, target-of-target, target-of-focus and regular party1–party4** (ten unit tokens). PetFrame retains its pet-family artwork as the baseline. Party portraits follow Blizzard's pooled frames and ignore Edit Mode placeholders; raid-style party/raid frames are not covered.

Native unit-frame chrome and spell icons remain the visual foundation. **The main portrait now falls back to Blizzard’s own class icon or 3D model**, according to the game setting. Verified player-race artwork appears in a **small Totem-style secondary circle** on Player, Target, Focus and regular party frames, mirrored toward the health bars and drawn **above** native frame artwork. **ToT, ToF and PetFrame have no secondary circle**; their main portrait aura systems remain unchanged. Where a complete public aura scan and native filter probes are readable, the circle can instead present the second-ranked **distinct** active aura with a native countdown. Unknown, partial, restricted, or indeterminate reads fall back to race/hidden. Skyborne still requires a verified face atlas. PetFrame retains one full primary aura system without a secondary circle.

## Current priority examples

- **Priority 0, absolute bottom:** Boosted Rest (1229451), Tricked or Treated (24755), and both harmful Tamed quest effects (19685/19686), in one `BoostedRest` aura lane.
- **Gathering 1:** Find Herbs, Find Minerals, Find Treasure. **Tracking 3:** sensing buffs, Sapta Sight, Hunting Kobolds. **Campfire Nearby 4** and **Violet Flames 5**.
- **Seal 210** includes Poised; **Offensive 280** includes Rushing Charge and Savagery; harmful **Control 310** includes Polymorph, while helpful **ControlHelpful 310** covers Frog Form.

See `Priority.lua` and `Spells.lua` for the complete, authoritative levels. Same-tier native order is reverse aura-instance ID; a refreshed buff does not always count as “last applied”. A 3,599-second native `SmallFriendlyHarmful` duration guard prevents Boosted Rest promotion, but also restricts other long/permanent generic harmful effects.

Use `/bp help` for commands, `/bp inspect <unit>` for eligible observed auras, `/bp layout <unit>` and `/bp pets debug pet` for presentation diagnostics. The `/bp secondary on|off` command controls the badge without changing the main portrait. `/bp layout player` reports `secondSpell`, `secondTier`, and `secondReason` for debugging fallback; v0.1.183 also reports the displayed hostile-main spell, tier, aura-instance identity and whether its helpful list completed. This helps distinguish blocked target reads from mismatched first-place evidence. `/bp test` still previews a **synthetic** icon for geometry checks. `/bp decimals` controls decimal countdowns strictly below ten seconds.

## Secondary aura prototype — bounded readable path

**[Design and acceptance plan](docs/SECONDARY_PORTRAIT_PLAN.md)** records the full objective and native API limitations. Version 0.1.180 adds a *conservative* public aura election, independent of the unchanged secure main portrait: complete helpful/harmful indexed lists (up to 48 entries each), verified occurrence IDs, native per-tier filter checks, and bounded probe work (192 per refresh). It understands same-tier native ID order, the three application-time tiers, exact/semantic priorities, and refuses ambiguous equal-level lanes or unavailable timing. It now runs on positively readable **friendly units** and on **targeted hostile units only when their complete public aura evidence and the independently displayed first-place portrait agree**. An independently proven stance/form may also be first when its rank exceeds every readable aura. The client can still withhold hostile aura data, so this does not guarantee a second icon in PvP or restricted combat. For known exact auras, their membership in a completed compatible native polarity scan can prove native eligibility without the extra `IsAuraFilteredOutByInstanceID` lookup; nameplate-only mismatches still require negative checks. Unclassified/semantic aura eligibility still requires the native filter oracle. The 0.1.182 fix preserves an explicitly readable **false** hostile relation as friendly, instead of treating it as unknown. It falls back to race when any required evidence is absent. **Universal combat/hostile coverage is still not guaranteed; no secure global second-winner API has been discovered.** The synthetic `/bp test` remains distinct from live evidence.

## Documentation and tests

- [Architecture](ARCHITECTURE.md) — source ownership and chronological build changes, including v0.1.173–0.1.178 in section 35.
- [Known issues](KNOWN_ISSUES.md) — current live-verification boundaries and outstanding aura-order issues.
- [Package workflow](.github/workflows/package-addon.yml) — Lua 5.1/5.4 syntax checks, regression scripts, and an installable CI artifact.

This project uses event-driven/native aura systems and conservative evidence permissions, not an unrestricted Lua spell scan on every rendered frame.
