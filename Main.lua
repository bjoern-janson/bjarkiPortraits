local addonName, BP = ...
local R = assert(BP.Runtime, "Core.lua must load first")

-- A binding/name event may run before Blizzard's current-unit state settles.
-- Coalesce ONE next-tick reconciliation, reading the live token again. Never
-- cache a unit's aura identity, borrow Target's result for Focus, or self-poll.
local tracked = {}
for _, unit in ipairs(R.TRACKED_UNITS) do tracked[unit] = true end
local queued, scheduled = {}, false
local function queueRefresh(unit, reason)
    if not R.CanAccess(unit) or type(unit) ~= "string" or not tracked[unit]
        or not C_Timer or type(C_Timer.After) ~= "function" then return end
    queued[unit] = reason or "unit-event"
    if scheduled then return end
    scheduled = true
    local ok = pcall(C_Timer.After, 0, function()
        local pending = queued
        queued, scheduled = {}, false
        if not R.db or not R.db.enabled then return end
        for token, why in pairs(pending) do
            R.Refresh(token, true)
            if R.hosts[token] then R.hosts[token]._nativeRefreshReason = why end
            if token ~= "player" then R.UpdateObservedPetPortrait(token) end
            R.ApplyPresentation(token)
        end
    end)
    if not ok then queued, scheduled = {}, false end
end

-- Native Focus may finish a portrait refresh or rebind without another
-- PLAYER_FOCUS_CHANGED. Observe those completed writes, not their secret data.
-- Compact portraits are deliberately excluded: their native updates can run
-- every frame. The callback only schedules the existing one-shot reconciler.
local nativePortraitHooked, nativeBindingHooked = false, false
local function installNativePortraitHooks()
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
                R.UpdateLocalPetPortrait()
            elseif frame == _G.FocusFrame then
                queueRefresh("focus", "native-binding")
                queueRefresh("focustarget", "native-binding")
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
}) do events:RegisterEvent(event) end

events:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == "Blizzard_UnitFrame" then installNativePortraitHooks() end
        if arg1 ~= addonName then return end
        R.ApplyDefaults()
        return
    end

    if not R.db then R.ApplyDefaults() end

    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        installNativePortraitHooks()
        R.BuildAll()
        R.UpdatePetPortraits()
        for _, token in ipairs(R.TRACKED_UNITS) do queueRefresh(token) end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if R.forceRebuildQueued then
            R.forceRebuildQueued = false
            R.DestroyAll()
        end
        if R.buildQueued then
            R.BuildAll()
            R.UpdatePetPortraits()
        end
        -- Existing hosts also need fresh eligibility after restrictions lift;
        -- a host build request is not required for a stale disabled aura lane.
        R.RefreshAll(true)
        R.ApplyPresentation()
    elseif event == "PLAYER_DEAD" or event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
        R.Refresh("player", true)
        -- Death/release can settle after the event and is also visible through
        -- Target/Focus aliases. One deferred pass rereads each current token.
        for _, token in ipairs(R.TRACKED_UNITS) do queueRefresh(token, "ghost-transition") end
    elseif event == "PLAYER_TARGET_CHANGED" then
        R.Refresh("target", true)
        R.Refresh("targettarget", true)
        R.UpdateObservedPetPortrait("target")
        R.UpdateObservedPetPortrait("targettarget")
        queueRefresh("target"); queueRefresh("targettarget")
    elseif event == "PLAYER_FOCUS_CHANGED" then
        R.Refresh("focus", true)
        R.Refresh("focustarget", true)
        R.UpdateObservedPetPortrait("focus")
        R.UpdateObservedPetPortrait("focustarget")
        queueRefresh("focus"); queueRefresh("focustarget")
    elseif event == "PET_BAR_UPDATE" then
        R.UpdateLocalPetPortrait()
    end
end)

-- High-frequency unit state events are scoped to only the five tokens this addon
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
    register("UNIT_FACTION")
    register("UNIT_FLAGS")
    register("UNIT_CONNECTION")
    register("UNIT_PORTRAIT_UPDATE")
    register("UNIT_NAME_UPDATE")
    frame:SetScript("OnEvent", function(_, event, unit)
        if not unit then return end
        if event == "UNIT_PORTRAIT_UPDATE" or event == "UNIT_NAME_UPDATE" then
            -- These events also signal late current-unit availability. Refresh
            -- the independent pet art now, then re-evaluate aura eligibility.
            if unit ~= "player" then R.UpdateObservedPetPortrait(unit) end
            queueRefresh(unit)
            return
        end
        if unit == "player" and (event == "UNIT_FACTION" or event == "UNIT_FLAGS") then
            -- Every host's exact filter permission depends on the player's
            -- relation, so these player events invalidate all five hosts.
            R.RefreshAll(true)
            R.UpdateObservedPetPortraits()
            for _, token in ipairs(R.TRACKED_UNITS) do queueRefresh(token) end
        elseif event == "UNIT_AURA" then
            R.Refresh(unit)
        elseif event == "UNIT_DISPLAYPOWER" then
            -- Re-evaluate the current primary power once immediately and
            -- once after Blizzard completes the form transition. No polling.
            R.Refresh(unit)
            queueRefresh(unit, "power-type")
            return
        else
            R.Refresh(unit, true)
            queueRefresh(unit)
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
installUnitStateEvents("focustarget")

-- PLAYER_TARGET_CHANGED / PLAYER_FOCUS_CHANGED already own the outer tokens.
-- UNIT_TARGET is needed only when target/focus changes its own target, which
-- rebinds the derived ToT/FoT tokens.
local unitTargetEvents = CreateFrame("Frame")
unitTargetEvents:RegisterUnitEvent("UNIT_TARGET", "target", "focus")
unitTargetEvents:SetScript("OnEvent", function(_, _, unit)
    if unit == "target" then
        R.Refresh("targettarget", true)
        R.UpdateObservedPetPortrait("targettarget")
        queueRefresh("targettarget")
    elseif unit == "focus" then
        R.Refresh("focustarget", true)
        R.UpdateObservedPetPortrait("focustarget")
        queueRefresh("focustarget")
    end
end)

-- Only the player's pet can affect the local PetFrame foundation.
local unitPetEvents = CreateFrame("Frame")
unitPetEvents:RegisterUnitEvent("UNIT_PET", "player")
unitPetEvents:RegisterUnitEvent("UNIT_PORTRAIT_UPDATE", "pet")
unitPetEvents:SetScript("OnEvent", function()
    R.UpdateLocalPetPortrait()
end)

installNativePortraitHooks()
