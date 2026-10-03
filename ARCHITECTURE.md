# bjarkiPortraits architecture

This document describes the current implementation of **bjarkiPortraits 0.1.62-local** as it exists in the repository. It is a maintenance reference for the addon and does not claim undocumented guarantees about the WoW: Forever client.

The runtime is split into seven Lua modules:

- `Spells.lua` — spell-ID category tables.
- `Core.lua` — settings, unit/portrait lookup, value-access helpers, relation checks, timer formatting.
- `Priority.lua` — display lanes and priority levels.
- `AuraEngine.lua` — portrait hosts, secure aura containers, readable fallbacks, rendering, lifecycle.
- `PetPortraits.lua` — pet-family artwork under portrait aura layers.
- `Commands.lua` — `/bp` commands and debug output.
- `Main.lua` — event registration and refresh routing.

`ARCHITECTURE.md` is not loaded by the game.

## 1. What the addon displays

The addon uses the native portrait area of five unit frames:

- `player`
- `target`
- `focus`
- `targettarget`
- `focustarget`

The intent is to show one high-priority aura/state over each portrait while keeping Blizzard's surrounding frame art and unit data.

The local PetFrame and observed pet portraits can also receive pet-family foundation artwork. That artwork is separate from aura selection.

## 2. Spell data and display priorities

`Spells.lua` contains plain spell-ID membership tables. It does not perform runtime discovery.

`Priority.lua` converts those categories into ordered display lanes.

Two lane types are used:

- **exact lanes** — include explicit spell IDs;
- **semantic lanes** — use Blizzard aura-filter metadata such as crowd-control, important, defensive, duration, or dispel type.

Categories that are meant to compete at the same priority are unioned before the lane is built. This matters because a shared lane gives Blizzard one actual candidate election rather than two independent frames that happen to have the same numeric level.

Examples in the current build include:

- Plainsrunning + Elemental Blessing;
- Paladin aura + Warlock armor;
- baseline class buffs + camp benefits;
- Slows + Chilled exact IDs;
- Innervate + Druid Enrage;
- Utility + Welcoming Campfire;
- Faerie Fire/Curse-of-Weakness-style low debuffs + taunts.

Current nearby harmful priorities include:

- Demoralizing Shout/Roar: 185
- DoTs: 190
- low debuffs / taunts / Faerie Fire: 200
- Slows: 220
- Roots: 300
- Control: 310
- Stuns: 320
- Immunities: 330

The numeric level is used as a portrait display priority, not as a general statement about spell strength.

## 3. Secure aura containers

Each portrait host creates Blizzard `CustomAuraContainer` instances for the configured lanes.

Exact lanes supply explicit spell-ID inclusion sets. Semantic lanes supply broader Blizzard candidate filters.

Within a lane, aura ordering uses:

- `AuraInstanceIDOnly`
- reverse sort direction

This lets the native aura container choose among candidates on that lane.

The addon does not run a general Lua loop every frame to update cooldowns. Cooldown progression and most aura-slot work are left to Blizzard widgets/containers.

## 4. Exact-filter availability

Forever does not expose every aura identity in every relation in the same way.

`Core.lua` therefore separates:

- whether a value can be read;
- whether the unit relation is readable;
- whether an exact helpful/harmful spell-ID filter is allowed for that relation;
- whether a spell family is explicitly known as NeverSecret.

`ExactFilterAllowed()` currently permits exact filtering through several paths, including:

- helpful auras on the player;
- helpful auras on positively identified controlled/group units;
- readable assist relation;
- selected lanes whose entire configured spell-ID family is known NeverSecret.

If the required relation value is unreadable, that path does not grant exact filtering.

## 5. Readable fallback paths

Some states use Lua-readable aura/state information when an exact secure lane is not available or when a more specific local election is useful.

Current examples include:

- baseline class-buff recency;
- hostile helpful aura handling;
- Slows on self/friendly units;
- Resurrection Sickness;
- Recently Bandaged;
- Boosted Rest;
- Welcoming Campfire;
- Ghost through `UnitIsGhost`.

These are separate paths rather than one universal scanner because they need different evidence and fallback behavior.

Most indexed scans are bounded and stop when the exposed aura stream terminates.

## 6. Portrait hosts and layering

A host records the native portrait, its original parent/points, the addon presentation layer, aura containers, cooldowns, and readable fallback frames.

For the larger player/target/focus frames, the addon creates a lower presentation layer and reparents the native portrait while preserving its geometry. Native frame chrome remains above the addon artwork.

The small ToT/FoT frames use separate geometry offsets:

- ToT icon: +2 X; timer centered with -1 Y
- FoT icon: +1 X; timer +1 X / -1 Y

The small-frame timer font is reduced by two points.

On destruction, containers are disabled/hidden, owned overlays are hidden, and the native portrait parent/points are restored when possible.

## 7. Lifecycle and combat

Structural frame changes are avoided while in combat.

If a rebuild or destruction is requested during combat, the addon records pending work and finishes it after `PLAYER_REGEN_ENABLED`.

The global `enabled` setting is checked at host-creation and refresh boundaries. When the addon is off, later target/focus/unit events should not recreate portrait hosts.

Pet artwork also checks the global enabled state.

This keeps `/bp off` from immediately restoring presentation through a later event.

## 8. Pet portrait foundations

`PetPortraits.lua` does not own aura containers.

It identifies local or observed Hunter/Warlock pets through the unit APIs and creature-family information available on the client, then chooses a family/summon texture when possible.

Observed pet textures live on the host's portrait layer. The local PetFrame uses a separate texture placed under the native border/chrome.

Pet art can be toggled independently with `/bp pets`, but the global addon-off state also hides it.

## 9. Timer presentation

Cooldowns use Blizzard's `CooldownFrameTemplate`.

Default timer behavior is:

- below 10 seconds: one decimal;
- 10 through 60 seconds: whole seconds;
- above 60 seconds: no numeric timer.

`/bp decimals` toggles the sub-10-second decimal behavior.

`/bp swipe` toggles the cooldown swipe.

The addon configures Blizzard's formatter rather than running its own per-frame countdown calculation.

## 10. Commands

Current commands include:

- `/bp on`
- `/bp off`
- `/bp player`
- `/bp target`
- `/bp focus`
- `/bp tot`
- `/bp fot`
- `/bp swipe`
- `/bp decimals`
- `/bp pets`
- `/bp test`
- `/bp debug`
- `/bp reset`

Test mode is primarily a presentation/geometry check.

Debug output exposes selected host state, relation/readability flags, and readable-election information.

## 11. Event model

`Main.lua` routes broad lifecycle events such as login/world entry, target/focus changes, death/ghost transitions, pet changes, and leaving combat.

High-frequency unit events are scoped to the five tracked tokens with `RegisterUnitEvent`.

`UNIT_TARGET` is registered only for target/focus because those are the outer units that can rebind ToT/FoT.

Ordinary `UNIT_AURA` refreshes the affected host without always forcing every secure container to rebuild; relation/referent changes can request a stronger refresh.

There is no addon-owned `OnUpdate` polling loop.

## 12. Protected and secret values

Forever can return secret or inaccessible values from aura/unit APIs.

The current implementation uses helpers such as:

- `IsSecret`
- `CanAccess`
- `SafeBool`
- `SafeString`
- `ReadAuraField`

before many comparisons or field reads.

Where exact identity is unavailable, the addon may keep a broader secure lane, use a narrower readable fallback, or show nothing, depending on the path.

These rules reflect the current code and observed client constraints; they should be rechecked when Blizzard changes the underlying APIs.

## 13. Practical maintenance rules

The current implementation is easiest to keep stable when:

- spell data stays in `Spells.lua`;
- display priority/election stays in `Priority.lua`;
- categories that truly share a priority also share one actual lane;
- new spell IDs are added by applied aura ID rather than display name alone;
- structural frame work remains out of combat;
- off-state checks remain present at every host/pet creation boundary;
- secret/inaccessible values are checked before comparison or arithmetic;
- docs and other non-runtime files remain outside the `.toc` load list.


## 14. Cleanup notes

The current build keeps the existing spell taxonomy, priority elections, access checks, lifecycle guards, and timer policy. A small cleanup pass removes unused wrappers and duplicate readable-frame setup, and avoids reading container enabled state during ordinary refreshes when that value is not used. These changes do not alter the configured spell ownership or lane order.
