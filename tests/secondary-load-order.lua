-- Regression: actual TOC must load Priority before SecondaryPortrait.
-- Also exercise SECONDARY loaded before PRIORITY, to ensure lazy hydration
-- cannot silently cache zero tiers if the load order changes again.
local checks = 0
local function equal(a,b,label)
    assert(a == b, (label or "value") .. ": got " .. tostring(a)
        .. ", expected " .. tostring(b))
    checks = checks + 1
end
local function tocPosition(file, module)
    local f = assert(io.open(file,"rb")); local content = assert(f:read("*a")); f:close()
    local n = 0
    for line in content:gmatch("[^\r\n]+") do
        if line:match("%.lua$") then
            n = n + 1
            if line == module then return n end
        end
    end
end
for _, toc in ipairs({"bjarkiPortraits.toc", "bjarkiPortraits_Camelot.toc"}) do
    local priority = assert(tocPosition(toc,"Priority.lua"))
    local secondary = assert(tocPosition(toc,"SecondaryPortrait.lua"))
    local engine = assert(tocPosition(toc,"AuraEngine.lua"))
    equal(priority < secondary, true, toc .. " initializes priorities first")
    equal(secondary < engine, true, toc .. " loads secondary before engine")
end

local function scenario(brokenOrder)
    local BP = { Runtime = {} }
    local R = BP.Runtime
    local function load(module)
        return assert(loadfile(module .. ".lua"))("bjarkiPortraits", BP)
    end
    load("Spells"); load("Core")
    if brokenOrder then load("SecondaryPortrait")
    else load("Priority") end
    R.ApplyDefaults()
    R.db.secondaryPortrait = true
    R.testMode = false
    local host = {unit="player",_buildComplete=true,
        _hostileUnit=false,_assistable=true,_containerWriteFailures=0,
        _readableTierOwners={}}
    if brokenOrder then
        local first, reason = R.GetReadableSecondaryAura(host)
        equal(first, nil, "pre-priority must never claim second aura")
        equal(reason, "tiers-not-ready", "pre-priority reports explicit failure")
        load("Priority")
    else
        load("SecondaryPortrait")
    end
    local thorns = {spellId=467,auraInstanceID=11,icon=10001,
        duration=120,expirationTime=140,timeMod=1,isNameplateOnly=false}
    local mark = {spellId=1126,auraInstanceID=10,icon=10002,
        duration=120,expirationTime=140,timeMod=1,isNameplateOnly=false}
    local helpful = {thorns,mark}
    C_UnitAuras = {GetAuraDataByIndex=function(unit,index,filter)
        if unit == "player" and filter:find("HELPFUL",1,true) then
            return helpful[index]
        end
        return nil
    end}
    UnitExists = function() return true end
    UnitCanAssist = function() return true end
    local second, reason = R.GetReadableSecondaryAura(host)
    equal(reason, "verified-readable", "two visible known buffs rank after load")
    equal(second and second.spellID,1126, "Thorns outranks Mark of the Wild")
    equal(second and second.tier.level,90, "second uses real numeric priority")
    -- Protect against future reload/testing replacement of the tier table:
    -- the source table identity changes and must not reuse a stale cache.
    local tiers = R.TIERS
    R.TIERS = {}
    local missing, why = R.GetReadableSecondaryAura(host)
    equal(missing,nil,"empty source list cannot keep a stale ranked owner")
    equal(why,"tiers-not-ready","empty source list reports a missing initialization")
    R.TIERS = tiers
    local recovered, why2 = R.GetReadableSecondaryAura(host)
    equal(why2,"verified-readable","rank cache recovers after tier restoration")
    equal(recovered and recovered.spellID,1126,"recovered original owner")
end
scenario(false)
scenario(true)
print("secondary priority module load order: " .. checks .. " assertions passed")
