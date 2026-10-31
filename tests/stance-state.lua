-- Ordinary Lua WoW boundary model: real resolver, UpdateHost, events and slash.
-- These tests cannot prove the live client exposes hidden stance AuraData.
local function eq(actual, expected, label)
    assert(actual == expected, (label or "value") .. ": wanted " .. tostring(expected) .. ", got " .. tostring(actual))
end
local function loadAddon(name, bp) return assert(loadfile(name .. ".lua"))("bjarkiPortraits", bp) end
local SECRET = setmetatable({}, {__tostring=function() error("secret printed") end})
local units = {"player", "target", "focus", "targettarget", "focustarget"}
local function frame()
    local f={shown=false, level=190}
    f.icon={SetTexture=function(_, value) f.texture=value; return true end}
    f.cooldown={Clear=function(self) self.duration=nil end,
        SetCooldown=function(self, _, duration) self.duration=duration end}
    function f:Show() self.shown=true end
    function f:Hide() self.shown=false end
    function f:SetFrameLevel(level) self.level=level end
    return f
end
local function setup(unsupported)
    BjarkiPortraitsDB=nil; SlashCmdList={}
    PlayerFrame,TargetFrame,FocusFrame=nil,nil,nil
    TargetFrameToT,FocusFrameToT=nil,nil
    local s={classes={player="WARRIOR"}, aliases={}, dead={}, exists={}, players={},
        auras={}, helpful={}, forms={{active=true,id=2457}}, timers={}, frames={}, messages={}, queries={}, formCalls=0}
    issecretvalue=function(v) return v==SECRET end
    canaccessvalue=function(v) return v~=SECRET end
    UnitExists=function(unit) if s.exists[unit]~=nil then return s.exists[unit] end return true end
    UnitIsPlayer=function(unit) if s.players[unit]~=nil then return s.players[unit] end return true end
    UnitGUID=nil
    UnitIsUnit=function(unit, other) eq(other,"player","self comparison"); return s.aliases[unit] or false end
    UnitClass=function(unit) return "localized", s.classes[unit] or "WARRIOR" end
    UnitIsDeadOrGhost=function(unit) return s.dead[unit] or false end
    UnitIsGhost=function() return false end
    UnitCanAssist=function(_,unit) return unit=="player" or s.aliases[unit]==true end
    UnitCanAttack=function() return true end
    UnitIsPlayerControlledOrGroupMember=function() return false end
    UnitPowerType=function() return 1,"RAGE" end
    InCombatLockdown=function() return false end
    C_Spell={GetSpellTexture=function(id) return id+100000 end}
    GetNumShapeshiftForms=function(...) eq(select('#',...),0,"own count has no unit"); s.formCalls=s.formCalls+1; return #s.forms end
    GetShapeshiftFormInfo=function(index, ...)
        eq(select('#',...),0,"own info has no unit"); s.formCalls=s.formCalls+1
        local f=s.forms[index]; return 999,f.active,true,f.id
    end
    C_UnitAuras={GetUnitAuraBySpellID=function(unit,id)
        s.queries[#s.queries+1]={unit,id}
        local value=s.auras[unit] and s.auras[unit][id]
        if value=="error" then error(SECRET) end
        return value
    end, GetAuraDataByIndex=function(unit,index,filter)
        if filter:find("HARMFUL",1,true) then return nil end
        return s.helpful[index]
    end}
    C_Timer={After=function(delay,fn) eq(delay,0); s.timers[#s.timers+1]=fn end}
    DEFAULT_CHAT_FRAME={AddMessage=function(_,message) s.messages[#s.messages+1]=message end}
    CreateFrame=function()
        local f={events={}}
        function f:RegisterEvent(event)
            if unsupported and unsupported[event] then error("unsupported") end
            self.events[event]=true
        end
        function f:RegisterUnitEvent(event,a,b)
            if unsupported and unsupported[event] then error("unsupported") end
            self.events[event]={[a]=true}; if b then self.events[event][b]=true end
        end
        function f:SetScript(_,callback) self.callback=callback end
        s.frames[#s.frames+1]=f; return f
    end
    local bp={}
    for _,name in ipairs({"Spells","Core"}) do loadAddon(name,bp) end
    -- Missing production feature is asserted explicitly, not a loadfile error.
    local module=io.open("StanceState.lua","r")
    if module then module:close(); loadAddon("StanceState",bp) end
    for _,name in ipairs({"Priority","AuraEngine","PetPortraits","Commands","Main"}) do loadAddon(name,bp) end
    s.R=bp.Runtime; s.R.ApplyDefaults()
    for _,unit in ipairs(units) do
        local h={unit=unit,unitFrame={unit=unit},smallBaseLevel=40,_buildComplete=true,containers={},cooldowns={}}
        for _,key in ipairs({"Hostile","Baseline","Healing","WelcomingCampfire","NearbyHarmful","Stun",
            "InterruptSilence","Wounds","StatusEffects","ResurrectionSickness","DoTs","FormState","Dazed",
            "Demoralizing","BaselineHarmful","Slows","Forbearance","OffensiveHarmful","WaitingToResurrect",
            "Ghost","DivineProtection"}) do h["readable"..key.."Frame"]=frame() end
        for i,tier in ipairs(s.R.TIERS) do
            h.containers[i]={tier=tier,SetEnabled=function(self,v) self.enabled=v end,
                SetShown=function(self,v) self.shown=v end,IsEnabled=function(self) return self.enabled end,
                UpdateAllAuras=function() end}
        end
        h.portrait={}; h.portraitMask={}
        h.unitFrame.Portrait=h.portrait; h.unitFrame.PortraitMask=h.portraitMask
        if unit=="player" then h.unitFrame.PlayerFrameContainer={PlayerPortrait=h.portrait,PlayerPortraitMask=h.portraitMask}
        elseif unit=="target" or unit=="focus" then h.unitFrame.TargetFrameContainer={Portrait=h.portrait,PortraitMask=h.portraitMask} end
        s.R.hosts[unit]=h
        if unit=="player" then PlayerFrame=h.unitFrame
        elseif unit=="target" then TargetFrame=h.unitFrame
        elseif unit=="focus" then FocusFrame=h.unitFrame
        elseif unit=="targettarget" then TargetFrameToT=h.unitFrame
        else FocusFrameToT=h.unitFrame end
    end
    function s:stanceQueries()
        local count=0
        for _,q in ipairs(self.queries) do if q[2]==2457 or q[2]==71 or q[2]==2458 then count=count+1 end end
        return count
    end
    function s:resolve(unit)
        assert(type(self.R.ResolveWarriorStance)=="function","Warrior stance resolver must exist")
        return self.R.ResolveWarriorStance(unit or "target")
    end
    function s:show(unit,id)
        local h=self.R.hosts[unit]; self.R.UpdateHost(h)
        eq(h._formStateSpellID,id,"current stance identity")
        eq(h._formStateActive,id~=nil,"current stance active")
        eq(h.readableFormStateFrame.shown,id~=nil,"current stance visible")
        return h
    end
    function s:fire(event,unit)
        for _,f in ipairs(self.frames) do
            local r=f.events[event]
            if r==true or (type(r)=="table" and r[unit]) then f.callback(f,event,unit) end
        end
    end
    function s:drain()
        local pending=self.timers; self.timers={}
        for _,fn in ipairs(pending) do fn() end
        eq(#self.timers,0,"no self polling")
    end
    return s
end
local function aura(id) return {spellId=id,isHelpful=true,icon=id+200000,auraInstanceID=1,duration=20,expirationTime=100,timeMod=1} end
local cases,failures=0,{}
local function test(name,body)
    cases=cases+1; local ok,err=pcall(body)
    if ok then print("PASS "..name) else failures[#failures+1]=name..": "..tostring(err); print("FAIL "..failures[#failures]) end
end
-- Break caught: missing resolver, positional assumptions, or player state leakage.
for _,id in ipairs({2457,71,2458}) do
    test("own stance "..id.." uses active ID across all self aliases",function()
        local s=setup(); s.forms={{active=false,id=18499},{active=true,id=id}}
        for _,unit in ipairs(units) do
            s.aliases[unit]=true
            local result=s:resolve(unit); eq(result.spellID,id); eq(result.source,"player-forms")
            s:show(unit,id)
        end
        eq(s:stanceQueries(),0,"own stances need no observed probes")
    end)
    test("Druid observer resolves exact current Warrior stance "..id.." on each nonself host",function()
        local s=setup(); s.classes.player="DRUID"; s.forms={{active=true,id=2457}}
        for _,unit in ipairs({"target","focus","targettarget","focustarget"}) do
            s.auras[unit]={[id]=aura(id)}
            local result=s:resolve(unit); eq(result.spellID,id); eq(result.source,"unit-aura")
            s:show(unit,id)
        end
        eq(s.formCalls,0,"other Warrior cannot borrow local form")
    end)
end
for _,fixture in ipairs({
    {name="no aura is unknown",auras={},reason="no-values"},
    {name="ambiguous two stances",auras={[2457]=aura(2457),[71]=aura(71)},reason="ambiguous"},
    {name="Berserker Rage is not stance",auras={[2457]=aura(18499)},reason="invalid-aura"},
    {name="mismatched helpful flag",auras={[71]={spellId=71,isHelpful=false}},reason="invalid-aura"},
    {name="missing helpful flag",auras={[71]={spellId=71}},reason="invalid-aura"},
    {name="non table aura",auras={[71]=71},reason="invalid-aura"},
    {name="secret aura",auras={[71]=SECRET},reason="unreadable"},
    {name="secret ID",auras={[71]={spellId=SECRET,isHelpful=true}},reason="unreadable"},
    {name="secret helpful",auras={[71]={spellId=71,isHelpful=SECRET}},reason="unreadable"},
    {name="query error beside positive",auras={[2457]="error",[71]=aura(71)},reason="api-error"},
}) do
    test(fixture.name,function()
        local s=setup(); s.auras.target=fixture.auras
        local r=s:resolve(); eq(r.spellID,nil); eq(r.reason,fixture.reason); eq(#s.queries,3,"three bounded exact queries")
        s:show("target",nil); eq(s.formCalls,0)
    end)
end
test("unavailable aura API never defaults to local Battle",function()
    local s=setup(); C_UnitAuras.GetUnitAuraBySpellID=nil
    eq(s:resolve().reason,"api-unavailable"); s:show("target",nil); eq(s.formCalls,0)
end)
for _,mode in ipairs({"count-error","count-secret","count-malformed","count-bounded","info-error","info-secret-active","info-nonboolean","info-secret-id","unsupported","multiple","none"}) do
    test("own malformed forms fail closed: "..mode,function()
        local s=setup()
        if mode=="count-error" then GetNumShapeshiftForms=function() error(SECRET) end
        elseif mode=="count-secret" then GetNumShapeshiftForms=function() return SECRET end
        elseif mode=="count-malformed" then GetNumShapeshiftForms=function() return 1.5 end
        elseif mode=="count-bounded" then GetNumShapeshiftForms=function() return 500 end
        elseif mode=="info-error" then GetShapeshiftFormInfo=function() error(SECRET) end
        elseif mode=="info-secret-active" then s.forms[1].active=SECRET
        elseif mode=="info-nonboolean" then s.forms[1].active=1
        elseif mode=="info-secret-id" then s.forms[1].id=SECRET
        elseif mode=="unsupported" then s.forms[1].id=18499
        elseif mode=="multiple" then s.forms[2]={id=71,active=true}
        elseif mode=="none" then s.forms[1].active=false end
        eq(s:resolve("player").spellID,nil); s:show("player",nil); eq(s:stanceQueries(),0,"failed own API cannot become observed proof")
    end)
end
test("unavailable own forms fail closed",function()
    local s=setup(); GetNumShapeshiftForms=nil; eq(s:resolve("player").spellID,nil)
    GetShapeshiftFormInfo=nil; s:show("player",nil)
end)
-- Break caught: truth testing identity, death or class without guarded access.
for _,mode in ipairs({"absent","secret-exists","not-player","secret-player","dead","secret-dead","not-warrior","secret-class","unsupported-token"}) do
    test("eligibility rejects "..mode,function()
        local s=setup(); s.auras.target={[71]=aura(71)}; local unit="target"
        if mode=="absent" then s.exists.target=false
        elseif mode=="secret-exists" then s.exists.target=SECRET
        elseif mode=="not-player" then s.players.target=false
        elseif mode=="secret-player" then s.players.target=SECRET
        elseif mode=="dead" then s.dead.target=true
        elseif mode=="secret-dead" then s.dead.target=SECRET
        elseif mode=="not-warrior" then s.classes.target="DRUID"
        elseif mode=="secret-class" then s.classes.target=SECRET
        elseif mode=="unsupported-token" then unit="party1" end
        eq(s:resolve(unit).spellID,nil); eq(#s.queries,0,"ineligible cannot probe")
    end)
end
test("unproven self identity uses only observed unit",function()
    local s=setup(); s.aliases.target=SECRET; s.auras.target={[71]=aura(71)}
    eq(s:resolve().spellID,71); eq(s.formCalls,0)
end)
test("static lane clears clocks and survives unrelated low helpful witness",function()
    local s=setup(); s.auras.target={[71]=aura(71)}
    s.helpful={{spellId=2383,auraInstanceID=2,icon=123,duration=0,expirationTime=0}}
    local h=s.R.hosts.target; h.readableFormStateFrame.cooldown.duration=99
    s:show("target",71); eq(h.readableFormStateFrame.cooldown.duration,nil,"no fabricated countdown")
    eq(h.readableFormStateFrame.level,190,"existing below SelfState level")
    for _,c in ipairs(h.containers) do if c.tier.key=="SelfState" then eq(c.enabled,false,"hostile native self state remains permission gated") end end
end)
test("current host rebind death disable and test mode revoke stance",function()
    local s=setup(); s.auras.target={[71]=aura(71)}; s:show("target",71)
    s.auras.target={[2458]=aura(2458)}; s:show("target",2458)
    s.dead.target=true; s:show("target",nil); s.dead.target=false
    s.R.db.target=false; s:show("target",nil); s.R.db.target=true
    s.R.testMode=true; s:show("target",nil); s.R.testMode=false
    s.R.hosts.player.unitFrame.unit="vehicle"; s:show("player",nil)
end)
test("native higher lanes retain priority and eligibility",function()
    local s=setup(); s.aliases.target=true; s:show("target",2457)
    local h=s.R.hosts.target; local seen={}
    for _,c in ipairs(h.containers) do
        if c.tier.key=="SelfState" or c.tier.key=="Immunity" then seen[c.tier.key]=true; eq(c.enabled,true,"native higher tier remains enabled"); assert(c.tier.level+41>h.readableFormStateFrame.level) end
    end
    eq(seen.SelfState,true); eq(seen.Immunity,true)
end)
test("hostile Druid Cat Bear fallback remains unchanged",function()
    local s=setup(); s.classes.target="DRUID"
    UnitPowerType=function() return 3,"ENERGY" end; s:show("target",768)
    UnitPowerType=function() return 1,"RAGE" end; s:show("target",5487)
    UnitPowerType=function() return 0,"MANA" end; s:show("target",nil)
end)
-- Break caught: missing native event route or stale captured alias after rebind.
test("UNIT_FORM_CHANGED refreshes all five scoped current hosts and coalesces",function()
    local s=setup()
    for _,unit in ipairs(units) do
        if unit~="player" then s.auras[unit]={[71]=aura(71)} end
        s:fire("UNIT_FORM_CHANGED",unit)
        eq(s.R.hosts[unit]._formStateSpellID,unit=="player" and 2457 or 71)
    end
    eq(#s.timers,1); s.auras.focus={[2458]=aura(2458)}; s:drain()
    eq(s.R.hosts.focus._formStateSpellID,2458)
end)
for _,event in ipairs({"UPDATE_SHAPESHIFT_FORM","UPDATE_SHAPESHIFT_FORMS"}) do
    test(event.." refreshes self aliases now and rechecks deferred identity",function()
        local s=setup(); s.aliases.focus=true; s.aliases.targettarget=true
        s:fire(event); eq(s.R.hosts.player._formStateSpellID,2457); eq(s.R.hosts.focus._formStateSpellID,2457)
        eq(s.R.hosts.target._formStateSpellID,nil,"other unit not refreshed with local form")
        s.forms[1].id=2458; s:fire(event); eq(#s.timers,1)
        s.aliases.focus=false; s.auras.focus={[71]=aura(71)}; s:drain()
        eq(s.R.hosts.focus._formStateSpellID,71,"deferred token rechecked")
        eq(s.R.hosts.targettarget._formStateSpellID,2458)
    end)
end
test("unsupported optional stance events do not abort startup",function()
    local s=setup({UNIT_FORM_CHANGED=true,UPDATE_SHAPESHIFT_FORM=true,UPDATE_SHAPESHIFT_FORMS=true})
    s:fire("UNIT_AURA","player"); eq(s.R.hosts.player._formStateSpellID,2457)
end)
test("stance slash uses same resolver with bounded read only diagnostics",function()
    local s=setup(); s.auras.target={[71]=aura(71)}
    SlashCmdList.BJARKIPORTRAITS("stance")
    eq(#s.queries,3); eq(#s.timers,0); eq(s.R.hosts.target._formStateSpellID,nil,"diagnostic cannot update presentation")
    local text=table.concat(s.messages,"\n"); assert(text:find("unit%-aura")); assert(text:find("Defensive")); assert(text:find("2457=")); assert(text:find("71=")); assert(text:find("2458="))
    for _,arg in ipairs({"player","target","focus","tot","tof"}) do SlashCmdList.BJARKIPORTRAITS("stance "..arg) end
    SlashCmdList.BJARKIPORTRAITS("help"); assert(s.messages[#s.messages]:find("stance"))
    SlashCmdList.BJARKIPORTRAITS("stance bad"); assert(s.messages[#s.messages]:find("usage"))
end)
test("diagnostics distinguish query statuses without secret values",function()
    local s=setup(); s.auras.target={[2457]="error",[71]=SECRET}
    SlashCmdList.BJARKIPORTRAITS("stance target")
    local text=table.concat(s.messages,"\n"); assert(text:find("api%-error")); assert(text:find("unreadable")); assert(text:find("no%-values"))
    C_UnitAuras.GetUnitAuraBySpellID=nil; SlashCmdList.BJARKIPORTRAITS("stance target")
    assert(s.messages[#s.messages]:find("api%-unavailable"))
end)
-- API failure doubles replace only the failing native boundary; the shipped
-- resolver remains responsible for proving access before any use.
for _,mode in ipairs({"exists-error","player-error","dead-error","class-error","class-unavailable","self-error","self-unavailable"}) do
    test("native identity API boundary: "..mode,function()
        local s=setup(); s.auras.target={[71]=aura(71)}
        if mode=="exists-error" then UnitExists=function() error(SECRET) end
        elseif mode=="player-error" then UnitIsPlayer=function() error(SECRET) end
        elseif mode=="dead-error" then UnitIsDeadOrGhost=function() error(SECRET) end
        elseif mode=="class-error" then UnitClass=function() error(SECRET) end
        elseif mode=="class-unavailable" then UnitClass=nil
        elseif mode=="self-error" then UnitIsUnit=function() error(SECRET) end
        elseif mode=="self-unavailable" then UnitIsUnit=nil end
        local observed=mode=="self-error" or mode=="self-unavailable"
        eq(s:resolve().spellID,observed and 71 or nil)
        eq(s.formCalls,0,"unproven alias cannot use own form")
    end)
end
for _,id in ipairs({2457,71,2458}) do
    test("failed exact query "..id.." invalidates an independent positive",function()
        local s=setup(); s.auras.target={[id]="error"}
        local positive=id==71 and 2458 or 71
        s.auras.target[positive]=aura(positive)
        eq(s:resolve().spellID,nil); eq(#s.queries,3)
    end)
end
test("unknown next tick cancels previously proven stance",function()
    local s=setup(); s.auras.target={[71]=aura(71)}
    s:fire("UNIT_FORM_CHANGED","target"); eq(s.R.hosts.target._formStateSpellID,71)
    s.auras.target={}; s:drain(); s:show("target",nil)
end)
test("disabled queued stance reconciliation performs no reads",function()
    local s=setup(); s.aliases.focus=true; s:fire("UPDATE_SHAPESHIFT_FORM")
    local queries,forms=#s.queries,s.formCalls
    s.R.db.enabled=false; s:drain()
    eq(#s.queries,queries); eq(s.formCalls,forms)
end)
test("secret and irrelevant event units cannot enter stance work",function()
    local s=setup()
    for _,f in ipairs(s.frames) do
        if type(f.events.UNIT_FORM_CHANGED)=="table" then
            f.callback(f,"UNIT_FORM_CHANGED",SECRET)
            f.callback(f,"UNIT_FORM_CHANGED","party1")
        end
    end
    eq(#s.queries,0); eq(s.formCalls,0); eq(#s.timers,0)
end)
print("stance-state: "..cases.." cases, "..#failures.." failures")
assert(#failures==0,table.concat(failures,"\n"))
