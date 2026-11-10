-- Source-backed regression for public HELPFUL/HARMFUL filtered membership.
-- The inclusive list can omit optional isNameplateOnly; a positively matching
-- aura in the native plain polarity list is a valid exact-lane witness.
local BP={Runtime={}}
assert(loadfile('Spells.lua'))('bjarkiPortraits',BP)
assert(loadfile('Priority.lua'))('bjarkiPortraits',BP)
local R=BP.Runtime
R.SecondaryOwnerVisible = function() return true end -- Visible owner for this isolated election fixture.
local checks=0
local function eq(a,b,label)
  assert(a==b,(label or 'value')..': got '..tostring(a)..', expected '..tostring(b));checks=checks+1
end
R.CanAccess=function(x) return x~='SECRET' end
R.ReadAuraField=function(a,k)
  if not a or not R.CanAccess(a) then return nil,false end
  local x=a[k];if not R.CanAccess(x) then return nil,false end
  return x,true
end
R.SafeBool=function(fn,...)
  local ok,value=pcall(fn,...)
  return value,ok and type(value)=='boolean'
end
R.db={secondaryPortrait=true}
R.NativeExactContainerAllowed=function(_,tier) return tier and tier.exact or false end
R.ExactFilterAllowed=function(unit,helpful)
  return unit=='player' or not helpful
end
R.AURA_ANCHOR_TEMPLATE='DisableUntrustedLayoutScriptsTemplate'
R.ResolveRaceBaselineAtlas=function(unit)
  if unit=='player' then return 'Interface\\Icons\\Ability_Tracking',{0,1,0,1},false end
  return nil,'npc-no-race'
end
R.ApplyCountdownFormat=function()end
local forbidPlain,plainCalls,inclusiveCalls=false,{HELPFUL=0,HARMFUL=0},0
local lists={}
C_UnitAuras={GetAuraDataByIndex=function(unit,index,filter)
  local polarity=filter:find('HARMFUL',1,true) and 'HARMFUL' or 'HELPFUL'
  local isInclusive=filter:find('INCLUDE_NAME_PLATE_ONLY',1,true)~=nil
  if isInclusive then inclusiveCalls=inclusiveCalls+1
  else
    plainCalls[polarity]=plainCalls[polarity]+1
    if forbidPlain then error('plain aura unavailable') end
  end
  local list=lists[unit] or {}
  local bucket=list[polarity] or {}
  return (isInclusive and bucket.inclusive or bucket.plain or bucket.inclusive or {})[index]
end}
local function aura(spell,id,opts)
  local a={spellId=spell,auraInstanceID=id,icon=spell+5000,duration=30,
    expirationTime=200,timeMod=1}
  if opts~=nil then a.isNameplateOnly=opts end
  return a
end
local function frame()
  local f={}
  function f:Show()self.shown=true end
  function f:Hide()self.shown=false end
  function f:SetTexture(v)self.texture=v end
  function f:SetTexCoord(...) end
  function f:SetCooldown(start,duration)self.start=start;self.duration=duration end
  function f:Clear()self.duration=nil end
  return f
end
assert(loadfile('SecondaryPortrait.lua'))('bjarkiPortraits',BP)
local function host(unit,mode)
  local h={unit=unit,_buildComplete=true,_hostileUnit=(mode=='hostile'),
    _hostileRelationReadable=true,_assistable=mode~='hostile',
    _containerWriteFailures=0,_readableTierOwners={},
    secondaryBadge=frame(),racePortrait=frame(),secondaryCooldown=frame()}
  if mode=='hostile' then
    h._playerReadable=true;h._isPlayer=false
    h._exactHarmfulAllowed=true
    h._hostileAuraListComplete=true;h._hostileElectionReadable=true
    h._hostileCount=0;h._hostileActive=false
  end
  h.containers={}
  for i,t in ipairs(R.TIERS) do
    h.containers[i]={IsEnabled=function()return true end}
  end
  return h
end
local function reset()
  forbidPlain=false;plainCalls={HELPFUL=0,HARMFUL=0};inclusiveCalls=0
end

-- Two ordinary helpful buffs with omitted isNameplateOnly. Formerly both were
-- rejected if the optional native IsAuraFilteredOutByInstanceID was missing.
local mark,thorns=aura(1126,10),aura(467,11)
reset();lists.player={HELPFUL={inclusive={mark,thorns},plain={mark,thorns}},HARMFUL={inclusive={}}}
local player=host('player','friendly')
local second,reason=R.GetReadableSecondaryAura(player)
eq(reason,'verified-readable','filtered plain membership rescues exact helpful pair')
eq(second and second.spellID,1126,'Thorns > Mark of the Wild')
eq(plainCalls.HELPFUL>0,true,'plain helpful called for missing optional bit')
eq(plainCalls.HELPFUL<=4,true,'only one bounded helpful filter scan')
R.ReconcileSecondaryPortrait(player,true,true)
eq(player._secondaryAuraSpellID,1126,'second texture rendered')

-- Positively nameplate-only auras do not get put into normal exact lanes.
reset();local nameplate=aura(467,12,true)
lists.player={HELPFUL={inclusive={mark,nameplate},plain={mark}},HARMFUL={inclusive={}}}
second,reason=R.GetReadableSecondaryAura(player)
eq(second,nil,'nameplate-only never enters plain Thorns')
eq(reason,'not-two-presentable','only one eligible exact aura')

-- A complete ordinary filter that omits an otherwise inclusive aura proves
-- that the candidate cannot enter a normal HELPFUL exact lane.
reset();lists.player={HELPFUL={inclusive={mark,thorns},plain={mark}},HARMFUL={inclusive={}}}
second,reason=R.GetReadableSecondaryAura(player)
eq(second,nil,'missing plain-filter membership rejects the candidate')
eq(reason,'not-two-presentable','filtered-out exact aura is absent, not unknown')

-- A contradictory reused aura occurrence ID in the plain scan is unknown;
-- neither the first record nor its duplicate may certify membership.
reset();local wrong=aura(467,10)
lists.player={HELPFUL={inclusive={mark,thorns},plain={mark,wrong,thorns}},HARMFUL={inclusive={}}}
second,reason=R.GetReadableSecondaryAura(player)
eq(second,nil,'duplicate native ID cannot authorize an exact aura')
eq(reason,'native-filter-unreadable','duplicate public identity fails closed')

-- No positive plain membership, no native oracle: do not guess eligibility.
reset();forbidPlain=true;lists.player={HELPFUL={inclusive={mark,thorns}},HARMFUL={inclusive={}}}
second,reason=R.GetReadableSecondaryAura(player)
eq(second,nil,'restricted normal filter cannot authorize icon')
eq(reason,'native-filter-unreadable','unavailable native filter reports uncertainty')

-- Hostile NPC with two known debuffs and an additional lower helpful buff:
-- the older hostileCount==0 / harmful-only gate refused this despite a known
-- stronger harmful primary and complete public lists.
reset();local hamstring,rend=aura(1715,31),aura(772,32)
local nearby=aura(1283391,33)
lists.target={HELPFUL={inclusive={nearby},plain={nearby}},
 HARMFUL={inclusive={hamstring,rend},plain={hamstring,rend}}}
local npc=host('target','hostile')
npc._hostileCount=1;npc._hostileActive=false
second,reason=R.GetReadableSecondaryAura(npc)
eq(second,nil,'unknown semantic membership could promote the restricted nearby effect')
C_UnitAuras.IsAuraFilteredOutByInstanceID=function(_,_,filter)
    if filter:find('DEFENSIVE',1,true) or filter:find('IMPORTANT',1,true) then return true end
    error('plain instance filter unavailable')
end
second,reason=R.GetReadableSecondaryAura(npc)
eq(reason,'npc-readable-harmful-projection','low helpful aura does not veto harmful NPC main')
eq(second and second.spellID,772,'Rend is second below Hamstring')
eq(second and second.tier.key,'DoTs','Rend real numeric tier preserved')
R.ReconcileSecondaryPortrait(npc,true,false)
eq(npc._secondaryMode,'aura','NPC with no race still receives verified debuff badge')
eq(npc._secondaryAuraSpellID,772,'NPC second aura drawn')

-- Higher helpful main with no positively presented helpful owner remains
-- unproven; never misrepresent an ordinary aura as a harmful main.
reset();local immunity=aura(642,34)
lists.target.HELPFUL={inclusive={immunity},plain={immunity}}
second,reason=R.GetReadableSecondaryAura(npc)
eq(second,nil,'NPC helpful primary not projected from harmful-only proof')
eq(reason,'hostile-primary-unverified','missing helpful primary authority explained')

-- Cannot infer non-player identity from absence: even with two harmful auras
-- we refuse the NPC route if UnitIsPlayer identity itself is inaccessible.
reset();npc._isPlayer=nil
lists.target.HELPFUL={inclusive={},plain={}}
second,reason=R.GetReadableSecondaryAura(npc)
eq(second,nil,'unknown identity cannot claim NPC exception')
eq(reason,'hostile-primary-unverified','unproven NPC identity blocks exception')

print('secondary filtered membership and mixed NPC: '..checks..' assertions passed')
