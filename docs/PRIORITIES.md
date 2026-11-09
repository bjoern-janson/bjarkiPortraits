# Priority lanes — 0.1.222

**Generated from the exact 62 `R.TIERS` declarations** in [`Priority.lua`](../Priority.lua) on `feat/secondary-portrait-p1`, version `0.1.222-native-runner-up-duplicate-suppression-test` (2026-11-09). This is a readable **numeric snapshot**; the Lua files, not this Markdown, control the addon. It is sorted by numeric level descending, not by source-file declaration order.

- **Exact IDs:** membership is derived from `Spells.lua` applied-aura groupings or unions. The existence of an ID in a group does not prove that aura is currently applied to a unit.
- **Semantic:** candidate filtering uses Blizzard-native aura metadata and can be restricted in combat. The table does not claim arbitrary secure aura identity visibility.
- **Equal levels:** positive and negative polarity lanes may coexist; independent same-level lanes do not always have a provable public tie-break. The native selection and guarded readable recency rules apply.
- **A state/race baseline is not a numbered aura tier.** A positively observed stance/form can be ranked as a separate static presentation candidate (normally just below the SelfState lane), and Ghost can be a static immunity-relative presentation. These are not synthetic applied-aura records.

## Complete lane table

| Level | Runtime lane | Polarity | Selection |
| ---: | --- | --- | --- |
| 332 | `WaitingToResurrect` | Helpful | Exact IDs |
| 330 | `ImmunityHarmful` | Harmful | Exact IDs |
| 330 | `Immunity` | Helpful | Exact IDs |
| 320 | `Stun` | Harmful | Exact IDs |
| 320 | `HelpfulSelfStun` | Helpful | Exact IDs |
| 316 | `SpellImmunity` | Helpful | Exact IDs |
| 315 | `PhysicalImmunity` | Helpful | Exact IDs |
| 310 | `Control` | Harmful | Exact IDs |
| 310 | `ControlHelpful` | Helpful | Exact IDs |
| 309 | `CrowdControl` | Harmful | Semantic |
| 306 | `InterruptSilence` | Harmful | Exact IDs |
| 305 | `RootImmunity` | Helpful | Exact IDs |
| 300 | `Roots` | Harmful | Exact IDs |
| 290 | `Defensive` | Helpful | Exact IDs |
| 289 | `BigDef` | Helpful | Semantic |
| 288 | `ExternalDef` | Helpful | Semantic |
| 280 | `Offensive` | Helpful | Exact IDs |
| 280 | `OffensiveHarmful` | Harmful | Exact IDs |
| 279 | `Dazed` | Harmful | Exact IDs |
| 278 | `Slows` | Harmful | Exact IDs |
| 261 | `Innervate` | Helpful | Exact IDs |
| 260 | `FoodDrink` | Helpful | Exact IDs |
| 259 | `MinorRegen` | Helpful | Exact IDs |
| 257 | `HonorlessTarget` | Helpful | Exact IDs |
| 256 | `PowerWordShield` | Helpful | Exact IDs |
| 255 | `ResurrectionSickness` | Harmful | Exact IDs |
| 253 | `StatusEffects` | Harmful | Exact IDs |
| 251 | `Healing` | Helpful | Exact IDs |
| 240 | `Forbearance` | Harmful | Exact IDs |
| 238 | `PriorityDebuff` | Harmful | Semantic |
| 230 | `Wounds` | Harmful | Exact IDs |
| 225 | `Utility` | Helpful | Exact IDs |
| 210 | `Seal` | Helpful | Exact IDs |
| 190 | `DoTs` | Harmful | Exact IDs |
| 189 | `Consecration` | Harmful | Exact IDs |
| 185 | `Demoralizing` | Harmful | Exact IDs |
| 180 | `HuntersMark` | Harmful | Exact IDs |
| 175 | `SmallFriendlyHarmful` | Harmful | Semantic |
| 170 | `LoneWolf` | Helpful | Exact IDs |
| 160 | `Mobility` | Helpful | Exact IDs |
| 150 | `SelfState` | Helpful | Exact IDs |
| 120 | `Thorns` | Helpful | Exact IDs |
| 90 | `BaselineClass` | Helpful | Exact IDs |
| 90 | `BaselineClassHarmful` | Harmful | Exact IDs |
| 85 | `Important` | Helpful | Semantic |
| 81 | `Consumables` | Helpful | Exact IDs |
| 80 | `Scrolls` | Helpful | Exact IDs |
| 70 | `BloodPact` | Helpful | Exact IDs |
| 60 | `PaladinAura` | Helpful | Exact IDs |
| 59 | `PassiveDebuff` | Harmful | Exact IDs |
| 50 | `TravelUtility` | Helpful | Exact IDs |
| 10 | `Plainsrunning` | Helpful | Exact IDs |
| 9 | `PassiveSpeed` | Helpful | Exact IDs |
| 5 | `VioletFlames` | Helpful | Exact IDs |
| 5 | `HostileHelpful` | Helpful | Semantic |
| 4 | `CampfireNearby` | Helpful | Exact IDs |
| 4 | `CampfireNearbyHarmful` | Harmful | Exact IDs |
| 3 | `Tracking` | Helpful | Exact IDs |
| 3 | `TrackingHarmful` | Harmful | Exact IDs |
| 1 | `Gathering` | Helpful | Exact IDs |
| 0 | `BoostedRest` | Harmful | Exact IDs |
| 0 | `BottomHelpful` | Helpful | Exact IDs |

## Recent classification decisions

| Applied spell / category | Actual lane | Level | Why |
| --- | --- | ---: | --- |
| Static Electricity `1294477` from Gahz'rilla Fang | `Thorns` | **120** | User-requested visual priority for the stacking +2% weapon proc damage buff; not the unrelated boss aura `366305` or old proc spell `3742` |
| Daunting Growl `3146`; Decayed Strength `6951`; Curse of Weakness ranks and NPC variants | `Demoralizing` | **185** | Ordinary Strength/Agility, attack output or similar flat stat/output reductions, with existing Demo Shout/Roar/Screech |
| Ice Claw `3130`; Thunder Clap attack cadence penalty | `StatusEffects` | **253** | Disrupts attack timing/combat flow; not an ordinary movement snare |
| Camp Benefits, maintained class buffs, Darkmoon/other reviewed world buffs, documented mount auras | `BaselineClass` | **90** | One significant helpful native lane; no new mount priority |
| Well Fed variants, elixirs and approved minor effects | `Consumables` | **81** | One exact helpful lane; old `Elixirs`, `WellFed` and `MinorHelpful` lane keys retired |
| Cozy Sleeping Bag Well-Rested `429959`; Shiny Silver Coin; Far Sight family | `BottomHelpful` | **0** | Visible helpful informational effects, not the passive `1225478` Legacy talent |
| Boosted Rest `1229451`, Tricked or Treated, Tamed quest effects | `BoostedRest` | **0** | Harmful informational effects share bottom rank but separate polarity from `BottomHelpful` |
| Magic Wings `24742` and Walk on Air | `Utility` | **225** | Controlled falling utility, not `TravelUtility` or a movement snare |

## Adding or changing a classification

1. Confirm the actual **applied** aura identity and polarity from trustworthy spell data; the screenshot's tooltip cannot, by itself, expose an aura ID.
2. Put the reviewed ID in one `Spells.lua` category, and inherit an existing `Priority.lua` lane unless a **user-requested** tier change is explicit.
3. Confirm no other exact tier owns it (`/bp audit`, `R.TIER_AUDIT.overlapCount`, regression checks).
4. Test positive exact membership, native candidate filters, generic fallback exclusions, and the class/category intended to stay unchanged.
5. Separate **source tests** from **live client evidence**—the client may withhold auras in combat.

See [Architecture](../ARCHITECTURE.md), [Testing](TESTING.md), and the [historical issue log](KNOWN_ISSUES_HISTORY.md) for reasons previous classifications changed.
