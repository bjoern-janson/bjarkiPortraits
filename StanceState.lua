local addonName, BP = ...
local R = assert(BP.Runtime, "Core.lua must load first")

-- Own-player form APIs have no unit argument. Arbitrary-unit hidden stance
-- AuraData is experimental: only an exact, readable current positive counts.
local stances = {
    {id=2457, name="Battle"}, {id=71, name="Defensive"}, {id=2458, name="Berserker"},
}
local byID, supported = {}, {}
for _, stance in ipairs(stances) do byID[stance.id] = stance.name end
for _, unit in ipairs(R.TRACKED_UNITS) do supported[unit] = true end

function R.IsPlayerStanceUnit(unit)
    if not R.CanAccess(unit) or type(unit) ~= "string" or not supported[unit] then return false end
    if unit == "player" then return true end
    local same, readable = R.SafeBool(UnitIsUnit, unit, "player")
    return readable and same == true
end

local function resolvePlayer(result)
    result.source = "player-forms"
    if type(GetNumShapeshiftForms) ~= "function" or type(GetShapeshiftFormInfo) ~= "function" then
        result.reason = "api-unavailable"; return result
    end
    local ok, count = pcall(GetNumShapeshiftForms)
    if not ok then result.reason = "api-error"; return result end
    if not R.CanAccess(count) then result.reason = "unreadable"; return result end
    -- A malformed/oversized count must not cause unbounded work or a partial
    -- scan that could mistake one of several active forms for a unique stance.
    if type(count) ~= "number" or count < 0 or count > 16 or count % 1 ~= 0 then
        result.reason = "invalid-forms"; return result
    end
    local activeID, activeCount = nil, 0
    for index = 1, count do
        local got, _, active, _castable, id = pcall(GetShapeshiftFormInfo, index)
        if not got then result.reason = "api-error"; return result end
        if not R.CanAccess(active) or not R.CanAccess(id) then result.reason = "unreadable"; return result end
        if type(active) ~= "boolean" then result.reason = "invalid-forms"; return result end
        if active then
            if type(id) ~= "number" or not byID[id] then result.reason = "unsupported-form"; return result end
            activeCount, activeID = activeCount + 1, id
        end
    end
    if activeCount ~= 1 then result.reason = activeCount == 0 and "no-values" or "ambiguous"; return result end
    result.spellID, result.name, result.reason = activeID, byID[activeID], "proven"
    return result
end

local function inspectLookup(unit, id, getter)
    if type(getter) ~= "function" then return "api-unavailable" end
    local ok, aura = pcall(getter, unit, id)
    if not ok then return "api-error" end -- Never inspect/stringify error data.
    if not R.CanAccess(aura) then return "unreadable" end
    if aura == nil then return "no-values" end -- absent, invisible or restricted
    if type(aura) ~= "table" then return "invalid-aura" end
    local actualID, idReadable = R.ReadAuraField(aura, "spellId")
    local helpful, helpfulReadable = R.ReadAuraField(aura, "isHelpful")
    if not idReadable or not helpfulReadable then return "unreadable" end
    if type(actualID) ~= "number" or actualID ~= id or helpful ~= true then return "invalid-aura" end
    return "positive"
end

function R.ResolveWarriorStance(unit)
    local result = {source="none", reason="unsupported-unit"}
    if not R.CanAccess(unit) or type(unit) ~= "string" or not supported[unit] then return result end
    local exists, existsReadable = R.UnitExistsState(unit)
    if not existsReadable or not exists then result.reason = existsReadable and "absent" or "existence-unreadable"; return result end
    local player, playerReadable = R.PlayerUnitState(unit)
    if not playerReadable or not player then result.reason = playerReadable and "not-player" or "identity-unreadable"; return result end
    local dead, deadReadable = R.SafeBool(UnitIsDeadOrGhost, unit)
    if not deadReadable or dead then result.reason = deadReadable and "dead" or "dead-unreadable"; return result end
    if type(UnitClass) ~= "function" then result.reason = "class-unavailable"; return result end
    local ok, _, class = pcall(UnitClass, unit)
    if not ok or not R.CanAccess(class) or type(class) ~= "string" then result.reason = "class-unreadable"; return result end
    if class ~= "WARRIOR" then result.reason = "not-warrior"; return result end
    if R.IsPlayerStanceUnit(unit) then return resolvePlayer(result) end

    result.source, result.lookups = "unit-aura", {}
    local getter = C_UnitAuras and C_UnitAuras.GetUnitAuraBySpellID
    local positiveID, positives, failure = nil, 0, nil
    for _, stance in ipairs(stances) do
        local status = inspectLookup(unit, stance.id, getter)
        result.lookups[#result.lookups + 1] = {spellID=stance.id, status=status}
        if status == "positive" then positives, positiveID = positives + 1, stance.id
        elseif status ~= "no-values" then failure = failure or status end
    end
    if failure then result.reason = failure
    elseif positives ~= 1 then result.reason = positives == 0 and "no-values" or "ambiguous"
    else result.spellID, result.name, result.reason = positiveID, byID[positiveID], "proven" end
    return result
end

function R.GetStanceDiagnostic(unit)
    local result = R.ResolveWarriorStance(unit)
    local line = "stance " .. unit .. " source=" .. result.source .. " reason=" .. result.reason
        .. " recognized=" .. (result.name and result.name .. ":" .. result.spellID or "unknown")
    for _, lookup in ipairs(result.lookups or {}) do
        line = line .. " " .. lookup.spellID .. "=" .. lookup.status
    end
    return line
end
