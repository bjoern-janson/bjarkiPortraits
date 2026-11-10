-- Regression against the actual shipped tier maps, not simplified test tiers.
-- A complete self-helpful scan can rank exact known buffs even when the
-- separate native identity-filter oracle is unavailable to addon Lua.
local BP={Runtime={}}
assert(loadfile('Spells.lua'))('bjarkiPortraits',BP)
assert(loadfile('Priority.lua'))('bjarkiPortraits',BP)
local R=BP.Runtime
R.SecondaryOwnerVisible = function() return true end -- Visible owner for this isolated election fixture.
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
    function f:SetTexCoord(...) self.coords={...} end
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
local auras, harmful={}, {}
C_UnitAuras={GetAuraDataByIndex=function(unit,index,filter)
    if unit~='player' then return nil end
    if filter:sub(1,7)=='HELPFUL' then return auras[index] end
    if filter:sub(1,7)=='HARMFUL' then return harmful[index] end
    return nil
end}
local function aura(spell,id,shown)
    return {spellId=spell,auraInstanceID=id,icon=spell+10000,
        duration=120,expirationTime=220,timeMod=1,isNameplateOnly=shown or false}
end
local function eq(a,b,label) assert(a==b,(label or 'mismatch')..': '..tostring(a)..' ~= '..tostring(b)) end
-- Thorns 467 outranks Mark of the Wild 1126 on the current priority map.
R.ReconcileSecondaryPortrait(host,true,true)
local originalRace=host.racePortrait.texture
auras={aura(467,11),aura(1126,12)}
auras[2].duration,auras[2].expirationTime=nil,nil
R.ReconcileSecondaryPortrait(host,true,true)
eq(host._secondaryMode,'race','failed clock restores race fallback')
eq(host.racePortrait.texture,originalRace,'race cache matches drawn texture')
eq(host.racePortrait.coords[2],0.125,'race sheet UVs restored')
auras={}
R.ReconcileSecondaryPortrait(host,true,true)
eq(host.racePortrait.texture,originalRace,'empty aura list keeps original race art')
auras={aura(1126,120),aura(467,100)}
C_UnitAuras.GetAuraDuration=function()
    return setmetatable({}, {__index=function()error('denied duration member')end})
end
R.ReconcileSecondaryPortrait(host,true,true)
eq(host._secondaryMode,'aura','two known buffs without native oracle')
eq(host._secondaryAuraSpellID,1126,'second is Mark of the Wild')
eq(host._secondaryElectionReason,'verified-readable','positive reason')
local clear,hide,setClock=host.secondaryCooldown.Clear,host.secondaryCooldown.Hide,host.secondaryCooldown.SetCooldown
host.secondaryCooldown.Clear=function() error('protected reset') end
host.secondaryCooldown.Hide=function() error('protected hide') end
host.secondaryCooldown.SetCooldown=host.secondaryCooldown.Clear
auras={}
R.ReconcileSecondaryPortrait(host,true,true)
eq(host.secondaryBadge.shown,false,'race fallback cannot inherit an uncleared aura timer')
host.secondaryCooldown.Clear,host.secondaryCooldown.Hide,host.secondaryCooldown.SetCooldown=clear,hide,setClock
R.ReconcileSecondaryPortrait(host,true,true)
eq(host._secondaryMode,'race','safe fallback recovers after timer cleanup')
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
-- Friendly harmful Boosted Rest may be a readable second aura even though
-- the native exact harmful relation gate on player would be false.
auras={aura(1126,220)}
harmful={aura(1229451,221)}
harmful[1].duration=3600
-- Boosted Rest is an hour-long non-priority debuff outside CrowdControl.
-- These affirmative facts rule out promotion by a restricted native slot.
AuraUtil={IsPriorityDebuff=function()return false end}
R.SafeBool=function(fn,...)local ok,v=pcall(fn,...);return v,ok and type(v)=="boolean" end
C_UnitAuras.IsAuraFilteredOutByInstanceID=function(_,_,filter)
    if filter:find("CROWD_CONTROL",1,true) then return true end
end
R.ReconcileSecondaryPortrait(host,true,true)
eq(host._secondaryMode,'aura','friendly bottom status elected behind higher buff')
eq(host._secondaryAuraSpellID,1229451,'Boosted Rest becomes second')
eq(host._secondaryAuraTier,'BoostedRest','priority-zero category unchanged')
-- A higher harmful aura can also displace Boosted Rest into the badge.
-- This mock supplies the independent completed owner for the slow.
host._readableTierOwners.Slows={complete=true}
auras={}
harmful={aura(1715,321),aura(1229451,322)}
harmful[2].duration=3600
R.ReconcileSecondaryPortrait(host,true,true)
eq(host._secondaryMode,'aura','higher harmful winner and bottom status')
eq(host._secondaryAuraSpellID,1229451,'Boosted Rest follows higher slow')
print('secondary real tier eligibility passed')
