-- Publicly readable target-aura projection against ACTUAL Spells / Priority.
-- Tests exactly the state previously excluded before scanning hostile targets.
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
-- This is the important case: secure exact helpful filters on hostile targets
-- are *not* granted, even though some indexed aura identities are public.
R.ExactFilterAllowed=function(unit,helpful) return helpful and unit=='player' end
R.ApplyCountdownFormat=function() end
R.ResolveRaceBaselineAtlas=function()
    return 'Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Races', {0,0.125,0,0.25},false
end
local function region()
    local f={}
    function f:Show() self.shown=true end
    function f:Hide() self.shown=false end
    function f:SetTexture(tex) self.texture=tex end
    function f:SetTexCoord(...) end
    function f:SetCooldown(start,duration) self.start=start;self.duration=duration end
    function f:Clear() self.duration=0 end
    return f
end
assert(loadfile('SecondaryPortrait.lua'))('bjarkiPortraits',BP)
local checks=0
local function eq(a,b,msg) assert(a==b,(msg or 'value')..': '..tostring(a)..' ~= '..tostring(b));checks=checks+1 end
local function aura(spell,id,seconds)
    seconds=seconds or 3600
    return {spellId=spell,auraInstanceID=id,icon=spell+10000,
        duration=seconds,expirationTime=6000+seconds,timeMod=1,
        isNameplateOnly=false}
end
local lists={}
C_UnitAuras={GetAuraDataByIndex=function(unit,i,filter)
    if unit~='target' then return nil end
    local group=filter:find('HARMFUL',1,true) and 'harmful' or 'helpful'
    return lists[group] and lists[group][i] or nil
end}
local function host()
    return {unit='target',_buildComplete=true,_hostileUnit=true,
        _hostileRelationReadable=true,_assistable=false,
        _containerWriteFailures=0,_readableTierOwners={},
        _hostileAuraListComplete=true,_hostileElectionReadable=true,
        _hostileReadable=true,_hostileActive=true,
        secondaryBadge=region(),racePortrait=region(),secondaryCooldown=region()}
end
-- Welcoming Campfire 257 outranks Camp Benefits 90, which outranks
-- Campfire Nearby 4. The verified main hostile helpful winner is present.
lists.helpful={aura(1229741,17),aura(1283391,19),aura(1229739,11,60)}
local h=host()
h._hostileSpellID=1229739;h._hostileTierKey='HonorlessTarget';h._hostileAuraInstanceID=11
local candidate,reason=R.GetReadableSecondaryAura(h)
eq(reason,'verified-readable','hostile complete public proof')
eq(candidate and candidate.spellID,1229741,'Camp Benefits is actual runner-up')
eq(candidate and candidate.tier.key,'BaselineClass','Camp Benefits owner preserved')
R.ReconcileSecondaryPortrait(h,true,false)
eq(h._secondaryMode,'aura','hostile target shows second aura')
eq(h._secondaryAuraSpellID,1229741,'secondary badge icon is Camp Benefits')
-- A different native/main winner means this public list is insufficient proof.
h._hostileAuraInstanceID=900
candidate,reason=R.GetReadableSecondaryAura(h)
eq(candidate,nil,'mismatched main never produces an icon')
eq(reason,'hostile-primary-mismatch','diagnostic describes disagreement')
-- An incomplete native helper's proof is not enough to bypass hostile checks.
h._hostileAuraInstanceID=11;h._hostileAuraListComplete=false
candidate,reason=R.GetReadableSecondaryAura(h)
eq(candidate,nil,'incomplete hostile scan is rejected')
eq(reason,'hostile-list-unreadable','incomplete list explanation')
h._hostileAuraListComplete=true;h._hostileActive=false
candidate,reason=R.GetReadableSecondaryAura(h)
eq(reason,'hostile-primary-unverified','no main witness is rejected')
eq(candidate,nil,'no second from an unverified main')
-- An already displayed and positively proven Warrior form is an independent
-- first-place witness at 149. Below it: Camp Benefits 90 > CampfireNearby 4.
h=host()
h._formStateActive=true;h._formStateSpellID=71;h._formStateReason='unit-aura:proven'
h._hostileSpellID=1229741;h._hostileTierKey='BaselineClass';h._hostileAuraInstanceID=17
lists.helpful={aura(1229741,17),aura(1283391,19)}
candidate,reason=R.GetReadableSecondaryAura(h)
eq(reason,'verified-form-then-aura','verified form qualifies as first portrait')
eq(candidate and candidate.spellID,1229741,'Camp Benefits is the first aura after form')
R.ReconcileSecondaryPortrait(h,true,false)
eq(h._secondaryAuraSpellID,1229741,'Camp Benefits displays beside form')
-- If another aura outranks the form, the form can no longer be claimed as
-- the primary by this projected reader; do not fabricate a badge selection.
lists.helpful={aura(1229741,17),aura(1229739,20,60)}
candidate,reason=R.GetReadableSecondaryAura(h)
eq(candidate,nil,'higher aura invalidates assumed primary form')
eq(reason,'form-not-proven-primary','form case fails closed')
-- A genuine unreadable indexed aura invalidates the election, not just its
-- place in the sorted set. This must also apply to hostile units.
lists.helpful={aura(1229741,17),'SECRET'}
candidate,reason=R.GetReadableSecondaryAura(h)
eq(candidate,nil,'secret hostile index disallows election')
eq(reason,'inaccessible-index','unreadable scan returns source reason')
-- Hostile target that is actually unreadable still gets no second effect.
h._hostileRelationReadable=false;h._formStateActive=false
candidate,reason=R.GetReadableSecondaryAura(h)
eq(candidate,nil,'unreadable relation is not promoted')
eq(reason,'hostile-relation-unreadable','guard reports relation')
print('secondary hostile target: '..checks..' actual-map checks passed')
