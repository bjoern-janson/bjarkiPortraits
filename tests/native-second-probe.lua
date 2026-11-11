-- Native second-slot probe: source-backed shape and safety tests.
-- This models addon inbound calls, NOT Blizzard's secure layout itself.
-- The critical client experiment is whether grouped secret buttons flow
-- correctly through the fixed second-cell clipping viewport.
local BP={Runtime={}}
assert(loadfile("Core.lua"))("bjarkiPortraits", BP)
assert(loadfile("Spells.lua"))("bjarkiPortraits", BP)
assert(loadfile("Priority.lua"))("bjarkiPortraits", BP)
local R=BP.Runtime
local applyRealFormat=R.ApplyCountdownFormat
-- Persisted 0.1.195 off state must not require an in-game re-enable.
R.db={enabled=true,secondaryPortrait=true,nativeSecondProbe=false,showDecimals=true}
local combat=false
InCombatLockdown=function() return combat end
R.SafeBool=function(fn,...)
    if type(fn)~="function" then return nil,false end
    local ok,value=pcall(fn,...)
    return value,ok and type(value)=="boolean"
end
R.CanAccess=function(v) return v ~= "SECRET" end
R.ApplyCountdownFormat=function(cd)
    cd.formatCalls=(cd.formatCalls or 0)+1
    if cd.rejectFormat then return false end
    cd.decimals=R.db.showDecimals;return true
end
R.ApplySecondaryCountdownFont=function(cooldown)
    cooldown._bjarkiUsesRegularBuffFont=true
    return true
end
R.AttachPortraitAuraClock=function(button,cooldown)
    assert(not combat,"native timer bridge is attached out of combat")
    assert(button.cooldown==cooldown,"native cooldown is assigned before its timer bridge")
    assert(cooldown._bjarkiUsesRegularBuffFont,"native timer bridge follows source typography")
    cooldown.nativeClockButton=button
    cooldown.attachCalls=(cooldown.attachCalls or 0)+1
    return true
end
R.AURA_ANCHOR_TEMPLATE="DisableUntrustedLayoutScriptsTemplate"
R.SORT_METHOD=8
R.SORT_DIRECTION=1
local selfAliases={target=false,focus=false}
local guidByUnit={target="Creature-Initial",focus="Player-Focus",player="Player-Self"}
UnitGUID=function(unit) return guidByUnit[unit] end
UnitIsUnit=function(unit,compared)
    return compared=="player" and selfAliases[unit]==true
end

local checks=0
local function eq(value,want,label)
    assert(value==want,(label or "comparison")..": "..tostring(value).." versus "..tostring(want))
    checks=checks+1
end

local rejectGroupOnce, persistentGroupFailure, deniedGroups
local function frame(kind,parent)
    local o={kind=kind,parent=parent,shown=true}
    if kind=="AuraContainer" then o.enabled=true; o.unit="none" end
    function o:SetSize(w,h) self.width,self.height=w,h end
    function o:SetPoint(...) self.points={...} end
    function o:ClearAllPoints()self.points={}end
    function o:SetFrameStrata(v)self.strata=v end
    function o:GetFrameStrata()return self.strata or "HIGH" end
    function o:SetFrameLevel(v)self.level=v end
    function o:GetFrameLevel()return self.level or 40 end
    function o:EnableMouse(v)self.mouse=v end
    function o:SetClipsChildren(v)self.clips=v end
    function o:Show()self.shown=true end
    function o:Hide()self.shown=false end
    function o:IsVisible()return self.shown end
    function o:SetUnit(v)
        assert(type(v)=="string","Blizzard SetUnit requires a string")
        if self.unit ~= v then
            self.unit=v
            self:UpdateAllAuras()
        end
    end
    function o:SetEnabled(v)
        assert(type(v)=="boolean")
        if self.enabled ~= v then
            self.enabled=v
            self:UpdateAllAuras()
        end
    end
    function o:SetAuraGroupEnabled(key,enabled)
        assert(type(enabled)=="boolean")
        assert(not combat,"no native group setter during lockdown")
        for _,g in ipairs(self.groups or {}) do
            if g.key==key then
                self.groupEnableWrites=(self.groupEnableWrites or 0)+1
                if g.enabled~=enabled then
                    g.enabled=enabled
                    self:UpdateAllAuras()
                end
                return
            end
        end
        error("unknown group")
    end
    function o:SetAuraGroupFilterString(key,filter)
        assert(not combat,"no native filter setter during lockdown")
        for _,g in ipairs(self.groups) do
            if g.key==key then g.filter=filter; self:UpdateAllAuras();return end
        end
        error("unknown group")
    end
    function o:SetAuraGroupCandidateFilters(key,filters)
        assert(not combat)
        for _,g in ipairs(self.groups) do
            if g.key==key then g.options.candidateFilters=filters;return end
        end
        error("unknown group")
    end
    function o:SetAuraGroupLayout(key,layout)
        for _,g in ipairs(self.groups) do
            if g.key==key then g.options.layout=layout;return end
        end
        error("unknown group")
    end
    function o:UpdateAllAuras()
        self.refreshes=(self.refreshes or 0)+1
        self.lastRefreshedUnit=self.unit
        self.rebuildQueued=true
    end
    function o:CreateTexture()
        self.textures=self.textures or {}
        local tex=frame("texture",self)
        self.textures[#self.textures+1]=tex
        return tex
    end
    function o:CreateMaskTexture() return frame("mask",self) end
    function o:SetAtlas(v)self.atlas=v end
    function o:SetTexCoord(...) self.coords={...} end
    function o:SetAllPoints()self.allPoints=true end
    function o:AddMaskTexture(mask)self.mask=mask end
    function o:SetIcon(icon)self.icon=icon end
    function o:SetDurationCooldown(cooldown)self.cooldown=cooldown end
    function o:SetDrawBling()end
    function o:SetDrawEdge()end
    function o:SetDrawSwipe()end
    function o:SetReverse()end
    function o:SetUsingParentLevel()end
    function o:AddAuraGroup(key,filter,options)
        self.groups=self.groups or {}
        assert(not self:HasAuraGroup(key),"duplicate native group")
        if persistentGroupFailure and #self.groups==2 then
            deniedGroups=deniedGroups+1
            error("group currently unavailable")
        end
        self.groups[#self.groups+1]={key=key,filter=filter,options=options,
            enabled=true}
        -- The engine preallocates a guarded batch of button frames. One mock
        -- button suffices to check the inbound geometry/wiring shape.
        local b=frame("button",self)
        options.initializeFrame(b)
        self.groups[#self.groups].sampleCooldown=b.cooldown
        eq(b.width,50,"native second-button cell actually enlarged")
        eq(b.icon.width,30,"secure secondary art matches regular buff icon, not border")
        eq(b.textures[2].width,41,"native totem bezel visibly grows to 36px")
        eq(b.textures[2].atlas,"UI-HUD-UnitFrame-TotemFrame",
            "enlarged native ring retains Blizzard artwork")
        eq(b.cooldown~=nil,true,"native cooldown assigned")
        eq(b.cooldown._bjarkiUsesRegularBuffFont,true,
            "native second countdown applies regular buff-duration font")
        eq(b.icon.mask~=nil,true,"circular icon mask installed")
        eq(b.icon.coords[1],2/64,"native second art trims left edge")
        eq(b.icon.coords[2],1-2/64,"native second art trims right edge")
        eq(b.icon.coords[3],2/64,"native second art trims top edge")
        eq(b.icon.coords[4],1-2/64,"native second art trims bottom edge")
eq(b.icon.points[1],"CENTER","native art centered on its cell")
eq(b.textures[2].points[4],1.35,"native rim x matches Blizzard optical inset")
eq(b.textures[2].points[5],-2,"native rim y matches Blizzard optical inset")
        if rejectGroupOnce and #self.groups==3 then
            rejectGroupOnce=false
            self.groups[#self.groups].options.layout=nil
            error("failed after registering third native group")
        end
    end
    function o:HasAuraGroup(key)
        for _,g in ipairs(self.groups or {}) do if g.key==key then return true end end
        return false
    end
    return o
end
UIParent=frame("UIParent")
CreateFrame=function(kind,name,parent,template)
    local f=frame(kind,parent)
    f.template=template
    return f
end
assert(loadfile("NativeSecondProbe.lua"))("bjarkiPortraits",BP)

-- Existing lifecycle scenarios advance the deferred native builder to its
-- next stable boundary. The scheduling scenarios below inspect each turn.
local constructionCallbacks={}
C_Timer={After=function(delay,callback)
    if delay~=.01 then return false end
    constructionCallbacks[#constructionCallbacks+1]=callback
end}
local advancing,callDepth=false,0
local function advanceConstruction()
    if advancing then return end
    advancing=true
    local steps=0
    while #constructionCallbacks>0 do
        steps=steps+1;assert(steps<1000,"construction must be bounded")
        table.remove(constructionCallbacks,1)()
    end
    advancing=false
end
local updateNative,createNative=R.UpdateNativeSecondProbe,R.CreateNativeSecondProbe
R.UpdateNativeSecondProbe=function(h,...)
    R.hosts[h.unit]=h;h.testNativeArguments={...}
    callDepth=callDepth+1;local result=updateNative(h,...);callDepth=callDepth-1
    if callDepth==0 then advanceConstruction() end
    return result
end
R.CreateNativeSecondProbe=function(h)
    R.hosts[h.unit]=h
    callDepth=callDepth+1;local result=createNative(h);callDepth=callDepth-1
    if callDepth==0 then
        advanceConstruction()
        return result or (h._nativeSecondProbe and h._nativeSecondProbe.ready==true) or false
    end
    return result
end
R.Refresh=function(unit)
    local h=R.hosts[unit]
    if h and h.testNativeArguments then R.UpdateNativeSecondProbe(h,(unpack or table.unpack)(h.testNativeArguments))
    elseif h then R.CreateNativeSecondProbe(h) end
end

local host={unit="target",portrait=frame("portrait"),
    secondaryBadge=frame("badge")}
host.unitFrame=frame("native target")
host.secondaryBadge.level=50
eq(host._nativeSecondProbe,nil,"no eager construction on load")
R.UpdateNativeSecondProbe(host,true,nil,true,false)
eq(host._nativeSecondProbe,nil,"unknown target relation creates no native groups")
combat=true
R.UpdateNativeSecondProbe(host,true,true,true,false)
eq(host._nativeSecondProbe,nil,"first hostile target in combat defers structural setup")
eq(host._nativeSecondProbeReason,"setup-deferred-until-out-of-combat",
    "deferred setup is recorded for diagnosis")
combat=false
R.UpdateNativeSecondProbe(host,true,true,true,false)
eq(host._nativeSecondProbe~=nil,true,"eligible NPC builds automatically without commands")
local p=host._nativeSecondProbe
eq(p.ready,true,"native container initialized")
eq(p.cooldowns[1].nativeClockButton,nil,"native second avoids the extra duration-bar bridge")
eq(p.cooldowns[1]._bjarkiLightNativeSecond,true,"native second receiver uses capped lightweight path")
eq(p.clip.clips,true,"fixed clipping viewport")
eq(p.clip.width,50,"entire native secondary viewport actually enlarged")
eq(p.clip.points[3],"TOPLEFT","native Target runner-up avoids right-hand combo points")
eq(p.clip.points[4],10,"native Target has +10 upper-left x offset")
eq(p.clip.points[5],12,"native Target is raised 12px above frame top corner")
eq(p.container.points[4],-50,"first native cell still completely clipped after resizing")
eq(p.container.unit,"target","native unit owns current target")
eq(p.container.enabled,true,"first native Target build enables all secure aura groups")
eq(p.container.refreshes>=2,true,"fresh native groups actually reparse after enable")
eq(p.boundGUID,"Creature-Initial","native viewport remembers exact bound creature")
eq(p.groups>20,true,"cross-priority native groups created")
eq(#p.container.groups,p.groups,"group registry complete")
local oldLevel=math.huge
local keys={}
for i,g in ipairs(p.container.groups) do
    local tIndex=tonumber(g.key:match("^tier(%d+)$"))
    local tier=R.TIERS[tIndex]
    eq(g.options.maxFrameCount,2,"only top two per group")
    eq(g.options.layout.layoutIndex,i,"global group order is contiguous")
    eq(tier.level<=oldLevel,true,"global priority descends across groups")
    oldLevel=tier.level
    keys[tier.key]=g
end
eq(keys.DoTs~=nil,true,"DoTs are present in native list")
eq(keys.Slows~=nil,true,"slows are present in native list")
eq(keys.BoostedRest~=nil,true,"bottom harmful tier retained")
eq(keys.SmallFriendlyHarmful.options.candidateFilters.excludeSpellIDs[772],
   true,"generic harmful cannot duplicate exact Rend")
eq(keys.HostileHelpful.options.candidateFilters.excludeSpellIDs[1126],
   true,"generic helpful cannot duplicate exact Mark")
eq(keys.SmallFriendlyHarmful.options.candidateFilters.isPriorityAura,
   false,"generic harmful cannot duplicate priority debuff")
eq(keys.HostileHelpful.filter,
    "HELPFUL|INCLUDE_NAME_PLATE_ONLY|!IMPORTANT|!BIG_DEFENSIVE|!EXTERNAL_DEFENSIVE",
    "hostile broad helpful cannot also consume an Important/BigDef aura")
-- Model the documented Forever filter tokens on synthetic non-exact IDs.
-- An inclusive generic exclusion is safe only while another enabled group
-- can actually receive the excluded effect, including nameplate-only ones.
local function matchingSemanticGroups(flags, priority, duration)
    duration=duration or 8
    local matched = {}
    for _,key in ipairs({"HostileHelpful","Important","ExternalDef","BigDef",
        "SmallFriendlyHarmful","PriorityDebuff","CrowdControl"}) do
        local group=keys[key]
        local accepts=group.enabled and (not flags.INCLUDE_NAME_PLATE_ONLY or
            group.filter:find("INCLUDE_NAME_PLATE_ONLY",1,true) ~= nil)
        for token in group.filter:gmatch("[^|]+") do
            if token ~= "INCLUDE_NAME_PLATE_ONLY" then
                local negative=token:sub(1,1)=="!"
                local flag=negative and token:sub(2) or token
                if (flags[flag]==true)==negative then accepts=false end
            end
        end
        local options=group.options.candidateFilters or {}
        if options.maxDuration and (duration==0 or duration>options.maxDuration) then accepts=false end
        if options.isPriorityAura~=nil and options.isPriorityAura~=priority then accepts=false end
        if accepts then matched[#matched+1]=key end
    end
    return table.concat(matched,",")
end
eq(matchingSemanticGroups({HARMFUL=true,CROWD_CONTROL=true,INCLUDE_NAME_PLATE_ONLY=true},true,3600),
    "","long nameplate-only CC cannot enter when the main generic rejects it")
eq(matchingSemanticGroups({HARMFUL=true,CROWD_CONTROL=true,INCLUDE_NAME_PLATE_ONLY=true},true,3599),
    "CrowdControl","main generic duration boundary remains eligible exactly once")
eq(matchingSemanticGroups({HELPFUL=true,IMPORTANT=true,INCLUDE_NAME_PLATE_ONLY=true},false,0),
    "","permanent nameplate-only Important cannot enter via its generic exclusion")
for _,nameplate in ipairs({false,true}) do
    eq(matchingSemanticGroups({HARMFUL=true,CROWD_CONTROL=true,INCLUDE_NAME_PLATE_ONLY=nameplate},true),
        "CrowdControl","timed CC has exactly one native owner in either nameplate mode")
    eq(matchingSemanticGroups({HARMFUL=true,INCLUDE_NAME_PLATE_ONLY=nameplate},true),
        "PriorityDebuff","priority debuff has one owner in either nameplate mode")
    eq(matchingSemanticGroups({HELPFUL=true,IMPORTANT=true,EXTERNAL_DEFENSIVE=true,BIG_DEFENSIVE=true,
        INCLUDE_NAME_PLATE_ONLY=nameplate},false),"BigDef","hostile defensive has one native owner")
end
eq(keys.SmallFriendlyHarmful.filter,
    "HARMFUL|INCLUDE_NAME_PLATE_ONLY|!CROWD_CONTROL",
    "generic harmful cannot duplicate CrowdControl")
eq(keys.HostileHelpful.enabled,true,"hostile Target broad helpful enabled")

R.UpdateNativeSecondProbe(host,true,true,true,false)
eq(p.clip.shown,true,"verified NPC probe is shown")
eq(host.secondaryBadge.shown,false,"legacy NPC badge hidden under native ribbon")
local writes=p.container.groupEnableWrites
combat=true
R.UpdateNativeSecondProbe(host,true,false,true,true)
eq(p.clip.shown,false,"combat relation flip suppresses stale broad group")
eq(p.container.groupEnableWrites,writes,"combat avoids protected group write")
eq(keys.HostileHelpful.enabled,true,"failed combat change cannot relabel secure group")
eq(host._nativeSecondProbeReason,"hostile-group-change-deferred-combat",
    "combat relation deferral carries explicit reason")
combat=false
R.UpdateNativeSecondProbe(host,true,false,true,true)
eq(keys.HostileHelpful.enabled,false,"friendly target turns broad group off")
R.UpdateNativeSecondProbe(host,true,true,true,false)
eq(keys.HostileHelpful.enabled,true,"hostile target turns group on again")

-- Fear expiry / aura removal while the native public reader is restricted:
-- the optional hostile helpful group may still be OFF from an earlier
-- friendly relation. Enabling it is protected in combat, but unrelated
-- harmful and exact native groups remain usable and must not disappear.
combat=false
R.UpdateNativeSecondProbe(host,true,false,true,false)
eq(keys.HostileHelpful.enabled,false,"friendly Target starts with broad group disabled")
eq(matchingSemanticGroups({HELPFUL=true,IMPORTANT=true,INCLUDE_NAME_PLATE_ONLY=true},false),
    "","friendly Target cannot acquire an extra hostile-only nameplate buff")
eq(matchingSemanticGroups({HELPFUL=true,IMPORTANT=true},false,0),
    "Important","friendly ordinary permanent Important survives hostile-to-friendly filter reset")
host._secondaryMode="hidden"
host._secondaryElectionReason="inaccessible-index"
combat=true
local priorGroupWrites=p.container.groupEnableWrites
local priorAuraUpdates=p.container.refreshes
R.UpdateNativeSecondProbe(host,true,true,true,false)
eq(p.clip.shown,true,
    "hostile Coyote retains native runner-up after Fear removal in combat")
eq(keys.HostileHelpful.enabled,false,
    "optional hostile helpful group stays disabled during combat")
eq(p.container.groupEnableWrites,priorGroupWrites,
    "Fear-expiry transition performs no protected group writes")
eq(p.container.refreshes,priorAuraUpdates,
    "Fear-expiry fallback does not force a prohibited full aura rebuild")
eq(host._nativeSecondProbeReason,
    "other-unit-native-ribbon:hostile-helpful-deferred",
    "debug explains safe partial hostile helpful coverage")
R.UpdateNativeSecondProbe(host,true,true,true,false,true,false)
eq(p.clip.shown,true,"stable forced combat state refresh keeps Coyote ribbon")
combat=false
R.UpdateNativeSecondProbe(host,true,true,true,false)
eq(keys.HostileHelpful.enabled,true,
    "combat exit enables optional hostile helpful group")
eq(host._nativeSecondProbeReason,"other-unit-native-ribbon",
    "normal native fallback resumes after safe completion")

-- Newly targeted UNTAGGED mob: the token remains "target", but the
-- native second must not keep the previous mob's aura and ticking timer.
local count=p.container.refreshes or 0
guidByUnit.target="Creature-Untagged"
R.UpdateNativeSecondProbe(host,true,true,true,false,true)
eq(p.container.refreshes,count+1,"forced retarget refreshes native second too")
eq(p.container.lastRefreshedUnit,"target","refreshes current token")
eq(p.boundGUID,"Creature-Untagged","current creature GUID replaces stale one")
eq(p.clip.shown,true,"native clip is eligible after fresh out-of-combat update")

-- A hidden/restricted GUID during a forced target change cannot be
-- compared to the previous owner, so refuse to display the old icon.
guidByUnit.target="SECRET"
R.UpdateNativeSecondProbe(host,true,true,true,false,true,true)
eq(p.clip.shown,false,"unknown replacement GUID hides stale aura")
eq(p._unused,nil,"no synthetic positive evidence created")
eq(host._nativeSecondProbeReason,"unit-identity-unreadable",
    "secret target identity reports fail-closed reason")
eq(p.boundGUID,"Creature-Untagged","unreadable GUID cannot overwrite witness")
R.UpdateNativeSecondProbe(host,true,true,true,false)
eq(p.clip.shown,false,"ordinary aura update cannot release unresolved target handoff")

-- Retargeting during combat cannot safely refresh protected group layout;
-- the old badge stays hidden until an ordinary OOC refresh.
guidByUnit.target="Creature-CombatSwap"
combat=true
R.UpdateNativeSecondProbe(host,true,true,true,false,true)
eq(p.clip.shown,false,"combat retarget hides previous creature's aura")
eq(p.boundGUID,"Creature-Untagged","combat change does not relabel old group")
combat=false
R.UpdateNativeSecondProbe(host,true,true,true,false,true)
eq(p.clip.shown,true,"OOC refresh restores native second eligibility")
eq(p.boundGUID,"Creature-CombatSwap","OOC restoration tracks new creature")
eq(p.container.refreshes,count+2,"one refresh for each safe target swap")
for _,g in ipairs(p.container.groups) do
    eq(g.sampleCooldown.decimals,true,"native groups use initial decimal preference")
end
combat=true
R.db.showDecimals=false
if R.ApplyNativeSecondPresentation then R.ApplyNativeSecondPresentation(host) end
eq(keys.DoTs.sampleCooldown.decimals,true,"native protected timers defer formatting in combat")
combat=false
R.UpdateNativeSecondProbe(host,true,true,true,false)
for _,g in ipairs(p.container.groups) do
    eq(g.sampleCooldown.decimals,false,"existing native timers adopt deferred decimal preference")
end
keys.DoTs.sampleCooldown.rejectFormat=true
R.db.showDecimals=true
R.ApplyNativeSecondPresentation(host)
local alreadyFormatted=keys.Slows.sampleCooldown.formatCalls
keys.DoTs.sampleCooldown.rejectFormat=false
R.ApplyNativeSecondPresentation(host)
eq(keys.DoTs.sampleCooldown.decimals,true,"failed formatter retries the affected timer")
eq(keys.Slows.sampleCooldown.formatCalls,alreadyFormatted,"successful native timers do not retry on a partial failure")

do
    local previousFormat,previousStrings,previousEnum=R.ApplyCountdownFormat,C_StringUtil,Enum
    local attempts,visibilityWrites,numeric=0,0,0
    C_StringUtil=nil
    Enum={NumericRuleFormatRounding={Floor=1,Down=1}}
    R.RetryCountdownFormatter()
    R.ApplyCountdownFormat=function(cd,label,verify)
        cd.SetHideCountdownNumbers=function(self,hidden)
            self.numbersHidden=hidden
            visibilityWrites=visibilityWrites+1
        end
        cd.GetHideCountdownNumbers=function(self)return self.numbersHidden==true end
        cd.SetCountdownMillisecondsThreshold=function()error("decimal thresholds cannot hide long numbers")end
        cd.SetCountdownFormatter=function(self,formatter)
            if self.rejectNative then return false end
            self.installed=formatter
            numeric=numeric+1
        end
        cd.GetCountdownFormatter=function(self)return self.installed end
        return applyRealFormat(cd,label,verify)
    end
    local other={unit="focus",unitFrame=frame("focus"),portrait=frame("portrait"),secondaryBadge=frame("badge")}
    assert(R.CreateNativeSecondProbe(other))
    local ribbons=other._nativeSecondProbe.cooldowns
    local count=#ribbons
    for _,clock in ipairs(ribbons) do eq(clock.numbersHidden,true,"no cap means native strips start hidden") end
    local before=visibilityWrites
    for _=1,10 do R.ApplyNativeSecondPresentation(other) end
    eq(visibilityWrites,before,"ordinary updates leave safely hidden strip clocks alone")
    C_StringUtil={CreateNumericRuleFormatter=function()
        attempts=attempts+1
        return {
            SetBreakpoints=function(self,rules) self.rules=rules end,
            FormatNumber=function(self,value)
                local active
                for _,rule in ipairs(self.rules) do
                    if value>=rule.threshold then active=rule end
                end
                if active.step then value=math.floor(value/active.step)*active.step end
                return string.format(active.format,value)
            end,
        }
    end}
    R.RetryCountdownFormatter()
    ribbons[1].rejectNative=true
    combat=true;R.UpdateNativeSecondProbe(other,true,true,true,false);eq(numeric,0,"combat defers formatter recovery")
    combat=false;R.UpdateNativeSecondProbe(other,true,true,true,false)
    eq(numeric,count-1,"normal safe update upgrades hidden strips after a new formatter epoch")
    eq(ribbons[1].numbersHidden,true,"a receiver that refuses the cap stays hidden")
    for i=2,count do eq(ribbons[i].numbersHidden,false,"accepted cap permits short numbers") end
    eq(ribbons[2].installed:FormatNumber(30),"30","native second shows the last permitted whole second")
    eq(ribbons[2].installed:FormatNumber(48*60),"","native second cannot display a 48-minute label")
    eq(attempts,1,"recovery shares one native formatter")
    ribbons[1].rejectNative=nil
    for _=1,10 do R.ApplyNativeSecondPresentation(other) end
    eq(numeric,count-1,"one hidden receiver does not retry every event")
    R.RetryCountdownFormatter();R.UpdateNativeSecondProbe(other,true,true,true,false)
    eq(ribbons[1].numbersHidden,false,"the remaining strip clock recovers on the next safe epoch")
    R.ApplyNativeSecondPresentation(other);eq(numeric,count,"successful upgrade is retained")
    local capped=ribbons[2].installed
    ribbons[2].installed={}
    combat=true
    R.ApplyNativeSecondPresentation(other,true)
    eq(numeric,count,"combat queues explicit timer verification without native writes")
    combat=false
    R.UpdateNativeSecondProbe(other,true,true,true,false)
    eq(ribbons[2].installed,capped,"normal recovery repairs a replaced native formatter")
    eq(numeric,count+1,"verification rewrites only the changed native recipient")
    R.UpdateNativeSecondProbe(other,true,true,true,false)
    eq(numeric,count+1,"unchanged aura updates do not reverify the strip")
    R.ApplyCountdownFormat,C_StringUtil,Enum=previousFormat,previousStrings,previousEnum
end

do
    -- Production low-overhead path: no native duration bridge or six-cell
    -- renderer on the many preallocated secondary buttons. A capped native
    -- formatter remains installed, including on reuse.
    local oldFormat,oldFont,oldCells=R.ApplyCountdownFormat,R.ApplySecondaryCountdownFont,R.ApplyPortraitTimer
    local formatter,attemptedCells={},0
    R.ApplyPortraitTimer=function()
        attemptedCells=attemptedCells+1
        error("native second must not allocate fixed glyphs")
    end
    R.ApplyCountdownFormat=function(cd)
        cd.formatter=formatter
        cd.formatCalls=(cd.formatCalls or 0)+1
        return true,"formatter"
    end
    local function owner(unit)
        return {unit=unit,unitFrame=frame(unit),portrait=frame("portrait"),secondaryBadge=frame("badge")}
    end
    local other=owner("focus")
    assert(R.CreateNativeSecondProbe(other))
    local probe=other._nativeSecondProbe
    local clocks=probe.cooldowns
    eq(#clocks>50,true,"native runner-up groups still constructed")
    eq(#probe.fallbackClocks,0,"intentional capped native clocks have no glyph retry queue")
    for _,cd in ipairs(clocks) do
        eq(cd._bjarkiLightNativeSecond,true,"secondary preallocation selects cheap countdown")
        eq(cd.nativeClockButton,nil,"no extra status-bar bridge")
        eq(cd.attachCalls,nil,"no additional duration-bar attachment")
        eq(cd.formatter,formatter,"native second retains its number formatter")
    end
    eq(attemptedCells,0,"no six-cell processing")
    local calls=clocks[1].formatCalls
    R.RetryCountdownFormatter()
    R.ApplyNativeSecondPresentation(other)
    eq(clocks[1].formatCalls,calls,"formatter epoch does not retry successful lightweight clocks")
    assert(R.ReleaseNativeSecondProbe(other))
    local rebound=owner("target")
    assert(R.CreateNativeSecondProbe(rebound))
    eq(rebound._nativeSecondProbe.cooldowns,clocks,"same cheap receiver pool is reused")
    eq(attemptedCells,0,"pooled reuse adds no text bindings")
    R.ApplyCountdownFormat,R.ApplySecondaryCountdownFont,R.ApplyPortraitTimer=oldFormat,oldFont,oldCells
end

-- A complete readable inventory can still lack the metadata to RANK
-- its two visible auras. That is NOT proof of zero or one secure aura
-- candidate; let the native second-cell clip decide whether there is an
-- actual second icon. It paints nothing if no second button exists.
host._secondaryMode="hidden"
host._secondaryElectionReason="not-two-presentable"
R.UpdateNativeSecondProbe(host,true,true,true,false)
eq(p.clip.shown,true,
    "hostile Wendigo can expose secure runner-up after public rank uncertainty")
host._secondaryElectionReason=nil
R.UpdateNativeSecondProbe(host,true,true,true,false)
eq(p.clip.shown,true,"unknown native second still permitted when not disproved")

-- Public verified two-aura NPC selection must not be covered by a second
-- competing native renderer with potentially different classification.
host._secondaryMode="aura"
R.UpdateNativeSecondProbe(host,true,true,true,false)
eq(p.clip.shown,false,"real NPC second from public election is authoritative")
host._secondaryMode=nil
R.UpdateNativeSecondProbe(host,true,true,true,false)
eq(p.clip.shown,true,"NPC native fallback recovers when public proof lost")
host._secondaryOnlyRepeatedSpell=772
R.UpdateNativeSecondProbe(host,true,true,true,false)
eq(p.clip.shown,false,"two known instances of Rend cannot be its own runner-up")
host._secondaryOnlyRepeatedSpell=nil
host._readableTierOwners={BaselineClass={complete=true,nativeOrderMismatch=true}}
R.UpdateNativeSecondProbe(host,true,true,true,false)
eq(p.clip.shown,false,"known disagreement with the application-time primary prevents duplicate")
host._readableTierOwners={}
host.unitFrame:Hide()
R.UpdateNativeSecondProbe(host,true,true,true,false)
eq(p.clip.shown,false,"hidden native owner vetoes detached secure clip")
host.unitFrame:Show()
R.UpdateNativeSecondProbe(host,true,true,true,false)
eq(p.clip.shown,true,"current visible host can again expose best-effort native second")
-- The same false no-second inference also affects friendly player targets
-- visibly carrying two or more buffs. Its native runner-up must cover race.
host._secondaryMode="race"
host._raceBaselineActive=true
-- In production ReconcileSecondaryPortrait has already painted the
-- verified race underlay before native fallback reconciliation.
host.secondaryBadge:Show()
host._secondaryElectionReason="not-two-presentable"
R.UpdateNativeSecondProbe(host,true,false,true,true)
eq(p.clip.shown,true,"friendly player with unrankable second can use native clip")
eq(host.secondaryBadge.shown,true,"verified friendly race remains under native second")
eq(p.container.enabled,true,"friend's actual native aura groups are enabled")
eq(keys.HostileHelpful.enabled,false,"friend's important buff cannot be counted twice")
host._secondaryElectionReason=nil
host._secondaryMode="hidden"
host._raceBaselineActive=false
-- Opposite-faction players previously showed only race even with two
-- visible auras, since the secure native ribbon excluded ALL players.
-- The native second can now cover a verified race baseline without Lua
-- reading the hostile player's protected aura identities.
host.secondaryBadge:Show()
R.UpdateNativeSecondProbe(host,true,true,true,true)
eq(p.clip.shown,true,"opposite-faction player receives native runner-up")
eq(keys.HostileHelpful.enabled,true,"hostile player may retain broad helpful fallback")
eq(host.secondaryBadge.shown,true,"hostile player's race underlay remains available")
eq(p.container.unit,"target","hostile player uses same native target token")
R.UpdateNativeSecondProbe(host,true,true,false,true)
eq(p.clip.shown,false,"hostile player with unreadable identity excluded")
R.UpdateNativeSecondProbe(host,true,true,true,nil)
eq(p.clip.shown,false,"unknown player-versus-NPC distinction excluded")
R.UpdateNativeSecondProbe(host,true,nil,true,true)
eq(p.clip.shown,false,"unknown relation fails closed")

-- Friendly and neutral targets previously reverted to race/hidden whenever
-- a single inaccessible harmful aura invalidated their public top-two scan.
-- Native groups can render the second without reading that debuff into Lua.
host._secondaryMode="race"
host._raceBaselineActive=true
host.secondaryBadge:Show()
host._secondaryElectionReason="inaccessible-index"
R.UpdateNativeSecondProbe(host,true,false,true,true)
eq(p.clip.shown,true,"friendly player fallback uses native second cell")
eq(host.secondaryBadge.shown,true,"verified friendly player race stays under native")
eq(host._nativeSecondProbeReason,"friendly-secondary-native-fallback",
   "friendly fallback is distinguishable without a slash command")
eq(p.container.unit,"target","friendly target still uses native target token")
host._secondaryMode="aura"
R.UpdateNativeSecondProbe(host,true,false,true,true)
eq(p.clip.shown,false,"publicly verified friendly second is authoritative")
host._secondaryMode="form"
R.UpdateNativeSecondProbe(host,true,false,true,true)
eq(p.clip.shown,false,"public static-form second is authoritative")
host._secondaryMode="race"
host._formStateActive=true
R.UpdateNativeSecondProbe(host,true,false,true,true)
eq(p.clip.shown,false,"independent friendly static form cannot be outranked")
host._formStateActive=false
host._ghostActive=true
R.UpdateNativeSecondProbe(host,true,false,true,true)
eq(p.clip.shown,false,"independent friendly Ghost remains authoritative")
host._ghostActive=false

-- Two or more visible buffs plus a restricted debuff on a neutral NPC:
-- public reader can hide the badge; native must be able to paint its
-- second cell without requiring race or publicly readable harmful IDs.
host._secondaryMode="hidden"
host.secondaryBadge:Show()
R.UpdateNativeSecondProbe(host,true,false,true,false)
eq(p.clip.shown,true,"neutral NPC can render native second after public failure")
eq(host.secondaryBadge.shown,false,"confirmed nonplayer cannot retain stale race")
host._secondaryMode="aura"
host.secondaryBadge:Show()
R.UpdateNativeSecondProbe(host,true,false,true,false)
eq(p.clip.shown,false,"valid friendly NPC public second stays visible")
eq(host.secondaryBadge.shown,true,"public aura portrait was not hidden")

R.UpdateNativeSecondProbe(host,false,true,true,true)
eq(p.clip.shown,false,"inactive hostile player excluded")

R.ReleaseNativeSecondProbe(host)
eq(host._nativeSecondProbe,nil,"host releases native probe ownership")
eq(p.container.unit,"target","Blizzard retains the old token when disabled")
eq(p.container.enabled,false,"release disables and clears the native groups")
eq(p.container.rebuildQueued,true,"release requested a native full rebuild")
local beforeReuse=p.container.refreshes
local other={unit="target",portrait=frame("portrait"),
    secondaryBadge=frame("badge")}
other.unitFrame=frame("native target")
other.secondaryBadge.level=60
local bind=p.container.SetUnit
p.container.SetUnit=function() error("one denied pooled bind") end
R.UpdateNativeSecondProbe(other,true,true,true,true)
eq(other._nativeSecondProbe,p,"failed pool setter retains exclusive owner for retry")
eq(p.clip.shown,false,"failed pooled bind cannot display old cell")
p.container.SetUnit=bind
R.UpdateNativeSecondProbe(other,true,true,true,true)
eq(other._nativeSecondProbe,p,"next hostile player automatically reuses pooled probe")
eq(p.container.enabled,true,"pooled second-aura container re-enabled")
eq(p.container.refreshes>beforeReuse,true,
    "same token reuse forces new aura read rather than retaining Rend")
eq(other._nativeSecondProbe.ready,true,"reused native strip is ready")
eq(p.clip.points[2],other.portrait,"reused probe anchors to current portrait")
eq(p.clip.level,62,"reused native viewport remains above the current badge")
eq(p.clip.points[3],"TOPLEFT","reused target probe retains combo-safe side")
eq(p.clip.points[4],10,"reused target probe retains x offset")
eq(p.clip.points[5],12,"reused target probe retains raised y offset")
local filterSetter=p.container.SetAuraGroupFilterString
local changes=0
p.container.SetAuraGroupFilterString=function(self,key,filter)
    changes=changes+1
    if changes==2 then error("partial relation filter update") end
    return filterSetter(self,key,filter)
end
R.UpdateNativeSecondProbe(other,true,false,true,true)
eq(p.clip.shown,false,"mixed native filters are kept hidden after partial failure")
combat=true
R.UpdateNativeSecondProbe(other,true,true,true,true)
eq(p.clip.shown,false,"return to former relation cannot reuse mixed filters in combat")
combat=false
p.container.SetAuraGroupFilterString=filterSetter
R.UpdateNativeSecondProbe(other,true,true,true,true)
eq(p.clip.shown,true,"safe retry restores the whole hostile filter configuration")
local partial={unit="focus",unitFrame=frame("focus"),portrait=frame("portrait"),secondaryBadge=frame("badge")}
rejectGroupOnce=true
R.UpdateNativeSecondProbe(partial,true,true,true,false)
local failed=partial._nativeSecondProbe
eq(failed.clip.shown,false,"part-built native ribbon stays hidden")
R.UpdateNativeSecondProbe(partial,true,true,true,false,true)
eq(partial._nativeSecondProbe,failed,"retry reuses the partial frame tree")
eq(failed.ready,true,"after-register failure resumes at its configuration checkpoint")
eq(#failed.container.groups,#p.container.groups,"no successful native group is allocated twice")
local recoveredLayout=failed.container.groups[3].options.layout
eq(recoveredLayout and recoveredLayout.layoutIndex,3,"native post-registration layout is repaired")
local enabledSetter=failed.container.SetEnabled
local rejectedDisable=false
failed.container.SetEnabled=function(self,enabled)
    if not enabled and not rejectedDisable then rejectedDisable=true; error("release denied once") end
    return enabledSetter(self,enabled)
end
R.ReleaseNativeSecondProbe(partial)
local recovered={unit="focus",unitFrame=frame("focus"),portrait=frame("portrait"),secondaryBadge=frame("badge")}
R.UpdateNativeSecondProbe(recovered,true,true,true,false)
eq(recovered._nativeSecondProbe,failed,"hidden ribbon with denied disable is disarmed and reused")
eq(failed.container.enabled,true,"release denial recovers with an explicit safe bind")
local hideClip=failed.clip.Hide
failed.clip.Hide=function()error("hidden state unavailable")end
eq(R.ReleaseNativeSecondProbe(recovered),false,"unrevokeable viewport cannot be relinquished")
eq(recovered._nativeSecondProbe,failed,"release retains owner while visibility cannot be revoked")
local retryHost={unit="focus",unitFrame=frame("focus"),portrait=frame("portrait"),secondaryBadge=frame("badge")}
persistentGroupFailure,deniedGroups=true,0
R.UpdateNativeSecondProbe(retryHost,true,true,true,false)
R.UpdateNativeSecondProbe(retryHost,true,true,true,false)
eq(deniedGroups,1,"ordinary aura event cannot allocate another failed batch")
for i=1,6 do R.UpdateNativeSecondProbe(retryHost,true,true,true,false,true) end
eq(deniedGroups,2,"one structural retry at the same unresolved group bounds allocation")
local quarantined=retryHost._nativeSecondProbe
eq(quarantined.clip.shown,false,"exhausted setup stays hidden")
R.ReleaseNativeSecondProbe(retryHost)
persistentGroupFailure=false
R.UpdateNativeSecondProbe(retryHost,true,true,true,false)
eq(retryHost._nativeSecondProbe,quarantined,"new explicit host lifecycle recovers quarantined tree")
eq(quarantined.ready,true,"previously denied group can complete safely")
R.ReleaseNativeSecondProbe(retryHost)
failed.clip.Hide=hideClip
eq(R.ReleaseNativeSecondProbe(recovered),true,"resolved visibility failure permits release")
R.ReleaseNativeSecondProbe(other)

-- PlayerFrame: eagerly prewarm in the first out-of-combat update, while
-- the normal readable second is still working. A new frost/control debuff
-- can then seal the public aura scan while the native strip stays active.
local player={unit="player", portrait=frame("portrait"),
    secondaryBadge=frame("badge"), _assistable=true,
    _secondaryMode="aura", _raceBaselineActive=false}
player.unitFrame=frame("native player")
player.secondaryBadge.level=65
R.UpdateNativeSecondProbe(player,true,false,true,true)
local pp=player._nativeSecondProbe
eq(pp~=nil,true,"player prewarms native ribbon before receiving a debuff")
eq(pp.ready,true,"player native groups fully initialized out of combat")
eq(pp.container.enabled,true,"first Player build enables native secure runner-up")
local selfBroad
for _,g in ipairs(pp.container.groups) do
    if g.key==pp.hostileHelpfulKey then selfBroad=g;break end
end
eq(selfBroad~=nil,true,"native Player group registered for safe pool reuse")
eq(selfBroad.enabled,false,"Player never consumes HostileHelpful into a duplicate slot")
eq(pp.container.unit,"player","native ribbon binds its actual player token")
eq(pp.clip.points[3],"TOPRIGHT","player native ribbon mirrors inward toward bars")
eq(pp.clip.points[4],-10,"player native mirrored x inset")
eq(pp.clip.points[5],12,"player native preserves elevated position")
eq(pp.clip.shown,false,"verified readable second remains authoritative")
eq(pp.groups,p.groups,"player shares same existing tier policy")

-- An incoming combat debuff can make GetAuraDataByIndex inaccessible and
-- force the public election back to race. Native protected renderer must
-- then cover the race while preserving the existing fallback below.
combat=true
player._secondaryMode="race"
player._raceBaselineActive=true
player._secondaryAuraEventDirty=true
player._secondaryElectionReason="inaccessible-index"
player.secondaryBadge:Show()
R.UpdateNativeSecondProbe(player,true,false,true,true)
eq(pp.clip.shown,true,"incoming combat debuff activates native runner-up")
eq(selfBroad.enabled,false,"combat entry cannot re-enable hostile group on Player")
eq(player.secondaryBadge.shown,true,"underlying race is not destroyed")
eq(player._nativeSecondProbeReason,"player-native-race-fallback",
    "native player fallback reason is explicit")
eq(pp.container.unit,"player","no target-token leakage on player")

-- When Lua regains complete evidence, keep its existing winner and turn off
-- the native overlay to avoid competing with static/recency election.
player._secondaryMode="aura"
player._raceBaselineActive=false
R.UpdateNativeSecondProbe(player,true,false,true,true)
eq(pp.clip.shown,false,"readable second wins again after combat")
player._secondaryMode="race"
player._raceBaselineActive=true
player._ghostActive=true
R.UpdateNativeSecondProbe(player,true,false,true,true)
eq(pp.clip.shown,false,"Ghost static state suppresses native guess")
player._ghostActive=false
player._formStateActive=true
R.UpdateNativeSecondProbe(player,true,false,true,true)
eq(pp.clip.shown,false,"stance/form state suppresses native guess")
player._formStateActive=false
R.UpdateNativeSecondProbe(player,true,false,true,false)
eq(pp.clip.shown,false,"unproven player identity cannot use ribbon")
R.UpdateNativeSecondProbe(player,true,true,true,true)
eq(pp.clip.shown,false,"hostile relation cannot masquerade as self")
R.UpdateNativeSecondProbe(player,false,false,true,true)
eq(pp.clip.shown,false,"ineligible player frame hides ribbon")
combat=false

R.ReleaseNativeSecondProbe(player)
eq(pp.container.enabled,false,"player native groups disabled on release")
eq(pp.container.unit,"player","native SetUnit token stays valid across release")
eq(player._nativeSecondProbe,nil,"player native host state released")

-- If the player was first initialized during combat, no protected frame
-- construction is attempted; the next ordinary OOC refresh constructs it.
local late={unit="player",portrait=frame("portrait"),
    secondaryBadge=frame("badge"),_assistable=true,
    _secondaryMode="race",_raceBaselineActive=true}
late.unitFrame=frame("native player")
combat=true
R.UpdateNativeSecondProbe(late,true,false,true,true)
eq(late._nativeSecondProbe,nil,"combat lock prevents player construction")
combat=false
R.UpdateNativeSecondProbe(late,true,false,true,true)
eq(late._nativeSecondProbe~=nil,true,"OOC player refresh retries without command")
R.ReleaseNativeSecondProbe(late)

R.db.enabled=false
eq(R.CreateNativeSecondProbe(host),false,"global addon off creates no groups")
R.UpdateNativeSecondProbe(host,true,true,true,false)
eq(host._nativeSecondProbe,nil,"disabled addon never auto-allocates")
R.db.enabled=true
R.db.secondaryPortrait=false
R.UpdateNativeSecondProbe(host,true,true,true,false)
eq(host._nativeSecondProbe,nil,"secondary disabled skips auto setup")
R.db.secondaryPortrait=true
-- Focus has the same native second-cell fallback as Target. This fixes
-- mixed DMF-like helpful buffs on a Focus which was never supported by the
-- original hostile-only/native Target prototype.
local focus={unit="focus",portrait=frame("portrait"),
    secondaryBadge=frame("badge"),_secondaryMode="race",
    _raceBaselineActive=true}
focus.unitFrame=frame("native focus")
R.UpdateNativeSecondProbe(focus,true,false,true,true)
local fp=focus._nativeSecondProbe
eq(fp~=nil,true,"friendly Focus constructs its own native second")
eq(fp.clip.shown,true,"Focus race fallback can show native second")
eq(fp.container.enabled,true,"first Focus build enables real secure second-aura groups")
local focusBroad
for _,g in ipairs(fp.container.groups) do
    if g.key==fp.hostileHelpfulKey then focusBroad=g;break end
end
eq(focusBroad.enabled,false,"friendly Focus suppresses duplicate-prone group")
eq(fp.container.unit,"focus","ordinary Focus native source is focus")
eq(fp.clip.points[3],"TOPLEFT","Focus native circle uses shared upper-left corner")
eq(fp.clip.points[4],10,"Focus native uses shared inset")
eq(fp.clip.points[5],12,"Focus native uses shared lift")
eq(fp.groups,p.groups,"Focus uses the existing complete tier policy")
focus._secondaryMode="aura"
R.UpdateNativeSecondProbe(focus,true,false,true,true)
eq(fp.clip.shown,false,"completed readable Focus second stays authoritative")
focus._secondaryMode="race"
R.UpdateNativeSecondProbe(focus,true,false,true,true)
eq(fp.clip.shown,true,"Focus native fallbacks return when index unavailable")

-- Positively verified self Focus/Target can bind their native groups to
-- the self-readable "player" token without changing their frame geometry.
selfAliases.focus=true
R.UpdateNativeSecondProbe(focus,true,false,true,true)
eq(fp.boundUnit,"player","self Focus binds native player aura source")
eq(fp.container.unit,"player","Focus native container receives verified alias")
eq(fp.clip.shown,true,"self Focus still exposes native second")

-- A target swap in combat is not permission to show the previous PLAYER'S
-- aura over another target. Hide until the native setter can safely rebind.
combat=true
selfAliases.focus=false
R.UpdateNativeSecondProbe(focus,true,false,true,true)
eq(fp.clip.shown,false,"combat identity switch suppresses stale second")
eq(fp.boundUnit,"player","protected native binding is not mutated in combat")
eq(focus._nativeSecondProbeReason,"source-rebind-deferred-combat",
    "unsafe focus rebind has an explicit fail-closed outcome")
combat=false
R.UpdateNativeSecondProbe(focus,true,false,true,true)
eq(fp.boundUnit,"focus","out of combat Focus source safely rebound")
eq(fp.container.unit,"focus","Focus native unit uses correct post-swap token")
eq(fp.clip.shown,true,"focus native fallback recovers after safe rebind")
R.ReleaseNativeSecondProbe(focus)
eq(fp.container.enabled,false,"released Focus group is disabled and cleared")
eq(fp.container.unit,"focus","released Focus token stays string-typed")

local selfTarget={unit="target",portrait=frame("portrait"),
    secondaryBadge=frame("badge"),_secondaryMode="race",
    _raceBaselineActive=true}
selfTarget.unitFrame=frame("native target")
selfAliases.target=true
R.UpdateNativeSecondProbe(selfTarget,true,false,true,true)
eq(selfTarget._nativeSecondProbe.boundUnit,"player",
    "self Target native renderer uses the verified player source")
eq(selfTarget._nativeSecondProbe.clip.points[3],"TOPLEFT",
    "self Target native second also avoids combo-point column")
eq(selfTarget._nativeSecondProbe.clip.points[4],10,
    "self Target uses +10 left-corner x offset")
eq(selfTarget._nativeSecondProbe.clip.points[5],12,
    "self Target also keeps +12px upper lift")
R.ReleaseNativeSecondProbe(selfTarget)
selfAliases.target=false

-- Actual main election and native handoff. Mark refreshes after Fortitude
-- without receiving a newer instance ID. The sealed harmful list prevents a
-- public runner-up, while the helpful primary remains positively observable.
do
    assert(loadfile("AuraEngine.lua"))("bjarkiPortraits",BP)
    assert(loadfile("SecondaryPortrait.lua"))("bjarkiPortraits",BP)
    combat=true
    UnitExists=function()return true end
    UnitCanAssist=function()return true end
    UnitIsPlayer=function()return true end
    UnitIsGhost=function()return false end
    UnitRace=function()return "Human","Human" end
    UnitSex=function()return 2 end
    GetTime=function()return 80 end
    local mark={spellId=1126,auraInstanceID=100,icon=12,duration=1800,expirationTime=1890,isNameplateOnly=false}
    local fort={spellId=1243,auraInstanceID=200,icon=24,duration=1800,expirationTime=1885,isNameplateOnly=false}
    local list={mark,fort}
    C_UnitAuras={GetAuraDataByIndex=function(_,index,filter)
        if filter:sub(1,7)=="HELPFUL" then return list[index] end
        error("unreadable harmful stream")
    end}
    local function region()
        local obj=frame("region")
        function obj:SetTexture()return true end
        function obj:Clear()end
        function obj:SetCooldown()end
        return obj
    end
    local own=region(); own.icon=region(); own.cooldown=region()
    local h={unit="player",unitFrame=frame("real player"),_buildComplete=true,
        containers={},cooldowns={},readableBaselineFrame=own,secondaryBadge=region(),
        secondaryCooldown=region(),racePortrait=region(),_nativeSecondProbe={
        ready=true,clip=region(),container={},boundUnit="player",boundGUID=guidByUnit.player,
        decimals=R.db.showDecimals,cooldowns={},hostileHelpfulEnabled=false}}
    h.unitFrame.unit="player"
    for i=1,#R.TIERS do h.containers[i]={SetEnabled=function()end,SetShown=function()end} end
    R.hosts.player=h
    R.UpdateHost(h)
    eq(h._baselineSpellID,1126,"application-time winner is refreshed Mark")
    eq(h._nativeSecondProbe.clip.shown,false,"the same Mark in reverse-instance second cannot cover race")
    list[3]={spellId=6673,auraInstanceID=300,icon=66,duration=1800,expirationTime=1884,isNameplateOnly=false}
    R.UpdateHost(h)
    eq(h._nativeSecondProbe.clip.shown,true,"different firsts can still agree on the distinct second Fortitude")
    list[4]={spellId=17,auraInstanceID=400,icon=17,duration=30,expirationTime=100,isNameplateOnly=false}
    R.UpdateHost(h)
    eq(h._nativeSecondProbe.clip.shown,false,"one higher native-only aura makes the lane's FIRST supply global second")
    list[3]={spellId=22812,auraInstanceID=500,icon=22812,duration=30,expirationTime=100,isNameplateOnly=false}
    R.UpdateHost(h)
    eq(h._nativeSecondProbe.clip.shown,true,"two higher native-only auras exclude an unrelated lower recency conflict")
    list[4]=nil
    list[3]=nil
    mark.expirationTime=1884
    R.UpdateHost(h)
    eq(h._baselineSpellID,1243,"ordinary instance order now agrees with application time")
    eq(h._nativeSecondProbe.clip.shown,true,"matching known order preserves native combat projection")
    list[1]={spellId=1243,auraInstanceID=100,icon=24,duration=1800,expirationTime=1884,isNameplateOnly=false}
    R.UpdateHost(h)
    eq(h._nativeSecondProbe.clip.shown,false,"positive duplicate in readable polarity rejects repeating Fortitude")
    combat=false
    local clip=h._nativeSecondProbe.clip
    local hideBefore=clip.Hide
    clip.Hide=function()error("temporary native hide failure")end
    eq(R.DestroyHost("player"),false,"host destruction defers if the overlay cannot be revoked")
    eq(R.hosts.player,h,"destroy keeps recovery ownership until the viewport is hidden")
    clip.Hide=hideBefore
    h._nativeSecondProbe.container.SetEnabled=function()end
    eq(R.DestroyHost("player"),true,"safe retry completes host destruction")
end
do
    -- Fresh module queue, with the pinned native allocation of TEN buttons
    -- per group even though only two may be displayed.
    assert(loadfile("NativeSecondProbe.lua"))("bjarkiPortraits",BP)
    local callbacks={};local allocated=0;local declineGroup
    local function schedule(delay,callback)
        eq(delay,.01,"construction uses a positive deferred delay")
        callbacks[#callbacks+1]=callback
    end
    C_Timer={After=schedule}
    local originalCreate=CreateFrame
    CreateFrame=function(...)
        local f=originalCreate(...)
        if f.kind=="AuraContainer" then
            local add=f.AddAuraGroup
            local enable=f.SetEnabled
            f.SetEnabled=function(self,enabled)
                assert(not combat,"construction/release never writes native groups in combat")
                return enable(self,enabled)
            end
            f.AddAuraGroup=function(self,key,filter,options)
                allocated=allocated+1
                local initialize=options.initializeFrame
                options.initializeFrame=function(button)
                    initialize(button)
                    for i=2,10 do initialize(frame("button",self))end
                end
                local result=add(self,key,filter,options)
                if declineGroup then declineGroup=false;return false end
                return result
            end
        end
        return f
    end
    local owners={}
    R.Refresh=function(unit,force)
        eq(force,true,"completed tree gets fresh recipient evidence")
        local h=R.hosts[unit]
        if h then h.finished=(h.finished or 0)+1;R.UpdateNativeSecondProbe(h,true,unit~="player",true,unit=="player")end
    end
    for _,unit in ipairs({"player","target","focus"})do
        local h={unit=unit,unitFrame=frame(unit),portrait=frame("portrait"),secondaryBadge=frame("badge"),_assistable=true}
        owners[#owners+1]=h;R.hosts[unit]=h
        R.UpdateNativeSecondProbe(h,true,unit~="player",true,unit=="player")
    end
    eq(allocated,0,"eligible target event never allocates a full native strip")
    eq(#callbacks,1,"all three hosts share one scheduled construction pump")
    for i=1,3 do
        local before=allocated;table.remove(callbacks,1)()
        eq(allocated-before,1,"one native group per deferred turn globally")
        eq(owners[i]._nativeSecondProbe.groups,1,"fair queue advances each host")
        eq(#owners[i]._nativeSecondProbe.cooldowns,10,"native batch size is modeled accurately")
        eq(owners[i]._nativeSecondProbe.clip.shown,false,"partial strip is never exposed")
    end
    combat=true
    local before=allocated;table.remove(callbacks,1)()
    eq(allocated,before,"combat parks construction without protected writes")
    eq(#callbacks,0,"combat does not self-poll")
    combat=false
    R.UpdateNativeSecondProbe(owners[1],true,false,true,true)
    eq(#callbacks,1,"existing safe update resumes the global queue")
    local retired=owners[2];local partial=retired._nativeSecondProbe
    assert(R.ReleaseNativeSecondProbe(retired));R.hosts.target=nil
    local turns=0
    while #callbacks>0 do
        turns=turns+1;assert(turns<200)
        before=allocated;table.remove(callbacks,1)()
        assert(allocated-before<=1,"cancelled jobs never exceed the global budget")
    end
    eq(partial.groups,1,"retired ownership cancels outstanding construction")
    eq(retired.finished,nil,"retired host cannot be refreshed by its old callback")
    for _,index in ipairs({1,3})do
        local h=owners[index];eq(h._nativeSecondProbe.ready,true,"active tree eventually completes")
        eq(#h._nativeSecondProbe.cooldowns,h._nativeSecondProbe.groups*10,"all native groups retain their complete batches")
        eq(h.finished,1,"completion reconciles current evidence once")
    end
    local rebound={unit="target",unitFrame=frame("target"),portrait=frame("new portrait"),secondaryBadge=frame("badge")}
    R.hosts.target=rebound
    R.UpdateNativeSecondProbe(rebound,true,true,true,false)
    eq(rebound._nativeSecondProbe,partial,"partial pooled tree resumes under its new owner")
    R.db.secondaryPortrait=false;before=allocated;table.remove(callbacks,1)()
    eq(allocated,before,"disabling during construction cancels queued allocation")
    eq(#callbacks,0,"disabled queue has no idle polling")
    R.db.secondaryPortrait=true;guidByUnit.target="Creature-ChangedDuringConstruction"
    R.UpdateNativeSecondProbe(rebound,true,true,true,false)
    while #callbacks>0 do table.remove(callbacks,1)()end
    eq(rebound._nativeSecondProbe.boundGUID,guidByUnit.target,"completion binds the latest recipient rather than captured evidence")
    eq(retired.finished,nil,"pool takeover never revives the retired owner")

    -- A declined/synchronous scheduler leaves recoverable ownership without
    -- recursively draining the queue or trusting a callback it rejected.
    assert(loadfile("NativeSecondProbe.lua"))("bjarkiPortraits",BP)
    local rejectedCallback
    C_Timer.After=function(_,callback)rejectedCallback=callback;return false end
    local retry={unit="focus",unitFrame=frame("focus"),portrait=frame("portrait"),secondaryBadge=frame("badge")}
    R.hosts.focus=retry;before=allocated
    R.UpdateNativeSecondProbe(retry,true,true,true,false)
    eq(allocated,before,"declined scheduling performs no synchronous construction")
    C_Timer.After=schedule;R.UpdateNativeSecondProbe(retry,true,true,true,false)
    rejectedCallback();eq(allocated,before,"stale rejected callback cannot consume a newer queue ticket")
    table.remove(callbacks,1)();eq(allocated,before+1,"next safe opportunity recovers declined scheduling")
    combat=true;assert(R.ReleaseNativeSecondProbe(retry))
    table.remove(callbacks,1)();combat=false
    eq(#callbacks,0,"combat release leaves no construction polling")
    eq(retry._nativeSecondProbe,nil,"combat release cancels its queue owner")

    assert(loadfile("NativeSecondProbe.lua"))("bjarkiPortraits",BP)
    C_Timer.After=function(_,callback)callback()end
    local synchronous={unit="focus",unitFrame=frame("focus"),portrait=frame("portrait"),secondaryBadge=frame("badge")}
    R.hosts.focus=synchronous;before=allocated
    R.UpdateNativeSecondProbe(synchronous,true,true,true,false)
    eq(allocated,before,"synchronous callbacks cannot cause an allocation burst")
    C_Timer.After=schedule;R.UpdateNativeSecondProbe(synchronous,true,true,true,false)
    declineGroup=true;table.remove(callbacks,1)()
    eq(synchronous._nativeSecondProbe.groups,0,"declined partial group remains uncommitted")
    eq(#synchronous._nativeSecondProbe.cooldowns,10,"declined setter retains its initialized native batch")
    before=allocated
    R.UpdateNativeSecondProbe(synchronous,true,true,true,false)
    eq(#callbacks,0,"ordinary events do not spin a failed native setter")
    R.UpdateNativeSecondProbe(synchronous,true,true,true,false,true)
    table.remove(callbacks,1)()
    eq(allocated,before,"safe retry repairs the registered group without another native batch")
    eq(synchronous._nativeSecondProbe.groups,1,"registered group commits after its layout repair")
    synchronous.unitFrame.shown=false;table.remove(callbacks,1)()
    eq(allocated,before,"hidden native owner cancels unfinished construction")
    eq(#callbacks,0,"hidden native owner does not keep the queue alive")
    CreateFrame=originalCreate
end
do
    -- The pinned provider calls TEN initializers through securecallfunction
    -- before registering the group. A callback error does not fail AddAuraGroup.
    -- Reproduce that boundary with the real Refresh/UpdateHost completion path.
    for _,reuse in ipairs({false,true}) do
        assert(loadfile("NativeSecondProbe.lua"))("bjarkiPortraits",BP)
        assert(loadfile("AuraEngine.lua"))("bjarkiPortraits",BP)
        local callbacks,buttons={},{}
        local allocated,failedButton,failedClock=0,nil,nil
        local denied=true
        local originalCreate=CreateFrame
        CreateFrame=function(kind,...)
            local f=originalCreate(kind,...)
            if kind=="Cooldown" and f.parent==failedButton then failedClock=f end
            if kind=="AuraContainer" then
                f.AddAuraGroup=function(self,key,filter,options)
                    assert(not combat,"native construction stays out of combat")
                    allocated=allocated+1
                    for i=1,10 do
                        local b=frame("button",self);buttons[#buttons+1]=b
                        if allocated==1 and i==9 then
                            failedButton=b
                            local setter,mask=b.SetDurationCooldown,b.CreateMaskTexture
                            b.SetDurationCooldown=function(self,clock)
                                assert(not combat,"initializer recovery stays out of combat")
                                if denied then error("injected native receiver failure") end
                                return setter(self,clock)
                            end
                            b.CreateMaskTexture=function(self,...)
                                self.maskAllocations=(self.maskAllocations or 0)+1
                                return mask(self,...)
                            end
                        end
                        pcall(options.initializeFrame,b) -- secure native error isolation
                    end
                    self.groups=self.groups or {}
                    self.groups[#self.groups+1]={key=key,filter=filter,options=options,enabled=true}
                end
            end
            return f
        end
        C_Timer={After=function(delay,cb)
            eq(delay,.01,"recovery shares the bounded native construction queue")
            callbacks[#callbacks+1]=cb
        end}
        combat=false
        R.db.enabled,R.db.secondaryPortrait=true,true
        UnitExists=function()return true end
        UnitCanAssist=function()return false end
        UnitIsPlayer=function()return false end
        UnitIsGhost=function()return false end
        GetTime=function()return 100 end
        C_UnitAuras={GetAuraDataByIndex=function()return nil end}
        local h
        local function owner()
            local result={unit="target",unitFrame=frame("target"),portrait=frame("portrait"),
                secondaryBadge=frame("badge"),_buildComplete=true,containers={},cooldowns={}}
            result.unitFrame.unit="target"
            for i=1,#R.TIERS do result.containers[i]=frame("AuraContainer")end
            return result
        end
        h=owner();R.hosts.target=h
        R.GetPortrait=function()return h.portrait,nil,h.unitFrame,true end
        R.Refresh("target")
        table.remove(callbacks,1)()
        local p=h._nativeSecondProbe
        eq(p.groups,0,"a swallowed initializer failure cannot commit its native group")
        eq(p.ready,false,"unfinished native recipients are not ready")
        eq(p.clip.shown,false,"unfinished native recipients stay hidden")
        eq(p.container.enabled,false,"unfinished native recipients stay disabled")
        eq(#callbacks,0,"a failed initializer never starts a background retry loop")
        eq(failedButton.cooldown,nil,"injection left the real native receiver unfinished")
        local icon,border=failedButton.textures[1],failedButton.textures[2]
        R.Refresh("target")
        eq(#callbacks,0,"ordinary aura refresh does not spin the failed initializer")
        denied=false;combat=true;R.Refresh("target",true)
        eq(#callbacks,0,"combat leaves recovery for a safe construction opportunity")
        combat=false;R.Refresh("target",true)
        if reuse then
            local retired=h
            assert(R.ReleaseNativeSecondProbe(retired))
            h=owner();R.hosts.target=h
            R.Refresh("target")
            eq(h._nativeSecondProbe,p,"pooled owner retains the unfinished native batch")
            eq(retired._nativeSecondProbe,nil,"retired host cannot own pending repair")
        end
        local before=allocated
        table.remove(callbacks,1)()
        eq(allocated,before,"repair reuses the registered group's native buttons")
        eq(failedButton.cooldown,failedClock,"repair binds the original native cooldown")
        eq(failedButton.textures[1],icon,"repair reuses original native artwork")
        eq(failedButton.textures[2],border,"repair reuses original native border")
        eq(#failedButton.textures,2,"repair cannot accumulate duplicate artwork")
        eq(failedButton.maskAllocations,1,"repair cannot accumulate duplicate masks")
        eq(p.clip.shown,false,"remaining native groups still gate presentation")
        guidByUnit.target="Creature-Repaired-"..tostring(reuse)
        while #callbacks>0 do
            before=allocated;table.remove(callbacks,1)()
            assert(allocated-before<=1,"repair never bypasses one group per callback")
        end
        eq(p.ready,true,"the repaired native tree completes")
        eq(p.boundGUID,guidByUnit.target,"real completion refresh binds current recipient")
        eq(p.clip.shown,true,"only a complete native tree is presented")
        eq(#p.cooldowns,#buttons,"repaired native clocks are registered once")
        local seen={}
        for _,clock in ipairs(p.cooldowns)do assert(not seen[clock]);seen[clock]=true end
        for _,button in ipairs(buttons)do assert(button.cooldown,"every allocated button has its native receiver")end
        eq(failedClock.attachCalls,nil,"initializer recovery does not add a duration bridge")
        CreateFrame=originalCreate
    end
end
print("native runner-up ribbon: "..checks.." inbound/safety checks passed")
