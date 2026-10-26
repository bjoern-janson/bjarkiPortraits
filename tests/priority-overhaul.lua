-- bjarkiPortraits v0.1.153 priority consolidation: source-backed checks.
-- Loads actual Spell and Priority modules, verifies tier ownership and safe
-- runtime wiring; Lua 5.1 and 5.4, no WoW client required.
local BP={Runtime={}}
assert(loadfile("Spells.lua"))("bjarkiPortraits",BP)
assert(loadfile("Priority.lua"))("bjarkiPortraits",BP)
local C,R=BP.categories,BP.Runtime
local total=0
local function check(value,label)
    assert(value,label)
    total=total+1
end
local function eq(a,b,label)
    check(a==b,(label or "mismatch")..": "..tostring(a).." vs "..tostring(b))
end
local function tier(k)
    return assert(R.TIER_BY_KEY[k],"missing tier "..k)
end
local function level(k) return tier(k).level end
local function owns(t,id)
    return tier(t).spellIDs and tier(t).spellIDs[id] == true
end
local function contains(k,id)
    return C[k] and C[k][id] == true
end
local function ownerOf(id)
    local found={}
    for _,t in ipairs(R.TIERS) do
        if t.exact and t.spellIDs[id] then found[#found+1]=t.key end
    end
    return found
end
local function unique(id,expected)
    local owners=ownerOf(id)
    eq(#owners,1,"one exact owner for spell "..id)
    eq(owners[1],expected,"expected exact owner for spell "..id)
end

-- Screenshot-era top-level ordering, interpreted as qualitative priorities:
-- true immunities/control > interrupts > defensives > offensive cooldowns
-- > ordinary utility/roots > slowing/mobility effects > informational auras.
local hierarchy={"WaitingToResurrect","Immunity","Stun","SpellImmunity",
    "PhysicalImmunity","Control","CrowdControl","InterruptSilence",
    "RootImmunity","Roots","Defensive","Offensive","Dazed","Slows",
    "Utility","Mobility","SelfState","Thorns","Plainsrunning",
    "CampfireNearby","Tracking","Gathering"}
for i=1,#hierarchy-1 do
    check(level(hierarchy[i]) > level(hierarchy[i+1]),
        "priority descends: "..hierarchy[i].." > "..hierarchy[i+1])
end
eq(level("Dazed"),level("Slows")+1,"Dazed stronger than ordinary slows")
eq(level("OffensiveHarmful"),level("Offensive"),"harmful offense shares offensive priority")
eq(level("HelpfulSelfStun"),level("Stun"),"helpful cocoon stun joins harmful stun priority")
eq(level("ImmunityHarmful"),level("Immunity"),"harmful ghost state shares immunity rank")
eq(level("CampfireNearbyHarmful"),level("CampfireNearby"),
   "nearby harmful/informational effects share priority")
eq(level("BaselineClassHarmful"),level("BaselineClass"),
   "baseline class effects remain same priority")
check(level("HonorlessTarget")>level("Utility"),
   "honorless/campfire/flag above ordinary utility")
check(level("Defensive")>level("Offensive"),
   "defensive above offensive")
check(level("Roots")>level("Slows"),"root priority above snare")
check(level("Roots")>level("Defensive") and level("Roots")>level("Offensive"),
    "roots retain the original high priority, above defensive/offensive effects")

-- Lock every retained pre-overhaul tier to its original level. The only
-- approved level changes were explicit requests: Utility lower and harmful
-- Offensive merged with helpful Offensive. Other merges use new keys.
-- This guards against extrapolating from screenshots into unrelated priorities.
local preservedPriorityLevels = {
    Gathering = 1,
    Tracking = 3,
    CampfireNearby = 4,
    CampfireNearbyHarmful = 4,
    PassiveSpeed = 9,
    Plainsrunning = 10,
    TravelUtility = 50,
    PassiveDebuff = 59,
    PaladinAura = 60,
    BloodPact = 70,
    Scrolls = 80,
    Elixirs = 81,
    BaselineClass = 90,
    BaselineClassHarmful = 90,
    WellFed = 110,
    Thorns = 120,
    SelfState = 150,
    HostileHelpful = 5,
    Mobility = 160,
    LoneWolf = 170,
    HuntersMark = 180,
    SmallFriendlyHarmful = 175,
    Demoralizing = 185,
    Consecration = 189,
    DoTs = 190,
    Seal = 210,
    Slows = 278,
    Dazed = 279,
    PriorityDebuff = 238,
    Forbearance = 240,
    Healing = 251,
    StatusEffects = 253,
    ResurrectionSickness = 255,
    PowerWordShield = 256,
    HonorlessTarget = 257,
    MinorRegen = 259,
    FoodDrink = 260,
    Innervate = 261,
    Utility = 225,
    Important = 85,
    Offensive = 280,
    OffensiveHarmful = 280,
    ExternalDef = 288,
    BigDef = 289,
    Defensive = 290,
    Roots = 300,
    RootImmunity = 305,
    CrowdControl = 309,
    Control = 310,
    PhysicalImmunity = 315,
    Stun = 320,
    HelpfulSelfStun = 320,
    ImmunityHarmful = 330,
    Immunity = 330,
    WaitingToResurrect = 332,
}
for name,expectedLevel in pairs(preservedPriorityLevels) do
    eq(level(name),expectedLevel,
        "pre-overhaul level retained unless explicitly requested: "..name)
end

-- Consolidated defensive/immunity effects.
for _,id in ipairs({498,5573}) do unique(id,"Immunity") end
-- Explicit live Forever observation overrides historical Classic assumptions:
-- Will of the Forsaken cast 7744 has no observed portrait buff.
check(#ownerOf(7744)==0, "no fabricated Will of the Forsaken aura tier")
for category,set in pairs(C) do
    check(not set[7744], "WotF must not be included in category "..category)
end
check(R.HELPFUL_TIER_BY_SPELL[7744]==nil,
    "WotF has no helpful exact-tier lookup")
check(not owns("Immunity",1303458),"Reflection Field no longer treated as immunity")
unique(1303458,"Thorns")
unique(20594,"Defensive")
unique(6615,"PhysicalImmunity")
unique(1310897,"SpellImmunity")
unique(8178,"SpellImmunity")
unique(1044,"RootImmunity")
unique(20589,"RootImmunity")
unique(1953,"RootImmunity")
unique(1236175,"RootImmunity")
for _,id in ipairs({11426,13031,13032,13033}) do
    unique(id,"PowerWordShield")
    check(not contains("buffs_shield",id),"Ice Barrier excluded from lower Healing lane")
end

-- Previously known stun IDs were NOT absent from the data. The missing
-- behavior is addressed by safe native + complete-readable presentation.
for _,id in ipairs({7922,20253,20614,20615,1833,9005,9823,9827,
                    5211,6798,8983,408,8643,853,20549,4068,13237}) do
    unique(id,"Stun")
end
for _,id in ipairs({9007,9824,9826}) do
    unique(id,"DoTs")
    check(not owns("Stun",id),"long Pounce bleed never gets stun priority")
end
for _,id in ipairs({15487,18425,18469,24259,1330,
                    2139,1766,6552,19647}) do
    unique(id,"InterruptSilence")
end
check(not tier("Control").spellIDs[15487],
    "Silence excluded from generic CC exact lane")
check(not tier("Control").spellIDs[1833],
    "Cheap Shot excluded from generic CC exact lane")

-- Nature's Grasp SELF BUFF is not its separately applied roots.
for _,id in ipairs({16689,16810,16811,16812,16813,17329}) do
    unique(id,"Utility")
    check(not owns("Roots",id),"Grasp self buff never given harmful root priority")
end
for _,id in ipairs({19970,19971,19972,19973,19974,19975}) do
    unique(id,"Roots")
end

-- Merge requested ordinary tiers.
for _,id in ipairs({400573,12328}) do unique(id,"OffensiveHarmful") end
for _,id in ipairs({6788,11196,3436,3439}) do unique(id,"Wounds") end
for _,id in ipairs({324,325,905,945,8134,10431,10432,408510,408514}) do
    unique(id,"SelfState")
end
for _,id in ipairs({2479,1284560,1229739,1289723}) do
    unique(id,"HonorlessTarget")
end
unique(25780,"Plainsrunning")
for _,id in ipairs({24755,1229451}) do unique(id,"CampfireNearbyHarmful") end
for _,id in ipairs({2383,2580,8387,8388}) do unique(id,"Gathering") end
for _,id in ipairs({19883,5500,19885,6197}) do unique(id,"Tracking") end

for _,obsolete in ipairs({
    "DivineProtection","RacialDefensive","ElementalShield",
    "RighteousFury","OffensiveDebuffs","InformationalDebuffs",
    "BattlegroundFlag","RecentlyBandaged","WeakenedSoul",
    "WeakenedSoulFallback","FrostArmorSignature","ChilledSignature",
}) do
    check(R.TIER_BY_KEY[obsolete] == nil, "retired tier absent: "..obsolete)
end
-- One spelling map belongs to exactly one exact runtime category. Helpful and
-- harmful effects at the same numeric level stay disjoint in native filters.
local owners={}
for _,t in ipairs(R.TIERS) do
    if t.exact then
        for id in pairs(t.spellIDs) do
            check(owners[id]==nil,
                "no duplicate exact ownership: "..id.." ("..tostring(owners[id]).." / "..t.key..")")
            owners[id]=t.key
        end
    end
end

-- Retired heuristics must not linger as invisible effective tiers.
local function file(path)
    local f=assert(io.open(path,"rb"))
    local s=assert(f:read("*a")); f:close()
    return s
end
local engine=file("AuraEngine.lua")
local priority=file("Priority.lua")
local commands=file("Commands.lua")
for _,obsolete in ipairs({"FrostArmorSignature","ChilledSignature","WeakenedSoulFallback"}) do
    check(not engine:find(obsolete,1,true),"no stale heuristic switch: "..obsolete)
    check(not priority:find(obsolete,1,true),"no stale heuristic tier: "..obsolete)
end
check(engine:find('updateReadableHarmfulTier(host, base, "Stun"',1,true)~=nil,
    "complete readable stun evidence path wired")
check(engine:find('updateReadableHarmfulTier(host, base, "InterruptSilence"',1,true)~=nil,
    "complete readable silence/interrupt aura evidence path wired")
check(engine:find('updateReadableHarmfulTier(host, base, "Wounds"',1,true)~=nil,
    "merged weak-soul/bandage helper wired")
check(engine:find('updateReadableHarmfulTier(host, base, "CampfireNearbyHarmful"',1,true)~=nil,
    "one merged informational/nearby harmful helper")
check(engine:find('scanLatestReadableExactTierAura(',1,true)~=nil,
    "stun/silence complete native-order election retained")
check(engine:find('if (not complete and not direct) or not electionReadable or not best then',1,true)~=nil,
    "incomplete reads cannot select a synthetic stun/silence")
check(engine:find('local tier = findTierByKey("Immunity")',1,true)~=nil,
    "Divine Protection helper now uses general immunity tier")
check(engine:find('scanReadableHonorlessWinner',1,true)~=nil,
    "campfire complete election now shares HonorlessTarget tier")
check(commands:find('honorlessWinnerSpell=',1,true)~=nil,
    "debug output reports new shared Campfire priority, not utility")
check(not engine:find('readableInformationalDebuffFrame',1,true),
    "informational helper does not retain a second shadow tier")
check(not engine:find('readableCampfireHarmfulFrame',1,true),
    "nearby world effects no longer duplicate harmful presenters")
print("bjarkiPortraits consolidation: "..total.." source-backed assertions passed")
