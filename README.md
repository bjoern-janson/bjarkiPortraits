# bjarkiPortraits

Portrait aura prioritization for **WoW: Forever**.

Current source: **v0.1.32-clean**. v0.1.24 has live passes for Welcoming Campfire, the Frost Armor/Chilled NPC mechanism, hostile-player aura selection so far, and a dense Booty Bay check without the earlier reported lag. v0.1.25 is a data-only priority refinement for Shaman party totem auras.

The addon turns Blizzard unit portraits into a single high-signal aura surface for:

- player
- target
- focus
- target-of-target
- focus-target

It combines Blizzard's secure `AuraContainer` system with readable Lua fallbacks when aura identity/timing is directly accessible.

## Current scale

- 43 spell/effect categories
- 821 category memberships
- 787 unique spell IDs
- 46 priority lanes

## Files

- `Spells.lua` — spell/effect taxonomy.
- `Core.lua` — secret-value safety, relation checks, frame discovery, settings.
- `Priority.lua` — exact and semantic priority lanes.
- `AuraEngine.lua` — secure containers, readable fallbacks, portrait/timer rendering.
- `PetPortraits.lua` — Hunter/Warlock pet-foundation artwork only.
- `Commands.lua` — `/bp` test/debug/configuration.
- `Main.lua` — event lifecycle.
- `ARCHITECTURE.md` — detailed model of Forever aura secrecy, secure filtering, recency, and rendering.

## Live-tested facts

- ToT/FoT use the same lower-layer portrait primitive as the large frames and are visually working.
- The earlier disappearance of ToT/FoT was traced to `showTargetOfTarget = 0`, not to the current visual composition.
- Scarlet Initiate Frost Armor was observed as **12544** out of combat.
- Its Chilled proc was observed as **6136**.
- Both IDs are readable out of combat but not `NeverSecret`; exact identity becomes unavailable in combat.
- The working in-combat solution is therefore a secure **non-identity metadata signature**.
- Chilled and Frost Armor are now both confirmed rendering in combat on that NPC.
- Welcoming Campfire is confirmed working through the repaired v0.1.23 path.
- Hostile-player portrait aura selection has been correct across the current live sample.
- After v0.1.24 scoped high-frequency unit events to owned tokens, a dense Booty Bay test no longer exhibited the reported lag.

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
- v0.1.24 restores the generic secure harmful surface for ToT/FoT whenever exact harmful identity is not authorized, makes player identity explicitly tri-state so UNKNOWN is not treated as NPC, separates Lua-visible hostile-stream completeness from secure-plane authority, and unit-scopes high-frequency aura/relation/target events.
- v0.1.25 moves Stoneskin out of BaselineClass and adds the Healing Stream aura family; both now share the PaladinAura priority band as persistent party-support effects.


### v0.1.26
- Adds Righteous Fury (25780) as its own exact helpful lane at priority 59, immediately below the PaladinAura party-support band at 60.


### v0.1.27
- Readable hostile texture failure now hides the readable overlay instead of leaving the previous winner's icon visible.
- Bounded 80-entry readable scans no longer claim completeness unless they actually observe the aura-stream terminator.
- Unreadable/failed NeverSecret lookups fail closed for the current check but are no longer cached as permanent false results.
- No hostileReadable policy, semantic signature, priority, geometry, or event behavior changes.


### v0.1.28
- Numeric portrait countdown text now remains hidden above 45 seconds instead of above 60 seconds.
- Decimal behavior below 10 seconds is unchanged.
- No aura admission, priority, geometry, or event behavior changes.


### v0.1.29
- BaselineClass recency now prefers C_UnitAuras.GetAuraDuration(...):GetStartTime() as the direct application/refresh-time witness.
- expirationTime-duration remains a readable fallback.
- auraInstanceID is no longer treated as evidence that one BaselineClass aura is newer than another; it is used only as a deterministic tie-break when readable start times are equal.
- If any competing BaselineClass aura lacks readable start time, the readable override abstains and leaves the secure lane underneath.
- /bp debug now reports baselineTimingSource and baselineAppliedAt.


### v0.1.30
- Adds Forever fishing Well Fed aura 1249521 to the existing WellFed tier at priority 110.
- Removes the previous policy exclusion for profession-oriented visible Well Fed variants.
- No priority, geometry, rendering, semantic fallback, or event behavior changes.


### v0.1.31
- Adds a narrow readable exact fallback for Boosted Rest (1229451) on player/target/focus when friendly/self relation gating makes the secure exact HARMFUL filter unavailable.
- The fallback retains Boosted Rest's real priority 20 and does not add a broad harmful lane to large frames.
- /bp debug adds boostedRestReadable and boostedRestActive.


### v0.1.32
- Moves SmallFriendlyHarmful from priority 189 to priority 1.
- The ToT/FoT generic secure HARMFUL surface is now a true last-resort fallback: any known tracked aura outranks it.
- This preserves generic harmful visibility when no tracked state is available while preventing the small-frame fallback from overriding what target/focus would otherwise select.
