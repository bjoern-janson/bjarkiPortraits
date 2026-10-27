# bjarkiPortraits — complete spell priority index

Source snapshot: **0.1.154-priority-scope-correction-test** · [GitHub source commit `e9c4b32`](https://github.com/bjoern-janson/bjarkiPortraits/commit/e9c4b3237c83fba9acbf2f7d0497b09776149c50)

This index contains **all 1,254 spell IDs** assigned to the addon's **51 exact display tiers**. It also includes all **7 native fallback tiers** and the **8 intentionally excluded source IDs**, with no representative-example truncation. Higher level means higher priority.

**Name accuracy:** The Name/annotation column reproduces comments in `Spells.lua`, not independently validated client spell names. When the source did not label an ID, the row says *Unlabeled in source*. Nothing is silently omitted; click its ID to see the authoritative source line.

**Rendering vs mapping:** A source spell ID being mapped does not guarantee the Forever client exposes its aura. Some host relationships restrict exact aura filtering. Separate HELPFUL and HARMFUL lanes at the same level do not have a guaranteed cross-filter recency order. Native semantic fallback tiers can include additional auras not represented by a fixed spell-ID list.

## Priority tier overview

| Level | Tier | Filter | Mapped IDs |
|---:|---|---|---:|
| 332 | [WaitingToResurrect](#tier-332-waitingtoresurrect) | `HELPFUL` | 4 |
| 330 | [ImmunityHarmful](#tier-330-immunityharmful) | `HARMFUL` | 3 |
| 330 | [Immunity](#tier-330-immunity) | `HELPFUL` | 10 |
| 320 | [Stun](#tier-320-stun) | `HARMFUL` | 36 |
| 320 | [HelpfulSelfStun](#tier-320-helpfulselfstun) | `HELPFUL` | 1 |
| 316 | [SpellImmunity](#tier-316-spellimmunity) | `HELPFUL` | 2 |
| 315 | [PhysicalImmunity](#tier-315-physicalimmunity) | `HELPFUL` | 4 |
| 310 | [Control](#tier-310-control) | `HARMFUL` | 65 |
| 309 | [CrowdControl](#tier-309-crowdcontrol) | `HARMFUL\|CROWD_CONTROL` | Native / dynamic |
| 306 | [InterruptSilence](#tier-306-interruptsilence) | `HARMFUL\|INCLUDE_NAME_PLATE_ONLY` | 26 |
| 305 | [RootImmunity](#tier-305-rootimmunity) | `HELPFUL` | 4 |
| 300 | [Roots](#tier-300-roots) | `HARMFUL` | 34 |
| 290 | [Defensive](#tier-290-defensive) | `HELPFUL` | 37 |
| 289 | [BigDef](#tier-289-bigdef) | `HELPFUL\|BIG_DEFENSIVE` | Native / dynamic |
| 288 | [ExternalDef](#tier-288-externaldef) | `HELPFUL\|EXTERNAL_DEFENSIVE` | Native / dynamic |
| 280 | [Offensive](#tier-280-offensive) | `HELPFUL` | 76 |
| 280 | [OffensiveHarmful](#tier-280-offensiveharmful) | `HARMFUL` | 2 |
| 279 | [Dazed](#tier-279-dazed) | `HARMFUL\|INCLUDE_NAME_PLATE_ONLY` | 3 |
| 278 | [Slows](#tier-278-slows) | `HARMFUL\|INCLUDE_NAME_PLATE_ONLY` | 47 |
| 261 | [Innervate](#tier-261-innervate) | `HELPFUL` | 18 |
| 260 | [FoodDrink](#tier-260-fooddrink) | `HELPFUL` | 78 |
| 259 | [MinorRegen](#tier-259-minorregen) | `HELPFUL` | 1 |
| 257 | [HonorlessTarget](#tier-257-honorlesstarget) | `HELPFUL\|INCLUDE_NAME_PLATE_ONLY` | 4 |
| 256 | [PowerWordShield](#tier-256-powerwordshield) | `HELPFUL` | 15 |
| 255 | [ResurrectionSickness](#tier-255-resurrectionsickness) | `HARMFUL\|INCLUDE_NAME_PLATE_ONLY` | 1 |
| 253 | [StatusEffects](#tier-253-statuseffects) | `HARMFUL\|INCLUDE_NAME_PLATE_ONLY` | 121 |
| 251 | [Healing](#tier-251-healing) | `HELPFUL` | 67 |
| 240 | [Forbearance](#tier-240-forbearance) | `HARMFUL` | 1 |
| 238 | [PriorityDebuff](#tier-238-prioritydebuff) | `HARMFUL` | Native / dynamic |
| 230 | [Wounds](#tier-230-wounds) | `HARMFUL` | 4 |
| 225 | [Utility](#tier-225-utility) | `HELPFUL\|INCLUDE_NAME_PLATE_ONLY` | 24 |
| 210 | [Seal](#tier-210-seal) | `HELPFUL` | 23 |
| 190 | [DoTs](#tier-190-dots) | `HARMFUL` | 149 |
| 189 | [Consecration](#tier-189-consecration) | `HARMFUL` | 1 |
| 185 | [Demoralizing](#tier-185-demoralizing) | `HARMFUL` | 18 |
| 180 | [HuntersMark](#tier-180-huntersmark) | `HARMFUL\|INCLUDE_NAME_PLATE_ONLY` | 5 |
| 175 | [SmallFriendlyHarmful](#tier-175-smallfriendlyharmful) | `HARMFUL\|INCLUDE_NAME_PLATE_ONLY` | Native / dynamic |
| 170 | [LoneWolf](#tier-170-lonewolf) | `HELPFUL\|INCLUDE_NAME_PLATE_ONLY` | 1 |
| 160 | [Mobility](#tier-160-mobility) | `HELPFUL\|INCLUDE_NAME_PLATE_ONLY` | 16 |
| 150 | [SelfState](#tier-150-selfstate) | `HELPFUL` | 55 |
| 120 | [Thorns](#tier-120-thorns) | `HELPFUL` | 12 |
| 110 | [WellFed](#tier-110-wellfed) | `HELPFUL` | 23 |
| 90 | [BaselineClass](#tier-90-baselineclass) | `HELPFUL` | 69 |
| 90 | [BaselineClassHarmful](#tier-90-baselineclassharmful) | `HARMFUL` | 1 |
| 85 | [Important](#tier-85-important) | `HELPFUL\|IMPORTANT\|!BIG_DEFENSIVE\|!EXTERNAL_DEFENSIVE` | Native / dynamic |
| 81 | [Elixirs](#tier-81-elixirs) | `HELPFUL` | 38 |
| 80 | [Scrolls](#tier-80-scrolls) | `HELPFUL` | 24 |
| 70 | [BloodPact](#tier-70-bloodpact) | `HELPFUL` | 13 |
| 60 | [PaladinAura](#tier-60-paladinaura) | `HELPFUL` | 73 |
| 59 | [PassiveDebuff](#tier-59-passivedebuff) | `HARMFUL` | 2 |
| 50 | [TravelUtility](#tier-50-travelutility) | `HELPFUL` | 9 |
| 10 | [Plainsrunning](#tier-10-plainsrunning) | `HELPFUL` | 4 |
| 9 | [PassiveSpeed](#tier-9-passivespeed) | `HELPFUL` | 1 |
| 5 | [HostileHelpful](#tier-5-hostilehelpful) | `HELPFUL\|INCLUDE_NAME_PLATE_ONLY` | Native / dynamic |
| 4 | [CampfireNearby](#tier-4-campfirenearby) | `HELPFUL` | 3 |
| 4 | [CampfireNearbyHarmful](#tier-4-campfirenearbyharmful) | `HARMFUL` | 3 |
| 3 | [Tracking](#tier-3-tracking) | `HELPFUL` | 19 |
| 1 | [Gathering](#tier-1-gathering) | `HELPFUL` | 4 |

## Every mapped spell, from highest to lowest


<a id="tier-332-waitingtoresurrect"></a>
### 332 — WaitingToResurrect

**Exact spell tier** · `HELPFUL`

**4 exact spells.** Source sets: `buffs_waiting_to_resurrect`, `buffs_ghost_speed`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [2584](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L770) | Waiting to Resurrect | `buffs_waiting_to_resurrect` |
| [21989](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L771) | Waiting to Resurrect | `buffs_waiting_to_resurrect` |
| [1234325](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L772) | Waiting to Resurrect (Forever) | `buffs_waiting_to_resurrect` |
| [1262229](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L775) | The Quick and the Dead (visible movement buff while dead) | `buffs_ghost_speed` |

<a id="tier-330-immunityharmful"></a>
### 330 — ImmunityHarmful

**Exact spell tier** · `HARMFUL`

**3 exact spells.** Source sets: `immunities_harmful`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [8326](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L6) | Ghost (death debuff) | `immunities_harmful` |
| [9036](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L7) | Ghost (passive death aura) | `immunities_harmful` |
| [1278162](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L8) | Ghost (Forever model variant; no native aura icon) | `immunities_harmful` |

<a id="tier-330-immunity"></a>
### 330 — Immunity

**Exact spell tier** · `HELPFUL`

**10 exact spells.** Source sets: `immunities`, `buffs_divine_protection`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [498](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L778) | Divine Protection | `buffs_divine_protection` |
| [642](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L14) | *Unlabeled in source* | `immunities` |
| [1020](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L15) | *Unlabeled in source* | `immunities` |
| [3169](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L11) | *Unlabeled in source* | `immunities` |
| [5573](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L779) | Divine Protection Rank 2 (Forever) | `buffs_divine_protection` |
| [11958](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L16) | *Unlabeled in source* | `immunities` |
| [16621](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L12) | *Unlabeled in source* | `immunities` |
| [20230](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L18) | *Unlabeled in source* | `immunities` |
| [27619](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L17) | Ice Block (visible NPC/Forever equivalent) | `immunities` |
| [425876](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L13) | *Unlabeled in source* | `immunities` |

<a id="tier-320-stun"></a>
### 320 — Stun

**Exact spell tier** · `HARMFUL`

**36 exact spells.** Source sets: `stuns`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [408](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L177) | Kidney Shot | `stuns` |
| [835](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L152) | Tidal Charm | `stuns` |
| [853](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L160) | Hammer of Justice | `stuns` |
| [1833](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L176) | Cheap Shot | `stuns` |
| [4068](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L154) | Iron Grenade | `stuns` |
| [5211](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L172) | Bash | `stuns` |
| [5530](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L186) | Mace Spec Stun | `stuns` |
| [5588](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L161) | Hammer of Justice | `stuns` |
| [5589](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L162) | Hammer of Justice | `stuns` |
| [6798](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L173) | Bash | `stuns` |
| [7922](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L185) | Charge Stun | `stuns` |
| [8643](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L178) | Kidney Shot | `stuns` |
| [8983](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L174) | Bash | `stuns` |
| [9005](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L168) | Pounce Stun Rank 1 | `stuns` |
| [9823](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L169) | Pounce Stun Rank 2 | `stuns` |
| [9827](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L170) | Pounce Stun Rank 3 | `stuns` |
| [10308](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L163) | Hammer of Justice | `stuns` |
| [12355](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L175) | Impact Stun | `stuns` |
| [12798](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L183) | Revenge Stun | `stuns` |
| [12809](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L184) | Concussion Blow | `stuns` |
| [13237](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L156) | Goblin Mortar | `stuns` |
| [13238](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L157) | Goblin Mortar (separate self-area stun) | `stuns` |
| [13327](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L151) | Reckless Charge | `stuns` |
| [15269](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L158) | Blackout | `stuns` |
| [15753](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L155) | Linken's Boomerang Stun | `stuns` |
| [16922](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L171) | Starfire Stun | `stuns` |
| [18093](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L159) | Pyroclasm | `stuns` |
| [19410](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L165) | Concussive Shot Stun | `stuns` |
| [19769](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L153) | Thorium Grenade | `stuns` |
| [20170](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L164) | Seal of Justice stun | `stuns` |
| [20253](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L180) | Intercept Stun | `stuns` |
| [20549](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L150) | War Stomp | `stuns` |
| [20614](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L181) | Intercept Stun | `stuns` |
| [20615](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L182) | Intercept Stun | `stuns` |
| [24394](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L188) | Intimidation | `stuns` |
| [400009](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L179) | Between the Eyes | `stuns` |

<a id="tier-320-helpfulselfstun"></a>
### 320 — HelpfulSelfStun

**Exact spell tier** · `HELPFUL`

**1 exact spells.** Source sets: `buffs_self_stun`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [1301167](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L40) | Transformative Cocoon (self-stun; currently a helpful aura) | `buffs_self_stun` |

<a id="tier-316-spellimmunity"></a>
### 316 — SpellImmunity

**Exact spell tier** · `HELPFUL`

**2 exact spells.** Source sets: `immunities_interrupt`, `buffs_grounding`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [8178](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L36) | Grounding Totem Effect (spell redirection) | `buffs_grounding` |
| [1310897](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L33) | Voice of Truth (Silence and Interrupt immunity) | `immunities_interrupt` |

<a id="tier-315-physicalimmunity"></a>
### 315 — PhysicalImmunity

**Exact spell tier** · `HELPFUL`

**4 exact spells.** Source sets: `immunities_physical`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [1022](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L21) | Blessing of Protection Rank 1 | `immunities_physical` |
| [5599](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L22) | Blessing of Protection Rank 2 | `immunities_physical` |
| [6615](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L24) | Free Action Potion (stun/root/snare immunity; grouped here by display priority) | `immunities_physical` |
| [10278](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L23) | Blessing of Protection Rank 3 | `immunities_physical` |

<a id="tier-310-control"></a>
### 310 — Control

**Exact spell tier** · `HARMFUL`

**65 exact spells.** Source sets: `cc`; excluded: `stuns`, `interrupts`, `silences`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [118](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L109) | *Unlabeled in source* | `cc` |
| [605](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L55) | *Unlabeled in source* | `cc` |
| [676](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L143) | Disarm | `cc` |
| [710](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L74) | *Unlabeled in source* | `cc` |
| [1090](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L44) | *Unlabeled in source* | `cc` |
| [1098](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L144) | Subjugate Demon | `cc` |
| [1513](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L87) | *Unlabeled in source* | `cc` |
| [1776](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L125) | *Unlabeled in source* | `cc` |
| [1777](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L126) | *Unlabeled in source* | `cc` |
| [2070](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L121) | *Unlabeled in source* | `cc` |
| [2094](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L124) | *Unlabeled in source* | `cc` |
| [2637](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L98) | *Unlabeled in source* | `cc` |
| [2878](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L145) | Turn Undead | `cc` |
| [3355](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L91) | *Unlabeled in source* | `cc` |
| [5134](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L47) | *Unlabeled in source* | `cc` |
| [5246](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L132) | *Unlabeled in source* | `cc` |
| [5484](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L72) | *Unlabeled in source* | `cc` |
| [5782](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L69) | *Unlabeled in source* | `cc` |
| [6213](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L70) | *Unlabeled in source* | `cc` |
| [6215](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L71) | *Unlabeled in source* | `cc` |
| [6358](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L68) | *Unlabeled in source* | `cc` |
| [6770](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L122) | *Unlabeled in source* | `cc` |
| [6789](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L76) | *Unlabeled in source* | `cc` |
| [8122](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L58) | *Unlabeled in source* | `cc` |
| [8124](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L59) | *Unlabeled in source* | `cc` |
| [8629](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L127) | *Unlabeled in source* | `cc` |
| [9484](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L64) | *Unlabeled in source* | `cc` |
| [9485](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L65) | *Unlabeled in source* | `cc` |
| [10888](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L60) | *Unlabeled in source* | `cc` |
| [10890](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L61) | *Unlabeled in source* | `cc` |
| [10911](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L56) | *Unlabeled in source* | `cc` |
| [10912](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L57) | *Unlabeled in source* | `cc` |
| [10955](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L66) | *Unlabeled in source* | `cc` |
| [11285](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L128) | *Unlabeled in source* | `cc` |
| [11286](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L129) | *Unlabeled in source* | `cc` |
| [11297](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L123) | *Unlabeled in source* | `cc` |
| [12824](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L110) | *Unlabeled in source* | `cc` |
| [12825](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L111) | *Unlabeled in source* | `cc` |
| [12826](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L112) | *Unlabeled in source* | `cc` |
| [14308](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L92) | *Unlabeled in source* | `cc` |
| [14309](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L93) | *Unlabeled in source* | `cc` |
| [14326](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L88) | *Unlabeled in source* | `cc` |
| [14327](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L89) | *Unlabeled in source* | `cc` |
| [17925](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L77) | *Unlabeled in source* | `cc` |
| [17926](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L78) | *Unlabeled in source* | `cc` |
| [17928](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L73) | *Unlabeled in source* | `cc` |
| [18498](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L131) | *Unlabeled in source* | `cc` |
| [18647](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L75) | *Unlabeled in source* | `cc` |
| [18657](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L99) | *Unlabeled in source* | `cc` |
| [18658](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L100) | *Unlabeled in source* | `cc` |
| [18798](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L53) | *Unlabeled in source* | `cc` |
| [19386](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L94) | *Unlabeled in source* | `cc` |
| [19503](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L97) | *Unlabeled in source* | `cc` |
| [20066](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L84) | *Unlabeled in source* | `cc` |
| [20511](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L133) | *Unlabeled in source* | `cc` |
| [24132](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L95) | *Unlabeled in source* | `cc` |
| [24133](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L96) | *Unlabeled in source* | `cc` |
| [28270](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L113) | *Unlabeled in source* | `cc` |
| [28271](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L114) | *Unlabeled in source* | `cc` |
| [28272](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L115) | *Unlabeled in source* | `cc` |
| [427719](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L86) | *Unlabeled in source* | `cc` |
| [446391](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L54) | *Unlabeled in source* | `cc` |
| [1265054](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L146) | Mine! | `cc` |
| [1265055](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L142) | Mine! | `cc` |
| [1265056](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L147) | Mine! | `cc` |

<a id="tier-309-crowdcontrol"></a>
### 309 — CrowdControl

**Native semantic fallback** · `HARMFUL\|CROWD_CONTROL`

No enumerable spell-ID set: Blizzard chooses from currently eligible auras using the native candidate filter.

No additional candidate rules are specified.

<a id="tier-306-interruptsilence"></a>
### 306 — InterruptSilence

**Exact spell tier** · `HARMFUL\|INCLUDE_NAME_PLATE_ONLY`

**26 exact spells.** Source sets: `interrupts`, `silences`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [72](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L428) | *Unlabeled in source* | `interrupts` |
| [1330](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L407) | Garrote - Silence (later-rank effect, only if present) | `silences` |
| [1671](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L429) | *Unlabeled in source* | `interrupts` |
| [1672](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L430) | *Unlabeled in source* | `interrupts` |
| [1766](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L421) | *Unlabeled in source* | `interrupts` |
| [1767](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L422) | *Unlabeled in source* | `interrupts` |
| [1768](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L423) | *Unlabeled in source* | `interrupts` |
| [1769](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L424) | *Unlabeled in source* | `interrupts` |
| [2139](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L420) | *Unlabeled in source* | `interrupts` |
| [6552](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L426) | *Unlabeled in source* | `interrupts` |
| [6554](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L427) | *Unlabeled in source* | `interrupts` |
| [8042](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L413) | *Unlabeled in source* | `interrupts` |
| [8044](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L414) | *Unlabeled in source* | `interrupts` |
| [8045](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L415) | *Unlabeled in source* | `interrupts` |
| [8046](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L416) | *Unlabeled in source* | `interrupts` |
| [10412](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L417) | *Unlabeled in source* | `interrupts` |
| [10413](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L418) | *Unlabeled in source* | `interrupts` |
| [10414](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L419) | *Unlabeled in source* | `interrupts` |
| [14251](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L425) | *Unlabeled in source* | `interrupts` |
| [15487](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L403) | Silence (Priest) | `silences` |
| [15752](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L410) | *Unlabeled in source* | `interrupts` |
| [18425](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L404) | Kick - Silenced (Improved Kick effect) | `silences` |
| [18469](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L405) | Silenced - Improved Counterspell | `silences` |
| [19244](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L411) | *Unlabeled in source* | `interrupts` |
| [19647](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L412) | *Unlabeled in source* | `interrupts` |
| [24259](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L406) | Spell Lock (applied silence) | `silences` |

<a id="tier-305-rootimmunity"></a>
### 305 — RootImmunity

**Exact spell tier** · `HELPFUL`

**4 exact spells.** Source sets: `immunities_root`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [1044](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L27) | Blessing of Freedom | `immunities_root` |
| [1953](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L29) | Blink (Mage; displayed here if an eligible aura is present) | `immunities_root` |
| [20589](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L28) | Escape Artist | `immunities_root` |
| [1236175](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L30) | Blink (Forever variant) | `immunities_root` |

<a id="tier-300-roots"></a>
### 300 — Roots

**Exact spell tier** · `HARMFUL`

**34 exact spells.** Source sets: `roots`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [122](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L387) | *Unlabeled in source* | `roots` |
| [339](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L374) | *Unlabeled in source* | `roots` |
| [865](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L388) | *Unlabeled in source* | `roots` |
| [1062](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L375) | *Unlabeled in source* | `roots` |
| [5195](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L376) | *Unlabeled in source* | `roots` |
| [5196](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L377) | *Unlabeled in source* | `roots` |
| [6131](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L389) | *Unlabeled in source* | `roots` |
| [6533](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L364) | *Unlabeled in source* | `roots` |
| [9852](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L378) | *Unlabeled in source* | `roots` |
| [9853](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L379) | *Unlabeled in source* | `roots` |
| [10230](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L390) | *Unlabeled in source* | `roots` |
| [12494](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L386) | *Unlabeled in source* | `roots` |
| [16979](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L365) | *Unlabeled in source* | `roots` |
| [18310](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L366) | *Unlabeled in source* | `roots` |
| [18313](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L367) | *Unlabeled in source* | `roots` |
| [19185](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L372) | *Unlabeled in source* | `roots` |
| [19229](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L368) | *Unlabeled in source* | `roots` |
| [19306](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L369) | *Unlabeled in source* | `roots` |
| [19675](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L394) | Feral Charge | `roots` |
| [19970](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L380) | *Unlabeled in source* | `roots` |
| [19971](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L381) | *Unlabeled in source* | `roots` |
| [19972](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L382) | *Unlabeled in source* | `roots` |
| [19973](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L383) | *Unlabeled in source* | `roots` |
| [19974](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L384) | *Unlabeled in source* | `roots` |
| [19975](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L385) | *Unlabeled in source* | `roots` |
| [20909](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L370) | *Unlabeled in source* | `roots` |
| [20910](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L371) | *Unlabeled in source* | `roots` |
| [23694](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L391) | *Unlabeled in source* | `roots` |
| [25999](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L373) | *Unlabeled in source* | `roots` |
| [1242634](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L395) | Counterattack | `roots` |
| [1265843](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L396) | Web | `roots` |
| [1265878](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L397) | Web | `roots` |
| [1277331](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L393) | Chastise | `roots` |
| [1277332](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L398) | Chastise | `roots` |

<a id="tier-290-defensive"></a>
### 290 — Defensive

**Exact spell tier** · `HELPFUL`

**37 exact spells.** Source sets: `buffs_defensive`, `buffs_racial_defensive`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [871](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L496) | *Unlabeled in source* | `buffs_defensive` |
| [2565](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L502) | Shield Block | `buffs_defensive` |
| [2651](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L503) | Elune's Grace | `buffs_defensive` |
| [2893](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L504) | Abolish Poison | `buffs_defensive` |
| [5277](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L494) | *Unlabeled in source* | `buffs_defensive` |
| [6940](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L488) | *Unlabeled in source* | `buffs_defensive` |
| [14278](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L495) | *Unlabeled in source* | `buffs_defensive` |
| [14751](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L505) | Inner Focus | `buffs_defensive` |
| [14892](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L481) | *Unlabeled in source* | `buffs_defensive` |
| [15362](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L482) | *Unlabeled in source* | `buffs_defensive` |
| [15363](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L483) | *Unlabeled in source* | `buffs_defensive` |
| [16177](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L506) | Ancestral Fortitude | `buffs_defensive` |
| [16188](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L486) | *Unlabeled in source* | `buffs_defensive` |
| [17116](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L507) | Nature's Swiftness | `buffs_defensive` |
| [19263](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L492) | *Unlabeled in source* | `buffs_defensive` |
| [19753](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L508) | Divine Intervention | `buffs_defensive` |
| [20216](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L509) | Divine Favor | `buffs_defensive` |
| [20594](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1334) | Stoneform | `buffs_racial_defensive` |
| [20729](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L489) | *Unlabeled in source* | `buffs_defensive` |
| [22812](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L493) | *Unlabeled in source* | `buffs_defensive` |
| [23506](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L479) | *Unlabeled in source* | `buffs_defensive` |
| [26064](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L510) | Shell Shield | `buffs_defensive` |
| [27828](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L511) | Focused Casting | `buffs_defensive` |
| [29506](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L480) | *Unlabeled in source* | `buffs_defensive` |
| [402004](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L484) | *Unlabeled in source* | `buffs_defensive` |
| [407613](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L490) | *Unlabeled in source* | `buffs_defensive` |
| [412019](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L491) | *Unlabeled in source* | `buffs_defensive` |
| [425294](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L485) | *Unlabeled in source* | `buffs_defensive` |
| [436391](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L487) | *Unlabeled in source* | `buffs_defensive` |
| [1277462](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L497) | Contingency Plan Rank 1 (ward) | `buffs_defensive` |
| [1277634](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L498) | Contingency Plan Rank 2 (ward) | `buffs_defensive` |
| [1277638](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L499) | Contingency Plan Rank 3 (ward) | `buffs_defensive` |
| [1277639](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L500) | Contingency Plan Rank 4 (ward) | `buffs_defensive` |
| [1277640](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L501) | Contingency Plan Rank 5 (ward) | `buffs_defensive` |
| [1299026](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L478) | Shatter Curse | `buffs_defensive` |
| [1310612](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L513) | Trickster's Dance | `buffs_defensive` |
| [1311015](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L512) | Templar's Bulwark | `buffs_defensive` |

<a id="tier-289-bigdef"></a>
### 289 — BigDef

**Native semantic fallback** · `HELPFUL\|BIG_DEFENSIVE`

No enumerable spell-ID set: Blizzard chooses from currently eligible auras using the native candidate filter.

No additional candidate rules are specified.

<a id="tier-288-externaldef"></a>
### 288 — ExternalDef

**Native semantic fallback** · `HELPFUL\|EXTERNAL_DEFENSIVE`

No enumerable spell-ID set: Blizzard chooses from currently eligible auras using the native candidate filter.

No additional candidate rules are specified.

<a id="tier-280-offensive"></a>
### 280 — Offensive

**Exact spell tier** · `HELPFUL`

**76 exact spells.** Source sets: `buffs_offensive`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [1719](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L600) | *Unlabeled in source* | `buffs_offensive` |
| [1850](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L583) | *Unlabeled in source* | `buffs_offensive` |
| [1949](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L604) | Hellfire | `buffs_offensive` |
| [2379](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L566) | *Unlabeled in source* | `buffs_offensive` |
| [2983](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L597) | *Unlabeled in source* | `buffs_offensive` |
| [3045](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L580) | *Unlabeled in source* | `buffs_offensive` |
| [5024](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L565) | *Unlabeled in source* | `buffs_offensive` |
| [5171](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L605) | Slice and Dice | `buffs_offensive` |
| [6150](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L606) | Quick Shots | `buffs_offensive` |
| [8385](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L550) | Swift Wind (movement and attack speed) | `buffs_offensive` |
| [8696](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L598) | *Unlabeled in source* | `buffs_offensive` |
| [8892](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L575) | *Unlabeled in source* | `buffs_offensive` |
| [9175](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L573) | *Unlabeled in source* | `buffs_offensive` |
| [9774](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L576) | *Unlabeled in source* | `buffs_offensive` |
| [9821](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L584) | *Unlabeled in source* | `buffs_offensive` |
| [10060](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L578) | *Unlabeled in source* | `buffs_offensive` |
| [11305](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L599) | *Unlabeled in source* | `buffs_offensive` |
| [11359](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L564) | *Unlabeled in source* | `buffs_offensive` |
| [12042](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L594) | *Unlabeled in source* | `buffs_offensive` |
| [12043](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L607) | Presence of Mind | `buffs_offensive` |
| [12292](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L608) | Sweeping Strikes | `buffs_offensive` |
| [12536](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L609) | Clearcasting | `buffs_offensive` |
| [12733](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L570) | *Unlabeled in source* | `buffs_offensive` |
| [13141](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L574) | *Unlabeled in source* | `buffs_offensive` |
| [13159](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L579) | *Unlabeled in source* | `buffs_offensive` |
| [13494](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L577) | *Unlabeled in source* | `buffs_offensive` |
| [13750](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L595) | *Unlabeled in source* | `buffs_offensive` |
| [13877](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L596) | *Unlabeled in source* | `buffs_offensive` |
| [13896](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L610) | Feedback | `buffs_offensive` |
| [14177](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L611) | Cold Blood | `buffs_offensive` |
| [14253](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L572) | *Unlabeled in source* | `buffs_offensive` |
| [14530](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L571) | *Unlabeled in source* | `buffs_offensive` |
| [16246](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L612) | Clearcasting | `buffs_offensive` |
| [16870](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L592) | Clearcasting (Druid) | `buffs_offensive` |
| [16886](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L613) | Nature's Grace | `buffs_offensive` |
| [18499](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L601) | *Unlabeled in source* | `buffs_offensive` |
| [19271](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L614) | Feedback | `buffs_offensive` |
| [19574](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L581) | *Unlabeled in source* | `buffs_offensive` |
| [20554](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L555) | Berserking (Troll racial, Forever) | `buffs_offensive` |
| [20572](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L557) | Blood Fury (Orc racial) | `buffs_offensive` |
| [20600](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L556) | *Unlabeled in source* | `buffs_offensive` |
| [23097](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L567) | *Unlabeled in source* | `buffs_offensive` |
| [23131](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L568) | *Unlabeled in source* | `buffs_offensive` |
| [23132](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L569) | *Unlabeled in source* | `buffs_offensive` |
| [23451](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L558) | Speed (battleground rune) | `buffs_offensive` |
| [23505](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L561) | Berserking (battleground) | `buffs_offensive` |
| [23978](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L559) | Speed (battleground rune applied variant) | `buffs_offensive` |
| [24364](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L563) | *Unlabeled in source* | `buffs_offensive` |
| [24378](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L551) | Berserking (battleground damage buff) | `buffs_offensive` |
| [400589](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L615) | Missile Barrage | `buffs_offensive` |
| [402975](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L549) | Victorious (applied Victory Rush state) | `buffs_offensive` |
| [409368](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L582) | *Unlabeled in source* | `buffs_offensive` |
| [417141](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L585) | *Unlabeled in source* | `buffs_offensive` |
| [422621](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L593) | Preparation (battleground resource-cost aura) | `buffs_offensive` |
| [1248808](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L542) | Revelation (Mage active enchant proc) | `buffs_offensive` |
| [1259799](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L591) | Elune's Light | `buffs_offensive` |
| [1259812](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L586) | Eureka! (Gnome Rogue) | `buffs_offensive` |
| [1259813](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L587) | Eureka! (Gnome Warrior) | `buffs_offensive` |
| [1259817](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L588) | Eureka! (Gnome Mage) | `buffs_offensive` |
| [1259821](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L589) | Eureka! (Gnome Warlock) | `buffs_offensive` |
| [1259823](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L590) | Eureka! (Gnome Priest) | `buffs_offensive` |
| [1284536](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L616) | Holy Purpose | `buffs_offensive` |
| [1286304](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L562) | Berserking (Forever battleground applied aura) | `buffs_offensive` |
| [1286345](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L560) | Speed (Forever battleground rune applied aura) | `buffs_offensive` |
| [1299448](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L617) | Quick Strikes | `buffs_offensive` |
| [1301168](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L554) | Transformative Cocoon (movement-speed aura) | `buffs_offensive` |
| [1309728](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L553) | Speed (Satchel of Potions) | `buffs_offensive` |
| [1310726](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L618) | Expose Prey | `buffs_offensive` |
| [1310994](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L619) | Swift Judgement | `buffs_offensive` |
| [1323377](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L543) | Revelation (Priest active enchant proc) | `buffs_offensive` |
| [1323392](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L544) | Revelation (Warlock active enchant proc) | `buffs_offensive` |
| [1323400](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L545) | Revelation (Druid active enchant proc) | `buffs_offensive` |
| [1323410](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L546) | Revelation (Hunter active enchant proc) | `buffs_offensive` |
| [1323418](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L547) | Revelation (Shaman active enchant proc) | `buffs_offensive` |
| [1323419](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L548) | Revelation (Paladin active enchant proc) | `buffs_offensive` |
| [1323969](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L603) | Gore Drinker | `buffs_offensive` |

<a id="tier-280-offensiveharmful"></a>
### 280 — OffensiveHarmful

**Exact spell tier** · `HARMFUL`

**2 exact spells.** Source sets: `debuffs_offensive`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [12328](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1338) | Death Wish (offensive cooldown, applied as a debuff) | `debuffs_offensive` |
| [400573](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1337) | Arcane Blast (applied Intellect/spell-damage and mana-cost stacks) | `debuffs_offensive` |

<a id="tier-279-dazed"></a>
### 279 — Dazed

**Exact spell tier** · `HARMFUL\|INCLUDE_NAME_PLATE_ONLY`

**3 exact spells.** Source sets: `slows_dazed`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [1604](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L349) | Dazed (applied movement slow) | `slows_dazed` |
| [13496](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L350) | Dazed (item-effect movement slow) | `slows_dazed` |
| [15571](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L351) | Dazed (formerly misclassified with Forbearance) | `slows_dazed` |

<a id="tier-278-slows"></a>
### 278 — Slows

**Exact spell tier** · `HARMFUL\|INCLUDE_NAME_PLATE_ONLY`

**47 exact spells.** Source sets: `slows`, `slows_chilled`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [116](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L310) | Frostbolt Rank 1 | `slows` |
| [120](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L361) | Cone of Cold | `slows_chilled` |
| [205](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L311) | Frostbolt Rank 2 | `slows` |
| [837](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L312) | Frostbolt Rank 3 | `slows` |
| [1715](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L329) | Hamstring | `slows` |
| [2974](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L330) | Wing Clip | `slows` |
| [3409](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L343) | Crippling Poison (movement slow) | `slows` |
| [3600](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L325) | Earthbind (Earthbind Totem slow aura) | `slows` |
| [5116](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L331) | Concussive Shot | `slows` |
| [6136](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L354) | Chilled (Frost Armor) | `slows_chilled` |
| [7321](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L355) | Chilled (Ice/Frost Armor family) | `slows_chilled` |
| [7322](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L313) | Frostbolt Rank 4 | `slows` |
| [8034](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L332) | Frostbrand Attack | `slows` |
| [8037](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L333) | Frostbrand Attack | `slows` |
| [8056](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L334) | Frost Shock | `slows` |
| [8058](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L306) | Frost Shock Rank 2 | `slows` |
| [8406](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L314) | Frostbolt Rank 5 | `slows` |
| [8407](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L315) | Frostbolt Rank 6 | `slows` |
| [8408](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L316) | Frostbolt Rank 7 | `slows` |
| [10179](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L317) | Frostbolt Rank 8 | `slows` |
| [10180](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L318) | Frostbolt Rank 9 | `slows` |
| [10181](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L319) | Frostbolt Rank 10 | `slows` |
| [10472](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L307) | Frost Shock Rank 3 | `slows` |
| [10473](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L308) | Frost Shock Rank 4 | `slows` |
| [11113](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L335) | Blast Wave | `slows` |
| [11201](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L344) | Crippling Poison (movement slow) | `slows` |
| [12323](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L336) | Piercing Howl | `slows` |
| [12484](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L356) | Chilled (Forever/NPC variant) | `slows_chilled` |
| [12548](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L345) | Frost Shock (movement slow) | `slows` |
| [13810](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L326) | Frost Trap Aura (applied 60% slow, not the trap summon) | `slows` |
| [15407](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L337) | Mind Flay | `slows` |
| [15850](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L357) | Chilled (Forever/NPC variant) | `slows_chilled` |
| [17311](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L338) | Mind Flay | `slows` |
| [18101](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L358) | Chilled (Forever/NPC variant) | `slows_chilled` |
| [18118](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L339) | Aftermath | `slows` |
| [18223](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L346) | Curse of Exhaustion (movement slow) | `slows` |
| [20005](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L359) | Chilled (Forever/NPC variant) | `slows_chilled` |
| [21369](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L321) | Frostbolt (NPC/Forever variant) | `slows` |
| [350025](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L322) | Frostbolt (Forever variant) | `slows` |
| [420526](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L323) | Frostbolt (NPC/Forever variant) | `slows` |
| [1264735](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L340) | Pinch | `slows` |
| [1264736](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L341) | Pinch | `slows` |
| [1265038](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L328) | Tendon Rip | `slows` |
| [1265039](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L342) | Tendon Rip | `slows` |
| [1296223](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L360) | Chilled (Forever/NPC variant) | `slows_chilled` |
| [1303226](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L324) | Frostbolt (NPC/Forever variant) | `slows` |
| [1316489](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L309) | Highland Venom (dungeon Disease, movement slow) | `slows` |

<a id="tier-261-innervate"></a>
### 261 — Innervate

**Exact spell tier** · `HELPFUL`

**18 exact spells.** Source sets: `buffs_innervate`, `buffs_druid_enrage`, `buffs_bloodrage`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [5229](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L970) | Enrage (Druid) | `buffs_druid_enrage` |
| [15271](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L961) | Spirit Tap | `buffs_innervate` |
| [16191](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L962) | Mana Tide | `buffs_innervate` |
| [17355](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L963) | Mana Tide | `buffs_innervate` |
| [17360](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L964) | Mana Tide | `buffs_innervate` |
| [29131](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L973) | Bloodrage (Warrior aura; 10 sec rage generation) | `buffs_bloodrage` |
| [29166](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L951) | Innervate (Druid) | `buffs_innervate` |
| [1242688](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L965) | Resourcefulness | `buffs_innervate` |
| [1262243](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L953) | Mage | `buffs_innervate` |
| [1262307](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L954) | Druid | `buffs_innervate` |
| [1262309](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L955) | Hunter | `buffs_innervate` |
| [1262310](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L956) | Paladin | `buffs_innervate` |
| [1262312](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L957) | Priest | `buffs_innervate` |
| [1262315](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L958) | Shaman | `buffs_innervate` |
| [1262316](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L959) | Warlock | `buffs_innervate` |
| [1262317](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L960) | Warrior | `buffs_innervate` |
| [1277324](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L966) | Dark Sacrifice | `buffs_innervate` |
| [1277325](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L967) | Dark Sacrifice | `buffs_innervate` |

<a id="tier-260-fooddrink"></a>
### 260 — FoodDrink

**Exact spell tier** · `HELPFUL`

**78 exact spells.** Source sets: `buffs_fooddrink`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [430](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L877) | Drink (level 5 water) | `buffs_fooddrink` |
| [431](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L878) | Drink (level 15 water) | `buffs_fooddrink` |
| [432](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L879) | Drink (level 25 water) | `buffs_fooddrink` |
| [433](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L828) | Food | `buffs_fooddrink` |
| [434](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L829) | Food | `buffs_fooddrink` |
| [435](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L830) | Food | `buffs_fooddrink` |
| [833](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L885) | Drink | `buffs_fooddrink` |
| [1127](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L831) | Food | `buffs_fooddrink` |
| [1129](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L832) | Food | `buffs_fooddrink` |
| [1131](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L833) | Food | `buffs_fooddrink` |
| [1133](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L880) | Drink (level 35 water) | `buffs_fooddrink` |
| [1135](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L881) | Drink (level 45 water) | `buffs_fooddrink` |
| [2639](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L834) | Food | `buffs_fooddrink` |
| [5004](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L835) | Food | `buffs_fooddrink` |
| [5005](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L836) | Food | `buffs_fooddrink` |
| [5006](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L837) | Food | `buffs_fooddrink` |
| [5007](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L838) | Food | `buffs_fooddrink` |
| [6410](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L839) | Food | `buffs_fooddrink` |
| [7737](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L840) | Food | `buffs_fooddrink` |
| [9177](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L841) | Food | `buffs_fooddrink` |
| [10250](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L882) | Drink (higher-rank water) | `buffs_fooddrink` |
| [10256](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L842) | Food | `buffs_fooddrink` |
| [10257](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L843) | Food | `buffs_fooddrink` |
| [12051](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L826) | Evocation (Mage) | `buffs_fooddrink` |
| [18124](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L844) | Food | `buffs_fooddrink` |
| [18140](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L886) | Drink | `buffs_fooddrink` |
| [18229](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L845) | Food | `buffs_fooddrink` |
| [18230](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L846) | Food | `buffs_fooddrink` |
| [18231](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L847) | Food | `buffs_fooddrink` |
| [18232](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L848) | Food | `buffs_fooddrink` |
| [18233](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L849) | Food | `buffs_fooddrink` |
| [18234](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L850) | Food | `buffs_fooddrink` |
| [20577](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L824) | Cannibalize activation (Undead) | `buffs_fooddrink` |
| [20578](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L825) | Cannibalize channel aura (Undead) | `buffs_fooddrink` |
| [21149](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L851) | Food | `buffs_fooddrink` |
| [22731](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L852) | Food | `buffs_fooddrink` |
| [22734](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L900) | Drink | `buffs_fooddrink` |
| [23493](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L820) | Restoration (battleground health and mana recovery) | `buffs_fooddrink` |
| [23698](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L887) | Drink | `buffs_fooddrink` |
| [24005](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L853) | Food | `buffs_fooddrink` |
| [24355](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L888) | Drink | `buffs_fooddrink` |
| [24379](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L821) | Restoration (battleground health, mana and pet-happiness recovery) | `buffs_fooddrink` |
| [24707](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L854) | Food | `buffs_fooddrink` |
| [24800](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L855) | Food | `buffs_fooddrink` |
| [24869](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L856) | Food | `buffs_fooddrink` |
| [25660](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L857) | Food | `buffs_fooddrink` |
| [25695](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L858) | Food | `buffs_fooddrink` |
| [25696](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L889) | Drink | `buffs_fooddrink` |
| [25697](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L859) | Food | `buffs_fooddrink` |
| [25700](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L860) | Food | `buffs_fooddrink` |
| [25701](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L890) | Drink | `buffs_fooddrink` |
| [25702](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L861) | Food | `buffs_fooddrink` |
| [25703](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L891) | Drink | `buffs_fooddrink` |
| [25886](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L862) | Food | `buffs_fooddrink` |
| [25887](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L892) | Drink | `buffs_fooddrink` |
| [25888](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L863) | Food | `buffs_fooddrink` |
| [25889](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L893) | Drink | `buffs_fooddrink` |
| [25990](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L864) | Food | `buffs_fooddrink` |
| [26030](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L865) | Food | `buffs_fooddrink` |
| [26260](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L866) | Food | `buffs_fooddrink` |
| [26261](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L894) | Drink | `buffs_fooddrink` |
| [26263](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L867) | Food | `buffs_fooddrink` |
| [26401](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L868) | Food | `buffs_fooddrink` |
| [26402](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L895) | Drink | `buffs_fooddrink` |
| [26472](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L869) | Food | `buffs_fooddrink` |
| [26473](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L896) | Drink | `buffs_fooddrink` |
| [26474](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L870) | Food | `buffs_fooddrink` |
| [26475](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L897) | Drink | `buffs_fooddrink` |
| [28616](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L871) | Food | `buffs_fooddrink` |
| [29007](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L898) | Drink | `buffs_fooddrink` |
| [29008](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L872) | Food | `buffs_fooddrink` |
| [29038](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L873) | Food | `buffs_fooddrink` |
| [29039](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L899) | Drink | `buffs_fooddrink` |
| [29055](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L874) | Food | `buffs_fooddrink` |
| [29073](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L875) | Food | `buffs_fooddrink` |
| [446714](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L883) | Drink (Forever) | `buffs_fooddrink` |
| [468767](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L884) | Drink (Forever) | `buffs_fooddrink` |
| [1286344](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L822) | Restoration (current Forever battleground recovery aura) | `buffs_fooddrink` |

<a id="tier-259-minorregen"></a>
### 259 — MinorRegen

**Exact spell tier** · `HELPFUL`

**1 exact spells.** Source sets: `buffs_minor_regen`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [1261483](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L948) | Thrill of Adventure (active 10s recovery proc, not passive 1225472) | `buffs_minor_regen` |

<a id="tier-257-honorlesstarget"></a>
### 257 — HonorlessTarget

**Exact spell tier** · `HELPFUL\|INCLUDE_NAME_PLATE_ONLY`

**4 exact spells.** Source sets: `buffs_honorless_target`, `buffs_battleground_flag`, `buffs_welcoming_campfire`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [2479](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L782) | Honorless Target | `buffs_honorless_target` |
| [1229739](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1406) | Welcoming Campfire (Forever live variant) | `buffs_welcoming_campfire` |
| [1284560](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1461) | Darkspear Islands Flag (carried objective) | `buffs_battleground_flag` |
| [1289723](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1407) | Welcoming Campfire (Forever live variant) | `buffs_welcoming_campfire` |

<a id="tier-256-powerwordshield"></a>
### 256 — PowerWordShield

**Exact spell tier** · `HELPFUL`

**15 exact spells.** Source sets: `buffs_power_word_shield`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [17](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L433) | Power Word: Shield | `buffs_power_word_shield` |
| [592](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L434) | Power Word: Shield | `buffs_power_word_shield` |
| [600](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L435) | Power Word: Shield | `buffs_power_word_shield` |
| [3747](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L436) | Power Word: Shield | `buffs_power_word_shield` |
| [6065](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L437) | Power Word: Shield | `buffs_power_word_shield` |
| [6066](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L438) | Power Word: Shield | `buffs_power_word_shield` |
| [10898](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L439) | Power Word: Shield | `buffs_power_word_shield` |
| [10899](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L440) | Power Word: Shield | `buffs_power_word_shield` |
| [10900](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L441) | Power Word: Shield | `buffs_power_word_shield` |
| [10901](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L442) | Power Word: Shield | `buffs_power_word_shield` |
| [11426](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L444) | Ice Barrier Rank 1 | `buffs_power_word_shield` |
| [13031](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L445) | Ice Barrier Rank 2 | `buffs_power_word_shield` |
| [13032](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L446) | Ice Barrier Rank 3 | `buffs_power_word_shield` |
| [13033](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L447) | Ice Barrier Rank 4 | `buffs_power_word_shield` |
| [1316048](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L443) | Transformative Cocoon (absorb aura) | `buffs_power_word_shield` |

<a id="tier-255-resurrectionsickness"></a>
### 255 — ResurrectionSickness

**Exact spell tier** · `HARMFUL\|INCLUDE_NAME_PLATE_ONLY`

**1 exact spells.** Source sets: `debuffs_resurrection_sickness`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [15007](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L763) | Resurrection Sickness (highest StatusEffect) | `debuffs_resurrection_sickness` |

<a id="tier-253-statuseffects"></a>
### 253 — StatusEffects

**Exact spell tier** · `HARMFUL\|INCLUDE_NAME_PLATE_ONLY`

**121 exact spells.** Source sets: `debuffs_other`, `debuffs_taunts`, `debuffs_casting_penalty`, `debuffs_attack_penalty`, `debuffs_healing_reduction`, `debuffs_environmental_danger`, `debuffs_res_sickness`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [355](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L192) | Taunt | `debuffs_taunts` |
| [453](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L718) | Mind Soothe | `debuffs_other` |
| [689](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L719) | Drain Life | `debuffs_other` |
| [694](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L195) | Mocking Blow Rank 1 | `debuffs_taunts` |
| [699](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L720) | Drain Life | `debuffs_other` |
| [702](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L709) | Curse of Weakness Rank 1 | `debuffs_other` |
| [704](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L721) | Curse of Recklessness | `debuffs_other` |
| [709](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L722) | Drain Life | `debuffs_other` |
| [770](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L704) | Faerie Fire Rank 1 | `debuffs_other` |
| [778](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L705) | Faerie Fire Rank 2 | `debuffs_other` |
| [1108](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L710) | Curse of Weakness Rank 2 | `debuffs_other` |
| [1161](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L194) | Challenging Shout | `debuffs_taunts` |
| [1515](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L723) | Tame Beast | `debuffs_other` |
| [1714](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L653) | Curse of Tongues Rank 1 | `debuffs_casting_penalty` |
| [2908](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L724) | Soothe Animal Rank 1 | `debuffs_other` |
| [3034](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L744) | Viper Sting (mana drain) | `debuffs_other` |
| [3043](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L727) | Scorpid Sting | `debuffs_other` |
| [5138](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L728) | Drain Mana | `debuffs_other` |
| [5209](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L204) | Challenging Roar | `debuffs_taunts` |
| [5760](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L655) | Mind-numbing Poison Rank 1 | `debuffs_casting_penalty` |
| [6016](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L701) | Pierce Armor (NPC 50% armor reduction) | `debuffs_other` |
| [6205](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L711) | Curse of Weakness Rank 3 | `debuffs_other` |
| [6343](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L666) | Thunder Clap Rank 1 (Warrior attack-speed penalty) | `debuffs_attack_penalty` |
| [6795](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L202) | Growl | `debuffs_taunts` |
| [7068](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L677) | Veil of Shadow (75% healing reduction, single target) | `debuffs_healing_reduction` |
| [7386](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L729) | Sunder Armor | `debuffs_other` |
| [7400](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L196) | Mocking Blow Rank 2 | `debuffs_taunts` |
| [7402](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L197) | Mocking Blow Rank 3 | `debuffs_taunts` |
| [7405](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L730) | Sunder Armor | `debuffs_other` |
| [7646](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L712) | Curse of Weakness Rank 4 | `debuffs_other` |
| [7658](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L731) | Curse of Recklessness | `debuffs_other` |
| [8078](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L672) | Thunderclap (NPC attack-speed and movement penalty) | `debuffs_attack_penalty` |
| [8137](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L760) | Silithid Pox (ordinary StatusEffects) | `debuffs_res_sickness` |
| [8139](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L702) | Fevered Fatigue (applied Intellect/Spirit Disease) | `debuffs_other` |
| [8198](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L667) | Thunder Clap Rank 2 | `debuffs_attack_penalty` |
| [8204](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L668) | Thunder Clap Rank 3 | `debuffs_attack_penalty` |
| [8205](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L669) | Thunder Clap Rank 4 | `debuffs_attack_penalty` |
| [8267](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L703) | Cursed Blood (applied Intellect curse, including the dungeon report) | `debuffs_other` |
| [8272](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L652) | Mind Tremor (NPC casting-speed penalty) | `debuffs_casting_penalty` |
| [8647](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L732) | Expose Armor | `debuffs_other` |
| [8649](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L733) | Expose Armor | `debuffs_other` |
| [8692](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L656) | Mind-numbing Poison Rank 2 | `debuffs_casting_penalty` |
| [8955](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L725) | Soothe Animal Rank 2 | `debuffs_other` |
| [9035](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L688) | Hex of Weakness Rank 1 | `debuffs_healing_reduction` |
| [9749](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L706) | Faerie Fire Rank 3 | `debuffs_other` |
| [9901](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L726) | Soothe Animal Rank 3 | `debuffs_other` |
| [9907](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L707) | Faerie Fire Rank 4 | `debuffs_other` |
| [11398](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L657) | Mind-numbing Poison Rank 3 | `debuffs_casting_penalty` |
| [11580](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L670) | Thunder Clap Rank 5 | `debuffs_attack_penalty` |
| [11581](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L671) | Thunder Clap Rank 6 | `debuffs_attack_penalty` |
| [11707](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L713) | Curse of Weakness Rank 5 | `debuffs_other` |
| [11708](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L714) | Curse of Weakness Rank 6 | `debuffs_other` |
| [11719](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L654) | Curse of Tongues Rank 2 | `debuffs_casting_penalty` |
| [12294](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L680) | Mortal Strike Rank 1 | `debuffs_healing_reduction` |
| [12579](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L734) | Winter's Chill | `debuffs_other` |
| [13218](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L684) | Wound Poison Rank 1 (flat healing-received reduction) | `debuffs_healing_reduction` |
| [13222](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L685) | Wound Poison Rank 2 | `debuffs_healing_reduction` |
| [13223](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L686) | Wound Poison Rank 3 | `debuffs_healing_reduction` |
| [13224](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L687) | Wound Poison Rank 4 | `debuffs_healing_reduction` |
| [14279](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L745) | Viper Sting (mana drain) | `debuffs_other` |
| [14280](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L746) | Viper Sting (mana drain) | `debuffs_other` |
| [15258](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L735) | Shadow Weaving | `debuffs_other` |
| [15286](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L736) | Vampiric Embrace | `debuffs_other` |
| [16511](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L737) | Hemorrhage | `debuffs_other` |
| [17364](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L738) | Stormstrike | `debuffs_other` |
| [17820](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L678) | Veil of Shadow (75% healing reduction, nearby enemies) | `debuffs_healing_reduction` |
| [17877](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L747) | Shadowburn (create-item-on-death aura) | `debuffs_other` |
| [18867](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L748) | Shadowburn (create-item-on-death aura) | `debuffs_other` |
| [19281](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L689) | Hex of Weakness Rank 2 | `debuffs_healing_reduction` |
| [19282](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L690) | Hex of Weakness Rank 3 | `debuffs_healing_reduction` |
| [19283](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L691) | Hex of Weakness Rank 4 | `debuffs_healing_reduction` |
| [19284](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L692) | Hex of Weakness Rank 5 | `debuffs_healing_reduction` |
| [19285](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L693) | Hex of Weakness Rank 6 | `debuffs_healing_reduction` |
| [19577](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L228) | Intimidation | `debuffs_taunts` |
| [20232](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L208) | Judgement of Fury | `debuffs_taunts` |
| [20559](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L198) | Mocking Blow Rank 4 | `debuffs_taunts` |
| [20560](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L199) | Mocking Blow Rank 5 | `debuffs_taunts` |
| [21551](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L681) | Mortal Strike Rank 2 | `debuffs_healing_reduction` |
| [21552](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L682) | Mortal Strike Rank 3 | `debuffs_healing_reduction` |
| [21553](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L683) | Mortal Strike Rank 4 | `debuffs_healing_reduction` |
| [22959](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L739) | Fire Vulnerability | `debuffs_other` |
| [408681](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L217) | *Unlabeled in source* | `debuffs_taunts` |
| [408683](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L218) | *Unlabeled in source* | `debuffs_taunts` |
| [408685](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L219) | *Unlabeled in source* | `debuffs_taunts` |
| [408687](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L220) | *Unlabeled in source* | `debuffs_taunts` |
| [408688](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L221) | *Unlabeled in source* | `debuffs_taunts` |
| [408689](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L222) | *Unlabeled in source* | `debuffs_taunts` |
| [409372](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L211) | Growl | `debuffs_taunts` |
| [440892](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L740) | Curse of the Elements | `debuffs_other` |
| [442226](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L212) | Menace | `debuffs_taunts` |
| [460755](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L679) | Veil of Shadow (75% healing reduction, area variant) | `debuffs_healing_reduction` |
| [1213464](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L673) | Thunderclap (matching NPC applied variant) | `debuffs_attack_penalty` |
| [1218506](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L203) | Growl (Forever variant) | `debuffs_taunts` |
| [1219206](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L207) | Hand of Reckoning | `debuffs_taunts` |
| [1219379](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L216) | *Unlabeled in source* | `debuffs_taunts` |
| [1219475](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L213) | Menace (Forever variant) | `debuffs_taunts` |
| [1219541](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L193) | Taunt (Forever variant) | `debuffs_taunts` |
| [1220744](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L223) | *Unlabeled in source* | `debuffs_taunts` |
| [1220746](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L224) | *Unlabeled in source* | `debuffs_taunts` |
| [1220748](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L225) | *Unlabeled in source* | `debuffs_taunts` |
| [1220749](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L226) | *Unlabeled in source* | `debuffs_taunts` |
| [1220751](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L227) | *Unlabeled in source* | `debuffs_taunts` |
| [1225228](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L741) | Bane of Havoc | `debuffs_other` |
| [1264478](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L658) | Sonic Blast Rank 1 | `debuffs_casting_penalty` |
| [1264479](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L659) | Sonic Blast Rank 2 | `debuffs_casting_penalty` |
| [1264480](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L660) | Sonic Blast Rank 3 | `debuffs_casting_penalty` |
| [1264481](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L661) | Sonic Blast Rank 4 | `debuffs_casting_penalty` |
| [1264482](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L662) | Sonic Blast Rank 5 | `debuffs_casting_penalty` |
| [1264758](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L694) | Dismember Rank 1 | `debuffs_healing_reduction` |
| [1264927](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L695) | Dismember Rank 2 | `debuffs_healing_reduction` |
| [1264929](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L696) | Dismember Rank 3 | `debuffs_healing_reduction` |
| [1264930](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L697) | Dismember Rank 4 | `debuffs_healing_reduction` |
| [1264933](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L698) | Dismember Rank 5 | `debuffs_healing_reduction` |
| [1265899](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L742) | Dust Cloud | `debuffs_other` |
| [1265901](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L717) | Dust Cloud | `debuffs_other` |
| [1277455](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L229) | Confounding Flash | `debuffs_taunts` |
| [1302342](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L663) | Carved Mind (applied casting-time penalty) | `debuffs_casting_penalty` |
| [1311676](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L743) | Curse of the Elements | `debuffs_other` |
| [1316382](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L674) | Dust Storm (applied attack-hit penalty) | `debuffs_attack_penalty` |
| [1316387](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L767) | Muculent Rot (applied Spirit/Stamina Disease) | `debuffs_environmental_danger` |
| [1323184](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L766) | Shark Attack (Darkspear Islands water hazard) | `debuffs_environmental_danger` |

<a id="tier-251-healing"></a>
### 251 — Healing

**Exact spell tier** · `HELPFUL`

**67 exact spells.** Source sets: `buffs_shield`, `buffs_hots`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [136](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L905) | Mend Pet | `buffs_hots` |
| [139](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L906) | Renew | `buffs_hots` |
| [543](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L460) | Fire Ward | `buffs_shield` |
| [740](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L907) | Tranquility | `buffs_hots` |
| [746](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L928) | Linen Bandage | `buffs_hots` |
| [755](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L908) | Health Funnel | `buffs_hots` |
| [774](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L909) | Rejuvenation | `buffs_hots` |
| [1058](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L910) | Rejuvenation | `buffs_hots` |
| [1159](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L929) | Heavy Linen Bandage | `buffs_hots` |
| [1430](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L911) | Rejuvenation | `buffs_hots` |
| [1463](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L470) | Mana Shield | `buffs_shield` |
| [2090](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L912) | Rejuvenation | `buffs_hots` |
| [2091](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L913) | Rejuvenation | `buffs_hots` |
| [3111](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L914) | Mend Pet | `buffs_hots` |
| [3267](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L930) | Wool Bandage | `buffs_hots` |
| [3268](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L931) | Heavy Wool Bandage | `buffs_hots` |
| [3661](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L915) | Mend Pet | `buffs_hots` |
| [3698](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L916) | Health Funnel | `buffs_hots` |
| [3699](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L917) | Health Funnel | `buffs_hots` |
| [6074](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L918) | Renew | `buffs_hots` |
| [6075](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L919) | Renew | `buffs_hots` |
| [6076](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L920) | Renew | `buffs_hots` |
| [6143](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L465) | Frost Ward | `buffs_shield` |
| [6229](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L450) | Shadow Ward | `buffs_shield` |
| [7812](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L454) | Sacrifice | `buffs_shield` |
| [7926](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L932) | Silk Bandage | `buffs_hots` |
| [7927](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L933) | Heavy Silk Bandage | `buffs_hots` |
| [8457](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L461) | Fire Ward | `buffs_shield` |
| [8458](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L462) | Fire Ward | `buffs_shield` |
| [8461](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L466) | Frost Ward | `buffs_shield` |
| [8462](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L467) | Frost Ward | `buffs_shield` |
| [8494](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L471) | Mana Shield | `buffs_shield` |
| [8495](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L472) | Mana Shield | `buffs_shield` |
| [8936](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L921) | Regrowth | `buffs_hots` |
| [8938](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L922) | Regrowth | `buffs_hots` |
| [8939](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L923) | Regrowth | `buffs_hots` |
| [8940](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L924) | Regrowth | `buffs_hots` |
| [10177](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L468) | Frost Ward | `buffs_shield` |
| [10191](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L473) | Mana Shield | `buffs_shield` |
| [10192](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L474) | Mana Shield | `buffs_shield` |
| [10193](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L475) | Mana Shield | `buffs_shield` |
| [10223](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L463) | Fire Ward | `buffs_shield` |
| [10225](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L464) | Fire Ward | `buffs_shield` |
| [10838](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L934) | Mageweave Bandage | `buffs_hots` |
| [10839](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L935) | Heavy Mageweave Bandage | `buffs_hots` |
| [11739](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L451) | Shadow Ward | `buffs_shield` |
| [11740](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L452) | Shadow Ward | `buffs_shield` |
| [16488](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L925) | Blood Craze | `buffs_hots` |
| [17767](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L904) | Consume Shadows | `buffs_hots` |
| [17850](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L926) | Consume Shadows | `buffs_hots` |
| [18608](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L936) | Runecloth Bandage | `buffs_hots` |
| [18610](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L937) | Heavy Runecloth Bandage | `buffs_hots` |
| [18956](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L903) | Restore Life (Orb of Soran'ruk on-use periodic heal) | `buffs_hots` |
| [19438](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L455) | Sacrifice | `buffs_shield` |
| [19440](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L456) | Sacrifice | `buffs_shield` |
| [19441](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L457) | Sacrifice | `buffs_shield` |
| [19442](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L458) | Sacrifice | `buffs_shield` |
| [19443](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L459) | Sacrifice | `buffs_shield` |
| [23567](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L938) | Warsong Gulch Runecloth Bandage | `buffs_hots` |
| [23568](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L939) | Warsong Gulch Mageweave Bandage | `buffs_hots` |
| [23569](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L940) | Warsong Gulch Silk Bandage | `buffs_hots` |
| [23696](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L941) | Alterac Heavy Runecloth Bandage | `buffs_hots` |
| [24412](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L942) | Arathi Basin Silk Bandage | `buffs_hots` |
| [24413](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L943) | Arathi Basin Mageweave Bandage | `buffs_hots` |
| [24414](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L944) | Arathi Basin Runecloth Bandage | `buffs_hots` |
| [28609](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L469) | Frost Ward | `buffs_shield` |
| [28610](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L453) | Shadow Ward | `buffs_shield` |

<a id="tier-240-forbearance"></a>
### 240 — Forbearance

**Exact spell tier** · `HARMFUL`

**1 exact spells.** Source sets: `debuffs_priority`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [25771](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L755) | Forbearance (Paladin) | `debuffs_priority` |

<a id="tier-238-prioritydebuff"></a>
### 238 — PriorityDebuff

**Native semantic fallback** · `HARMFUL`

No enumerable spell-ID set: Blizzard chooses from currently eligible auras using the native candidate filter.

Native candidate rules:

```lua
{ isPriorityAura = true }
```

<a id="tier-230-wounds"></a>
### 230 — Wounds

**Exact spell tier** · `HARMFUL`

**4 exact spells.** Source sets: `debuffs_weakenedsoul`, `debuffs_recently_bandaged`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [3436](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L788) | Wandering Plague (initial applied Disease) | `debuffs_recently_bandaged` |
| [3439](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L789) | Wandering Plague (spread Disease) | `debuffs_recently_bandaged` |
| [6788](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L785) | Weakened Soul (Priest) | `debuffs_weakenedsoul` |
| [11196](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L790) | Recently Bandaged | `debuffs_recently_bandaged` |

<a id="tier-225-utility"></a>
### 225 — Utility

**Exact spell tier** · `HELPFUL\|INCLUDE_NAME_PLATE_ONLY`

**24 exact spells.** Source sets: `buffs_utility`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [130](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L534) | Slow Fall | `buffs_utility` |
| [1002](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L519) | Eyes of the Beast (Hunter) | `buffs_utility` |
| [1539](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L535) | Feed Pet Effect | `buffs_utility` |
| [1725](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L536) | Distract | `buffs_utility` |
| [4511](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L537) | Phase Shift | `buffs_utility` |
| [6346](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L527) | Fear Ward | `buffs_utility` |
| [16689](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L528) | Nature's Grasp Rank 1 | `buffs_utility` |
| [16810](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L529) | Nature's Grasp Rank 2 | `buffs_utility` |
| [16811](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L530) | Nature's Grasp Rank 3 | `buffs_utility` |
| [16812](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L531) | Nature's Grasp Rank 4 | `buffs_utility` |
| [16813](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L532) | Nature's Grasp Rank 5 | `buffs_utility` |
| [17329](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L533) | Nature's Grasp Rank 6 | `buffs_utility` |
| [18288](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L538) | Amplify Curse | `buffs_utility` |
| [18708](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L539) | Fel Domination | `buffs_utility` |
| [20707](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L520) | Soulstone Resurrection Rank 1 | `buffs_utility` |
| [20762](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L521) | Soulstone Resurrection Rank 2 | `buffs_utility` |
| [20763](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L522) | Soulstone Resurrection Rank 3 | `buffs_utility` |
| [20764](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L523) | Soulstone Resurrection Rank 4 | `buffs_utility` |
| [20765](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L524) | Soulstone Resurrection Rank 5 | `buffs_utility` |
| [1259416](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L516) | Walk on Air (Skyborne racial, 10 sec) | `buffs_utility` |
| [1259691](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L525) | Energized (Read Ley Line, 15 min) | `buffs_utility` |
| [1260270](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L518) | Rapid Regeneration (Troll racial, Forever) | `buffs_utility` |
| [1270842](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L526) | Energized (Read Ley Line, 15 sec) | `buffs_utility` |
| [1308663](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L517) | Walk on Air (Forever variant, 1 min) | `buffs_utility` |

<a id="tier-210-seal"></a>
### 210 — Seal

**Exact spell tier** · `HELPFUL`

**23 exact spells.** Source sets: `buffs_seals`, `buffs_improved_stormstrike`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [20154](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L796) | Seal of Righteousness Rank 1 (Paladin) | `buffs_seals` |
| [20162](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L806) | Seal of the Crusader Rank 2 (Paladin) | `buffs_seals` |
| [20163](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L811) | Seal of Fury | `buffs_seals` |
| [20164](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L812) | Seal of Justice | `buffs_seals` |
| [20165](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L813) | Seal of Light | `buffs_seals` |
| [20287](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L797) | Seal of Righteousness Rank 2 (Paladin) | `buffs_seals` |
| [20288](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L798) | Seal of Righteousness Rank 3 (Paladin) | `buffs_seals` |
| [20289](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L799) | Seal of Righteousness Rank 4 (Paladin) | `buffs_seals` |
| [20290](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L800) | Seal of Righteousness Rank 5 (Paladin) | `buffs_seals` |
| [20291](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L801) | Seal of Righteousness Rank 6 (Paladin) | `buffs_seals` |
| [20292](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L802) | Seal of Righteousness Rank 7 (Paladin) | `buffs_seals` |
| [20293](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L803) | Seal of Righteousness Rank 8 (Paladin) | `buffs_seals` |
| [20305](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L807) | Seal of the Crusader Rank 3 (Paladin) | `buffs_seals` |
| [20306](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L808) | Seal of the Crusader Rank 4 (Paladin) | `buffs_seals` |
| [20307](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L809) | Seal of the Crusader Rank 5 (Paladin) | `buffs_seals` |
| [20308](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L810) | Seal of the Crusader Rank 6 (Paladin) | `buffs_seals` |
| [20375](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L814) | Seal of Command | `buffs_seals` |
| [20915](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L815) | Seal of Command | `buffs_seals` |
| [21082](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L805) | Seal of the Crusader Rank 1 (Paladin) | `buffs_seals` |
| [21084](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L804) | Seal of Righteousness Rank 1 alternate aura ID (Paladin) | `buffs_seals` |
| [1238931](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L793) | Improved Stormstrike (mana-regeneration proc) | `buffs_improved_stormstrike` |
| [1311649](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L816) | Seal of Fury | `buffs_seals` |
| [1311656](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L817) | Seal of Fury | `buffs_seals` |

<a id="tier-190-dots"></a>
### 190 — DoTs

**Exact spell tier** · `HARMFUL`

**149 exact spells.** Source sets: `debuffs_dots`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [133](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L245) | *Unlabeled in source* | `debuffs_dots` |
| [143](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L245) | *Unlabeled in source* | `debuffs_dots` |
| [145](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L245) | *Unlabeled in source* | `debuffs_dots` |
| [172](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L259) | *Unlabeled in source* | `debuffs_dots` |
| [348](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L263) | *Unlabeled in source* | `debuffs_dots` |
| [589](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L253) | *Unlabeled in source* | `debuffs_dots` |
| [594](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L253) | *Unlabeled in source* | `debuffs_dots` |
| [703](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L283) | Garrote | `debuffs_dots` |
| [707](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L263) | *Unlabeled in source* | `debuffs_dots` |
| [772](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L288) | *Unlabeled in source* | `debuffs_dots` |
| [970](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L253) | *Unlabeled in source* | `debuffs_dots` |
| [980](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L261) | *Unlabeled in source* | `debuffs_dots` |
| [992](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L253) | *Unlabeled in source* | `debuffs_dots` |
| [1014](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L261) | *Unlabeled in source* | `debuffs_dots` |
| [1079](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L279) | Rip | `debuffs_dots` |
| [1094](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L263) | *Unlabeled in source* | `debuffs_dots` |
| [1120](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L237) | *Unlabeled in source* | `debuffs_dots` |
| [1822](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L278) | Rake | `debuffs_dots` |
| [1823](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L278) | Rake | `debuffs_dots` |
| [1824](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L278) | Rake | `debuffs_dots` |
| [1943](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L284) | Rupture | `debuffs_dots` |
| [1978](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L269) | *Unlabeled in source* | `debuffs_dots` |
| [2767](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L254) | Shadow Word: Pain | `debuffs_dots` |
| [2818](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L285) | Deadly Poison debuff | `debuffs_dots` |
| [2941](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L263) | *Unlabeled in source* | `debuffs_dots` |
| [2944](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L255) | *Unlabeled in source* | `debuffs_dots` |
| [3140](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L245) | *Unlabeled in source* | `debuffs_dots` |
| [3815](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L238) | Poison Cloud (Ironspine, periodic Poison) | `debuffs_dots` |
| [5570](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L277) | Insect Swarm | `debuffs_dots` |
| [6217](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L261) | *Unlabeled in source* | `debuffs_dots` |
| [6222](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L259) | *Unlabeled in source* | `debuffs_dots` |
| [6223](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L259) | *Unlabeled in source* | `debuffs_dots` |
| [6546](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L288) | *Unlabeled in source* | `debuffs_dots` |
| [6547](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L288) | *Unlabeled in source* | `debuffs_dots` |
| [6548](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L288) | *Unlabeled in source* | `debuffs_dots` |
| [7648](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L259) | *Unlabeled in source* | `debuffs_dots` |
| [8050](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L291) | Flame Shock | `debuffs_dots` |
| [8052](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L291) | Flame Shock | `debuffs_dots` |
| [8053](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L291) | Flame Shock | `debuffs_dots` |
| [8288](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L237) | *Unlabeled in source* | `debuffs_dots` |
| [8289](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L237) | *Unlabeled in source* | `debuffs_dots` |
| [8400](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L246) | *Unlabeled in source* | `debuffs_dots` |
| [8401](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L246) | *Unlabeled in source* | `debuffs_dots` |
| [8402](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L246) | *Unlabeled in source* | `debuffs_dots` |
| [8631](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L283) | Garrote | `debuffs_dots` |
| [8632](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L283) | Garrote | `debuffs_dots` |
| [8633](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L283) | Garrote | `debuffs_dots` |
| [8639](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L284) | Rupture | `debuffs_dots` |
| [8640](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L284) | Rupture | `debuffs_dots` |
| [8921](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L274) | *Unlabeled in source* | `debuffs_dots` |
| [8924](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L274) | *Unlabeled in source* | `debuffs_dots` |
| [8925](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L274) | *Unlabeled in source* | `debuffs_dots` |
| [8926](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L274) | *Unlabeled in source* | `debuffs_dots` |
| [8927](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L275) | *Unlabeled in source* | `debuffs_dots` |
| [8928](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L275) | *Unlabeled in source* | `debuffs_dots` |
| [8929](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L275) | *Unlabeled in source* | `debuffs_dots` |
| [9007](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L280) | Pounce bleed | `debuffs_dots` |
| [9492](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L279) | Rip | `debuffs_dots` |
| [9493](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L279) | Rip | `debuffs_dots` |
| [9752](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L279) | Rip | `debuffs_dots` |
| [9824](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L280) | Pounce bleed | `debuffs_dots` |
| [9826](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L280) | Pounce bleed | `debuffs_dots` |
| [9833](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L275) | *Unlabeled in source* | `debuffs_dots` |
| [9834](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L276) | Moonfire | `debuffs_dots` |
| [9835](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L276) | Moonfire | `debuffs_dots` |
| [9894](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L279) | Rip | `debuffs_dots` |
| [9896](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L279) | Rip | `debuffs_dots` |
| [9904](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L278) | Rake | `debuffs_dots` |
| [10148](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L247) | Fireball | `debuffs_dots` |
| [10149](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L247) | Fireball | `debuffs_dots` |
| [10150](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L247) | Fireball | `debuffs_dots` |
| [10151](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L247) | Fireball | `debuffs_dots` |
| [10447](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L291) | Flame Shock | `debuffs_dots` |
| [10448](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L291) | Flame Shock | `debuffs_dots` |
| [10797](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L294) | Starshards | `debuffs_dots` |
| [10892](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L254) | Shadow Word: Pain | `debuffs_dots` |
| [10893](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L254) | Shadow Word: Pain | `debuffs_dots` |
| [10894](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L254) | Shadow Word: Pain | `debuffs_dots` |
| [11273](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L284) | Rupture | `debuffs_dots` |
| [11274](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L284) | Rupture | `debuffs_dots` |
| [11275](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L284) | Rupture | `debuffs_dots` |
| [11289](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L283) | Garrote | `debuffs_dots` |
| [11290](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L283) | Garrote | `debuffs_dots` |
| [11366](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L248) | *Unlabeled in source* | `debuffs_dots` |
| [11572](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L289) | Rend | `debuffs_dots` |
| [11573](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L289) | Rend | `debuffs_dots` |
| [11574](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L289) | Rend | `debuffs_dots` |
| [11665](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L264) | Immolate | `debuffs_dots` |
| [11667](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L264) | Immolate | `debuffs_dots` |
| [11668](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L264) | Immolate | `debuffs_dots` |
| [11671](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L260) | Corruption | `debuffs_dots` |
| [11672](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L260) | Corruption | `debuffs_dots` |
| [11675](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L237) | *Unlabeled in source* | `debuffs_dots` |
| [11711](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L261) | *Unlabeled in source* | `debuffs_dots` |
| [11712](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L262) | Curse of Agony | `debuffs_dots` |
| [11713](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L262) | Curse of Agony | `debuffs_dots` |
| [12505](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L248) | *Unlabeled in source* | `debuffs_dots` |
| [12522](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L248) | *Unlabeled in source* | `debuffs_dots` |
| [12523](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L248) | *Unlabeled in source* | `debuffs_dots` |
| [12524](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L249) | Pyroblast | `debuffs_dots` |
| [12525](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L249) | Pyroblast | `debuffs_dots` |
| [12526](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L249) | Pyroblast | `debuffs_dots` |
| [12654](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L250) | Ignite | `debuffs_dots` |
| [12721](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L290) | Deep Wounds periodic debuff | `debuffs_dots` |
| [13549](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L269) | *Unlabeled in source* | `debuffs_dots` |
| [13550](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L269) | *Unlabeled in source* | `debuffs_dots` |
| [13551](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L269) | *Unlabeled in source* | `debuffs_dots` |
| [13552](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L270) | Serpent Sting | `debuffs_dots` |
| [13553](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L270) | Serpent Sting | `debuffs_dots` |
| [13554](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L270) | Serpent Sting | `debuffs_dots` |
| [13555](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L270) | Serpent Sting | `debuffs_dots` |
| [13797](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L271) | Immolation Trap effect | `debuffs_dots` |
| [14298](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L271) | Immolation Trap effect | `debuffs_dots` |
| [14299](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L271) | Immolation Trap effect | `debuffs_dots` |
| [14300](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L271) | Immolation Trap effect | `debuffs_dots` |
| [14301](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L271) | Immolation Trap effect | `debuffs_dots` |
| [14914](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L295) | Holy Fire | `debuffs_dots` |
| [15262](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L296) | Holy Fire | `debuffs_dots` |
| [15263](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L297) | Holy Fire | `debuffs_dots` |
| [18265](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L265) | *Unlabeled in source* | `debuffs_dots` |
| [18809](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L249) | Pyroblast | `debuffs_dots` |
| [18879](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L265) | *Unlabeled in source* | `debuffs_dots` |
| [18880](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L265) | *Unlabeled in source* | `debuffs_dots` |
| [18881](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L265) | *Unlabeled in source* | `debuffs_dots` |
| [18927](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L266) | Siphon Life | `debuffs_dots` |
| [18928](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L266) | Siphon Life | `debuffs_dots` |
| [18929](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L266) | Siphon Life | `debuffs_dots` |
| [19276](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L255) | *Unlabeled in source* | `debuffs_dots` |
| [19277](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L255) | *Unlabeled in source* | `debuffs_dots` |
| [19278](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L255) | *Unlabeled in source* | `debuffs_dots` |
| [19279](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L256) | Devouring Plague | `debuffs_dots` |
| [19280](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L256) | Devouring Plague | `debuffs_dots` |
| [19296](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L298) | Starshards | `debuffs_dots` |
| [19299](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L299) | Starshards | `debuffs_dots` |
| [24118](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L300) | Lacerate | `debuffs_dots` |
| [24583](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L301) | Scorpid Poison | `debuffs_dots` |
| [24640](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L302) | Scorpid Poison | `debuffs_dots` |
| [24974](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L277) | Insect Swarm | `debuffs_dots` |
| [24975](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L277) | Insect Swarm | `debuffs_dots` |
| [24976](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L277) | Insect Swarm | `debuffs_dots` |
| [24977](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L277) | Insect Swarm | `debuffs_dots` |
| [25295](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L270) | Serpent Sting | `debuffs_dots` |
| [25306](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L247) | Fireball | `debuffs_dots` |
| [25309](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L264) | Immolate | `debuffs_dots` |
| [25311](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L260) | Corruption | `debuffs_dots` |
| [1231579](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L242) | Rapid Poison (Nature, 6 sec) | `debuffs_dots` |
| [1231580](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L243) | Foul Disease (Shadow, 12 sec) | `debuffs_dots` |
| [1265065](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L293) | Savage Rend | `debuffs_dots` |
| [1265066](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L303) | Savage Rend | `debuffs_dots` |

<a id="tier-189-consecration"></a>
### 189 — Consecration

**Exact spell tier** · `HARMFUL`

**1 exact spells.** Source sets: `debuffs_consecration`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [1280353](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L232) | Consecration (Forever applied damage-amplification aura) | `debuffs_consecration` |

<a id="tier-185-demoralizing"></a>
### 185 — Demoralizing

**Exact spell tier** · `HARMFUL`

**18 exact spells.** Source sets: `debuffs_demoralizing`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [99](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L639) | Demoralizing Roar Rank 1 | `debuffs_demoralizing` |
| [1160](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L634) | Demoralizing Shout Rank 1 | `debuffs_demoralizing` |
| [1735](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L640) | Demoralizing Roar Rank 2 | `debuffs_demoralizing` |
| [6190](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L635) | Demoralizing Shout Rank 2 | `debuffs_demoralizing` |
| [9490](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L641) | Demoralizing Roar Rank 3 | `debuffs_demoralizing` |
| [9747](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L642) | Demoralizing Roar Rank 4 | `debuffs_demoralizing` |
| [9898](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L643) | Demoralizing Roar Rank 5 | `debuffs_demoralizing` |
| [11554](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L636) | Demoralizing Shout Rank 3 | `debuffs_demoralizing` |
| [11555](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L637) | Demoralizing Shout Rank 4 | `debuffs_demoralizing` |
| [11556](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L638) | Demoralizing Shout Rank 5 | `debuffs_demoralizing` |
| [13730](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L630) | Demoralizing Shout (NPC applied variant) | `debuffs_demoralizing` |
| [16244](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L631) | Demoralizing Shout (NPC applied variant) | `debuffs_demoralizing` |
| [19778](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L632) | Demoralizing Shout (NPC applied variant) | `debuffs_demoralizing` |
| [24423](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L644) | Demoralizing Screech Rank 1 (Hunter pet) | `debuffs_demoralizing` |
| [24577](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L645) | Demoralizing Screech Rank 2 (Hunter pet) | `debuffs_demoralizing` |
| [24578](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L646) | Demoralizing Screech Rank 3 (Hunter pet) | `debuffs_demoralizing` |
| [24579](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L647) | Demoralizing Screech Rank 4 (Hunter pet) | `debuffs_demoralizing` |
| [27579](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L633) | Demoralizing Shout (NPC applied variant) | `debuffs_demoralizing` |

<a id="tier-180-huntersmark"></a>
### 180 — HuntersMark

**Exact spell tier** · `HARMFUL\|INCLUDE_NAME_PLATE_ONLY`

**5 exact spells.** Source sets: `debuffs_hunters_mark`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [1130](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L622) | Hunter's Mark Rank 1 | `debuffs_hunters_mark` |
| [14323](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L623) | Hunter's Mark Rank 2 | `debuffs_hunters_mark` |
| [14324](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L624) | Hunter's Mark Rank 3 | `debuffs_hunters_mark` |
| [14325](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L625) | Hunter's Mark Rank 4 | `debuffs_hunters_mark` |
| [1213268](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L626) | Hunter's Mark Rank 4 (Forever alternate aura) | `debuffs_hunters_mark` |

<a id="tier-175-smallfriendlyharmful"></a>
### 175 — SmallFriendlyHarmful

**Native semantic fallback** · `HARMFUL\|INCLUDE_NAME_PLATE_ONLY`

No enumerable spell-ID set: Blizzard chooses from currently eligible auras using the native candidate filter.

No additional candidate rules are specified.

<a id="tier-170-lonewolf"></a>
### 170 — LoneWolf

**Exact spell tier** · `HELPFUL\|INCLUDE_NAME_PLATE_ONLY`

**1 exact spells.** Source sets: `buffs_lone_wolf`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [1310684](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1432) | Lone Wolf visible buff (Forever) | `buffs_lone_wolf` |

<a id="tier-160-mobility"></a>
### 160 — Mobility

**Exact spell tier** · `HELPFUL\|INCLUDE_NAME_PLATE_ONLY`

**16 exact spells.** Source sets: `buffs_ghostwolf`, `buffs_ghostwolf_variants`, `buffs_cheetah`, `buffs_mobility`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [586](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1343) | Fade | `buffs_mobility` |
| [2645](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1435) | Ghost Wolf (Shaman) | `buffs_ghostwolf` |
| [5118](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1442) | Aspect of the Cheetah (Hunter) | `buffs_cheetah` |
| [5384](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1342) | Feign Death | `buffs_mobility` |
| [7371](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1350) | Charge | `buffs_mobility` |
| [9578](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1344) | Fade | `buffs_mobility` |
| [9579](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1345) | Fade | `buffs_mobility` |
| [11327](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1346) | Vanish | `buffs_mobility` |
| [23099](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1347) | Dash | `buffs_mobility` |
| [23145](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1348) | Dive | `buffs_mobility` |
| [24450](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1349) | Prowl | `buffs_mobility` |
| [26177](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1351) | Charge | `buffs_mobility` |
| [26178](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1352) | Charge | `buffs_mobility` |
| [415233](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1438) | Ghost Wolf (Forever variant) | `buffs_ghostwolf_variants` |
| [1238640](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1439) | Ghost Wolf (Forever alternate/rank variant) | `buffs_ghostwolf_variants` |
| [1317257](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1353) | Strider Kick | `buffs_mobility` |

<a id="tier-150-selfstate"></a>
### 150 — SelfState

**Exact spell tier** · `HELPFUL`

**55 exact spells.** Source sets: `buffs_other`, `buffs_frost_armor`, `buffs_lightning_shield`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [168](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1454) | Frost Armor Rank 1 (Mage) | `buffs_frost_armor` |
| [324](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1421) | Lightning Shield Rank 1 | `buffs_lightning_shield` |
| [325](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1422) | Lightning Shield Rank 2 | `buffs_lightning_shield` |
| [588](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1473) | Inner Fire Rank 1 (Priest) | `buffs_other` |
| [602](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1475) | Inner Fire Rank 3 (Priest) | `buffs_other` |
| [768](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1486) | Cat Form | `buffs_other` |
| [783](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1487) | Travel Form | `buffs_other` |
| [905](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1423) | Lightning Shield Rank 3 | `buffs_lightning_shield` |
| [945](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1424) | Lightning Shield Rank 4 | `buffs_lightning_shield` |
| [1006](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1476) | Inner Fire Rank 4 (Priest) | `buffs_other` |
| [1784](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1501) | Stealth Rank 1 (Rogue) | `buffs_other` |
| [1785](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1502) | Stealth Rank 2 (Rogue) | `buffs_other` |
| [1786](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1503) | Stealth Rank 3 (Rogue) | `buffs_other` |
| [1787](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1504) | Stealth Rank 4 (Rogue) | `buffs_other` |
| [2652](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1479) | Touch of Weakness Rank 1 (Undead Priest) | `buffs_other` |
| [5215](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1498) | Prowl Rank 1 (Druid) | `buffs_other` |
| [5487](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1485) | Bear Form | `buffs_other` |
| [6783](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1499) | Prowl Rank 2 (Druid) | `buffs_other` |
| [7128](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1474) | Inner Fire Rank 2 (Priest) | `buffs_other` |
| [7300](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1455) | Frost Armor Rank 2 (Mage) | `buffs_frost_armor` |
| [7301](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1456) | Frost Armor Rank 3 (Mage) | `buffs_frost_armor` |
| [8134](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1425) | Lightning Shield Rank 5 | `buffs_lightning_shield` |
| [9913](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1500) | Prowl Rank 3 (Druid) | `buffs_other` |
| [10431](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1426) | Lightning Shield Rank 6 | `buffs_lightning_shield` |
| [10432](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1427) | Lightning Shield Rank 7 | `buffs_lightning_shield` |
| [10951](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1477) | Inner Fire Rank 5 (Priest) | `buffs_other` |
| [10952](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1478) | Inner Fire Rank 6 (Priest) | `buffs_other` |
| [12544](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1457) | Frost Armor (NPC/Forever visible variant) | `buffs_frost_armor` |
| [13163](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1489) | Aspect of the Monkey (Hunter) | `buffs_other` |
| [13165](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1490) | Aspect of the Hawk Rank 1 | `buffs_other` |
| [14318](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1491) | Aspect of the Hawk Rank 2 | `buffs_other` |
| [14319](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1492) | Aspect of the Hawk Rank 3 | `buffs_other` |
| [14320](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1493) | Aspect of the Hawk Rank 4 | `buffs_other` |
| [14321](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1494) | Aspect of the Hawk Rank 5 | `buffs_other` |
| [14322](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1495) | Aspect of the Hawk Rank 6 | `buffs_other` |
| [15784](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1458) | Frost Armor (NPC/Forever ally-target variant) | `buffs_frost_armor` |
| [18137](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1467) | Shadowguard Rank 1 (Troll Priest) | `buffs_other` |
| [18789](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1465) | Burning Shadow (Demonic Sacrifice effect; forms/Self State) | `buffs_other` |
| [19261](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1480) | Touch of Weakness Rank 2 (Undead Priest) | `buffs_other` |
| [19262](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1481) | Touch of Weakness Rank 3 (Undead Priest) | `buffs_other` |
| [19264](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1482) | Touch of Weakness Rank 4 (Undead Priest) | `buffs_other` |
| [19265](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1483) | Touch of Weakness Rank 5 (Undead Priest) | `buffs_other` |
| [19266](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1484) | Touch of Weakness Rank 6 (Undead Priest) | `buffs_other` |
| [19308](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1468) | Shadowguard Rank 2 (Troll Priest) | `buffs_other` |
| [19309](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1469) | Shadowguard Rank 3 (Troll Priest) | `buffs_other` |
| [19310](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1470) | Shadowguard Rank 4 (Troll Priest) | `buffs_other` |
| [19311](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1471) | Shadowguard Rank 5 (Troll Priest) | `buffs_other` |
| [19312](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1472) | Shadowguard Rank 6 (Troll Priest) | `buffs_other` |
| [20580](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1497) | Shadowmeld (Night Elf racial) | `buffs_other` |
| [23605](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1466) | *Unlabeled in source* | `buffs_other` |
| [24858](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1488) | Moonkin Form | `buffs_other` |
| [25228](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1464) | Soul Link (applied Warlock/demon aura) | `buffs_other` |
| [25296](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1496) | Aspect of the Hawk Rank 7 | `buffs_other` |
| [408510](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1428) | Water Shield (Forever) | `buffs_lightning_shield` |
| [408514](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1429) | Earth Shield (Forever) | `buffs_lightning_shield` |

<a id="tier-120-thorns"></a>
### 120 — Thorns

**Exact spell tier** · `HELPFUL`

**12 exact spells.** Source sets: `buffs_thorns`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [467](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L977) | Thorns Rank 1 (Druid) | `buffs_thorns` |
| [782](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L978) | Thorns Rank 2 (Druid) | `buffs_thorns` |
| [1075](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L979) | Thorns Rank 3 (Druid) | `buffs_thorns` |
| [2947](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L983) | Fire Shield Rank 1 (Imp) | `buffs_thorns` |
| [8316](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L984) | Fire Shield Rank 2 (Imp) | `buffs_thorns` |
| [8317](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L985) | Fire Shield Rank 3 (Imp) | `buffs_thorns` |
| [8914](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L980) | Thorns Rank 4 (Druid) | `buffs_thorns` |
| [9756](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L981) | Thorns Rank 5 (Druid) | `buffs_thorns` |
| [9910](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L982) | Thorns Rank 6 (Druid) | `buffs_thorns` |
| [11770](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L986) | Fire Shield Rank 4 (Imp) | `buffs_thorns` |
| [11771](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L987) | Fire Shield Rank 5 (Imp) | `buffs_thorns` |
| [1303458](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L976) | Reflection Field (spell reflection, Thorns-like counterattack priority) | `buffs_thorns` |

<a id="tier-110-wellfed"></a>
### 110 — WellFed

**Exact spell tier** · `HELPFUL`

**23 exact spells.** Source sets: `buffs_well_fed`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [6114](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1360) | Raptor Punch: persistent 5-minute stat aura, not item 5342 | `buffs_well_fed` |
| [19705](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1362) | Well Fed: +2 Stamina/Spirit | `buffs_well_fed` |
| [19706](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1363) | Well Fed: +4 Stamina/Spirit | `buffs_well_fed` |
| [19708](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1364) | Well Fed: +6 Stamina/Spirit | `buffs_well_fed` |
| [19709](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1365) | Well Fed: +8 Stamina/Spirit | `buffs_well_fed` |
| [19710](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1366) | Well Fed: +12 Stamina/Spirit | `buffs_well_fed` |
| [19711](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1367) | Well Fed: +14 Stamina/Spirit | `buffs_well_fed` |
| [24799](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1368) | Well Fed: +20 Strength | `buffs_well_fed` |
| [24870](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1369) | Well Fed: level-scaled Stamina/Spirit | `buffs_well_fed` |
| [1225778](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1370) | Forever Well Fed: Strength + Stamina | `buffs_well_fed` |
| [1225779](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1371) | Forever Well Fed: Agility + Stamina | `buffs_well_fed` |
| [1225780](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1372) | Forever Well Fed: Spell Damage/Healing + Stamina | `buffs_well_fed` |
| [1225782](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1373) | Forever Well Fed: AP/Spell/Healing + Stamina | `buffs_well_fed` |
| [1248406](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1374) | Forever Well Fed: +1 Stamina | `buffs_well_fed` |
| [1248421](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1375) | Forever Well Fed: Intellect | `buffs_well_fed` |
| [1248422](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1376) | Forever Well Fed: Strength | `buffs_well_fed` |
| [1248688](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1380) | Forever Well Fed: movement speed (Westfall) | `buffs_well_fed` |
| [1249519](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1377) | Forever Well Fed: Attack Power | `buffs_well_fed` |
| [1249520](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1378) | Forever Well Fed: Spell Damage | `buffs_well_fed` |
| [1249523](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1379) | Forever Well Fed: Critical Strike | `buffs_well_fed` |
| [1249926](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1381) | Forever Well Fed: Spirit | `buffs_well_fed` |
| [1294007](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1382) | Forever Well Fed: movement speed (Hyjal) | `buffs_well_fed` |
| [1302064](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1383) | Forever Well Fed: Strength variant | `buffs_well_fed` |

<a id="tier-90-baselineclass"></a>
### 90 — BaselineClass

**Exact spell tier** · `HELPFUL`

**69 exact spells.** Source sets: `buffs_class_baseline`, `buffs_camp_benefits`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [604](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1270) | Dampen Magic | `buffs_class_baseline` |
| [976](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1273) | Shadow Protection | `buffs_class_baseline` |
| [1008](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1274) | Amplify Magic | `buffs_class_baseline` |
| [1038](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1261) | *Unlabeled in source* | `buffs_class_baseline` |
| [1126](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1211) | *Unlabeled in source* | `buffs_class_baseline` |
| [1243](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1201) | *Unlabeled in source* | `buffs_class_baseline` |
| [1244](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1202) | *Unlabeled in source* | `buffs_class_baseline` |
| [1245](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1203) | *Unlabeled in source* | `buffs_class_baseline` |
| [1459](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1223) | *Unlabeled in source* | `buffs_class_baseline` |
| [1460](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1224) | *Unlabeled in source* | `buffs_class_baseline` |
| [1461](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1225) | *Unlabeled in source* | `buffs_class_baseline` |
| [2791](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1204) | *Unlabeled in source* | `buffs_class_baseline` |
| [5232](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1212) | *Unlabeled in source* | `buffs_class_baseline` |
| [5234](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1214) | *Unlabeled in source* | `buffs_class_baseline` |
| [5242](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1193) | *Unlabeled in source* | `buffs_class_baseline` |
| [6192](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1194) | *Unlabeled in source* | `buffs_class_baseline` |
| [6673](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1192) | *Unlabeled in source* | `buffs_class_baseline` |
| [6756](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1213) | *Unlabeled in source* | `buffs_class_baseline` |
| [7302](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1275) | Ice Armor | `buffs_class_baseline` |
| [8450](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1271) | Dampen Magic | `buffs_class_baseline` |
| [8455](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1272) | Amplify Magic | `buffs_class_baseline` |
| [8907](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1215) | *Unlabeled in source* | `buffs_class_baseline` |
| [9884](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1216) | *Unlabeled in source* | `buffs_class_baseline` |
| [9885](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1217) | *Unlabeled in source* | `buffs_class_baseline` |
| [10156](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1226) | *Unlabeled in source* | `buffs_class_baseline` |
| [10157](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1227) | *Unlabeled in source* | `buffs_class_baseline` |
| [10937](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1205) | *Unlabeled in source* | `buffs_class_baseline` |
| [10938](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1206) | *Unlabeled in source* | `buffs_class_baseline` |
| [11549](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1195) | *Unlabeled in source* | `buffs_class_baseline` |
| [11550](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1196) | *Unlabeled in source* | `buffs_class_baseline` |
| [11551](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1197) | *Unlabeled in source* | `buffs_class_baseline` |
| [13161](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1276) | Aspect of the Beast | `buffs_class_baseline` |
| [14752](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1277) | Divine Spirit | `buffs_class_baseline` |
| [19740](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1238) | *Unlabeled in source* | `buffs_class_baseline` |
| [19742](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1248) | *Unlabeled in source* | `buffs_class_baseline` |
| [19834](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1239) | *Unlabeled in source* | `buffs_class_baseline` |
| [19835](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1240) | *Unlabeled in source* | `buffs_class_baseline` |
| [19836](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1241) | *Unlabeled in source* | `buffs_class_baseline` |
| [19837](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1242) | *Unlabeled in source* | `buffs_class_baseline` |
| [19838](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1243) | *Unlabeled in source* | `buffs_class_baseline` |
| [19850](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1249) | *Unlabeled in source* | `buffs_class_baseline` |
| [19852](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1250) | *Unlabeled in source* | `buffs_class_baseline` |
| [19853](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1251) | *Unlabeled in source* | `buffs_class_baseline` |
| [19854](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1252) | *Unlabeled in source* | `buffs_class_baseline` |
| [20166](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1232) | Seal of Wisdom Rank 1 (mana seal) | `buffs_class_baseline` |
| [20217](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1257) | *Unlabeled in source* | `buffs_class_baseline` |
| [20356](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1233) | Seal of Wisdom Rank 2 (mana seal) | `buffs_class_baseline` |
| [20357](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1234) | Seal of Wisdom Rank 3 (mana seal) | `buffs_class_baseline` |
| [20911](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1265) | *Unlabeled in source* | `buffs_class_baseline` |
| [20912](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1266) | *Unlabeled in source* | `buffs_class_baseline` |
| [20913](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1267) | *Unlabeled in source* | `buffs_class_baseline` |
| [20914](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1268) | *Unlabeled in source* | `buffs_class_baseline` |
| [21562](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1207) | *Unlabeled in source* | `buffs_class_baseline` |
| [21564](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1208) | *Unlabeled in source* | `buffs_class_baseline` |
| [21849](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1218) | *Unlabeled in source* | `buffs_class_baseline` |
| [21850](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1219) | *Unlabeled in source* | `buffs_class_baseline` |
| [23028](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1228) | *Unlabeled in source* | `buffs_class_baseline` |
| [25289](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1198) | *Unlabeled in source* | `buffs_class_baseline` |
| [25290](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1253) | *Unlabeled in source* | `buffs_class_baseline` |
| [25291](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1244) | *Unlabeled in source* | `buffs_class_baseline` |
| [25782](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1245) | Greater Blessing of Might | `buffs_class_baseline` |
| [25894](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1254) | Greater Blessing of Wisdom | `buffs_class_baseline` |
| [25895](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1262) | Greater Blessing of Salvation | `buffs_class_baseline` |
| [25898](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1258) | Greater Blessing of Kings | `buffs_class_baseline` |
| [25899](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1269) | Greater Blessing of Sanctuary | `buffs_class_baseline` |
| [364161](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1229) | *Unlabeled in source* | `buffs_class_baseline` |
| [1229741](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1357) | Camp Benefits (Forever camping) | `buffs_camp_benefits` |
| [1243120](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1189) | Demonic Knowledge (Warlock pet-owner aura) | `buffs_class_baseline` |
| [1310503](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1220) | *Unlabeled in source* | `buffs_class_baseline` |

<a id="tier-90-baselineclassharmful"></a>
### 90 — BaselineClassHarmful

**Exact spell tier** · `HARMFUL`

**1 exact spells.** Source sets: `debuffs_class_baseline`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [8733](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1181) | Blessing of Blackfathom (harmful class-buff band) | `debuffs_class_baseline` |

<a id="tier-85-important"></a>
### 85 — Important

**Native semantic fallback** · `HELPFUL\|IMPORTANT\|!BIG_DEFENSIVE\|!EXTERNAL_DEFENSIVE`

No enumerable spell-ID set: Blizzard chooses from currently eligible auras using the native candidate filter.

No additional candidate rules are specified.

<a id="tier-81-elixirs"></a>
### 81 — Elixirs

**Exact spell tier** · `HELPFUL`

**38 exact spells.** Source sets: `buffs_elixirs`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [673](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1102) | Elixir of Minor Defense | `buffs_elixirs` |
| [3166](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1103) | Elixir of Wisdom / Lesser Intellect | `buffs_elixirs` |
| [3219](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1104) | Minor Troll's Blood Elixir | `buffs_elixirs` |
| [3220](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1105) | Elixir of Lesser Defense / Armor | `buffs_elixirs` |
| [3222](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1106) | Lesser Troll's Blood Elixir | `buffs_elixirs` |
| [3223](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1107) | Troll's Blood Elixir | `buffs_elixirs` |
| [11328](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1108) | Elixir of Agility / Agility | `buffs_elixirs` |
| [11334](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1109) | Elixir of Greater Agility / Greater Agility | `buffs_elixirs` |
| [11405](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1110) | Elixir of the Giants | `buffs_elixirs` |
| [17535](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1111) | Elixir of the Sages | `buffs_elixirs` |
| [17537](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1112) | Elixir of Brute Force | `buffs_elixirs` |
| [17538](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1113) | Elixir of the Mongoose | `buffs_elixirs` |
| [17539](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1114) | Greater Arcane Elixir | `buffs_elixirs` |
| [24361](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1115) | Major Troll's Blood Elixir | `buffs_elixirs` |
| [439959](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1116) | Lesser Arcane Elixir (legacy variant) | `buffs_elixirs` |
| [1213904](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1117) | Elixir of the Honey Badger | `buffs_elixirs` |
| [1213914](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1118) | Elixir of the Mage-Lord | `buffs_elixirs` |
| [1213917](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1119) | Elixir of the Ironside (armor/defense) | `buffs_elixirs` |
| [1245244](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1120) | Minor Arcane Elixir | `buffs_elixirs` |
| [1250918](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1121) | Elixir of Cunning | `buffs_elixirs` |
| [1250920](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1122) | Elixir of the Phalanx | `buffs_elixirs` |
| [1250922](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1123) | Minor Cleric's Elixir | `buffs_elixirs` |
| [1250928](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1124) | Elixir of Fortitude | `buffs_elixirs` |
| [1250931](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1125) | Elixir of Greater Fortitude | `buffs_elixirs` |
| [1250932](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1126) | Elixir of Wicked Regeneration | `buffs_elixirs` |
| [1250940](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1127) | Elixir of the Owl | `buffs_elixirs` |
| [1250941](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1128) | Elixir of Sages | `buffs_elixirs` |
| [1250942](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1129) | Minor Mageblood Elixir | `buffs_elixirs` |
| [1250944](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1130) | Lesser Mageblood Elixir | `buffs_elixirs` |
| [1250971](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1131) | Lesser Arcane Elixir | `buffs_elixirs` |
| [1250972](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1132) | Elixir of Nature Power | `buffs_elixirs` |
| [1250978](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1133) | Elixir of Spirit | `buffs_elixirs` |
| [1250981](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1134) | Elixir of the Whale | `buffs_elixirs` |
| [1250984](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1135) | Elixir of Strength | `buffs_elixirs` |
| [1250985](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1136) | Elixir of Ferocity | `buffs_elixirs` |
| [1250986](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1137) | Elixir of the Grizzly | `buffs_elixirs` |
| [1250988](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1138) | Elixir of Lesser Intellect | `buffs_elixirs` |
| [1250989](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1139) | Elixir of Intellect | `buffs_elixirs` |

<a id="tier-80-scrolls"></a>
### 80 — Scrolls

**Exact spell tier** · `HELPFUL`

**24 exact spells.** Source sets: `buffs_scrolls`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [8091](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1144) | *Unlabeled in source* | `buffs_scrolls` |
| [8094](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1145) | *Unlabeled in source* | `buffs_scrolls` |
| [8095](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1146) | *Unlabeled in source* | `buffs_scrolls` |
| [8096](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1150) | *Unlabeled in source* | `buffs_scrolls` |
| [8097](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1151) | *Unlabeled in source* | `buffs_scrolls` |
| [8098](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1152) | *Unlabeled in source* | `buffs_scrolls` |
| [8099](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1156) | *Unlabeled in source* | `buffs_scrolls` |
| [8100](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1157) | *Unlabeled in source* | `buffs_scrolls` |
| [8101](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1158) | *Unlabeled in source* | `buffs_scrolls` |
| [8112](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1162) | *Unlabeled in source* | `buffs_scrolls` |
| [8113](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1163) | *Unlabeled in source* | `buffs_scrolls` |
| [8114](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1164) | *Unlabeled in source* | `buffs_scrolls` |
| [8115](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1168) | *Unlabeled in source* | `buffs_scrolls` |
| [8116](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1169) | *Unlabeled in source* | `buffs_scrolls` |
| [8117](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1170) | *Unlabeled in source* | `buffs_scrolls` |
| [8118](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1174) | *Unlabeled in source* | `buffs_scrolls` |
| [8119](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1175) | *Unlabeled in source* | `buffs_scrolls` |
| [8120](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1176) | *Unlabeled in source* | `buffs_scrolls` |
| [12174](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1171) | *Unlabeled in source* | `buffs_scrolls` |
| [12175](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1147) | *Unlabeled in source* | `buffs_scrolls` |
| [12176](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1153) | *Unlabeled in source* | `buffs_scrolls` |
| [12177](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1165) | *Unlabeled in source* | `buffs_scrolls` |
| [12178](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1159) | *Unlabeled in source* | `buffs_scrolls` |
| [12179](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1177) | *Unlabeled in source* | `buffs_scrolls` |

<a id="tier-70-bloodpact"></a>
### 70 — BloodPact

**Exact spell tier** · `HELPFUL`

**13 exact spells.** Source sets: `buffs_blood_pact`, `buffs_furious_howl`, `buffs_minor_class`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [6307](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1080) | Blood Pact Rank 1 (Warlock Imp) | `buffs_blood_pact` |
| [7804](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1081) | Blood Pact Rank 2 (Warlock Imp) | `buffs_blood_pact` |
| [7805](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1082) | Blood Pact Rank 3 (Warlock Imp) | `buffs_blood_pact` |
| [11766](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1083) | Blood Pact Rank 4 (Warlock Imp) | `buffs_blood_pact` |
| [11767](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1084) | Blood Pact Rank 5 (Warlock Imp) | `buffs_blood_pact` |
| [20050](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1093) | Vengeance (applied Paladin damage proc) | `buffs_minor_class` |
| [24529](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1095) | Spirit Bond (5 sec pet regeneration aura) | `buffs_minor_class` |
| [24597](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1090) | Furious Howl Rank 4 (Hunter Wolf) | `buffs_furious_howl` |
| [24603](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1089) | Furious Howl Rank 3 (Hunter Wolf) | `buffs_furious_howl` |
| [24604](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1087) | Furious Howl Rank 1 (Hunter Wolf) | `buffs_furious_howl` |
| [24605](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1088) | Furious Howl Rank 2 (Hunter Wolf) | `buffs_furious_howl` |
| [1310725](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1096) | Spirit Bond (10 sec pet regeneration variant) | `buffs_minor_class` |
| [1311033](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1094) | Iron Creed (minor damage-reduction aura) | `buffs_minor_class` |

<a id="tier-60-paladinaura"></a>
### 60 — PaladinAura

**Exact spell tier** · `HELPFUL`

**73 exact spells.** Source sets: `buffs_paladin_auras`, `buffs_warlock_armor`, `buffs_minor_world`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [465](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L996) | Devotion Aura Rank 1 | `buffs_paladin_auras` |
| [643](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L998) | Devotion Aura Rank 3 | `buffs_paladin_auras` |
| [687](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1445) | Demon Skin Rank 1 (Warlock) | `buffs_warlock_armor` |
| [696](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1446) | Demon Skin Rank 2 (Warlock) | `buffs_warlock_armor` |
| [706](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1447) | Demon Armor Rank 1 (Warlock) | `buffs_warlock_armor` |
| [1032](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1000) | Devotion Aura Rank 5 | `buffs_paladin_auras` |
| [1086](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1448) | Demon Armor Rank 2 (Warlock) | `buffs_warlock_armor` |
| [5672](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1040) | *Unlabeled in source* | `buffs_paladin_auras` |
| [5677](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1045) | Mana Spring | `buffs_paladin_auras` |
| [6371](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1041) | *Unlabeled in source* | `buffs_paladin_auras` |
| [6372](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1042) | *Unlabeled in source* | `buffs_paladin_auras` |
| [7294](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1016) | Retribution Aura Rank 1 | `buffs_paladin_auras` |
| [8072](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1032) | *Unlabeled in source* | `buffs_paladin_auras` |
| [8076](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1046) | Strength of Earth | `buffs_paladin_auras` |
| [8156](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1033) | *Unlabeled in source* | `buffs_paladin_auras` |
| [8157](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1034) | *Unlabeled in source* | `buffs_paladin_auras` |
| [8162](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1047) | Strength of Earth | `buffs_paladin_auras` |
| [8163](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1048) | Strength of Earth | `buffs_paladin_auras` |
| [8182](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1049) | Frost Resistance | `buffs_paladin_auras` |
| [8185](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1050) | Fire Resistance | `buffs_paladin_auras` |
| [8230](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1026) | *Unlabeled in source* | `buffs_paladin_auras` |
| [8250](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1027) | *Unlabeled in source* | `buffs_paladin_auras` |
| [10290](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L997) | Devotion Aura Rank 2 | `buffs_paladin_auras` |
| [10291](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L999) | Devotion Aura Rank 4 | `buffs_paladin_auras` |
| [10292](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1001) | Devotion Aura Rank 6 | `buffs_paladin_auras` |
| [10293](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1002) | Devotion Aura Rank 7 | `buffs_paladin_auras` |
| [10298](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1017) | Retribution Aura Rank 2 | `buffs_paladin_auras` |
| [10299](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1018) | Retribution Aura Rank 3 | `buffs_paladin_auras` |
| [10300](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1019) | Retribution Aura Rank 4 | `buffs_paladin_auras` |
| [10301](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1020) | Retribution Aura Rank 5 | `buffs_paladin_auras` |
| [10403](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1035) | *Unlabeled in source* | `buffs_paladin_auras` |
| [10404](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1036) | *Unlabeled in source* | `buffs_paladin_auras` |
| [10405](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1037) | *Unlabeled in source* | `buffs_paladin_auras` |
| [10441](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1051) | Strength of Earth | `buffs_paladin_auras` |
| [10460](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1043) | *Unlabeled in source* | `buffs_paladin_auras` |
| [10461](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1044) | *Unlabeled in source* | `buffs_paladin_auras` |
| [10476](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1052) | Frost Resistance | `buffs_paladin_auras` |
| [10477](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1053) | Frost Resistance | `buffs_paladin_auras` |
| [10491](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1054) | Mana Spring | `buffs_paladin_auras` |
| [10493](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1055) | Mana Spring | `buffs_paladin_auras` |
| [10494](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1056) | Mana Spring | `buffs_paladin_auras` |
| [10521](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1028) | *Unlabeled in source* | `buffs_paladin_auras` |
| [10534](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1057) | Fire Resistance | `buffs_paladin_auras` |
| [10535](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1058) | Fire Resistance | `buffs_paladin_auras` |
| [10596](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1059) | Nature Resistance | `buffs_paladin_auras` |
| [10598](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1060) | Nature Resistance | `buffs_paladin_auras` |
| [10599](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1061) | Nature Resistance | `buffs_paladin_auras` |
| [11733](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1449) | Demon Armor Rank 3 (Warlock) | `buffs_warlock_armor` |
| [11734](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1450) | Demon Armor Rank 4 (Warlock) | `buffs_warlock_armor` |
| [11735](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1451) | Demon Armor Rank 5 (Warlock) | `buffs_warlock_armor` |
| [15036](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1029) | *Unlabeled in source* | `buffs_paladin_auras` |
| [17007](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1072) | Leader of the Pack (retained talent record) | `buffs_paladin_auras` |
| [19506](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1069) | Trueshot Aura Rank 3 (level 40) | `buffs_paladin_auras` |
| [19746](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L994) | Concentration Aura | `buffs_paladin_auras` |
| [19876](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1012) | Shadow Resistance Aura Rank 1 | `buffs_paladin_auras` |
| [19888](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1008) | Frost Resistance Aura Rank 1 | `buffs_paladin_auras` |
| [19891](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1004) | Fire Resistance Aura Rank 1 | `buffs_paladin_auras` |
| [19895](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1013) | Shadow Resistance Aura Rank 2 | `buffs_paladin_auras` |
| [19896](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1014) | Shadow Resistance Aura Rank 3 | `buffs_paladin_auras` |
| [19897](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1009) | Frost Resistance Aura Rank 2 | `buffs_paladin_auras` |
| [19898](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1010) | Frost Resistance Aura Rank 3 | `buffs_paladin_auras` |
| [19899](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1005) | Fire Resistance Aura Rank 2 | `buffs_paladin_auras` |
| [19900](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1006) | Fire Resistance Aura Rank 3 | `buffs_paladin_auras` |
| [20218](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1022) | Sanctity Aura | `buffs_paladin_auras` |
| [20905](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1070) | Trueshot Aura Rank 4 (level 50) | `buffs_paladin_auras` |
| [20906](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1071) | Trueshot Aura Rank 5 (level 60) | `buffs_paladin_auras` |
| [24853](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1062) | Mana Spring | `buffs_paladin_auras` |
| [24932](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1073) | Leader of the Pack (applied party aura) | `buffs_paladin_auras` |
| [25362](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1063) | Strength of Earth | `buffs_paladin_auras` |
| [1292142](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1077) | Benevolence (minor party health regeneration) | `buffs_minor_world` |
| [1296202](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1076) | Rat Familiar (+2 Intellect) | `buffs_minor_world` |
| [1299346](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1067) | Trueshot Aura Rank 1 (level 25) | `buffs_paladin_auras` |
| [1299348](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1068) | Trueshot Aura Rank 2 (level 32) | `buffs_paladin_auras` |

<a id="tier-59-passivedebuff"></a>
### 59 — PassiveDebuff

**Exact spell tier** · `HARMFUL`

**2 exact spells.** Source sets: `debuffs_passive`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [26013](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L751) | Deserter (battleground queue lockout) | `debuffs_passive` |
| [1292749](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L752) | Martyrdom (permanent harmful item aura; not the Priest talent) | `debuffs_passive` |

<a id="tier-50-travelutility"></a>
### 50 — TravelUtility

**Exact spell tier** · `HELPFUL`

**9 exact spells.** Source sets: `buffs_travel_utility`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [131](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1412) | Water Breathing | `buffs_travel_utility` |
| [546](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1414) | Water Walking (Shaman) | `buffs_travel_utility` |
| [1066](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1415) | Aquatic Form (Druid) | `buffs_travel_utility` |
| [5697](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1413) | Unending Breath (Warlock) | `buffs_travel_utility` |
| [16591](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1416) | Noggenfogger Elixir (skeleton and underwater breathing) | `buffs_travel_utility` |
| [16593](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1417) | Noggenfogger Elixir (slow fall) | `buffs_travel_utility` |
| [16595](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1418) | Noggenfogger Elixir (shrink) | `buffs_travel_utility` |
| [17775](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1410) | Air Bubbles: underwater breathing from bubble vents | `buffs_travel_utility` |
| [18733](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1411) | Air Bubbles: short alternate water-breathing aura | `buffs_travel_utility` |

<a id="tier-10-plainsrunning"></a>
### 10 — Plainsrunning

**Exact spell tier** · `HELPFUL`

**4 exact spells.** Source sets: `buffs_plainsrunning`, `buffs_elemental_blessing`, `buffs_righteous_fury`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [25780](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L990) | Righteous Fury (Paladin) | `buffs_righteous_fury` |
| [1259688](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1392) | Elemental Blessing (Skysight, 30 sec) | `buffs_elemental_blessing` |
| [1270893](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1393) | Elemental Blessing (Skysight, 15 min) | `buffs_elemental_blessing` |
| [1299038](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1389) | Plainsrunning active aura (Forever Tauren) | `buffs_plainsrunning` |

<a id="tier-9-passivespeed"></a>
### 9 — PassiveSpeed

**Exact spell tier** · `HELPFUL`

**1 exact spells.** Source sets: `buffs_passive_speed`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [1293199](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1386) | Agamaggan's Clutch (minor regional movement bonus) | `buffs_passive_speed` |

<a id="tier-5-hostilehelpful"></a>
### 5 — HostileHelpful

**Native semantic fallback** · `HELPFUL\|INCLUDE_NAME_PLATE_ONLY`

No enumerable spell-ID set: Blizzard chooses from currently eligible auras using the native candidate filter.

Native candidate rules:

```lua
{ maxDuration = math.huge }
```

<a id="tier-4-campfirenearby"></a>
### 4 — CampfireNearby

**Exact spell tier** · `HELPFUL`

**3 exact spells.** Source sets: `buffs_campfire_nearby`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [12627](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1401) | Disease Cloud (persistent emitter aura, not the damage trigger) | `buffs_campfire_nearby` |
| [1283391](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1403) | Campfire Nearby (Forever) | `buffs_campfire_nearby` |
| [1321936](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1402) | Disease Cloud (Forever persistent emitter; observed unit ID pending) | `buffs_campfire_nearby` |

<a id="tier-4-campfirenearbyharmful"></a>
### 4 — CampfireNearbyHarmful

**Exact spell tier** · `HARMFUL`

**3 exact spells.** Source sets: `debuffs_campfire_nearby`, `debuffs_noncombat`, `debuffs_boosted_rest`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [24755](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1330) | Tricked or Treated: Halloween interaction cooldown | `debuffs_noncombat` |
| [1229451](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1398) | Boosted Rest (Forever camp rest eligibility) | `debuffs_boosted_rest` |
| [1299099](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1184) | Quitter (Air Rifle lockout; harmful camp-nearby band) | `debuffs_campfire_nearby` |

<a id="tier-3-tracking"></a>
### 3 — Tracking

**Exact spell tier** · `HELPFUL`

**19 exact spells.** Source sets: `buffs_tracking`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [126](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1298) | Eye of Kilrogg | `buffs_tracking` |
| [132](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1299) | Detect Invisibility | `buffs_tracking` |
| [1462](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1300) | Beast Lore | `buffs_tracking` |
| [1494](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1301) | Track Beasts | `buffs_tracking` |
| [2096](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1302) | Mind Vision | `buffs_tracking` |
| [2481](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1292) | Find Treasure / treasure tracking | `buffs_tracking` |
| [5225](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1293) | Druid Track Humanoids (cat form) | `buffs_tracking` |
| [5500](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1303) | Sense Demons | `buffs_tracking` |
| [5502](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1304) | Sense Undead | `buffs_tracking` |
| [6196](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1305) | Far Sight | `buffs_tracking` |
| [6197](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1306) | Eagle Eye | `buffs_tracking` |
| [19878](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1294) | Track Demons | `buffs_tracking` |
| [19879](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1295) | Track Dragonkin | `buffs_tracking` |
| [19880](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1307) | Track Elementals | `buffs_tracking` |
| [19882](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1296) | Track Giants | `buffs_tracking` |
| [19883](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1308) | Track Humanoids | `buffs_tracking` |
| [19884](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1309) | Track Undead | `buffs_tracking` |
| [19885](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1310) | Track Hidden | `buffs_tracking` |
| [43308](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1297) | Find Fish | `buffs_tracking` |

<a id="tier-1-gathering"></a>
### 1 — Gathering

**Exact spell tier** · `HELPFUL`

**4 exact spells.** Source sets: `buffs_gathering`.

| Spell ID (source link) | Name or annotation from `Spells.lua` | Contributing categories |
|---:|---|---|
| [2383](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1283) | Find Herbs Rank 1 | `buffs_gathering` |
| [2580](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1285) | Find Minerals Rank 1 | `buffs_gathering` |
| [8387](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1284) | Find Herbs Rank 2 | `buffs_gathering` |
| [8388](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1286) | Find Minerals Rank 2 | `buffs_gathering` |

## Present in `Spells.lua` but intentionally without a portrait priority

These IDs are explicitly in the repository's spell categories but are not members of any exact aura-priority tier.

| Spell ID (source link) | Name or annotation | Category |
|---:|---|---|
| [8213](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1316) | Savory Deviate Delight (visual transformation) | `buffs_cosmetic` |
| [8219](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1318) | Savory Deviate Delight: Flip Out, male | `buffs_cosmetic` |
| [8220](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1319) | Savory Deviate Delight: Flip Out, female | `buffs_cosmetic` |
| [8221](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1320) | Savory Deviate Delight: Yaaarrrr, male | `buffs_cosmetic` |
| [8222](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1321) | Savory Deviate Delight: Yaaarrrr, female | `buffs_cosmetic` |
| [1249521](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1325) | Profession-only Well Fed: Fishing Skill | `buffs_noncombat` |
| [1252576](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1317) | Savory Whimsyfin Delight (visual transformation) | `buffs_cosmetic` |
| [1280341](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua#L1324) | Uncommon Fishing: Fishing Rack loot bonus | `buffs_noncombat` |

## Code sources and scope

- [Priority.lua — exact/semantic tiers](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Priority.lua)
- [Spells.lua — every ID and source comment](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/Spells.lua)
- [AuraEngine.lua — native and readable selection, fallback visibility](https://github.com/bjoern-janson/bjarkiPortraits/blob/e9c4b3237c83fba9acbf2f7d0497b09776149c50/AuraEngine.lua)

Generated documentation only. This file does not participate in the addon TOC or its runtime. Update the index when the underlying priority and spell datasets change.
