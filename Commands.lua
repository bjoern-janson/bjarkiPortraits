local addonName, BP = ...
local R = assert(BP.Runtime, "Core.lua must load first")

local function setToggle(key, value)
    R.db[key] = value
    if not value then R.Refresh(key) end
    R.BuildAll()
    R.UpdatePetPortraits()
end

local function inspectAuras(option)
    local unit = ({ player="player", target="target", focus="focus",
        tot="targettarget", targettarget="targettarget",
        fot="focustarget", focustarget="focustarget" })[option == "" and "target" or option]
    if not unit then R.Print("usage: /bp inspect [player|target|focus|tot|fot]"); return end
    local host = R.hosts[unit]
    R.Print("inspect " .. unit .. " version=" .. R.VERSION .. " host=" .. tostring(host ~= nil)
        .. " exactHelpful=" .. tostring(R.ExactFilterAllowed(unit, true, nil, false))
        .. " exactHarmful=" .. tostring(R.ExactFilterAllowed(unit, false, nil, false))
        .. " readableWinner=" .. tostring(host and host._hostileTierKey or "none")
        .. " active=" .. tostring(host and host._hostileActive == true or false))

    -- Report only public numeric IDs. Inspecting must not refresh presentation,
    -- construct hosts, or infer identities from native protected widgets.
    local getter = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex
    for _, filter in ipairs({ "HELPFUL", "HARMFUL" }) do
        local readable, restricted, ids = 0, 0, {}
        local status = "unavailable"
        if type(getter) == "function" then
            status = "limit"
            for index = 1, 80 do
                local ok, aura = pcall(getter, unit, index, filter .. "|INCLUDE_NAME_PLATE_ONLY")
                if not ok then status = "error"; break end
                if not R.CanAccess(aura) then
                    restricted = restricted + 1
                elseif aura == nil then
                    status = "complete"; break
                else
                    local id, accessible = R.ReadAuraField(aura, "spellId")
                    if accessible and type(id) == "number" and id > 0 and id % 1 == 0 then
                        readable = readable + 1
                        if #ids < 12 then
                            local priority = "unlisted"
                            for _, tier in ipairs(R.TIERS) do
                                if tier.exact and tier.helpful == (filter == "HELPFUL") and tier.spellIDs[id] then
                                    priority = tostring(tier.level); break
                                end
                            end
                            ids[#ids + 1] = tostring(id) .. "@" .. priority
                        end
                    else
                        restricted = restricted + 1
                    end
                end
            end
        end
        R.Print(filter:lower() .. " readable=" .. readable .. " restricted=" .. restricted
            .. " listed=" .. #ids .. "/" .. readable .. " scan=" .. status
            .. " ids=" .. (#ids > 0 and table.concat(ids, ",") or "none"))
    end

    local policies = {}
    for _, id in ipairs({ 6615, 2645, 1286304, 1229451 }) do
        local state = "unknown"
        if C_Secrets and type(C_Secrets.GetSpellAuraSecrecy) == "function" and Enum and Enum.SecrecyLevel then
            local ok, value = pcall(C_Secrets.GetSpellAuraSecrecy, id)
            if ok and R.CanAccess(value) and type(value) == "number" then
                state = value == Enum.SecrecyLevel.NeverSecret and "yes" or "no"
            end
        end
        policies[#policies + 1] = id .. "=" .. state
    end
    R.Print("neverSecret " .. table.concat(policies, " "))
end

SLASH_BJARKIPORTRAITS1 = "/bp"
SLASH_BJARKIPORTRAITS2 = "/bjarkiportraits"
SlashCmdList.BJARKIPORTRAITS = function(message)
    local command, option, detail = (message or ""):lower():match("^%s*(%S*)%s*(%S*)%s*(%S*)")
    if command == "" or command == "help" then
        R.Print("/bp or /bjarkiportraits test | on | off | player | target | focus | tot | fot | swipe | decimals | pets [status|on|off|debug [unit]] | inspect [unit] | debug | audit | reset")
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
    elseif command == "decimals" then
        R.db.showDecimals = not R.db.showDecimals
        R._formatter, R._formatterKey = nil, nil
        R.ApplyPresentation()
        R.Print("decimals " .. tostring(R.db.showDecimals))
    elseif command == "pets" then
        if option == "debug" then
            local debugUnit = ({ pet="pet", target="target", focus="focus",
                tot="targettarget", targettarget="targettarget",
                fot="focustarget", focustarget="focustarget" })[detail]
            if detail ~= "" and not debugUnit then
                R.Print("usage: /bp pets debug [pet|target|focus|tot|fot]")
                return
            end
            -- Observe the failure before a manual refresh can hide it.
            R.Print("pets debug version=" .. tostring(R.VERSION)
                .. " enabled=" .. tostring(R.db and R.db.enabled == true)
                .. " setting=" .. tostring(R.db and R.db.petPortraits == true))
            if debugUnit then
                local summary, access = R.GetPetPortraitDebug(debugUnit, true)
                R.Print(summary)
                R.Print(access)
            else
                for _, unit in ipairs({ "pet", "target", "focus", "targettarget", "focustarget" }) do
                    R.Print(R.GetPetPortraitDebug(unit))
                end
            end
        elseif option == "status" then
            R.Print("pet portraits " .. tostring(R.db.petPortraits))
        elseif option == "on" or option == "off" then
            R.db.petPortraits = option == "on"
            R.UpdatePetPortraits()
            R.Print("pet portraits " .. tostring(R.db.petPortraits))
        else
            R.db.petPortraits = not R.db.petPortraits
            R.UpdatePetPortraits()
            R.Print("pet portraits " .. tostring(R.db.petPortraits))
        end
    elseif command == "inspect" then
        inspectAuras(option)
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
                .. " hostileUnit=" .. tostring(host and host._hostileUnit)
                .. " hostileRelationReadable=" .. tostring(host and host._hostileRelationReadable or false)
                .. " hostilePlayer=" .. tostring(host and host._hostilePlayer or false)
                .. " playerReadable=" .. tostring(host and host._playerReadable or false)
                .. " isPlayer=" .. tostring(host and host._isPlayer)
                .. " assistReadable=" .. tostring(host and host._assistReadable or false)
                .. " assistable=" .. tostring(host and host._assistable)
                .. " exactHelpful=" .. tostring(exactHelpful)
                .. " exactHarmful=" .. tostring(host and host._exactHarmfulAllowed or false)
                .. " smallHarmful=" .. tostring(host and host._smallHarmfulEnabled or false)
                .. " hostileReadable=" .. tostring(host and host._hostileReadable or false)
                .. " hostileActive=" .. tostring(host and host._hostileActive or false)
                .. " hostileElectionReadable=" .. tostring(host and host._hostileElectionReadable or false)
                .. " hostileAuraListComplete=" .. tostring(host and host._hostileAuraListComplete or false)
                .. " hostileCount=" .. tostring(host and host._hostileCount or 0)
                .. " hostileSpell=" .. tostring(host and host._hostileSpellID or nil)
                .. " hostileTier=" .. tostring(host and host._hostileTierKey or nil)
                .. " divineSecureAllowed=" .. tostring(host and host._divineProtectionSecureAllowed or false)
                .. " divineReadable=" .. tostring(host and host._divineProtectionReadable or false)
                .. " divineActive=" .. tostring(host and host._divineProtectionActive or false)
                .. " divineSpell=" .. tostring(host and host._divineProtectionSpellID or nil)
                .. " boostedRestReadable=" .. tostring(host and host._boostedRestReadable or false)
                .. " boostedRestActive=" .. tostring(host and host._boostedRestActive or false)
                .. " baselineReadable=" .. tostring(host and host._baselineReadable or false)
                .. " baselineElectionReadable=" .. tostring(host and host._baselineElectionReadable or false)
                .. " baselineSpell=" .. tostring(host and host._baselineSpellID or nil)
                .. " baselineTiming=" .. tostring(host and host._baselineTimingReadable or false)
                .. " baselineTimingSource=" .. tostring(host and host._baselineTimingSource or nil)
                .. " baselineAppliedAt=" .. tostring(host and host._baselineAppliedAt or nil)
                .. " baselineActive=" .. tostring(host and host._baselineActive or false)
                .. " healingReadable=" .. tostring(host and host._healingReadable or false)
                .. " healingElectionReadable=" .. tostring(host and host._healingElectionReadable or false)
                .. " healingSpell=" .. tostring(host and host._healingSpellID or nil)
                .. " healingTiming=" .. tostring(host and host._healingTimingReadable or false)
                .. " healingTimingSource=" .. tostring(host and host._healingTimingSource or nil)
                .. " healingAppliedAt=" .. tostring(host and host._healingAppliedAt or nil)
                .. " healingActive=" .. tostring(host and host._healingActive or false)
                .. " slowsReadable=" .. tostring(host and host._slowsReadable or false)
                .. " slowsElectionReadable=" .. tostring(host and host._slowsElectionReadable or false)
                .. " slowsSpell=" .. tostring(host and host._slowsSpellID or nil)
                .. " slowsActive=" .. tostring(host and host._slowsActive or false)
                .. " resSicknessReadable=" .. tostring(host and host._resSicknessReadable or false)
                .. " resSicknessActive=" .. tostring(host and host._resSicknessActive or false)
                .. " waitingSecureAllowed=" .. tostring(host and host._waitingToResurrectSecureAllowed or false)
                .. " waitingReadable=" .. tostring(host and host._waitingToResurrectReadable or false)
                .. " waitingActive=" .. tostring(host and host._waitingToResurrectActive or false)
                .. " waitingSpell=" .. tostring(host and host._waitingToResurrectSpellID or nil)
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
    elseif command == "audit" then
        local audit = R.TIER_AUDIT or {}
        R.Print("audit version=" .. tostring(R.VERSION)
            .. " enabled=" .. tostring(R.db and R.db.enabled == true)
            .. " pets=" .. tostring(R.db and R.db.petPortraits == true)
            .. " exactLanes=" .. tostring(audit.exactLaneCount or 0)
            .. " memberships=" .. tostring(audit.exactMemberships or 0)
            .. " distinctSpellIDs=" .. tostring(audit.distinctExactSpellIDs or 0)
            .. " overlaps=" .. tostring(audit.overlapCount or 0))

        for _, overlap in ipairs(audit.overlaps or {}) do
            R.Print("WARNING overlap spell=" .. tostring(overlap.spellID)
                .. " first=" .. tostring(overlap.first)
                .. " second=" .. tostring(overlap.second))
        end

        for _, unit in ipairs(R.TRACKED_UNITS) do
            local host = R.hosts[unit]
            R.Print(unit
                .. " enabled=" .. tostring(R.IsUnitEnabled(unit))
                .. " host=" .. tostring(host ~= nil)
                .. " containers=" .. tostring(host and #host.containers or 0)
                .. " unitExistsReadable=" .. tostring(host and host._unitExistsReadable or false)
                .. " playerReadable=" .. tostring(host and host._playerReadable or false)
                .. " assistReadable=" .. tostring(host and host._assistReadable or false))
        end
    elseif command == "reset" then
        BjarkiPortraitsDB = nil
        R.ApplyDefaults()
        R.DestroyAll()
        R.BuildAll()
        R.ApplyPresentation()
        R.UpdatePetPortraits()
        R.Print("reset")
    else
        R.Print("unknown command; /bp help")
    end
end
