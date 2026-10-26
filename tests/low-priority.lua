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
local info = assert(R.TIER_BY_KEY.CampfireNearbyHarmful)
local tracking = assert(R.TIER_BY_KEY.Tracking)
local ambient = assert(R.TIER_BY_KEY.CampfireNearby)
local ambientHarmful = assert(R.TIER_BY_KEY.CampfireNearbyHarmful)
local fallback = assert(R.TIER_BY_KEY.HostileHelpful)

equal(gathering.level, 1, "Find Herbs/Minerals lowest aura tier")
equal(info.level, 4, "informational harmful merged into nearby-world effects")
equal(tracking.level, 3, "tracking/sensing immediately above gathering")
equal(ambient.level, 4, "original ambient buff above tracking")
equal(ambientHarmful.level, 4, "ambient harmful and informational effects share priority")
equal(fallback.level, 5, "generic hostile fallback above the exact low lanes")
check(gathering.helpful and gathering.exact, "gathering is exact helpful")
check(not info.helpful and info.exact, "informational effects are exact harmful")
check(tracking.helpful and tracking.exact, "tracking is exact helpful")
for _, tier in ipairs(R.TIERS) do
    if tier ~= gathering and tier ~= tracking then
        check(tier.level >= 4, "all remaining aura tiers above race-fallback lanes: " .. tier.key)
    end
end

local gatheringIDs = {
    [2383] = "Find Herbs rank 1",
    [8387] = "Find Herbs rank 2",
    [2580] = "Find Minerals rank 1",
    [8388] = "Find Minerals rank 2",
}
local infoIDs = {
    [24755] = "Tricked or Treated",
    [1229451] = "Boosted Rest",
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
    [2481] = "Find Treasure",
    [43308] = "Find Fish",
    [132] = "Detect Invisibility",
    [126] = "Eye of Kilrogg",
    [2096] = "Mind Vision",
    [6196] = "Far Sight",
    [6197] = "Eagle Eye",
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
equal(gatheringCount, 4, "four gathering ranks in the lowest tier")
for id, name in pairs(infoIDs) do
    check(info.spellIDs[id] == true, name .. " harmful display")
    check(R.NONCOMBAT_EXCLUDED_HARMFUL[id] == true,
        name .. " cannot be promoted by generic harmful fallback")
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
for id in pairs(sensingIDs) do
    check(filter("Tracking").includeSpellIDs[id] == true, "secure tracking filter")
    check(filter("HostileHelpful").excludeSpellIDs[id] == true,
        "generic hostile helpful does not promote tracking")
end
for id in pairs(infoIDs) do
    check(filter("CampfireNearbyHarmful").includeSpellIDs[id] == true,
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
    "merged nearby-world readable frame inherits tier four")
check(engineSource:find('updateReadableHarmfulTier(host, base, "CampfireNearbyHarmful"', 1, true) ~= nil,
    "one complete-election harmful refresh covers informational and nearby effects")
check(engineSource:find('local function updateReadableHarmfulTier(host, baseEnabled, tierKey', 1, true) ~= nil,
    "reuses the pre-existing guarded harmful helper")
check(engineSource:find('createRaceBaseline(host)', 1, true) ~= nil,
    "native portrait race foundation remains the fallback")
print("bjarkiPortraits low-priority tiers: " .. checks .. " assertions passed")
