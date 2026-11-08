-- Bounded public-only secondary election tests; mocks, not WoW combat proof.
local checks=0
local function eq(value, expected, message)
    assert(value == expected, (message or 'value') .. ': got ' .. tostring(value)
        .. ', expected ' .. tostring(expected))
    checks=checks+1
end
local BP={Runtime={}}
local R=BP.Runtime
R.AURA_ANCHOR_TEMPLATE='DisableUntrustedLayoutScriptsTemplate'
R.db={secondaryPortrait=true}
R.CanAccess=function(v) return v ~= 'SECRET' end
R.ReadAuraField=function(a,k)
    if not a or not R.CanAccess(a) or not R.CanAccess(a[k]) then return nil,false end
    return a[k],true
end
R.SafeBool=function(f,...) local ok,v=pcall(f,...);return v,ok and type(v)=='boolean' end
R.ApplyCountdownFormat=function() end
local high={key='High',level=280,filter='HELPFUL',exact=true,helpful=true,spellIDs={[101]=true,[104]=true}}
local mid={key='Middle',level=210,filter='HELPFUL',exact=true,helpful=true,spellIDs={[102]=true,[105]=true}}
local low={key='Gathering',level=1,filter='HELPFUL',exact=true,helpful=true,spellIDs={[103]=true}}
local important={key='Important',level=85,filter='HELPFUL|IMPORTANT',semantic=true}
R.TIERS={high,mid,low,important}
R.NativeExactContainerAllowed=function() return true end
R.CandidateFilters=function(t) if t==important then
    return {excludeSpellIDs={[101]=true,[102]=true,[103]=true,[104]=true,[105]=true}}
end return {includeSpellIDs=t.spellIDs} end
R.ResolveRaceBaselineAtlas=function()return 'Interface\\RaceSheet',{0,0.125,0,0.25},false end
local byId={}
local seen={}
C_UnitAuras={
    GetAuraDataByIndex=function(unit,index,filter)
        if filter:sub(1,7)=='HELPFUL' then return (seen[unit] or {})[index] end
        return nil
    end,
    IsAuraFilteredOutByInstanceID=function(unit,id,filter)
        local a=byId[id]
        if filter:find('IMPORTANT',1,true) then return not a.important end
        return false
    end,
}
local function aura(spell,id,expire,duration,importantFlag)
    return {spellId=spell,auraInstanceID=id,icon=1000+spell,
        expirationTime=expire or 110,duration=duration or 10,
        timeMod=1,important=importantFlag or false}
end
local function setAuras(unit, t)
    seen[unit]=t;byId={}
    for _,v in ipairs(t) do if type(v)=='table' then byId[v.auraInstanceID]=v end end
end
local function mockRegion()
    local f={shown=false}
    function f:Show() self.shown=true end
    function f:Hide() self.shown=false end
    function f:SetTexture(tex) self.texture=tex;return true end
    function f:SetAtlas(atlas) self.atlas=atlas;return true end
    function f:SetTexCoord(...) self.coords={...} end
    function f:Clear() self.cleared=(self.cleared or 0)+1 end
    function f:SetCooldown(start, dur) self.start=start; self.duration=dur end
    return f
end
assert(loadfile('SecondaryPortrait.lua'))('bjarkiPortraits',BP)
local function makeHost()
    return {unit='player',_buildComplete=true,_hostileUnit=false,_assistable=true,
        _containerWriteFailures=0,_readableTierOwners={},secondaryBadge=mockRegion(),
        racePortrait=mockRegion(),secondaryCooldown=mockRegion()}
end
local host=makeHost()
setAuras('player',{aura(101,10),aura(102,11),aura(103,12)})
R.ReconcileSecondaryPortrait(host,true,true)
eq(host._secondaryMode,'aura','real second selected')
eq(host._secondaryAuraSpellID,102,'highest 280 then second 210')
eq(host._secondaryAuraInstanceID,11,'occurrence identity preserved')
eq(host.racePortrait.texture,1102,'second aura icon shown')
eq(host.secondaryCooldown.duration,10,'native timer configured')
eq(host.secondaryBadge.shown,true,'badge visible above native')
-- Two auras in the same native lane use its reverse instance-ID order.
setAuras('player',{aura(101,51),aura(104,42),aura(103,12)})
R.ReconcileSecondaryPortrait(host,true,true)
eq(host._secondaryAuraSpellID,104,'two from one lane')
eq(host._secondaryAuraInstanceID,42,'lower native ID is runner-up')
-- An unrelated important semantic candidate is still considered at its level.
setAuras('player',{aura(101,51),aura(103,12),aura(999,43,110,10,true)})
R.ReconcileSecondaryPortrait(host,true,true)
eq(host._secondaryAuraSpellID,999,'unknown exact ID may still have semantic priority')
eq(host._secondaryAuraTier,'Important','semantic rank retained')
-- One aura falls back to race (without keeping the preceding aura timer).
setAuras('player',{aura(101,51)})
R.ReconcileSecondaryPortrait(host,true,true)
eq(host._secondaryMode,'race','race when second absent')
eq(host.secondaryCooldown.shown,false,'race never retains previous cooldown')
eq(host._secondaryAuraSpellID,nil,'stale secondary identity cleared')
-- Secret fields and nonterminating scans fail closed.
setAuras('player',{aura(101,2),aura(102,'SECRET')})
R.ReconcileSecondaryPortrait(host,true,true)
eq(host._secondaryMode,'race','incomplete identity cannot present aura')
setAuras('player',{aura(101,1),aura(102,2)})
local orig=C_UnitAuras.IsAuraFilteredOutByInstanceID
C_UnitAuras.IsAuraFilteredOutByInstanceID=function() return 'SECRET' end
R.ReconcileSecondaryPortrait(host,true,true)
eq(host._secondaryMode,'race','secret native filter rejects second')
C_UnitAuras.IsAuraFilteredOutByInstanceID=orig
-- No stale data on hostile or ineligible units.
host._hostileUnit=true
R.ReconcileSecondaryPortrait(host,true,true)
eq(host._secondaryMode,'race','hostile unsupported remains identity fallback')
host._hostileUnit=false
R.ReconcileSecondaryPortrait(host,false,true)
eq(host._secondaryMode,'hidden','disabled native host revokes badge')
eq(host._secondaryAuraSpellID,nil,'revoked host clears identity')
-- Equal numeric levels in distinct native slots are not silently sorted.
mid.level=280
R.ReconcileSecondaryPortrait(host,true,true)
eq(host._secondaryMode,'race','same-level different lane order is unknown')
mid.level=210
-- Missing API and missing timing do not invent a positive.
C_UnitAuras.GetAuraDataByIndex=nil
R.ReconcileSecondaryPortrait(host,true,true)
eq(host._secondaryMode,'race','absent aura index fails closed')
print('secondary portrait readable top-two: '..checks..' assertions passed')
