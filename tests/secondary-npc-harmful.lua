-- Full real priority/spell table, but simulated public WoW aura APIs.
-- NPCs may have multiple harmful effects without a race or a helpful main.
-- Do not claim a native main winner from unobserved/secret data.
local BP = {Runtime={}}
assert(loadfile('Spells.lua'))('bjarkiPortraits', BP)
assert(loadfile('Priority.lua'))('bjarkiPortraits', BP)
local R=BP.Runtime
R.SecondaryOwnerVisible = function() return true end -- Visible owner for this isolated election fixture.
R.db={secondaryPortrait=true}
R.CanAccess=function(value) return value ~= 'SECRET' end
R.ReadAuraField=function(aura,key)
    if not aura or not R.CanAccess(aura) or not R.CanAccess(aura[key]) then
        return nil,false
    end
    return aura[key],true
end
R.SafeBool=function(fn,...)
    local ok,value=pcall(fn,...)
    return value, ok and R.CanAccess(value) and type(value)=='boolean'
end
R.ExactFilterAllowed=function(unit,helpful)
    return (unit=='target' or unit=='focus') and not helpful
end
R.NativeExactContainerAllowed=function(unit,tier)
    return (unit=='target' or unit=='focus') and tier.helpful==false
end
R.ApplyCountdownFormat=function() end
R.ResolveRaceBaselineAtlas=function() return nil,'npc-no-race-art',false end
R.testMode=false
local contents={helpful={},harmful={}}
local secretRead=false
C_UnitAuras={GetAuraDataByIndex=function(_,index,filter)
    if secretRead then error('modeled restricted aura index') end
    return contents[filter:find('HARMFUL',1,true) and 'harmful' or 'helpful'][index]
end}
local now=100
GetTime=function() return now end
InCombatLockdown=function() return false end
local guid='Creature-0-9000-111-4'
UnitGUID=function() return guid end
local function frame()
    local f={shown=false}
    function f:Show() self.shown=true end
    function f:Hide() self.shown=false end
    function f:SetTexture(tex) self.texture=tex;return true end
    function f:SetTexCoord(...) self.coords={...};return true end
    function f:SetCooldown(start,duration) self.start=start;self.duration=duration end
    function f:Clear() self.duration=nil end
    return f
end
assert(loadfile('SecondaryPortrait.lua'))('bjarkiPortraits',BP)
local checks=0
local function eq(a,b,label)
    assert(a==b,(label or 'comparison')..': '..tostring(a)..' vs '..tostring(b))
    checks=checks+1
end
local function aura(id,instance)
    return {spellId=id,auraInstanceID=instance,icon=id+1000,
        duration=11,expirationTime=111,timeMod=1,isNameplateOnly=false}
end
local function host(unit)
    unit=unit or 'target'
    local h={unit=unit,_buildComplete=true,_hostileUnit=true,
        _hostileRelationReadable=true,_isPlayer=false,_playerReadable=true,
        _hostileCount=0,_hostileAuraListComplete=true,_hostileElectionReadable=true,
        _hostileActive=false,_formStateActive=false,_exactHarmfulAllowed=true,
        _smallHarmfulEnabled=true,_containerWriteFailures=0,
        _readableTierOwners={},secondaryBadge=frame(),racePortrait=frame(),
        secondaryCooldown=frame(),containers={}}
    for i,tier in ipairs(R.TIERS) do
        h.containers[i]={tier=tier, enabled=tier.filter:sub(1,7)=='HARMFUL'}
        h.containers[i].IsEnabled = function(self) return self.enabled end
        h.containers[i].IsShown = function(self) return self.enabled end
    end
    return h
end
local h=host()
-- Slows 278 outranks DoTs 190. The lower generic harmful semantic filter
-- is irrelevant, and may not demand a second restricted native oracle.
contents.harmful={aura(772,24),aura(1715,28)}
local selected,reason=R.GetReadableSecondaryAura(h)
eq(reason,'npc-readable-harmful-projection','NPC exact harmful main permits second')
eq(selected and selected.spellID,772,'Rend is secondary behind Hamstring')
eq(selected and selected.tier.key,'DoTs','Rend remains DoTs')
R.ReconcileSecondaryPortrait(h,true,false)
eq(h._secondaryMode,'aura','NPC badge displays a real secondary debuff')
eq(h._secondaryAuraSpellID,772,'NPC secondary texture is correct')
eq(h.secondaryBadge.shown,true,'NPC badge is visible without race fallback')
eq(h.secondaryCooldown.duration,11,'NPC second uses native aura duration')
-- The hostile helpful-only helper is NOT the authority on a harmful NPC.
-- Its winner may be indeterminate even though this reader can independently
-- prove the complete public helpful+harmful union and harmful first place.
h=host()
h._hostileAuraListComplete=false
h._hostileElectionReadable=false
selected,reason=R.GetReadableSecondaryAura(h)
eq(reason,'npc-readable-harmful-projection','NPC can use its own complete union instead of helper result')
eq(selected and selected.spellID,772,'NPC second is still Rend under incomplete helper')
-- An unreadable IsEnabled is not evidence that an addon-owned container was
-- disabled. The successfully applied setter state is a bounded witness.
h=host()
local slowIndex
for i,tier in ipairs(R.TIERS) do
    if tier.key=='Slows' then slowIndex=i; break end
end
assert(slowIndex)
h.containers[slowIndex].IsEnabled=function() return 'SECRET' end
h.containers[slowIndex]._bjarkiAppliedShown=true
selected,reason=R.GetReadableSecondaryAura(h)
eq(reason,'npc-readable-harmful-projection','last successful native enable proves exact NPC slot')
eq(selected and selected.spellID,772,'native fallback still uses complete public occurrence')
h.containers[slowIndex]._bjarkiAppliedShown=false
selected,reason=R.GetReadableSecondaryAura(h)
eq(reason,'npc-native-slot-unreadable','known disabled native slot is refused')
h.containers[slowIndex]._bjarkiAppliedShown=nil
selected,reason=R.GetReadableSecondaryAura(h)
eq(reason,'npc-native-slot-unreadable','unknown native state without prior success fails closed')
h=host()

-- A pair within one exact tier uses the native reverse aura-instance order.
contents.harmful={aura(772,34),aura(6546,21)}
selected,reason=R.GetReadableSecondaryAura(h)
eq(reason,'npc-readable-harmful-projection','same-tier NPC two harms')
eq(selected and selected.auraInstanceID,21,'lower instance ID is second')
-- A public generic harmful pair can also be shown ONLY when the native
-- CrowdControl/PriorityDebuff filters are positively excluded and the exact
-- generic fallback is enabled. Never guess unknown CC classification.
AuraUtil={IsPriorityDebuff=function() return false end}
C_UnitAuras.IsAuraFilteredOutByInstanceID=function(_,_,filter)
    return filter:find("CROWD_CONTROL",1,true) ~= nil
end
contents.harmful={aura(990001,71),aura(990002,66)}
h=host()
selected,reason=R.GetReadableSecondaryAura(h)
eq(reason,'npc-readable-harmful-projection','verified generic NPC fallback can project')
eq(selected and selected.auraInstanceID,66,'native generic reverse instance ID order')
eq(selected and selected.tier.key,'SmallFriendlyHarmful','generic still has existing level 175')
-- Exact harmful permission may be unknown while the NPC's identity-blind
-- native harmful slot is positively enabled and publicly visible.
h=host();h._exactHarmfulAllowed=false
selected,reason=R.GetReadableSecondaryAura(h)
eq(reason,'npc-readable-harmful-projection','enabled generic NPC slot admits projection')
eq(selected and selected.auraInstanceID,66,'NPC generic second remains occurrence-ordered')
h._smallHarmfulEnabled=false
selected,reason=R.GetReadableSecondaryAura(h)
eq(reason,'hostile-primary-unverified','no exact or generic proof fails closed')
h=host()
-- An unreadable higher CrowdControl filter could overturn generic priority.
C_UnitAuras.IsAuraFilteredOutByInstanceID=nil
selected,reason=R.GetReadableSecondaryAura(h)
eq(selected,nil,'unknown higher semantic cannot be skipped')
eq(reason,'native-filter-unreadable','unreadable CrowdControl defeats generic proof')
AuraUtil=nil
-- No second effect means NO manufactured NPC race.
contents.harmful={aura(772,34)}
R.ReconcileSecondaryPortrait(h,true,false)
eq(h._secondaryMode,'hidden','NPC with one harm has no fabricated race')
eq(h.secondaryBadge.shown,false,'empty secondary circle hides')
-- Hostile players are still distinct from NPCs and require their own verified
-- main helper/form before a second may be projected.
contents.harmful={aura(772,24),aura(1715,28)}
h=host();h._isPlayer=true
selected,reason=R.GetReadableSecondaryAura(h)
eq(selected,nil,'hostile player cannot use NPC path')
eq(reason,'hostile-primary-unverified','hostile player still guarded')
-- Unknown race/player identity is not equivalent to a proven NPC.
h=host();h._playerReadable=false;h._isPlayer=nil
selected,reason=R.GetReadableSecondaryAura(h)
eq(reason,'hostile-primary-unverified','unknown player status fails closed')
-- Do not project if the native exact primary slot was disabled or if writes
-- could not be verified.
h=host();local slowTierIndex
for i,tier in ipairs(R.TIERS) do if tier.key=='Slows' then slowTierIndex=i end end
assert(slowTierIndex)
h.containers[slowTierIndex].enabled=false
selected,reason=R.GetReadableSecondaryAura(h)
eq(selected,nil,'disabled main container disallows NPC projection')
eq(reason,'npc-native-slot-unreadable','disabled main slot diagnostic')
h=host();h._containerWriteFailures=1
selected,reason=R.GetReadableSecondaryAura(h)
eq(reason,'native-update-failed','write failure blocks NPC projection')
-- A harmless, lower-level helpful aura on an NPC does not invalidate the
-- complete harmful-first projection. Check *all* auras before deciding.
h=host();h._hostileCount=1
contents.helpful={aura(1126,12)} -- BaselineClass 90 below Slows 278 / DoTs 190
selected,reason=R.GetReadableSecondaryAura(h)
eq(reason,'npc-readable-harmful-projection','lower helpful NPC aura cannot veto stronger harmful main')
eq(selected and selected.spellID,772,'Rend stays second beneath Hamstring')
-- If helpful Immunity 330 becomes the real first-place candidate, do NOT
-- falsely claim that a harmful native slot is the main portrait.
contents.helpful={aura(642,13)}
selected,reason=R.GetReadableSecondaryAura(h)
eq(reason,'hostile-primary-unverified','higher helpful main requires its own direct witness')
eq(selected,nil,'unproven helpful main never yields second harmful')
contents.helpful={}
-- A restricted aura list is unknown, even on an otherwise proven NPC.
h=host(); secretRead=true
selected,reason=R.GetReadableSecondaryAura(h)
eq(selected,nil,'secret current evidence is not promoted')
eq(reason,'inaccessible-index','read restriction diagnostic')
secretRead=false
-- Focus frame supports the same public NPC case. Party pets/ToT do not.
h=host('focus')
selected,reason=R.GetReadableSecondaryAura(h)
eq(reason,'npc-readable-harmful-projection','focused NPC also receives second harmful')
eq(selected and selected.spellID,772,'focused NPC second matches exact tier order')
h=host('party1')
selected,reason=R.GetReadableSecondaryAura(h)
eq(reason,'hostile-primary-unverified','party tokens cannot impersonate NPC target')
h=host('targettarget')
selected,reason=R.GetReadableSecondaryAura(h)
eq(reason,'unit-excluded','ToT remains excluded')
print('NPC harmful secondary evidence: '..checks..' assertions passed')
