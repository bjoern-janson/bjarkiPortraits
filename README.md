# bjarkiPortraits

Portrait aura prioritization for **WoW: Forever**.

Current live-tested baseline: **v0.1.17-clean**.

The addon turns Blizzard unit portraits into a single high-signal aura surface for:

- player
- target
- focus
- target-of-target
- focus-target

It combines Blizzard's secure `AuraContainer` system with readable Lua fallbacks when aura identity/timing is directly accessible.

## Current scale

- 41 spell/effect categories
- 814 category memberships
- 778 unique spell IDs
- 44 priority lanes

## Files

- `Spells.lua` — spell/effect taxonomy.
- `Core.lua` — secret-value safety, relation checks, frame discovery, settings.
- `Priority.lua` — exact and semantic priority lanes.
- `AuraEngine.lua` — secure containers, readable fallbacks, portrait/timer rendering.
- `PetPortraits.lua` — Hunter/Warlock pet-foundation artwork only.
- `Commands.lua` — `/bp` test/debug/configuration.
- `Main.lua` — event lifecycle.
- `ARCHITECTURE.md` — detailed model of Forever aura secrecy, secure filtering, recency, and rendering.

## Live-tested v0.1.17 facts

- ToT/FoT use the same lower-layer portrait primitive as the large frames and are visually working.
- The earlier disappearance of ToT/FoT was traced to `showTargetOfTarget = 0`, not to the current visual composition.
- Scarlet Initiate Frost Armor was observed as **12544** out of combat.
- Its Chilled proc was observed as **6136**.
- Both IDs are readable out of combat but not `NeverSecret`; exact identity becomes unavailable in combat.
- The working in-combat solution is therefore a secure **non-identity metadata signature**.
- Chilled and Frost Armor are now both confirmed rendering in combat on that NPC.

## Commands

- `/bp test` — synthetic portrait rendering test.
- `/bp debug` — current host/relation/readability/winner diagnostics.
- `/bp help` — all commands.

`README.txt` preserves the detailed development/version history.
