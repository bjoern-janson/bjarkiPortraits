# bjarkiPortraits

Native-styled priority aura portraits for **WoW: Forever**. A high-priority observed aura or state can replace the normal Blizzard portrait; a smaller circle may show the next distinct eligible effect. The addon respects the client's protected-aura boundaries and does not guess hidden spell IDs.

**0.1.250 low-overhead recovery build for WoW: Forever.** Fixed-position timers retain the existing fonts, and native secondary construction resumes incomplete button initialization before showing the finished tree. Landed school interrupts can supply a portrait and countdown, with Target and Focus each following their current recipient. Start with the [code map](docs/CODE_MAP.md) for event paths and the [timer lifecycle](docs/TIMER_LIFECYCLE.md) for clock ownership and recovery.

## Install

1. Download the `bjarkiPortraits` artifact from a successful [Package addon run on main](https://github.com/bjoern-janson/bjarkiPortraits/actions/workflows/package-addon.yml?query=branch%3Amain), or use a packaged release built from this branch.
2. Place the **`bjarkiPortraits` folder** directly inside `World of Warcraft/Interface/AddOns/`. Check that `Interface/AddOns/bjarkiPortraits/bjarkiPortraits.toc` exists alongside its Lua modules.
3. Enable the addon, then `/reload`. The existing Blizzard settings control whether regular party frames and ToT/ToF are visible.

There is **no setup command** for second portraits: they are enabled by default. Existing settings are saved in `BjarkiPortraitsDB`.

## Portrait behavior

- **Primary portraits:** Player, pet, Target, Focus, ToT, ToF and regular `party1`–`party4` (10 unit tokens) share the priority model. Without a selected aura/state, the normal Blizzard 3D portrait or class icon remains.
- **Secondary portraits:** Player, Target, Focus and regular party members can show a second distinct, eligible aura or state. The guarded public reader takes precedence when its complete election is proven. Player/Target/Focus also have a native ranked-second fallback when public ranking cannot be completed.
- **Fallback artwork:** Verified race icons are secondary-only for player characters. Confirmed Hunter/Warlock pets targeted on Target/Focus can use pet-family artwork underneath real second-aura art. Unverified races and NPCs are never assigned a guessed race tile.
- **No second circle:** Local PetFrame, ToT and ToF. Their **primary** portraits still work. Raid/compact raid frames and party-pet frames are not hosts.

### Interrupts on Target and Focus

A readable loss-of-control record can identify a landed Kick, Pummel or other school interrupt. When Target or Focus changes, the addon rechecks the recipient. Two reports for one effect can occupy one rank, leaving room for a different active lockout. The countdown can use a native duration object or corroborated public timing. In combat, the client may allow the native secondary icon to render while withholding its identity from Lua.

The remaining in-game checks include swapping Target and Focus during a lockout and watching a second effect take over when the first expires. [Known issues](KNOWN_ISSUES.md)

### Secondary layout

| Host | Center relative to main portrait | Cell | Rim | Artwork |
| --- | --- | ---: | ---: | ---: |
| Player | `TOPRIGHT (-10, +12)` | 50px | 41px | **30px** |
| Party 1–4 | `TOPRIGHT (-10, +12)` | 40px | 33px | 24px |
| Target, Focus | `TOPLEFT (+10, +12)` | 50px | 41px | **30px** |

The 30px full-size artwork matches a regular Blizzard buff icon; its Totem-style rim scales around the artwork rather than cropping it tightly. Version 0.1.223 additionally applies a slight 2/64 source-image inset to actual spell/form and confirmed secondary pet-family art to hide thin square icon edges. The local PetFrame retains its prior 3/64 crop; registered race atlases and race sprite-sheet tile coordinates are left untouched. `R.SecondaryCirclePlacement` and `R.SecondaryCircleGeometry` are the two layout authorities for readable icons, native second-aura clips and pet-family fallbacks. Native Blizzard spell artwork is retained. The masks and cooldowns follow the icon, not a larger invisible rectangle.

### Performance recovery

The 0.1.248 native secondary renderer can preallocate ten buttons in each of approximately 62 priority groups for Player, Target and Focus. Version **0.1.249** stopped attaching six extra continuously updating fixed-digit bindings and a hidden duration-bar bridge **to every one of those backing buttons**. Instead, their native cooldowns retain Blizzard's verified **90-second-capped formatter** and the same default buff-duration font. This avoids a potential **3,720 unnecessary glyph bindings per secondary host** without disabling any aura categories, removing native second portraits, or changing combat evidence.

The fixed-position digit presentation stays active on **main portraits** and publicly elected secondary auras. On native hidden-identity secondaries, native single-text digits may shift slightly; that's a deliberate performance tradeoff. No new commands or user settings required. The [recovery guide](docs/PERFORMANCE_RECOVERY.md) records the source path and verification limits. **Main remains unchanged at 0.1.248**; this build is on a separate branch.

### Countdown and priority examples

Portrait countdowns retain fixed-position digits in the existing font: tenths below ten seconds when enabled, truncated whole seconds **through 90 inclusive**, and no number strictly above 90 at native precision. Version 0.1.250 changes only the number visibility threshold; the lightweight native-secondary path retains the same cap. Native duration bindings drive the digits without Lua reading the current private countdown. If fixed cells cannot be used, the addon tries the same capped native formatter; if that cannot be installed, it hides the number while preserving the icon and swipe.

Version .248 previously restored the 60-second numeric display window, superseded by .250's 90-second limit while retaining fixed digits, font styling, native duration bindings and fallback safety. The actual 30-minute Draught of Water Breathing buff (`7178`) now shares Travel Utility 50 with Shaman Water Breathing (`131`); the unrelated daytime/nighttime quest buff Vigilant (`1326064`) enters Bottom Helpful 0. No other priority levels changed.

Version .246 spreads native secondary construction across deferred out-of-combat callbacks and avoids rewriting unchanged timer bindings during target-layout checks. A partially built secondary stays hidden until its full native group tree can be bound to the current recipient. Version .247 retains failed button initialization and already-created artwork, masks and clocks for a safe retry; completion requires every initializer to finish. These source repairs retain the timer work. Their effect on live responsiveness and rendering still needs confirmation. [Timer ownership and lifecycle](docs/TIMER_LIFECYCLE.md)

Numeric tiers indicate **portrait display priority**, not general spell strength. A few current classifications:

| Priority | Examples |
| ---: | --- |
| 330–332 | True immunities; Waiting to Resurrect |
| 320 / 310 / 300 | Stuns / Control / Roots |
| 280 | Offensive cooldowns |
| **253** | Combat-flow penalties, including Ice Claw (3130) and Thunder Clap |
| **185** | Demoralizing Shout/Roar/Screech; Decayed Strength (6951), Curse of Weakness and **Daunting Growl (3146)** |
| **120** | Thorns, Fire Shield, Reflection Field and **Static Electricity (1294477)** from Gahz'rilla Fang |
| **90** | Class buffs, major world buffs, Camp Benefits and verified mounted auras |
| **50** | Travel Utility, including both 10-minute Shaman Water Breathing (`131`) and 30-minute Draught of Water Breathing (`7178`) |
| **81** | Consumables, Well Fed and approved minor effects |
| **0** | Informational bottom auras, including Well-Rested (`429959`), nighttime **Vigilant (`1326064`)**, and harmful Boosted Rest (`1229451`), in separate polarity lanes |

For **all 62 exact/semantic lanes**, see [Current priority reference](docs/PRIORITIES.md); `Priority.lua` and `Spells.lua` remain the actual runtime source of truth. Static Electricity was added to the existing Thorns tier without changing numeric priorities.

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

- [Code map](docs/CODE_MAP.md) — event paths, state owners and tests for specific symptoms.
- [Architecture](ARCHITECTURE.md) — current module loading, main/secondary election, guards, native pooling and lifecycle.
- [Timer lifecycle](docs/TIMER_LIFECYCLE.md) — exact-font cells, native duration bridge, deferred groups, initialization receipts and Target/Focus interrupt clocks.
- [Known issues / verification status](KNOWN_ISSUES.md) — current open questions versus source-level repairs.
- [Priority reference](docs/PRIORITIES.md) — numeric lane table from `Priority.lua`.
- [Testing and debugging](docs/TESTING.md) — automated checks, in-game acceptance cases and release checks.
- [Historical 0.1.247 verification record](docs/BUILD_VERIFICATION.md) — pinned source and package identity for the previous version. See [current CI runs](https://github.com/bjoern-janson/bjarkiPortraits/actions/workflows/package-addon.yml?query=branch%3Amain) for 0.1.248.
- [Secondary portrait design history](docs/SECONDARY_PORTRAIT_PLAN.md) — chronological experiments, acceptance goals and source evidence.
- [Historical README / release notes](docs/README_RELEASE_HISTORY.md), [legacy architecture](docs/ARCHITECTURE_HISTORY.md) and [earlier issue log](docs/KNOWN_ISSUES_HISTORY.md) — preserved provenance; **not current configuration guidance**.

The current verification set contains **35 Lua regression scripts** and **15 runtime modules**. CI syntax-checks and runs the scripts under **Lua 5.1 and 5.4**, then packages the runtime modules and both manifests into one installable folder. Passing these checks verifies modeled source behavior; protected execution, final typography and frame time still require an in-game observation. [Verification commands](docs/TESTING.md) · [CI workflow](.github/workflows/package-addon.yml).
