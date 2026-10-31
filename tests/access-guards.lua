-- Run from the addon source directory: lua tests/access-guards.lua
-- Exercises the shipped guards against modeled client access APIs. Ordinary
-- Lua cannot reproduce the client secrecy VM or protected-value operations.
local oldSecret, oldAccess = issecretvalue, canaccessvalue
local BP = {}
assert(loadfile("Core.lua"))("bjarkiPortraits", BP)
local R = assert(BP.Runtime)
local SECRET = {}
local passed, failures = 0, {}
local function equal(actual, expected, label)
    assert(actual == expected, (label or "value") .. ": expected "
        .. tostring(expected) .. ", actual " .. tostring(actual))
end
local function test(name, body)
    issecretvalue = function(value) return value == SECRET end
    canaccessvalue = nil
    local ok, err = pcall(body)
    if ok then
        passed = passed + 1
        print("PASS " .. name)
    else
        failures[#failures + 1] = name .. ": " .. tostring(err)
        print("FAIL " .. failures[#failures])
    end
end

-- Catches treating an unsuccessful or malformed available checker as access.
-- Each fixture models only the external API; expectations are literal policy.
local checkers = {
    {name="absent", want=true},
    {name="explicit grant", fn=function() return true end, want=true},
    {name="explicit denial", fn=function() return false end, want=false},
    {name="throwing checker", fn=function() error("modeled inaccessible check") end, want=false},
    {name="nil result", fn=function() return nil end, want=false},
    {name="string result", fn=function() return "true" end, want=false},
    {name="number result", fn=function() return 1 end, want=false},
    {name="table result", fn=function() return {} end, want=false},
    {name="secret result", fn=function() return SECRET end, want=false},
}
for _, checker in ipairs(checkers) do
    test("CanAccess: " .. checker.name, function()
        canaccessvalue = checker.fn
        equal(R.CanAccess("ordinary"), checker.want, "readability")
    end)
    -- Catches wrappers bypassing CanAccess, plus collapsing readable false to
    -- UNKNOWN or accepting truthy nonbooleans. They must preserve two results.
    for _, value in ipairs({true, false}) do
        test("SafeBool " .. tostring(value) .. ": " .. checker.name, function()
            canaccessvalue = checker.fn
            local got, readable = R.SafeBool(function() return value end)
            equal(readable, checker.want, "readability")
            if checker.want then equal(got, value, "boolean value")
            else equal(got, nil, "unreadable value") end
        end)
    end
    test("SafeString: " .. checker.name, function()
        canaccessvalue = checker.fn
        local got, readable = R.SafeString(function() return "Player-1-Readable" end)
        equal(readable, checker.want, "readability")
        if checker.want then equal(got, "Player-1-Readable", "string value")
        else equal(got, nil, "unreadable value") end
    end)
end

-- Catches a failed available secrecy checker being mistaken for proof that
-- ordinary API results are public, both with and without an access checker.
local secrecyCheckers = {
    {name="absent", want=true},
    {name="public", fn=function() return false end, want=true},
    {name="secret", fn=function() return true end, want=false},
    {name="throwing", fn=function() error("modeled secrecy failure") end, want=false},
    {name="nil", fn=function() return nil end, want=false},
    {name="string", fn=function() return "false" end, want=false},
    {name="number", fn=function() return 0 end, want=false},
    {name="table", fn=function() return {} end, want=false},
    {name="secret result", fn=function() return SECRET end, want=false},
}
local oldUnits = {exists=UnitExists, assist=UnitCanAssist,
    player=UnitIsPlayer, guid=UnitGUID, controlled=UnitIsPlayerControlledOrGroupMember}
UnitExists = function() return true end
UnitCanAssist = function() return true end
UnitIsPlayer = function() return true end
UnitGUID = function() return "Player-1-Readable" end
UnitIsPlayerControlledOrGroupMember = nil
for _, checker in ipairs(secrecyCheckers) do
    for _, grant in ipairs({false, true}) do
        local label = checker.name .. ", access checker " .. tostring(grant)
        local function configure()
            issecretvalue = checker.fn
            if grant then canaccessvalue = function() return true end end
        end
        test("CanAccess secrecy: " .. label, function()
            configure()
            equal(R.CanAccess("ordinary"), checker.want, "readability")
        end)
        test("SafeBool secrecy: " .. label, function()
            configure()
            local value, readable = R.SafeBool(UnitExists, "target")
            equal(readable, checker.want, "readability")
            if checker.want then equal(value, true) else equal(value, nil) end
        end)
        test("SafeString secrecy: " .. label, function()
            configure()
            local value, readable = R.SafeString(UnitGUID, "target")
            equal(readable, checker.want, "readability")
            if checker.want then equal(value, "Player-1-Readable")
            else equal(value, nil) end
        end)
        test("ExactFilterAllowed secrecy: " .. label, function()
            configure()
            equal(R.ExactFilterAllowed("target", true, {}), checker.want, "permission")
        end)
        test("PlayerUnitState secrecy: " .. label, function()
            configure()
            local value, readable = R.PlayerUnitState("target")
            equal(readable, checker.want, "identity readability")
            if checker.want then equal(value, true) else equal(value, nil) end
        end)
    end
end
UnitExists, UnitCanAssist = oldUnits.exists, oldUnits.assist
UnitIsPlayer, UnitGUID = oldUnits.player, oldUnits.guid
UnitIsPlayerControlledOrGroupMember = oldUnits.controlled

-- Catches checking the input but certifying an unreadable access-check result.
test("CanAccess rejects failed secrecy check on the access result", function()
    issecretvalue = function(value)
        if value == "ordinary" then return false end
        return nil
    end
    canaccessvalue = function() return true end
    equal(R.CanAccess("ordinary"), false)
end)

-- Catches allowing a positive access check to override known secret values.
for _, grant in ipairs({false, true}) do
    test("known secret denied with checker " .. tostring(grant), function()
        if grant then canaccessvalue = function() return true end end
        equal(R.CanAccess(SECRET), false)
        for _, guard in ipairs({R.SafeBool, R.SafeString}) do
            local value, readable = guard(function() return SECRET end)
            equal(value, nil)
            equal(readable, false)
        end
    end)
end

-- Catches losing type validation or pcall handling when sharing access guards.
for _, guard in ipairs({{name="SafeBool", fn=R.SafeBool, wrong="true"},
    {name="SafeString", fn=R.SafeString, wrong=true}}) do
    test(guard.name .. " rejects wrong types and API failures", function()
        canaccessvalue = function() return true end
        local functions = {
            function() return guard.wrong end,
            function() return nil end,
            function() error("modeled API failure") end,
        }
        for _, fn in ipairs(functions) do
            local value, readable = guard.fn(fn)
            equal(value, nil)
            equal(readable, false)
        end
        local value, readable = guard.fn(nil)
        equal(value, nil)
        equal(readable, false)
    end)
end

-- Catches turning an ordinary but inaccessible unit result into evidence.
test("UnitExistsState keeps denied existence UNKNOWN", function()
    local oldExists = UnitExists
    UnitExists = function() return true end
    canaccessvalue = function() return false end
    local value, readable = R.UnitExistsState("targettarget")
    UnitExists = oldExists
    equal(value, nil)
    equal(readable, false)
end)

-- Catches reading an aura whose access check failed and certifying its fields.
test("ReadAuraField rejects failed access before indexing", function()
    local indexed = false
    local aura = setmetatable({}, {__index=function()
        indexed = true
        error("denied aura must not be indexed")
    end})
    canaccessvalue = function() error("modeled access failure") end
    local value, readable = R.ReadAuraField(aura, "spellId")
    equal(indexed, false, "denied aura indexing")
    equal(value, nil)
    equal(readable, false)
end)
test("ReadAuraField rejects a field with unknown access", function()
    local aura = {spellId=22812}
    canaccessvalue = function(value)
        if value == aura then return true end
        return nil
    end
    local value, readable = R.ReadAuraField(aura, "spellId")
    equal(value, nil)
    equal(readable, false)
end)

issecretvalue, canaccessvalue = oldSecret, oldAccess
print("bjarkiPortraits access guards: " .. passed .. " passed, " .. #failures .. " failed")
assert(#failures == 0, table.concat(failures, "\n"))
