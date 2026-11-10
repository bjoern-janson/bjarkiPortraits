-- Actual primary presentation, public election, and native backup handoff.
local BP={}
for _,name in ipairs({"Spells","Core","Priority","SecondaryPortrait","NativeSecondProbe","AuraEngine"}) do
    assert(loadfile(name..".lua"))("bjarkiPortraits",BP)
end
local R=BP.Runtime
R.ApplyDefaults()
local hostile,player,ghost,sealed,guid=false,true,false,false,"Player-Test"
local buffs,harms={},{}
local denyPlainHelpful=false
function UnitExists()return true end
function UnitIsUnit(a,b)return a==b end
function UnitCanAssist()return not hostile end
function UnitIsPlayer()return player end
function UnitIsGhost()return ghost end
function UnitGUID()return guid end
function UnitRace()return "Human","Human" end
function UnitSex()return 2 end
function InCombatLockdown()return true end
function GetTime()return 100 end
C_Spell={GetSpellTexture=function(id)return id end}
local function aura(spell,id,start,duration,nameplate)
    return {spellId=spell,auraInstanceID=id,icon=spell,duration=duration,
        expirationTime=start+duration,isNameplateOnly=nameplate==true}
end
C_UnitAuras={GetAuraDataByIndex=function(_,index,filter)
    local list=filter:match("^HELPFUL") and buffs or harms
    if filter=="HELPFUL" and denyPlainHelpful then error("plain filter unavailable") end
    if list==harms and sealed then error("sealed") end
    local inclusive=filter:find("INCLUDE_NAME_PLATE_ONLY",1,true)
    local count=0
    for _,a in ipairs(list) do
        if inclusive or not (a.isNameplateOnly or a.nativeNameplateOnly) then
            count=count+1;if count==index then return a end
        end
    end
end,IsAuraFilteredOutByInstanceID=function(_,_,filter)
    return filter:find("IMPORTANT",1,true)~=nil or filter:find("DEFENSIVE",1,true)~=nil
        or filter:find("CROWD_CONTROL",1,true)~=nil
end}
local function region()
    return {visible=true, IsVisible=function(s)return s.visible end,
        Show=function(s)s.visible=true end, Hide=function(s)s.visible=false end,
        SetTexture=function(s,v)s.art=v;return true end, SetTexCoord=function()end,
        SetFrameLevel=function()end, SetCooldown=function()end, Clear=function()end}
end
local function host(unit)
    local h={unit=unit,unitFrame=region(),_buildComplete=true,containers={},cooldowns={},
        secondaryBadge=region(),racePortrait=region(),secondaryCooldown=region()}
    h.unitFrame.unit=unit
    for _,key in ipairs({"Hostile","Baseline","Healing","Stun","Ghost","DoTs"}) do
        local f=region();f.icon=region();f.cooldown=region();h["readable"..key.."Frame"]=f
    end
    for i=1,#R.TIERS do
        h.containers[i]={SetEnabled=function(s,v)s.en=v end,SetShown=function()end,
            IsEnabled=function(s)return s.en==true end}
    end
    R.hosts[unit]=h
    return h
end
local function elected(h,a,b)
    local second,reason,first=R.GetReadableSecondaryAura(h)
    assert(first and first.spellID==a and second and second.spellID==b,
        "wanted "..a.."/"..b..", got "..tostring(reason))
end
local failures={}
local function check(name,fn)
    hostile,player,ghost,sealed,guid=false,true,false,false,"Player-Test"
    buffs,harms={},{}
    denyPlainHelpful=false
    local ok,err=pcall(fn)
    if not ok then failures[#failures+1]=name..": "..tostring(err) end
end
check("NPC exact positive",function()
    hostile,player=true,false;guid="Creature-Test"
    local h=host("target")
    harms={aura(853,100,98,6),aura(772,200,96,15)}
    R.UpdateHost(h)
    assert(h._stunActive and h._readableTierOwners.Stun.complete)
    elected(h,853,772)
    -- A different application of the same spell cannot certify the first place.
    h._readableTierOwners.Stun.auraInstanceID=99
    assert(R.GetReadableSecondaryAura(h)==nil)
    h._readableTierOwners.Stun.auraInstanceID=100
    h._readableTierOwners.Stun.spellID=408
    assert(R.GetReadableSecondaryAura(h)==nil,"same occurrence with wrong spell is not the owner")
    R.UpdateHost(h)
    h._readableTierOwners.Stun.complete=false
    assert(R.GetReadableSecondaryAura(h)==nil)
    harms={harms[1]};buffs={aura(17,202,96,30)}
    R.UpdateHost(h);elected(h,853,17)
    function h.readableStunFrame.icon:SetTexture()return false end
    R.UpdateHost(h);elected(h,853,17)
end)
check("occurrence-sensitive native clock",function()
    local h=host("player")
    h._nativeSecondProbe={ready=true,clip=region(),container={},boundUnit="player",boundGUID=guid,
        decimals=true,formatRetries={},cooldowns={}}
    buffs={aura(17,500,99,30),aura(139,100,99,15),aura(139,200,90,15)}
    R.UpdateHost(h)
    assert(h._secondaryAuraInstanceID==100 and h._secondaryClockExpiry==114)
    R.NoteSecondaryAuraEvent("player",{isFullUpdate=true})
    sealed=true;R.UpdateHost(h)
    assert(not h._nativeSecondProbe.clip.visible,"old Renew would count down to 105")
    buffs[3]=nil;R.UpdateHost(h)
    assert(h._nativeSecondProbe.clip.visible,"same known occurrence still permits native backup")
end)
check("ordinary vs nameplate membership",function()
    local h=host("player")
    buffs={aura(1126,51,80,100,true),aura(465,52,78,300),aura(2580,53,70,300)}
    R.UpdateHost(h);assert(not h._baselineActive,"nameplate Mark cannot own plain BaselineClass")
    elected(h,465,2580)
    buffs[1].isNameplateOnly=false;R.UpdateHost(h);elected(h,1126,465)
    buffs[1]=aura(139,51,96,15,true);R.UpdateHost(h)
    assert(not h._healingActive,"nameplate Renew cannot own plain Healing")
    hostile=true;local t=host("target");R.UpdateHost(t)
    assert(t._hostileSpellID==465,"hostile projection must use same plain filter")
    buffs[1].isNameplateOnly=false;R.UpdateHost(t);assert(t._hostileSpellID==139)
    buffs[1].isNameplateOnly=nil;buffs[1].nativeNameplateOnly=true;R.UpdateHost(t)
    assert(t._hostileSpellID==465,"unknown optional bit needs actual plain-filter membership")
    buffs[1].nativeNameplateOnly=false;R.UpdateHost(t);assert(t._hostileSpellID==139)
    denyPlainHelpful=true;R.UpdateHost(t);assert(t._hostileSpellID~=139 and not t._hostileReadable)
    denyPlainHelpful=false
    buffs[1]=aura(11327,51,96,15,true);R.UpdateHost(t)
    assert(t._hostileSpellID==11327,"explicitly inclusive Vanish remains eligible")
end)
check("proven hostile Ghost",function()
    hostile,ghost=true,true;local h=host("target")
    buffs={aura(1126,51,80,100)};R.UpdateHost(h)
    assert(h._ghostActive and h._hostileActive);elected(h,8326,1126)
    buffs={};harms={aura(772,55,96,15)};R.UpdateHost(h)
    elected(h,8326,772)
    h._ghostSource="unknown";assert(R.GetReadableSecondaryAura(h)==nil)
end)
check("low hostile tracked helper and generic",function()
    hostile=true;local h=host("target")
    buffs={aura(2383,100,0,0),aura(7999999,200,96,20)}
    R.UpdateHost(h);assert(h._hostileTierKey=="Gathering");elected(h,7999999,2383)
    buffs[2].duration=0;R.UpdateHost(h);assert(R.GetReadableSecondaryAura(h)==nil)
    -- In restricted hostile polarity, native ID exclusions can be ignored.
    -- A newer timed Gathering occurrence may occupy the generic slot itself.
    buffs={aura(2383,300,95,30),aura(7999999,200,96,20)}
    R.UpdateHost(h);assert(R.GetReadableSecondaryAura(h)==nil)
    UnitIsPlayerControlledOrGroupMember=function()return true end
    R.UpdateHost(h);elected(h,7999999,2383)
    UnitIsPlayerControlledOrGroupMember=nil
end)
check("visibility acknowledgment",function()
    assert(R.HideSecondaryPortrait(nil) and R.HideNativeSecondProbe(nil))
    local h=host("target");h._nativeSecondProbe={clip=region()}
    h.secondaryBadge.Hide=function()return false end
    h._nativeSecondProbe.clip.Hide=function()return false end
    assert(not R.HideSecondaryPortrait(h) and not R.HideNativeSecondProbe(h),
        "explicitly denied visibility write cannot retire the surface")
end)
check("fully readable hostile native primaries",function()
    local oracle=C_UnitAuras.IsAuraFilteredOutByInstanceID
    local oldUtil=AuraUtil
    local flags={}
    local deniedFilter
    AuraUtil={IsPriorityDebuff=function()return false end}
    C_UnitAuras.IsAuraFilteredOutByInstanceID=function(_,id,filter)
        if deniedFilter and filter==deniedFilter then error("native membership denied") end
        local row=flags[id] or {}
        if row.plate and not filter:find("INCLUDE_NAME_PLATE_ONLY",1,true) then return true end
        for token in filter:gmatch("[^|]+") do
            if token~="HELPFUL" and token~="HARMFUL" and token~="INCLUDE_NAME_PLATE_ONLY" then
                local neg=token:sub(1,1)=="!"
                if (row[neg and token:sub(2) or token]==true)==neg then return true end
            end
        end
        return false
    end
    hostile=true
    for _,isPlayer in ipairs({true,false}) do
        player=isPlayer;guid=isPlayer and "Player-Test" or "Creature-Test"
        local h=host("target")
        buffs={aura(900001,222,98,20),aura(900002,111,97,20)}
        harms={};flags={}
        R.UpdateHost(h);assert(not h._hostileActive);elected(h,900001,900002)
        local slot
        for i,tier in ipairs(R.TIERS) do if tier.key=="HostileHelpful" then slot=h.containers[i] end end
        slot.en=false;assert(R.GetReadableSecondaryAura(h)==nil,"disabled generic slot cannot prove a primary")
        slot.en=true
        slot.IsShown=function()return false end
        assert(R.GetReadableSecondaryAura(h)==nil,"known hidden native slot cannot prove a generic primary")
        slot.IsShown=nil

        buffs={aura(900001,222,0,0),aura(2383,111,0,0)};flags={[222]={IMPORTANT=true}}
        R.UpdateHost(h);elected(h,900001,2383)
        deniedFilter=R.TIER_BY_KEY.Important.filter
        assert(R.GetReadableSecondaryAura(h)==nil,"an unreadable semantic oracle cannot certify the primary")
        deniedFilter=nil
        for i,tier in ipairs(R.TIERS) do
            if tier.key=="Important" then
                local native=h.containers[i];native.en=false
                assert(R.GetReadableSecondaryAura(h)==nil,"semantic slot disabled revokes ownership")
                native.en=true
            end
        end
        buffs[1].isNameplateOnly=true;flags[222].plate=true
        R.UpdateHost(h);assert(R.GetReadableSecondaryAura(h)==nil,"permanent nameplate-only is in neither primary lane")
        buffs={aura(2383,111,0,0)};harms={aura(900003,333,95,3600)}
        flags={[333]={CROWD_CONTROL=true}}
        R.UpdateHost(h);elected(h,900003,2383)
        harms[1].isNameplateOnly=true;flags[333].plate=true
        R.UpdateHost(h);assert(R.GetReadableSecondaryAura(h)==nil,"long nameplate-only CC cannot enter through the capped generic lane")

        -- A restricted low-priority exact ID may still satisfy a much
        -- higher native semantic group when its exclusion is unenforceable.
        buffs={aura(900001,222,98,20),aura(2383,111,0,0)}
        harms={};flags={[111]={BIG_DEFENSIVE=true}}
        R.UpdateHost(h);assert(R.GetReadableSecondaryAura(h)==nil,"ignored exclusion could change the native winner")
    end
    C_UnitAuras.IsAuraFilteredOutByInstanceID=oracle
    AuraUtil=oldUtil
end)
local function slot(h,key)
    for i,tier in ipairs(R.TIERS) do if tier.key==key then return h.containers[i] end end
end
local function withFlags(flags, fn)
    local original, oldUtil=C_UnitAuras.IsAuraFilteredOutByInstanceID,AuraUtil
    AuraUtil={IsPriorityDebuff=function()return false end}
    C_UnitAuras.IsAuraFilteredOutByInstanceID=function(_,id,filter)
        local row=flags[id] or {}
        for token in filter:gmatch("[^|]+") do
            if token~="HELPFUL" and token~="HARMFUL" and token~="INCLUDE_NAME_PLATE_ONLY" then
                local neg=token:sub(1,1)=="!"
                if (row[neg and token:sub(2) or token]==true)==neg then return true end
            end
        end
        return false
    end
    local ok,err=pcall(fn)
    C_UnitAuras.IsAuraFilteredOutByInstanceID,AuraUtil=original,oldUtil
    assert(ok,err)
end
check("native exclusions must agree through second",function()
    local flags={[333]={CROWD_CONTROL=true}}
    withFlags(flags,function()
        hostile,player=true,false;local h=host("target")
        harms={aura(900003,333,95,20)}
        buffs={aura(1321323,222,95,1800),aura(900002,111,97,20)}
        R.UpdateHost(h)
        assert(R.GetReadableSecondaryAura(h)==nil,"native second can select newer Shiny Silver Coin")
        buffs[1].auraInstanceID=100;R.UpdateHost(h);elected(h,900003,900002)
        buffs[1].auraInstanceID=222
        UnitIsPlayerControlledOrGroupMember=function()return true end
        R.UpdateHost(h);elected(h,900003,900002)
        UnitIsPlayerControlledOrGroupMember=nil
        buffs={aura(6268,100,97,10),aura(17,110,97,20)}
        flags[110]={EXTERNAL_DEFENSIVE=true}
        R.UpdateHost(h);assert(R.GetReadableSecondaryAura(h)==nil,"a 288 native contender can displace the 280 second")
        flags[110]=nil;R.UpdateHost(h);elected(h,900003,6268)
    end)
end)
check("known disabled slot and unknown slot have different authority",function()
    local assist,attack=UnitCanAssist,UnitCanAttack
    UnitCanAssist=function()return nil end;UnitCanAttack=function()return true end
    local ok,err=pcall(withFlags,{[222]={IMPORTANT=true}},function()
        hostile,player=true,false;local h=host("target")
        buffs={aura(900001,222,98,20),aura(900002,111,97,20)}
        harms={aura(2096,333,95,20)}
        R.UpdateHost(h)
        local native=slot(h,"SmallFriendlyHarmful")
        assert(native.en==false)
        elected(h,900001,900002)
        native.IsEnabled=function()error("unavailable") end
        native._bjarkiAppliedShown=nil
        assert(R.GetReadableSecondaryAura(h)==nil,"unresolved competing slot cannot prove the pair")
        native.IsEnabled=function()return true end
        native.IsShown=function()error("unavailable")end
        native._bjarkiAppliedShown=false
        assert(R.GetReadableSecondaryAura(h)==nil,"current enable contradicts the cached disabled assignment")
    end)
    UnitCanAssist,UnitCanAttack=assist,attack
    assert(ok,err)
end)
check("hostile player complete exact owner",function()
    hostile,player=true,true;local h=host("target")
    harms={aura(853,100,98,6),aura(772,200,96,15)}
    R.UpdateHost(h);elected(h,853,772)
    h._readableTierOwners.Stun.auraInstanceID=99
    assert(R.GetReadableSecondaryAura(h)==nil,"hostile player needs exact current occurrence")
    buffs={aura(1126,300,0,0),aura(1243,301,0,0)}
    R.UpdateHost(h);assert(h._hostileElectionReadable==false)
    elected(h,853,772) -- Unordered lower helpful effects cannot defeat a proven 320/190 pair.
    buffs={aura(139,300,0,0),aura(774,301,0,0)}
    R.UpdateHost(h);assert(h._hostileElectionReadable==false)
    assert(R.GetReadableSecondaryAura(h)==nil,"unordered Healing contenders can take second ahead of Rend")
    harms={harms[1]};buffs={aura(17,202,96,30)}
    R.UpdateHost(h);elected(h,853,17)
    h._readableTierOwners.Stun.complete=false
    assert(R.GetReadableSecondaryAura(h)==nil,"partial helper cannot certify hostile player")
    function h.readableStunFrame.icon:SetTexture()return false end
    R.UpdateHost(h);assert(R.GetReadableSecondaryAura(h)==nil,"native exact slot alone is insufficient here")
end)
check("combat hold follows relation and eligibility",function()
    C_Timer={After=function()end}
    withFlags({[222]={BIG_DEFENSIVE=true}},function()
        hostile=true;local h=host("target")
        buffs={aura(900001,222,98,20),aura(900002,111,97,20)}
        R.UpdateHost(h);assert(h._secondaryAuraSpellID==900002)
        sealed=true;R.UpdateHost(h);assert(h._secondaryAuraSpellID==900002,"unchanged relation retains")
        hostile=false;R.UpdateHost(h,true)
        assert(h._secondaryMode=="race" and not h._secondaryAuraSpellID,"friendly target cannot retain hostile-only aura")
        hostile=true;sealed=false;R.UpdateHost(h)
        assert(h._secondaryAuraSpellID==900002)
        sealed=true;R.UpdateHost(h)
        local native=slot(h,"HostileHelpful")
        native.IsEnabled=function()return nil end;native._bjarkiAppliedShown=nil
        R.ReconcileSecondaryPortrait(h,true,true)
        assert(h._secondaryAuraSpellID==900002,"unknown slot state alone is not a contradiction")
        native.IsEnabled=function()return false end
        R.ReconcileSecondaryPortrait(h,true,true)
        assert(h._secondaryMode=="race","affirmatively disabled required slot invalidates hold")
    end)
    C_Timer=nil
end)
check("shared Healing slot handoff retains only the same distinct pair",function()
    C_Timer={After=function()end}
    local function transition(initialPlainDenied, newPlainDenied, change, olderRenewID)
        sealed=false;denyPlainHelpful=initialPlainDenied
        local h=host("player")
        buffs={aura(139,olderRenewID and 100 or 300,98,15),aura(774,200,94,15)}
        R.UpdateHost(h);assert(h._secondaryAuraSpellID==774)
        if change then change(h) end
        denyPlainHelpful=newPlainDenied;sealed=true;R.UpdateHost(h)
        return h
    end
    local h=transition(true,false)
    assert(slot(h,"Healing").en==false and h._readableTierOwners.Healing.spellID==139)
    assert(h._secondaryAuraSpellID==774,"successful first-place helper takeover displaced the unchanged second")
    assert(transition(false,true)._secondaryAuraSpellID==774,"native first-place handback still agrees")
    assert(not transition(false,true,nil,true)._secondaryAuraSpellID,
        "native handback makes Rejuvenation first when refreshed Renew has the older instance ID")
    assert(not transition(true,false,function()
        buffs[2]=aura(774,199,94,15)
    end)._secondaryAuraSpellID,"a different occurrence cannot retain the old countdown")
    assert(not transition(true,false,function()
        buffs[2]=nil
        R.NoteSecondaryAuraEvent("player",{isFullUpdate=false,removedAuraInstanceIDs={200}})
    end)._secondaryAuraSpellID,"removed second was retained")
    C_Timer=nil
end)
check("direct Welcoming Campfire occupies its actual rank",function()
    local h=host("player")
    local frame=region();frame.icon=region();frame.cooldown=region();h.readableWelcomingCampfireFrame=frame
    local camp=aura(1289723,270,80,60)
    local calls=0
    C_UnitAuras.GetPlayerAuraBySpellID=function(id)
        if id==1289723 then calls=calls+1;return camp end
    end
    buffs={aura(17,260,95,30),aura(139,250,96,15)}
    R.UpdateHost(h)
    assert(h._welcomingCampfireActive and h._secondaryAuraSpellID==17,"direct main Campfire makes Shield second")
    assert(calls==1,"main and secondary must reuse this update's direct witness")
    buffs[1]=aura(22812,260,95,30);R.UpdateHost(h)
    assert(h._secondaryAuraInstanceID==270,"direct Campfire has its own clock behind Barkskin")
    buffs[3]=camp;R.UpdateHost(h);elected(h,22812,1289723)
    buffs[3]=aura(139,270,95,15);R.UpdateHost(h)
    assert(R.GetReadableSecondaryAura(h)==nil,"contradictory identity cannot occupy a rank")
    camp=nil;buffs[3]=nil;R.UpdateHost(h);elected(h,22812,139)
    C_UnitAuras.GetPlayerAuraBySpellID=nil
end)
check("friendly harmful exclusions must agree with the native generic slot",function()
    withFlags({},function()
        local h=host("player");buffs={aura(17,500,95,30)}
        harms={aura(2096,300,96,15),aura(900010,200,95,20)}
        R.UpdateHost(h);assert(h._smallHarmfulEnabled)
        assert(R.GetReadableSecondaryAura(h)==nil,"unfilterable newer Mind Vision displaces claimed native second")
        harms[1].auraInstanceID=100;R.UpdateHost(h);elected(h,17,900010)
        harms[1].auraInstanceID=300;harms[1].duration=3600;R.UpdateHost(h);elected(h,17,900010)
        local old=R.AuraIsNeverSecret
        R.AuraIsNeverSecret=function(id)return id==2096 or old(id)end
        harms[1].duration=15;R.UpdateHost(h);elected(h,17,900010)
        R.AuraIsNeverSecret=old
    end)
end)
check("hostile static state cannot be replaced by the second native aura",function()
    hostile=true
    C_Timer={After=function()end}
    UnitIsDeadOrGhost=function()return false end
    UnitClass=function()return "Druid","DRUID" end
    UnitPowerType=function()return 3,"ENERGY" end
    local h=host("target");local f=region();f.icon=region();f.cooldown=region();h.readableFormStateFrame=f
    h._nativeSecondProbe={ready=true,clip=region(),container={},boundUnit="target",boundGUID=guid,
        decimals=true,formatRetries={},cooldowns={},hostileHelpfulEnabled=true}
    harms={aura(853,300,96,6),aura(2096,222,90,30)}
    R.UpdateHost(h);assert(h._secondaryMode=="form" and not h._nativeSecondProbe.clip.visible)
    UnitPowerType=function() return 0,"MANA" end
    R.UpdateHost(h)
    function h.racePortrait:SetTexture(value) if value==768 then return false end;self.art=value;return true end
    UnitPowerType=function()return 3,"ENERGY" end
    R.UpdateHost(h);elected(h,853,768)
    assert(not h._nativeSecondProbe.clip.visible,"native Mind Vision cannot stand in for confirmed Cat Form")
    harms[2]=aura(5782,222,96,15)
    function h.racePortrait:SetTexture(value) if value==5782 then return false end;self.art=value;return true end
    R.UpdateHost(h);elected(h,853,5782)
    assert(h._formStateActive and h._secondaryMode~="aura")
    assert(h._nativeSecondProbe.clip.visible,"two verified higher auras can use native fallback above Cat Form")
    sealed=true;R.UpdateHost(h);assert(not h._nativeSecondProbe.clip.visible,"sealed stream with confirmed form")
    UnitPowerType=function()return 0,"MANA" end
    R.UpdateHost(h);assert(h._nativeSecondProbe.clip.visible,"no remaining form witness; allow native fallback")
    UnitPowerType,UnitClass,UnitIsDeadOrGhost=nil,nil,nil
    C_Timer=nil
end)
check("self alias requires a physical Campfire presenter",function()
    local same,assist,controlled=UnitIsUnit,UnitCanAssist,UnitIsPlayerControlledOrGroupMember
    local function run()
        UnitIsUnit=function(a,b)return a==b or (a=="target" and b=="player")end
        UnitCanAssist=function()return nil end;UnitIsPlayerControlledOrGroupMember=function()return nil end
        local h=host("target")
        for _,key in ipairs({"StatusEffects","WelcomingCampfire"}) do
            local f=region();f.icon=region();f.cooldown=region();h["readable"..key.."Frame"]=f
        end
        local camp=aura(1289723,270,80,60)
        C_UnitAuras.GetPlayerAuraBySpellID=function(id)if id==1289723 then return camp end end
        buffs={aura(139,195,96,15)};harms={aura(6343,250,95,15)}
        R.UpdateHost(h);assert(h._statusEffectsActive and not slot(h,"HonorlessTarget").en)
        elected(h,6343,139)
        buffs[2]=camp;UnitCanAssist=function()return true end;R.UpdateHost(h)
        assert(h._welcomingCampfireActive);elected(h,1289723,6343)
        -- The physical target can also prove the Campfire while its player
        -- alias exposes that occurrence only to the direct API.
        local index=C_UnitAuras.GetAuraDataByIndex
        C_UnitAuras.GetAuraDataByIndex=function(unit,i,filter)
            local a=index(unit,i,filter)
            if unit=="player" and a==camp then return nil end
            return a
        end
        R.UpdateHost(h)
        C_UnitAuras.GetAuraDataByIndex=index
        assert(h._welcomingCampfireActive and h._secondaryAuraSpellID==6343)
    end
    local ok,err=pcall(run)
    UnitIsUnit,UnitCanAssist,UnitIsPlayerControlledOrGroupMember=same,assist,controlled
    C_UnitAuras.GetPlayerAuraBySpellID=nil
    assert(ok,err)
end)
check("fresh public election follows actual recency presenter",function()
    local h=host("player");buffs={aura(139,100,98,15),aura(774,200,94,15)}
    R.UpdateHost(h);assert(h._healingActive);elected(h,139,774)
    denyPlainHelpful=true;R.UpdateHost(h);assert(slot(h,"Healing").en and not h._healingActive)
    elected(h,774,139);assert(h._secondaryAuraSpellID==139)
    buffs[1].auraInstanceID=300;R.UpdateHost(h);elected(h,139,774)
    buffs[1].auraInstanceID=100;denyPlainHelpful=false
    function h.readableHealingFrame.icon:SetTexture()return false end
    R.UpdateHost(h);elected(h,774,139)
end)
check("Honorless helper takeover verifies the distinct runner",function()
    C_Timer={After=function()end};local h=host("player")
    local f=region();f.icon=region();f.cooldown=region();h.readableWelcomingCampfireFrame=f
    local denied=true;f.icon.SetTexture=function()return not denied end
    buffs={aura(1289723,270,80,60),aura(2479,210,95,30)}
    R.UpdateHost(h);assert(h._secondaryAuraSpellID==2479)
    denied=false;sealed=true;R.UpdateHost(h)
    assert(h._welcomingCampfireActive and h._secondaryAuraInstanceID==210,"unchanged Honorless runner disappeared")
    R.NoteSecondaryAuraEvent("player",{isFullUpdate=false,removedAuraInstanceIDs={210}})
    buffs[2]=nil;R.UpdateHost(h);assert(not h._secondaryAuraSpellID)
    C_Timer=nil
end)
check("known native Shield placement after public clock failure",function()
    local controlled,never=UnitIsPlayerControlledOrGroupMember,R.AuraIsNeverSecret
    local previousSecrets,previousEnum=C_Secrets,Enum
    local ok,err=pcall(withFlags,{},function()
        hostile=true;UnitIsPlayerControlledOrGroupMember=function()return false end
        local shieldAllowed=false
        Enum={SecrecyLevel={NeverSecret=0}}
        C_Secrets={GetSpellAuraSecrecy=function(id)return id==17 and shieldAllowed and 0 or 1 end}
        R.AuraIsNeverSecret=function(id)return C_Secrets.GetSpellAuraSecrecy(id)==0 end
        local h=host("target")
        h._nativeSecondProbe={ready=true,clip=region(),container={},boundUnit="target",boundGUID=guid,
            decimals=true,formatRetries={},cooldowns={},hostileHelpfulEnabled=true}
        buffs={aura(17,222,96,30)};harms={aura(853,300,96,6),aura(772,100,96,15)}
        buffs[1].expirationTime=nil;R.UpdateHost(h);elected(h,853,17)
        assert(not h._nativeSecondProbe.clip.visible,"native second Rend contradicts verified Shield")
        shieldAllowed=true;R.UpdateHost(h);assert(h._nativeSecondProbe.clip.visible,"exact native Shield is second")
        shieldAllowed=false;harms[2]=nil;R.UpdateHost(h)
        assert(h._nativeSecondProbe.clip.visible,"Shield can be second through the timed generic group")
        harms[2]=aura(772,100,96,15);sealed=true;R.UpdateHost(h)
        assert(h._nativeSecondProbe.clip.visible,"opaque election still allows native best effort")
    end)
    UnitIsPlayerControlledOrGroupMember,R.AuraIsNeverSecret=controlled,never
    C_Secrets,Enum=previousSecrets,previousEnum
    assert(ok,err)
end)
check("above-static native fallback ends with the shorter verified lifetime",function()
    local oldTime,oldTimer,oldRefresh=GetTime,C_Timer,R.Refresh
    local oldDead,oldClass,oldPower=UnitIsDeadOrGhost,UnitClass,UnitPowerType
    local ok,err=pcall(function()
        hostile=true;UnitIsDeadOrGhost=function()return false end;UnitClass=function()return "Druid","DRUID" end
        UnitPowerType=function()return 3,"ENERGY" end
        local h=host("target")
        for _,name in ipairs({"FormState","StatusEffects"})do
            local f=region();f.icon=region();f.cooldown=region();h["readable"..name.."Frame"]=f
        end
        h._nativeSecondProbe={ready=true,clip=region(),container={},boundUnit="target",boundGUID=guid,
            decimals=true,formatRetries={},cooldowns={},hostileHelpfulEnabled=true}
        local time=100;GetTime=function()return time end
        local timers={};C_Timer={After=function(delay,fn)timers[#timers+1]={at=time+delay,fn=fn}end}
        local refreshes=0;R.Refresh=function(unit)assert(unit=="target");refreshes=refreshes+1;R.UpdateHost(h)end
        harms={aura(853,300,96,6),aura(6343,222,96,15),aura(2096,100,90,30)}
        function h.racePortrait:SetTexture(v)if v==6343 then return false end;self.art=v;return true end
        R.UpdateHost(h);assert(h._nativeSecondProbe.clip.visible)
        R.UpdateHost(h);assert(#timers==1 and timers[1].at==102,"missing or duplicated earliest-expiry check")
        -- A later application moves the bound. Its old callback cannot revoke the newer native ribbon.
        harms[1].expirationTime=108;R.UpdateHost(h)
        assert(#timers==2 and timers[2].at==108);time=102;timers[1].fn()
        assert(refreshes==0 and h._nativeSecondProbe.clip.visible)
        time=108;table.remove(harms,1);timers[2].fn()
        assert(refreshes==1 and not h._nativeSecondProbe.clip.visible and h._secondaryMode=="form")
        time=110
        harms={aura(853,310,109,6),aura(6343,224,104,8),aura(2096,100,90,30)}
        R.UpdateHost(h);assert(h._nativeSecondProbe.clip.visible and timers[3].at==112)
        time=112;table.remove(harms,2);timers[3].fn()
        assert(refreshes==2 and not h._nativeSecondProbe.clip.visible and h._secondaryMode=="form",
            "an earlier runner-up expiry must end the same exception")
    end)
    GetTime,C_Timer,R.Refresh=oldTime,oldTimer,oldRefresh
    UnitIsDeadOrGhost,UnitClass,UnitPowerType=oldDead,oldClass,oldPower
    assert(ok,err)
end)
check("physical Honorless runner survives a narrower self index",function()
    local same,index,lookup=UnitIsUnit,C_UnitAuras.GetAuraDataByIndex,C_UnitAuras.GetPlayerAuraBySpellID
    local ok,err=pcall(function()
        UnitIsUnit=function(a,b)return a==b or (a=="target" and b=="player")end
        local h=host("target");local f=region();f.icon=region();f.cooldown=region();h.readableWelcomingCampfireFrame=f
        local camp=aura(1289723,270,80,60);buffs={aura(2479,300,96,30),aura(139,180,90,15)}
        local physical=camp
        C_UnitAuras.GetPlayerAuraBySpellID=function(id)if id==1289723 then return camp end end
        C_UnitAuras.GetAuraDataByIndex=function(u,i,k)
            if u=="target" and i==3 and k:sub(1,7)=="HELPFUL" then return physical end
            return index(u,i,k)
        end
        R.UpdateHost(h);assert(slot(h,"HonorlessTarget").en and not h._welcomingCampfireActive)
        elected(h,2479,1289723);assert(h._secondaryAuraInstanceID==270)
        physical=aura(1289723,269,80,60);R.UpdateHost(h)
        assert(h._secondaryAuraInstanceID~=270,"different physical occurrence cannot certify the clock")
        physical=nil;R.UpdateHost(h);elected(h,2479,139)
    end)
    UnitIsUnit,C_UnitAuras.GetAuraDataByIndex,C_UnitAuras.GetPlayerAuraBySpellID=same,index,lookup
    assert(ok,err)
end)
check("self alias cannot elect an unavailable physical Shield",function()
    local same,assist,controlled=UnitIsUnit,UnitCanAssist,UnitIsPlayerControlledOrGroupMember
    local ok,err=pcall(function()
        UnitIsUnit=function(a,b)return a==b or (a=="focus" and b=="player")end
        UnitCanAssist=function()return nil end;UnitIsPlayerControlledOrGroupMember=function()return nil end
        local h=host("focus");local f=region();f.icon=region();f.cooldown=region();h.readableStatusEffectsFrame=f
        buffs={aura(17,270,96,30)};harms={aura(6343,250,95,15),aura(772,180,94,15)}
        R.UpdateHost(h);assert(not slot(h,"PowerWordShield").en and h._statusEffectsActive)
        elected(h,6343,772);assert(h._secondaryAuraSpellID==772)
        local dot=harms[2];harms[2]=nil
        h._nativeSecondProbe={ready=true,clip=region(),container={},boundUnit="player",boundGUID=guid,
            decimals=true,formatRetries={},cooldowns={},hostileHelpfulEnabled=false}
        local attack=UnitCanAttack;UnitCanAttack=function()return false end
        R.UpdateHost(h);UnitCanAttack=attack
        assert(not h._secondaryOnlyRepeatedSpell and not h._nativeSecondProbe.clip.visible,
            "two different spells supply only one physical rank; the alias strip would repeat the main")
        harms[2]=dot
        UnitIsPlayerControlledOrGroupMember=function()return true end;R.UpdateHost(h)
        assert(slot(h,"PowerWordShield").en);elected(h,17,6343)
    end)
    UnitIsUnit,UnitCanAssist,UnitIsPlayerControlledOrGroupMember=same,assist,controlled
    assert(ok,err)
end)
check("permanent Felsteed behind the physical party native winner",function()
    local party,duration=PartyFrame,C_UnitAuras.GetAuraDuration
    local ok,err=pcall(function()
        local h=host("party1");h.unitFrame.IsShown=function()return true end
        h.portrait=region();h.unitFrame.Portrait=h.portrait;PartyFrame={MemberFrame1=h.unitFrame}
        buffs={aura(5784,100,0,0),aura(1243,200,90,1800)}
        C_UnitAuras.GetAuraDuration=function()return {GetStartTime=function()error("denied")end} end
        R.UpdateHost(h);assert(slot(h,"BaselineClass").en and not h._baselineActive)
        elected(h,1243,5784);assert(h._secondaryAuraSpellID==5784)
        buffs[3]=aura(1126,180,0,0);R.UpdateHost(h)
        assert(R.GetReadableSecondaryAura(h)==nil,"two unresolved runners must remain unknown")
        C_UnitAuras.GetAuraDuration=function(_,id)return {GetStartTime=function()return id end}end
        R.UpdateHost(h);assert(h._baselineActive);elected(h,1243,1126)
        buffs={buffs[2]};R.UpdateHost(h);assert(R.GetReadableSecondaryAura(h)==nil)
    end)
    PartyFrame,C_UnitAuras.GetAuraDuration=party,duration
    assert(ok,err)
end)
check("unrelated native unknown cannot lift Shield past two higher occurrences",function()
    local controlled,never=UnitIsPlayerControlledOrGroupMember,R.AuraIsNeverSecret
    local previousSecrets,previousEnum,oracle,util=C_Secrets,Enum,C_UnitAuras.IsAuraFilteredOutByInstanceID,AuraUtil
    local ok,err=pcall(function()
        hostile=true;UnitIsPlayerControlledOrGroupMember=function()return false end
        local shieldAllowed=false
        Enum={SecrecyLevel={NeverSecret=0}}
        C_Secrets={GetSpellAuraSecrecy=function(id)return id==17 and shieldAllowed and 0 or 1 end}
        R.AuraIsNeverSecret=function(id)return C_Secrets.GetSpellAuraSecrecy(id)==0 end
        AuraUtil={IsPriorityDebuff=function()return false end}
        local ccMember
        C_UnitAuras.IsAuraFilteredOutByInstanceID=function(_,id,filter)
            local inclusive=filter:find("INCLUDE_NAME_PLATE_ONLY",1,true)
            if id==990 and not inclusive then return true end
            if id==990 and inclusive and filter:find("|CROWD_CONTROL",1,true) then
                if ccMember==nil then error("native CC membership unavailable") end
                return not ccMember
            end
            for token in filter:gmatch("[^|]+") do
                if token~="HARMFUL" and token~="HELPFUL" and token~="INCLUDE_NAME_PLATE_ONLY"
                    and token:sub(1,1)~="!" then return true end
            end
            return false
        end
        local h=host("target")
        h._nativeSecondProbe={ready=true,clip=region(),container={},boundUnit="target",boundGUID=guid,
            decimals=true,formatRetries={},cooldowns={},hostileHelpfulEnabled=true}
        buffs={aura(17,222,96,30)};buffs[1].expirationTime=nil
        harms={aura(853,300,96,6),aura(772,100,96,15),aura(900005,990,96,20,true)}
        R.UpdateHost(h);elected(h,853,17)
        assert(not h._nativeSecondProbe.clip.visible,"both possible CC answers force another second")
        shieldAllowed=true;R.UpdateHost(h);assert(h._nativeSecondProbe.clip.visible,"unknown can now put Shield second")
        ccMember=true;R.UpdateHost(h);assert(not h._nativeSecondProbe.clip.visible)
        ccMember=false;R.UpdateHost(h);assert(h._nativeSecondProbe.clip.visible)
    end)
    UnitIsPlayerControlledOrGroupMember,R.AuraIsNeverSecret=controlled,never
    C_Secrets,Enum,C_UnitAuras.IsAuraFilteredOutByInstanceID,AuraUtil=previousSecrets,previousEnum,oracle,util
    assert(ok,err)
end)
check("self Focus bounds the alias election with its actual Healing owner",function()
    local same,index,duration=UnitIsUnit,C_UnitAuras.GetAuraDataByIndex,C_UnitAuras.GetAuraDuration
    local ok,err=pcall(function()
        UnitIsUnit=function(a,b)return a==b or (a=="focus" and b=="player")end
        local h=host("focus");local renew=aura(139,100,98,15);local rejuv=aura(774,200,94,15)
        local thorns,mark=aura(467,80,85,30),aura(1126,70,80,120)
        local physical={renew,rejuv,thorns};local alias={rejuv,thorns}
        C_UnitAuras.GetAuraDataByIndex=function(unit,i,filter)
            if filter:sub(1,7)=="HELPFUL" then return (unit=="focus" and physical or alias)[i] end
            return index(unit,i,filter)
        end
        local function checkPair(primaryID,secondID)
            R.UpdateHost(h)
            local second,reason,first=R.GetReadableSecondaryAura(h)
            assert(first and first.auraInstanceID==primaryID and second.auraInstanceID==secondID,
                "wrong physical occurrence pair: "..tostring(reason))
            assert(h._secondaryAuraInstanceID==secondID)
        end
        checkPair(100,200) -- Alias omits the actual main, while the physical helper still sees both.
        physical={renew,thorns,mark};alias={aura(139,201,94,15),thorns,mark}
        checkPair(100,80) -- Another visible application of the same spell is not the physical main.
        physical={renew,rejuv,thorns};alias=physical;renew.expirationTime=nil
        h.readableHealingFrame.cooldown.SetCooldownFromDurationObject=function()return true end
        C_UnitAuras.GetAuraDuration=function(unit,id)return {unit=unit,id=id,GetStartTime=function()
            if unit=="player" and id==100 then error("restricted start")end
            return id==100 and 98 or 94
        end}end
        checkPair(100,200)
        alias={renew,thorns};rejuv.expirationTime=nil
        local clock
        h.secondaryCooldown.SetCooldownFromDurationObject=function(_,object)clock=object;return true end
        checkPair(100,200)
        assert(clock and clock.unit=="focus" and clock.id==200,"physical-only runner borrowed the alias clock")
        alias={aura(772,100,98,15),thorns};R.UpdateHost(h)
        assert(R.GetReadableSecondaryAura(h)==nil,"two spells cannot share the physical occurrence")
    end)
    UnitIsUnit,C_UnitAuras.GetAuraDataByIndex,C_UnitAuras.GetAuraDuration=same,index,duration
    assert(ok,err)
end)
check("combat hold expires when a previously excluded higher physical slot is admitted",function()
    local same,assist,attack,controlled=UnitIsUnit,UnitCanAssist,UnitCanAttack,UnitIsPlayerControlledOrGroupMember
    local index,timer=C_UnitAuras.GetAuraDataByIndex,C_Timer
    local ok,err=pcall(function()
        C_Timer={After=function()end}
        UnitIsUnit=function(a,b)return a==b or (a=="focus" and b=="player")end
        UnitCanAssist=function()return nil end;UnitCanAttack=function()return false end
        local allowed;UnitIsPlayerControlledOrGroupMember=function()return allowed end
        local h=host("focus");local f=region();f.icon=region();f.cooldown=region();h.readableStatusEffectsFrame=f
        buffs={aura(17,270,96,30)};harms={aura(6343,250,95,15),aura(772,180,94,15)}
        local hidden=false;C_UnitAuras.GetAuraDataByIndex=function(u,i,k)
            if hidden and u=="player" and k:sub(1,7)=="HARMFUL" then error("alias index sealed")end
            return index(u,i,k)
        end
        R.UpdateHost(h);assert(h._secondaryAuraSpellID==772)
        hidden=true;R.UpdateHost(h,true);assert(h._secondaryAuraSpellID==772)
        allowed=true;R.UpdateHost(h,true)
        assert(slot(h,"PowerWordShield").en and h._secondaryAuraSpellID~=772,"retained Rend past the higher Shield transition")
        hidden=false;R.UpdateHost(h,true);assert(h._secondaryAuraSpellID==6343)
        allowed=nil;R.UpdateHost(h,true);assert(h._secondaryAuraSpellID==772)
        buffs={};hidden=true
        R.NoteSecondaryAuraEvent("focus",{isFullUpdate=false,removedAuraInstanceIDs={270}})
        allowed=true;R.UpdateHost(h,true)
        assert(h._secondaryAuraSpellID==772,"a positively removed Shield cannot invalidate the retained pair")
    end)
    UnitIsUnit,UnitCanAssist,UnitCanAttack,UnitIsPlayerControlledOrGroupMember=same,assist,attack,controlled
    C_UnitAuras.GetAuraDataByIndex,C_Timer=index,timer
    assert(ok,err)
end)
check("complementary native harmful groups guarantee one earlier cell",function()
    local controlled,never=UnitIsPlayerControlledOrGroupMember,R.AuraIsNeverSecret
    local secrets,enum,oracle,util=C_Secrets,Enum,C_UnitAuras.IsAuraFilteredOutByInstanceID,AuraUtil
    local ok,err=pcall(function()
        hostile=true;UnitIsPlayerControlledOrGroupMember=function()return false end
        local canUseShield=false;Enum={SecrecyLevel={NeverSecret=0}}
        C_Secrets={GetSpellAuraSecrecy=function(id)return id==17 and canUseShield and 0 or 1 end}
        R.AuraIsNeverSecret=function(id)return C_Secrets.GetSpellAuraSecrecy(id)==0 end
        local priority=false
        AuraUtil={IsPriorityDebuff=function(id)
            if id==900005 and priority==nil then error("priority flag sealed") end
            return id==900005 and priority
        end}
        local cc;C_UnitAuras.IsAuraFilteredOutByInstanceID=function(_,id,filter)
            local plate=filter:find("INCLUDE_NAME_PLATE_ONLY",1,true)
            if id==990 and not plate then return true end
            for flag in filter:gmatch("[^|]+")do
                if flag~="HELPFUL" and flag~="HARMFUL" and flag~="INCLUDE_NAME_PLATE_ONLY" then
                    local neg=flag:sub(1,1)=="!";local key=neg and flag:sub(2) or flag;local present=false
                    if id==990 and key=="CROWD_CONTROL" then
                        if cc==nil then error("shared flag sealed")end
                        present=cc
                    end
                    if present==neg then return true end
                end
            end
            return false
        end
        local h=host("target");h._nativeSecondProbe={ready=true,clip=region(),container={},boundUnit="target",
            boundGUID=guid,decimals=true,formatRetries={},cooldowns={},hostileHelpfulEnabled=true}
        buffs={aura(17,222,96,30)};buffs[1].expirationTime=nil
        harms={aura(853,300,96,6),aura(900005,990,96,20,true)}
        for _,isPriority in ipairs({false,true})do
            priority=isPriority;cc=nil;R.UpdateHost(h);elected(h,853,17)
            assert(not h._nativeSecondProbe.clip.visible,"the CC or !CC native group precedes unfilterable Shield")
            cc=false;R.UpdateHost(h);assert(not h._nativeSecondProbe.clip.visible)
            cc=true;R.UpdateHost(h);assert(not h._nativeSecondProbe.clip.visible)
        end
        priority=nil;cc=nil;R.UpdateHost(h)
        assert(not h._nativeSecondProbe.clip.visible,"all three harmful branches still precede generic Shield")
        cc=nil;canUseShield=true;R.UpdateHost(h);assert(h._nativeSecondProbe.clip.visible,"the flag matters above native Shield")
        canUseShield=false;harms[2].duration=3600;R.UpdateHost(h);assert(h._nativeSecondProbe.clip.visible)
        harms[2]=nil;R.UpdateHost(h);assert(h._nativeSecondProbe.clip.visible)
    end)
    UnitIsPlayerControlledOrGroupMember,R.AuraIsNeverSecret=controlled,never
    C_Secrets,Enum,C_UnitAuras.IsAuraFilteredOutByInstanceID,AuraUtil=secrets,enum,oracle,util
    assert(ok,err)
end)
local function selfFocusCase(run)
    local same,reader,oracle,clock,timer,attack=UnitIsUnit,C_UnitAuras.GetAuraDataByIndex,
        C_UnitAuras.IsAuraFilteredOutByInstanceID,C_UnitAuras.GetAuraDuration,C_Timer,UnitCanAttack
    UnitIsUnit=function(a,b)return a==b or (a=="focus" and b=="player")end
    UnitCanAttack=function()return false end
    C_Timer={After=function()end}
    local h=host("focus")
    local lists={focus={HELPFUL={},HARMFUL={}},player={HELPFUL={},HARMFUL={}}}
    C_UnitAuras.GetAuraDataByIndex=function(unit,i,filter)
        local list=lists[unit][filter:match("^[A-Z]+")]
        if list==false then error("restricted index") end
        return list[i]
    end
    local ok,err=pcall(run,h,lists,oracle)
    UnitIsUnit,C_UnitAuras.GetAuraDataByIndex,C_UnitAuras.IsAuraFilteredOutByInstanceID,
        C_UnitAuras.GetAuraDuration,C_Timer,UnitCanAttack=same,reader,oracle,clock,timer,attack
    assert(ok,err)
end
check("physical-only Rend uses the Focus semantic oracle",function()
    selfFocusCase(function(h,lists,oracle)
        local renew=aura(139,100,98,15)
        lists.player.HELPFUL={renew};lists.focus.HELPFUL={renew}
        lists.focus.HARMFUL={aura(772,21,97,15)}
        local crowd=false
        C_UnitAuras.IsAuraFilteredOutByInstanceID=function(unit,id,filter)
            if id==21 and filter:find("CROWD_CONTROL",1,true) then
                if unit=="player" then error("no such occurrence on this token") end
                return not crowd
            end
            return oracle(unit,id,filter)
        end
        R.UpdateHost(h);assert(h._secondaryAuraSpellID==772,"Focus excluded its Rend from native CC")
        crowd=true;R.UpdateHost(h);assert(h._secondaryAuraSpellID~=772,"physical native conflict")
    end)
end)
check("corroborated Focus clock survives sealed alias timing",function()
    selfFocusCase(function(h,lists)
        local renew=aura(139,100,98,15);local rejuv=aura(774,200,94,15)
        local partial=aura(774,200,94,15);partial.expirationTime=nil
        lists.focus.HELPFUL={renew,rejuv};lists.player.HELPFUL={renew,partial}
        R.UpdateHost(h)
        assert(h._secondaryAuraInstanceID==200 and h._secondaryClockExpiry==109,"same occurrence has a public Focus clock")
        rejuv.expirationTime=nil
        local applied
        h.readableHealingFrame.cooldown.SetCooldownFromDurationObject=function()return true end
        h.secondaryCooldown.SetCooldownFromDurationObject=function(_,obj)applied=obj;return true end
        C_UnitAuras.GetAuraDuration=function(unit,id)
            if unit=="focus" then return {id=id,GetStartTime=function()return id==100 and 98 or 94 end} end
        end
        R.UpdateHost(h)
        assert(h._secondaryAuraInstanceID==200 and applied and applied.id==200,"same physical opaque clock")
        lists.focus.HELPFUL={renew,aura(774,201,94,15)}
        R.UpdateHost(h);assert(h._secondaryAuraInstanceID~=200,"different physical application cannot supply its clock")
    end)
end)
check("player ribbon cannot certify a Focus-only Rejuvenation clock",function()
    selfFocusCase(function(h,lists)
        local shield=aura(17,301,98,30);local new=aura(774,200,98,15);local old=aura(774,150,90,15)
        lists.focus.HELPFUL={shield,new,old};lists.player.HELPFUL={shield,old}
        h._nativeSecondProbe={ready=true,clip=region(),container={},boundUnit="player",boundGUID=guid,
            decimals=true,formatRetries={},cooldowns={},hostileHelpfulEnabled=false}
        R.UpdateHost(h);assert(h._secondaryAuraInstanceID==200 and h._secondaryClockExpiry==113)
        new.expirationTime=114 -- A changed visible clock requires an actual rebind.
        R.NoteSecondaryAuraEvent("focus",{isFullUpdate=true})
        h.secondaryCooldown.SetCooldown=function()return false end;R.UpdateHost(h)
        assert(not h._nativeSecondProbe.clip.visible,"the player ribbon only has the older Rejuvenation expiring at 105")
        lists.player.HELPFUL={shield,new,old};R.UpdateHost(h)
        assert(h._nativeSecondProbe.clip.visible,"the same occurrence is now on the ribbon token")
    end)
end)
check("a higher physical helper revokes an older sealed pair",function()
    selfFocusCase(function(h,lists)
        local both={aura(139,100,98,15),aura(774,200,94,15)}
        lists.focus.HELPFUL=both;lists.player.HELPFUL=both;lists.focus.HARMFUL=false
        R.UpdateHost(h);assert(h._secondaryAuraSpellID==774)
        lists.player.HELPFUL=false;R.UpdateHost(h,true)
        assert(h._secondaryAuraSpellID==774,"unrelated unreadability alone preserves the verified runner")
        lists.focus.HARMFUL={aura(853,304,99,6)};R.UpdateHost(h,true)
        assert(h._stunActive and h._secondaryAuraSpellID~=774,"newly presented HoJ changes both places")
        lists.player.HELPFUL=both;R.UpdateHost(h,true);assert(h._secondaryAuraSpellID==139)
    end)
end)
check("unavailable Skyborne art leaves the player native cell eligible",function()
    local race=UnitRace
    UnitRace=function()return "Skyborne","Skyborne" end
    local h=host("player")
    h._nativeSecondProbe={ready=true,clip=region(),container={},boundUnit="player",boundGUID=guid,
        decimals=true,formatRetries={},cooldowns={}}
    sealed=true;R.UpdateHost(h)
    local visible=h._nativeSecondProbe.clip.visible
    ghost=true;R.UpdateHost(h)
    UnitRace=race
    assert(visible,"native second should survive the missing portrait atlas")
    assert(not h._nativeSecondProbe.clip.visible,"unranked Ghost still blocks fallback")
end)
check("equivalent recipient events retain the live secondary clock",function()
    local loc,timer=C_LossOfControl,C_Timer
    assert(loadfile("Interrupts.lua"))("bjarkiPortraits",BP)
    local kick={locType="SCHOOL_INTERRUPT",spellID=1766,startTime=98,duration=5,iconTexture=1766}
    local active={kick}
    C_LossOfControl={GetActiveLossOfControlDataCount=function()return #active end,
        GetActiveLossOfControlData=function(i)return active[i] end}
    C_Timer={After=function()end}
    local ok,err=pcall(function()
        local h=host("player");local f=region();f.icon=region();f.cooldown=region();h.schoolInterruptFrame=f
        harms={aura(853,401,99,6)};buffs={aura(17,301,98,30)}
        R.UpdateHost(h);assert(h._secondaryAuraSpellID==1766)
        local clears=0;h.secondaryCooldown.Clear=function()clears=clears+1 end
        h.secondaryCooldown.SetCooldown=function()return false end
        R.UpdateHost(h);assert(h._secondaryAuraSpellID==1766 and clears==0)
        sealed=true;R.UpdateHost(h,true)
        assert(h._secondaryAuraSpellID==1766 and clears==0,"a fresh scan of the same timed application must retain Kick")
        active={{locType="SCHOOL_INTERRUPT",spellID=1766,startTime=100,duration=5,iconTexture=1766}}
        R.UpdateHost(h,true);assert(h._secondaryMode~="interrupt","a new Kick is a new clock")
        sealed=false;h.secondaryCooldown.SetCooldown=function()return true end
        harms={};active={kick,{locType="SCHOOL_INTERRUPT",spellID=6552,startTime=99,duration=4}}
        R.UpdateHost(h,true)
        assert(h._schoolInterrupt.spellID==6552 and h._secondaryAuraSpellID==1766,"both recipient records outrank Shield")
        sealed=true;active={active[2]};R.UpdateHost(h,true)
        assert(h._secondaryAuraSpellID~=1766,"losing the older record revokes the second clock")
    end)
    C_LossOfControl,C_Timer=loc,timer
    assert(ok,err)
end)
local function hostileSchoolCase(unit,run)
    local api,timer,attack,reader,oracle=C_LossOfControl,C_Timer,UnitCanAttack,
        C_UnitAuras.GetAuraDataByIndex,C_UnitAuras.IsAuraFilteredOutByInstanceID
    assert(loadfile("Interrupts.lua"))("bjarkiPortraits",BP)
    hostile=true;UnitCanAttack=function()return true end;C_Timer={After=function()end}
    local state={rows={{locType="SCHOOL_INTERRUPT",spellID=1766,startTime=98,duration=5}}}
    C_LossOfControl={GetActiveLossOfControlDataCountByUnit=function()return #state.rows end,
        GetActiveLossOfControlDataByUnit=function(_,i)return state.rows[i] end,
        GetActiveLossOfControlDuration=function(_,i)return state.rows[i].handle end}
    local h=host(unit)
    for _,key in ipairs({"schoolInterruptFrame","readableControlFrame"}) do
        local f=region();f.icon=region();f.cooldown=region();h[key]=f
    end
    local ok,err=pcall(run,h,state)
    C_LossOfControl,C_Timer,UnitCanAttack=api,timer,attack
    C_UnitAuras.GetAuraDataByIndex,C_UnitAuras.IsAuraFilteredOutByInstanceID=reader,oracle
    assert(ok,err)
end
for _,unit in ipairs({"target","focus"}) do
    check(unit.." binds and clears the current unbounded school clock",function()
        hostileSchoolCase(unit,function(h,state)
            local kick=state.rows[1];kick.auraInstanceID=42;kick.duration=nil
            local equalWrappers={__eq=function()return true end}
            local a,b=setmetatable({},equalWrappers),setmetatable({},equalWrappers);kick.handle=a
            local clock=h.secondaryCooldown
            function clock:SetCooldownFromDurationObject(obj)self.bound=obj;self.binds=(self.binds or 0)+1 end
            function clock:Clear()self.bound=nil end
            h.schoolInterruptFrame.cooldown.SetCooldownFromDurationObject=function()return true end
            harms={aura(853,11,97,6)};R.UpdateHost(h)
            assert(rawequal(clock.bound,a) and h._secondaryAuraSpellID==1766)
            R.UpdateHost(h,true);assert(clock.binds==1,"identical native handle is left running")
            kick.handle=b;R.UpdateHost(h,true)
            assert(rawequal(clock.bound,b) and clock.binds==2,"fresh opaque wrapper must replace the installed one")
            kick.handle=nil;R.UpdateHost(h,true)
            assert(clock.bound==nil and h._secondaryAuraSpellID==1766,"a withdrawn clock leaves verified art only")
            harms={};state.rows[2]={locType="SCHOOL_INTERRUPT",spellID=6552,startTime=99,duration=5}
            kick.handle=a;R.UpdateHost(h,true);assert(rawequal(clock.bound,a) and h._secondaryAuraSpellID==1766)
            kick.handle=b;R.UpdateHost(h,true);assert(rawequal(clock.bound,b),"lower of two recipient records uses its own clock")
        end)
    end)
    check(unit.." invalidates a sealed pair when a higher helper obtains a distinct runner",function()
        hostileSchoolCase(unit,function(h)
            local old=C_UnitAuras.GetAuraDataByIndex;local blocked=false
            C_UnitAuras.GetAuraDataByIndex=function(u,i,f)
                if blocked and f:sub(1,7)=="HELPFUL" then error("unavailable helpful list") end
                return old(u,i,f)
            end
            harms={aura(853,301,97,6)};R.UpdateHost(h);assert(h._secondaryAuraSpellID==1766)
            blocked=true;harms[2]=aura(853,201,96,6);R.UpdateHost(h,true)
            assert(h._secondaryAuraSpellID==1766,"duplicate copies do not occupy a distinct rank")
            harms[2]=aura(408,201,96,6);R.UpdateHost(h,true)
            assert(h._readableTierOwners.Stun.runnerSpellID==408 and h._secondaryAuraSpellID~=1766,"Kidney now ranks above Kick")
            blocked=false;R.UpdateHost(h,true);assert(h._secondaryAuraSpellID==408)
        end)
    end)
    check(unit.." native Fear can certify the distinct school runner",function()
        hostileSchoolCase(unit,function(h)
            local oracle=C_UnitAuras.IsAuraFilteredOutByInstanceID;local member=true
            C_UnitAuras.IsAuraFilteredOutByInstanceID=function(u,id,f)
                if id==91 and f=="HARMFUL" then
                    if member==nil then error("unreadable")end
                    return not member
                end
                return oracle(u,id,f)
            end
            harms={aura(5782,91,97,10)};R.UpdateHost(h)
            assert(slot(h,"Control").en and not h._controlActive and h._secondaryAuraSpellID==1766,"sole eligible native Fear")
            buffs={aura(17,51,95,30)};R.UpdateHost(h);assert(h._secondaryAuraSpellID==1766,"lower helpful helper")
            member=false;R.UpdateHost(h);assert(h._secondaryAuraSpellID~=1766,"explicit native membership refusal")
            member=nil;R.UpdateHost(h);assert(h._secondaryAuraSpellID~=1766,"opaque native membership")
            member=true;R.UpdateHost(h);assert(h._secondaryAuraSpellID==1766)
            local lane=slot(h,"Control");local old=lane.IsEnabled
            lane.IsEnabled=function()return false end
            assert(R.GetReadableSecondaryAura(h)==nil,"disabled native Control")
            lane.IsEnabled=old
            lane.IsShown=function()return false end
            assert(R.GetReadableSecondaryAura(h)==nil,"hidden native Control")
            lane.IsShown=nil
            h._hostileAuraListComplete=false
            local uncertain,_,first=R.GetReadableSecondaryAura(h)
            assert(not (first and first.spellID==5782 and uncertain and uncertain.spellID==1766),"incomplete hostile coverage")
            h._hostileAuraListComplete=true
            local allowed=R.ExactFilterAllowed
            R.ExactFilterAllowed=function(u,helpful,...)if helpful then return allowed(u,helpful,...) end return false end
            uncertain,_,first=R.GetReadableSecondaryAura(h)
            R.ExactFilterAllowed=allowed
            assert(not (first and first.spellID==5782 and uncertain and uncertain.spellID==1766),"forbidden exact harmful identity")
            harms[2]=aura(5782,16,94,10);R.UpdateHost(h)
            assert(h._secondaryAuraSpellID~=1766,"two possible native Fear clocks cannot prove a sole occurrence")
            harms[2]=aura(853,50,97,6);R.UpdateHost(h)
            assert(h._secondaryAuraSpellID==5782,"higher visible stun still takes rank one")
        end)
    end)
end
check("only relevant recipient changes revoke a higher sealed aura pair",function()
    hostileSchoolCase("target",function(h,state)
        local kick=state.rows[1];state.rows={}
        harms={aura(853,301,97,6),aura(118,201,96,10)};R.UpdateHost(h);assert(h._secondaryAuraSpellID==118)
        sealed=true;R.UpdateHost(h,true);assert(h._secondaryAuraSpellID==118)
        state.rows={kick};R.UpdateHost(h,true);assert(h._secondaryAuraSpellID==118,"fresh school record lies below both")
        state.rows={};R.UpdateHost(h,true);assert(h._secondaryAuraSpellID==118,"lower school removal")
        kick.auraInstanceID=201;state.rows={kick};R.UpdateHost(h,true)
        assert(h._secondaryAuraSpellID~=118,"a lower record linked to a retained occurrence still requires re-election")
    end)
end)
check("the current physical application supplies a conflicting public Focus clock",function()
    selfFocusCase(function(h,lists)
        local shield=aura(17,500,95,30)
        local alias=aura(774,200,90,15);local physical=aura(774,200,90,15)
        lists.player.HELPFUL={shield,alias};lists.focus.HELPFUL={shield,physical}
        R.UpdateHost(h);assert(h._secondaryClockExpiry==105)
        physical.expirationTime=113
        R.UpdateHost(h);assert(h._secondaryClockExpiry==113 and h._secondaryClockSource=="focus","refreshed Focus application")
        alias.expirationTime,physical.expirationTime=114,110
        R.UpdateHost(h,true);assert(h._secondaryClockExpiry==110 and h._secondaryClockSource=="focus","an earlier physical deadline also wins")
        physical.expirationTime=alias.expirationTime;R.UpdateHost(h,true)
        assert(h._secondaryClockExpiry==114,"agreeing public clocks")
        h._nativeSecondProbe={ready=true,clip=region(),container={},boundUnit="player",boundGUID=guid,
            decimals=true,formatRetries={},cooldowns={},hostileHelpfulEnabled=false}
        local set=h.secondaryCooldown.SetCooldown
        physical.expirationTime=108;h.secondaryCooldown.SetCooldown=function(_,start,duration)return start+duration~=108 end
        R.UpdateHost(h)
        assert(h._secondaryAuraSpellID~=774 and not h._nativeSecondProbe.clip.visible,
            "a denied physical clock cannot be replaced by the conflicting alias timer or the player ribbon")
        h.secondaryCooldown.SetCooldown=set
        alias.auraInstanceID=400;R.UpdateHost(h,true)
        assert(h._secondaryAuraInstanceID~=400 or h._secondaryClockSource~="focus","different ID cannot borrow the physical clock")
    end)
end)
check("retained badge requires an accepted expiry and handles an early callback once",function()
    local clock,timer,refresh=GetTime,C_Timer,R.Refresh
    local ok,err=pcall(function()
        local now,accepted=100,false;local calls={}
        GetTime=function()return now end
        C_Timer={After=function(delay,cb)
            calls[#calls+1]={delay=delay,cb=cb}
            if not accepted then return false end
        end}
        local h=host("player");R.Refresh=function()R.UpdateHost(h)end
        buffs={aura(17,301,98,30),aura(139,200,99,9)}
        R.UpdateHost(h);assert(h._secondaryAuraSpellID==139)
        sealed=true;R.UpdateHost(h)
        assert(h._secondaryAuraSpellID==nil,"an explicitly refused expiry cannot authorize a held badge")
        local refused=calls[#calls]
        sealed=false;accepted=true;R.UpdateHost(h)
        sealed=true;R.UpdateHost(h);local first=calls[#calls];local count=#calls
        refused.cb();assert(h._secondaryAuraSpellID==139 and #calls==count,"a refused callback never owns a later election")
        now=103;first.cb()
        assert(h._secondaryAuraSpellID==139 and #calls==count+1 and calls[#calls].delay==5,
            "an early callback schedules only the remaining window")
        local last=calls[#calls];first.cb();R.UpdateHost(h)
        assert(#calls==count+1 and h._secondaryAuraSpellID==139,"stale early callbacks and ordinary events cannot fork timers")
        now=108;last.cb();assert(h._secondaryAuraSpellID==nil,"the actual deadline ends sealed retention")
        now=100;sealed=false;R.UpdateHost(h);sealed=true;R.UpdateHost(h)
        local early=calls[#calls];now=102;accepted=false;early.cb()
        assert(h._secondaryAuraSpellID==nil,"a refused early replacement ends sealed retention")
        now=100;accepted=true;sealed=false;R.UpdateHost(h);sealed=true;R.UpdateHost(h)
        calls[#calls].cb();local maxCalls=#calls;calls[maxCalls].cb()
        assert(#calls==maxCalls and h._secondaryAuraSpellID==nil,"repeatedly early callbacks cannot spin")
    end)
    GetTime,C_Timer,R.Refresh=clock,timer,refresh
    assert(ok,err)
end)
for _,unit in ipairs({"target","focus"}) do
    check(unit.." retained native Control rechecks its sole verified occurrence",function()
        hostileSchoolCase(unit,function(h,state)
            local silence=region();silence.icon=region();silence.cooldown=region();h.readableInterruptSilenceFrame=silence
            local index=C_UnitAuras.GetAuraDataByIndex;local block=false;local plainBlocked=false;local member=true
            local crowd=false
            local oracle=C_UnitAuras.IsAuraFilteredOutByInstanceID
            C_UnitAuras.GetAuraDataByIndex=function(u,i,f)
                if block and f:sub(1,7)=="HELPFUL" then error("restricted")end
                if plainBlocked and f=="HARMFUL" then error("restricted plain index")end
                return index(u,i,f)
            end
            C_UnitAuras.IsAuraFilteredOutByInstanceID=function(u,id,f)
                if f=="HARMFUL" and id==301 then return not member end
                if f=="HARMFUL|CROWD_CONTROL" and id==91 then return not crowd end
                return oracle(u,id,f)
            end
            harms={aura(5782,301,97,10)};R.UpdateHost(h);assert(h._secondaryAuraSpellID==1766)
            block=true;R.UpdateHost(h,true);assert(h._secondaryAuraSpellID==1766,"same sole native Fear can be held")
            harms[2]=aura(118,201,96,10);R.NoteSecondaryAuraEvent(unit,{isFullUpdate=false,removedAuraInstanceIDs={999}})
            R.UpdateHost(h,true);assert(h._secondaryAuraSpellID~=1766,"both native Control effects outrank Kick")
            block=false;harms[2]=nil;R.UpdateHost(h,true);assert(h._secondaryAuraSpellID==1766)
            block=true;plainBlocked=true;harms[2]=aura(118,201,96,10);R.UpdateHost(h,true)
            assert(h._secondaryAuraSpellID~=1766,"inclusive harmful evidence and the native filter also establish both Control members")
            plainBlocked=false
            block=false;harms[2]=nil;R.UpdateHost(h,true)
            block=true;harms[2]=aura(900005,91,96,10);R.UpdateHost(h,true)
            assert(h._secondaryAuraSpellID==1766,"a lower unclassified effect does not break the hold")
            crowd=true;R.UpdateHost(h,true)
            assert(h._secondaryAuraSpellID~=1766,"a distinct native CrowdControl occurrence also outranks Kick")
            block=false;harms[2]=nil;state.rows[1].auraInstanceID=91;R.UpdateHost(h,true)
            block=true;harms[2]=aura(900005,91,96,10);R.UpdateHost(h,true)
            assert(h._secondaryAuraSpellID==1766,"a CC occurrence linked to the school record is not a third distinct effect")
            block=false;harms[2]=nil;R.UpdateHost(h,true);assert(h._secondaryAuraSpellID==1766)
            block=true;member=false;R.UpdateHost(h,true);assert(h._secondaryAuraSpellID~=1766,"refused physical membership")
            block=false;member=true;R.UpdateHost(h,true);block=true;harms={}
            R.UpdateHost(h,true);assert(h._secondaryAuraSpellID~=1766,"completed harmful index lost the physical first")
        end)
    end)
    check(unit.." a fresh public aura pair reuses its badge without a held-evidence timer",function()
        hostileSchoolCase(unit,function(h,state)
            state.rows={};harms={aura(853,301,97,6)};buffs={aura(17,222,98,30),aura(1126,111,82,1700)}
            local writes,scheduled=0,0
            h.secondaryCooldown.SetCooldown=function()writes=writes+1;return writes==1 end
            C_Timer.After=function()scheduled=scheduled+1;return false end
            R.UpdateHost(h)
            for i=1,3 do
                buffs[2].expirationTime=1782+i
                R.NoteSecondaryAuraEvent(unit,{isFullUpdate=false,updatedAuraInstanceIDs={111}})
                R.UpdateHost(h)
            end
            assert(h._secondaryAuraSpellID==17 and writes==1 and scheduled==0,"verified unchanged Shield never needed a timer or repaint")
            sealed=true;R.UpdateHost(h)
            assert(h._secondaryAuraSpellID~=17 and scheduled==1,"actually sealing the list still requires a future accepted expiry")
            sealed=false;h.secondaryCooldown.SetCooldown=function()writes=writes+1;return true end;R.UpdateHost(h)
            local before=writes;buffs[1].auraInstanceID=223;R.UpdateHost(h)
            assert(writes==before+1 and h._secondaryAuraInstanceID==223,"new application with identical digits must bind")
            before=writes;R.UpdateHost(h,false,true);assert(writes==before+1,"same public fields on an explicit recipient change must bind")
        end)
    end)
    check(unit.." current public lockout output avoids writes across fresh snapshots",function()
        hostileSchoolCase(unit,function(h,state)
            guid=nil;harms={aura(853,301,97,6)}
            local numeric,clears,shows=0,0,0
            function h.secondaryCooldown:SetCooldown()numeric=numeric+1 end
            function h.secondaryCooldown:Clear()clears=clears+1 end
            function h.secondaryBadge:Show()shows=shows+1;self.visible=true end
            R.UpdateHost(h);local shown,cleared=shows,clears
            for i=1,3 do
                local a,b,c=R.GetSchoolInterrupt(unit)
                R.UpdateHost(h,false,false,false,{host=h,record=a,second=b,complete=c})
                R.UpdateHost(h,true)
            end
            assert(numeric==1 and shows==shown and clears==cleared,"fresh identical numeric observations must not repaint")
            state.rows[1].auraInstanceID=999;R.UpdateHost(h,true);assert(numeric==2,"a changed reported occurrence must bind")
            R.UpdateHost(h,false,true);assert(numeric==3,"a binding barrier must reinstall even the same numeric result")
            guid="Player-Test";state.rows[1]={locType="SCHOOL_INTERRUPT",spellID=1766,iconTexture=1766}
            R.UpdateHost(h,true);shown,cleared=shows,clears
            for i=1,3 do R.UpdateHost(h) end
            assert(h._secondaryAuraSpellID==1766 and shows==shown and clears==cleared,"verified clockless art needs no repeat clears")
        end)
    end)
    check(unit.." replacement of a bound school handle survives numeric fallback",function()
        hostileSchoolCase(unit,function(h,state)
            harms={aura(853,301,97,6)}
            local a,b={},{};local clock=h.secondaryCooldown;local kick=state.rows[1]
            function clock:SetCooldownFromDurationObject(obj)self.object=obj;self.sets=(self.sets or 0)+1 end
            function clock:SetCooldown(start,duration)self.object=nil;self.deadline=start+duration end
            function clock:Clear()self.object=nil;self.deadline=nil end
            kick.handle=a;R.UpdateHost(h);assert(rawequal(clock.object,a))
            kick.handle=b;R.UpdateHost(h,true);assert(rawequal(clock.object,b),"cached numeric deadline does not identify the installed object")
            kick.handle=nil;R.UpdateHost(h,true);assert(clock.object==nil and clock.deadline==103,"use observed numeric timer after object withdrawal")
            local attempts=0
            function clock:SetCooldownFromDurationObject()attempts=attempts+1;return false end
            kick.startTime=99;kick.handle=a;R.UpdateHost(h,true);assert(attempts==1 and clock.deadline==104)
            kick.handle=b;R.UpdateHost(h,true);assert(attempts==1 and clock.deadline==104,"unbound alternate wrapper cannot invalidate a numeric clock")
        end)
    end)
end
for _,unit in ipairs({"target","focus"}) do
    check(unit.." verifies regular aura cooldown and permanent art without repaint",function()
        hostileSchoolCase(unit,function(h,state)
            local getter=C_UnitAuras.GetAuraDuration
            local ok,err=pcall(function()
                state.rows={};harms={aura(853,301,97,6)}
                local shield=aura(17,222,98,30);shield.expirationTime=nil;buffs={shield}
                local sink,current,hits=nil,{},0
                C_UnitAuras.GetAuraDuration=function(u,id)if u==unit and id==222 then return current end end
                h.secondaryCooldown.SetCooldownFromDurationObject=function(_,o)sink=o;hits=hits+1;return true end
                R.UpdateHost(h);assert(rawequal(sink,current) and hits==1)
                R.NoteSecondaryAuraEvent(unit,{isFullUpdate=true});R.UpdateHost(h)
                assert(h._secondaryAuraSpellID==17 and hits==1,"same verified native aura object is already running")
                current={};R.UpdateHost(h);assert(rawequal(sink,current) and hits==2,"new native aura object binds")
                current=nil;R.UpdateHost(h);assert(h._secondaryAuraSpellID~=17,"withdrawn native-only clock cannot be held")
                shield.duration=0;shield.expirationTime=0;R.UpdateHost(h);assert(h._secondaryAuraSpellID==17)
                local calls=0;h.secondaryCooldown.Clear=function()calls=calls+1 end
                R.NoteSecondaryAuraEvent(unit,{isFullUpdate=true});R.UpdateHost(h)
                assert(calls==0 and h._secondaryAuraSpellID==17,"current permanent occurrence keeps its cleared clock")
            end)
            C_UnitAuras.GetAuraDuration=getter;assert(ok,err)
        end)
    end)
end
for _,unit in ipairs({"target","focus"}) do
    check(unit.." a helper-owned first cannot hide a higher native competitor",function()
        hostileSchoolCase(unit,function(h,state)
            local reader=C_UnitAuras.GetAuraDataByIndex
            local blocked=false
            C_UnitAuras.GetAuraDataByIndex=function(u,i,f)
                if blocked and f:match("^HELPFUL") then error("protected helpful index")end
                return reader(u,i,f)
            end
            harms={aura(853,301,97,6)};R.UpdateHost(h)
            assert(h._stunActive and h._secondaryAuraSpellID==1766)
            blocked=true;harms[2]=aura(772,201,96,10);R.UpdateHost(h,true)
            assert(h._secondaryAuraSpellID==1766,"lower Rend preserves the verified school runner")
            harms[2]=aura(5782,201,96,10);R.UpdateHost(h,true)
            assert(slot(h,"Control").en and h._secondaryAuraSpellID~=1766,"HoJ and native Fear both rank above Kick")
            blocked=false;R.UpdateHost(h,true);assert(h._secondaryAuraSpellID==5782,"fully visible runner is Fear")
            harms[2]=nil;state.rows[1].auraInstanceID=201;R.UpdateHost(h,true)
            blocked=true;harms[2]=aura(5782,201,96,10);R.UpdateHost(h,true)
            assert(h._secondaryAuraSpellID==1766,"a linked occurrence is not a third distinct effect")
            blocked=false;harms[2]=nil;state.rows[1].auraInstanceID=nil;R.UpdateHost(h,true)
            blocked=true;harms[2]=aura(5782,201,96,10)
            local lane=slot(h,"Control");local getter=lane.IsEnabled
            lane.IsEnabled=function()return false end
            R.UpdateHost(h);lane.IsEnabled=getter
            assert(h._secondaryAuraSpellID==1766,"affirmatively disabled native Control cannot promote Fear")
        end)
    end)
end
for _,unit in ipairs({"player","target","focus","party1"}) do
    local function regularHost()
        local h=host(unit)
        if unit=="party1" then
            h.unitFrame.IsShown=function()return true end
            h.portrait=region();h.unitFrame.Portrait=h.portrait;PartyFrame={MemberFrame1=h.unitFrame}
        end
        return h
    end
    check(unit.." unchanged confirmation keeps an accepted held-rank wakeup",function()
        local timer,party,refresh,clock=C_Timer,PartyFrame,R.Refresh,GetTime
        local ok,err=pcall(function()
            local h=regularHost();local now=100;local queued={};local refuse=false
            GetTime=function()return now end
            C_Timer={After=function(dt,callback)queued[#queued+1]={delay=dt,callback=callback};if refuse then return false end end}
            R.Refresh=function()R.UpdateHost(h)end
            harms={aura(853,301,97,6)};buffs={aura(17,222,98,30)}
            R.UpdateHost(h);sealed=true;R.UpdateHost(h)
            assert(#queued==1 and queued[1].delay==3 and h._secondaryAuraSpellID==17)
            refuse=true
            for i=1,3 do sealed=false;R.UpdateHost(h);sealed=true;R.UpdateHost(h) end
            assert(#queued==1 and h._secondaryAuraSpellID==17,"the original accepted deadline remains valid across equivalent fresh confirmations")
            now=103;queued[1].callback()
            assert(h._secondaryAuraSpellID~=17,"the preserved wake still retires a sealed rank at its deadline")
            now=100;sealed=false;refuse=false;R.UpdateHost(h);sealed=true;R.UpdateHost(h);local old=queued[#queued]
            sealed=false;harms[1].expirationTime=102;R.UpdateHost(h);refuse=true;sealed=true;R.UpdateHost(h)
            assert(h._secondaryAuraSpellID~=17,"a changed earlier deadline requires its own accepted wake")
            refuse=false;sealed=false;harms[1].expirationTime=103;R.UpdateHost(h)
            sealed=true;R.UpdateHost(h);local count=#queued;local prior=queued[count]
            sealed=false;harms[1].auraInstanceID=305;R.UpdateHost(h);sealed=true;R.UpdateHost(h)
            assert(#queued==count+1 and h._secondaryAuraSpellID==17,"same deadline with a different primary occurrence does not inherit its callback")
            local beforeBinding=queued[#queued]
            sealed=false;R.UpdateHost(h,false,true);sealed=true;R.UpdateHost(h);assert(#queued==count+2,"recipient barrier invalidates the old wake")
            now=103;beforeBinding.callback();prior.callback();old.callback()
            assert(h._secondaryAuraSpellID==17,"callbacks for superseded dependencies cannot revoke the new pair")
            queued[#queued].callback();assert(h._secondaryAuraSpellID~=17)
        end)
        C_Timer,PartyFrame,R.Refresh,GetTime=timer,party,refresh,clock;assert(ok,err)
    end)
    check(unit.." permanent runner commits only after its old clock is gone",function()
        local party=PartyFrame
        local ok,err=pcall(function()
            local h=regularHost();local c=h.secondaryCooldown
            local clear,hide,zero=true,true,true
            function c:Clear()if not clear then return false end;self.digits=nil end
            function c:Hide()if not hide then return false end;self.visible=false end
            function c:SetCooldown(start,duration)
                if duration==0 then if not zero then return false end;self.digits=nil else self.digits=start end
            end
            local shield,renew,devotion=aura(17,300,98,30),aura(139,200,97,15),aura(465,151,0,0)
            buffs={shield,renew,devotion};R.UpdateHost(h);assert(h._secondaryAuraSpellID==139 and c.digits==97 and c.visible)
            clear,hide,zero=false,false,false;buffs={shield,devotion};R.UpdateHost(h)
            assert(h._secondaryAuraSpellID~=465,"old digits cannot be committed with permanent Devotion")
            clear=true;R.UpdateHost(h)
            assert(h._secondaryAuraSpellID==465 and c.digits==nil,"later acknowledged Clear recovers the clockless icon")
            buffs={shield,renew,devotion};R.UpdateHost(h);assert(c.digits==97)
            clear,hide=false,true;buffs={shield,devotion};R.UpdateHost(h)
            assert(h._secondaryAuraSpellID==465 and not c.visible,"a positive Hide independently prevents old digits")
            buffs={shield,renew,devotion};R.UpdateHost(h);hide=false;zero=true;buffs={shield,devotion};R.UpdateHost(h)
            assert(h._secondaryAuraSpellID==465 and not c.digits,"an accepted numeric reset is also a valid cleanup")
        end)
        PartyFrame=party;assert(ok,err)
    end)
end
check("a current helpful native effect can also outrank a held Kick",function()
    hostileSchoolCase("player",function(h)
        hostile=false;harms={aura(853,301,97,6)};R.UpdateHost(h);assert(h._secondaryAuraSpellID==1766)
        sealed=true;buffs={aura(17,210,96,30)};R.UpdateHost(h)
        assert(h._secondaryAuraSpellID==1766,"a lower helpful Shield does not contradict the pair")
        buffs={aura(1022,210,96,10)};R.UpdateHost(h)
        assert(slot(h,"PhysicalImmunity").en and h._secondaryAuraSpellID~=1766,"a positive helpful physical-immunity lane outranks Kick")
        sealed=false;R.UpdateHost(h);assert(h._secondaryAuraSpellID==1022)
    end)
end)
for _,unit in ipairs({"target","focus"}) do
    check(unit.." keeps a corroborated fractional recipient deadline",function()
        hostileSchoolCase(unit,function(h,state)
            local clock,same=GetTime,UnitIsUnit
            local ok,err=pcall(function()
                GetTime=function()return 100.2 end
                UnitIsUnit=function(a,b)return a==b or a==unit and b=="player" end
                local own={locType="SCHOOL_INTERRUPT",spellID=1766,iconTexture=1766,startTime=97.1,auraInstanceID=42}
                local peer={locType="SCHOOL_INTERRUPT",spellID=1766,iconTexture=1766,duration=5,timeRemaining=1.9,auraInstanceID=42}
                state.rows={own}
                C_LossOfControl.GetActiveLossOfControlDataCountByUnit=function(u)return u==unit and 1 or 0 end
                C_LossOfControl.GetActiveLossOfControlDataCount=function()return 1 end
                C_LossOfControl.GetActiveLossOfControlData=function()return peer end
                harms={aura(853,300,99,6)}
                h.secondaryCooldown.SetCooldown=function(s,start,duration)s.finish=start+duration end
                R.UpdateHost(h,true)
                assert(h._schoolInterrupt.expires==own.startTime+5 and h.secondaryCooldown.finish==own.startTime+5,
                    "mathematically equal decimal deadlines must authorize the numeric clock")
                peer.timeRemaining=1.91;R.UpdateHost(h,true)
                assert(not h._schoolInterrupt.expires,"a genuine interval contradiction still rejects the borrowed timer")
                peer.timeRemaining=1.9;peer.startTime=97.09999999999998;R.UpdateHost(h,true)
                assert(h._schoolInterrupt.startTime==own.startTime and not h._schoolInterrupt.expires,
                    "a nearby but distinct application time cannot enrich the later observation")
            end)
            GetTime,UnitIsUnit=clock,same;assert(ok,err)
        end)
    end)
    check(unit.." native rank is recomputed when the application time becomes readable during overflow",function()
        hostileSchoolCase(unit,function(h,state)
            local same=UnitIsUnit
            local ok,err=pcall(function()
                UnitIsUnit=function(a,b)if b:match("^nameplate") then error("restricted") end;return a==b end
                local pummel={locType="SCHOOL_INTERRUPT",spellID=6552,timeRemaining=5}
                state.rows={{locType="SCHOOL_INTERRUPT",spellID=1766,startTime=96,duration=8,auraInstanceID=30},pummel}
                R.UpdateHost(h);assert(h._schoolInterrupt.spellID==1766 and h._secondaryAuraSpellID==6552)
                for i=1,9 do R.NoteUnresolvedInterruptAlias(h,"nameplate"..i) end
                pummel.startTime,pummel.duration=99,6
                for i=1,3 do R.UpdateHost(h) end
                assert(h._schoolInterrupt.spellID==6552 and h._secondaryAuraSpellID==1766,"new start changes order with the same expiry")
                local get=C_LossOfControl.GetActiveLossOfControlDataByUnit;local probes=0
                C_LossOfControl.GetActiveLossOfControlDataByUnit=function(...)probes=probes+1;return get(...)end
                for i=1,6 do R.UpdateHost(h) end
                assert(probes==6,"unchanged overflow keeps its one-row budget after learning the start")
            end)
            UnitIsUnit=same;assert(ok,err)
        end)
    end)
    check(unit.." merges aura-linked school records before retaining the genuine runner",function()
        hostileSchoolCase(unit,function(h,state)
            local a={locType="SCHOOL_INTERRUPT",spellID=1766,startTime=99,duration=8}
            local b={locType="SCHOOL_INTERRUPT",spellID=1767,startTime=98,duration=8,auraInstanceID=91}
            local c={locType="SCHOOL_INTERRUPT",spellID=6552,startTime=97,duration=5,handle={}}
            h.secondaryCooldown.SetCooldownFromDurationObject=function(s,object)s.bound=object;s.binds=(s.binds or 0)+1;return true end
            local oldTime=GetTime;local now=100;GetTime=function()return now end
            local ok,err=pcall(function()
                state.rows={a,b,c};harms={aura(1766,91,98,8)};buffs={aura(17,250,95,30)}
                R.UpdateHost(h)
                assert(h._secondSchoolInterrupt.spellID==6552 and h._secondaryAuraSpellID==6552,
                    "two linked labels are one effect and the remaining confirmed Pummel outranks Shield")
                assert(rawequal(h.secondaryCooldown.bound,c.handle) and h._schoolInterruptDeadline==102,
                    "the replacement owns its clock and bounds the host deadline")
                local installs=h.secondaryCooldown.binds;local previous=h._secondSchoolInterrupt
                for i=1,6 do
                    local first,second,complete,unresolved,playerRank=R.GetSchoolInterrupt(unit)
                    R.UpdateHost(h,false,false,false,{host=h,record=first,second=second,complete=complete,
                        unresolvedSelf=unresolved,rankUsesPlayer=playerRank})
                end
                assert(h._secondSchoolInterrupt==previous and h.secondaryCooldown.binds==installs,
                    "unchanged indexed-only notifications preserve the same ranked Pummel and its installed clock")
                state.rows={c,b,a};R.UpdateHost(h,true);assert(h._secondaryAuraSpellID==6552)
                harms={};sealed=true;R.NoteSecondaryAuraEvent(unit,{isFullUpdate=false,removedAuraInstanceIDs={91}});R.UpdateHost(h)
                assert(h._secondaryAuraSpellID~=6552,"removing the bridge revokes the held runner even while the index is sealed")
                sealed=false;R.UpdateHost(h)
                assert(h._secondaryAuraSpellID==1767,"when the bridge disappears the original school order applies")
                harms={aura(1766,91,98,8)};R.NoteSecondaryAuraEvent(unit,{isFullUpdate=false,addedAuras=harms});R.UpdateHost(h)
                assert(h._secondaryAuraSpellID==6552,"a bridge obtained from the indexed API restores the genuine runner")
                now=102;R.UpdateHost(h)
                assert(h._secondaryAuraSpellID==17 and not h._secondaryDisplayedInterrupt,"the expired replacement cannot retain its art")
                now=100;state.rows={b,a,c};a.startTime=98;R.UpdateHost(h,true)
                assert(h._schoolInterrupt.spellID==1766 and h._secondaryAuraSpellID==6552,"equal-time ordering stays deterministic")
                for _,other in ipairs({1767,6552,772}) do
                    local x,y=aura(1766,91,98,8),aura(other,91,98,8)
                    harms={x,y};local _,one=R.GetSchoolInterrupt(unit)
                    harms={y,x};local _,two=R.GetSchoolInterrupt(unit)
                    assert(one.spellID==1767 and two.spellID==1767,"contradictory indexed identities cannot select a bridge by order")
                end
            end)
            GetTime=oldTime;assert(ok,err)
        end)
    end)
end
assert(#failures==0,table.concat(failures,"\n"))
print("PASS secondary ownership, occurrence clocks, filter polarity, Ghost and low hostile fallback")
