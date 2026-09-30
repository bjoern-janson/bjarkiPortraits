local addonName, BP = ...
local R = assert(BP.Runtime, "Core.lua must load first")
local C = BP.categories or {}

local function union(...)
    local result = {}
    for i = 1, select("#", ...) do
        local set = C[select(i, ...)]
        for spellID in pairs(set or {}) do result[spellID] = true end
    end
    return result
end

local function exact(key, filter, level, helpful, spellIDs, allowNeverSecret)
    return {
        key = key, filter = filter, level = level, helpful = helpful and true or false,
        spellIDs = spellIDs, exact = true, allowNeverSecret = allowNeverSecret and true or false,
    }
end

local function semantic(key, filter, level, candidateFilters)
    return { key = key, filter = filter, level = level, semantic = true, candidateFilters = candidateFilters }
end

-- One container represents one actual priority lane. Categories that genuinely
-- share a lane are unioned before the secure engine sees them, so recency within
-- that lane is decided by AuraInstanceID rather than by sibling-frame accident.
R.TIERS = {
    exact("Plainsrunning", "HELPFUL", 10, true, union("buffs_plainsrunning", "buffs_elemental_blessing"), true),
    exact("BoostedRest", "HARMFUL", 20, false, C.debuffs_boosted_rest, true),
    exact("CampfireNearby", "HELPFUL", 30, true, C.buffs_campfire_nearby),
    exact("TravelUtility", "HELPFUL", 50, true, C.buffs_travel_utility),
    exact("RighteousFury", "HELPFUL", 59, true, C.buffs_righteous_fury),
    exact("PaladinAura", "HELPFUL", 60, true, union("buffs_paladin_auras", "buffs_warlock_armor")),
    exact("BloodPact", "HELPFUL", 70, true, C.buffs_blood_pact),
    exact("Scrolls", "HELPFUL", 80, true, C.buffs_scrolls),
    exact("BaselineClass", "HELPFUL", 90, true, C.buffs_class_baseline),
    exact("CampBenefits", "HELPFUL", 100, true, C.buffs_camp_benefits),
    exact("Thorns", "HELPFUL", 120, true, C.buffs_thorns),
    exact("WellFed", "HELPFUL", 125, true, C.buffs_well_fed),
    exact("ElementalShield", "HELPFUL", 130, true, C.buffs_lightning_shield),
    exact("SelfState", "HELPFUL", 150, true, union("buffs_other", "buffs_frost_armor")),
    -- Combat-safe hostile-NPC fallback for Frost Armor when spell identity is
    -- sealed. 12544 is a 30-minute Magic buff and is spellstealable from NPCs.
    -- This lane is enabled only for hostile NPCs when the readable exact path
    -- has disappeared, so it cannot broaden ordinary readable behavior.
    semantic("FrostArmorSignature", "HELPFUL|INCLUDE_NAME_PLATE_ONLY", 150, {
        includeDispelTypes = { Magic = true },
        maxDuration = 1800.1,
        isFromPlayerOrPlayerPet = false,
    }),

    -- Opposite-faction exact helpful identity filters are relation-restricted in
    -- Forever. This deliberately broad secure lane is enabled only when hostile
    -- aura identities are not readable to addon Lua. When identities are
    -- readable, AuraEngine renders only explicitly tracked helpful spells.
    semantic("HostileHelpful", "HELPFUL|INCLUDE_NAME_PLATE_ONLY", 150),

    exact("Mobility", "HELPFUL|INCLUDE_NAME_PLATE_ONLY", 160, true,
        union("buffs_ghostwolf", "buffs_ghostwolf_variants", "buffs_cheetah"), true),
    exact("LoneWolf", "HELPFUL|INCLUDE_NAME_PLATE_ONLY", 170, true, C.buffs_lone_wolf, true),
    exact("HuntersMark", "HARMFUL|INCLUDE_NAME_PLATE_ONLY", 180, false, C.debuffs_hunters_mark),

    -- Small friendly derived frames (ToT/FoT) sit on the relation side where
    -- exact harmful spell-ID filtering can be unavailable. This broad secure
    -- lane means only "some harmful state is present", so it is deliberately
    -- the lowest-priority aura surface. Any known tracked state must outrank it.
    semantic("SmallFriendlyHarmful", "HARMFUL|INCLUDE_NAME_PLATE_ONLY", 1),

    exact("DoTs", "HARMFUL", 190, false, C.debuffs_dots),
    exact("LowDebuff", "HARMFUL|INCLUDE_NAME_PLATE_ONLY", 200, false, C.debuffs_other),
    exact("Seal", "HELPFUL", 210, true, C.buffs_seals),
    exact("Slows", "HARMFUL|INCLUDE_NAME_PLATE_ONLY", 220, false,
        union("slows", "slows_chilled")),
    -- 12544 Frost Armor procs spell 6136 Chilled. In combat its identity is
    -- secret, but its safe metadata remains distinctive: harmful Magic,
    -- <=5 seconds, nameplate-personal, and not cast by the player/pet.
    semantic("ChilledSignature", "HARMFUL|INCLUDE_NAME_PLATE_ONLY", 220, {
        includeDispelTypes = { Magic = true },
        maxDuration = 5.1,
        nameplateShowPersonal = true,
        isFromPlayerOrPlayerPet = false,
    }),
    exact("WeakenedSoul", "HARMFUL", 230, false, C.debuffs_weakenedsoul),
    semantic("WeakenedSoulFallback", "HARMFUL", 229, {
        maxDuration = 15.1,
        excludeSpellIDs = C.debuffs_dots,
        excludeDispelTypes = { Magic = true, Curse = true, Disease = true, Poison = true, Bleed = true },
    }),
    semantic("PriorityDebuff", "HARMFUL", 238, { isPriorityAura = true }),
    exact("Forbearance", "HARMFUL", 240, false, C.debuffs_priority, true),
    exact("ResSickness", "HARMFUL", 241, false, C.debuffs_res_sickness, true),
    exact("HonorlessTarget", "HELPFUL|INCLUDE_NAME_PLATE_ONLY", 242, true, C.buffs_honorless_target, true),
    exact("Shield", "HELPFUL", 250, true, C.buffs_shield),
    exact("FoodDrink", "HELPFUL", 260, true, C.buffs_fooddrink),
    exact("Innervate", "HELPFUL", 261, true, C.buffs_innervate),
    -- One actual Utility lane. Welcoming Campfire shares this secure slot so
    -- equal-priority effects cannot stack independent cooldown widgets.
    exact("Utility", "HELPFUL|INCLUDE_NAME_PLATE_ONLY", 270, true,
        union("buffs_utility", "buffs_welcoming_campfire")),
    semantic("Important", "HELPFUL|IMPORTANT|!BIG_DEFENSIVE|!EXTERNAL_DEFENSIVE", 279),
    exact("Offensive", "HELPFUL", 280, true, C.buffs_offensive),
    semantic("ExternalDef", "HELPFUL|EXTERNAL_DEFENSIVE", 288),
    semantic("BigDef", "HELPFUL|BIG_DEFENSIVE", 289),
    exact("Defensive", "HELPFUL", 290, true, C.buffs_defensive),
    exact("Roots", "HARMFUL", 300, false, C.roots),
    semantic("CrowdControl", "HARMFUL|CROWD_CONTROL", 309),
    exact("Control", "HARMFUL", 310, false, union("interrupts", "cc")),
    exact("Stun", "HARMFUL", 320, false, C.stuns),
    exact("Immunity", "HELPFUL", 330, true, C.immunities),
}

local helpfulExplicit, harmfulExplicit = {}, {}
for _, tier in ipairs(R.TIERS) do
    if tier.exact then
        local destination = tier.helpful and helpfulExplicit or harmfulExplicit
        for spellID in pairs(tier.spellIDs or {}) do destination[spellID] = true end
    end
end

function R.CandidateFilters(tier)
    if tier.exact then return { includeSpellIDs = tier.spellIDs } end
    local out = {}
    for key, value in pairs(tier.candidateFilters or {}) do out[key] = value end
    if tier.key == "Important" or tier.key == "ExternalDef" or tier.key == "BigDef" then
        out.excludeSpellIDs = helpfulExplicit
    elseif tier.key == "CrowdControl" or tier.key == "PriorityDebuff" then
        out.excludeSpellIDs = harmfulExplicit
    end
    return next(out) and out or nil
end
