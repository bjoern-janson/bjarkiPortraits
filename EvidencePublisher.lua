local _, BP = ...
local R = assert(BP.Runtime, "Core must load first")
-- Only positive, genuinely readable observations. A selected portrait or
-- securely rendered aura is NOT a readable observation and never enters CC.
local SOURCE_UNITS = {target=true, focus=true, targettarget=true, focustarget=true}
local MAX_EVENT_ITEMS = 64
-- Fixed self-cast cooldown aura shortlist for derived binding and aura updates.
-- Newly added readable auras are not constrained to this shortlist; the CC
-- consumer owns the inference whitelist.
local COOLDOWN_AURAS = {16689,16810,16811,16812,16813,17329,22812,5277,26669}
-- The v1 replay window is eight seconds. Renew a still-observed snapshot
-- halfway through that window without filling the shared history every frame.
local SNAPSHOT_RENEW_SECONDS = 4
local derivedSnapshots = {}
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

local function deliver(bus, record)
    return bus:Publish(record)
end

local function positiveRecord(unit, guid, aura, stamp, newlyAssigned)
    if not BP.EvidenceBus or not R.CanAccess(aura) or type(aura) ~= "table" then return end
    local id, helpful = field(aura, "spellId"), field(aura, "isHelpful")
    if helpful ~= true or type(id) ~= "number" then return end
    return {
        source="bjarkiPortraits", kind="aura-positive", isHelpful=true,
        unit=unit, recipientGUID=guid, spellId=id,
        auraInstanceID=field(aura, "auraInstanceID"),
        expirationTime=field(aura, "expirationTime"), duration=field(aura, "duration"),
        observedAt=stamp, newApplication=newlyAssigned == true,
    }
end

local function publish(record)
    -- A separately loaded addon may own the v1 bridge. Its implementation
    -- must not abort the UNIT_AURA refresh or the entire derived work queue.
    local ok, success = pcall(deliver, BP.EvidenceBus, record)
    if ok and R.CanAccess(success) and success == true then
        R.evidenceStats.published = R.evidenceStats.published + 1
        return true
    end
    R.evidenceStats.rejected = R.evidenceStats.rejected + 1
    return false
end

function R.PublishAuraEvent(unit, updateInfo)
    if not BP.EvidenceBus then return end
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
        local record = positiveRecord(unit, guid, aura, stamp, true)
        if record then
            publish(record)
            if i<count and validRecipient(unit)~=guid then return end
        end
    end
end

local function needsRenewal(record, stamp)
    return stamp < record.observedAt or stamp - record.observedAt >= SNAPSHOT_RENEW_SECONDS
end

local function sameObservation(old, current)
    return old and rawequal(old.auraInstanceID, current.auraInstanceID)
        and rawequal(old.duration, current.duration)
        and rawequal(old.expirationTime, current.expirationTime)
        and not needsRenewal(old, current.observedAt)
end

local function emptyList(list)
    return list == nil or (type(list) == "table" and next(list) == nil and #list == 0)
end

-- Only a fully public dense removal list establishes that nothing on our
-- shortlist changed. Unknown and malformed deltas take the normal read path.
local function unrelatedRemovals(added, changed, removed, records)
    if not emptyList(added) or not emptyList(changed) then return false end
    local count, largest = 0, 0
    for index, id in pairs(removed) do
        count = count + 1
        if count > MAX_EVENT_ITEMS or not R.CanAccess(index) or type(index) ~= "number"
            or index < 1 or index > MAX_EVENT_ITEMS or index ~= math.floor(index) then return false end
        if index > largest then largest = index end
        if not R.CanAccess(id) or type(id) ~= "number" or id <= 0 or id >= math.huge
            or id ~= math.floor(id) then return false end
        for _, record in pairs(records) do
            if record.auraInstanceID == id then return false end
        end
    end
    return count > 0 and count == largest and count == #removed
end

local function completeOccurrence(record, stamp)
    local id, duration, expires = record.auraInstanceID, record.duration, record.expirationTime
    -- Same optional numeric bounds accepted by the v1 bridge. Missing timing
    -- or identity may become readable even during an unrelated removal.
    return type(id) == "number" and id >= 1 and id <= 9999999 and id == math.floor(id)
        and type(duration) == "number" and duration > 0 and duration <= 300
        and type(expires) == "number" and expires > stamp and expires <= 100000000
end

function R.CanSkipDerivedSnapshot(unit, updateInfo)
    if not BP.EvidenceBus then return true end
    local snapshot = derivedSnapshots[unit]
    if not snapshot or not snapshot.complete or validRecipient(unit) ~= snapshot.guid then return false end
    local full, fullOK = field(updateInfo, "isFullUpdate")
    if not fullOK or full ~= false then return false end
    local added, addedOK = field(updateInfo, "addedAuras")
    local changed, changedOK = field(updateInfo, "updatedAuraInstanceIDs")
    local removed, removedOK = field(updateInfo, "removedAuraInstanceIDs")
    if not addedOK or not changedOK or not removedOK or type(removed) ~= "table" then return false end
    local visible, known = R.SafeBool(UnitIsVisible, unit)
    local stamp = nowTime()
    if not known or not visible or not stamp then return false end
    for _, record in pairs(snapshot.sent) do
        if not completeOccurrence(record, stamp) or needsRenewal(record, stamp) then return false end
    end
    local ok, unrelated = pcall(unrelatedRemovals, added, changed, removed, snapshot.sent)
    return ok and unrelated
end

-- New target-of-target or focus-of-focus bindings may show buffs that started
-- before the binding. These are first sightings, NEVER new application claims.
-- False means eligibility, a query, or required evidence blocked this pass;
-- true means the readable shortlist completed, including a genuinely empty pass.
function R.PublishDerivedSnapshot(unit)
    if unit ~= "targettarget" and unit ~= "focustarget" then return false end
    if not BP.EvidenceBus then return true end
    -- The API can return nil for an invisible unit. This affects absence
    -- only; an independently readable positive can still be published.
    local visible, known = R.SafeBool(UnitIsVisible,unit)
    local guid = validRecipient(unit)
    if not guid then derivedSnapshots[unit] = nil; return false end
    local snapshot = derivedSnapshots[unit]
    if not snapshot or snapshot.guid ~= guid then
        snapshot = {guid=guid, sent={}}
        derivedSnapshots[unit] = snapshot
    end
    if snapshot.delivering then return false end
    snapshot.complete = false
    if not C_UnitAuras
        or type(C_UnitAuras.GetUnitAuraBySpellID) ~= "function" then return false end
    local stamp = nowTime()
    if not stamp then return false end
    R.evidenceStats.snapshots = R.evidenceStats.snapshots + 1
    -- Independent readable positives must not wait for an unrelated query.
    -- Retries remain first sightings and can refine their readable timing.
    local complete = true
    local records, absent
    for _, spellID in ipairs(COOLDOWN_AURAS) do
        local ok, aura = pcall(C_UnitAuras.GetUnitAuraBySpellID, unit, spellID)
        local confirmedAbsent = false
        if not ok or not R.CanAccess(aura) then
            complete = false
        elseif aura == nil then
            if known and visible then confirmedAbsent = true else complete = false end
        elseif type(aura) ~= "table" then
            complete = false
        else
            local id, idReadable = field(aura, "spellId")
            local helpful, helpfulReadable = field(aura, "isHelpful")
            if not idReadable or id ~= spellID or not helpfulReadable or type(helpful) ~= "boolean" then
                complete = false
            elseif helpful then
                local record=positiveRecord(unit,guid,aura,stamp,false)
                if record then
                    records=records or {}
                    records[#records+1]=record
                end
            else
                confirmedAbsent = true
            end
        end
        if confirmedAbsent and snapshot.sent[spellID] then
            absent = absent or {}
            absent[#absent+1] = spellID
        end
    end
    -- External subscribers run synchronously. Finish the native reads first,
    -- then stop delivery if a subscriber changed the token or its eligibility.
    if validRecipient(unit)~=guid then return false end
    if absent then
        for _, spellID in ipairs(absent) do snapshot.sent[spellID] = nil end
    end
    if records then
        snapshot.delivering = true
        for _,record in ipairs(records) do
            if not sameObservation(snapshot.sent[record.spellId], record) then
                if publish(record) then snapshot.sent[record.spellId] = record
                else complete = false end
                if validRecipient(unit) ~= guid or derivedSnapshots[unit] ~= snapshot then
                    snapshot.delivering = nil
                    return false
                end
            end
        end
        snapshot.delivering = nil
    end
    snapshot.complete = complete
    return complete
end
