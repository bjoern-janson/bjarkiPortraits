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

local function unionExcept(excludeCategory, ...)
    local result = union(...)
    for spellID in pairs(C[excludeCategory] or {}) do result[spellID] = nil end
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
-- share a lane are unioned before the secure engine sees them. Native ordering
-- uses AuraInstanceID; BaselineClass and Healing can replace their native owner
-- only with a complete readable application-time election.
R.TIERS = {
    exact("PassiveSpeed", "HELPFUL", 9, true, C.buffs_passive_speed, true),
    exact("Plainsrunning", "HELPFUL", 10, true, union("buffs_plainsrunning", "buffs_elemental_blessing"), true),
    exact("BoostedRest", "HARMFUL", 1, false, C.debuffs_boosted_rest, true),
    exact("CampfireNearby", "HELPFUL", 2, true, C.buffs_campfire_nearby),
    exact("Cosmetic", "HELPFUL", 1, true, C.buffs_cosmetic),
    exact("Tracking", "HELPFUL", 0, true, C.buffs_tracking),
    exact("TravelUtility", "HELPFUL", 50, true, C.buffs_travel_utility),
    -- Persistent item/queue status stays below passive class and totem buffs.
    exact("PassiveDebuff", "HARMFUL", 59, false, C.debuffs_passive, true),
    exact("RighteousFury", "HELPFUL", 59, true, C.buffs_righteous_fury),
    exact("PaladinAura", "HELPFUL", 60, true,
        union("buffs_paladin_auras", "buffs_warlock_armor", "buffs_minor_world")),
    exact("BloodPact", "HELPFUL", 70, true,
        union("buffs_blood_pact", "buffs_furious_howl", "buffs_minor_class")),
    exact("Scrolls", "HELPFUL", 80, true, C.buffs_scrolls),
    exact("BaselineClass", "HELPFUL", 90, true,
        union("buffs_class_baseline", "buffs_camp_benefits")),
    exact("WellFed", "HELPFUL", 110, true, C.buffs_well_fed),
    exact("Thorns", "HELPFUL", 120, true, C.buffs_thorns),
    exact("ElementalShield", "HELPFUL", 130, true, C.buffs_lightning_shield),
    exact("SelfState", "HELPFUL", 150, true, union("buffs_other", "buffs_frost_armor")),
    -- Carried objectives outrank forms and Inner Fire, below active Utility.
    exact("BattlegroundFlag", "HELPFUL", 151, true, C.buffs_battleground_flag, true),
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
    -- Forever. This broad secure lane is only a visibility fallback when hostile
    -- aura identities are not readable to Lua. Keep it at the bottom so its
    -- arbitrary winner cannot mask any classified category above it.
    semantic("HostileHelpful", "HELPFUL|INCLUDE_NAME_PLATE_ONLY", 3),

    exact("Mobility", "HELPFUL|INCLUDE_NAME_PLATE_ONLY", 160, true,
        union("buffs_ghostwolf", "buffs_ghostwolf_variants", "buffs_cheetah", "buffs_mobility"), true),
    exact("LoneWolf", "HELPFUL|INCLUDE_NAME_PLATE_ONLY", 170, true, C.buffs_lone_wolf, true),
    exact("HuntersMark", "HARMFUL|INCLUDE_NAME_PLATE_ONLY", 180, false, C.debuffs_hunters_mark),

    -- Small friendly derived frames (ToT/FoT) sit on the relation side where
    -- exact harmful spell-ID filtering can be unavailable. This broad secure
    -- lane means only "some harmful state is present". Keep it below tactical
    -- categories and above the passive tracking/cosmetic/camping bottom band.
    semantic("SmallFriendlyHarmful", "HARMFUL|INCLUDE_NAME_PLATE_ONLY", 4),

    exact("Demoralizing", "HARMFUL", 185, false, C.debuffs_demoralizing),
    exact("Consecration", "HARMFUL", 189, false, C.debuffs_consecration, true),
    exact("DoTs", "HARMFUL", 190, false, C.debuffs_dots),
    exact("Seal", "HELPFUL", 210, true, union("buffs_seals", "buffs_improved_stormstrike")),
    -- Schedule public per-aura exceptions on self/friendly units as well;
    -- Blizzard still rejects each identity that is not permitted for the unit.
    exact("Slows", "HARMFUL|INCLUDE_NAME_PLATE_ONLY", 220, false,
        union("slows", "slows_chilled"), true),
    -- 12544 Frost Armor procs spell 6136 Chilled. In combat its identity is
    -- secret, but its safe metadata remains distinctive: harmful Magic,
    -- <=5 seconds, nameplate-personal, and not cast by the player/pet.
    -- Keep the approximation below exact Slows when both native containers
    -- are eligible; an absent public member must not hide this fallback.
    semantic("ChilledSignature", "HARMFUL|INCLUDE_NAME_PLATE_ONLY", 219, {
        includeDispelTypes = { Magic = true },
        maxDuration = 5.1,
        nameplateShowPersonal = true,
        isFromPlayerOrPlayerPet = false,
    }),
    exact("WeakenedSoul", "HARMFUL", 230, false, C.debuffs_weakenedsoul),
    exact("RecentlyBandaged", "HARMFUL", 229, false, C.debuffs_recently_bandaged, true),
    semantic("WeakenedSoulFallback", "HARMFUL", 228, {
        maxDuration = 15.1,
        excludeSpellIDs = C.debuffs_dots,
        excludeDispelTypes = { Magic = true, Curse = true, Disease = true, Poison = true, Bleed = true },
    }),
    semantic("PriorityDebuff", "HARMFUL", 238, { isPriorityAura = true }),
    exact("Forbearance", "HARMFUL", 240, false, C.debuffs_priority, true),
    exact("ResSickness", "HARMFUL", 241, false, C.debuffs_res_sickness, true),
    exact("Healing", "HELPFUL", 255, true, union("buffs_shield", "buffs_hots")),
    exact("PowerWordShield", "HELPFUL", 256, true, C.buffs_power_word_shield),
    -- PvP Honorless status outranks routine healing-over-time auras such as Renew.
    exact("HonorlessTarget", "HELPFUL|INCLUDE_NAME_PLATE_ONLY", 257, true, C.buffs_honorless_target, true),
    -- Recovery/consumable channel category remains above routine harmful DoTs;
    -- hostile readable election uses this same category level in battlegrounds.
    exact("FoodDrink", "HELPFUL", 260, true, C.buffs_fooddrink),
    -- Innervate, Druid Enrage, Warrior Bloodrage, and resource-recovery states intentionally share one
    -- actual priority surface so equal-priority recency is arbitrated inside
    -- one lane.
    exact("Innervate", "HELPFUL", 261, true,
        union("buffs_innervate", "buffs_druid_enrage", "buffs_bloodrage")),
    -- One actual Utility lane. Welcoming Campfire shares this secure slot so
    -- equal-priority effects cannot stack independent cooldown widgets.
    exact("Utility", "HELPFUL|INCLUDE_NAME_PLATE_ONLY", 270, true,
        union("buffs_utility", "buffs_welcoming_campfire")),
    -- IMPORTANT is a broad client flag, not a PvP priority class. It is the
    -- fallback for otherwise unclassified important buffs; explicit categories
    -- and dedicated Big/External defensive lanes outrank it.
    semantic("Important", "HELPFUL|IMPORTANT|!BIG_DEFENSIVE|!EXTERNAL_DEFENSIVE", 85),
    -- Faerie Fire, curses, taunts, combat penalties and environmental danger
    -- share one status-effect election immediately below offensive cooldowns.
    -- Preserve Shark Attack's existing per-aura NeverSecret eligibility.
    exact("StatusEffects", "HARMFUL|INCLUDE_NAME_PLATE_ONLY", 279, false,
        union("debuffs_other", "debuffs_taunts", "debuffs_casting_penalty", "debuffs_attack_penalty",
            "debuffs_healing_reduction", "debuffs_environmental_danger"), true),
    exact("Offensive", "HELPFUL", 280, true, C.buffs_offensive),
    -- Death Wish is harmful offensive state. One level above helpful offense
    -- gives simultaneous cooldowns a deterministic order within this band.
    exact("OffensiveHarmful", "HARMFUL", 281, false, C.debuffs_offensive, true),
    semantic("ExternalDef", "HELPFUL|EXTERNAL_DEFENSIVE", 288),
    semantic("BigDef", "HELPFUL|BIG_DEFENSIVE", 289),
    exact("Defensive", "HELPFUL", 290, true, C.buffs_defensive),
    -- Defensive racials are one PvP category: let Stoneform and Will of the
    -- Forsaken outrank offensive cooldowns, including when their IDs are safe
    -- for secure hostile filtering.
    exact("RacialDefensive", "HELPFUL", 291, true, C.buffs_racial_defensive, true),
    exact("Roots", "HARMFUL", 300, false, C.roots),
    -- Movement/casting immunity and spell redirection share one protection lane.
    exact("RootImmunity", "HELPFUL", 305, true,
        union("immunities_root", "immunities_interrupt", "buffs_grounding"), true),
    semantic("CrowdControl", "HARMFUL|CROWD_CONTROL", 309),
    -- Harmful stuns are conceptually CC, but exact lanes must be disjoint:
    -- the dedicated 320 Stun lane owns every harmful stun ID.
    exact("Control", "HARMFUL", 310, false, unionExcept("stuns", "interrupts", "cc")),
    exact("PhysicalImmunity", "HELPFUL", 315, true, C.immunities_physical, true),
    exact("Stun", "HARMFUL", 320, false, C.stuns),
    -- Cocoon's self-stun is currently HELPFUL in the client spell data.
    exact("HelpfulSelfStun", "HELPFUL", 320, true, C.buffs_self_stun, true),
    exact("ImmunityHarmful", "HARMFUL", 330, false, C.immunities_harmful),
    exact("Immunity", "HELPFUL", 330, true, C.immunities),
    -- Keep Divine Protection independently eligible for safe hostile exact
    -- identity, above Forbearance and the ordinary Immunity lane.
    exact("DivineProtection", "HELPFUL", 331, true, C.buffs_divine_protection, true),
    -- Secure buttons use tier + 1; Ghost's state witness uses Immunity + 2.
    -- Level 332 makes resurrection waiting and the dead-only speed aura
    -- visibly outrank Ghost without inferring either aura from death state.
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
