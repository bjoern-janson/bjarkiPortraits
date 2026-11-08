-- Execute the real AuraEngine.UpdateHost and secondary reader on a ghosted
-- friendly player. No private aura API or native frame internals inspected.
local BP={}
local R=nil
local count=0
local function eq(actual,expected,label)
 assert(actual==expected,(label or 'value')..' got '..tostring(actual)..' expected '..tostring(expected))
 count=count+1
end
issecretvalue=function()return false end
canaccessvalue=function()return true end
AuraContainerSortMethod={AuraInstanceIDOnly=1}
AuraContainerSortDirection={Reverse=1}
Enum={SecrecyLevel={NeverSecret=0}}
C_Secrets={GetSpellAuraSecrecy=function()return 1 end}
UnitExists=function()return true end
UnitIsPlayer=function()return true end
UnitCanAssist=function()return true end
UnitCanAttack=function()return false end
UnitIsPlayerControlledOrGroupMember=function()return false end
UnitIsGhost=function()return true end
UnitIsDeadOrGhost=function()return true end
UnitClass=function()return 'Mage','MAGE' end
InCombatLockdown=function()return false end
C_Spell={GetSpellTexture=function(id) return 100000+id end}
local ghost={spellId=8326,auraInstanceID=7,duration=0,
    icon=108326,timeMod=1,expirationTime=1000,isNameplateOnly=false}
local boost={spellId=1229451,auraInstanceID=9,duration=3600,
    icon=1229451+10000,timeMod=1,expirationTime=4600,isNameplateOnly=false}
local helpful={}
local harmful={ghost,boost}
local function byIndex(_,index,filter)
 return (filter:find('HARMFUL',1,true) and harmful or helpful)[index]
end
C_UnitAuras={GetAuraDataByIndex=byIndex,
    GetUnitAuraBySpellID=function()return nil end,
    GetPlayerAuraBySpellID=function()return nil end,
    GetAuraDuration=function()return nil end}
for _,module in ipairs({'Spells','Core','Priority','SecondaryPortrait','AuraEngine'}) do
 assert(loadfile(module..'.lua'))('bjarkiPortraits',BP)
end
R=BP.Runtime
R.ApplyDefaults()
R.ResolveRaceBaselineAtlas = function()
    return 'Interface\\RaceSheet', {0, 0.125, 0, 0.25}, false
end
local function frame()
 local f={shown=false,level=0}
 f.icon={SetTexture=function(self,texture)self.texture=texture;return true end,
         GetTexture=function(self)return self.texture end}
 f.cooldown={Clear=function(self)self.duration=nil end,
    SetCooldown=function(self,start,duration)self.start=start;self.duration=duration end}
 function f:Show()self.shown=true end
 function f:Hide()self.shown=false end
 function f:SetFrameLevel(level)self.level=level end
 return f
end
local function host()
 local h={unit='player',unitFrame={unit='player',IsShown=function()return true end},
     _buildComplete=true,smallBaseLevel=40,containers={},cooldowns={}}
 for _,name in ipairs({'Hostile','Baseline','Healing','WelcomingCampfire',
  'NearbyHarmful','TrackingHarmful','BoostedRest','Roots','Control','Stun',
  'InterruptSilence','Wounds','StatusEffects','ResurrectionSickness',
  'DoTs','FormState','Dazed','Demoralizing','BaselineHarmful',
  'PassiveDebuff','Slows','Forbearance','OffensiveHarmful',
  'WaitingToResurrect','Ghost','DivineProtection'}) do
  h['readable'..name..'Frame']=frame()
 end
 for index,tier in ipairs(R.TIERS) do
  h.containers[index]={tier=tier,enabled=false,
     SetEnabled=function(self,value)self.enabled=value end,
     SetShown=function(self,value)self.shown=value end,
     IsEnabled=function(self)return self.enabled end,
     UpdateAllAuras=function()end}
 end
 local widget=frame()
 widget.SetTexture=function(self,texture)self.texture=texture;return true end
 widget.SetAtlas=function()end
 widget.SetTexCoord=function()end
 h.secondaryBadge=frame()
 h.racePortrait=widget
 h.secondaryCooldown=frame().cooldown
 h.secondaryCooldown.Show=function(self)self.shown=true end
 h.secondaryCooldown.Hide=function(self)self.shown=false end
 return h
end
local h=host()
R.UpdateHost(h)
eq(h._hostileUnit,false,'actual host relation is friendly')
eq(h._ghostActive,true,'actual host positively presents Ghost')
eq(h._ghostSource,'unit-state','Ghost is backed by current UnitIsGhost')
eq(h.readableGhostFrame.shown,true,'original large ghost portrait stays visible')
eq(h._secondaryMode,'aura','actual host displays second aura')
eq(h._secondaryAuraSpellID,1229451,'actual host displays Boosted Rest as second')
eq(h._secondaryAuraTier,'BoostedRest','original bottom tier unchanged')
eq(h._secondaryElectionReason,'verified-ghost-then-aura','reason records ghost first')
eq(h.racePortrait.texture,boost.icon,'actual second aura artwork displayed')
-- A second ordinary refresh has the same intended native slot states.
-- Simulate protected SetEnabled/SetShown APIs refusing redundant writes:
-- the addon must not attempt them while already correctly configured.
local originalSetters={}
for i,container in ipairs(h.containers) do
 originalSetters[i]={container.SetEnabled,container.SetShown}
 container.SetEnabled=function()error('mock protected unchanged SetEnabled')end
 container.SetShown=function()error('mock protected unchanged SetShown')end
end
R.UpdateHost(h)
eq(h._containerWriteFailures,0,'unchanged native tiers skip protected writes')
eq(h._secondaryMode,'aura','valid secondary survives same-state host refresh')
for i,container in ipairs(h.containers) do
 container.SetEnabled=originalSetters[i][1]
 container.SetShown=originalSetters[i][2]
end
-- A real aura change that removes Boosted Rest must revoke the second icon.
harmful={ghost}
R.UpdateHost(h)
eq(h._secondaryMode,'race','ghost only falls back to race')
eq(h._secondaryAuraSpellID,nil,'removed Boosted Rest has no stale icon')
-- No unit-state Ghost without current positive source: ordinary election resumes.
UnitIsGhost=function()return false end
R.UpdateHost(h)
eq(h._ghostActive,false,'live negative UnitIsGhost clears state')
print('secondary Ghost real UpdateHost: '..count..' assertions passed')
