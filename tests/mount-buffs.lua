-- No runtime mount guessing: the mounted applied aura uses exact tier 90.
local BP={Runtime={}}
assert(loadfile("Spells.lua"))("bjarkiPortraits",BP)
assert(loadfile("Priority.lua"))("bjarkiPortraits",BP)
local C,R=BP.categories,BP.Runtime
local n=0
local function eq(got,want,why)
    assert(got==want,why..": got "..tostring(got).." expected "..tostring(want))
    n=n+1
end
local mounts=assert(C.buffs_mounts)
local class=assert(R.TIER_BY_KEY.BaselineClass)
eq(class.level,90,"existing class tier unchanged")
eq(class.exact,true,"native class tier exact")
eq(class.helpful,true,"mount auras helpful")
for _,id in ipairs({13819,1279399,5784,23161,23214,458,580,6777,
    8394,10793,17462,17481,18989,22721,23238,23509}) do
    eq(mounts[id],true,"reviewed mount "..id)
    eq(class.spellIDs[id],true,"class-tier membership "..id)
    eq(R.HELPFUL_TIER_BY_SPELL[id],class,"public tier "..id)
    eq(R.CandidateFilters(class).includeSpellIDs[id],true,"secure rank "..id)
    -- NativeSecondProbe.groupPlans excludes every exact-owned aura from
    -- its generic groups. Priority.CandidateFilters alone does not supply
    -- that cross-tier exclusion, so do not assert it here.
end
local count=0
for id in pairs(mounts) do
    count=count+1
    eq(class.spellIDs[id],true,"all mounts have a class tier "..id)
    eq(R.HELPFUL_TIER_BY_SPELL[id],class,"no split priority "..id)
end
eq(count>75,true,"coverage of ground, class, PvP and AQ mounts")
eq(class.spellIDs[1126],true,"Mark of the Wild retained")
eq(class.spellIDs[1229741],true,"Camp Benefits retained")
eq(R.TIER_BY_KEY.Consumables.level,81,"Consumables unchanged")
eq(R.TIER_AUDIT.overlapCount,0,"no duplicate exact IDs")
eq(mounts[13820],nil,"teaching spell not a mounted aura")
print("mounts at baseline class priority: "..n.." assertions passed")
