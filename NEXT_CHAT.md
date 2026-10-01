# Next-chat handoff

## Current repository checkpoint

- Repository: `bjoern-janson/bjarkiPortraits`
- Current source: **v0.1.56-local**
- Companion repository: `bjoern-janson/bjarkiUI`
- Companion source at this sync: **v0.2.45-local**

Continue from the current secure/readable/state-witness engine. Do not reconstruct
older PortraitTimersForever architecture.

## Current invariants

- Inaccessible or secret values are UNKNOWN, not false/absent.
- One conceptual priority should map to one actual election surface whenever possible.
- Exact runtime lane IDs should be disjoint unless overlap is deliberate.
- Helpful/harmful exact identity is relation-authorized, not universally readable.
- `unitAuraUpdateInfo.isFullUpdate` must not be read.
- Structural rebuilds remain combat-safe.
- High-frequency unit events stay scoped to owned unit tokens.
- No addon-owned cosmetic `OnUpdate` loop.
- Timer text cutoff is 60 seconds.
- Ghost uses `UnitIsGhost()` at Immunity priority 330; the harmful exact Ghost family remains backup data.

## Current low-end priority changes

```text
0   Campfire Nearby
1   Boosted Rest
2   Small friendly harmful fallback
10  Plainsrunning / Elemental Blessing
...
228 Weakened Soul fallback
229 Recently Bandaged
230 Weakened Soul
...
330 harmful/helpful Immunity
```

## Recent additions since the previous GitHub checkpoint

- First Aid/bandage channels in Food/Drink.
- Recently Bandaged exact + readable coverage.
- Shatter Curse in Defensive.
- Minor Troll's Blood Elixir in Well Fed.
- broader Frostbolt/Chilled Forever/NPC IDs.
- 60-second timer text threshold.
- Ghost/death state witness and death lifecycle refresh.
- architecture documentation expanded to include the container-cohort refactor,
  readable-snapshot refactor, partial exact-authority model, and NPC
  mechanical-equivalence corpus plan.

## Next major project

Build the NPC aura equivalence corpus offline:

1. canonical tracked family
2. candidate Forever/NPC IDs
3. verify applied aura ID and mechanics
4. alias verified equivalents into `Spells.lua`
5. keep runtime as set membership
6. separately respect relation/secrecy authority

Do not use localized name equality as mechanical proof.

See `ARCHITECTURE.md` for the full model and anti-regression checklist.

## Research-program integration handoff

A separate plan now lives in `RESEARCH_PROGRAM_PLAN.md`.

The wider ~65-repository research program is currently being re-parsed with
Astra. Preserve each completed deep-parse report under
`research/deep-parse/<repository>.md` and wait for Astra's full-program
digestion before choosing which research concepts, if any, are promoted into
addon engineering.

Hard constraint: **functionally pristine addon first**. Research richness should
remain offline unless it eliminates a demonstrated failure mode, improves
correctness, simplifies runtime, or enables a genuinely useful behavior.

Read **all of `RESEARCH_PROGRAM_PLAN.md`**, especially Section 9. That section
contains the full motivation for the unusual research → WoW connection: the
"Rolex of WoW addons" quality target, the desired outward chain from competitive
artifact → engineering curiosity → design principles → broader research →
AI-safety questions, the reason the abrupt topic switch is intentional, and the
requirement to reject superficial analogies rather than force a synthesis.

The addon must stand on its own even if an external engineer rejects every
AI-safety generalization. The strongest integrations are principles that remain
useful under that condition.
