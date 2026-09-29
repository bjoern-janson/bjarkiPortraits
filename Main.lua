local addonName, BP = ...
local R = assert(BP.Runtime, "Core.lua must load first")

local events = CreateFrame("Frame")
R.eventFrame = events
for _, event in ipairs({
    "ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED",
    "PLAYER_TARGET_CHANGED", "PLAYER_FOCUS_CHANGED", "UNIT_TARGET", "UNIT_AURA",
    "UNIT_FACTION", "UNIT_FLAGS", "UNIT_CONNECTION", "UNIT_PET", "PET_BAR_UPDATE",
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
        if R.buildQueued then R.BuildAll() end
    elseif event == "PLAYER_TARGET_CHANGED" then
        R.Refresh("target")
        R.Refresh("targettarget")
        R.UpdateObservedPetPortraits()
    elseif event == "PLAYER_FOCUS_CHANGED" then
        R.Refresh("focus")
        R.Refresh("focustarget")
        R.UpdateObservedPetPortraits()
    elseif event == "UNIT_TARGET" then
        if arg1 == "target" then R.Refresh("targettarget")
        elseif arg1 == "focus" then R.Refresh("focustarget")
        elseif arg1 == "player" then R.Refresh("target") end
    elseif event == "UNIT_AURA" or event == "UNIT_FACTION" or event == "UNIT_FLAGS" or event == "UNIT_CONNECTION" then
        for _, unit in ipairs(R.TRACKED_UNITS) do
            if arg1 == unit then R.Refresh(unit); break end
        end
        if arg1 == "target" or arg1 == "focus" then R.UpdateObservedPetPortraits() end
    elseif event == "UNIT_PET" or event == "PET_BAR_UPDATE" then
        R.UpdateLocalPetPortrait()
    end
end)
