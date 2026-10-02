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
        R.Print("/bp test | on | off | player | target | focus | tot | fot | swipe | pets | debug | reset")
    elseif command == "test" then
        R.testMode = not R.testMode
        R.RefreshAll()
        R.Print("test " .. (R.testMode and "on" or "off"))
    elseif command == "on" then
        R.db.enabled = true; R.BuildAll(); R.UpdatePetPortraits(); R.Print("on")
    elseif command == "off" then
        R.db.enabled = false
        -- In combat, hide presentation now and let the queued cleanup restore
        -- native ownership after combat. Disabled refresh cannot create hosts.
        if not R.DestroyAll() then R.RefreshAll() end
        R.UpdatePetPortraits()
        R.Print("off")
    elseif command == "player" or command == "target" or command == "focus" then
        setToggle(command, not R.db[command]); R.Print(command .. " " .. tostring(R.db[command]))
    elseif command == "tot" or command == "targettarget" then
        setToggle("targettarget", not R.db.targettarget); R.Print("targettarget " .. tostring(R.db.targettarget))
    elseif command == "fot" or command == "focustarget" then
        setToggle("focustarget", not R.db.focustarget); R.Print("focustarget " .. tostring(R.db.focustarget))
    elseif command == "swipe" then
        R.db.showSwipe = not R.db.showSwipe; R.ApplyPresentation(); R.Print("swipe " .. tostring(R.db.showSwipe))
    elseif command == "pets" then
        R.db.petPortraits = not R.db.petPortraits; R.UpdatePetPortraits(); R.Print("pet portraits " .. tostring(R.db.petPortraits))
    elseif command == "debug" then
        for _, unit in ipairs(R.TRACKED_UNITS) do
            local host = R.hosts[unit]
            local exactHelpful = R.ExactFilterAllowed(unit, true, nil, false)
            R.Print(unit .. " host=" .. tostring(host ~= nil)
                .. " portrait=" .. tostring(host and host.portrait ~= nil)
                .. " unitExists=" .. tostring(host and host._unitExists or false)
                .. " unitExistsReadable=" .. tostring(host and host._unitExistsReadable or false)
                .. " containers=" .. tostring(host and #host.containers or 0)
                .. " reparented=" .. tostring(host and host.reparented or false)
                .. " hostileUnit=" .. tostring(host and host._hostileUnit or false)
                .. " hostilePlayer=" .. tostring(host and host._hostilePlayer or false)
                .. " playerReadable=" .. tostring(host and host._playerReadable or false)
                .. " isPlayer=" .. tostring(host and host._isPlayer)
                .. " assistReadable=" .. tostring(host and host._assistReadable or false)
                .. " assistable=" .. tostring(host and host._assistable)
                .. " exactHelpful=" .. tostring(exactHelpful)
                .. " exactHarmful=" .. tostring(host and host._exactHarmfulAllowed or false)
                .. " smallHarmful=" .. tostring(host and host._smallHarmfulEnabled or false)
                .. " hostileReadable=" .. tostring(host and host._hostileReadable or false)
                .. " hostileVisibleComplete=" .. tostring(host and host._hostileVisibleComplete or false)
                .. " hostileCount=" .. tostring(host and host._hostileCount or 0)
                .. " hostileSpell=" .. tostring(host and host._hostileSpellID or nil)
                .. " boostedRestReadable=" .. tostring(host and host._boostedRestReadable or false)
                .. " boostedRestActive=" .. tostring(host and host._boostedRestActive or false)
                .. " baselineReadable=" .. tostring(host and host._baselineReadable or false)
                .. " baselineSpell=" .. tostring(host and host._baselineSpellID or nil)
                .. " baselineTiming=" .. tostring(host and host._baselineTimingReadable or false)
                .. " baselineTimingSource=" .. tostring(host and host._baselineTimingSource or nil)
                .. " baselineAppliedAt=" .. tostring(host and host._baselineAppliedAt or nil)
                .. " slowsReadable=" .. tostring(host and host._slowsReadable or false)
                .. " slowsSpell=" .. tostring(host and host._slowsSpellID or nil)
                .. " slowsActive=" .. tostring(host and host._slowsActive or false)
                .. " resSicknessReadable=" .. tostring(host and host._resSicknessReadable or false)
                .. " resSicknessActive=" .. tostring(host and host._resSicknessActive or false)
                .. " utilityReadable=" .. tostring(host and host._utilityReadable or false)
                .. " utilityWinnerSpell=" .. tostring(host and host._utilityWinnerSpellID or nil)
                .. " welcomingDirect=" .. tostring(host and host._welcomingCampfireDirect or false)
                .. " welcomingDirectFound=" .. tostring(host and host._welcomingCampfireDirectFound or false)
                .. " welcomingPresent=" .. tostring(host and host._welcomingCampfirePresent or false)
                .. " welcomingReadable=" .. tostring(host and host._welcomingCampfireReadable or false)
                .. " welcomingAppliedAt=" .. tostring(host and host._welcomingCampfireAppliedAt or nil)
                .. " welcomingTimingSource=" .. tostring(host and host._welcomingCampfireTimingSource or nil)
                .. " welcomingActive=" .. tostring(host and host._welcomingCampfireActive or false))
        end
    elseif command == "reset" then
        BjarkiPortraitsDB = nil; R.ApplyDefaults(); R.DestroyAll(); R.BuildAll(); R.UpdatePetPortraits(); R.Print("reset")
    else
        R.Print("unknown command; /bp help")
    end
end
