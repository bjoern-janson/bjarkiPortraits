# bjarkiPortraits

A native-styled portrait-aura addon for **WoW: Forever**, displaying the highest-priority eligible, positively observed aura or state on Blizzard's portrait regions.

**Current synced source:** `0.1.178-bottom-harmful-consolidation-test` (2026-11-08). This is a test build; successful simulated Lua regressions do not certify live-client combat, aura secrecy, or visual geometry.

## Install

Install the **`bjarkiPortraits`** folder in your game's `Interface/AddOns/` directory, with the ten `.lua` modules and both `.toc` manifests directly inside the folder. Enable the addon and `/reload`. Blizzard's in-game unit-frame settings still control whether ToT/ToF and regular party frames are visible.

## Supported portraits

The **same one-aura priority engine** is used for **player, pet, target, focus, target-of-target, target-of-focus and regular party1–party4** (ten unit tokens). PetFrame retains its pet-family artwork as the baseline. Party portraits follow Blizzard's pooled frames and ignore Edit Mode placeholders; raid-style party/raid frames are not covered.

Native unit-frame chrome and spell icons remain the visual foundation. Player-race artwork is currently a **large-portrait fallback** when eligible; Skyborne face art is displayed only when a suitable atlas is available. Otherwise the addon leaves the native portrait visible.

## Current priority examples

- **Priority 0, absolute bottom:** Boosted Rest (1229451), Tricked or Treated (24755), and both harmful Tamed quest effects (19685/19686), in one `BoostedRest` aura lane.
- **Gathering 1:** Find Herbs, Find Minerals, Find Treasure. **Tracking 3:** sensing buffs, Sapta Sight, Hunting Kobolds. **Campfire Nearby 4** and **Violet Flames 5**.
- **Seal 210** includes Poised; **Offensive 280** includes Rushing Charge and Savagery; harmful **Control 310** includes Polymorph, while helpful **ControlHelpful 310** covers Frog Form.

See `Priority.lua` and `Spells.lua` for the complete, authoritative levels. Same-tier native order is reverse aura-instance ID; a refreshed buff does not always count as “last applied”. A 3,599-second native `SmallFriendlyHarmful` duration guard prevents Boosted Rest promotion, but also restricts other long/permanent generic harmful effects.

Use `/bp help` for commands, `/bp inspect <unit>` for eligible observed auras, `/bp layout <unit>` and `/bp pets debug pet` for presentation diagnostics. `/bp decimals` controls decimal countdowns strictly below ten seconds.

## Next update: secondary portrait (planned, not implemented)

**[Secondary portrait design and acceptance plan](docs/SECONDARY_PORTRAIT_PLAN.md)** records the agreed small Shaman Totem-style circle, second-highest distinct aura, and race-only badge fallback. It also documents the difficult **secure second-winner election** feasibility gate. No second circle or top-two election exists in 0.1.178; **PetFrame is excluded from the secondary circle for now**, but retains its full primary aura system.

## Documentation and tests

- [Architecture](ARCHITECTURE.md) — source ownership and chronological build changes, including v0.1.173–0.1.178 in section 35.
- [Known issues](KNOWN_ISSUES.md) — current live-verification boundaries and outstanding aura-order issues.
- [Package workflow](.github/workflows/package-addon.yml) — Lua 5.1/5.4 syntax checks, regression scripts, and an installable CI artifact.

This project uses event-driven/native aura systems and conservative evidence permissions, not an unrestricted Lua spell scan on every rendered frame.
