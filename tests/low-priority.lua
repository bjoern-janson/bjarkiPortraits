-- Low-priority portrait aura policy, evaluated from the actual shipped
-- Spells.lua / Priority.lua modules. Pure Lua 5.1/5.4: no WoW globals.
local BP = { Runtime = {} }
assert(loadfile("Spells.lua"))("bjarkiPortraits", BP)
assert(loadfile("Priority.lua"))("bjarkiPortraits", BP)
local C, R = assert(BP.categories), assert(BP.Runtime)
local checks = 0
local function check(ok, label)
    assert(ok, label)
    checks = checks + 1
end
local function equal(actual, expected, label)
    check(actual == expected, label .. " (got " .. tostring(actual)
        .. ", wanted " .. tostring(expected) .. ")")
end
local gathering = assert(R.TIER_BY_KEY.Gathering)
local info = assert(R.TIER_BY_KEY.BoostedRest)
local bottomHelpful = assert(R.TIER_BY_KEY.BottomHelpful)
local tracking = assert(R.TIER_BY_KEY.Tracking)
local trackingHarmful = assert(R.TIER_BY_KEY.TrackingHarmful)
local ambient = assert(R.TIER_BY_KEY.CampfireNearby)
local ambientHarmful = assert(R.TIER_BY_KEY.CampfireNearbyHarmful)
local fallback = assert(R.TIER_BY_KEY.HostileHelpful)
local consumables = assert(R.TIER_BY_KEY.Consumables)

equal(gathering.level, 1, "Gathering remains priority one above bottom")
equal(info.level, 0, "passive informational harmful is absolute lowest aura tier")
equal(bottomHelpful.level, info.level, "helpful coin shares numeric bottom tier")
check(bottomHelpful.helpful and bottomHelpful.exact, "bottom helpful uses its own native exact polarity")
check(bottomHelpful.spellIDs[1321323] == true, "coin applied aura is bottom helpful")
equal(tracking.level, 3, "tracking/sensing immediately above gathering")
equal(trackingHarmful.level, tracking.level, "harmful tracking shares the informational priority")
equal(ambient.level, 4, "original ambient buff above tracking")
equal(ambientHarmful.level, 4, "nearby harmful stays at ambient level four")
equal(fallback.level, 5, "generic hostile fallback above the exact low lanes")
equal(consumables.level, 81, "minor and Well Fed auras share Consumables priority")
check(consumables.exact and consumables.helpful, "combined consumables band uses helpful exact filter")
check(R.TIER_BY_KEY.MinorHelpful == nil, "former minor helpful tier is retired")
check(R.TIER_BY_KEY.MinorHarmful == nil, "former empty harmful tier is retired")
check(R.TIER_BY_KEY.WellFed == nil, "former Well Fed tier is retired")
check(consumables.level < R.TIER_BY_KEY.BaselineClass.level,
    "combined elixir band remains below class and major world buffs")
check(gathering.helpful and gathering.exact, "gathering is exact helpful")
check(not info.helpful and info.exact, "informational effects are exact harmful")
check(tracking.helpful and tracking.exact, "tracking is exact helpful")
for _, tier in ipairs(R.TIERS) do
    if tier ~= gathering and tier ~= tracking and tier ~= trackingHarmful and tier ~= info and tier ~= bottomHelpful then
        check(tier.level >= 4, "all remaining aura tiers above race-fallback lanes: " .. tier.key)
    end
end

local gatheringIDs = {
    [2383] = "Find Herbs rank 1",
    [8387] = "Find Herbs rank 2",
    [2580] = "Find Minerals rank 1",
    [8388] = "Find Minerals rank 2",
    [2481] = "Find Treasure",
}
local infoIDs = {
    [24755] = "Tricked or Treated",
    [1229451] = "Boosted Rest",
    [19685] = "Tame Nightsaber Stalker",
    [19686] = "Tame Strigid Screecher",
}
local bottomSightIDs = {
    [1293681] = "Farsen's Far Sight",
    [6196] = "Shaman Far Sight",
    [6197] = "Hunter Eagle Eye",
    [126] = "Warlock Eye of Kilrogg",
}
local sensingIDs = {
    [5225] = "Track Humanoids (Druid)",
    [19883] = "Track Humanoids",
    [5500] = "Sense Demons",
    [5502] = "Sense Undead",
    [19878] = "Track Demons",
    [19879] = "Track Dragonkin",
    [19880] = "Track Elementals",
    [19882] = "Track Giants",
    [19884] = "Track Undead",
    [19885] = "Track Hidden",
    [1494] = "Track Beasts",
    [43308] = "Find Fish",
    [132] = "Detect Invisibility",
    [1462] = "Beast Lore",
}

for id, name in pairs(gatheringIDs) do
    check(C.buffs_gathering[id] == true, name .. " gathering category")
    check(gathering.spellIDs[id] == true, name .. " gathering display")
    check(C.buffs_tracking[id] == nil, name .. " not in tracking tier")
    check(R.HELPFUL_TIER_BY_SPELL[id] == gathering, name .. " indexed winner")
end
local gatheringCount = 0
for id in pairs(gathering.spellIDs) do
    gatheringCount = gatheringCount + 1
    check(gatheringIDs[id] ~= nil, "gathering contains no other tracking spells")
end
equal(gatheringCount, 5, "five gathering ranks including Find Treasure at level one")
for id, name in pairs(infoIDs) do
    check(info.spellIDs[id] == true, name .. " harmful display")
    check(R.NONCOMBAT_EXCLUDED_HARMFUL[id] == true,
        name .. " cannot be promoted by generic harmful fallback")
end
for id, name in pairs({[1296202]="Rat Familiar (+2 Int)",
    [1292142]="Benevolence (4 HP/5s)"}) do
    check(C.buffs_minor_world[id] == true, name .. " classified as very minor")
    check(consumables.spellIDs[id] == true, name .. " native consumables-tier member")
    check(R.HELPFUL_TIER_BY_SPELL[id] == consumables, name .. " indexed at 81")
    check(R.TIER_BY_KEY.BaselineClass.spellIDs[id] == nil,
        name .. " must never take the class/world-buff portrait")
    check(R.CandidateFilters(consumables).includeSpellIDs[id] == true,
        name .. " native spell filter includes verified minor effect")
    check(R.CandidateFilters(R.TIER_BY_KEY.HostileHelpful).excludeSpellIDs[id] == true,
        name .. " excluded from generic hostile helpful fallback")
    check(R.CandidateFilters(R.TIER_BY_KEY.Important).excludeSpellIDs[id] == true,
        name .. " excluded from high semantic Important fallback")
end
check(R.TIER_BY_KEY.PassiveDebuff.spellIDs[26013] == true,
    "Deserter remains original level-59 passive debuff")
check(R.TIER_BY_KEY.PassiveDebuff.spellIDs[1292749] == true,
    "Martyrdom remains original level-59 passive debuff")
check(R.TIER_BY_KEY.BoostedRest.spellIDs[24755] == true,
    "Tricked or Treated stays at absolute bottom, not silently promoted")
for id, name in pairs(bottomSightIDs) do
    check(C.buffs_bottom[id] == true, name .. " bottom helpful source category")
    check(bottomHelpful.level == 0, name .. " absolute bottom numeric tier")
    check(bottomHelpful.filter == "HELPFUL", name .. " polarity stays helpful")
    check(bottomHelpful.spellIDs[id] == true, name .. " native bottom candidate")
    check(C.buffs_tracking[id] == nil, name .. " demoted out of tracking")
    check(tracking.spellIDs[id] == nil, name .. " no tracking overlap")
    check(R.HELPFUL_TIER_BY_SPELL[id] == bottomHelpful,
        name .. " indexed tier follows bottom helpful")
    check(R.NONCOMBAT_EXCLUDED_HELPFUL[id] == true,
        name .. " no generic helpful promotion")
end
for id, name in pairs(sensingIDs) do
    check(C.buffs_tracking[id] == true, name .. " tracking category")
    check(tracking.spellIDs[id] == true, name .. " tracking display")
    check(R.HELPFUL_TIER_BY_SPELL[id] == tracking, name .. " indexed winner")
end
for id in pairs(C.buffs_tracking) do
    check(tracking.spellIDs[id], "all tracking IDs have an exact visible tier")
    check(not C.buffs_gathering[id], "tracking and gathering are disjoint")
end
for _, tier in ipairs(R.TIERS) do
    if tier.exact and tier ~= gathering and tier ~= tracking and tier ~= info then
        for id in pairs(gatheringIDs) do
            check(not tier.spellIDs[id], "gathering not duplicated in " .. tier.key)
        end
        for id in pairs(infoIDs) do
            check(not tier.spellIDs[id], "info debuffs not duplicated in " .. tier.key)
        end
        if tier ~= bottomHelpful then
            for id in pairs(bottomSightIDs) do
                check(not tier.spellIDs[id], "bottom sight not duplicated in " .. tier.key)
            end
        end
        for id in pairs(sensingIDs) do
            check(not tier.spellIDs[id], "tracking not duplicated in " .. tier.key)
        end
    end
end

local function filter(key)
    return assert(R.CandidateFilters(assert(R.TIER_BY_KEY[key])))
end
for id in pairs(gatheringIDs) do
    check(filter("Gathering").includeSpellIDs[id] == true, "secure gathering filter")
    check(filter("HostileHelpful").excludeSpellIDs[id] == true,
        "generic hostile helpful does not promote gathering")
    check(filter("Important").excludeSpellIDs[id] == true,
        "IMPORTANT does not promote gathering")
end
for id in pairs(bottomSightIDs) do
    check(filter("BottomHelpful").includeSpellIDs[id] == true,
        "secure native bottom helpful candidate")
    for _, tier in ipairs({"Important", "HostileHelpful", "BigDef", "ExternalDef"}) do
        check(filter(tier).excludeSpellIDs[id] == true,
            "generic " .. tier .. " cannot promote low-priority viewpoint status")
    end
end
check(R.TIER_AUDIT.overlapCount == 0, "no exact-tier overlaps after viewpoint demotion")
for id in pairs(sensingIDs) do
    check(filter("Tracking").includeSpellIDs[id] == true, "secure tracking filter")
    check(filter("HostileHelpful").excludeSpellIDs[id] == true,
        "generic hostile helpful does not promote tracking")
end
for id in pairs(infoIDs) do
    check(filter("BoostedRest").includeSpellIDs[id] == true,
        "secure informational harmful filter")
    check(filter("SmallFriendlyHarmful").excludeSpellIDs[id] == true,
        "generic harmful fallback does not promote informational status")
    check(filter("PriorityDebuff").excludeSpellIDs[id] == true,
        "priority harmful fallback does not promote informational status")
end
for id in pairs(C.buffs_cosmetic) do
    check(R.HELPFUL_TIER_BY_SPELL[id] == nil,
        "pure cosmetic auras stay excluded from portrait tiers")
end
for id in pairs(C.buffs_noncombat) do
    check(R.HELPFUL_TIER_BY_SPELL[id] == nil,
        "profession-only noncombat auras remain excluded")
end

-- This integration check is separate from ID membership: for friendly/self
-- harmful units, exact-ID native filtering may be restricted by secrecy.
local engine = assert(io.open("AuraEngine.lua", "rb"))
local engineSource = assert(engine:read("*a")); engine:close()
check(engineSource:find('{ "CampfireNearbyHarmful", "readableNearbyHarmfulFrame", 4 }', 1, true) ~= nil,
    "nearby-world readable frame retains tier four")
check(engineSource:find('updateReadableHarmfulTier(host, base, "CampfireNearbyHarmful"', 1, true) ~= nil,
    "nearby harmful refresh remains separately owned at level four")
check(engineSource:find('{ "BoostedRest", "readableBoostedRestFrame", 0 }', 1, true) ~= nil,
    "one bottom harmful readable presenter has level zero")
check(engineSource:find('updateReadableHarmfulTier(host, base, "BoostedRest"', 1, true) ~= nil,
    "bottom harmful readable owner follows priority zero")
check(engineSource:find('local function updateReadableHarmfulTier(host, baseEnabled, tierKey', 1, true) ~= nil,
    "reuses the pre-existing guarded harmful helper")
check(engineSource:find('R.CreateSecondaryPortrait(host, parentStrata)', 1, true) ~= nil,
    "race art now uses secondary circle, never a main overlay")
print("bjarkiPortraits low-priority tiers: " .. checks .. " assertions passed")
