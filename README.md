# bjarkiPortraits

Portrait aura prioritization for **WoW: Forever**.

Current checkpoint: **v0.1.56-local**.

bjarkiPortraits turns Blizzard unit portraits into one high-signal aura surface for
player, target, focus, target-of-target, and focus-target. The runtime combines
Blizzard-managed secure aura selection, readable Lua evidence when legally
available, and narrowly justified state/semantic witnesses when exact aura
identity is relation-gated.

## Current checkpoint highlights

- Numeric portrait timers show through **60 seconds**; sub-10-second timers can use decimals.
- Runtime priority low end is `Campfire Nearby 0 < Boosted Rest 1 < Small friendly harmful 2`.
- Recently Bandaged is a dedicated harmful lane at 229, immediately below Weakened Soul 230.
- First Aid/bandage channels are part of Food/Drink at 260.
- Shatter Curse is in Defensive at 290.
- Minor Troll's Blood Elixir is in Well Fed at 110.
- Ghost/death state is represented at Immunity priority 330 through `UnitIsGhost()` rather than relying only on relation-gated harmful aura identity.
- Exact Control excludes Stuns, so the dedicated Stun lane owns every stun ID.
- Utility/Welcoming Campfire uses one actual election surface.
- Pet classification prefers positive `UnitIsOtherPlayersPet` evidence.
- High-frequency unit events are scoped to owned unit tokens.
- Inaccessible/secret evidence remains **UNKNOWN**, never silently false.

## Files

- `Spells.lua` — canonical spell/effect taxonomy.
- `Core.lua` — accessibility, relation authority, frame discovery, timer formatting.
- `Priority.lua` — exact and semantic runtime lanes.
- `AuraEngine.lua` — secure/readable/state-witness arbitration and portrait rendering.
- `PetPortraits.lua` — Hunter/Warlock pet-family portrait foundations.
- `Commands.lua` — `/bp` test/debug/configuration.
- `Main.lua` — lifecycle and scoped events.
- `ARCHITECTURE.md` — detailed engineering model, failure history, NPC-aura plan, and anti-regression rules.
- `NEXT_CHAT.md` — concise continuation state.

## Architecture direction

The next large coverage project is **not** runtime spell-database scanning. It is
an offline/auditable mechanical-equivalence corpus that maps verified
player/NPC/Forever aura IDs into the existing conceptual families. Mechanical
equivalence and observability authority remain separate questions.

The next plausible performance refactor is also separate: consolidate the
current per-lane `CustomAuraContainer` topology into filter-string cohorts with
multiple AuraSlots, then snapshot readable filters once per host update.

See `ARCHITECTURE.md` before changing either area.
