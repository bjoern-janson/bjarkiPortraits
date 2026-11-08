-- Source-level Ghost + Boosted Rest top-two election, real spell/tier policy.
-- Portable ordinary Lua model; protected live-client values are not simulated.
local BP={Runtime={}}
local R=BP.Runtime
local function load(name)
    return assert(loadfile(name..'.lua'))('bjarkiPortraits',BP)
end
load('Spells'); load('Core'); load('Priority')
local checks=0
local function eq(actual,expected,message)
    assert(actual==expected,(message or 'value')..': got '..tostring(actual)..', expected '..tostring(expected))
    checks=checks+1
end
R.CanAccess=function(x) return x~='SECRET' end
R.ReadAuraField=function(a,k)
    if a==nil or not R.CanAccess(a) then return nil,false end
    local v=a[k]
    if not R.CanAccess(v) then return nil,false end
    return v,true
end
R.SafeBool=function(fn,...)
    local ok,value=pcall(fn,...)
    return value,ok and type(value)=='boolean'
end
R.ExactFilterAllowed=function(_,helpful) return helpful end
R.AuraIsNeverSecret=function() return false end
R.ApplyCountdownFormat=function()end
R.ResolveRaceBaselineAtlas=function()return 'Interface\\RaceSheet',{0,0.125,0,0.25},false end
R.db={secondaryPortrait=true}
R.testMode=false
local byUnit={}
local function aura(spell,id,opts)
    local a={spellId=spell,auraInstanceID=id,icon=spell+10000,
        duration=(spell==1229451 and 3600 or 0),expirationTime=4600,
        timeMod=1,isNameplateOnly=false}
    if opts then for k,v in pairs(opts) do a[k]=v end end
    return a
end
C_UnitAuras={GetAuraDataByIndex=function(unit,index,filter)
    local polarity=filter:find('HARMFUL',1,true) and 'harmful' or 'helpful'
    return byUnit[unit] and byUnit[unit][polarity] and byUnit[unit][polarity][index] or nil
end}
local function region()
    local f={shown=false}
    function f:Show()self.shown=true end
    function f:Hide()self.shown=false end
    function f:SetTexture(v)self.texture=v;return true end
    function f:SetTexCoord(...)end
    function f:Clear()self.duration=nil end
    function f:SetCooldown(start,duration)self.start=start;self.duration=duration end
    return f
end
load('SecondaryPortrait')
local function ghostHost(unit)
    return {unit=unit or 'player',_buildComplete=true,
        _hostileUnit=false,_assistable=true,_hostileRelationReadable=true,
        _containerWriteFailures=0,_readableTierOwners={},
        _ghostActive=true,_ghostReadable=true,_ghostSource='unit-state',
        secondaryBadge=region(),racePortrait=region(),secondaryCooldown=region(),
        unitFrame={IsShown=function()return true end}}
end
local boost=aura(1229451,16)
local ghostAura=aura(8326,15)
local ghostVariant=aura(9036,20)
local h=ghostHost()
byUnit.player={helpful={},harmful={ghostAura,boost}}
local second,why=R.GetReadableSecondaryAura(h)
eq(why,'verified-ghost-then-aura','verified Ghost is first without discarding every aura')
eq(second and second.spellID,1229451,'Boosted Rest is second')
eq(second and second.tier.key,'BoostedRest','Boosted Rest retains priority-zero lane')
eq(second and second.tier.level,0,'Boosted Rest remains absolute bottom')
R.ReconcileSecondaryPortrait(h,true,true)
eq(h._secondaryMode,'aura','second circle shows an actual aura')
eq(h._secondaryAuraSpellID,1229451,'second circle shows Boosted Rest')
eq(h.racePortrait.texture,boost.icon,'second circle uses verified Boosted Rest icon')
eq(h.secondaryCooldown.duration,3600,'second circle shows real duration')
eq(h._secondaryElectionReason,'verified-ghost-then-aura','diagnostics expose first-place Ghost proof')
-- Three spell representations of Ghost must never count as extra effects.
byUnit.player.harmful={ghostAura,ghostVariant,aura(1278162,21),boost}
second,why=R.GetReadableSecondaryAura(h)
eq(why,'verified-ghost-then-aura','multiple Ghost debuff variants deduplicate')
eq(second and second.spellID,1229451,'none of the Ghost variants displaces Boosted Rest')
-- Some client builds expose the unit Ghost state but no Ghost AuraData.
-- The state itself is still positive evidence for the real main portrait.
byUnit.player.harmful={boost}
second,why=R.GetReadableSecondaryAura(h)
eq(why,'verified-ghost-then-aura','Ghost state remains first without a Ghost debuff entry')
eq(second and second.spellID,1229451,'single public Boosted Rest is second to the state')
-- Waiting to Resurrect sits at the same visible frame level as the Ghost
-- presenter. A tie is unknown, not permission to replace the main portrait.
local waiting=aura(2584,51,{duration=60,expirationTime=1060})
byUnit.player.helpful={waiting}
second,why=R.GetReadableSecondaryAura(h)
eq(second,nil,'Ghost / Waiting equal-level ordering remains unproven')
eq(why,'ghost-rank-tie','equal primary priority fails closed')
byUnit.player.helpful={}
byUnit.player.harmful={ghostAura,ghostVariant}
second,why=R.GetReadableSecondaryAura(h)
eq(second,nil,'Ghost alone does not produce duplicate second-place icon')
eq(why,'not-two-presentable','Ghost without another effect returns fallback')
-- No positive Ghost state: an aura/death guess cannot claim priority first.
h._ghostSource='none'
byUnit.player.harmful={ghostAura,boost}
second,why=R.GetReadableSecondaryAura(h)
eq(second,nil,'missing authoritative Ghost evidence revokes selection')
eq(why,'ghost-unproven','unproven state is diagnostic')
-- The real Ghost presenter can also be established by a positive aura
-- when the unit-state API itself is restricted.
h._ghostSource='aura'; h._ghostReadable=false
second,why=R.GetReadableSecondaryAura(h)
eq(why,'verified-ghost-then-aura','positive Ghost aura remains an authoritative state')
eq(second and second.spellID,1229451,'positive Ghost aura still ranks Boosted Rest second')
h._ghostSource='unit-state'; h._ghostReadable=false
second,why=R.GetReadableSecondaryAura(h)
eq(why,'ghost-unproven','unreadable UnitIsGhost cannot be inferred')
h._ghostReadable=true
-- Unreadable Boosted Rest identity fails closed, even with a proven Ghost.
byUnit.player.harmful={ghostAura,aura(1229451,'SECRET')}
second,why=R.GetReadableSecondaryAura(h)
eq(second,nil,'no guessed Boosted Rest from an unreadable instance ID')
eq(why,'incomplete-identity','identity gap is explicit')
-- A new lower-priority aura cannot displace the main Ghost. Baseline only.
byUnit.player.harmful={ghostAura,boost}
h._ghostActive=false
second,why=R.GetReadableSecondaryAura(h)
eq(second,nil,'two auras without state witness are not mistaken for Ghost + Boost')
-- The same proven Ghost on a friendly target (not just player) can elect Boost.
local t=ghostHost('target')
byUnit.target={helpful={},harmful={ghostAura,boost}}
second,why=R.GetReadableSecondaryAura(t)
eq(why,'verified-ghost-then-aura','friendly target also uses positive unit state')
eq(second and second.spellID,1229451,'friendly target Boosted Rest second')
print('secondary Ghost state and bottom aura: '..checks..' checks passed')
