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
        timeMod=1,important=importantFlag or false,isNameplateOnly=false}
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
eq(host._secondaryElectionReason,'verified-readable','reason reports positive election')
-- Combat may seal the public aura list without changing an existing aura.
-- A previously verified, timed secondary remains only until the first actual
-- UNIT_AURA event, its observed expiration, or a different unit binding.
local combat, clock, expiryCallbacks = false, 100, {}
InCombatLockdown=function() return combat end
GetTime=function() return clock end
C_Timer={After=function(delay, callback)
    expiryCallbacks[#expiryCallbacks+1]={delay=delay,callback=callback}
end}
R.hosts={player=host}
local readableIndex=C_UnitAuras.GetAuraDataByIndex
local function sealIndex() error('model combat aura secrecy') end
combat=true
C_UnitAuras.GetAuraDataByIndex=sealIndex
R.ReconcileSecondaryPortrait(host,true,true)
eq(host._secondaryMode,'aura','combat entry retains earlier positive without mutation')
eq(host._secondaryAuraSpellID,102,'held aura retains original identity')
eq(host._secondaryElectionReason,'combat-positive-retained:inaccessible-index',
    'diagnostic identifies unconfirmed combat retention')
eq(#expiryCallbacks,1,'one expiry timer only when retention begins')
eq(expiryCallbacks[1].delay,10,'expiry timer uses the actual aura clock')
R.ReconcileSecondaryPortrait(host,true,true)
eq(#expiryCallbacks,1,'no repeated retention timers on event bursts')
R.NoteSecondaryAuraEvent('player')
R.ReconcileSecondaryPortrait(host,true,true)
eq(host._secondaryMode,'race','unreadable actual aura change revokes retained icon')
eq(host._secondaryAuraSpellID,nil,'revoked aura identity is cleared')
-- The old timer must never clear an unrelated/new election.
C_UnitAuras.GetAuraDataByIndex=readableIndex
combat=false
setAuras('player',{aura(101,61,106,6),aura(102,62,106,6)})
R.ReconcileSecondaryPortrait(host,true,true)
eq(host._secondaryAuraSpellID,102,'new positive after previous aura event')
expiryCallbacks[1].callback()
eq(host._secondaryMode,'aura','stale old one-shot timer cannot revoke new positive')
combat=true
C_UnitAuras.GetAuraDataByIndex=sealIndex
R.ReconcileSecondaryPortrait(host,true,true)
eq(#expiryCallbacks,2,'new positive has one independent expiry timer')
R.Refresh=function(unit)
    eq(unit,'player','expiry timer refresh is scoped to player')
    R.ReconcileSecondaryPortrait(host,true,true)
end
clock=107
expiryCallbacks[2].callback()
eq(host._secondaryMode,'race','expired combat-held positive is not shown forever')
eq(host._secondaryAuraSpellID,nil,'expired positive identity cleared')
C_UnitAuras.GetAuraDataByIndex=readableIndex
combat=false
-- Without a usable current GUID, a recycled nonplayer unit must NEVER keep
-- a stale portrait across combat. ToT and ToF have no badge at all.
local other=makeHost(); other.unit='target'
setAuras('target',{aura(101,71,120,20),aura(102,72,120,20)})
R.ReconcileSecondaryPortrait(other,true,false)
eq(other._secondaryMode,'aura','target verified before combat')
combat=true
C_UnitAuras.GetAuraDataByIndex=sealIndex
R.ReconcileSecondaryPortrait(other,true,false)
eq(other._secondaryMode ~= 'aura',true,'target without confirmed GUID cannot retain aura')
C_UnitAuras.GetAuraDataByIndex=readableIndex
combat=false
local liveGUID = 'Creature-verified-one'
UnitGUID=function() return liveGUID end
setAuras('target',{aura(101,73,140,40),aura(102,74,140,40)})
R.ReconcileSecondaryPortrait(other,true,false)
eq(other._secondaryPositiveGUID,liveGUID,'positive target tracks readable current GUID')
combat=true
C_UnitAuras.GetAuraDataByIndex=sealIndex
R.hosts.target=other
R.ReconcileSecondaryPortrait(other,true,false)
eq(other._secondaryMode,'aura','target retains with matching current GUID')
liveGUID='Creature-new-occupant'
R.ReconcileSecondaryPortrait(other,true,false)
eq(other._secondaryMode ~= 'aura',true,'changed target GUID revokes cached effect')
C_UnitAuras.GetAuraDataByIndex=readableIndex
combat=false
UnitGUID=nil
-- Exact spell membership is already proven by the full indexed polarity scan.
-- The separate native filter oracle can fail or be absent for addon callers.
-- Its failure must not prevent an otherwise fully readable exact-aura pair.
local originalNativeOracle = C_UnitAuras.IsAuraFilteredOutByInstanceID
C_UnitAuras.IsAuraFilteredOutByInstanceID = nil
setAuras('player',{aura(101,31),aura(102,32),aura(103,33)})
R.ReconcileSecondaryPortrait(host,true,true)
eq(host._secondaryMode,'aura','known exact auras work without native identity oracle')
eq(host._secondaryAuraSpellID,102,'verified second exact aura retained')
-- Normal HELPFUL exact lanes must not consume nameplate-only auras merely
-- because the inclusive scan could see them.
local exclusive = aura(101,91); exclusive.isNameplateOnly=true
setAuras('player',{exclusive,aura(102,92)})
R.ReconcileSecondaryPortrait(host,true,true)
eq(host._secondaryMode,'race','nameplate-only aura excluded from normal exact lane')
C_UnitAuras.IsAuraFilteredOutByInstanceID = originalNativeOracle

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
setAuras('player',{aura(101,1),aura(102,2),aura(999,3,110,10,true)})
local orig=C_UnitAuras.IsAuraFilteredOutByInstanceID
C_UnitAuras.IsAuraFilteredOutByInstanceID=function() return 'SECRET' end
R.ReconcileSecondaryPortrait(host,true,true)
eq(host._secondaryMode,'race','secret semantic filter still rejects unproven runner-up')
C_UnitAuras.IsAuraFilteredOutByInstanceID=orig
-- No stale data on hostile or ineligible units.
host._hostileUnit=true
R.ReconcileSecondaryPortrait(host,true,true)
eq(host._secondaryMode,'race','hostile unsupported remains identity fallback')
host._hostileUnit=false
R.ReconcileSecondaryPortrait(host,false,true)
eq(host._secondaryMode,'hidden','disabled native host revokes badge')
eq(host._secondaryAuraSpellID,nil,'revoked host clears identity')
local scoped = makeHost()
scoped.unit = 'targettarget'
local result, why = R.GetReadableSecondaryAura(scoped)
eq(result,nil,'ToT has no secondary election')
eq(why,'unit-excluded','explicit ToT exclusion reason')
scoped.unit = 'focustarget'
result, why = R.GetReadableSecondaryAura(scoped)
eq(result,nil,'ToF has no secondary election')
eq(why,'unit-excluded','explicit ToF exclusion reason')

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
