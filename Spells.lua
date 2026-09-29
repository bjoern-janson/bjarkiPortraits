local addonName, PT = ...

-- Canonical spell/category data. Runtime logic does not live in this file.
PT.categories = {
    immunities = {
        [3169] = true,
        [16621] = true,
        [8178] = true,
        [425876] = true,
        [1022] = true,
        [5599] = true,
        [10278] = true,
        [498] = true,
        [5573] = true,
        [642] = true,
        [1020] = true,
        [11958] = true,
        [20230] = true,
        [20589] = true, -- Escape Artist (Gnome; 3 sec movement-impairing immunity)
    },
    cc = {
        [20549] = true,
        [1090] = true,
        [13327] = true,
        [835] = true,
        [5134] = true,
        [19769] = true,
        [4068] = true,
        [15753] = true,
        [13237] = true,
        [18798] = true,
        [446391] = true,
        [605] = true,
        [10911] = true,
        [10912] = true,
        [8122] = true,
        [8124] = true,
        [10888] = true,
        [10890] = true,
        [15269] = true,
        [15487] = true,
        [9484] = true,
        [9485] = true,
        [10955] = true,
        [24259] = true,
        [6358] = true,
        [5782] = true,
        [6213] = true,
        [6215] = true,
        [5484] = true,
        [17928] = true,
        [710] = true,
        [18647] = true,
        [6789] = true,
        [17925] = true,
        [17926] = true,
        [18093] = true,
        [853] = true,
        [5588] = true,
        [5589] = true,
        [10308] = true,
        [20066] = true,
        [20170] = true,
        [427719] = true,
        [1513] = true,
        [14326] = true,
        [14327] = true,
        [19410] = true,
        [3355] = true,
        [14308] = true,
        [14309] = true,
        [19386] = true,
        [24132] = true,
        [24133] = true,
        [19503] = true,
        [2637] = true,
        [18657] = true,
        [18658] = true,
        [9005] = true,
        [9823] = true,
        [9827] = true,
        [16922] = true,
        [5211] = true,
        [6798] = true,
        [8983] = true,
        [18469] = true,
        [118] = true,
        [12824] = true,
        [12825] = true,
        [12826] = true,
        [28270] = true,
        [28271] = true,
        [28272] = true,
        [12355] = true,
        [18425] = true,
        [1833] = true,
        [408] = true,
        [8643] = true,
        [2070] = true,
        [6770] = true,
        [11297] = true,
        [2094] = true,
        [1776] = true,
        [1777] = true,
        [8629] = true,
        [11285] = true,
        [11286] = true,
        [400009] = true,
        [18498] = true,
        [5246] = true,
        [20511] = true,
        [20253] = true,
        [20614] = true,
        [20615] = true,
        [12798] = true,
        [12809] = true,
        [7922] = true,
        [5530] = true,
    },
    stuns = {
        [20549] = true, -- War Stomp
        [13327] = true, -- Reckless Charge
        [835] = true, -- Tidal Charm
        [19769] = true, -- Thorium Grenade
        [4068] = true, -- Iron Grenade
        [15753] = true, -- Linken's Boomerang Stun
        [13237] = true, -- Goblin Mortar
        [15269] = true, -- Blackout
        [18093] = true, -- Pyroclasm
        [853] = true, -- Hammer of Justice
        [5588] = true, -- Hammer of Justice
        [5589] = true, -- Hammer of Justice
        [10308] = true, -- Hammer of Justice
        [20170] = true, -- Seal of Justice stun
        [19410] = true, -- Concussive Shot Stun
        [9005] = true, -- Pounce Stun
        [9823] = true, -- Pounce Stun
        [9827] = true, -- Pounce Stun
        [16922] = true, -- Starfire Stun
        [5211] = true, -- Bash
        [6798] = true, -- Bash
        [8983] = true, -- Bash
        [12355] = true, -- Impact Stun
        [1833] = true, -- Cheap Shot
        [408] = true, -- Kidney Shot
        [8643] = true, -- Kidney Shot
        [400009] = true, -- Between the Eyes
        [20253] = true, -- Intercept Stun
        [20614] = true, -- Intercept Stun
        [20615] = true, -- Intercept Stun
        [12798] = true, -- Revenge Stun
        [12809] = true, -- Concussion Blow
        [7922] = true, -- Charge Stun
        [5530] = true, -- Mace Spec Stun
    },
    debuffs_dots = {
        -- Mage residual/periodic damage
        [133] = true, [143] = true, [145] = true, [3140] = true,
        [8400] = true, [8401] = true, [8402] = true,
        [10148] = true, [10149] = true, [10150] = true, [10151] = true, [25306] = true, -- Fireball
        [11366] = true, [12505] = true, [12522] = true, [12523] = true,
        [12524] = true, [12525] = true, [12526] = true, [18809] = true, -- Pyroblast
        [12654] = true, -- Ignite

        -- Priest
        [589] = true, [594] = true, [970] = true, [992] = true,
        [2767] = true, [10892] = true, [10893] = true, [10894] = true, -- Shadow Word: Pain
        [2944] = true, [19276] = true, [19277] = true, [19278] = true,
        [19279] = true, [19280] = true, -- Devouring Plague

        -- Warlock
        [172] = true, [6222] = true, [6223] = true, [7648] = true,
        [11671] = true, [11672] = true, [25311] = true, -- Corruption
        [980] = true, [1014] = true, [6217] = true, [11711] = true,
        [11712] = true, [11713] = true, -- Curse of Agony
        [348] = true, [707] = true, [1094] = true, [2941] = true,
        [11665] = true, [11667] = true, [11668] = true, [25309] = true, -- Immolate
        [18265] = true, [18879] = true, [18880] = true, [18881] = true,
        [18927] = true, [18928] = true, [18929] = true, -- Siphon Life

        -- Hunter
        [1978] = true, [13549] = true, [13550] = true, [13551] = true,
        [13552] = true, [13553] = true, [13554] = true, [13555] = true, [25295] = true, -- Serpent Sting
        [13797] = true, [14298] = true, [14299] = true, [14300] = true, [14301] = true, -- Immolation Trap effect

        -- Druid
        [8921] = true, [8924] = true, [8925] = true, [8926] = true,
        [8927] = true, [8928] = true, [8929] = true, [9833] = true,
        [9834] = true, [9835] = true, -- Moonfire
        [5570] = true, [24974] = true, [24975] = true, [24976] = true, [24977] = true, -- Insect Swarm
        [1822] = true, [1823] = true, [1824] = true, [9904] = true, -- Rake
        [1079] = true, [9492] = true, [9493] = true, [9752] = true, [9894] = true, [9896] = true, -- Rip
        [9007] = true, [9824] = true, [9826] = true, -- Pounce bleed

        -- Rogue
        [703] = true, [8631] = true, [8632] = true, [8633] = true, [11289] = true, [11290] = true, -- Garrote
        [1943] = true, [8639] = true, [8640] = true, [11273] = true, [11274] = true, [11275] = true, -- Rupture
        [2818] = true, -- Deadly Poison debuff

        -- Warrior / Shaman
        [772] = true, [6546] = true, [6547] = true, [6548] = true,
        [11572] = true, [11573] = true, [11574] = true, -- Rend
        [12721] = true, -- Deep Wounds periodic debuff
        [8050] = true, [8052] = true, [8053] = true, [10447] = true, [10448] = true, -- Flame Shock
    },
    slows = {
        [116] = true, -- Frostbolt Rank 1
        [205] = true, -- Frostbolt Rank 2
        [837] = true, -- Frostbolt Rank 3
        [7322] = true, -- Frostbolt Rank 4
        [8406] = true, -- Frostbolt Rank 5
        [8407] = true, -- Frostbolt Rank 6
        [8408] = true, -- Frostbolt Rank 7
        [10179] = true, -- Frostbolt Rank 8
        [10180] = true, -- Frostbolt Rank 9
        [10181] = true, -- Frostbolt Rank 10
        [3600] = true, -- Earthbind (Earthbind Totem slow aura)
    },
    slows_chilled = {
        [6136] = true, -- Chilled (Frost Armor)
        [7321] = true, -- Chilled (Ice/Frost Armor family)
        [12484] = true, -- Chilled (Forever/NPC variant)
        [15850] = true, -- Chilled (Forever/NPC variant)
        [18101] = true, -- Chilled (Forever/NPC variant)
        [20005] = true, -- Chilled (Forever/NPC variant)
        [1296223] = true, -- Chilled (Forever/NPC variant)
    },
    roots = {
        [6533] = true,
        [16979] = true,
        [18223] = true,
        [18310] = true,
        [18313] = true,
        [1714] = true,
        [11719] = true,
        [12548] = true,
        [19229] = true,
        [19306] = true,
        [20909] = true,
        [20910] = true,
        [19185] = true,
        [25999] = true,
        [3034] = true,
        [14279] = true,
        [14280] = true,
        [339] = true,
        [1062] = true,
        [5195] = true,
        [5196] = true,
        [9852] = true,
        [9853] = true,
        [19970] = true,
        [19971] = true,
        [19972] = true,
        [19973] = true,
        [19974] = true,
        [19975] = true,
        [12494] = true,
        [122] = true,
        [865] = true,
        [6131] = true,
        [10230] = true,
        [3409] = true,
        [11201] = true,
        [23694] = true,
    },
    interrupts = {
        [15752] = true,
        [19244] = true,
        [19647] = true,
        [8042] = true,
        [8044] = true,
        [8045] = true,
        [8046] = true,
        [10412] = true,
        [10413] = true,
        [10414] = true,
        [2139] = true,
        [1766] = true,
        [1767] = true,
        [1768] = true,
        [1769] = true,
        [14251] = true,
        [6552] = true,
        [6554] = true,
        [72] = true,
        [1671] = true,
        [1672] = true,
    },
    buffs_shield = {
        [17] = true, -- Power Word: Shield
        [592] = true, -- Power Word: Shield
        [600] = true, -- Power Word: Shield
        [3747] = true, -- Power Word: Shield
        [6065] = true, -- Power Word: Shield
        [6066] = true, -- Power Word: Shield
        [10898] = true, -- Power Word: Shield
        [10899] = true, -- Power Word: Shield
        [10900] = true, -- Power Word: Shield
        [10901] = true, -- Power Word: Shield
    },
    buffs_defensive = {
        [23493] = true,
        [23506] = true,
        [29506] = true,
        [14892] = true,
        [15362] = true,
        [15363] = true,
        [6346] = true,
        [402004] = true,
        [425294] = true,
        [6229] = true,
        [11739] = true,
        [11740] = true,
        [28610] = true,
        [7812] = true,
        [19438] = true,
        [19440] = true,
        [19441] = true,
        [19442] = true,
        [19443] = true,
        [16188] = true,
        [436391] = true,
        [1044] = true,
        [6940] = true,
        [20729] = true,
        [407613] = true,
        [412019] = true,
        [19263] = true,
        [22812] = true,
        [11426] = true,
        [13031] = true,
        [13032] = true,
        [13033] = true,
        [543] = true,
        [8457] = true,
        [8458] = true,
        [10223] = true,
        [10225] = true,
        [6143] = true,
        [8461] = true,
        [8462] = true,
        [10177] = true,
        [28609] = true,
        [1463] = true,
        [8494] = true,
        [8495] = true,
        [10191] = true,
        [10192] = true,
        [10193] = true,
        [5277] = true,
        [14278] = true,
        [871] = true,
        [1277462] = true, -- Contingency Plan Rank 1 (ward)
        [1277634] = true, -- Contingency Plan Rank 2 (ward)
        [1277638] = true, -- Contingency Plan Rank 3 (ward)
        [1277639] = true, -- Contingency Plan Rank 4 (ward)
        [1277640] = true, -- Contingency Plan Rank 5 (ward)
    },
    buffs_utility = {
        [1953] = true, -- Blink (Mage)
        [1236175] = true, -- Blink (Mage, Forever variant)
        [1259416] = true, -- Walk on Air (Skyborne racial, 10 sec)
        [1308663] = true, -- Walk on Air (Forever variant, 1 min)
        [1260270] = true, -- Rapid Regeneration (Troll racial, Forever)
        [1002] = true, -- Eyes of the Beast (Hunter)
        [20707] = true, -- Soulstone Resurrection Rank 1
        [20762] = true, -- Soulstone Resurrection Rank 2
        [20763] = true, -- Soulstone Resurrection Rank 3
        [20764] = true, -- Soulstone Resurrection Rank 4
        [20765] = true, -- Soulstone Resurrection Rank 5
        [1259691] = true, -- Energized (Read Ley Line, 15 min)
        [1270842] = true, -- Energized (Read Ley Line, 15 sec)
        [16689] = true, -- Nature's Grasp Rank 1
        [16810] = true, -- Nature's Grasp Rank 2
        [16811] = true, -- Nature's Grasp Rank 3
        [16812] = true, -- Nature's Grasp Rank 4
        [16813] = true, -- Nature's Grasp Rank 5
        [17329] = true, -- Nature's Grasp Rank 6
    },
    buffs_offensive = {
        [20554] = true, -- Berserking (Troll racial, Forever)
        [20600] = true,
        [7744] = true,
        [20594] = true,
        [20572] = true, -- Blood Fury (Orc racial)
        [23451] = true,
        [23505] = true,
        [6615] = true,
        [24364] = true,
        [11359] = true,
        [5024] = true,
        [2379] = true,
        [23097] = true,
        [23131] = true,
        [23132] = true,
        [12733] = true,
        [14530] = true,
        [14253] = true,
        [9175] = true,
        [13141] = true,
        [8892] = true,
        [9774] = true,
        [13494] = true,
        [10060] = true,
        [13159] = true,
        [3045] = true,
        [19574] = true,
        [409368] = true,
        [1850] = true,
        [9821] = true,
        [417141] = true,
        [5229] = true, -- Enrage (Druid)
        [1259812] = true, -- Eureka! (Gnome Rogue)
        [1259813] = true, -- Eureka! (Gnome Warrior)
        [1259817] = true, -- Eureka! (Gnome Mage)
        [1259821] = true, -- Eureka! (Gnome Warlock)
        [1259823] = true, -- Eureka! (Gnome Priest)
        [1259799] = true, -- Elune's Light
        [16870] = true, -- Clearcasting (Druid)
        [12042] = true,
        [13750] = true,
        [13877] = true,
        [2983] = true,
        [8696] = true,
        [11305] = true,
        [1719] = true,
        [12328] = true,
        [18499] = true,
    },
    debuffs_hunters_mark = {
        [1130] = true, -- Hunter's Mark Rank 1
        [14323] = true, -- Hunter's Mark Rank 2
        [14324] = true, -- Hunter's Mark Rank 3
        [14325] = true, -- Hunter's Mark Rank 4
        [1213268] = true, -- Hunter's Mark Rank 4 (Forever alternate aura)
    },
    debuffs_other = {
        [770] = true, -- Faerie Fire Rank 1
        [778] = true, -- Faerie Fire Rank 2
        [9749] = true, -- Faerie Fire Rank 3
        [9907] = true, -- Faerie Fire Rank 4

        [702] = true, -- Curse of Weakness Rank 1
        [1108] = true, -- Curse of Weakness Rank 2
        [6205] = true, -- Curse of Weakness Rank 3
        [7646] = true, -- Curse of Weakness Rank 4
        [11707] = true, -- Curse of Weakness Rank 5
        [11708] = true, -- Curse of Weakness Rank 6

    },
    debuffs_priority = {
        [25771] = true, -- Forbearance (Paladin)
    },
    debuffs_res_sickness = {
        [15007] = true, -- Resurrection Sickness
    },
    buffs_honorless_target = {
        [2479] = true, -- Honorless Target
    },
    debuffs_weakenedsoul = {
        [6788] = true, -- Weakened Soul (Priest)
    },
    buffs_seals = {
        [20154] = true, -- Seal of Righteousness Rank 1 (Paladin)
        [20287] = true, -- Seal of Righteousness Rank 2 (Paladin)
        [20288] = true, -- Seal of Righteousness Rank 3 (Paladin)
        [20289] = true, -- Seal of Righteousness Rank 4 (Paladin)
        [20290] = true, -- Seal of Righteousness Rank 5 (Paladin)
        [20291] = true, -- Seal of Righteousness Rank 6 (Paladin)
        [20292] = true, -- Seal of Righteousness Rank 7 (Paladin)
        [20293] = true, -- Seal of Righteousness Rank 8 (Paladin)
        [21084] = true, -- Seal of Righteousness Rank 1 alternate aura ID (Paladin)
        [21082] = true, -- Seal of the Crusader Rank 1 (Paladin)
        [20162] = true, -- Seal of the Crusader Rank 2 (Paladin)
        [20305] = true, -- Seal of the Crusader Rank 3 (Paladin)
        [20306] = true, -- Seal of the Crusader Rank 4 (Paladin)
        [20307] = true, -- Seal of the Crusader Rank 5 (Paladin)
        [20308] = true, -- Seal of the Crusader Rank 6 (Paladin)
    },
    buffs_fooddrink = {
        -- Active recovery/channel states share one portrait priority lane.
        [20577] = true, -- Cannibalize activation (Undead)
        [20578] = true, -- Cannibalize channel aura (Undead)
        [12051] = true, -- Evocation (Mage)
        -- Food (Vanilla/Forever eating auras)
        [433] = true, -- Food
        [434] = true, -- Food
        [435] = true, -- Food
        [1127] = true, -- Food
        [1129] = true, -- Food
        [1131] = true, -- Food
        [2639] = true, -- Food
        [5004] = true, -- Food
        [5005] = true, -- Food
        [5006] = true, -- Food
        [5007] = true, -- Food
        [6410] = true, -- Food
        [7737] = true, -- Food
        [9177] = true, -- Food
        [10256] = true, -- Food
        [10257] = true, -- Food
        [18124] = true, -- Food
        [18229] = true, -- Food
        [18230] = true, -- Food
        [18231] = true, -- Food
        [18232] = true, -- Food
        [18233] = true, -- Food
        [18234] = true, -- Food
        [21149] = true, -- Food
        [22731] = true, -- Food
        [24005] = true, -- Food
        [24707] = true, -- Food
        [24800] = true, -- Food
        [24869] = true, -- Food
        [25660] = true, -- Food
        [25695] = true, -- Food
        [25697] = true, -- Food
        [25700] = true, -- Food
        [25702] = true, -- Food
        [25886] = true, -- Food
        [25888] = true, -- Food
        [25990] = true, -- Food
        [26030] = true, -- Food
        [26260] = true, -- Food
        [26263] = true, -- Food
        [26401] = true, -- Food
        [26472] = true, -- Food
        [26474] = true, -- Food
        [28616] = true, -- Food
        [29008] = true, -- Food
        [29038] = true, -- Food
        [29055] = true, -- Food
        [29073] = true, -- Food
        -- Drink (Vanilla/Forever drinking auras)
        [430] = true, -- Drink (level 5 water)
        [431] = true, -- Drink (level 15 water)
        [432] = true, -- Drink (level 25 water)
        [1133] = true, -- Drink (level 35 water)
        [1135] = true, -- Drink (level 45 water)
        [10250] = true, -- Drink (higher-rank water)
        [446714] = true, -- Drink (Forever)
        [468767] = true, -- Drink (Forever)
        [833] = true, -- Drink
        [18140] = true, -- Drink
        [23698] = true, -- Drink
        [24355] = true, -- Drink
        [25696] = true, -- Drink
        [25701] = true, -- Drink
        [25703] = true, -- Drink
        [25887] = true, -- Drink
        [25889] = true, -- Drink
        [26261] = true, -- Drink
        [26402] = true, -- Drink
        [26473] = true, -- Drink
        [26475] = true, -- Drink
        [29007] = true, -- Drink
        [29039] = true, -- Drink
        [22734] = true, -- Drink
    },
    buffs_innervate = {
        [29166] = true, -- Innervate (Druid)
    },
    buffs_thorns = {
        [467] = true, -- Thorns Rank 1 (Druid)
        [782] = true, -- Thorns Rank 2 (Druid)
        [1075] = true, -- Thorns Rank 3 (Druid)
        [8914] = true, -- Thorns Rank 4 (Druid)
        [9756] = true, -- Thorns Rank 5 (Druid)
        [9910] = true, -- Thorns Rank 6 (Druid)
    },
    buffs_righteous_fury = {
        [25780] = true, -- Righteous Fury (Paladin)
    },
    buffs_paladin_auras = {
        -- Passive Paladin aura states are the absolute-bottom tracked buffs.
        [19746] = true, -- Concentration Aura

        [465] = true, -- Devotion Aura Rank 1
        [10290] = true, -- Devotion Aura Rank 2
        [643] = true, -- Devotion Aura Rank 3
        [10291] = true, -- Devotion Aura Rank 4
        [1032] = true, -- Devotion Aura Rank 5
        [10292] = true, -- Devotion Aura Rank 6
        [10293] = true, -- Devotion Aura Rank 7

        [19891] = true, -- Fire Resistance Aura Rank 1
        [19899] = true, -- Fire Resistance Aura Rank 2
        [19900] = true, -- Fire Resistance Aura Rank 3

        [19888] = true, -- Frost Resistance Aura Rank 1
        [19897] = true, -- Frost Resistance Aura Rank 2
        [19898] = true, -- Frost Resistance Aura Rank 3

        [19876] = true, -- Shadow Resistance Aura Rank 1
        [19895] = true, -- Shadow Resistance Aura Rank 2
        [19896] = true, -- Shadow Resistance Aura Rank 3

        [7294] = true, -- Retribution Aura Rank 1
        [10298] = true, -- Retribution Aura Rank 2
        [10299] = true, -- Retribution Aura Rank 3
        [10300] = true, -- Retribution Aura Rank 4
        [10301] = true, -- Retribution Aura Rank 5

        [20218] = true, -- Sanctity Aura

        -- Shaman: persistent party-support totem auras share this priority band.
        -- Stoneskin
        [8072] = true,
        [8156] = true,
        [8157] = true,
        [10403] = true,
        [10404] = true,
        [10405] = true,

        -- Healing Stream
        [5672] = true,
        [6371] = true,
        [6372] = true,
        [10460] = true,
        [10461] = true,
    },
    buffs_blood_pact = {
        [6307] = true, -- Blood Pact Rank 1 (Warlock Imp)
        [7804] = true, -- Blood Pact Rank 2 (Warlock Imp)
        [7805] = true, -- Blood Pact Rank 3 (Warlock Imp)
        [11766] = true, -- Blood Pact Rank 4 (Warlock Imp)
        [11767] = true, -- Blood Pact Rank 5 (Warlock Imp)
    },
    buffs_scrolls = {
        -- Vanilla stat/armor scroll buffs. Kept below maintained class buffs.
        -- Protection / Armor
        [8091] = true,
        [8094] = true,
        [8095] = true,
        [12175] = true,

        -- Intellect
        [8096] = true,
        [8097] = true,
        [8098] = true,
        [12176] = true,

        -- Stamina
        [8099] = true,
        [8100] = true,
        [8101] = true,
        [12178] = true,

        -- Spirit
        [8112] = true,
        [8113] = true,
        [8114] = true,
        [12177] = true,

        -- Agility
        [8115] = true,
        [8116] = true,
        [8117] = true,
        [12174] = true,

        -- Strength
        [8118] = true,
        [8119] = true,
        [8120] = true,
        [12179] = true,
    },
    buffs_class_baseline = {
        -- Regular class buffs: meaningful combat state, but deliberately below
        -- forms/stealth and active combat effects.

        -- Warrior: Battle Shout
        [6673] = true,
        [5242] = true,
        [6192] = true,
        [11549] = true,
        [11550] = true,
        [11551] = true,
        [25289] = true,

        -- Priest: Power Word: Fortitude + Prayer of Fortitude
        [1243] = true,
        [1244] = true,
        [1245] = true,
        [2791] = true,
        [10937] = true,
        [10938] = true,
        [21562] = true,
        [21564] = true,

        -- Druid: Mark/Gift of the Wild (plus Forever's observed level-60 aura)
        [1126] = true,
        [5232] = true,
        [6756] = true,
        [5234] = true,
        [8907] = true,
        [9884] = true,
        [9885] = true,
        [21849] = true,
        [21850] = true,
        [1310503] = true,

        -- Mage: Arcane Intellect / Arcane Brilliance (+ Forever alternate aura)
        [1459] = true,
        [1460] = true,
        [1461] = true,
        [10156] = true,
        [10157] = true,
        [23028] = true,
        [364161] = true,

        -- Paladin: maintained class buffs / mana seal
        [20166] = true, -- Seal of Wisdom Rank 1 (mana seal)
        [20356] = true, -- Seal of Wisdom Rank 2 (mana seal)
        [20357] = true, -- Seal of Wisdom Rank 3 (mana seal)

        -- Paladin: long-lived Blessings (not active defensive/utility blessings)
        -- Might
        [19740] = true,
        [19834] = true,
        [19835] = true,
        [19836] = true,
        [19837] = true,
        [19838] = true,
        [25291] = true,
        [25782] = true, -- Greater Blessing of Might

        -- Wisdom
        [19742] = true,
        [19850] = true,
        [19852] = true,
        [19853] = true,
        [19854] = true,
        [25290] = true,
        [25894] = true, -- Greater Blessing of Wisdom

        -- Kings
        [20217] = true,
        [25898] = true, -- Greater Blessing of Kings

        -- Salvation
        [1038] = true,
        [25895] = true, -- Greater Blessing of Salvation

        -- Sanctuary
        [20911] = true,
        [20912] = true,
        [20913] = true,
        [20914] = true,
        [25899] = true, -- Greater Blessing of Sanctuary
    },
    buffs_camp_benefits = {
        [1229741] = true, -- Camp Benefits (Forever camping)
    },
    buffs_well_fed = {
        -- Visible Well Fed auras, including profession-oriented variants.
        [19705] = true, -- Well Fed: +2 Stamina/Spirit
        [19706] = true, -- Well Fed: +4 Stamina/Spirit
        [19708] = true, -- Well Fed: +6 Stamina/Spirit
        [19709] = true, -- Well Fed: +8 Stamina/Spirit
        [19710] = true, -- Well Fed: +12 Stamina/Spirit
        [19711] = true, -- Well Fed: +14 Stamina/Spirit
        [24799] = true, -- Well Fed: +20 Strength
        [24870] = true, -- Well Fed: level-scaled Stamina/Spirit
        [1225778] = true, -- Forever Well Fed: Strength + Stamina
        [1225779] = true, -- Forever Well Fed: Agility + Stamina
        [1225780] = true, -- Forever Well Fed: Spell Damage/Healing + Stamina
        [1225782] = true, -- Forever Well Fed: AP/Spell/Healing + Stamina
        [1248421] = true, -- Forever Well Fed: Intellect
        [1248422] = true, -- Forever Well Fed: Strength
        [1249519] = true, -- Forever Well Fed: Attack Power
        [1249520] = true, -- Forever Well Fed: Spell Damage
        [1249521] = true, -- Forever Well Fed: Fishing Skill
        [1249523] = true, -- Forever Well Fed: Critical Strike
        [1248688] = true, -- Forever Well Fed: movement speed (Westfall)
        [1249926] = true, -- Forever Well Fed: Spirit
        [1294007] = true, -- Forever Well Fed: movement speed (Hyjal)
        [1302064] = true, -- Forever Well Fed: Strength variant
    },
    buffs_plainsrunning = {
        [1299038] = true, -- Plainsrunning active aura (Forever Tauren)
    },
    buffs_elemental_blessing = {
        [1259688] = true, -- Elemental Blessing (Skysight, 30 sec)
        [1270893] = true, -- Elemental Blessing (Skysight, 15 min)
    },
    debuffs_boosted_rest = {
        [1229451] = true, -- Boosted Rest camping cooldown debuff (Forever)
    },
    buffs_campfire_nearby = {
        [1283391] = true, -- Campfire Nearby (Forever)
    },
    buffs_welcoming_campfire = {
        [1229739] = true, -- Welcoming Campfire (Forever)
    },
    buffs_travel_utility = {
        [5697] = true, -- Unending Breath (Warlock)
        [546] = true,  -- Water Walking (Shaman)
        [1066] = true, -- Aquatic Form (Druid)
    },
    buffs_lightning_shield = {
        [324] = true,   -- Lightning Shield Rank 1
        [325] = true,   -- Lightning Shield Rank 2
        [905] = true,   -- Lightning Shield Rank 3
        [945] = true,   -- Lightning Shield Rank 4
        [8134] = true,  -- Lightning Shield Rank 5
        [10431] = true, -- Lightning Shield Rank 6
        [10432] = true, -- Lightning Shield Rank 7
        [408510] = true, -- Water Shield (Forever)
        [408514] = true, -- Earth Shield (Forever)
    },
    buffs_lone_wolf = {
        [1310684] = true, -- Lone Wolf visible buff (Forever)
    },
    buffs_ghostwolf = {
        [2645] = true, -- Ghost Wolf (Shaman)
    },
    buffs_ghostwolf_variants = {
        [415233] = true, -- Ghost Wolf (Forever variant)
        [1238640] = true, -- Ghost Wolf (Forever alternate/rank variant)
    },
    buffs_cheetah = {
        [5118] = true, -- Aspect of the Cheetah (Hunter)
    },
    buffs_warlock_armor = {
        [687] = true, -- Demon Skin Rank 1 (Warlock)
        [696] = true, -- Demon Skin Rank 2 (Warlock)
        [706] = true, -- Demon Armor Rank 1 (Warlock)
        [1086] = true, -- Demon Armor Rank 2 (Warlock)
        [11733] = true, -- Demon Armor Rank 3 (Warlock)
        [11734] = true, -- Demon Armor Rank 4 (Warlock)
        [11735] = true, -- Demon Armor Rank 5 (Warlock)
    },
    buffs_frost_armor = {
        [168] = true, -- Frost Armor Rank 1 (Mage)
        [7300] = true, -- Frost Armor Rank 2 (Mage)
        [7301] = true, -- Frost Armor Rank 3 (Mage)
        [12544] = true, -- Frost Armor (NPC/Forever visible variant)
        [15784] = true, -- Frost Armor (NPC/Forever ally-target variant)
    },
    buffs_other = {
        [23605] = true,
        [18137] = true, -- Shadowguard Rank 1 (Troll Priest)
        [19308] = true, -- Shadowguard Rank 2 (Troll Priest)
        [19309] = true, -- Shadowguard Rank 3 (Troll Priest)
        [19310] = true, -- Shadowguard Rank 4 (Troll Priest)
        [19311] = true, -- Shadowguard Rank 5 (Troll Priest)
        [19312] = true, -- Shadowguard Rank 6 (Troll Priest)
        [588] = true, -- Inner Fire Rank 1 (Priest)
        [7128] = true, -- Inner Fire Rank 2 (Priest)
        [602] = true, -- Inner Fire Rank 3 (Priest)
        [1006] = true, -- Inner Fire Rank 4 (Priest)
        [10951] = true, -- Inner Fire Rank 5 (Priest)
        [10952] = true, -- Inner Fire Rank 6 (Priest)
        [2652] = true, -- Touch of Weakness Rank 1 (Undead Priest)
        [19261] = true, -- Touch of Weakness Rank 2 (Undead Priest)
        [19262] = true, -- Touch of Weakness Rank 3 (Undead Priest)
        [19264] = true, -- Touch of Weakness Rank 4 (Undead Priest)
        [19265] = true, -- Touch of Weakness Rank 5 (Undead Priest)
        [19266] = true, -- Touch of Weakness Rank 6 (Undead Priest)
        [5487] = true, -- Bear Form
        [768] = true, -- Cat Form
        [783] = true, -- Travel Form
        [24858] = true, -- Moonkin Form
        [13163] = true, -- Aspect of the Monkey (Hunter)
        [13165] = true, -- Aspect of the Hawk Rank 1
        [14318] = true, -- Aspect of the Hawk Rank 2
        [14319] = true, -- Aspect of the Hawk Rank 3
        [14320] = true, -- Aspect of the Hawk Rank 4
        [14321] = true, -- Aspect of the Hawk Rank 5
        [14322] = true, -- Aspect of the Hawk Rank 6
        [25296] = true, -- Aspect of the Hawk Rank 7
        [20580] = true, -- Shadowmeld (Night Elf racial)
        [5215] = true, -- Prowl Rank 1 (Druid)
        [6783] = true, -- Prowl Rank 2 (Druid)
        [9913] = true, -- Prowl Rank 3 (Druid)
        [1784] = true, -- Stealth Rank 1 (Rogue)
        [1785] = true, -- Stealth Rank 2 (Rogue)
        [1786] = true, -- Stealth Rank 3 (Rogue)
        [1787] = true, -- Stealth Rank 4 (Rogue)
    },
}


