# bjarkiPortraits

A lightweight portrait-aura addon for **WoW: Forever**. Displays the highest eligible observed aura or state on Blizzard's existing portrait area for **player, target, focus, target-of-target and target-of-focus**. Pet-family and race portraits provide foundations when appropriate; native spell artwork is retained.

**Current synced source:** `0.1.172-frog-form-control-test` (2026-11-07). This is a **test build**: regression checks do not substitute for live WoW verification.

## Install

Copy the ten `.lua` modules and both `.toc` manifests from this repository into `Interface/AddOns/bjarkiPortraits/` (adjust the game folder to your installation). Do not nest an extra `bjarkiPortraits` directory. Enable the addon and use `/reload`. ToT/ToF visibility is controlled separately by the game's unit-frame settings.

The modules load in the order listed by `bjarkiPortraits.toc`; `bjarkiPortraits_Camelot.toc` has the same load order and version.

## Behavior

- One priority-selected portrait effect per unit where accessible, using Blizzard aura containers and guarded readable evidence. Inaccessible auras are **unknown**, not license to guess.
- Informational effects stay below combat effects: Gathering **1** (Herbs, Minerals, Treasure, Tamed Strigid Screecher), Tracking **3** (Sapta Sight, Hunting Kobolds, sensing), Campfire Nearby / Boosted Rest **4**, Violet Flames **5**.
- Selected combat lanes: Seal **210** (including Poised), Offensive **280** (including Rushing Charge and Savagery), harmful Control **310** (including Polymorph) and helpful Control **310** (Frog Form). See `Priority.lua` for the actual full list.
- `/bp decimals` toggles decimal countdowns strictly below ten seconds. Native Blizzard icons and unit-frame art are preserved.
- Same-tier Tracking uses native instance-ID order, **not reliably last refreshed**. The broad harmful fallback's 3,599-second cap excludes Boosted Rest promotion and other long/permanent generic harmful effects.

## Commands and diagnosis

`/bp help` lists toggles and tools. Useful probes are `/bp inspect player`, `/bp inspect target`, `/bp audit`, `/bp stance target`, `/bp pets debug` and `/bp decimals`. The inspect command reports only positively readable aura IDs; it does not force secret data into a category.

## Source and verification

`Spells.lua` owns applied spell-ID categories; `Priority.lua` defines native exact/semantic lanes; `AuraEngine.lua` handles presentation. Source changes from the November launch are summarized in [ARCHITECTURE.md](ARCHITECTURE.md#34-launch-follow-up-01164-through-01172-2026-11-05-to-2026-11-07). Historical reports and unresolved client conditions are in [KNOWN_ISSUES.md](KNOWN_ISSUES.md).

The [package workflow](.github/workflows/package-addon.yml) checks Lua syntax and behavioral regressions on Lua **5.1** and **5.4**, including `tests/low-priority.lua` and `tests/launch-auras.lua`. Test mocks verify the source paths and filter policy; protected-value behavior, rendering, and PvP combat transitions require a live-client check.
