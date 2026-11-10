local addonName, BP = ...
local R = assert(BP.Runtime, "Core.lua must load first")

-- A binding/name event may run before Blizzard's current-unit state settles.
-- Coalesce ONE next-tick reconciliation, reading the live token again. Never
-- cache a unit's aura identity, borrow Target's result for Focus, or self-poll.
local tracked = {}
for _, unit in ipairs(R.TRACKED_UNITS) do tracked[unit] = true end
local derived = {targettarget=true, focustarget=true}
local queued, scheduled = {}, false
local postNativeLayouts = {}
local snapshotNeeded = {}
local layoutReasons = {["world-entry"]=true, ["native-portrait"]=true, ["native-binding"]=true,
    ["native-party-binding"]=true, ["settling-binding"]=true, ["derived-binding"]=true,
    ["party-pool"]=true, ["party-layout"]=true, ["party-roster"]=true}
local function publishDerivedSnapshot(unit)
    if R.PublishDerivedSnapshot then
        -- Only an explicit unavailable result retains work for a later event.
        -- A completed pass (including an empty one) consumes the request.
        snapshotNeeded[unit] = R.PublishDerivedSnapshot(unit) == false or nil
    end
end
local function queueRefresh(unit, reason, requestSnapshot, snapshotOnly)
    if not R.CanAccess(unit) or type(unit) ~= "string" or not tracked[unit] then return end
    local needsSnapshot = derived[unit] and (reason == "derived-binding" or requestSnapshot)
    if not C_Timer or type(C_Timer.After) ~= "function" then
        if needsSnapshot then snapshotNeeded[unit] = true end
        return
    end
    local request = queued[unit]
    if not request then request = {}; queued[unit] = request end
    -- Visual work can upgrade a snapshot-only request, never be cancelled by it.
    request.refresh = request.refresh or not snapshotOnly
    if not snapshotOnly or not request.reason then request.reason = reason or "unit-event" end
    if reason == "native-binding" or reason == "world-entry" then request.bindingChanged = true end
    if reason == "settling-binding" then request.settlingBinding = true end
    if reason == "aura-clock" then request.layoutHost = R.hosts[unit] end
    if layoutReasons[reason] then request.verifyLayout = true end
    -- Later visual reasons must not cancel evidence work already requested.
    if needsSnapshot then
        request.publishDerivedSnapshot = true
    end
    if scheduled then return true end
    scheduled = true
    local ok, result = pcall(C_Timer.After, 0, function()
        local pending = queued
        queued, scheduled = {}, false
        if not R.db or not R.db.enabled then snapshotNeeded = {}; return end
        local lateLayouts
        for token, request in pairs(pending) do
            if request.refresh then
                local host=R.hosts[token]
                if request.settlingBinding and host then
                    host._verifySettledBinding, host._schoolInterruptSettling=true,true
                end
                R.Refresh(token,true,request.bindingChanged==true,true)
            end
            if request.publishDerivedSnapshot and R.PublishDerivedSnapshot then
                publishDerivedSnapshot(token)
            end
            if request.refresh then
                if R.hosts[token] then R.hosts[token]._nativeRefreshReason = request.reason end
                if token == "pet" then
                    R.UpdateLocalPetPortrait()
                elseif token ~= "player" and not R.PARTY_UNITS[token] then
                    R.UpdateObservedPetPortrait(token)
                end
                R.ApplyPresentation(token,true,request.verifyLayout==true)
            end
            local host=request.layoutHost
            if host and R.hosts[token]==host and host._pendingClockLayouts then
                lateLayouts=lateLayouts or {}
                lateLayouts[host]=true
            end
        end
        if lateLayouts then
            -- Native aura assignments run in OnUpdate. Leave a full frame
            -- between the event batch and this one check of its pending clocks.
            -- Hidden and inaccessible receivers never reschedule themselves.
            -- A host discovered in this batch cannot share an already-due
            -- timer from a different batch. Clear only our own reservations.
            for host in pairs(lateLayouts) do postNativeLayouts[host]=lateLayouts end
            local function finish(retry)
                if not lateLayouts then return end
                local batch=lateLayouts
                lateLayouts=nil
                for host in pairs(batch) do
                    if postNativeLayouts[host]==batch then postNativeLayouts[host]=nil end
                end
                if retry then
                    for host in pairs(batch) do R.RetryPostAuraLayouts(host) end
                end
            end
            local ok,result=pcall(C_Timer.After,0,function() finish(true) end)
            if not ok or not R.CanAccess(result) or result==false then finish(false) end
        end
    end)
    if not ok or not R.CanAccess(result) or result==false then
        if needsSnapshot then snapshotNeeded[unit] = true end
        queued, scheduled = {}, false
        return false
    end
    return true
end

local function refreshAuraToken(unit)
    local request=queued[unit]
    local host=R.hosts[unit]
    local willCheck=(host and postNativeLayouts[host])
        or (request and (request.refresh or (host and request.layoutHost==host)))
    R.Refresh(unit,false,nil,willCheck)
    host=R.hosts[unit]
    if not host or host._unitAuraSuppressed or host._staleBinding
        or host._restorePending or not R.RetryPostAuraLayouts or not R.IsUnitEnabled(unit) then return end
    local combat,known=R.SafeBool(InCombatLockdown)
    if not known or combat then return end
    if not (request and request.layoutHost==host) and R.NoteAuraClockVisibility then R.NoteAuraClockVisibility(host) end
    if host._pendingClockLayouts then queueRefresh(unit,"aura-clock",false,true) end
end

function R.QueueDerivedSnapshots()
    for unit in pairs(derived) do queueRefresh(unit, "derived-recovery", true) end
end

-- Native Focus may finish a portrait refresh or rebind without another
-- PLAYER_FOCUS_CHANGED. Observe those completed writes, not their secret data.
-- Compact portraits are deliberately excluded: their native updates can run
-- every frame. The callback only schedules the existing one-shot reconciler.
local nativePortraitHooked, nativeBindingHooked = false, false
local partyPoolInitHooked, partyPoolUpdateHooked = false, false
local function queuePartyRefresh(reason)
    for index = 1, 4 do queueRefresh("party" .. index, reason or "party-roster") end
end
local function installNativePortraitHooks()
    -- PartyFrame creates pooled member frames when it first becomes visible
    -- and may recycle them on roster/Edit Mode transitions. Hook only the
    -- completed native pool/layout writes, never replace Blizzard methods.
    local partyFrame = _G.PartyFrame
    if partyFrame and type(hooksecurefunc) == "function" then
        if not partyPoolInitHooked and type(partyFrame.InitializePartyMemberFrames) == "function" then
            partyPoolInitHooked = pcall(hooksecurefunc, partyFrame,
                "InitializePartyMemberFrames", function() queuePartyRefresh("party-pool") end)
        end
        if not partyPoolUpdateHooked and type(partyFrame.UpdatePartyFrames) == "function" then
            partyPoolUpdateHooked = pcall(hooksecurefunc, partyFrame,
                "UpdatePartyFrames", function() queuePartyRefresh("party-layout") end)
        end
    end
    if type(hooksecurefunc) ~= "function" then return end
    if not nativePortraitHooked and type(UnitFramePortrait_Update) == "function" then
        nativePortraitHooked = pcall(hooksecurefunc, "UnitFramePortrait_Update", function(frame)
            if frame == _G.FocusFrame then queueRefresh("focus", "native-portrait") end
        end)
    end
    if not nativeBindingHooked and type(UnitFrame_SetUnit) == "function" then
        nativeBindingHooked = pcall(hooksecurefunc, "UnitFrame_SetUnit", function(frame)
            if frame == _G.PlayerFrame then
                R.Refresh("player", true)
            elseif frame == _G.PetFrame then
                if R.CheckNativeUnitBinding then R.CheckNativeUnitBinding("pet") end
                R.UpdateLocalPetPortrait()
                queueRefresh("pet", "native-binding")
            elseif frame == _G.FocusFrame or frame == _G.TargetFrame then
                local unit=frame == _G.FocusFrame and "focus" or "target"
                local host=R.hosts[unit]
                if host and (host._schoolInterrupt or host._schoolInterruptRankUsesPlayer) and R.GetSchoolInterrupt then
                    local record,second,complete,unresolvedSelf,rankUsesPlayer=R.GetSchoolInterrupt(unit)
                    R.Refresh(unit,false,true,true,{host=host,record=record,second=second,
                        complete=complete and not unresolvedSelf,unresolvedSelf=unresolvedSelf,rankUsesPlayer=rankUsesPlayer})
                end
                queueRefresh(unit, "native-binding")
                queueRefresh(unit.."target", "native-binding")
            else
                -- Native party member frames can rebind to vehicles, or to
                -- player-only placeholders in Edit Mode. Never use their
                -- previous occupant; re-evaluate the real partyN token.
                local token = R.ReadAuraField(frame,"unitToken")
                if type(token)~="string" or not R.PARTY_UNITS[token] then token=nil end
                local outgoing=R.CheckOutgoingPartyFrame and R.CheckOutgoingPartyFrame(frame,token)
                if outgoing and outgoing~=token then queueRefresh(outgoing,"native-party-binding") end
                if token then
                    if outgoing~=token and R.CheckNativeUnitBinding then R.CheckNativeUnitBinding(token) end
                    queueRefresh(token, "native-party-binding")
                end
            end
        end)
    end
end

local events = CreateFrame("Frame")
R.eventFrame = events
for _, event in ipairs({
    "ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED",
    "PLAYER_DEAD", "PLAYER_ALIVE", "PLAYER_UNGHOST",
    "PLAYER_TARGET_CHANGED", "PLAYER_FOCUS_CHANGED", "PET_BAR_UPDATE",
    "GROUP_ROSTER_UPDATE",
}) do events:RegisterEvent(event) end

-- Optional native events differ across supported clients; an unsupported
-- event must not prevent the rest of the addon from loading.
for _, event in ipairs({"LOSS_OF_CONTROL_ADDED", "LOSS_OF_CONTROL_UPDATE",
    "UI_SCALE_CHANGED", "DISPLAY_SIZE_CHANGED", "UPDATE_SHAPESHIFT_FORM", "UPDATE_SHAPESHIFT_FORMS",
    "PARTY_MEMBER_ENABLE", "PARTY_MEMBER_DISABLE", "UNIT_OTHER_PARTY_CHANGED"}) do
    pcall(events.RegisterEvent, events, event)
end

events:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == "Blizzard_UnitFrame" then installNativePortraitHooks() end
        if arg1 ~= addonName then return end
        R.ApplyDefaults()
        return
    end

    if not R.db then R.ApplyDefaults() end

    if event == "LOSS_OF_CONTROL_ADDED" or event == "LOSS_OF_CONTROL_UPDATE" then
        if not R.db.enabled or not R.GetSchoolInterrupt then return end
        local hasUnit = R.CanAccess(arg1) and type(arg1) == "string" and arg1 ~= ""
        for unit, host in pairs(R.hosts) do
            local matches = not hasUnit or unit == arg1
            local uncertain
            if not matches then
                local same, known = R.SafeBool(UnitIsUnit, unit, arg1)
                uncertain = not known and (unit == "target" or unit == "focus")
                matches = same or uncertain or (arg1=="player" and R.InterruptUsesPlayer and R.InterruptUsesPlayer(host))
                    or (not known and ((host._schoolInterrupt and not host._schoolInterrupt.expires)
                    or (host._secondSchoolInterrupt and not host._secondSchoolInterrupt.expires)))
            end
            if matches and host.schoolInterruptFrame and R.IsUnitEnabled(unit) then
                -- Query the current occupant of each matching portrait; the
                -- event index is not a stable identifier across alias tokens.
                local record, second, complete, unresolvedSelf, rankUsesPlayer = R.GetSchoolInterrupt(unit)
                if unresolvedSelf or uncertain then complete=false end
                if record or host._schoolInterrupt or host._schoolInterruptHidePending or host._schoolInterruptRankUsesPlayer then
                    R.Refresh(unit, false, false, false, {host=host, record=record, second=second, complete=complete,
                        unresolvedSelf=unresolvedSelf,alias=uncertain and arg1 or nil,rankUsesPlayer=rankUsesPlayer})
                else
                    -- A positive count with inaccessible rows can recover on
                    -- an ordinary event. A proven empty result needs no retry.
                    if unresolvedSelf then R.NoteUnresolvedInterruptAlias(host,"player") end
                    if uncertain then R.NoteUnresolvedInterruptAlias(host,arg1) end
                    host._schoolInterruptRankUsesPlayer=rankUsesPlayer
                    host._schoolInterruptRetries = complete == false and 2 or nil
                end
            end
        end
    elseif event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        R.RetryCountdownFormatter()
        installNativePortraitHooks()
        R.BuildAll()
        R.UpdatePetPortraits()
        if R.PublishDerivedSnapshot then
            publishDerivedSnapshot("targettarget")
            publishDerivedSnapshot("focustarget")
        end
        -- Identity may become readable only after the immediate world pass.
        for _, token in ipairs(R.TRACKED_UNITS) do queueRefresh(token, "world-entry", snapshotNeeded[token]) end
    elseif event == "PLAYER_REGEN_ENABLED" then
        R.RetryCountdownFormatter()
        if R.forceRebuildQueued then
            R.forceRebuildQueued = false
            R.DestroyAll()
        end
        if R.buildQueued then
            R.BuildAll(true)
            R.UpdatePetPortraits()
        end
        -- Existing hosts also need fresh eligibility after restrictions lift;
        -- a host build request is not required for a stale disabled aura lane.
        R.RefreshAll(true)
        R.ApplyPresentation()
        for token in pairs(snapshotNeeded) do
            queueRefresh(token, "combat-exit", true, true)
        end
    elseif event == "UI_SCALE_CHANGED" or event == "DISPLAY_SIZE_CHANGED" then
        R.ApplyPresentation(nil,true,true)
    elseif event == "PLAYER_DEAD" or event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
        R.Refresh("player", true)
        -- Death/release can settle after the event and is also visible through
        -- Target/Focus aliases. One deferred pass rereads each current token.
        for _, token in ipairs(R.TRACKED_UNITS) do queueRefresh(token, "ghost-transition") end
    elseif event == "PLAYER_TARGET_CHANGED" then
        R.Refresh("target", true, true)
        R.Refresh("targettarget", true)
        R.UpdateObservedPetPortrait("target")
        R.UpdateObservedPetPortrait("targettarget")
        queueRefresh("target","settling-binding"); queueRefresh("targettarget", "derived-binding")
    elseif event == "PLAYER_FOCUS_CHANGED" then
        R.Refresh("focus", true, true)
        R.Refresh("focustarget", true)
        R.UpdateObservedPetPortrait("focus")
        R.UpdateObservedPetPortrait("focustarget")
        queueRefresh("focus","settling-binding"); queueRefresh("focustarget", "derived-binding")
    elseif event == "UPDATE_SHAPESHIFT_FORM" or event == "UPDATE_SHAPESHIFT_FORMS" then
        for _, token in ipairs(R.TRACKED_UNITS) do
            if token == "player" or (R.IsPlayerStanceUnit and R.IsPlayerStanceUnit(token)) then
                R.Refresh(token, true)
                queueRefresh(token, "stance-transition")
            end
        end
    elseif event == "PET_BAR_UPDATE" then
        R.UpdateLocalPetPortrait()
        queueRefresh("pet", "pet-bar")
    elseif event == "GROUP_ROSTER_UPDATE" or event == "PARTY_MEMBER_ENABLE"
        or event == "PARTY_MEMBER_DISABLE" or event == "UNIT_OTHER_PARTY_CHANGED"
    then
        queuePartyRefresh("party-roster")
    end
end)

-- High-frequency unit state events are scoped to only the six tokens this addon
-- owns. Dense hubs can emit large amounts of unrelated UNIT_AURA/FLAGS/FACTION
-- traffic; RegisterUnitEvent keeps that traffic out of addon Lua entirely.
local unitStateFrames = {}
local function installUnitStateEvents(unitA, unitB)
    local frame = CreateFrame("Frame")
    local function register(event)
        if unitB then frame:RegisterUnitEvent(event, unitA, unitB)
        else frame:RegisterUnitEvent(event, unitA) end
    end
    register("UNIT_AURA")
    -- Form changes are observable even while hostile aura identity is sealed.
    -- A scoped display-power event is much cheaper than polling resource APIs.
    register("UNIT_DISPLAYPOWER")
    pcall(register, "UNIT_FORM_CHANGED")
    register("UNIT_FACTION")
    register("UNIT_FLAGS")
    register("UNIT_CONNECTION")
    register("UNIT_PORTRAIT_UPDATE")
    register("UNIT_NAME_UPDATE")
    frame:SetScript("OnEvent", function(_, event, unit, updateInfo)
        if not R.CanAccess(unit) or type(unit) ~= "string" or not tracked[unit] then return end
        if event == "UNIT_PORTRAIT_UPDATE" or event == "UNIT_NAME_UPDATE" then
            -- These events also signal late current-unit availability. Refresh
            -- the independent pet art now, then re-evaluate aura eligibility.
            if R.CheckNativeUnitBinding then R.CheckNativeUnitBinding(unit) end
            if unit == "pet" then R.UpdateLocalPetPortrait()
            elseif unit ~= "player" and not R.PARTY_UNITS[unit] then
                R.UpdateObservedPetPortrait(unit)
            end
            queueRefresh(unit, event=="UNIT_PORTRAIT_UPDATE" and "native-portrait" or "unit-availability", snapshotNeeded[unit])
            return
        end
        if unit == "player" and (event == "UNIT_FACTION" or event == "UNIT_FLAGS") then
            -- Every host's exact filter permission depends on the player's
            -- relation, so these player events invalidate all six hosts.
            R.RefreshAll(true,true)
            R.UpdateObservedPetPortraits()
            -- Player relation changes can unblock retained derived evidence too.
            for _, token in ipairs(R.TRACKED_UNITS) do
                if not queueRefresh(token,nil,snapshotNeeded[token]) then R.ApplyPresentation(token,true,false) end
            end
        elseif event == "UNIT_AURA" then
            if R.NoteSecondaryAuraEvent then R.NoteSecondaryAuraEvent(unit, updateInfo) end
            if R.PublishAuraEvent then R.PublishAuraEvent(unit, updateInfo) end
            refreshAuraToken(unit)
            -- A positive self Target/Focus alias must update alongside the
            -- actual PlayerFrame aura event. Forever may notify "player"
            -- without separately notifying "target"/"focus"; otherwise the
            -- mirrored second can keep obsolete artwork or miss a new buff.
            -- This is strictly identity-gated and never refreshes a different
            -- player's protected auras on the basis of matching names.
            if unit == "player" and type(UnitIsUnit) == "function"
                and type(R.SafeBool) == "function" then
                for _, alias in ipairs({"target","focus"}) do
                    local same, readable = R.SafeBool(UnitIsUnit, alias, "player")
                    if readable and same then
                        if R.NoteSecondaryAuraEvent then
                            R.NoteSecondaryAuraEvent(alias, updateInfo)
                        end
                        refreshAuraToken(alias)
                    elseif R.InterruptUsesPlayer and R.InterruptUsesPlayer(R.hosts[alias]) then
                        -- The current token must shed formerly borrowed player
                        -- evidence. Do not deliver the player's aura delta.
                        R.Refresh(alias)
                    end
                end
            end
            -- A completed binding can still gain readable timing or a new
            -- positive on a full update. Re-read the bounded shortlist through
            -- the same one-shot queue; these remain first sightings/corrections.
            -- Pending availability recovery retains its full visual refresh.
            if derived[unit] and (snapshotNeeded[unit] or not R.CanSkipDerivedSnapshot
                or not R.CanSkipDerivedSnapshot(unit, updateInfo)) then
                queueRefresh(unit, "derived-evidence", true, not snapshotNeeded[unit])
            end
        elseif event == "UNIT_DISPLAYPOWER" or event == "UNIT_FORM_CHANGED" then
            -- Re-evaluate the current primary power once immediately and
            -- once after Blizzard completes the form transition. No polling.
            R.Refresh(unit)
            queueRefresh(unit, event == "UNIT_FORM_CHANGED" and "stance-transition" or "power-type")
            return
        else
            R.Refresh(unit,true,nil,true)
            if not queueRefresh(unit,nil,snapshotNeeded[unit]) then R.ApplyPresentation(unit,true,false) end
        end
        -- Aura changes do not change pet identity/family. Reclassify only on
        -- relation/state changes, and only for the unit that actually changed.
        if event ~= "UNIT_AURA"
            and (unit == "target" or unit == "focus"
                or unit == "targettarget" or unit == "focustarget")
        then
            R.UpdateObservedPetPortrait(unit)
        end
    end)
    unitStateFrames[#unitStateFrames + 1] = frame
end

-- Keep the stable cross-client RegisterUnitEvent shape to at most two unit tokens.
installUnitStateEvents("player", "target")
installUnitStateEvents("focus", "targettarget")
installUnitStateEvents("focustarget", "pet")
installUnitStateEvents("party1", "party2")
installUnitStateEvents("party3", "party4")

-- PLAYER_TARGET_CHANGED / PLAYER_FOCUS_CHANGED already own the outer tokens.
-- UNIT_TARGET is needed only when target/focus changes its own target, which
-- rebinds the derived ToT/FoT tokens.
local unitTargetEvents = CreateFrame("Frame")
unitTargetEvents:RegisterUnitEvent("UNIT_TARGET", "target", "focus")
unitTargetEvents:SetScript("OnEvent", function(_, _, unit)
    if unit == "target" then
        R.Refresh("targettarget", true)
        R.UpdateObservedPetPortrait("targettarget")
        queueRefresh("targettarget", "derived-binding")
    elseif unit == "focus" then
        R.Refresh("focustarget", true)
        R.UpdateObservedPetPortrait("focustarget")
        queueRefresh("focustarget", "derived-binding")
    end
end)

-- Pet ownership may change without an aura event. Reconcile the native
-- family foundation immediately and the secure aura host at the next stable
-- event boundary. UNIT_AURA itself uses the common scoped unit-state route.
local unitPetEvents = CreateFrame("Frame")
unitPetEvents:RegisterUnitEvent("UNIT_PET", "player")
unitPetEvents:SetScript("OnEvent", function()
    R.UpdateLocalPetPortrait()
    R.Refresh("pet", true)
    queueRefresh("pet", "pet-binding")
end)

installNativePortraitHooks()
