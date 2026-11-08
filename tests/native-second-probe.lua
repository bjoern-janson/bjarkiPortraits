-- Native second-slot probe: source-backed shape and safety tests.
-- This models addon inbound calls, NOT Blizzard's secure layout itself.
-- The critical client experiment is whether grouped secret buttons flow
-- correctly through the fixed second-cell clipping viewport.
local BP={Runtime={}}
assert(loadfile("Spells.lua"))("bjarkiPortraits", BP)
assert(loadfile("Priority.lua"))("bjarkiPortraits", BP)
local R=BP.Runtime
-- Persisted 0.1.195 off state must not require an in-game re-enable.
R.db={enabled=true,secondaryPortrait=true,nativeSecondProbe=false}
local combat=false
InCombatLockdown=function() return combat end
R.SafeBool=function(fn,...)
    if type(fn)~="function" then return nil,false end
    local ok,value=pcall(fn,...)
    return value,ok and type(value)=="boolean"
end
R.CanAccess=function(v) return v ~= "SECRET" end
R.ApplyCountdownFormat=function()end
R.AURA_ANCHOR_TEMPLATE="DisableUntrustedLayoutScriptsTemplate"
R.SORT_METHOD=8
R.SORT_DIRECTION=1

local checks=0
local function eq(value,want,label)
    assert(value==want,(label or "comparison")..": "..tostring(value).." versus "..tostring(want))
    checks=checks+1
end

local function frame(kind,parent)
    local o={kind=kind,parent=parent,shown=true}
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
    function o:SetUnit(v)self.unit=v end
    function o:CreateTexture() return frame("texture",self) end
    function o:CreateMaskTexture() return frame("mask",self) end
    function o:SetAtlas(v)self.atlas=v end
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
        self.groups[#self.groups+1]={key=key,filter=filter,options=options}
        -- The engine preallocates a guarded batch of button frames. One mock
        -- button suffices to check the inbound geometry/wiring shape.
        local b=frame("button",self)
        options.initializeFrame(b)
        eq(b.width,37,"native button cell width")
        eq(b.icon.width,22,"native icon inner width")
        eq(b.cooldown~=nil,true,"native cooldown assigned")
        eq(b.icon.mask~=nil,true,"circular icon mask installed")
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

local host={unit="target",portrait=frame("portrait"),
    secondaryBadge=frame("badge")}
host.secondaryBadge.level=50
eq(host._nativeSecondProbe,nil,"no eager construction on load")
R.UpdateNativeSecondProbe(host,true,false,true,false)
eq(host._nativeSecondProbe,nil,"friendly target allocates no native groups")
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
eq(p.clip.clips,true,"fixed clipping viewport")
eq(p.clip.width,37,"one-cell aperture")
eq(p.container.points[4],-37,"the primary cell is outside viewport")
eq(p.container.unit,"target","native unit owns current target")
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

R.UpdateNativeSecondProbe(host,true,true,true,false)
eq(p.clip.shown,true,"verified NPC probe is shown")
eq(host.secondaryBadge.shown,false,"legacy badge hidden under native ribbon")
R.UpdateNativeSecondProbe(host,true,true,true,true)
eq(p.clip.shown,false,"hostile player excluded")
R.UpdateNativeSecondProbe(host,true,false,true,false)
eq(p.clip.shown,false,"friendly unit excluded")
R.UpdateNativeSecondProbe(host,false,true,true,false)
eq(p.clip.shown,false,"inactive host excluded")

R.ReleaseNativeSecondProbe(host)
eq(host._nativeSecondProbe,nil,"host releases native probe ownership")
eq(p.container.unit,nil,"pooled native group no longer binds prior target")
local other={unit="target",portrait=frame("portrait"),
    secondaryBadge=frame("badge")}
other.secondaryBadge.level=60
R.UpdateNativeSecondProbe(other,true,true,true,false)
eq(other._nativeSecondProbe,p,"next eligible target automatically reuses pooled probe")
eq(other._nativeSecondProbe.ready,true,"reused native strip is ready")
eq(p.clip.points[2],other.portrait,"reused probe anchors to current portrait")
R.ReleaseNativeSecondProbe(other)
R.db.enabled=false
eq(R.CreateNativeSecondProbe(host),false,"global addon off creates no groups")
R.UpdateNativeSecondProbe(host,true,true,true,false)
eq(host._nativeSecondProbe,nil,"disabled addon never auto-allocates")
R.db.enabled=true
R.db.secondaryPortrait=false
R.UpdateNativeSecondProbe(host,true,true,true,false)
eq(host._nativeSecondProbe,nil,"secondary disabled skips auto setup")
R.db.secondaryPortrait=true
local focus={unit="focus",portrait=frame("portrait"),
    secondaryBadge=frame("badge")}
eq(R.CreateNativeSecondProbe(focus),false,"experimental scope is target-only")
R.UpdateNativeSecondProbe(focus,true,true,true,false)
eq(focus._nativeSecondProbe,nil,"focus receives no native target ribbon")
print("native runner-up ribbon: "..checks.." inbound/safety checks passed")
