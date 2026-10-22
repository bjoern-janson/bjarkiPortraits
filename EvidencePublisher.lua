local _, BP = ...
local R = assert(BP.Runtime, "Core must load first")
-- Only positive, genuinely readable observations. A selected portrait or
-- securely rendered aura is NOT a readable observation and never enters CC.
local SOURCE_UNITS = {target=true, focus=true, targettarget=true, focustarget=true}
local MAX_EVENT_ITEMS = 64
-- Fixed, self-cast cooldown aura shortlist used only on derived unit binding.
-- Newly added readable auras are not constrained to this shortlist; the CC
-- consumer owns the inference whitelist.
local COOLDOWN_AURAS = {16689,16810,16811,16812,16813,17329,22812,5277,26669}
R.evidenceStats = {published=0, rejected=0, snapshots=0, events=0}

local function field(tableValue, key)
    if not R.CanAccess(tableValue) or type(tableValue) ~= "table" then return nil, false end
    local ok, value = pcall(function() return tableValue[key] end)
    if not ok or not R.CanAccess(value) then return nil, false end
    return value, true
end

local function validRecipient(unit)
    if not SOURCE_UNITS[unit] or not R.db or R.db.enabled == false then return nil end
    local isPlayer, hasPlayer = R.SafeBool(UnitIsPlayer, unit)
    local hostile, hasHostile = R.SafeBool(UnitCanAttack, "player", unit)
    if not hasPlayer or isPlayer ~= true or not hasHostile or hostile ~= true then return nil end
    local ok, guid = pcall(UnitGUID, unit)
    if ok and R.CanAccess(guid) and type(guid) == "string" and #guid <= 128
        and guid:match("^Player%-[%w%-]+$") then return guid end
end

local function nowTime()
    if type(GetTime) ~= "function" then return nil end
    local ok, stamp = pcall(GetTime)
    if ok and R.CanAccess(stamp) and type(stamp) == "number"
        and stamp >= 0 and stamp < math.huge then return stamp end
end

local function publish(unit, guid, aura, stamp, newlyAssigned)
    if not BP.EvidenceBus or not R.CanAccess(aura) or type(aura) ~= "table" then return end
    local id, helpful = field(aura, "spellId"), field(aura, "isHelpful")
    if helpful ~= true or type(id) ~= "number" then return end
    local success = BP.EvidenceBus:Publish({
        source="bjarkiPortraits", kind="aura-positive", isHelpful=true,
        unit=unit, recipientGUID=guid, spellId=id,
        auraInstanceID=field(aura, "auraInstanceID"),
        expirationTime=field(aura, "expirationTime"), duration=field(aura, "duration"),
        observedAt=stamp, newApplication=newlyAssigned == true,
    })
    if success then R.evidenceStats.published = R.evidenceStats.published + 1 end
end

function R.PublishAuraEvent(unit, updateInfo)
    local guid = validRecipient(unit)
    if not guid then return end
    local stamp = nowTime()
    if not stamp then return end
    R.evidenceStats.events = R.evidenceStats.events + 1
    local added = field(updateInfo, "addedAuras")
    if type(added) ~= "table" then return end
    local ok, count = pcall(function() return #added end)
    if not ok or not R.CanAccess(count) or type(count) ~= "number"
        or count < 0 or count > MAX_EVENT_ITEMS then return end
    for i=1,count do
        local aura = field(added, i)
        if aura then publish(unit, guid, aura, stamp, true) end
    end
end

-- New target-of-target or focus-of-focus bindings may show buffs that started
-- before the binding. These are first sightings, NEVER new application claims.
-- False means eligibility, a query, or required evidence blocked this pass;
-- true means the readable shortlist completed, including a genuinely empty pass.
function R.PublishDerivedSnapshot(unit)
    if unit ~= "targettarget" and unit ~= "focustarget" then return false end
    local guid = validRecipient(unit)
    if not guid or not C_UnitAuras
        or type(C_UnitAuras.GetUnitAuraBySpellID) ~= "function" then return false end
    local stamp = nowTime()
    if not stamp then return false end
    R.evidenceStats.snapshots = R.evidenceStats.snapshots + 1
    -- Independent readable positives must not wait for an unrelated query.
    -- Retries remain first sightings; the cooldown consumer merges repeated
    -- observations of the same application and may refine its readable timing.
    local complete = true
    for _, spellID in ipairs(COOLDOWN_AURAS) do
        local ok, aura = pcall(C_UnitAuras.GetUnitAuraBySpellID, unit, spellID)
        if not ok or not R.CanAccess(aura) then
            complete = false
        elseif aura ~= nil and type(aura) ~= "table" then
            complete = false
        elseif aura ~= nil then
            local id, idReadable = field(aura, "spellId")
            local helpful, helpfulReadable = field(aura, "isHelpful")
            if not idReadable or not helpfulReadable then
                complete = false
            elseif id == spellID and helpful == true then
                publish(unit, guid, {
                    spellId=id, isHelpful=true,
                    auraInstanceID=field(aura, "auraInstanceID"),
                    expirationTime=field(aura, "expirationTime"),
                    duration=field(aura, "duration"),
                }, stamp, false)
            end
        end
    end
    return complete
end
