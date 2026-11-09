-- Native aura-present pet-family secondary, using the real PetPortraits
-- classification/texture code and native group *inbound* call shape.
-- These mocks test verified identity, lifecycle and presentation policy;
-- only the live Forever client can prove secret-group button rendering.
local BP={Runtime={}}
assert(loadfile("Core.lua"))("bjarkiPortraits",BP)
local R=BP.Runtime
R.db={enabled=true,secondaryPortrait=true,petPortraits=true}
R.AURA_ANCHOR_TEMPLATE="DisableUntrustedLayoutScriptsTemplate"
R.SORT_METHOD=1
R.SORT_DIRECTION=2
R.CanAccess=function(v) return v~="SECRET" end
R.IsSecret=function(v) return v=="SECRET" end
R.SafeBool=function(fn,...)
    if type(fn)~="function" then return nil,false end
    local ok,val=pcall(fn,...)
    return val,ok and type(val)=="boolean" and R.CanAccess(val)
end
R.SafeString=function(fn,...)
    if type(fn)~="function" then return nil,false end
    local ok,val=pcall(fn,...)
    return val,ok and type(val)=="string" and R.CanAccess(val)
end

local checks=0
local function eq(actual,want,label)
    assert(actual==want,(label or "mismatch")..": "..tostring(actual)..
        " vs "..tostring(want))
    checks=checks+1
end

local actor={kind="hunter",family="Owl",familyID=26,guid="Pet-First",
    auraHelpful=0,auraHarmful=0}
UnitCreatureType=function(unit)
    if actor.kind=="totem" then return "Totem",11 end
    return "Beast",1
end
UnitCreatureFamily=function(unit)
    return actor.family,actor.familyID
end
UnitIsUnit=function() return false end
UnitIsOtherPlayersPet=function()
    return actor.kind=="hunter" or actor.kind=="warlock"
end
UnitPlayerControlled=function()
    return actor.kind=="hunter" or actor.kind=="warlock"
end
UnitGUID=function() return actor.guid end
C_CreatureInfo={
    GetCreatureFamilyInfo=function(id)
        if id==26 then return {iconFile=920026,name="Owl"} end
        if id==7 then return {iconFile=920007,name="Carrion Bird"} end
    end,
}
C_Spell={GetSpellTexture=function(id) return id+100000 end}

-- PetPortraits obtains the same confirmed family art used by the main
-- portrait, without returning generic Growl for unrecognized pets.
assert(loadfile("PetPortraits.lua"))("bjarkiPortraits",BP)
local art,guid,reason=R.ResolveObservedPetSecondaryArt("target")
eq(art,920026,"Hunter pet uses actual family portrait icon")
eq(guid,"Pet-First","target pet identity accompanies art")
eq(reason,"confirmed-pet-family","no inferred pet type")
eq(select(1,R.ResolveObservedPetSecondaryArt("pet")),nil,
    "local PetFrame does not gain a secondary")

local combat=false
InCombatLockdown=function() return combat end

local function frame(kind,parent)
    local o={kind=kind,parent=parent,shown=true}
    function o:Show() self.shown=true end
    function o:Hide() self.shown=false end
    function o:SetSize(w,h) self.width,self.height=w,h end
    function o:SetPoint(...) self.points={...} end
    function o:ClearAllPoints()self.points={}end
    function o:SetFrameStrata(v)self.strata=v end
    function o:GetFrameStrata()return self.strata or "HIGH" end
    function o:SetFrameLevel(v)self.level=v end
    function o:GetFrameLevel()return self.level or 40 end
    function o:EnableMouse(v)self.mouse=v end
    function o:SetAlpha(v)self.alpha=v end
    function o:CreateTexture()
        self.textures=self.textures or {}
        local texture=frame("texture",self)
        self.textures[#self.textures+1]=texture
        return texture
    end
    function o:CreateMaskTexture()return frame("mask",self)end
    function o:SetTexture(v)self.texture=v;return true end
    function o:SetAtlas(v)self.atlas=v end
    function o:SetAllPoints()self.allPoints=true end
    function o:AddMaskTexture(v)self.mask=v end
    function o:SetIcon(v)self.icon=v end
    function o:SetUnit(u)
        self.unit=u
        for _,group in ipairs(self.groups or {}) do
            local present=u and (group.filter:sub(1,7)=="HELPFUL"
                and actor.auraHelpful>0 or
                group.filter:sub(1,7)=="HARMFUL" and actor.auraHarmful>0)
            group.button.shown=present and true or false
        end
    end
    function o:AddAuraGroup(key,filter,options)
        self.groups=self.groups or {}
        local button=frame("button",self)
        options.initializeFrame(button)
        self.groups[#self.groups+1]={key=key,filter=filter,
            options=options,button=button}
        button:Hide() -- batch created, no current aura assigned
    end
    return o
end
UIParent=frame("UIParent")
CreateFrame=function(kind,_,parent,template)
    local f=frame(kind,parent)
    f.template=template
    return f
end

assert(loadfile("PetSecondary.lua"))("bjarkiPortraits",BP)

local function host(unit)
    local h={unit=unit,portrait=frame("portrait"),
        secondaryBadge=frame("secondary")}
    h.secondaryBadge:SetFrameLevel(48)
    return h
end
local h=host("target")
R.UpdatePetSecondaryFallback(h,true)
local st=h._petSecondaryFallback
eq(st~=nil,true,"verified Target pet automatically constructs family gate")
eq(st.ready,true,"both native aura groups constructed")
eq(st.guid,"Pet-First","current GUID tracked")
eq(st.art,920026,"pet art stored independently of aura identity")
eq(st.root.shown,true,"family fallback viewport is active")
eq(st.root.points[3],"TOPLEFT",
    "Target pet-family secondary shares combo-safe top-left location")
eq(st.root.points[4],10,"Target pet-family x offset matches normal badge")
eq(st.root.points[5],12,"Target pet-family y lift matches native second")
eq(st.root.level<48,true,"family art stays below a public second aura")
eq(st.root.width,44,"pet badge outer viewport enlarged to 44px")
eq(#st.containers,2,"helpful and harmful have separate native gates")
eq(#st.textures,2,"two group buttons have current pet artwork")
for _,image in ipairs(st.textures) do
    eq(image.width,31,"pet-family icon grows with secondary circle")
    eq(image.mask~=nil,true,"pet-family icon retains circular mask")
end
for _,c in ipairs(st.containers) do
    eq(c.unit,"target","native group bound to current target")
    eq(#c.groups,1,"one group per native container")
    eq(c.groups[1].options.maxFrameCount,1,
        "presence gate never claims more than first aura")
    eq(c.groups[1].button.icon.alpha,0,
        "first aura icon cannot override family portrait")
    eq(c.groups[1].button.icon.width,1,
        "native receiver remains visually hidden")
    eq(c.groups[1].button.width,44,"entire conditional pet badge cell enlarged")
    eq(c.groups[1].button.textures[3].width,36,
       "conditional pet border really grows to 36px")
    eq(c.groups[1].button.textures[3].atlas,"UI-HUD-UnitFrame-TotemFrame",
       "conditional pet border retains native totem artwork")
end
eq(st.containers[1].groups[1].filter,"HELPFUL|INCLUDE_NAME_PLATE_ONLY",
    "helpful native presence includes nameplate-only")
eq(st.containers[2].groups[1].filter,"HARMFUL|INCLUDE_NAME_PLATE_ONLY",
    "harmful native presence includes nameplate-only")

-- Naked: neither native group draws any button; no second circle is shown.
eq(st.containers[1].groups[1].button.shown,false,"naked pet has no helpful art")
eq(st.containers[2].groups[1].button.shown,false,"naked pet has no harmful art")
-- Native engine can assign a button after a secret combat debuff, WITHOUT
-- requiring a Lua aura scan or any UI toggling.
actor.auraHarmful=1
st.containers[2]:SetUnit("target") -- simulated native aura assignment
eq(st.containers[2].groups[1].button.shown,true,
    "one harmful aura reveals family circle")
eq(st.containers[1].groups[1].button.shown,false,
    "other polarity remains empty")
actor.auraHelpful=1
st.containers[1]:SetUnit("target")
eq(st.containers[1].groups[1].button.shown,true,
    "helpful aura also gates the same family artwork")
actor.auraHelpful,actor.auraHarmful=0,0
for _,c in ipairs(st.containers) do c:SetUnit("target") end
eq(st.containers[1].groups[1].button.shown,false,
    "buff removal clears helpful native family art")
eq(st.containers[2].groups[1].button.shown,false,
    "debuff removal clears harmful native family art")

-- Reassignment to another pet family changes the art only at a safe
-- out-of-combat boundary and retains the two native filters.
actor.family,actor.familyID,actor.guid="Carrion Bird",7,"Pet-Second"
R.UpdatePetSecondaryFallback(h,true)
eq(st.guid,"Pet-Second","new target pet GUID replaces prior occupant")
eq(st.art,920007,"new pet family icon replaces prior bird family")
for _,icon in ipairs(st.textures) do
    eq(icon.texture,920007,"all preallocated aura frames receive new art")
end
-- If that reassignment happens during combat, never display old family art.
combat=true
actor.family,actor.familyID,actor.guid="Owl",26,"Pet-Third"
R.UpdatePetSecondaryFallback(h,true)
eq(st.root.shown,false,"combat swap hides stale family art immediately")
eq(h._petSecondaryReason,"family-change-deferred-combat",
    "protected family change recorded without forcing native writes")
combat=false
R.UpdatePetSecondaryFallback(h,true)
eq(st.root.shown,true,"safe OOC refresh automatically restores pet art")
eq(st.guid,"Pet-Third","restored pet has correct identity")
eq(st.art,920026,"restored pet has correct family")
-- Warlock pets use verified demon summon artwork instead of Hunter family
-- art. This is the same distinction as the pre-existing pet foundation.
actor.kind="warlock"; actor.family="Felhunter"; actor.familyID=15
actor.guid="Pet-Felhunter"
R.UpdatePetSecondaryFallback(h,true)
eq(st.art,100691,"Warlock Felhunter uses its summon portrait art")
eq(st.guid,"Pet-Felhunter","Warlock pet GUID is tracked")
for _,icon in ipairs(st.textures) do
    eq(icon.texture,100691,"native pet gates update to Warlock artwork")
end
actor.kind="hunter"; actor.family="Owl"; actor.familyID=26
actor.guid="Pet-BackToOwl"
R.UpdatePetSecondaryFallback(h,true)
eq(st.art,920026,"Hunter art restored after Warlock target handoff")

-- No fake pet portrait for a wild creature, minion/totem or unknown family.
actor.kind="wild"; actor.guid="Creature-Wild"
R.UpdatePetSecondaryFallback(h,true)
eq(st.root.shown,false,"wild beast never receives player pet fallback")
actor.kind="totem"
R.UpdatePetSecondaryFallback(h,true)
eq(st.root.shown,false,"totem never receives pet family fallback")
actor.kind="hunter";actor.family="Unknown";actor.familyID=999
R.UpdatePetSecondaryFallback(h,true)
eq(st.root.shown,false,"unknown Hunter family does not show Growl guess")
actor.family="Owl";actor.familyID=26
actor.guid="SECRET"
R.UpdatePetSecondaryFallback(h,true)
eq(st.root.shown,false,"unreadable identity never keeps stale pet art")
actor.guid="Pet-Fourth"
R.db.petPortraits=false
R.UpdatePetSecondaryFallback(h,true)
eq(st.root.shown,false,"user's existing pet portraits preference respected")
R.db.petPortraits=true
R.UpdatePetSecondaryFallback(h,false)
eq(st.root.shown,false,"hidden/disabled Target frame cannot show pet art")
R.UpdatePetSecondaryFallback(h,true)
eq(st.root.shown,true,"verified live pet recovers on next enabled update")

R.ReleasePetSecondaryFallback(h)
eq(h._petSecondaryFallback,nil,"old host loses art ownership")
eq(st.root.shown,false,"pooled state hidden on teardown")
for _,c in ipairs(st.containers) do
    eq(c.unit,nil,"pooled native group never retains previous target")
end
local focus=host("focus")
R.UpdatePetSecondaryFallback(focus,true)
eq(focus._petSecondaryFallback,st,
    "Focus reuses existing pooled native family gate")
eq(st.containers[1].unit,"focus","reused family gate follows Focus unit token")
R.ReleasePetSecondaryFallback(focus)
local notSupported=host("targettarget")
R.UpdatePetSecondaryFallback(notSupported,true)
eq(notSupported._petSecondaryFallback,nil,"ToT stays excluded")
print("Native pet secondary presence: "..checks.." assertions passed")
