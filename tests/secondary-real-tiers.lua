-- Regression against the actual shipped tier maps, not simplified test tiers.
-- A complete self-helpful scan can rank exact known buffs even when the
-- separate native identity-filter oracle is unavailable to addon Lua.
local BP={Runtime={}}
assert(loadfile('Spells.lua'))('bjarkiPortraits',BP)
assert(loadfile('Priority.lua'))('bjarkiPortraits',BP)
local R=BP.Runtime
R.AURA_ANCHOR_TEMPLATE='DisableUntrustedLayoutScriptsTemplate'
R.db={secondaryPortrait=true}
R.CanAccess=function(v) return v ~= 'SECRET' end
R.ReadAuraField=function(a,k)
    if a == nil or not R.CanAccess(a) or not R.CanAccess(a[k]) then return nil,false end
    return a[k],true
end
R.ExactFilterAllowed=function(unit,helpful) return unit=='player' and helpful end
R.ApplyCountdownFormat=function() end
local function mockRegion()
    local f={}
    function f:Show() self.shown=true end
    function f:Hide() self.shown=false end
    function f:SetTexture(tex) self.texture=tex end
    function f:SetTexCoord(...) end
    function f:SetCooldown(start,duration) self.start=start;self.duration=duration end
    function f:Clear() self.duration=0 end
    return f
end
R.ResolveRaceBaselineAtlas=function()
    return 'Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Races', {0,0.125,0,0.25},false
end
assert(loadfile('SecondaryPortrait.lua'))('bjarkiPortraits',BP)
local host={unit='player',_buildComplete=true,_hostileUnit=false,_assistable=true,
    _containerWriteFailures=0,_readableTierOwners={},secondaryBadge=mockRegion(),
    racePortrait=mockRegion(),secondaryCooldown=mockRegion()}
local auras={}
C_UnitAuras={GetAuraDataByIndex=function(unit,index,filter)
    if unit=='player' and filter=='HELPFUL|INCLUDE_NAME_PLATE_ONLY' then
        return auras[index]
    end
    return nil
end}
local function aura(spell,id,shown)
    return {spellId=spell,auraInstanceID=id,icon=spell+10000,
        duration=120,expirationTime=220,timeMod=1,isNameplateOnly=shown or false}
end
local function eq(a,b,label) assert(a==b,(label or 'mismatch')..': '..tostring(a)..' ~= '..tostring(b)) end
-- Thorns 467 outranks Mark of the Wild 1126 on the current priority map.
auras={aura(1126,120),aura(467,100)}
R.ReconcileSecondaryPortrait(host,true,true)
eq(host._secondaryMode,'aura','two known buffs without native oracle')
eq(host._secondaryAuraSpellID,1126,'second is Mark of the Wild')
eq(host._secondaryElectionReason,'verified-readable','positive reason')
-- Nameplate-only normal helpful buffs must not enter an exact HELPFUL lane.
auras={aura(1126,120,true),aura(467,100)}
R.ReconcileSecondaryPortrait(host,true,true)
eq(host._secondaryMode,'race','unproven second goes to race')
-- A positive exact INCLUDE_NAME_PLATE_ONLY tier can still compete.
auras={aura(1126,120),aura(11327,100,true)}
R.ReconcileSecondaryPortrait(host,true,true)
eq(host._secondaryMode,'aura','nameplate-inclusive exact lane supported')
eq(host._secondaryAuraSpellID,1126,'second positive Mark after Vanish')
-- Unclassified third aura may have a higher semantic rank: don't guess.
auras={aura(1126,120),aura(467,100),aura(999999,101)}
R.ReconcileSecondaryPortrait(host,true,true)
eq(host._secondaryMode,'race','unknown semantic eligibility remains conservative')
print('secondary real tier eligibility: 8 checks passed')
