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

local function unionExcept(excludeCategories, ...)
    local result = union(...)
    if type(excludeCategories) == "string" then excludeCategories = { excludeCategories } end
    for _, category in ipairs(excludeCategories) do
        for spellID in pairs(C[category] or {}) do result[spellID] = nil end
    end
    return result
end

local function exact(key, filter, level, helpful, spellIDs, allowNeverSecret, directWitnessSpellIDs)
    return {
        key = key, filter = filter, level = level, helpful = helpful and true or false,
        spellIDs = spellIDs, exact = true, allowNeverSecret = allowNeverSecret and true or false,
        directWitnessSpellIDs = directWitnessSpellIDs,
    }
end

local function semantic(key, filter, level, candidateFilters)
    return { key = key, filter = filter, level = level, semantic = true, candidateFilters = candidateFilters }
end

-- One container represents one actual priority lane. Categories that genuinely
-- share a lane are unioned before the secure engine sees them. Native ordering
-- uses AuraInstanceID; BaselineClass, Healing and StatusEffects can replace their native owner
-- only with a complete readable application-time election.
R.TIERS = {
    -- Lowest informational lanes immediately above the race-portrait baseline.
    exact("Gathering", "HELPFUL", 1, true, C.buffs_gathering),
    exact("Tracking", "HELPFUL", 3, true, C.buffs_tracking),
    -- Informational harmful effects share the actual nearby-world level.
    exact("CampfireNearby", "HELPFUL", 4, true, C.buffs_campfire_nearby),
    exact("CampfireNearbyHarmful", "HARMFUL", 4, false,
        union("debuffs_campfire_nearby", "debuffs_noncombat", "debuffs_boosted_rest"), true),
    -- Opposite-faction helpful fallback is deliberately low; do not infer a
    -- category from a restricted, arbitrary timed aura.
    semantic("HostileHelpful", "HELPFUL|INCLUDE_NAME_PLATE_ONLY", 5, { maxDuration = math.huge }),

    exact("PassiveSpeed", "HELPFUL", 9, true, C.buffs_passive_speed, true),
    exact("Plainsrunning", "HELPFUL", 10, true,
        union("buffs_plainsrunning", "buffs_elemental_blessing", "buffs_righteous_fury"), true),
    exact("TravelUtility", "HELPFUL", 50, true, C.buffs_travel_utility),
    exact("PassiveDebuff", "HARMFUL", 59, false, C.debuffs_passive, true),
    exact("PaladinAura", "HELPFUL", 60, true,
        union("buffs_paladin_auras", "buffs_warlock_armor", "buffs_minor_world")),
    exact("BloodPact", "HELPFUL", 70, true,
        union("buffs_blood_pact", "buffs_furious_howl", "buffs_minor_class")),
    exact("Scrolls", "HELPFUL", 80, true, C.buffs_scrolls),
    exact("Elixirs", "HELPFUL", 81, true, C.buffs_elixirs, true),
    semantic("Important", "HELPFUL|IMPORTANT|!BIG_DEFENSIVE|!EXTERNAL_DEFENSIVE", 85),
    exact("BaselineClass", "HELPFUL", 90, true,
        union("buffs_class_baseline", "buffs_camp_benefits")),
    exact("BaselineClassHarmful", "HARMFUL", 90, false, C.debuffs_class_baseline, true),
    exact("WellFed", "HELPFUL", 110, true, C.buffs_well_fed),
    exact("Thorns", "HELPFUL", 120, true, C.buffs_thorns),

    -- Ordinary forms, armor, Shaman shields and other persistent self states
    -- share one helpful lane. No Frost Armor signature guess is required.
    exact("SelfState", "HELPFUL", 150, true,
        union("buffs_other", "buffs_frost_armor", "buffs_lightning_shield")),
    exact("Mobility", "HELPFUL|INCLUDE_NAME_PLATE_ONLY", 160, true,
        union("buffs_ghostwolf", "buffs_ghostwolf_variants", "buffs_cheetah", "buffs_mobility"), true),
    exact("LoneWolf", "HELPFUL|INCLUDE_NAME_PLATE_ONLY", 170, true, C.buffs_lone_wolf, true),
    semantic("SmallFriendlyHarmful", "HARMFUL|INCLUDE_NAME_PLATE_ONLY", 175),
    exact("HuntersMark", "HARMFUL|INCLUDE_NAME_PLATE_ONLY", 180, false, C.debuffs_hunters_mark),
    exact("Demoralizing", "HARMFUL", 185, false, C.debuffs_demoralizing, true),
    exact("Consecration", "HARMFUL", 189, false, C.debuffs_consecration, true),
    exact("DoTs", "HARMFUL", 190, false, C.debuffs_dots),

    -- Preserve the pre-overhaul slow priority; no change was requested.
    exact("Slows", "HARMFUL|INCLUDE_NAME_PLATE_ONLY", 278, false,
        union("slows", "slows_chilled"), true),
    exact("Dazed", "HARMFUL|INCLUDE_NAME_PLATE_ONLY", 279, false, C.slows_dazed, true),
    exact("Seal", "HELPFUL", 210, true, union("buffs_seals", "buffs_improved_stormstrike")),
    -- Restore Roots to their pre-overhaul priority of 300; the user did not
    -- request a change to their relation with offensive/defensive cooldowns.
    -- Nature's Grasp's self-buff stays Utility; only its proc roots are Roots.
    exact("Roots", "HARMFUL", 300, false, C.roots),

    -- Utility was overpromoted above offensive and defensive cooldowns. The
    -- Blink aura IDs now belong to RootImmunity, if the client exposes them.
    exact("Utility", "HELPFUL|INCLUDE_NAME_PLATE_ONLY", 225, true, C.buffs_utility),
    -- One exact harmful priority for Weakened Soul, Recently Bandaged and
    -- Wandering Plague. Retire the uncertain 15-second shape-based fallback.
    exact("Wounds", "HARMFUL", 230, false,
        union("debuffs_weakenedsoul", "debuffs_recently_bandaged"), true),
    semantic("PriorityDebuff", "HARMFUL", 238, { isPriorityAura = true }),
    exact("Forbearance", "HARMFUL", 240, false, C.debuffs_priority, true),

    exact("Healing", "HELPFUL", 251, true, union("buffs_shield", "buffs_hots")),
    exact("StatusEffects", "HARMFUL|INCLUDE_NAME_PLATE_ONLY", 253, false,
        union("debuffs_other", "debuffs_taunts", "debuffs_casting_penalty",
            "debuffs_attack_penalty", "debuffs_healing_reduction",
            "debuffs_environmental_danger", "debuffs_res_sickness"),
        true, C.debuffs_res_sickness),
    exact("ResurrectionSickness", "HARMFUL|INCLUDE_NAME_PLATE_ONLY", 255, false,
        C.debuffs_resurrection_sickness, true, C.debuffs_resurrection_sickness),
    -- Ice Barrier and Power Word: Shield are now in the same absorb lane.
    exact("PowerWordShield", "HELPFUL", 256, true, C.buffs_power_word_shield),
    -- Campfire and the Darkspear flag share this informational status band.
    exact("HonorlessTarget", "HELPFUL|INCLUDE_NAME_PLATE_ONLY", 257, true,
        union("buffs_honorless_target", "buffs_battleground_flag",
            "buffs_welcoming_campfire"), true),
    exact("MinorRegen", "HELPFUL", 259, true, C.buffs_minor_regen),
    exact("FoodDrink", "HELPFUL", 260, true, C.buffs_fooddrink),
    exact("Innervate", "HELPFUL", 261, true,
        union("buffs_innervate", "buffs_druid_enrage", "buffs_bloodrage")),

    -- Helpful and harmful cannot share one Blizzard AuraContainer filter, but
    -- identical levels make them a *single* offensive priority category.
    exact("Offensive", "HELPFUL", 280, true, C.buffs_offensive),
    exact("OffensiveHarmful", "HARMFUL", 280, false, C.debuffs_offensive, true),
    semantic("ExternalDef", "HELPFUL|EXTERNAL_DEFENSIVE", 288),
    semantic("BigDef", "HELPFUL|BIG_DEFENSIVE", 289),
    exact("Defensive", "HELPFUL", 290, true,
        union("buffs_defensive", "buffs_racial_defensive")),

    exact("RootImmunity", "HELPFUL", 305, true, C.immunities_root, true),
    -- Casting lockouts are not always duration-bearing auras. Exact positive
    -- applied silence IDs share this lane with the reviewed interrupt IDs;
    -- neither a cast alone nor a school-lock inference creates a portrait aura.
    exact("InterruptSilence", "HARMFUL|INCLUDE_NAME_PLATE_ONLY", 306, false,
        union("interrupts", "silences"), true),
    semantic("CrowdControl", "HARMFUL|CROWD_CONTROL", 309),
    exact("Control", "HARMFUL", 310, false,
        unionExcept({"stuns", "interrupts", "silences"}, "cc")),
    -- Free Action is grouped here for display priority: it prevents stun,
    -- snare and root mechanics, not physical damage itself.
    exact("PhysicalImmunity", "HELPFUL", 315, true, C.immunities_physical, true),
    -- Grounding redirects one hostile spell. Voice of Truth prevents Silence
    -- and Interrupt; neither is a root immunity.
    exact("SpellImmunity", "HELPFUL", 316, true,
        union("immunities_interrupt", "buffs_grounding"), true),
    -- All verified applied stun auras belong here, including Charge Stun,
    -- Intercept Stun, Cheap Shot and Pounce's short stun (not its long bleed).
    exact("Stun", "HARMFUL", 320, false, C.stuns, true),
    exact("HelpfulSelfStun", "HELPFUL", 320, true, C.buffs_self_stun, true),
    exact("ImmunityHarmful", "HARMFUL", 330, false, C.immunities_harmful, true),
    -- Reserve this lane for actual immunity auras. Divine Protection belongs
    -- here per the requested consolidation. Will of the Forsaken has no
    -- observed Forever buff and must not be invented as a portrait aura.
    -- Reflection Field remains a reactive Thorns-tier effect.
    exact("Immunity", "HELPFUL", 330, true,
        union("immunities", "buffs_divine_protection"), true),
    exact("WaitingToResurrect", "HELPFUL", 332, true,
        union("buffs_waiting_to_resurrect", "buffs_ghost_speed"), true),
}

-- Immutable lookup indexes derived once from the frozen tier table. These do
-- not change priority semantics; they only replace repeated linear scans.
R.TIER_BY_KEY = {}
R.HELPFUL_TIER_BY_SPELL = {}

local exactOwners = {}
local exactOverlaps = {}
local exactLaneCount, exactMemberships, distinctExactSpellIDs = 0, 0, 0

for _, tier in ipairs(R.TIERS) do
    if tier.key then
        R.TIER_BY_KEY[tier.key] = tier
    end

    if tier.exact then
        exactLaneCount = exactLaneCount + 1
        for spellID in pairs(tier.spellIDs or {}) do
            exactMemberships = exactMemberships + 1

            local owner = exactOwners[spellID]
            if not owner then
                exactOwners[spellID] = tier.key
                distinctExactSpellIDs = distinctExactSpellIDs + 1
            elseif owner ~= tier.key then
                exactOverlaps[#exactOverlaps + 1] = {
                    spellID = spellID,
                    first = owner,
                    second = tier.key,
                }
            end

            if tier.helpful then
                local current = R.HELPFUL_TIER_BY_SPELL[spellID]
                if not current or (tier.level or 0) > (current.level or 0) then
                    R.HELPFUL_TIER_BY_SPELL[spellID] = tier
                end
            end
        end
    end
end

R.TIER_AUDIT = {
    exactLaneCount = exactLaneCount,
    exactMemberships = exactMemberships,
    distinctExactSpellIDs = distinctExactSpellIDs,
    overlapCount = #exactOverlaps,
    overlaps = exactOverlaps,
}

local helpfulExplicit, harmfulExplicit = {}, {}
for _, tier in ipairs(R.TIERS) do
    if tier.exact then
        local destination = tier.helpful and helpfulExplicit or harmfulExplicit
        for spellID in pairs(tier.spellIDs or {}) do destination[spellID] = true end
    end
end

-- Low-priority exact auras must never be PROMOTED by unrelated high semantic
-- fallbacks (IMPORTANT, hostile helpful, or generic harmful). The exclusion
-- sets filter those broad lanes, not the explicit Gathering/Tracking/info lanes.
-- Restricted hostile identities may still prevent enforcing the exclusions;
-- never infer an inaccessible aura's spell ID.
local excludedHelpful = union("buffs_gathering", "buffs_tracking", "buffs_campfire_nearby",
    "buffs_cosmetic", "buffs_noncombat")
local excludedHarmful = union("debuffs_campfire_nearby", "debuffs_noncombat", "debuffs_boosted_rest")
for spellID in pairs(excludedHelpful) do helpfulExplicit[spellID] = true end
for spellID in pairs(excludedHarmful) do harmfulExplicit[spellID] = true end
R.NONCOMBAT_EXCLUDED_HELPFUL = excludedHelpful
R.NONCOMBAT_EXCLUDED_HARMFUL = excludedHarmful

function R.CandidateFilters(tier)
    if tier.exact then return { includeSpellIDs = tier.spellIDs } end
    local out = {}
    for key, value in pairs(tier.candidateFilters or {}) do out[key] = value end
    if tier.key == "Important" or tier.key == "ExternalDef" or tier.key == "BigDef" then
        out.excludeSpellIDs = helpfulExplicit
    elseif tier.key == "HostileHelpful" then
        out.excludeSpellIDs = excludedHelpful
    elseif tier.key == "SmallFriendlyHarmful" then
        out.excludeSpellIDs = excludedHarmful
    elseif tier.key == "CrowdControl" or tier.key == "PriorityDebuff" then
        out.excludeSpellIDs = harmfulExplicit
    end
    return next(out) and out or nil
end
