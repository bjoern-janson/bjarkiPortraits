-- Regression for the live out-of-combat Warrior case: a strong aura covers
-- Battle Stance, but the secondary badge must not drop to race merely because
-- the stance is not the *primary* portrait. Test against real priority data.
local BP={Runtime={}}
assert(loadfile('Spells.lua'))('bjarkiPortraits',BP)
assert(loadfile('Priority.lua'))('bjarkiPortraits',BP)
local R=BP.Runtime
R.db={secondaryPortrait=true}
R.CanAccess=function(x) return x~='SECRET' end
R.ReadAuraField=function(a,k)
    if not a or not R.CanAccess(a) or not R.CanAccess(a[k]) then return nil,false end
    return a[k],true
end
R.SafeBool=function(fn,...) local ok,v=pcall(fn,...);return v,ok and type(v)=='boolean' end
R.ExactFilterAllowed=function() return true end
R.ApplyCountdownFormat=function() end
R.ResolveRaceBaselineAtlas=function() return 'Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Races', {0,0.125,0,0.25},false end
C_Spell={GetSpellTexture=function(id) return id+6000 end}
local lists={}
C_UnitAuras={GetAuraDataByIndex=function(unit,index,filter)
    if filter:find('HARMFUL',1,true) then return nil end
    return lists[index]
end}
local function region()
    local r={shown=false}
    function r:Show() self.shown=true end
    function r:Hide() self.shown=false end
    function r:SetTexture(tex) self.texture=tex;return true end
    function r:SetTexCoord(...) self.coords={...} end
    function r:Clear() self.cleared=true;self.duration=nil end
    function r:SetCooldown(start,dur) self.start,self.duration=start,dur end
    return r
end
assert(loadfile('SecondaryPortrait.lua'))('bjarkiPortraits',BP)
local count=0
local function eq(value,expected,label)
    assert(value==expected,(label or 'mismatch')..': got '..tostring(value)..' expected '..tostring(expected))
    count=count+1
end
local function aura(spell,id,duration)
    duration=duration or 2100
    return {spellId=spell,auraInstanceID=id,icon=spell+20000,
        duration=duration,expirationTime=2000+duration,timeMod=1,isNameplateOnly=false}
end
local function warriorHost()
    return {unit='player',_buildComplete=true,_hostileUnit=false,_assistable=true,
        _containerWriteFailures=0,_readableTierOwners={},
        _formStateActive=true,_formStateSpellID=2457,_formStateReason='player-forms:proven',
        secondaryBadge=region(),racePortrait=region(),secondaryCooldown=region()}
end
local h=warriorHost()
-- The primary is Welcoming Campfire (257), then verified Battle Stance
-- (SelfState 150, static 149), then Camp Benefits (90), then Nearby (4).
lists={aura(1229739,7,48),aura(1229741,9,2100),aura(1283391,13,900)}
local second,reason=R.GetReadableSecondaryAura(h)
eq(reason,'verified-aura-then-form','higher aura outranks stance')
eq(second and second.staticForm,true,'stance is an eligible secondary state')
eq(second and second.spellID,2457,'current Battle Stance ID')
eq(second and second.tier.level,149,'existing static form priority below SelfState')
R.ReconcileSecondaryPortrait(h,true,true)
eq(h._secondaryMode,'form','secondary shows static form rather than race')
eq(h._secondaryAuraSpellID,2457,'secondary shows current form icon')
eq(h._secondaryAuraTier,'FormState','secondary labels existing state priority')
eq(h._secondaryAuraInstanceID,nil,'no fake aura occurrence for form')
eq(h.racePortrait.texture,8457,'observed form icon texture, not race')
eq(h.secondaryCooldown.shown,false,'static state has no timer')
eq(h._secondaryPositiveExpiry,nil,'static form cannot be retained as a timed positive')
-- When TWO auras outrank the form, second must be the genuine second aura.
lists={aura(1229739,15,48),aura(642,16,20),aura(1229741,17,2100)}
second,reason=R.GetReadableSecondaryAura(h)
eq(reason,'verified-readable','two high-ranked auras outrank form')
eq(second and second.spellID,1229739,'Welcoming Campfire after higher immunity')
R.ReconcileSecondaryPortrait(h,true,true)
eq(h._secondaryMode,'aura','higher aura second is timed')
eq(h._secondaryAuraSpellID,1229739,'second aura rather than form when two are stronger')
-- When form is higher than every readable aura, Camp Benefits becomes second.
lists={aura(1229741,19,2100),aura(1283391,20,900)}
second,reason=R.GetReadableSecondaryAura(h)
eq(reason,'verified-form-then-aura','form higher than low-tier buffs')
eq(second and second.spellID,1229741,'Camp Benefits second after form')
R.ReconcileSecondaryPortrait(h,true,true)
eq(h._secondaryMode,'aura','Camp Benefits uses timed aura presentation')
eq(h._secondaryAuraSpellID,1229741,'Camp Benefits icon displayed')
-- One public spell and an independently derived form with the SAME
-- spell identity must not consume primary and secondary slots.
h._formStateSpellID=1229739
lists={aura(1229739,42,48),aura(1229741,43,2100)}
local dup,dupReason=R.GetReadableSecondaryAura(h)
eq(dupReason,'verified-readable','duplicate form witness is not second')
eq(dup and dup.spellID,1229741,'different Camp Benefits aura remains runner-up')
h._formStateSpellID=2457

-- A form alone is only one effect; secondary falls back to race.
lists={}
second,reason=R.GetReadableSecondaryAura(h)
eq(second,nil,'one form is not a two-effect election')
eq(reason,'not-two-presentable','form only falls back')
R.ReconcileSecondaryPortrait(h,true,true)
eq(h._secondaryMode,'race','race fallback when form is sole known state')
-- Form must remain positively proven; no speculative state from just class ID.
h._formStateReason='player-forms:unreadable'
lists={aura(1229739,21,48),aura(1229741,22,2100)}
second,reason=R.GetReadableSecondaryAura(h)
eq(second,nil,'unproven form aborts election')
eq(reason,'form-unproven','unproven form diagnostic')
-- Without an icon, do not draw an invented one for a known stance.
h._formStateReason='player-forms:proven'
C_Spell.GetSpellTexture=function() return nil end
R.ReconcileSecondaryPortrait(h,true,true)
eq(h._secondaryMode,'race','unavailable form icon must not draw bogus badge')
-- Hostile aura-first case needs the actual presented main occurrence to agree.
h=warriorHost();h.unit='target';h._hostileUnit=true;h._hostileRelationReadable=true
h._hostileAuraListComplete=true;h._hostileElectionReadable=true
h._hostileReadable=true;h._hostileActive=true
h._hostileSpellID=1229739;h._hostileTierKey='HonorlessTarget';h._hostileAuraInstanceID=21
second,reason=R.GetReadableSecondaryAura(h)
eq(reason,'verified-aura-then-form','matching hostile aura first permits stance second')
eq(second and second.staticForm,true,'hostile static form second')
h._hostileAuraInstanceID=999
second,reason=R.GetReadableSecondaryAura(h)
eq(second,nil,'mismatched hostile main cannot authorize second')
eq(reason,'hostile-primary-mismatch','hostile main mismatch diagnostic')
print('secondary form ranking: '..count..' real-map checks passed')
