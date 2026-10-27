-- Run from the addon source directory: lua tests/derived-evidence.lua
-- Ordinary-Lua API model. Executes shipped event routing, publisher, bus, and
-- presentation entry points; absent native portrait frames avoid UI ownership.
-- This proves event/record behavior, not protected-value or live-client behavior.
local function eq(actual, expected, message)
    assert(actual == expected, (message or "value") .. ": expected "
        .. tostring(expected) .. ", actual " .. tostring(actual))
end
local function loadAddon(name, ns)
    return assert(loadfile(name .. ".lua"))("bjarkiPortraits", ns)
end
local function setup()
    BjarkiEvidenceV1, BjarkiPortraitsDB = nil, nil
    issecretvalue, issecrettable, canaccessvalue = nil, nil, nil
    local s = {frames={}, timers={}, received={}, auras={}, failures={},
        guids={targettarget="Player-1-A", focustarget="Player-1-B"},
        clock=100, queries=0, queryLog={}, refreshes={}}
    GetTime = function() return s.clock end
    UnitIsPlayer = function() return true end
    UnitCanAttack = function() return true end
    UnitGUID = function(unit) return s.guids[unit] or "Player-1-" .. unit end
    InCombatLockdown = function() return false end
    C_Timer = {After=function(delay, callback)
        eq(delay, 0, "next-tick scheduling")
        s.timers[#s.timers+1] = callback
    end}
    C_UnitAuras = {GetUnitAuraBySpellID=function(unit, spellID)
        s.queries = s.queries + 1
        s.queryLog[#s.queryLog+1] = {unit=unit, spellID=spellID}
        if s.failures[spellID] then error("modeled unavailable query") end
        return s.auras[unit] and s.auras[unit][spellID]
    end}
    CreateFrame = function()
        local frame = {events={}}
        function frame:RegisterEvent(event) self.events[event] = true end
        function frame:RegisterUnitEvent(event, a, b)
            self.events[event] = {[a]=true}
            if b then self.events[event][b] = true end
        end
        function frame:SetScript(script, callback)
            eq(script, "OnEvent", "registered script")
            self.callback = callback
        end
        s.frames[#s.frames+1] = frame
        return frame
    end
    local bp = {}
    for _, name in ipairs({"Core", "SharedEvidence", "EvidencePublisher",
        "AuraEngine", "PetPortraits"}) do loadAddon(name, bp) end
    s.R, s.bus = bp.Runtime, bp.EvidenceBus
    s.R.ApplyDefaults()
    -- A forwarding spy measures the event path without replacing its effects.
    local refresh = s.R.Refresh
    s.R.Refresh = function(unit, force)
        s.refreshes[#s.refreshes+1] = {unit=unit, force=force == true}
        return refresh(unit, force)
    end
    loadAddon("Main", bp)
    assert(s.bus:Subscribe("regression", function(record)
        s.received[#s.received+1] = record
    end))
    function s:fire(event, unit, payload)
        for _, frame in ipairs(self.frames) do
            local registered = frame.events[event]
            if registered == true or (type(registered) == "table" and registered[unit]) then
                frame.callback(frame, event, unit, payload)
            end
        end
    end
    function s:drain()
        local pending = self.timers
        self.timers = {}
        for _, callback in ipairs(pending) do callback() end
        eq(#self.timers, 0, "callback must not self-poll")
    end
    function s:bind(unit)
        self:fire("UNIT_TARGET", unit == "focustarget" and "focus" or "target")
        self:drain()
    end
    return s
end
local function aura(expiration, duration, instance)
    return {spellId=22812, isHelpful=true, auraInstanceID=instance or 21,
        expirationTime=expiration, duration=duration}
end
local function recordIdentity(record, unit, guid, instance)
    eq(record.unit, unit, "source token")
    eq(record.recipientGUID, guid, "recipient identity")
    eq(record.auraInstanceID, instance or 21, "application identity")
    eq(record.spellId, 22812, "spell identity")
    eq(record.newApplication, false, "snapshot must not claim a new application")
end
local failures, passed = {}, 0
local function test(name, body)
    local ok, err = pcall(body)
    if ok then
        passed = passed + 1
        print("PASS " .. name)
    else
        failures[#failures+1] = name .. ": " .. tostring(err)
        print("FAIL " .. failures[#failures])
    end
end

-- Catches consuming snapshotNeeded after a successful pass and then ignoring
-- update-only events; both derived tokens must refine a completed observation.
test("completed snapshot publishes later readable and corrected timing", function()
    for _, unit in ipairs({"targettarget", "focustarget"}) do
        local s = setup()
        s.auras[unit] = {[22812]=aura()}
        s:bind(unit)
        eq(#s.received, 1, "initial observation")
        eq(s.received[1].expirationTime, nil, "initial unavailable expiry")
        eq(s.queries, 9, "completed shortlist")
        s.clock = 101
        s.auras[unit][22812] = aura(108, 12)
        s:fire("UNIT_AURA", unit, {updatedAuraInstanceIDs={21}})
        s:drain()
        eq(#s.received, 2, "later readable timing must publish")
        recordIdentity(s.received[2], unit, s.guids[unit])
        eq(s.received[2].expirationTime, 108, "readable expiry")
        eq(s.received[2].duration, 12, "readable duration")
        eq(s.received[2].observedAt, 101, "current observation time")
        s.clock = 102
        s.auras[unit][22812] = aura(112, 16)
        s:fire("UNIT_AURA", unit, {updatedAuraInstanceIDs={21}})
        s:drain()
        eq(#s.received, 3, "corrected timing must publish")
        recordIdentity(s.received[3], unit, s.guids[unit])
        eq(s.received[3].expirationTime, 112, "corrected expiry")
        eq(s.received[3].duration, 16, "corrected duration")
        eq(s.queries, 27, "one shortlist per completed event batch")
    end
end)

test("full update recovers after completed empty scan without removal claims", function()
    local s = setup()
    s:bind("targettarget")
    eq(s.queries, 9)
    eq(#s.received, 0)
    s.auras.targettarget = {[22812]=aura(108, 12)}
    s:fire("UNIT_AURA", "targettarget", {isFullUpdate=true})
    s:drain()
    eq(#s.received, 1, "full update after empty snapshot")
    recordIdentity(s.received[1], "targettarget", "Player-1-A")
    s.auras.targettarget = {}
    s:fire("UNIT_AURA", "targettarget", {removedAuraInstanceIDs={21}})
    s:drain()
    eq(#s.received, 1, "empty scan publishes no removal")
    eq(s.queries, 27)
end)

test("added observation stays new before snapshot first sighting", function()
    local s = setup()
    local added = aura(108, 12)
    s.auras.targettarget = {[22812]=added}
    s:fire("UNIT_AURA", "targettarget", {addedAuras={added}})
    eq(#s.received, 1, "added aura publishes immediately")
    eq(s.received[1].newApplication, true)
    eq(s.queries, 0, "snapshot waits for next tick")
    s:drain()
    eq(#s.received, 2, "snapshot follows added observation")
    recordIdentity(s.received[2], "targettarget", "Player-1-A")
    eq(s.received[1].newApplication, true, "snapshot cannot mutate earlier record")
end)

test("queued correction reads live recipient after rebind", function()
    local s = setup()
    s.auras.targettarget = {[22812]=aura(108, 12)}
    s:bind("targettarget")
    s:fire("UNIT_AURA", "targettarget", {updatedAuraInstanceIDs={21}})
    s.guids.targettarget = "Player-1-Rebound"
    s.auras.targettarget[22812] = aura(115, 15)
    s:drain()
    eq(#s.received, 2, "one correction at current binding")
    recordIdentity(s.received[2], "targettarget", "Player-1-Rebound")
    eq(s.received[2].expirationTime, 115)
    eq(s.received[1].recipientGUID, "Player-1-A", "old record stays immutable")
end)

test("disable before callback cancels queued publication", function()
    local s = setup()
    s.auras.targettarget = {[22812]=aura(108, 12)}
    s:bind("targettarget")
    s:fire("UNIT_AURA", "targettarget", {updatedAuraInstanceIDs={21}})
    eq(#s.timers, 1, "correction queued before disable")
    s.R.db.enabled = false
    s:drain()
    eq(s.queries, 9, "disabled callback cannot query")
    eq(#s.received, 1, "disabled callback cannot publish")
    s:fire("UNIT_AURA", "targettarget", {addedAuras={aura(108, 12)}})
    s:drain()
    eq(#s.received, 1, "disabled added event cannot publish")
end)

test("irrelevant unit and ordinary target do not schedule derived scans", function()
    local s = setup()
    s:fire("UNIT_AURA", "party1", {addedAuras={aura(108, 12)}})
    s:fire("UNIT_AURA", "target", {updatedAuraInstanceIDs={21}})
    eq(#s.timers, 0)
    eq(s.queries, 0)
    eq(#s.received, 0)
end)

test("event bursts coalesce fixed shortlist work and bounded bus history", function()
    local s = setup()
    s.auras.targettarget = {[22812]=aura(108, 12)}
    s:bind("targettarget")
    for burst=1,70 do
        local before = s.queries
        for event=1,100 do
            s:fire("UNIT_AURA", "targettarget", {updatedAuraInstanceIDs={21}})
        end
        eq(#s.timers, 1, "one callback per burst")
        eq(s.queries, before, "no synchronous shortlist")
        s:drain()
        eq(s.queries-before, 9, "fixed nine queries per token per callback")
        recordIdentity(s.received[#s.received], "targettarget", "Player-1-A")
    end
    eq(#s.received, 71, "one positive per snapshot")
    eq(#s.bus.recent, 64, "bounded replay history")
end)

test("incomplete lookup retains independent positives and later retries", function()
    local s = setup()
    s.auras.targettarget = {[22812]=aura(108, 12)}
    s.failures[5277] = true
    s:bind("targettarget")
    eq(#s.received, 1, "unrelated failed lookup must not discard positive")
    recordIdentity(s.received[1], "targettarget", "Player-1-A")
    eq(s.queries, 9, "incomplete pass remains bounded")
    s.failures[5277] = nil
    s:fire("UNIT_AURA", "targettarget", {updatedAuraInstanceIDs={21}})
    s:drain()
    eq(#s.received, 2)
    eq(s.queries, 18)
    recordIdentity(s.received[2], "targettarget", "Player-1-A")
end)

test("stable correction does not force an extra presentation refresh", function()
    local s = setup()
    s.auras.targettarget = {[22812]=aura(108, 12)}
    s:bind("targettarget")
    s.refreshes = {}
    s:fire("UNIT_AURA", "targettarget", {updatedAuraInstanceIDs={21}})
    s:drain()
    eq(#s.received, 2, "correction delivered")
    eq(#s.refreshes, 1, "only the immediate visual refresh")
    eq(s.refreshes[1].force, false, "no forced native refresh for stable aura update")
end)

test("mixed binding and correction preserve deferred full reconciliation", function()
    for _, correctionFirst in ipairs({true, false}) do
        local s = setup()
        s.auras.targettarget = {[22812]=aura(108, 12)}
        s:bind("targettarget")
        s.refreshes = {}
        if correctionFirst then
            s:fire("UNIT_AURA", "targettarget", {updatedAuraInstanceIDs={21}})
            s:fire("UNIT_TARGET", "target")
        else
            s:fire("UNIT_TARGET", "target")
            s:fire("UNIT_AURA", "targettarget", {updatedAuraInstanceIDs={21}})
        end
        eq(#s.timers, 1, "mixed requests share one callback")
        s:drain()
        eq(#s.received, 2)
        eq(#s.refreshes, 3, "two immediate and one deferred refresh")
        eq(s.refreshes[3].force, true, "binding retains deferred forced refresh")
        eq(s.queries, 18, "mixed requests scan once")
    end
end)

assert(#failures == 0, tostring(#failures) .. " derived evidence regression(s) failed:\n"
    .. table.concat(failures, "\n"))
print("derived-evidence: " .. passed .. " cases passed")
