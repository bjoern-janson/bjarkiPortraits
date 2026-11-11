-- Native portrait countdown formatting: decimals below ten seconds.
-- Load the actual Core.lua; validate both formatter and compatibility paths.
local BP = {}
local oldGlobals = { db = BjarkiPortraitsDB, strings = C_StringUtil, enumeration = Enum }
local constructors = 0
local render
C_StringUtil = {
    CreateNumericRuleFormatter = function()
        constructors = constructors + 1
        return {
            SetBreakpoints = function(self, rules) self.rules = rules end,
            FormatNumber=render,
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
render=function(formatter, seconds)
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
equal(enabled.rules[3].threshold,90+2^-46,"hide immediately above ninety on a double-precision clock")
equal(enabled.rules[3].format, "", "long duration text remains hidden")
for _, case in ipairs({
    {0.1, "0.1"}, {1.4, "1.4"}, {2.9, "2.9"},
    {3, "3.0"}, {4, "4.0"}, {4.9, "4.9"},
    {5, "5.0"}, {5.1, "5.1"}, {5.9, "5.9"},
    {9.9, "9.9"}, {10, "10"}, {10.1, "10"},
    {12.9, "12"}, {29.99,"29"}, {30,"30"}, {30.01,"30"},
    {31,"31"}, {59.99,"59"}, {60,"60"}, {60.01,"60"},
    {61,"61"}, {89.99,"89"}, {90,"90"}, {90+2^-46,""}, {91,""}, {48*60,""},
}) do
    equal(render(enabled, case[1]), case[2],
        "native decimal-on boundary " .. tostring(case[1]))
end
check(R.GetCountdownFormatter() == enabled, "same setting reuses formatter")
equal(constructors, 1, "no duplicate formatter construction")

local function makeCooldown(nativeSuccess)
    local result = { hidden = nil, formatter = nil, fallback = nil,
        applyCount = 0, fallbackCount = 0 }
    function result:SetHideCountdownNumbers(value)
        assert(value or self.formatter,"uncapped stock timer was exposed")
        self.hidden = value
    end
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
do
    local constructor=C_StringUtil.CreateNumericRuleFormatter
    R._formatter=nil
    for _,failure in ipairs({'constructor','setup','no numeric readback'}) do
        R.RetryCountdownFormatter()
        local attempts=0
        C_StringUtil.CreateNumericRuleFormatter=function()
            attempts=attempts+1
            if failure=='constructor' then error('denied object') end
            if failure=='no numeric readback' then return {SetBreakpoints=function() end} end
            return {SetBreakpoints=function()error('denied rules') end}
        end
        local cd=makeCooldown(true)
        equal(R.ApplyCountdownFormat(cd),true,'failed '..failure..' hides only numbers')
        equal(cd.hidden,true,'stock minutes remain hidden after '..failure)
        equal(R._formatter,nil,'failed build never cached')
        for _=1,120 do equal(R.ApplyCountdownFormat(cd),true,'avoid new work in a failed batch') end
        equal(attempts,1,'one failed formatter allocation per opportunity')
    end
    C_StringUtil.CreateNumericRuleFormatter=constructor
    local attemptsBefore=constructors
    local validEnum=Enum
    Enum=nil;R.RetryCountdownFormatter()
    equal(R.GetCountdownFormatter(),nil,'missing rounding enum is safe')
    equal(constructors,attemptsBefore,'missing enum skips allocation')
    Enum=validEnum;R.RetryCountdownFormatter()
    enabled=assert(R.GetCountdownFormatter())
end
equal(R.ApplyCountdownFormat(working), true, "native presenter confirms the preference")
equal(working.hidden, false, "native numbers kept visible")
check(working.formatter == enabled, "enabled rule applied to existing Cooldown")
equal(working.applyCount, 1, "formatter applied once")
equal(working.fallbackCount, 0, "compatibility threshold not used on native success")
local fallback = makeCooldown(false)
equal(R.ApplyCountdownFormat(fallback), true, "compatibility presenter confirms the preference")
equal(R.ApplyCountdownFormat({
    SetCountdownFormatter=function() return false end,
    SetCountdownMillisecondsThreshold=function() error("layout locked") end,
}), false, "rejected native and compatibility paths remain retryable")
equal(fallback.hidden,true,"unsupported native formatter suppresses 48m")
equal(fallback.fallbackCount,0,"decimal precision cannot enforce a visibility cutoff")
fallback.SetCountdownFormatter=working.SetCountdownFormatter
R.RetryCountdownFormatter()
equal(R.ApplyCountdownFormat(fallback),true,"formatter recovers on a later opportunity")
equal(fallback.hidden,false,"the capped countdown becomes visible on recovery")

R.db.showDecimals = false
local beforeToggle=constructors
local disabled = assert(R.GetCountdownFormatter())
equal(constructors, beforeToggle+1, "toggle obtains independent formatter")
check(disabled ~= enabled, "decimal-off mode has its own formatter")
equal(#disabled.rules, 2, "decimal-off rule count unchanged")
equal(disabled.rules[1].threshold, 0, "decimal-off whole seconds from zero")
equal(disabled.rules[1].format, "%.0f", "decimal-off uses whole seconds")
equal(disabled.rules[2].threshold,90+2^-46,"decimal-off uses the same visibility cap")
equal(render(disabled, 4.9), "4", "decimal-off leaves four whole seconds")
equal(render(disabled, 5), "5", "decimal-off five whole seconds")
equal(render(disabled, 9.9), "9", "decimal-off below ten whole seconds")
equal(render(disabled, 10), "10", "decimal-off ten whole seconds")
equal(render(disabled, 10.1), "10", "decimal-off above ten whole seconds")
equal(render(disabled,30),"30","decimal-off includes exactly 30")
equal(render(disabled,31),"31","decimal-off 31 seconds now visible")
equal(render(disabled,59.99),"59","decimal-off 59 whole seconds visible")
equal(render(disabled,60),"60","decimal-off includes exactly sixty")
equal(render(disabled,61),"61","decimal-off preserves 61 seconds")
equal(render(disabled,89.99),"89","decimal-off preserves whole 89 seconds")
equal(render(disabled,90),"90","decimal-off includes exactly ninety")
equal(render(disabled,90+2^-46),"","decimal-off suppresses the next representable instant")
equal(render(disabled,2880),"","decimal-off suppresses 48m")
local offFallback = makeCooldown(false)
R.ApplyCountdownFormat(offFallback)
equal(offFallback.hidden,true,"decimal-off fallback hides uncapped stock numbers")
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
equal(noNative.hidden,true,"missing numeric formatter API keeps uncapped stock times out of the portrait")
check(noNative.formatter == nil, "missing API adds no custom formatter")

-- Exact native AuraButtonArtTemplate.Duration font is GameFontNormalSmall.
local originalInCombat=InCombatLockdown
local originalRegularFont=GameFontNormalSmall
local originalAuraDurationFont=DEFAULT_AURA_DURATION_FONT
local regularFont={name="GameFontNormalSmall",size=10}
local otherFont={name="DEFAULT_AURA_DURATION_FONT",size=11}
GameFontNormalSmall=regularFont
DEFAULT_AURA_DURATION_FONT=nil
local combatLock=false
InCombatLockdown=function() return combatLock end
local function makeSecondaryFontCooldown()
    local cd={calls=0}
    local label={writes=0,points={}}
    function label:SetFontObject(value) self.font=value;self.writes=self.writes+1 end
    function label:ClearAllPoints() self.points={} end
    function label:SetPoint(...) self.points[#self.points+1]={...} end
    function label:SetJustifyH(value) self.justifyH=value end
    function label:SetJustifyV(value) self.justifyV=value end
    function label:SetTextColor(...) self.color={...} end
    function cd:GetCountdownFontString() self.calls=self.calls+1;return label end
    cd.label=label
    return cd
end
local smallTimer=makeSecondaryFontCooldown()
check(R.ApplySecondaryCountdownFont(smallTimer),"font applied")
check(smallTimer.label.font==regularFont,"exact same font object as regular buffs")
equal(smallTimer.label.writes,1,"first font write")
equal(smallTimer.label.points[1][1],"CENTER","center anchor")
check(smallTimer.label.points[1][2]==smallTimer,"center relative to cooldown")
equal(smallTimer.label.points[1][3],"CENTER","center relative point")
equal(smallTimer.label.justifyH,"CENTER","center horizontal")
equal(smallTimer.label.justifyV,"MIDDLE","center vertical")
for i=1,4 do equal(smallTimer.label.color[i],1,"white RGBA "..i) end
check(R.ApplySecondaryCountdownFont(smallTimer),"reassert style on pooled label")
equal(smallTimer.label.writes,1,"same font not rewritten")
DEFAULT_AURA_DURATION_FONT=otherFont
check(R.ApplySecondaryCountdownFont(smallTimer),"template font preferred")
check(smallTimer.label.font==regularFont,"not a potentially different default size")
GameFontNormalSmall=nil
check(R.ApplySecondaryCountdownFont(smallTimer),"fallback if exact font unavailable")
check(smallTimer.label.font==otherFont,"fallback font")
equal(smallTimer.label.writes,2,"fallback font installed")
combatLock=true
GameFontNormalSmall=regularFont
check(not R.ApplySecondaryCountdownFont(smallTimer),"no relayout in combat")
equal(smallTimer.label.writes,2,"combat leaves existing font")
combatLock=false
check(R.ApplySecondaryCountdownFont(smallTimer),"OOC restyles")
equal(smallTimer.label.writes,3,"regular font restored once")

local primary = makeCooldown(true)
R.ApplyCountdownFormat(primary)
equal(primary.hidden,true,"primary countdown keeps uncapped stock minutes hidden")
check(primary._bjarkiSecondaryFontObject==nil,
    "ApplyCountdownFormat alone never changes main-portrait typography")
check(not R.ApplySecondaryCountdownFont({}),
    "missing native GetCountdownFontString is nonfatal")
local noLabel={GetCountdownFontString=function() return nil end}
check(not R.ApplySecondaryCountdownFont(noLabel),
    "unavailable countdown FontString defers without fabricated text")
local badRead={GetCountdownFontString=function() error("protected") end}
check(not R.ApplySecondaryCountdownFont(badRead),
    "inaccessible text is never read outside guarded pcall")
local badSetter={GetCountdownFontString=function()
    return {SetFontObject=function() error("protected") end}
end}
check(not R.ApplySecondaryCountdownFont(badSetter),
    "rejected protected font write fails closed")
combatLock=true
local inCombat = makeSecondaryFontCooldown()
check(not R.ApplySecondaryCountdownFont(inCombat),
    "combat prevents even the initial font-object write")
equal(inCombat.calls,0,"no font-string read attempted during combat")
combatLock=false
DEFAULT_AURA_DURATION_FONT=originalAuraDurationFont
GameFontNormalSmall=originalRegularFont
InCombatLockdown=originalInCombat

-- Core delegates digit rendering before considering its capped stock fallback.
-- A rejected native formatter must still never expose uncapped minutes.
do
    local oldCells,oldBase=R.ApplyPortraitTimer,R.GetCountdownFormatter
    local label,base={},{}
    local permit=true
    R.ApplyPortraitTimer=function(clock,observed,verify)
        if not permit then return false end
        equal(observed,label,"the final style label reaches the cell owner")
        clock:SetHideCountdownNumbers(true)
        clock._bjarkiTimerNumbersShown=false
        return true
    end
    R.GetCountdownFormatter=function()return base end
    local clock={
        SetCountdownFormatter=function(self,f) self.formatter=f;self.writes=(self.writes or 0)+1 end,
        SetHideCountdownNumbers=function(self,hide)self.hidden=hide end,
        GetHideCountdownNumbers=function(self)return self.hidden end,
    }
    local ok,backend=R.ApplyCountdownFormat(clock,label,true)
    check(ok and backend=="cells" and clock.hidden,"complete cells retain exclusive digit ownership")
    equal(clock.writes,nil,"Core does not install or unhide a stock formatter over cells")
    permit=false
    ok,backend=R.ApplyCountdownFormat(clock,label,true)
    check(ok and backend=="formatter" and clock.formatter==base and not clock.hidden,
        "incomplete cells recover the capped stock formatter")

    -- A separate Lua handle may represent the formatter the widget accepted.
    local function policy(_,t) return t<=60 and tostring(t) or "" end
    base.FormatNumber=policy
    local proxy={
        SetCountdownFormatter=function(self,f) self.receipt={FormatNumber=f.FormatNumber} end,
        GetCountdownFormatter=function(self)return self.receipt end,
        SetHideCountdownNumbers=function(self,hide)self.hidden=hide end,
    }
    ok,backend=R.ApplyCountdownFormat(proxy,label)
    check(ok and backend=="formatter" and not proxy.hidden,"an equivalent capped handle remains visible")
    proxy.SetCountdownFormatter=function(self)
        self.receipt={FormatNumber=function(_,t)return t>60 and "48m" or tostring(t) end}
    end
    proxy.receipt=nil
    ok,backend=R.ApplyCountdownFormat(proxy,label,true)
    check(ok and backend=="hidden" and proxy.hidden,"a substituted stock rule stays hidden")
    -- Native-second backing clocks bypass the heavy fixed-cell path
    -- while continuing to use this verified 90-second native cap.
    permit=true
    local light=makeCooldown(true)
    light._bjarkiLightNativeSecond=true
    local lightOK,lightBackend=R.ApplyCountdownFormat(light,label,true)
    check(lightOK and lightBackend=="formatter" and light.formatter==base,
        "light native second never requests a six-cell renderer")
    R.ApplyPortraitTimer,R.GetCountdownFormatter=oldCells,oldBase
end
BjarkiPortraitsDB = oldGlobals.db
C_StringUtil = oldGlobals.strings
Enum = oldGlobals.enumeration
print("bjarkiPortraits ten-second decimals: " .. checked .. " assertions passed")
