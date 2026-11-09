-- Native second-slot probe: source-backed shape and safety tests.
-- This models addon inbound calls, NOT Blizzard's secure layout itself.
-- The critical client experiment is whether grouped secret buttons flow
-- correctly through the fixed second-cell clipping viewport.
local BP={Runtime={}}
assert(loadfile("Core.lua"))("bjarkiPortraits", BP)
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
R.ApplySecondaryCountdownFont=function(cooldown)
    cooldown._bjarkiUsesRegularBuffFont=true
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
    function o:UpdateAllAuras()
        self.refreshes=(self.refreshes or 0)+1
        self.lastRefreshedUnit=self.unit
        if self.enabled==false then self.clears=(self.clears or 0)+1 end
    end
    function o:CreateTexture()
        self.textures=self.textures or {}
        local tex=frame("texture",self)
        self.textures[#self.textures+1]=tex
        return tex
    end
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
        eq(b.width,37,"native second-button cell actually enlarged")
        eq(b.icon.width,22,"native second icon grows with its circle")
        eq(b.textures[2].width,30,"native totem bezel visibly grows to 36px")
        eq(b.textures[2].atlas,"UI-HUD-UnitFrame-TotemFrame",
            "enlarged native ring retains Blizzard artwork")
        eq(b.cooldown~=nil,true,"native cooldown assigned")
        eq(b.cooldown._bjarkiUsesRegularBuffFont,true,
            "native second countdown applies regular buff-duration font")
        eq(b.icon.mask~=nil,true,"circular icon mask installed")
eq(b.icon.points[1],"CENTER","native art centered on its cell")
eq(b.textures[2].points[4],1,"native rim x matches Blizzard optical inset")
eq(b.textures[2].points[5],-1.5,"native rim y matches Blizzard optical inset")
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
eq(p.clip.clips,true,"fixed clipping viewport")
eq(p.clip.width,37,"entire native secondary viewport actually enlarged")
eq(p.clip.points[3],"TOPLEFT","native Target runner-up avoids right-hand combo points")
eq(p.clip.points[4],10,"native Target has +10 upper-left x offset")
eq(p.clip.points[5],12,"native Target is raised 12px above frame top corner")
eq(p.container.points[4],-37,"first native cell still completely clipped after resizing")
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

R.UpdateNativeSecondProbe(host,true,true,true,false)
eq(p.clip.shown,true,"verified NPC probe is shown")
eq(host.secondaryBadge.shown,false,"legacy NPC badge hidden under native ribbon")

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
R.UpdateNativeSecondProbe(host,true,true,true,false,true)
eq(p.clip.shown,false,"unknown replacement GUID hides stale aura")
eq(p._unused,nil,"no synthetic positive evidence created")
eq(host._nativeSecondProbeReason,"unit-identity-unreadable",
    "secret target identity reports fail-closed reason")
eq(p.boundGUID,"Creature-Untagged","unreadable GUID cannot overwrite witness")

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
eq(p.container.clears>0,true,"release cleared previous Rend/aura assignments")
local beforeReuse=p.container.refreshes
local other={unit="target",portrait=frame("portrait"),
    secondaryBadge=frame("badge")}
other.secondaryBadge.level=60
R.UpdateNativeSecondProbe(other,true,true,true,true)
eq(other._nativeSecondProbe,p,"next hostile player automatically reuses pooled probe")
eq(p.container.enabled,true,"pooled second-aura container re-enabled")
eq(p.container.refreshes>beforeReuse,true,
    "same token reuse forces new aura read rather than retaining Rend")
eq(other._nativeSecondProbe.ready,true,"reused native strip is ready")
eq(p.clip.points[2],other.portrait,"reused probe anchors to current portrait")
eq(p.clip.points[3],"TOPLEFT","reused target probe retains combo-safe side")
eq(p.clip.points[4],10,"reused target probe retains x offset")
eq(p.clip.points[5],12,"reused target probe retains raised y offset")
R.ReleaseNativeSecondProbe(other)

-- PlayerFrame: eagerly prewarm in the first out-of-combat update, while
-- the normal readable second is still working. A new frost/control debuff
-- can then seal the public aura scan while the native strip stays active.
local player={unit="player", portrait=frame("portrait"),
    secondaryBadge=frame("badge"), _assistable=true,
    _secondaryMode="aura", _raceBaselineActive=false}
player.secondaryBadge.level=65
R.UpdateNativeSecondProbe(player,true,false,true,true)
local pp=player._nativeSecondProbe
eq(pp~=nil,true,"player prewarms native ribbon before receiving a debuff")
eq(pp.ready,true,"player native groups fully initialized out of combat")
eq(pp.container.enabled,true,"first Player build enables native secure runner-up")
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
R.UpdateNativeSecondProbe(focus,true,false,true,true)
local fp=focus._nativeSecondProbe
eq(fp~=nil,true,"friendly Focus constructs its own native second")
eq(fp.clip.shown,true,"Focus race fallback can show native second")
eq(fp.container.enabled,true,"first Focus build enables real secure second-aura groups")
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
print("native runner-up ribbon: "..checks.." inbound/safety checks passed")
