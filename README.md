# bjarkiPortraits

Native-styled priority aura portraits for **WoW: Forever**. A high-priority observed aura or state can replace the normal Blizzard portrait; a smaller circle may show the next distinct eligible effect. The addon respects the client's protected-aura boundaries and does not guess hidden spell IDs.

**Development baseline:** `0.1.220-daunting-growl-demoralizing-test` (2026-11-09), branch [`feat/secondary-portrait-p1`](https://github.com/bjoern-janson/bjarkiPortraits/tree/feat/secondary-portrait-p1). **`main` remains at 0.1.178**; the current secondary-portrait implementation is on the development branch, not `main`.

## Install

1. Download the `bjarkiPortraits` artifact from a successful [development-branch GitHub Actions run](https://github.com/bjoern-janson/bjarkiPortraits/actions/workflows/package-addon.yml), or use a packaged release built from this branch.
2. Place the **`bjarkiPortraits` folder** directly inside `World of Warcraft/Interface/AddOns/`. The thirteen `.lua` files and both `.toc` manifests must be **directly inside** that folder—not inside another `bjarkiPortraits` folder.
3. Enable the addon, then `/reload`. The existing Blizzard settings control whether regular party frames and ToT/ToF are visible.

There is **no setup command** for second portraits: they are enabled by default. Existing settings are saved in `BjarkiPortraitsDB`.

## Current behavior (0.1.220)

- **Primary portraits:** Player, pet, Target, Focus, ToT, ToF and regular `party1`–`party4` (10 unit tokens) share the priority model. Without a selected aura/state, the normal Blizzard 3D portrait or class icon remains.
- **Secondary portraits:** Player, Target, Focus and regular party members can show a second distinct, eligible aura or state. The guarded public reader takes precedence when its complete election is proven. Player/Target/Focus also have a native ranked-second fallback when public ranking cannot be completed.
- **Fallback artwork:** Verified race icons are secondary-only for player characters. Confirmed Hunter/Warlock pets targeted on Target/Focus can use pet-family artwork underneath real second-aura art. Unverified races and NPCs are never assigned a guessed race tile.
- **No second circle:** Local PetFrame, ToT and ToF. Their **primary** portraits still work. Raid/compact raid frames and party-pet frames are not hosts.

The secondary system is **experimental** under restricted combat reads: a visible aura does not guarantee that the addon can independently identify or prove its rank. Read [Known issues](KNOWN_ISSUES.md) before treating a race fallback as a priority bug.

### Secondary layout

| Host | Center relative to main portrait | Cell | Rim | Artwork |
| --- | --- | ---: | ---: | ---: |
| Player | `TOPRIGHT (-10, +12)` | 50px | 41px | **30px** |
| Party 1–4 | `TOPRIGHT (-10, +12)` | 40px | 33px | 24px |
| Target, Focus | `TOPLEFT (+10, +12)` | 50px | 41px | **30px** |

The 30px full-size artwork matches a regular Blizzard buff icon; its Totem-style rim scales around the artwork rather than cropping it tightly. `Core.SecondaryCirclePlacement` and `Core.SecondaryCircleGeometry` are the two layout authorities for readable icons, native second-aura clips and pet-family fallbacks. Native Blizzard spell artwork is retained. The masks and cooldowns follow the icon, not a larger invisible rectangle.

### Countdown and priority examples

Primary timers retain their per-frame calibration. Secondary timer text uses Blizzard's `GameFontNormalSmall`, centered and white. `/bp decimals` switches one decimal **strictly below 10 seconds**; at 10–60 seconds the formatter uses whole seconds, and above 60 it hides the text when the native formatter is available.

Numeric tiers indicate **portrait display priority**, not general spell strength. A few current classifications:

| Priority | Examples |
| ---: | --- |
| 330–332 | True immunities; Waiting to Resurrect |
| 320 / 310 / 300 | Stuns / Control / Roots |
| 280 | Offensive cooldowns |
| **253** | Combat-flow penalties, including Ice Claw (3130) and Thunder Clap |
| **185** | Demoralizing Shout/Roar/Screech; Decayed Strength (6951), Curse of Weakness and **Daunting Growl (3146)** |
| **90** | Class buffs, major world buffs, Camp Benefits and verified mounted auras |
| **81** | Consumables, Well Fed and approved minor effects |
| **0** | Informational bottom auras, including Well-Rested (429959) and harmful Boosted Rest (1229451), in separate polarity lanes |

For **all 62 exact/semantic lanes**, see [Current priority reference](docs/PRIORITIES.md); `Priority.lua` and `Spells.lua` remain the actual runtime source of truth. No numeric priority changes were made by this documentation pass.

## Commands

`/bp` or `/bp help` shows the complete in-game command set. Common commands:

| Command | Purpose |
| --- | --- |
| `/bp on`, `/bp off` | Enable/disable the addon |
| `/bp player`, `/bp target`, `/bp focus`, `/bp pet`, `/bp party1`–`party4`, `/bp tot`, `/bp fot` | Toggle an individual primary host |
| `/bp secondary on` / `off` | Toggle small secondary circles |
| `/bp decimals`, `/bp swipe` | Timer decimal behavior and swipe |
| `/bp pets status`, `/bp pets debug target` | Pet-family presentation and diagnostics |
| `/bp secondary debug target` | Read-only secondary election/fallback reason; also accepts player, focus, party1–4 |
| `/bp inspect target` | Bounded, public-only aura identities and tier availability |
| `/bp layout target`, `/bp geometry target` | Read-only host layout diagnostics |
| `/bp stance target`, `/bp audit` | State and source/tier auditing |
| `/bp test` | Synthetic icon preview for presentation checks—not a real aura |
| `/bp reset` | Reset saved options (use intentionally) |

For a regression, run the read-only debug command **before** manually refreshing or retargeting, then capture the relevant buff/debuff row and both portraits.

## Source and documentation

- [Architecture](ARCHITECTURE.md) — current module loading, main/secondary election, guards, native pooling and lifecycle.
- [Known issues / verification status](KNOWN_ISSUES.md) — current open questions versus source-level repairs.
- [Priority reference](docs/PRIORITIES.md) — complete numeric lane table generated from 0.1.220's `Priority.lua`.
- [Testing and debugging](docs/TESTING.md) — automated checks, in-game acceptance cases and release checks.
- [Secondary portrait design history](docs/SECONDARY_PORTRAIT_PLAN.md) — chronological experiments, acceptance goals and source evidence.
- [Historical README / release notes](docs/README_RELEASE_HISTORY.md), [legacy architecture](docs/ARCHITECTURE_HISTORY.md) and [earlier issue log](docs/KNOWN_ISSUES_HISTORY.md) — preserved provenance; **not current configuration guidance**.

CI compiles the addon and executes its Lua regression scripts under **Lua 5.1 and 5.4**, then packages the 13 Lua files and two manifests into one installable folder. Passing CI verifies the modeled source behavior, **not** every in-game protected-aura or visual case. [CI workflow](.github/workflows/package-addon.yml).
