-- Applied Forever aura and bottom-tier polarity regression for Shiny Silver Coin.
-- Run from the addon source directory on Lua 5.1 and Lua 5.4.
local BP = { Runtime = {} }
assert(loadfile("Spells.lua"))("bjarkiPortraits", BP)
assert(loadfile("Priority.lua"))("bjarkiPortraits", BP)
local R, C = assert(BP.Runtime), assert(BP.categories)
local checks = 0
local function eq(actual, expected, what)
    assert(actual == expected, what .. ": got " .. tostring(actual)
        .. ", expected " .. tostring(expected))
    checks = checks + 1
end
local applied, itemUse = 1321323, 1321320
local low = assert(R.TIER_BY_KEY.BottomHelpful)
local harmful = assert(R.TIER_BY_KEY.BoostedRest)
local gathering = assert(R.TIER_BY_KEY.Gathering)
eq(C.buffs_bottom[applied], true, "applied fishing buff is explicitly categorized")
eq(low.level, 0, "Shiny Silver Coin has absolute bottom numeric priority")
eq(low.helpful, true, "bottom fishing buff polarity is helpful")
eq(low.filter, "HELPFUL", "native helpful filter matches the aura")
eq(low.exact, true, "bottom selection is spell-ID exact")
eq(low.spellIDs[applied], true, "native bottom candidate includes the applied buff")
eq(harmful.level, low.level, "helpful and harmful bottom share numeric priority")
eq(harmful.helpful, false, "harmful bottom remains harmful")
eq(harmful.spellIDs[applied], nil, "helpful fishing buff not included in harmful filter")
eq(gathering.level, 1, "Gathering priority is unchanged")
eq(gathering.spellIDs[applied], nil, "fishing buff does not inherit Gathering priority")
eq(R.HELPFUL_TIER_BY_SPELL[applied], low, "indexed winner is the helpful bottom lane")
eq(R.NONCOMBAT_EXCLUDED_HELPFUL[applied], true,
    "noncombat buff excluded from high-level generic helpful fallback")
for _, key in ipairs({"Important", "HostileHelpful", "BigDef", "ExternalDef"}) do
    local filters = R.CandidateFilters(assert(R.TIER_BY_KEY[key]))
    eq(filters.excludeSpellIDs[applied], true, "no generic promotion via " .. key)
end
eq(R.CandidateFilters(low).includeSpellIDs[applied], true,
    "native exact low-priority candidate includes coin")
eq(R.TIER_AUDIT.overlapCount, 0, "no exact-tier duplicate IDs")
local owners = 0
for _, tier in ipairs(R.TIERS) do
    if tier.exact and tier.spellIDs[applied] then
        owners = owners + 1
        eq(tier, low, "only exact owner is bottom helpful")
    end
end
eq(owners, 1, "exactly one owner")
for category, set in pairs(C) do
    eq(set[itemUse], nil, "do not classify item-use/trigger spell in " .. category)
end
print("Shiny Silver Coin bottom helpful aura: " .. checks .. " assertions passed")
