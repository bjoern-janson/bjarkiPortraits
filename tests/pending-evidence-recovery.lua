-- Run from the addon source directory: lua tests/pending-evidence-recovery.lua
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
        relations={}, players={}, playerRelation=true, clock=100, queries=0, queryLog={}, refreshes={}}
    GetTime = function() return s.clock end
    UnitIsPlayer = function(unit) if s.players[unit] == "unknown" then return nil end return s.players[unit] ~= false end
    UnitCanAttack = function(_, unit) if s.relations[unit] == "unknown" then return nil end return s.playerRelation and s.relations[unit] ~= false end
    UnitGUID = function(unit) return s.guids[unit] or "Player-1-" .. unit end
    InCombatLockdown = function() return false end
    C_Timer = {After=function(delay, callback)
        eq(delay, 0, "next-tick scheduling")
        s.timers[#s.timers+1] = callback
    end}
    C_UnitAuras = {GetUnitAuraBySpellID=function(unit, spellID)
        s.queries = s.queries + 1
        s.queryLog[#s.queryLog+1] = {unit=unit, spellID=spellID}
        if s.failures[unit] and s.failures[unit][spellID] then error("modeled unavailable query") end
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
        self.timers = {}; self.clock = self.clock + 0.25
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

-- These regressions catch event routing that forgets retained snapshot work.
-- GetTime advances before each callback; this remains an offline API model.
local function identity(s, record, unit, guid, instance)
    recordIdentity(record, unit, guid or s.guids[unit], instance)
    eq(record.kind, "aura-positive", "positive-only observation")
    eq(record.observedAt, s.clock, "current observation time")
end
local function blocked(s, unit, reason)
    if reason == nil then reason = false end
    s.relations[unit] = reason
    s.auras[unit] = {[22812]=aura(112, 12)}
    s:bind(unit)
    eq(s.queries, 0, "ineligible binding must not query")
    eq(#s.received, 0, "ineligible binding must not publish")
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
local units = {"targettarget", "focustarget"}
local events = {"UNIT_FACTION", "UNIT_FLAGS"}
for _, unit in ipairs(units) do
    for _, event in ipairs(events) do
        test(event .. " recovers pending " .. unit .. " once", function()
            local s = setup()
            blocked(s, unit)
            s.relations[unit] = true
            s.refreshes = {}
            s:fire(event, unit)
            eq(#s.timers, 1, "one deferred recovery")
            eq(s.queries, 0, "recovery must remain deferred")
            eq(#s.refreshes, 1, "immediate visual reconciliation")
            eq(s.refreshes[1].force, true)
            s:drain()
            eq(s.queries, 9, "one fixed shortlist")
            eq(#s.received, 1, "eligible pending snapshot publishes")
            identity(s, s.received[1], unit)
            eq(s.clock, 100.5, "callback clock advanced")
            eq(#s.refreshes, 2, "deferred full visual reconciliation remains")
            eq(s.refreshes[2].unit, unit)
            eq(s.refreshes[2].force, true)
            s:fire(event, unit)
            s:drain()
            eq(s.queries, 9, "completed work must not reopen")
            eq(#s.received, 1, "completion consumes pending work")
        end)
    end
end
for _, event in ipairs(events) do
    test(event .. " player recovery includes both pending tokens", function()
        local s = setup()
        s.playerRelation = false
        for _, unit in ipairs(units) do
            s.auras[unit] = {[22812]=aura(112, 12)}
            s:bind(unit)
        end
        eq(s.queries, 0)
        s.playerRelation = true
        s.refreshes = {}
        s:fire(event, "player")
        eq(s.queries, 0, "player recovery remains deferred")
        eq(#s.timers, 1, "all hosts share one callback")
        eq(#s.refreshes, 5, "all hosts reconciled immediately")
        s:drain()
        eq(s.queries, 18, "nine queries for each pending token")
        eq(#s.received, 2)
        eq(#s.refreshes, 10, "all hosts retain deferred full reconciliation")
        local found = {}
        for _, record in ipairs(s.received) do
            identity(s, record, record.unit)
            found[record.unit] = true
        end
        eq(found.targettarget, true)
        eq(found.focustarget, true)
        s:fire(event, "player")
        s:drain()
        eq(s.queries, 18, "completed player-wide recovery stays consumed")
    end)
    for _, pendingUnit in ipairs(units) do
        test(event .. " player recovery scans only pending " .. pendingUnit, function()
            local s = setup()
            local completedUnit = pendingUnit == "targettarget" and "focustarget" or "targettarget"
            blocked(s, pendingUnit)
            s:bind(completedUnit)
            eq(s.queries, 9, "other token completed its empty pass")
            s.relations[pendingUnit] = true
            s:fire(event, "player")
            s:drain()
            eq(s.queries, 18, "only the pending token receives nine queries")
            eq(#s.received, 1)
            identity(s, s.received[1], pendingUnit)
            for i=10,18 do eq(s.queryLog[i].unit, pendingUnit, "completed token not rescanned") end
        end)
    end
    test(event .. " without pending binding creates no snapshot work", function()
        local s = setup()
        s:fire(event, "player")
        for _, unit in ipairs(units) do s:fire(event, unit) end
        s:drain()
        eq(s.queries, 0, "visual events cannot create fresh evidence work")
        eq(#s.received, 0)
    end)
end
-- A partial query keeps both tokens pending across repeated independent bursts.
test("relation bursts coalesce to nine queries per pending token", function()
    local s = setup()
    for _, unit in ipairs(units) do
        blocked(s, unit)
        s.failures[unit] = {[5277]=true}
    end
    for _, unit in ipairs(units) do s.relations[unit] = true end
    for burst=1,3 do
        local before = s.queries
        for n=1,100 do
            s:fire("UNIT_FACTION", "targettarget")
            s:fire("UNIT_FLAGS", "focustarget")
            s:fire("UNIT_FACTION", "player")
            s:fire("UNIT_FLAGS", "player")
        end
        eq(#s.timers, 1, "one callback per burst")
        eq(s.queries, before, "no synchronous scans")
        s:drain()
        eq(s.queries-before, 18, "exactly nine queries per pending token")
        eq(#s.received, burst*2, "independent positives survive partial reads")
    end
    s.failures = {}
    s:fire("UNIT_FLAGS", "player")
    s:drain()
    eq(s.queries, 72, "final complete pass scans both tokens")
    s:fire("UNIT_FACTION", "player")
    s:drain()
    eq(s.queries, 72, "completion consumes both requests")
end)
for _, unit in ipairs(units) do
    test("ineligible events retain " .. unit .. " without polling", function()
        local s = setup()
        blocked(s, unit, "unknown")
        s:fire("UNIT_FACTION", unit)
        s:drain()
        eq(s.queries, 0, "unknown relation remains blocked")
        s.clock = s.clock + 20
        s:drain()
        eq(s.queries, 0, "elapsed time alone cannot retry")
        s.relations[unit] = true
        s.players[unit] = "unknown"
        s:fire("UNIT_FLAGS", unit)
        s:drain()
        eq(s.queries, 0, "unknown player identity remains blocked")
        s.players[unit] = true
        s:fire("UNIT_FACTION", unit)
        s:drain()
        eq(s.queries, 9, "later eligible event still recovers")
        eq(#s.received, 1)
        identity(s, s.received[1], unit)
    end)
    test("queued recovery reads current GUID for " .. unit, function()
        local s = setup()
        blocked(s, unit)
        s.relations[unit] = true
        s:fire("UNIT_FACTION", unit)
        s.guids[unit] = "Player-1-Rebound"
        s.auras[unit] = {[22812]=aura(117, 12, 37)}
        s:drain()
        eq(s.queries, 9)
        eq(#s.received, 1)
        identity(s, s.received[1], unit, "Player-1-Rebound", 37)
        eq(s.received[1].expirationTime, 117, "current aura timing")
    end)
    test("global disable cancels pending recovery for " .. unit, function()
        local s = setup()
        blocked(s, unit)
        s.relations[unit] = true
        s:fire("UNIT_FLAGS", unit)
        eq(#s.timers, 1)
        s.R.db.enabled = false
        s:drain()
        eq(s.queries, 0, "disabled callback does not query")
        eq(#s.received, 0, "disabled callback does not publish")
        s.R.db.enabled = true
        s:fire("UNIT_FLAGS", unit)
        s:drain()
        eq(s.queries, 0, "disabled callback clears old pending state")
        s:bind(unit)
        eq(s.queries, 9, "fresh binding establishes work after re-enable")
        eq(#s.received, 1)
    end)
    test("partial recovery and later empty read preserve positives for " .. unit, function()
        local s = setup()
        blocked(s, unit)
        s.relations[unit] = true
        s.failures[unit] = {[5277]=true}
        s:fire("UNIT_FACTION", unit)
        s:drain()
        eq(s.queries, 9, "partial scan remains bounded")
        eq(#s.received, 1, "unrelated failure does not discard positive")
        identity(s, s.received[1], unit)
        local previous, stamp = s.received[1], s.clock
        s.failures = {}
        s.auras[unit] = {}
        s:fire("UNIT_FLAGS", unit)
        s:drain()
        eq(s.queries, 18, "partial work survives until later event")
        eq(#s.received, 1, "later empty scan makes no removal claim")
        recordIdentity(previous, unit, s.guids[unit])
        eq(previous.observedAt, stamp, "old positive time stays immutable")
        eq(previous.expirationTime, 112, "old positive expiry stays immutable")
        s:fire("UNIT_FACTION", unit)
        s:drain()
        eq(s.queries, 18, "completed empty retry consumes pending work")
    end)
    -- Positive control: this routing already works in the unchanged baseline.
    test("existing connection recovery remains valid for " .. unit, function()
        local s = setup()
        blocked(s, unit)
        s.relations[unit] = true
        s:fire("UNIT_CONNECTION", unit)
        s:drain()
        eq(s.queries, 9)
        eq(#s.received, 1)
        identity(s, s.received[1], unit)
    end)
end
-- Catches later visual-only work cancelling evidence, or a snapshot request
-- suppressing the full reconciliation already required by another event.
test("mixed visual and pending recovery requests preserve both kinds of work", function()
    for _, unit in ipairs(units) do
        for _, recoveryFirst in ipairs({true, false}) do
            local s = setup()
            blocked(s, unit)
            s.relations[unit] = true
            s.refreshes = {}
            if recoveryFirst then
                s:fire("UNIT_FACTION", unit)
                s:fire("UNIT_DISPLAYPOWER", unit)
            else
                s:fire("UNIT_DISPLAYPOWER", unit)
                s:fire("UNIT_FLAGS", unit)
            end
            eq(#s.timers, 1, "mixed requests share one callback")
            eq(s.queries, 0, "mixed requests remain deferred")
            s:drain()
            eq(s.queries, 9, "visual-only request cannot cancel pending evidence")
            eq(#s.received, 1)
            identity(s, s.received[1], unit)
            eq(#s.refreshes, 3, "two immediate and one deferred reconciliation")
            eq(s.refreshes[3].force, true, "deferred full reconciliation retained")
        end
    end
end)
assert(#failures == 0, tostring(#failures) .. " pending recovery regression(s) failed:\n"
    .. table.concat(failures, "\n"))
print("pending-evidence-recovery: " .. passed .. " cases passed")

