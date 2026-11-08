-- November 2026 live-observed aura classifications, against shipped data.
-- These checks exercise membership and native filters, not live-client rendering.
local BP = { Runtime = {} }
assert(loadfile("Spells.lua"))("bjarkiPortraits", BP)
assert(loadfile("Priority.lua"))("bjarkiPortraits", BP)
local R, C = assert(BP.Runtime), assert(BP.categories)
local checks = 0
local function equal(actual, wanted, label)
    assert(actual == wanted, label .. ": got " .. tostring(actual)
        .. ", expected " .. tostring(wanted))
    checks = checks + 1
end
local function member(category, tier, level, helpful, ids)
    local lane = assert(R.TIER_BY_KEY[tier], tier)
    equal(lane.level, level, tier .. " level")
    equal(lane.helpful, helpful, tier .. " polarity")
    for _, id in ipairs(ids) do
        equal(C[category][id], true, category .. " membership " .. id)
        equal(lane.spellIDs[id], true, tier .. " contains " .. id)
        if helpful then
            equal(R.HELPFUL_TIER_BY_SPELL[id], lane, tier .. " indexed owner " .. id)
        end
        for _, other in ipairs(R.TIERS) do
            if other.exact and other ~= lane then
                equal(other.spellIDs[id], nil, "no duplicate " .. id .. " in " .. other.key)
            end
        end
    end
end

member("buffs_bottom", "BottomHelpful", 0, true, { 1321323 })
member("buffs_gathering", "Gathering", 1, true, { 2383, 8387, 2580, 8388, 2481 })
member("buffs_tracking", "Tracking", 3, true, { 8202, 8898, 8899, 8900, 9735, 1246031 })
member("buffs_campfire_nearby", "CampfireNearby", 4, true, { 1283391 })
member("buffs_violet_flames", "VioletFlames", 5, true, { 1328375 })
member("buffs_offensive", "Offensive", 280, true, { 6268, 5515 })
member("buffs_seals", "Seal", 210, true, { 1328826, 1328827 })
member("buffs_control_transforms", "ControlHelpful", 310, true, { 3329 })
-- Four low-information harmful effects use a single exact priority-zero slot.
member("debuffs_boosted_rest", "BoostedRest", 0, false, { 1229451 })
member("debuffs_noncombat", "BoostedRest", 0, false, { 24755 })
member("debuffs_pet_taming", "BoostedRest", 0, false, { 19685, 19686 })
member("debuffs_campfire_nearby", "CampfireNearbyHarmful", 4, false, { 1299099 })
member("cc", "Control", 310, false, { 118 }) -- Polymorph's harmful control lane

local gatherFilter = R.CandidateFilters(assert(R.TIER_BY_KEY.Gathering))
local trackingFilter = R.CandidateFilters(assert(R.TIER_BY_KEY.Tracking))
local hostileFilter = R.CandidateFilters(assert(R.TIER_BY_KEY.HostileHelpful))
local importantFilter = R.CandidateFilters(assert(R.TIER_BY_KEY.Important))
for _, id in ipairs({ 2481 }) do
    equal(trackingFilter.includeSpellIDs[id], nil, "gathering is not tracking " .. id)
    equal(gatherFilter.includeSpellIDs[id], true, "gathering native inclusion " .. id)
    equal(hostileFilter.excludeSpellIDs[id], true, "no hostile fallback promotion " .. id)
    equal(importantFilter.excludeSpellIDs[id], true, "no important fallback promotion " .. id)
end
for _, id in ipairs({ 8202, 8898, 8899, 8900, 9735, 1246031 }) do
    equal(hostileFilter.excludeSpellIDs[id], true, "no tracking fallback promotion " .. id)
end
local shortHarmful = R.CandidateFilters(assert(R.TIER_BY_KEY.SmallFriendlyHarmful))
equal(shortHarmful.maxDuration, 3599, "generic harmful duration bound for Boosted Rest")
equal(shortHarmful.excludeSpellIDs[1229451], true, "Boosted Rest excluded from generic harmful")
local bottom = R.CandidateFilters(assert(R.TIER_BY_KEY.BoostedRest))
for _, id in ipairs({ 1229451, 24755, 19685, 19686 }) do
    equal(bottom.includeSpellIDs[id], true, "bottom native slot contains " .. id)
    equal(shortHarmful.excludeSpellIDs[id], true, "no generic promotion " .. id)
end
equal(R.TIER_BY_KEY.BoostedRest.directWitnessSpellIDs[19685], true, "tamed direct witness 1")
equal(R.TIER_BY_KEY.BoostedRest.directWitnessSpellIDs[19686], true, "tamed direct witness 2")
equal(R.TIER_BY_KEY.CampfireNearbyHarmful.spellIDs[1229451], nil, "old level four excludes Boosted Rest")
equal(R.TIER_BY_KEY.Gathering.spellIDs[19686], nil, "Tamed is no longer Gathering")
equal(R.TIER_AUDIT.overlapCount, 0, "no cross-tier exact ID conflicts")

local function file(path)
    local f = assert(io.open(path, "rb")); local contents = assert(f:read("*a")); f:close()
    return contents
end
local version = assert(file("Core.lua"):match('R%.VERSION%s*=%s*"([^"]+)"'))
for _, toc in ipairs({ "bjarkiPortraits.toc", "bjarkiPortraits_Camelot.toc" }) do
    equal(file(toc):match("## Version: ([^\r\n]+)"), version, toc .. " matches runtime")
end
print("bjarkiPortraits launch auras: " .. checks .. " assertions passed")
