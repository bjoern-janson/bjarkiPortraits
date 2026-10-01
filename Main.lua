local addonName, BP = ...
local R = assert(BP.Runtime, "Core.lua must load first")

local events = CreateFrame("Frame")
R.eventFrame = events
for _, event in ipairs({
    "ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED",
    "PLAYER_DEAD", "PLAYER_ALIVE", "PLAYER_UNGHOST",
    "PLAYER_TARGET_CHANGED", "PLAYER_FOCUS_CHANGED", "PET_BAR_UPDATE",
}) do events:RegisterEvent(event) end

events:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= addonName then return end
        R.ApplyDefaults()
        return
    end

    if not R.db then R.ApplyDefaults() end

    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        R.BuildAll()
        R.UpdatePetPortraits()
    elseif event == "PLAYER_REGEN_ENABLED" then
        if R.forceRebuildQueued then
            R.forceRebuildQueued = false
            R.DestroyAll()
        end
        if R.buildQueued then R.BuildAll() end
    elseif event == "PLAYER_DEAD" or event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
        R.Refresh("player", true)
    elseif event == "PLAYER_TARGET_CHANGED" then
        R.Refresh("target", true)
        R.Refresh("targettarget", true)
        R.UpdateObservedPetPortrait("target")
        R.UpdateObservedPetPortrait("targettarget")
    elseif event == "PLAYER_FOCUS_CHANGED" then
        R.Refresh("focus", true)
        R.Refresh("focustarget", true)
        R.UpdateObservedPetPortrait("focus")
        R.UpdateObservedPetPortrait("focustarget")
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
    register("UNIT_FACTION")
    register("UNIT_FLAGS")
    register("UNIT_CONNECTION")
    frame:SetScript("OnEvent", function(_, event, unit)
        if not unit then return end
        if event == "UNIT_AURA" then
            R.Refresh(unit)
        else
            R.Refresh(unit, true)
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
    elseif unit == "focus" then
        R.Refresh("focustarget", true)
        R.UpdateObservedPetPortrait("focustarget")
    end
end)

-- Only the player's pet can affect the local PetFrame foundation.
local unitPetEvents = CreateFrame("Frame")
unitPetEvents:RegisterUnitEvent("UNIT_PET", "player")
unitPetEvents:SetScript("OnEvent", function()
    R.UpdateLocalPetPortrait()
end)
