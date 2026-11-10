-- Drive the actual secondary election/presenter and native backup with an
-- already painted school-interrupt record from the main host.
local BP={}
for _,module in ipairs({"Spells","Core","Interrupts","Priority","SecondaryPortrait","NativeSecondProbe"}) do
    assert(loadfile(module..".lua"))("bjarkiPortraits",BP)
end
local R=BP.Runtime
R.ApplyDefaults()
R.ExactFilterAllowed=function()return true end
local helpful,harmful={},{}
local sealed,denyClock=false,false
local now=100
GetTime=function()return now end
UnitGUID=function()return "Player-current" end
UnitIsUnit=function(a,b)return a==b end
InCombatLockdown=function()return true end
UnitRace=function()return "Human","Human" end
UnitSex=function()return 2 end
C_Timer={After=function()end}
C_Spell={GetSpellTexture=function(spell)return spell end}
C_UnitAuras={GetAuraDataByIndex=function(_,index,filter)
    if sealed then error("protected aura index") end
    return (filter:match("^HELPFUL") and helpful or harmful)[index]
end,IsAuraFilteredOutByInstanceID=function(_,_,filter)
    return filter:find("IMPORTANT",1,true)~=nil or filter:find("DEFENSIVE",1,true)~=nil
        or filter:find("CROWD_CONTROL",1,true)~=nil
end}
local function region()
    return {shown=true,IsShown=function(s)return s.shown end,IsVisible=function(s)return s.shown end,
        Show=function(s)s.shown=true end, Hide=function(s)s.shown=false end,
        SetTexture=function(s,v)s.art=v;return true end, SetTexCoord=function()end,
        SetCooldown=function()return not denyClock end,Clear=function(s)s.record=nil end,
        SetCooldownFromDurationObject=function(s,object)
            if denyClock then return false end
            s.record=object;return true
        end}
end
local function aura(spell,instance,expires)
    return {spellId=spell,auraInstanceID=instance,icon=spell,duration=10,expirationTime=expires or 108,
        isNameplateOnly=false,timeMod=1}
end
local host={unit="player",_buildComplete=true,_hostileUnit=false,_assistable=true,
    unitFrame=region(),secondaryBadge=region(),racePortrait=region(),secondaryCooldown=region(),containers={}}
host.unitFrame.unit="player"
for i in ipairs(R.TIERS) do host.containers[i]={IsEnabled=function()return true end,IsShown=function()return true end} end
R.hosts.player=host
local nativeClock=setmetatable({},{__index=function()error("opaque clock inspected")end})
C_LossOfControl={GetActiveLossOfControlDataCountByUnit=function()return 1 end,
    GetActiveLossOfControlDataByUnit=function()return {locType="SCHOOL_INTERRUPT",spellID=1766,
        iconTexture=22222,startTime=99,duration=5} end,GetActiveLossOfControlDuration=function()return nativeClock end}
local interrupt=assert(R.GetSchoolInterrupt("player"))
local function reconcile()
    local reads={unit=host.unit}
    R.ReconcileSecondaryPortrait(host,true,true,reads)
    return reads
end
local function pair(firstID,secondID)
    local second,reason,first=R.GetReadableSecondaryAura(host)
    assert(first and first.spellID==firstID and second and second.spellID==secondID,
        "expected "..firstID.."/"..secondID..", got "..tostring(reason))
end
host._schoolInterrupt=interrupt
helpful={aura(17,4)}
pair(1766,17)
reconcile()
assert(host.racePortrait.art==17 and host._secondaryPositiveExpiry==104,"lockout bounds ranked aura")
harmful={aura(853,6)}
pair(853,1766)
reconcile()
assert(host.racePortrait.art==22222 and host.secondaryCooldown.record==nativeClock,"event icon/clock occupy second")
helpful={aura(642,7)}
pair(642,853)
local reads=reconcile()
assert(host.racePortrait.art==853 and reads.nativeSecondWitness and reads.auraPairAboveStatic,
    "two stronger real auras still supply the native witness")
local probe={ready=true,boundUnit="player",boundGUID="Player-current",
    clip=region(),container={},formatRetries={},cooldowns={},decimals=R.db.showDecimals==true}
host._nativeSecondProbe=probe
host._secondaryMode,host._raceBaselineActive="race",true
R.UpdateNativeSecondProbe(host,true,false,true,true,false,false,reads)
assert(probe.clip.shown and probe.staticExpiry and probe.staticExpiry.deadline==108,
    "two proven higher timed auras can still use the bounded native fallback")
helpful={};harmful={aura(1766,8),aura(772,11)}
pair(1766,772)
interrupt.auraInstanceID=18
harmful={aura(18425,18),aura(772,11)}
pair(1766,772)
harmful={aura(853,18),aura(772,11)}
pair(853,772)
harmful={aura(853,18),aura(1766,8),aura(772,11)}
pair(853,772)
interrupt.auraInstanceID=nil
harmful={aura(853,8)}
reconcile();sealed=true
reconcile()
assert(host.racePortrait.art==22222 and host.secondaryCooldown.record==nativeClock,"same proven timed pair may survive a sealed read")
host._schoolInterrupt=nil
reconcile()
assert(host.secondaryCooldown.record==nil,"old school clock cannot survive the source's removal")
sealed=false;helpful={aura(17,4)};harmful={aura(853,8)}
pair(853,17)
reconcile();sealed=true;host._schoolInterrupt=interrupt
reconcile()
assert(host._secondaryMode~="aura","new lockout invalidates the previous sealed rank")
R.UpdateNativeSecondProbe(host,true,false,true,true,false,false,{unit="player"})
assert(not host._nativeSecondProbe.clip.shown,"native-only aura ribbon cannot count a sealed school-lockout pair")
sealed=false;harmful={aura(853,8)};denyClock=true
reconcile();assert(host.secondaryCooldown.record==nil,"denied school clock retires previous presentation")
denyClock=false;reconcile()
now=104;reconcile();assert(host.secondaryCooldown.record==nil,"expired record cannot retain or repaint its clock")
now=100;host._schoolInterrupt=nil;host._schoolInterruptHidePending=true
assert(R.GetReadableSecondaryAura(host)==nil,"rejected main retirement prevents an unverified pair")
host._secondaryMode,host._raceBaselineActive="race",true
R.UpdateNativeSecondProbe(host,true,false,true,true,false,false,{unit="player"})
assert(not probe.clip.shown,"unknown main ownership also blocks native second")
host._schoolInterruptHidePending=nil;host._schoolInterrupt=interrupt
local show=host.secondaryBadge.Show;host.secondaryBadge.Show=function()return false end
reconcile();assert(host._secondaryMode~="interrupt","the badge must accept its visible write")
host.secondaryBadge.Show=show
now=100;host.unit="target";host.unitFrame.unit="target";R.hosts.target=host
host._hostileUnit,host._hostileRelationReadable,host._playerReadable,host._isPlayer=true,true,true,true
host._assistable=false;host._hostileAuraListComplete=false
helpful={};harmful={aura(772,9)}
pair(1766,772)
harmful={aura(853,8),aura(772,9)}
assert(R.GetReadableSecondaryAura(host)==nil,"unproven hostile primary cannot borrow the lower interrupt's witness")
host._hostileRelationReadable=false
assert(R.GetReadableSecondaryAura(host)==nil,"a lockout cannot turn an unknown relation into a public election")
-- Two independently confirmed school applications use the reader's stable order.
host.unit="player";host.unitFrame.unit="player";R.hosts.player=host
host._hostileUnit,host._hostileActive,host._assistable=false,false,true
host._schoolInterrupt=interrupt
local older={spellID=6552,icon=6552,startTime=98,duration=9,expires=107}
host._secondSchoolInterrupt=older
helpful={aura(17,9)};harmful={};sealed=false;now=100
pair(1766,6552);reconcile()
assert(host._secondaryAuraSpellID==6552 and host._secondaryPositiveExpiry==104,"earlier of both school clocks")
local clears,sets=0,0;local clear,set=host.secondaryCooldown.Clear,host.secondaryCooldown.SetCooldown
host.secondaryCooldown.Clear=function(...)clears=clears+1;return clear(...)end
host.secondaryCooldown.SetCooldown=function(...)sets=sets+1;return false end
reconcile()
assert(host._secondaryAuraSpellID==6552 and clears==0 and sets==0,"unchanged interrupt runner must keep the running clock")
host._secondSchoolInterrupt=nil;reconcile()
assert(host._secondaryAuraSpellID~=6552,"removed runner immediately retires")
host.secondaryCooldown.Clear,host.secondaryCooldown.SetCooldown=clear,set
host._secondSchoolInterrupt=older
harmful={aura(853,11)};pair(853,1766);reconcile()
sealed=true;reconcile();assert(host._secondaryAuraSpellID==1766,"unchanged known pair survives restricted read")
host._schoolInterrupt={spellID=1766,icon=22222,startTime=100,duration=5,expires=105}
reconcile();assert(host._secondaryAuraSpellID~=1766,"same spell but a renewed application has a different clock")
sealed=false;host._schoolInterrupt=interrupt
harmful={aura(853,11),aura(6552,19)};older.auraInstanceID=19
pair(853,1766)
harmful={aura(1766,19),aura(853,11)};helpful={aura(642,15)}
pair(642,853) -- Two lower record labels bridged by a single real occurrence cannot poison higher ranks.
harmful={aura(1766,19)};helpful={aura(17,9)};pair(1766,17)
interrupt.auraInstanceID=19;harmful={};pair(1766,17)
interrupt.auraInstanceID=nil
host._secondSchoolInterrupt={spellID=1766,icon=1766,startTime=98,expires=103}
harmful={};pair(1766,17)
host._secondSchoolInterrupt=older
older.expires=99;pair(1766,17)
older.expires=107;host._secondSchoolInterrupt=older;R.HideSecondaryPortrait(host,"reset-test")
local attempts=0
host.secondaryCooldown.SetCooldown=function()attempts=attempts+1;return false end
reconcile()
assert(host._secondaryAuraSpellID==6552,"a positively cleared art-only runner survives a refused clock")
for i=1,8 do reconcile() end
assert(attempts<=3,"native write denials get a bounded ordinary retry")
local blocked=attempts
host.secondaryCooldown.SetCooldown=function()attempts=attempts+1;return true end
R.ReconcileSecondaryPortrait(host,true,true,{unit=host.unit,interruptRefresh=true})
assert(attempts==blocked+1,"explicit refresh can recover a previously unavailable interrupt clock")
reconcile();assert(attempts==blocked+1,"recovered timer needs no further writes")
print("PASS school-interrupt secondary ordering, distinct identities, sealed evidence and fallback")
