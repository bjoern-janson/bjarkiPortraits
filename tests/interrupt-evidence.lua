-- Offline witnesses for the Forever loss-of-control API and native clock sink.
local BP = {}
assert(loadfile("Core.lua"))("bjarkiPortraits", BP)
local loadInterrupts = loadfile("Interrupts.lua")
if loadInterrupts then loadInterrupts("bjarkiPortraits", BP) end
local R = BP.Runtime
assert(type(R.GetSchoolInterrupt) == "function", "missing landed school interrupt reader")
assert(type(R.SetSchoolInterruptClock) == "function", "missing landed school interrupt clock")

local function equal(actual, expected, label)
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local SECRET, OPAQUE = {}, setmetatable({}, {__index=function() error("inspected duration object") end})
issecretvalue = function(value) return rawequal(value, SECRET) end
local now = 102
GetTime = function() return now end
local rows, durationIndex, durationUnit, durationCalls
local function api(records)
    rows, durationIndex, durationUnit, durationCalls = records, nil, nil, 0
    C_LossOfControl = {
        GetActiveLossOfControlDataCountByUnit=function(unit) return #(rows[unit] or {}) end,
        GetActiveLossOfControlDataByUnit=function(unit, index) return rows[unit][index] end,
        GetActiveLossOfControlDuration=function(unit, index)
            durationUnit, durationIndex, durationCalls = unit, index, durationCalls + 1
            return rows[unit][index].clock
        end,
    }
    C_Spell = {GetSpellTexture=function(id) if id == 1766 then return 600 end end}
end
local function landed(id, start)
    return {locType="SCHOOL_INTERRUPT", spellID=id, iconTexture=44, startTime=start, duration=5}
end

local kick, counter = landed(1766, 100), landed(2139, 101)
counter.clock = OPAQUE
api({target={kick, counter}, focus={kick}})
local result, runner, complete = R.GetSchoolInterrupt("target")
equal(result.spellID, 2139, "latest proven interrupt")
equal(runner and runner.spellID, 1766, "distinct simultaneously active lockout")
equal(complete, true, "public positive snapshot")
equal(result.icon, 44, "native interrupt art")
equal(result.expires, 106, "native expiry")
equal(result.durationObject, OPAQUE, "opaque duration transported")
equal(durationCalls, 2, "only the two elected clocks fetched")
equal(durationUnit, "target", "victim-specific duration")
equal(durationIndex, 2, "exact winning index")
equal(R.GetSchoolInterrupt("focus").spellID, 1766, "focus remains independent")
rows.target = {counter, kick}
equal(R.GetSchoolInterrupt("target").spellID, 2139, "record order independent")
kick.startTime = 101
equal(R.GetSchoolInterrupt("target").spellID, 1766, "equal application times stable by public spell ID")

local shownObject, numericStart, numericDuration
local cooldown = {
    SetCooldownFromDurationObject=function(_, obj) shownObject=obj end,
    SetCooldown=function(_, start, duration) numericStart,numericDuration=start,duration end,
}
equal(R.SetSchoolInterruptClock(cooldown, result), true, "native clock applied")
equal(shownObject, OPAQUE, "opaque clock forwarded directly")
cooldown.SetCooldownFromDurationObject = function() return false end
equal(R.SetSchoolInterruptClock(cooldown, result), true, "explicitly declined native setter uses numeric clock")
equal(numericStart, 101, "numeric start")
equal(numericDuration, 5, "numeric duration")
cooldown.SetCooldown = function() return SECRET end
equal(R.SetSchoolInterruptClock(cooldown, result), false, "secret setter result cannot certify a clock")
cooldown.SetCooldown = function() error("denied") end
equal(R.SetSchoolInterruptClock(cooldown, result), false, "both setters rejected")
now = 107
shownObject = nil
cooldown.SetCooldownFromDurationObject = function(_, obj) shownObject=obj end
equal(R.SetSchoolInterruptClock(cooldown, result), false, "expired positive cannot rebind its native clock")
equal(shownObject, nil, "stale native duration not forwarded")
now = 102
local future = landed(72, 110)
api({target={future}})
local invalidTiming = R.GetSchoolInterrupt("target")
equal(invalidTiming.startTime, nil, "an active interrupt cannot yet have a future application time")
equal(invalidTiming.expires, nil, "future application label cannot create a deadline")
equal(R.SetSchoolInterruptClock(cooldown, invalidTiming), false, "unsupported timing stays hidden")

local sealed = {locType="SCHOOL_INTERRUPT", spellID=1766, iconTexture=SECRET,
    startTime=SECRET, duration=SECRET, timeRemaining=SECRET, auraInstanceID=SECRET, clock=OPAQUE}
api({party2={sealed}})
local p = R.GetSchoolInterrupt("party2")
equal(p.icon, 600, "public spell art fallback")
equal(p.expires, nil, "opaque deadline is never invented")
equal(p.auraInstanceID, nil, "secret instance is optional")
equal(p.durationObject, OPAQUE, "secret times still allow the native handle")
sealed.clock = SECRET
p = R.GetSchoolInterrupt("party2")
equal(p.durationObject, nil, "sealed handle")
equal(R.SetSchoolInterruptClock(cooldown, p), false, "untimed evidence cannot create digits")
sealed.clock, sealed.timeRemaining = nil, 2.5
p = R.GetSchoolInterrupt("party2")
equal(p.expires, 104.5, "reported remaining time anchors public deadline")
equal(p.startTime, nil, "remaining alone cannot establish application time")
equal(p.duration, nil, "remaining alone cannot establish total duration")
cooldown.SetCooldown = function(_, start, duration) numericStart,numericDuration=start,duration end
now = 103
equal(R.SetSchoolInterruptClock(cooldown, p), true, "remaining-only clock uses unchanged observed deadline")
equal(numericStart + numericDuration, 104.5, "no countdown extension after delayed render")
now = 105
equal(R.SetSchoolInterruptClock(cooldown, p), false, "expired record cannot restart a clock")
now = 102
sealed.timeRemaining = 0
equal(R.GetSchoolInterrupt("party2"), nil, "zero remaining proves expiry")

api({target={{locType="STUN", spellID=1766, iconTexture=12},
    {locType="SILENCE", spellID=2139, iconTexture=15},
    {locType=SECRET, spellID=1766, iconTexture=12},
    {locType="SCHOOL_INTERRUPT", spellID=SECRET, iconTexture=12},
    {locType="SCHOOL_INTERRUPT", spellID=1.25, iconTexture=12},
    {locType="SCHOOL_INTERRUPT", spellID=9999, iconTexture=SECRET},
    {locType="SCHOOL_INTERRUPT", spellID=9999, iconTexture=12, startTime=90, duration=3},
    SECRET, setmetatable({}, {__index=function() error("denied row") end})}})
-- A cast stop, channel end, or naked interrupt cast has no recipient-side LoC
-- record. Neither cast identity nor a simultaneous different LoC is sufficient.
UnitCastingInfo = function() error("cast events cannot prove school lockout") end
equal(R.GetSchoolInterrupt("target"), nil, "only explicitly identified active school lockouts count")
equal(durationCalls, 0, "ambiguous rows never claim a native clock")
rows.target[#rows.target+1] = landed(6552,100)
equal(R.GetSchoolInterrupt("target").spellID, 6552, "unreadable peer does not erase independent positive")
equal(R.GetSchoolInterrupt(SECRET), nil, "secret unit cannot be indexed")

api({player={{locType="SCHOOL_INTERRUPT", spellID=2139, iconTexture=42}}})
local playerCalls = 0
C_LossOfControl.GetActiveLossOfControlDataCount = function() playerCalls=playerCalls+1; return 1 end
C_LossOfControl.GetActiveLossOfControlData = function() return landed(72,100) end
equal(R.GetSchoolInterrupt("focus"), nil, "a hostile focus cannot inherit player-only evidence")
equal(playerCalls, 0, "player-only reader never called for focus")
equal(R.GetSchoolInterrupt("player").spellID, 72, "player-specific list serves player")
UnitIsUnit = function(unit, other) return unit == "target" and other == "player" end
equal(R.GetSchoolInterrupt("target").spellID, 72, "positively verified player alias may use player source")
rows.player={}
equal(R.GetSchoolInterrupt("target").spellID, 72, "player-only positive still resolves a clock without a conflicting row")
equal(durationUnit, "player", "alias takes native duration from the record's actual source")
rows.player={{locType="SCHOOL_INTERRUPT", spellID=2139, iconTexture=42}}
UnitIsUnit = function() return SECRET end
equal(R.GetSchoolInterrupt("target"), nil, "unreadable alias cannot take player's interrupt")
local identityChecks = 0
UnitIsUnit = function() identityChecks=identityChecks+1; return identityChecks == 1 end
equal(R.GetSchoolInterrupt("target"), nil, "formerly proven alias is rechecked before player evidence returns")
UnitIsUnit = nil
C_LossOfControl.GetActiveLossOfControlData = function() return SECRET end
equal(R.GetSchoolInterrupt("player").spellID, 2139, "positive same-player by-unit alternative")
C_LossOfControl.GetActiveLossOfControlDataCountByUnit = function() return math.huge end
equal(R.GetSchoolInterrupt("player"), nil, "nonfinite count cannot authorize iteration")
C_LossOfControl = nil
equal(R.GetSchoolInterrupt("target"), nil, "unavailable API")

api({target={{locType="STUN",spellID=72}}})
local a,b,known = R.GetSchoolInterrupt("target")
equal(a,nil,"unrelated positive");equal(known,true,"fully readable negative")
rows.target={SECRET}
a,b,known=R.GetSchoolInterrupt("target")
equal(a,nil,"no fabricated candidate");equal(known,false,"inaccessible row is unresolved")
rows.target={SECRET,landed(72,101)}
a,b,known=R.GetSchoolInterrupt("target")
equal(a.spellID,72,"independent positive");equal(known,false,"unknown sibling retained")
rows.target={landed(2139,99),landed(72,100),landed(72,101)}
local playerRow=landed(1766,101)
C_LossOfControl.GetActiveLossOfControlDataCount=function()return 1 end
C_LossOfControl.GetActiveLossOfControlData=function()return playerRow end
UnitIsUnit=function(a,b)return a=="target" and b=="player" end
a,b,known=R.GetSchoolInterrupt("target")
equal(a.spellID,72,"current direct positive retained")
equal(b.spellID,1766,"self alias includes a distinct player-only lockout ahead of old Counterspell")
UnitIsUnit=function()return false end
a,b=R.GetSchoolInterrupt("target")
equal(b.spellID,2139,"foreign target cannot borrow player lockout")
local other=landed(19647,99);other.auraInstanceID=11
local linked=landed(2139,101);linked.auraInstanceID=11
rows.target={other,linked,landed(6552,98)}
a,b=R.GetSchoolInterrupt("target")
equal(a.spellID,2139,"best of linked spells")
equal(b.spellID,6552,"runner must be distinct from the same linked occurrence")
api({player={{locType="SCHOOL_INTERRUPT",spellID=6552,iconTexture=13,clock=OPAQUE}}})
C_LossOfControl.GetActiveLossOfControlDataCount=function()return 1 end
C_LossOfControl.GetActiveLossOfControlData=function()return landed(72,100) end
a,b=R.GetSchoolInterrupt("player")
equal(a.spellID,72,"player-only school spell");equal(b.spellID,6552,"by-unit player's distinct spell")
equal(a.durationObject,nil,"contradictory player index cannot transport a clock for the wrong effect")
equal(b.durationObject,nil,"one ambiguous native index cannot supply two different clocks")
equal(a.expires,105,"the independently observed numeric clock survives index ambiguity")

local directCopy={locType="SCHOOL_INTERRUPT",spellID=1766,iconTexture=123,auraInstanceID=22}
local playerCopy={locType="SCHOOL_INTERRUPT",spellID=1766,iconTexture=123,auraInstanceID=22,clock=OPAQUE}
api({target={directCopy},player={playerCopy}})
C_LossOfControl.GetActiveLossOfControlDataCount=function()return 1 end
C_LossOfControl.GetActiveLossOfControlData=function()return playerCopy end
UnitIsUnit=function(unit,other)return unit=="target" and other=="player" end
a=R.GetSchoolInterrupt("target")
equal(a.expires,nil,"duplicate observation never invents an expiry")
equal(a.durationObject,OPAQUE,"matched player copy supplies an opaque clock for a confirmed self target")
equal(durationCalls,2,"one probe for each distinct victim token/index")
playerCopy.clock=nil;durationCalls=0
equal(R.GetSchoolInterrupt("target").durationObject,nil,"two genuine sources can both lack a clock")
equal(durationCalls,2,"two player interfaces sharing an unsuccessful index do not probe twice")
playerCopy.clock=OPAQUE;playerCopy.auraInstanceID=11
equal(R.GetSchoolInterrupt("target").durationObject,nil,"another instance of the same spell cannot lend its clock")
playerCopy.auraInstanceID=22;directCopy.startTime=101;playerCopy.startTime=100
equal(R.GetSchoolInterrupt("target").durationObject,nil,"contradictory application times veto a shared instance")
directCopy.auraInstanceID=nil;playerCopy.auraInstanceID=nil;playerCopy.startTime=101
equal(R.GetSchoolInterrupt("target").durationObject,OPAQUE,"same public spell and application can corroborate a clock")
directCopy.lockoutSchool=4;playerCopy.lockoutSchool=16
equal(R.GetSchoolInterrupt("target").durationObject,nil,"contradictory public school masks distinguish simultaneous locks")
directCopy.lockoutSchool=nil;playerCopy.lockoutSchool=nil
directCopy.startTime=nil;playerCopy.startTime=nil
equal(R.GetSchoolInterrupt("target").durationObject,nil,"a spell ID by itself cannot link two opaque occurrences")
directCopy.auraInstanceID=22;playerCopy.auraInstanceID=22
UnitIsUnit=function()return SECRET end
equal(R.GetSchoolInterrupt("target").durationObject,nil,"unproven self cannot obtain a player duration")
local stillSelf=true
UnitIsUnit=function()return stillSelf end
local nativeDuration=C_LossOfControl.GetActiveLossOfControlDuration
C_LossOfControl.GetActiveLossOfControlDuration=function(unit,index)
    if unit=="player" then stillSelf=false end
    return nativeDuration(unit,index)
end
equal(R.GetSchoolInterrupt("target"),nil,"rebind during alternate clock acquisition revokes the whole observation")

local target={locType="SCHOOL_INTERRUPT",spellID=1766,iconTexture=22,auraInstanceID=22,startTime=100}
local player={locType="SCHOOL_INTERRUPT",spellID=1766,iconTexture=22,startTime=100,duration=5}
api({target={target},player={player}})
UnitIsUnit=function(u,v)return u=="target" and v=="player" end
C_LossOfControl.GetActiveLossOfControlDuration=nil
a=R.GetSchoolInterrupt("target")
equal(a.auraInstanceID,22,"elected alias retains its stronger identity")
equal(a.expires,105,"matching application corroborates a numeric expiry without a duration object")
equal(a.duration,5,"corroborated numeric interval")
player.startTime=99
equal(R.GetSchoolInterrupt("target").expires,nil,"conflicting application cannot donate timing")
player.startTime=nil;player.auraInstanceID=22
equal(R.GetSchoolInterrupt("target").expires,105,"one confirmed instance can join public start and public duration")
rows.player[2]={locType="SCHOOL_INTERRUPT",spellID=1766,iconTexture=22,duration=8,auraInstanceID=22}
equal(R.GetSchoolInterrupt("target").expires,nil,"contradictory corroborating durations cannot supply a synthetic interval")
UnitIsUnit=function()return false end
equal(R.GetSchoolInterrupt("target").expires,nil,"foreign timer remains isolated")

api({player={{locType="SCHOOL_INTERRUPT",spellID=1766,iconTexture=22,startTime=100,duration=8,clock=OPAQUE}}})
C_LossOfControl.GetActiveLossOfControlDataCount=function()return 1 end
C_LossOfControl.GetActiveLossOfControlData=function()return landed(1766,100) end
a=R.GetSchoolInterrupt("player")
equal(a.expires,108,"chosen public interval retained")
equal(a.durationObject,nil,"contradictory public duration at a shared index vetoes the opaque handle")
local numeric
R.SetSchoolInterruptClock({SetCooldown=function(_,start,duration)numeric=duration end},a)
equal(numeric,8,"native display uses the actual elected numeric interval")
C_LossOfControl.GetActiveLossOfControlData=function()return {locType="SCHOOL_INTERRUPT",spellID=1766,
    iconTexture=22,timeRemaining=3} end
equal(R.GetSchoolInterrupt("player").durationObject,nil,"contradictory remaining time also vetoes a crossed native index")
C_LossOfControl.GetActiveLossOfControlData=function()return {locType="SCHOOL_INTERRUPT",spellID=1766,
    iconTexture=22,startTime=100,duration=8} end
equal(R.GetSchoolInterrupt("player").durationObject,OPAQUE,"matching native interval remains transportable")

C_LossOfControl=setmetatable({}, {__index=function()error("sealed API member")end})
a,b,known=R.GetSchoolInterrupt("target")
equal(known,false,"an unavailable getter is not an enumerated empty snapshot")

local clearCount=0
cooldown.Clear=function()clearCount=clearCount+1 end
cooldown.SetCooldownFromDurationObject=function()return false end
local accepted,timed=R.SetSchoolInterruptClock(cooldown,{spellID=72,durationObject=OPAQUE})
equal(accepted,true,"rejected native clock still permits cleared art")
equal(timed,false,"no digits claimed for a declined clock");equal(clearCount,1,"stale countdown cleared")

-- A split public deadline is a real expiry even if native removal lags.
local split={locType="SCHOOL_INTERRUPT",spellID=1766,iconTexture=22,auraInstanceID=22,startTime=100}
local timing={locType="SCHOOL_INTERRUPT",spellID=1766,iconTexture=22,auraInstanceID=22,duration=4}
local remaining=landed(6552,99);remaining.duration=9
api({target={split,remaining},player={timing}})
UnitIsUnit=function(u,v)return u=="target" and v=="player" end
now=101;a,b=R.GetSchoolInterrupt("target");equal(a.expires,104,"certified split deadline")
now=104;a,b=R.GetSchoolInterrupt("target")
equal(a.spellID,6552,"expired partial cannot outrank the genuine living lock");equal(b,nil,"expired sparse copies suppressed")
split.duration=4
a,b=R.GetSchoolInterrupt("target")
equal(a.spellID,6552,"explicit expired identity also retires its sparse copy")
timing.auraInstanceID=33
a,b=R.GetSchoolInterrupt("target")
equal(b.spellID,1766,"another occurrence of same spell is not retired")

now=101;split.duration=nil;timing.auraInstanceID=22;timing.duration=nil;timing.lockoutSchool=16
local differentSchool=landed(1766,100);differentSchool.lockoutSchool=4;differentSchool.clock=OPAQUE
C_LossOfControl.GetActiveLossOfControlDataCount=function()return 1 end
C_LossOfControl.GetActiveLossOfControlData=function()return differentSchool end
a=R.GetSchoolInterrupt("target")
equal(a.expires,nil,"different schools cannot corroborate through a partial third record")
timing.lockoutSchool=4
equal(R.GetSchoolInterrupt("target").expires,105,"agreeing witnesses can supply the same interval")
timing.lockoutSchool=16;differentSchool.lockoutSchool=4;split.lockoutSchool=nil
C_LossOfControl.GetActiveLossOfControlDuration=function(unit)if unit=="player" then return OPAQUE end end
equal(R.GetSchoolInterrupt("target").durationObject,nil,"contradictory witnesses cannot lend an opaque handle")
split.auraInstanceID=nil;split.lockoutSchool=4
differentSchool.auraInstanceID=11;differentSchool.iconTexture=nil
timing.startTime=100;timing.auraInstanceID=22;timing.lockoutSchool=4;timing.iconTexture=nil
C_Spell.GetSpellTexture=function()return nil end
a=R.GetSchoolInterrupt("target")
equal(a.expires,nil,"mutually contradictory instance IDs cannot corroborate through a sparse common start")
equal(a.durationObject,nil,"incompatible occurrence IDs do not lend an opaque handle")
timing.auraInstanceID=11
equal(R.GetSchoolInterrupt("target").expires,105,"agreeing instance IDs restore corroboration")

local function nativeRow(spell,instance,start,duration,school,icon)
    return {locType="SCHOOL_INTERRUPT",spellID=spell,auraInstanceID=instance,startTime=start,
        duration=duration,lockoutSchool=school,iconTexture=icon}
end
now=101
local source=nativeRow(1766,22,100,nil,4,22)
local other=nativeRow(1766,nil,nil,10,4,22)
local donor=nativeRow(1766,22,nil,4,4,22)
api({player={source}});source.clock=OPAQUE
C_LossOfControl.GetActiveLossOfControlDataCount=function()return 2 end
C_LossOfControl.GetActiveLossOfControlData=function(i)return i==1 and other or donor end
a=R.GetSchoolInterrupt("player")
equal(a.duration,4,"public duration assembled at selected index")
equal(a.durationObject,nil,"native candidate is validated against the complete elected witness")
-- The target copy already knows the interval. The optional player index
-- lacks it and faces a different, positively timed row across its two views.
api({target={nativeRow(1766,22,100,4,4,22)},player={source}})
source.clock=OPAQUE
C_LossOfControl.GetActiveLossOfControlDataCount=function()return 1 end
C_LossOfControl.GetActiveLossOfControlData=function()return other end
a=R.GetSchoolInterrupt("target");equal(a.durationObject,nil,"alternate index must honor the full elected interval")
other.duration=4;equal(R.GetSchoolInterrupt("target").durationObject,OPAQUE,"corroborated alternate index can transport its clock")

now=105
local old=nativeRow(1766,22,100,nil,nil,7)
local expired=nativeRow(1766,22,100,4,16,7)
local live=nativeRow(1766,nil,100,8,4,9)
api({target={old},player={live}})
C_LossOfControl.GetActiveLossOfControlDataCount=function()return 1 end
C_LossOfControl.GetActiveLossOfControlData=function()return expired end
a=R.GetSchoolInterrupt("target")
equal(a.icon,9,"an expired exact instance cannot defeat the living weakly linked spell")
equal(a.expires,108,"independent live occurrence keeps its observed end")
old.duration=7
a=R.GetSchoolInterrupt("target")
equal(a.auraInstanceID,22,"equally specific current timing is not erased by a conflicting exact expiry")
equal(a.expires,107,"independently readable renewed interval remains available")

now=101
local base=nativeRow(1766,nil,100,5,nil,9)
local rich=nativeRow(1766,22,100,5,4,nil)
local linked=nativeRow(18425,22,99,5,4,12)
api({target={base,linked,nativeRow(6552,33,98,9,16,13)},player={rich}})
C_Spell.GetSpellTexture=function()return nil end
a,b=R.GetSchoolInterrupt("target")
equal(a.auraInstanceID,22,"unique corroborated occurrence carried into election");equal(a.lockoutSchool,4,"corroborated school")
equal(a.requiresPlayer,true,"borrowed identity requires its victim alias");equal(b.spellID,6552,"same occurrence is not ranked twice")
local f=nativeRow(1766,nil,nil,nil,4,22);local g=nativeRow(1766,nil,nil,nil,16,22)
api({target={f,g}});UnitIsUnit=function(x,y)return x==y end;f.clock={};g.clock={}
a=R.GetSchoolInterrupt("target");rows.target={g,f}
equal(R.GetSchoolInterrupt("target").durationObject,a.durationObject,"a reorder of distinct untimed schools keeps the same clock")

now=105
local sparse=nativeRow(1766,nil,100,nil,nil,9)
local bridge=nativeRow(1766,22,100,nil,nil,nil)
local exact=nativeRow(1766,22,nil,nil,nil,nil);exact.timeRemaining=0
api({target={sparse,nativeRow(6552,33,98,20,16,13)},player={bridge,exact}})
C_Spell.GetSpellTexture=function()return nil end
UnitIsUnit=function(u,v)return u=="target" and v=="player" end
local completeSnapshot,unresolvedSelf,neg
a,b,completeSnapshot,unresolvedSelf,neg=R.GetSchoolInterrupt("target")
equal(unresolvedSelf,false,"the self link was positively verified")
equal(a.spellID,6552,"a uniquely learned instance carries its exact expiry before election")
equal(b,nil,"the elapsed linked lock cannot return as untimed runner");equal(neg,true,"excluding rank retains self provenance")
rows.player={exact,bridge};equal(R.GetSchoolInterrupt("target").spellID,6552,"witness order independent")
exact.auraInstanceID=44
a=R.GetSchoolInterrupt("target");equal(a.spellID,1766,"expiry of a different instance cannot propagate")
equal(a.expires,nil,"no borrowed deadline for unrelated occurrence")
exact.auraInstanceID=22;exact.timeRemaining=nil;exact.duration=8
a=R.GetSchoolInterrupt("target");equal(a.expires,108,"unique instance contributes its live public duration")
equal(a.requiresPlayer,true,"player-supplied numeric witness is conditional")
exact.duration=nil;exact.clock=OPAQUE
equal(R.GetSchoolInterrupt("target").durationObject,OPAQUE,"a clock at the corroborated exact instance may be used")
UnitIsUnit=function()return false end
a=R.GetSchoolInterrupt("target");equal(a.expires,nil,"ordinary target keeps only its own interval")
equal(a.durationObject,nil,"former-self target never borrows the old handle")
-- Discovering a start through an exact ID does not authorize arbitrary
-- start-only clocks that were never checked against the elected interval.
local noStart=nativeRow(1766,22,nil,4,nil,9)
local weak=nativeRow(1766,nil,100,10,nil,nil);weak.clock=OPAQUE
api({target={noStart},player={bridge,weak}});C_Spell.GetSpellTexture=function()return nil end
UnitIsUnit=function(u,v)return u=="target" and v=="player" end
now=101;a=R.GetSchoolInterrupt("target")
equal(a.expires,104,"exact bridge supplies the missing start")
equal(a.durationObject,nil,"an unchecked start-only row cannot override the exact numeric interval")
print("interrupt evidence tests passed")
