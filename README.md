# bjarkiPortraits

Portrait aura prioritization for **WoW: Forever**.

Current source: **v0.1.23-clean**. Last live-tested baseline before this surgical hardening pass: **v0.1.22-clean**.

The addon turns Blizzard unit portraits into a single high-signal aura surface for:

- player
- target
- focus
- target-of-target
- focus-target

It combines Blizzard's secure `AuraContainer` system with readable Lua fallbacks when aura identity/timing is directly accessible.

## Current scale

- 42 spell/effect categories
- 814 category memberships
- 780 unique spell IDs
- 45 priority lanes

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


### Changes after v0.1.17

- v0.1.18 fixes local PetFrame family-icon layering.
- v0.1.19 restores a secure harmful fallback for friendly ToT/FoT.
- v0.1.20 uses direct player spell lookup for Welcoming Campfire.
- v0.1.21 moves Elemental Blessing into the Plainsrunning priority lane.
- v0.1.22 adds Walk on Air to Utility.
- v0.1.23 repairs Welcoming Campfire fallback coverage, gates semantic approximations behind stronger evidence, moves Rapid Regeneration to Utility, canonicalizes Forbearance/Resurrection Sickness/Honorless Target data, removes redundant secure-container full refreshes from the UNIT_AURA hot path, and makes structural teardown combat-safe.
