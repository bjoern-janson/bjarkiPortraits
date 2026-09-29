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
        [6136] = true, -- Chilled (Frost Armor)
        [7321] = true, -- Chilled (Ice/Frost Armor family)
        [3600] = true, -- Earthbind (Earthbind Totem slow aura)
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
