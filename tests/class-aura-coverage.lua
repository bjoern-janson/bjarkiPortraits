-- Run from the addon source root: lua tests/class-aura-coverage.lua
-- Lua 5.1/5.4 regression against real Spells.lua and Priority.lua. These checks
-- verify classification and native candidate filters, not live aura exposure.
-- Fixtures are reviewed applied IDs, not a generated copy of the spell table.
local BP = { Runtime = {} }
assert(loadfile("Spells.lua"))("bjarkiPortraits", BP)
assert(loadfile("Priority.lua"))("bjarkiPortraits", BP)
local C, R = assert(BP.categories), assert(BP.Runtime)
local checks, cases, failures, current = 0, 0, {}, "initialization"
local function check(ok, label)
    checks = checks + 1
    if not ok then failures[#failures + 1] = current .. ": " .. label end
end
local function equal(actual, expected, label)
    check(actual == expected, label .. " (got " .. tostring(actual)
        .. ", wanted " .. tostring(expected) .. ")")
end
local function run(name, body)
    current, cases = name, cases + 1
    local ok, err = pcall(body)
    if not ok then failures[#failures + 1] = name .. ": unexpected error: " .. tostring(err) end
end
local function filters(key)
    return assert(R.CandidateFilters(assert(R.TIER_BY_KEY[key])))
end
local function exactOwners(id)
    local owners = {}
    for _, tier in ipairs(R.TIERS) do
        if tier.exact and tier.spellIDs[id] then owners[#owners + 1] = tier.key end
    end
    return table.concat(owners, ",")
end
local function applied(id, category, key, level, helpful)
    local label = tostring(id)
    local tier = R.TIER_BY_KEY[key]
    equal(C[category] and C[category][id], true, label .. " canonical category " .. category)
    equal(exactOwners(id), key, label .. " has one exact owner")
    check(tier ~= nil, label .. " exact lane exists")
    if not tier then return end
    equal(tier.level, level, label .. " keeps family priority")
    equal(tier.helpful, helpful, label .. " correct polarity")
    equal(filters(key).includeSpellIDs[id], true, label .. " admitted by exact native lane")
    local indexed = R.HELPFUL_TIER_BY_SPELL[id]
    equal(indexed and indexed.key, helpful and key or nil, label .. " helpful lookup")
    -- A known application must not escape its family priority via a higher
    -- broad semantic lane. The low hostile-helpful fallback remains eligible.
    local broad = helpful and { "Important", "ExternalDef", "BigDef" }
        or { "PriorityDebuff", "CrowdControl" }
    for _, broadKey in ipairs(broad) do
        equal(filters(broadKey).excludeSpellIDs[id], true,
            label .. " excluded from semantic " .. broadKey)
    end
end
local function noAura(id)
    equal(exactOwners(id), "", tostring(id) .. " has no invented exact aura")
    equal(R.HELPFUL_TIER_BY_SPELL[id], nil, tostring(id) .. " has no helpful lookup")
    local categories = {}
    for name, spells in pairs(C) do
        if spells[id] then categories[#categories + 1] = name end
    end
    table.sort(categories)
    equal(table.concat(categories, ","), "", tostring(id) .. " not added to an aura category")
end

-- Breaks caught: helpful Distract masks its harmful status; pet Intimidation
-- is mistaken for the target taunt; disarm is placed in the interrupt lane.
run("Distract is harmful status", function()
    applied(1725, "debuffs_other", "StatusEffects", 253, false)
    equal(C.buffs_utility[1725], nil, "Distract removed from helpful utility")
end)
run("Intimidation separates pet buff from target stun", function()
    applied(19577, "buffs_offensive", "Offensive", 280, true)
    equal(C.debuffs_taunts[19577], nil, "pet proc-enabling buff is not a target taunt")
    applied(24394, "stuns", "Stun", 320, false)
end)
run("Riposte shares Disarm control priority", function()
    applied(14251, "cc", "Control", 310, false)
    applied(676, "cc", "Control", 310, false)
    equal(C.interrupts[14251], nil, "Riposte is not an interrupt")
    equal(filters("InterruptSilence").includeSpellIDs[14251], nil,
        "Riposte cannot enter InterruptSilence")
end)
-- Both Mind Vision ranks mark the observed target with a harmful sight aura.
-- Break caught: helpful-only classification hides the target application or a
-- broad harmful lane promotes this informational effect above its level3 band.
run("Mind Vision ranks are harmful tracking", function()
    for _, id in ipairs({ 2096, 10909 }) do
        applied(id, "debuffs_tracking", "TrackingHarmful", 3, false)
        equal(C.buffs_tracking[id], nil, tostring(id) .. " not helpful tracking")
        equal(R.HELPFUL_TIER_BY_SPELL[id], nil, tostring(id) .. " no helpful lookup")
        equal(filters("SmallFriendlyHarmful").excludeSpellIDs[id], true,
            tostring(id) .. " cannot be promoted by generic harmful")
        equal(filters("CrowdControl").excludeSpellIDs[id], true,
            tostring(id) .. " cannot be promoted by semantic control")
        equal(filters("PriorityDebuff").excludeSpellIDs[id], true,
            tostring(id) .. " cannot be promoted by priority harmful")
    end
end)

-- Break caught: a reviewed higher rank (or separate sacrifice result) falls
-- through while its lower-rank/sibling application has an exact priority.
-- The literal expected families cover all nine classes independently.
local families = {
    { "Druid Rejuvenation", 774, 25299, "buffs_hots", "Healing", 251, true },
    { "Rogue Slice and Dice", 5171, 6774, "buffs_offensive", "Offensive", 280, true },
    { "Warrior Sunder Armor", 7386, 11597, "debuffs_other", "StatusEffects", 253, false },
    { "Hunter Wing Clip", 2974, 14268, "slows", "Slows", 278, false },
    { "Paladin Seal of Command", 20375, 20920, "buffs_seals", "Seal", 210, true },
    { "Shaman Flame Shock", 8050, 29228, "debuffs_dots", "DoTs", 190, false },
    { "Mage Frostbolt", 116, 25304, "slows", "Slows", 278, false },
    { "Priest Renew", 139, 25315, "buffs_hots", "Healing", 251, true },
    { "Warlock sacrifice", 18789, 18790, "buffs_other", "SelfState", 150, true },
}
for _, fixture in ipairs(families) do
    run(fixture[1] .. " preserves sibling classification", function()
        applied(fixture[2], fixture[4], fixture[5], fixture[6], fixture[7])
        applied(fixture[3], fixture[4], fixture[5], fixture[6], fixture[7])
    end)
end

-- Breaks caught: adding a summon, cast, or script in place of its separate
-- applied aura; promoting ordinary support totems to combat cooldown lanes.
run("Vanish uses applied improved stealth", function()
    applied(11329, "buffs_mobility", "Mobility", 160, true)
    noAura(1856); noAura(1857)
end)
run("Explosive Trap uses target periodic applications", function()
    applied(13812, "debuffs_dots", "DoTs", 190, false)
    applied(14315, "debuffs_dots", "DoTs", 190, false)
    applied(19185, "roots", "Roots", 300, false)
    noAura(13813); noAura(14316); noAura(14317)
end)
run("Prayer of Mending uses recipient aura", function()
    applied(1240848, "buffs_hots", "Healing", 251, true)
    noAura(401859); noAura(1240826); noAura(1240827)
end)
run("Demonic Sacrifice uses result buffs", function()
    applied(18791, "buffs_other", "SelfState", 150, true)
    applied(18792, "buffs_other", "SelfState", 150, true)
    noAura(18788)
end)
local supportTotems = {
    { "Grace of Air", { 8836, 10626, 25360 }, 8835 },
    { "Windfury", { 8515, 10609, 10612 }, 8512 },
    { "Windwall", { 15108, 15109, 15110 }, 15107 },
}
for _, fixture in ipairs(supportTotems) do
    run(fixture[1] .. " uses ordinary support applications", function()
        applied(8076, "buffs_paladin_auras", "PaladinAura", 60, true)
        for _, id in ipairs(fixture[2]) do
            applied(id, "buffs_paladin_auras", "PaladinAura", 60, true)
        end
        noAura(fixture[3])
    end)
end

-- Break caught: a mixed application is duplicated/promoted by its periodic
-- component instead of retaining the established slow/root sibling family.
run("slow plus damage retains slow ownership", function()
    applied(18807, "slows", "Slows", 278, false) -- Mind Flay
    applied(401502, "slows", "Slows", 278, false) -- Frostfire Bolt
    applied(1265042, "slows", "Slows", 278, false) -- Tendon Rip
end)
run("root plus damage retains root ownership", function()
    applied(1265883, "roots", "Roots", 300, false) -- Pet Web
end)
run("supported form auras keep self-state priority", function()
    applied(9634, "buffs_other", "SelfState", 150, true) -- Dire Bear Form
    applied(15473, "buffs_other", "SelfState", 150, true) -- Shadowform
end)

-- Break caught: promoting unsupported spell identities into visible aura
-- classification while repairing verified entries. Warrior stance state is
-- deliberately handled by its existing presenter, outside these aura sets.
for _, fixture in ipairs({
    { 7744, "Will of the Forsaken" },
    { 2457, "Battle Stance" }, { 71, "Defensive Stance" }, { 2458, "Berserker Stance" },
    { 11129, "unresolved Combustion" }, { 14183, "hidden Premeditation" },
}) do
    run(fixture[2] .. " is not blindly added", function() noAura(fixture[1]) end)
end
run("semantic fallbacks retain unclassified candidates", function()
    local unknown = 987654321
    for _, key in ipairs({ "Important", "ExternalDef", "BigDef", "PriorityDebuff",
        "CrowdControl", "HostileHelpful", "SmallFriendlyHarmful" }) do
        equal(filters(key).excludeSpellIDs[unknown], nil, key .. " still admits unknown ID")
    end
    equal(filters("HostileHelpful").excludeSpellIDs[6774], nil,
        "low hostile helpful fallback remains eligible for combat buffs")
end)

for _, failure in ipairs(failures) do print("FAIL " .. failure) end
assert(#failures == 0, "class aura coverage: " .. #failures .. " failed checks / "
    .. checks .. " checks in " .. cases .. " cases")
print("PASS class aura coverage: " .. checks .. " checks in " .. cases .. " cases")
