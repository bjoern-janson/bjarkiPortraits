-- Native portrait countdown formatting: decimals below ten seconds.
-- Load the actual Core.lua; validate both formatter and compatibility paths.
local BP = {}
local oldGlobals = { db = BjarkiPortraitsDB, strings = C_StringUtil, enumeration = Enum }
local constructors = 0
C_StringUtil = {
    CreateNumericRuleFormatter = function()
        constructors = constructors + 1
        return {
            SetBreakpoints = function(self, rules) self.rules = rules end,
        }
    end,
}
Enum = { NumericRuleFormatRounding = {Down = 2} }
BjarkiPortraitsDB = {}
assert(loadfile("Core.lua"))("bjarkiPortraits", BP)
local R = assert(BP.Runtime)
R.ApplyDefaults()

local checked = 0
local function check(ok, label)
    assert(ok, label)
    checked = checked + 1
end
local function equal(actual, expected, label)
    check(actual == expected, (label or "unexpected value")
        .. ": got=" .. tostring(actual) .. " expected=" .. tostring(expected))
end
local function render(formatter, seconds)
    local choice
    for _, rule in ipairs(formatter.rules) do
        if seconds >= rule.threshold then choice = rule end
    end
    assert(choice, "no countdown rule")
    if choice.format == "" then return "" end
    local value = seconds
    if choice.step then
        local divided = value / choice.step
        if choice.rounding == Enum.NumericRuleFormatRounding.Down then
            value = math.floor(divided) * choice.step
        else
            value = math.floor(divided + 0.5) * choice.step
        end
    end
    return string.format(choice.format, value)
end

equal(R.db.showDecimals, true, "existing default enables decimals")
local enabled = assert(R.GetCountdownFormatter())
equal(constructors, 1, "one formatter allocated")
equal(#enabled.rules, 3, "existing three-breakpoint formatter")
equal(enabled.rules[1].threshold, 0, "one-decimal rule begins at zero")
equal(enabled.rules[1].format, "%.1f", "native one-decimal format unchanged")
equal(enabled.rules[2].threshold, 10, "whole seconds begin precisely at ten")
equal(enabled.rules[2].format, "%.0f", "whole-second format intact")
equal(enabled.rules[2].step, 1, "whole-second step unchanged")
equal(enabled.rules[2].rounding, Enum.NumericRuleFormatRounding.Down,
    "existing round-down behavior remains")
equal(enabled.rules[3].threshold, 60.000001, "existing sixty-second hiding rule unchanged")
equal(enabled.rules[3].format, "", "long duration text remains hidden")
for _, case in ipairs({
    {0.1, "0.1"}, {1.4, "1.4"}, {2.9, "2.9"},
    {3, "3.0"}, {4, "4.0"}, {4.9, "4.9"},
    {5, "5.0"}, {5.1, "5.1"}, {5.9, "5.9"},
    {9.9, "9.9"}, {10, "10"}, {10.1, "10"},
    {12.9, "12"}, {59.9, "59"}, {60, "60"},
    {60.000001, ""}, {90, ""},
}) do
    equal(render(enabled, case[1]), case[2],
        "native decimal-on boundary " .. tostring(case[1]))
end
check(R.GetCountdownFormatter() == enabled, "same setting reuses formatter")
equal(constructors, 1, "no duplicate formatter construction")

local function makeCooldown(nativeSuccess)
    local result = { hidden = nil, formatter = nil, fallback = nil,
        applyCount = 0, fallbackCount = 0 }
    function result:SetHideCountdownNumbers(value) self.hidden = value end
    function result:SetCountdownFormatter(value)
        self.applyCount = self.applyCount + 1
        if not nativeSuccess then error("native formatter unavailable") end
        self.formatter = value
    end
    function result:SetCountdownMillisecondsThreshold(value)
        self.fallbackCount = self.fallbackCount + 1
        self.fallback = value
    end
    return result
end

local working = makeCooldown(true)
R.ApplyCountdownFormat(working)
equal(working.hidden, false, "native numbers kept visible")
check(working.formatter == enabled, "enabled rule applied to existing Cooldown")
equal(working.applyCount, 1, "formatter applied once")
equal(working.fallbackCount, 0, "compatibility threshold not used on native success")
local fallback = makeCooldown(false)
R.ApplyCountdownFormat(fallback)
equal(fallback.fallback, 10, "unsupported native formatter uses 10-second fallback")
equal(fallback.fallbackCount, 1, "native fallback called exactly once")

R.db.showDecimals = false
local disabled = assert(R.GetCountdownFormatter())
equal(constructors, 2, "toggle obtains independent formatter")
check(disabled ~= enabled, "decimal-off mode has its own formatter")
equal(#disabled.rules, 2, "decimal-off rule count unchanged")
equal(disabled.rules[1].threshold, 0, "decimal-off whole seconds from zero")
equal(disabled.rules[1].format, "%.0f", "decimal-off uses whole seconds")
equal(disabled.rules[2].threshold, 60.000001,
    "decimal-off long timer hiding remains unchanged")
equal(render(disabled, 4.9), "4", "decimal-off leaves four whole seconds")
equal(render(disabled, 5), "5", "decimal-off five whole seconds")
equal(render(disabled, 9.9), "9", "decimal-off below ten whole seconds")
equal(render(disabled, 10), "10", "decimal-off ten whole seconds")
equal(render(disabled, 10.1), "10", "decimal-off above ten whole seconds")
equal(render(disabled, 59.9), "59", "decimal-off down-rounded whole seconds")
local offFallback = makeCooldown(false)
R.ApplyCountdownFormat(offFallback)
equal(offFallback.fallback, 0, "decimal-off compatibility threshold remains zero")
local offNative = makeCooldown(true)
R.ApplyCountdownFormat(offNative)
check(offNative.formatter == disabled, "decimal-off native formatter applied")

R.db.showDecimals = true
local again = assert(R.GetCountdownFormatter())
equal(again.rules[2].threshold, 10, "decimals toggle back restores ten seconds")

-- On builds without the numeric formatter, keep the compatibility path
-- instead of reading, comparing or rescheduling any protected aura duration.
R._formatter, R._formatterKey = nil, nil
C_StringUtil = nil
local noNative = makeCooldown(false)
R.ApplyCountdownFormat(noNative)
equal(noNative.fallback, 10, "missing numeric formatter API uses ten-second fallback")
check(noNative.formatter == nil, "missing API adds no custom formatter")

-- Restore the mutable globals for compatibility with combined test runners.
BjarkiPortraitsDB = oldGlobals.db
C_StringUtil = oldGlobals.strings
Enum = oldGlobals.enumeration
print("bjarkiPortraits ten-second decimals: " .. checked .. " assertions passed")
