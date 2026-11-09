-- P1 portrait geometry/identity test against the actual secondary module.
-- Uses ordinary Lua mock frames, not a simulated second-winner election.
local checks = 0
local function eq(a,b,label)
    assert(a == b, (label or "value") .. ": got " .. tostring(a) .. " wanted " .. tostring(b))
    checks = checks + 1
end
local function fakeRegion(kind)
    local r = {kind=kind, points={}, shown=false, textSetterCount=0}
    function r:Hide() self.shown=false; self.hides=(self.hides or 0)+1 end
    function r:Show() self.shown=true; self.shows=(self.shows or 0)+1 end
    function r:SetSize(x,y) self.width=x; self.height=y end
    function r:SetFrameStrata(v) self.strata=v end
    function r:SetFrameLevel(v) self.frameLevel=v end
    function r:EnableMouse(v) self.mouseEnabled=v end
    function r:SetPoint(...) self.points[#self.points+1]={...} end
    function r:ClearAllPoints() self.points={} end
    function r:SetAllPoints(w) self.allPoints=w end
    function r:SetAtlas(v,size) self.atlas=v; self.atlasResize=size; self.coords=nil end
    function r:SetCooldown(start,duration) self.cooldownStart=start;self.cooldownDuration=duration end
    function r:Clear() self.cooldownDuration=0 end
    function r:SetDrawSwipe(v) self.swipe=v end
    function r:SetTexture(v) self.texture=v; self.textureWrites=(self.textureWrites or 0)+1; return true end
    function r:SetTexCoord(...) self.coords={...}; self.coordWrites=(self.coordWrites or 0)+1 end
    function r:AddMaskTexture(mask) self.mask=mask end
    function r:CreateTexture(_, layer) local c=fakeRegion("texture"); c.drawLayer=layer; return c end
    function r:CreateMaskTexture(_, layer) local c=fakeRegion("mask");c.drawLayer=layer;return c end
    function r:GetFrameLevel() return self.frameLevel or 2 end
    return r
end
UIParent = fakeRegion("ui-parent")
local creates = 0
CreateFrame = function(kind, _, parent, template)
    eq(template, kind == "Cooldown" and "CooldownFrameTemplate,DisableUntrustedLayoutScriptsTemplate"
        or "DisableUntrustedLayoutScriptsTemplate","safe layout template")
    creates=creates+1
    local r=fakeRegion("frame"); r.parent=parent
    return r
end
local BP={Runtime={db={secondaryPortrait=true}, AURA_ANCHOR_TEMPLATE="DisableUntrustedLayoutScriptsTemplate"}}
local R=BP.Runtime
R.CanAccess=function() return true end
R.ApplySecondaryCountdownFont=function(cooldown)
    cooldown._bjarkiUsesRegularBuffFont=true
    return true
end
local atlasByUnit = {
    player={"Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Races",{0,0.125,0,0.25},nil},
    target={"raceicon128-skyborne-female",nil,true},
    focus={nil,"skyborne-face-atlas-unavailable",nil},
    party1={"Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Races",{0,0.125,0,0.25},nil},
}
function R.ResolveRaceBaselineAtlas(unit, confirmed)
    eq(confirmed,true,"only verified player races")
    local a=atlasByUnit[unit] or {nil,"unknown-race",nil}
    return a[1],a[2],a[3]
end
assert(loadfile("SecondaryPortrait.lua"))("bjarkiPortraits",BP)
local function makeHost(unit)
    return {unit=unit,layer=fakeRegion("parent"),portrait=fakeRegion("native-portrait"),
        unitFrame=fakeRegion("native-unit")}
end
local player=makeHost("player")
eq(R.CreateSecondaryPortrait(player,"LOW"),true,"player badge built")
eq(player.secondaryBadge.width,44,"actual secondary circle enlarged to 44px")
eq(player.secondaryBorder.width,36,"actual secondary border enlarged to 36px")
eq(player.racePortrait.width,31,"secondary icon enlarged proportionally to 31px")
eq(player.secondaryCooldown._bjarkiUsesRegularBuffFont,true,
    "readable second countdown uses the same font as regular buff durations")
eq(player.secondaryBadge.strata,"MEDIUM","badge above the native frame strata")
eq(player.secondaryBadge.frameLevel,14,"above unit frame border")
eq(player.secondaryBadge.parent,UIParent,"badge is an unprotected UIParent sibling above native frame")
eq(player.secondaryBadge.points[1][3],"TOPLEFT","player badge faces outward, away from rested Z")
eq(player.secondaryBadge.points[1][4],5,"outer player badge inset avoids screen clipping")
eq(player.secondaryBadge.mouseEnabled,false,"no click interception")
eq(player.racePortrait.mask,player.secondaryMask,"circular icon mask")
eq(player.secondaryMask.atlas,"CircleMask","native circle mask")
eq(player.secondaryBorder.atlas,"UI-HUD-UnitFrame-TotemFrame","totem rim only")
eq(player.secondaryBadge.shown,false,"hidden before eligibility")
eq(player.secondaryCooldown.shown,false,"secondary cooldown hidden for race art")
R.UpdateSecondaryPortrait(player,true)
eq(player.secondaryBadge.shown,true,"verified race visible")
eq(player._secondaryMode,"race","race state")
eq(player.racePortrait.texture,atlasByUnit.player[1],"classic race sheet")
eq(player.racePortrait.coords[2],0.125,"correct eighth-sheet tile")
eq(player.portrait.texture,nil,"native portrait unchanged")
local n=player.racePortrait.textureWrites
R.UpdateSecondaryPortrait(player,true)
eq(player.racePortrait.textureWrites,n,"no redundant texture writes")
R.UpdateSecondaryPortrait(player,false)
eq(player.secondaryBadge.shown,false,"no race for unproven unit")
eq(player.racePortrait.texture,nil,"stale art cleared")
R.PreviewSecondaryPortrait(player)
eq(player._secondaryMode,"test-only","test icon clearly synthetic")
eq(player.secondaryBadge.shown,true,"test badge visible")
R.UpdateSecondaryPortrait(player,true)
eq(player._secondaryMode,"race","race restored after test")
R.db.secondaryPortrait=false
R.UpdateSecondaryPortrait(player,true)
eq(player.secondaryBadge.shown,false,"user setting suppresses badge")
R.db.secondaryPortrait=true
local target=makeHost("target")
R.CreateSecondaryPortrait(target,"LOW")
eq(target.secondaryBadge.points[1][3],"TOPRIGHT","target badge faces outward, away from target bars")
eq(target.secondaryBadge.points[1][4],-5,"outer target badge inset avoids screen clipping")
R.UpdateSecondaryPortrait(target,true)
eq(target.racePortrait.atlas,"raceicon128-skyborne-female","valid atlas retained")
eq(target.racePortrait.coords,nil,"do not overwrite atlas native UVs")
R.UpdateSecondaryPortrait(target,false)
eq(target.racePortrait.texture,nil,"race cleared after recycle")
local focus=makeHost("focus")
R.CreateSecondaryPortrait(focus,"LOW")
eq(focus.secondaryBadge.points[1][3],"TOPRIGHT","focus badge faces outward, away from name and bars")
R.UpdateSecondaryPortrait(focus,true)
eq(focus.secondaryBadge.shown,false,"unknown Skyborne face stays hidden")
eq(focus._raceBaselineReason,"skyborne-face-atlas-unavailable","missing art reason retained")
local party=makeHost("party1")
R.CreateSecondaryPortrait(party,"LOW")
eq(party.secondaryBadge.points[1][3],"TOPLEFT","party badge faces outward, away from leader marker")
eq(party.secondaryBadge.width,35,"compact secondary circle enlarged")
eq(party.secondaryBorder.width,29,"compact ring enlarged to 29px")
eq(party.racePortrait.width,25,"compact secondary artwork enlarged to 25px")
eq(party.secondaryCooldown._bjarkiUsesRegularBuffFont,true,
    "compact party secondary timer uses the same regular buff duration font")
-- Small ToT/ToF portraits keep their existing main aura presentation but
-- deliberately receive NO secondary circle, even during test mode.
local tot=makeHost("targettarget")
local tof=makeHost("focustarget")
eq(R.CreateSecondaryPortrait(tot,"LOW"),false,"ToT secondary excluded")
eq(R.CreateSecondaryPortrait(tof,"LOW"),false,"ToF secondary excluded")
eq(tot.secondaryBadge,nil,"no ToT badge allocated")
eq(tof.secondaryBadge,nil,"no ToF badge allocated")
R.ReconcileSecondaryPortrait(tot,true,true)
R.ReconcileSecondaryPortrait(tof,true,true)
R.PreviewSecondaryPortrait(tot)
R.PreviewSecondaryPortrait(tof)
eq(tot.secondaryBadge,nil,"ToT remains excluded after refresh")
eq(tof.secondaryBadge,nil,"ToF remains excluded after preview")
local pet=makeHost("pet")
eq(R.CreateSecondaryPortrait(pet,"LOW"),false,"pet excluded")
eq(pet.secondaryBadge,nil,"pet has no second circle")
local before=creates
R.UpdateSecondaryPortrait(pet,true)
eq(creates,before,"no pet badge work")
R.HideSecondaryPortrait(player,"host-destroy")
eq(player.secondaryBadge.shown,false,"host teardown hides badge")
eq(player.racePortrait.texture,nil,"host teardown clears race")
local oldBadge = player.secondaryBadge
R.ReleaseSecondaryPortrait(player)
eq(player.secondaryBadge,nil,"released host drops badge references")
local replacement=makeHost("target")
R.CreateSecondaryPortrait(replacement,"LOW")
eq(replacement.secondaryBadge,oldBadge,"pooled root badge reused instead of leaked")
eq(replacement.secondaryBadge.points[1][3],"TOPRIGHT","reused badge reanchors to target outer corner")
print("secondary portrait race prototype: " .. checks .. " assertions passed")
