-- World-buff categorization regression against the actual shipped tiers.
-- Named Classic and Forever-visible world auras share BaselineClass=90.
-- Invisible Forever stat-effect twins must NOT be portrait candidates.
local BP={Runtime={}}
assert(loadfile("Spells.lua"))("bjarkiPortraits",BP)
assert(loadfile("Priority.lua"))("bjarkiPortraits",BP)
local C,R=assert(BP.categories),assert(BP.Runtime)
local checks=0
local function eq(actual,want,label)
    assert(actual==want,(label or "mismatch")..": "
        ..tostring(actual).." ~= "..tostring(want))
    checks=checks+1
end
local baseline=assert(R.TIER_BY_KEY.BaselineClass)
local paladin=assert(R.TIER_BY_KEY.PaladinAura)
eq(baseline.level,90,"class buffs remain at level 90")
eq(baseline.exact,true,"world buffs have explicit native aura spell-ID filters")
eq(baseline.helpful,true,"world buffs have helpful polarity")
eq(baseline.filter,"HELPFUL","native world buffs use helpful filter")
eq(paladin.level,60,"PaladinAura priority unchanged")
local world={
    -- Major city and zone buffs, Dire Maul tribute, seasonal variants.
    22888,16609,460939,460940,24425,355365,15366,
    22817,22818,22820,29534,1216566,30238,15123,29175,
    430947,431111,438537,446695,
    -- Sayge's eight possible visible Dark Fortunes.
    23735,23736,23737,23738,23766,23767,23768,23769,
}
local seen={}
for _,id in ipairs(world) do
    eq(seen[id],nil,"source world-buff list is disjoint")
    seen[id]=true
    eq(C.buffs_world[id],true,"World aura "..id.." source category")
    eq(baseline.spellIDs[id],true,"World aura "..id.." level-90 owner")
    eq(R.HELPFUL_TIER_BY_SPELL[id],baseline,
        "World aura "..id.." single helpful tier index")
    local filter=R.CandidateFilters(baseline)
    eq(filter.includeSpellIDs[id],true,
        "World aura "..id.." in native priority-90 filter")
    for _,key in ipairs({"Important","HostileHelpful","BigDef","ExternalDef"}) do
        eq(R.CandidateFilters(assert(R.TIER_BY_KEY[key])).excludeSpellIDs[id],
            true,"World aura "..id.." excluded from generic "..key)
    end
    local owners=0
    for _,tier in ipairs(R.TIERS) do
        if tier.exact and tier.spellIDs[id] then
            owners=owners+1
            eq(tier,baseline,"World aura "..id.." exact owner is baseline")
        end
    end
    eq(owners,1,"World aura "..id.." is not duplicated in an exact tier")
end
for id in pairs(C.buffs_world) do
    eq(seen[id],true,"all world IDs must be maintained in audit")
end
eq(#world,27,"27 named visible world-buff IDs audited")

-- Dedicated low-impact band (introduced after the world-buff audit).
-- +2 Intellect and +4 HP/5s should never displace major world buffs.
local minor=assert(R.TIER_BY_KEY.MinorHelpful)
local minorHarmful=assert(R.TIER_BY_KEY.MinorHarmful)
eq(minor.level,6,"minor beneficial buff is near the bottom")
eq(minorHarmful.level,minor.level,"minor effects have matching polarity lanes")
eq(minor.helpful,true,"minor helpful uses proper native polarity")
eq(minorHarmful.helpful,false,"minor harmful uses proper native polarity")
eq(minorHarmful.filter,"HARMFUL","native minor harmful is an exact debuff filter")
for _,id in ipairs({1296202,1292142}) do
    eq(C.buffs_minor_world[id],true,"minor world source membership")
    eq(baseline.spellIDs[id],nil,"minor world cannot inherit class/world priority 90")
    eq(minor.spellIDs[id],true,"minor world joins MinorHelpful")
    eq(paladin.spellIDs[id],nil,"minor world never returns to tier 60")
    eq(R.HELPFUL_TIER_BY_SPELL[id],minor,"minor world indexed at priority 6")
    eq(R.CandidateFilters(minor).includeSpellIDs[id],true,
        "minor world has one native exact filter")
    eq(R.CandidateFilters(R.TIER_BY_KEY.HostileHelpful).excludeSpellIDs[id],
        true,"minor world not promoted by hostile helpful semantic fallback")
    eq(R.CandidateFilters(R.TIER_BY_KEY.Important).excludeSpellIDs[id],
        true,"minor world not promoted to important")
end
eq(next(minorHarmful.spellIDs),nil,"no unverified tiny debuffs invented")

-- Keep existing legitimate class and camp buffs; never demote the established
-- special high-priority Welcoming Campfire or unrelated consumables.
eq(baseline.spellIDs[1126],true,"Mark of the Wild stays at class-buff tier")
eq(baseline.spellIDs[1229741],true,"Camp Benefits stays at class-buff tier")
eq(R.TIER_BY_KEY.HonorlessTarget.spellIDs[1229739],true,
    "Welcoming Campfire special lane preserved")
eq(R.TIER_BY_KEY.WellFed.level,110,"Well Fed tier preserved")
eq(R.TIER_BY_KEY.Elixirs.level,81,"Elixirs tier preserved")
eq(R.TIER_BY_KEY.Tracking.level,3,"Tracking tier preserved")
eq(R.TIER_BY_KEY.PaladinAura.spellIDs[24907],true,
    "ordinary PaladinAura effects still occupy their former tier")

-- Forever has separate hidden stat-effect twins for several world auras.
-- They are not independently presented status icons and must not consume
-- one of the two visible portrait slots.
for _,id in ipairs({1304452,1304594,1304678,1304690,1304751,1304753,
    1304759,1304769,1304782}) do
    eq(C.buffs_world[id],nil,"hidden twin "..id.." is not visible world portrait")
    eq(R.HELPFUL_TIER_BY_SPELL[id],nil,
        "hidden twin "..id.." has no separate exact portrait priority")
end
-- Blessing of Blackfathom is genuinely harmful, already level 90.
eq(R.TIER_BY_KEY.BaselineClassHarmful.spellIDs[8733],true,
    "Blackfathom debuff stays in harmful class-buff polarity")
eq(R.TIER_BY_KEY.BaselineClassHarmful.level,90,
    "Blackfathom harmful level preserved")
eq(R.TIER_AUDIT.overlapCount,0,"no exact-tier overlap introduced")
print("World buffs at class priority 90: "..checks.." assertions passed")
