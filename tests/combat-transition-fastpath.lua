-- Combat transition fast path uses the production Main.lua dispatch; no WoW client.
-- Assert that PLAYER_REGEN_ENABLED and target UNIT_FLAGS don't schedule a
-- global native forced-aura rebuild when the native container states are stable.
-- Real aura/binding/faction events must retain a way to request forced recovery.
local _, callbacks = {}, {}
local frames = {}
CreateFrame=function()
    local f={events={}}
    function f:RegisterEvent(ev) self.events[ev]=true end
    function f:RegisterUnitEvent(ev,...) self.events[ev]={...} end
    function f:SetScript(_,fn) self.callback=fn end
    frames[#frames+1]=f
    return f
end
local combat=true
InCombatLockdown=function()return combat end
local timeQueue={}
C_Timer={After=function(_,cb)timeQueue[#timeQueue+1]=cb end}
local updates,global,styled={},{},{}
local relations={target=true,focus=false}
local assist={target=false,focus=true}
UnitCanAssist=function(_,unit) return assist[unit] end
UnitIsUnit=function()return false end
local R={db={enabled=true},PARTY_UNITS={},TRACKED_UNITS={"player","target","focus"},
    hosts={target={_hostileRelationReadable=true,_hostileUnit=true,_assistReadable=true,_assistable=false},
           focus={_hostileRelationReadable=true,_hostileUnit=false,_assistReadable=true,_assistable=true}}}
R.CanAccess=function()return true end
R.SafeBool=function(fn,...)local ok,v=pcall(fn,...);return v,ok and type(v)=="boolean" end
R.HostileUnitState=function(unit)return relations[unit],relations[unit]~=nil end
R.Refresh=function(unit,force,binding)
    updates[#updates+1]={unit=unit,force=force==true,binding=binding==true}
end
R.RefreshAll=function(force,follow)
    global[#global+1]={force=force==true,follow=follow==true}
end
R.ApplyPresentation=function(unit,...)styled[#styled+1]=unit or "all" end
R.RetryCountdownFormatter=function()end
R.UpdateObservedPetPortraits=function()end
R.UpdateObservedPetPortrait=function()end
R.IsUnitEnabled=function()return true end
R.BuildAll=function()end
R.UpdatePetPortraits=function()end
assert(loadfile("Main.lua"))("bjarkiPortraits",{Runtime=R})
local function eq(a,b,msg)assert(a==b,(msg or "mismatch")..": "..tostring(a).." vs "..tostring(b))end
local function fire(ev,unit)
    for _,f in ipairs(frames)do
        local allowed=f.events[ev]
        if allowed==true then f.callback(f,ev,unit)
        elseif type(allowed)=="table" then
            for _,candidate in ipairs(allowed)do
                if candidate==unit then f.callback(f,ev,unit);break end
            end
        end
    end
end
local function flush()
    local limit=0
    while #timeQueue>0 do
        limit=limit+1;assert(limit<30,"event queue must be finite")
        table.remove(timeQueue,1)()
    end
end
fire("UNIT_FLAGS","player")
eq(#global,0,"combat player flags never force global refresh")
eq(#updates,1,"player flags refresh only one owner")
eq(updates[1].unit,"player");eq(updates[1].force,false,"player flags non-forced")
fire("UNIT_FLAGS","target")
eq(updates[#updates].force,false,"target flags immediate non-forced")
flush()
eq(updates[#updates].force,false,"target flags deferred non-forced")
local n=#updates
fire("UNIT_FLAGS","target")
fire("UNIT_FACTION","target")
flush()
eq(updates[#updates].unit,"target","coalesced target remains target")
eq(updates[#updates].force,true,"later faction event upgrades queued flags")
assert(#updates>n)
-- Player faction is a real relationship change: retain global force.
fire("UNIT_FACTION","player")
eq(global[#global].force,true,"player faction retains full force")
flush()
-- Combat exit should re-evaluate eligibility and pending container writes
-- without forcing a native aura rebuild of every unchanged host.
combat=false
fire("PLAYER_REGEN_ENABLED")
eq(global[#global].force,false,"normal combat exit does not force all native aura groups")
eq(global[#global].follow,true,"combat exit retains presentation reconciliation")
eq(styled[#styled],"all","post-combat presentation is retained")
eq(R.db.enabled,true)
print("combat transition fastpath: passed")
