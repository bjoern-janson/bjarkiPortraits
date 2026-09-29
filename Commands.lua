local addonName, BP = ...
local R = assert(BP.Runtime, "Core.lua must load first")

local function setToggle(key, value)
    R.db[key] = value
    R.BuildAll()
    R.UpdatePetPortraits()
end

SLASH_BJARKIPORTRAITS1 = "/bp"
SlashCmdList.BJARKIPORTRAITS = function(message)
    local command, arg = (message or ""):lower():match("^(%S*)%s*(.-)$")
    if command == "" or command == "help" then
        R.Print("/bp test | on | off | player | target | focus | tot | fot | swipe | decimals | pets | debug | reset")
    elseif command == "test" then
        R.testMode = not R.testMode
        R.RefreshAll()
        R.Print("test " .. (R.testMode and "on" or "off"))
    elseif command == "on" then
        R.db.enabled = true; R.BuildAll(); R.Print("on")
    elseif command == "off" then
        R.db.enabled = false; R.DestroyAll(); R.Print("off")
    elseif command == "player" or command == "target" or command == "focus" then
        setToggle(command, not R.db[command]); R.Print(command .. " " .. tostring(R.db[command]))
    elseif command == "tot" or command == "targettarget" then
        setToggle("targettarget", not R.db.targettarget); R.Print("targettarget " .. tostring(R.db.targettarget))
    elseif command == "fot" or command == "focustarget" then
        setToggle("focustarget", not R.db.focustarget); R.Print("focustarget " .. tostring(R.db.focustarget))
    elseif command == "swipe" then
        R.db.showSwipe = not R.db.showSwipe; R.ApplyPresentation(); R.Print("swipe " .. tostring(R.db.showSwipe))
    elseif command == "decimals" then
        R.db.showDecimals = not R.db.showDecimals; R.ApplyPresentation(); R.Print("decimals " .. tostring(R.db.showDecimals))
    elseif command == "pets" then
        R.db.petPortraits = not R.db.petPortraits; R.UpdatePetPortraits(); R.Print("pet portraits " .. tostring(R.db.petPortraits))
    elseif command == "debug" then
        for _, unit in ipairs(R.TRACKED_UNITS) do
            local host = R.hosts[unit]
            local exactHelpful = R.ExactFilterAllowed(unit, true, nil, false)
            R.Print(unit .. " host=" .. tostring(host ~= nil)
                .. " portrait=" .. tostring(host and host.portrait ~= nil)
                .. " containers=" .. tostring(host and #host.containers or 0)
                .. " reparented=" .. tostring(host and host.reparented or false)
                .. " hostilePlayer=" .. tostring(host and host._hostilePlayer or false)
                .. " exactHelpful=" .. tostring(exactHelpful)
                .. " hostileReadable=" .. tostring(host and host._hostileReadable or false)
                .. " hostileCount=" .. tostring(host and host._hostileCount or 0)
                .. " hostileSpell=" .. tostring(host and host._hostileSpellID or nil)
                .. " baselineReadable=" .. tostring(host and host._baselineReadable or false)
                .. " baselineSpell=" .. tostring(host and host._baselineSpellID or nil)
                .. " baselineTiming=" .. tostring(host and host._baselineTimingReadable or false)
                .. " resSicknessReadable=" .. tostring(host and host._resSicknessReadable or false)
                .. " resSicknessActive=" .. tostring(host and host._resSicknessActive or false))
        end
    elseif command == "reset" then
        BjarkiPortraitsDB = nil; R.ApplyDefaults(); R.DestroyAll(); R.BuildAll(); R.UpdatePetPortraits(); R.Print("reset")
    else
        R.Print("unknown command; /bp help")
    end
end
