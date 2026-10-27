-- Run from the addon source root: lua tests/hostile-helpful-priority.lua
-- Portable Lua 5.1/5.4 behavioral regression against real R.UpdateHost.
-- WoW API/frame doubles expose enablement and presentation; they do not model
-- the native engine or establish live-game behavior. No debug/upvalue access.
-- Break caught: low exact helper authority disables a higher generic lane.
local BP, SECRET = {}, {}
local helpful, harmful, scanErrorAt = {}, {}, nil
local friendly, controlled, exists = false, false, true
issecretvalue = function(v) return v == SECRET end
canaccessvalue = function(v) return v ~= SECRET end
AuraContainerSortMethod = { AuraInstanceIDOnly = 1 }
AuraContainerSortDirection = { Reverse = 1 }
Enum = { SecrecyLevel = { NeverSecret = 0 } }
C_Secrets = { GetSpellAuraSecrecy = function() return 1 end }
UnitExists = function() return exists end
UnitCanAssist = function(_, unit) return unit == "player" or friendly end
UnitIsPlayer = function() return true end
UnitIsPlayerControlledOrGroupMember = function() return controlled end
UnitIsDeadOrGhost = function() return false end
UnitIsGhost = function() return false end
UnitClass = function() return "Mage", "MAGE" end
InCombatLockdown = function() return false end
C_Spell = { GetSpellTexture = function() return 999 end }
local function readAura(_, index, filter)
    if filter:find("HARMFUL", 1, true) then return harmful[index] end
    if scanErrorAt == index then error("modeled aura read failure") end
    return helpful[index]
end
C_UnitAuras = {
    GetAuraDataByIndex = readAura,
    GetUnitAuraBySpellID = function() return nil end,
    GetPlayerAuraBySpellID = function() return nil end,
    GetAuraDuration = function() return nil end,
}
for _, file in ipairs({ "Spells.lua", "Core.lua", "Priority.lua", "AuraEngine.lua" }) do
    assert(loadfile(file))("bjarkiPortraits", BP)
end
local R = BP.Runtime
R.ApplyDefaults()
local checks, cases, failures, current = 0, 0, {}, "initialization"
local function check(ok, label)
    checks = checks + 1
    if not ok then failures[#failures + 1] = current .. ": " .. label end
end
local function equal(actual, expected, label)
    check(actual == expected, label .. " (got " .. tostring(actual)
        .. ", wanted " .. tostring(expected) .. ")")
end
local function aura(id, instance, duration)
    return { spellId = id, auraInstanceID = instance, duration = duration or 20,
        expirationTime = 120, icon = 12345 }
end
local function frame()
    local f = { shown = false, level = 0 }
    f.icon = { SetTexture = function(_, texture)
        if f.fail == "texture" then return false end
        f.texture = texture; return true
    end }
    f.cooldown = {
        SetCooldown = function(self, startTime, duration, timeMod)
            if f.fail == "cooldown" then error("modeled cooldown failure") end
            self.startTime, self.duration, self.timeMod = startTime, duration, timeMod
        end,
        Clear = function(self) self.startTime, self.duration, self.timeMod = nil, nil, nil end,
    }
    f.Show = function(self)
        if self.fail == "show" then error("modeled show failure") end
        self.shown = true
    end
    f.Hide = function(self) self.shown = false end
    f.SetFrameLevel = function(self, level)
        if self.fail == "level" then error("modeled level failure") end
        self.level = level
    end
    return f
end
local function host()
    local h = { unit = "target", unitFrame = { unit = "target" }, smallBaseLevel = 40,
        _buildComplete = true, containers = {}, cooldowns = {} }
    for _, key in ipairs({ "Hostile", "Baseline", "Healing", "WelcomingCampfire",
        "NearbyHarmful", "Stun", "InterruptSilence", "Wounds", "StatusEffects",
        "ResurrectionSickness", "DoTs", "FormState", "Dazed", "Demoralizing",
        "BaselineHarmful", "Slows", "Forbearance", "OffensiveHarmful",
        "WaitingToResurrect", "Ghost", "DivineProtection" }) do
        h["readable" .. key .. "Frame"] = frame()
    end
    for index, tier in ipairs(R.TIERS) do
        h.containers[index] = {
            tier = tier, enabled = false,
            SetEnabled = function(self, enabled) self.enabled = enabled end,
            SetShown = function(self, shown) self.shown = shown end,
            IsEnabled = function(self) return self.enabled end,
            UpdateAllAuras = function() end,
        }
    end
    return h
end
local function native(h, key)
    for _, c in ipairs(h.containers) do if c.tier.key == key then return c end end
    error("missing native container " .. key)
end
local function run(name, body)
    current, cases = name, cases + 1
    helpful, harmful, scanErrorAt = {}, {}, nil
    friendly, controlled, exists = false, false, true
    C_UnitAuras.GetAuraDataByIndex = readAura
    R.db.enabled, R.db.target, R.testMode = true, true, false
    local ok, err = pcall(body)
    if not ok then failures[#failures + 1] = name .. ": unexpected error: " .. tostring(err) end
end
local function broad(h, enabled)
    equal(native(h, "HostileHelpful").enabled, enabled, "generic native enabled")
    equal(native(h, "HostileHelpful").shown, enabled, "generic native shown")
end
local function presented(h, id, key, level, complete)
    equal(h._hostileActive, true, "readable helper is active")
    equal(h._hostileSpellID, id, "readable helper spell")
    equal(h.readableHostileFrame.shown, true, "readable helper is shown")
    equal(h.readableHostileFrame.level, level, "helper retains exact priority")
    local owner = h._readableTierOwners[key]
    check(owner ~= nil, "successful helper owns exact tier")
    if owner then
        equal(owner.frame, h.readableHostileFrame, "ownership names presented frame")
        equal(owner.complete, complete, "ownership completeness")
    end
end
local function absent(h)
    equal(h._hostileActive, false, "helper has no active presentation")
    equal(h.readableHostileFrame.shown, false, "helper is hidden")
    for _, owner in pairs(h._readableTierOwners) do
        check(owner.frame ~= h.readableHostileFrame, "absent helper has no ownership")
    end
end
-- CandidateFilters is the real production boundary passed to native containers.
-- Readable IDs below generic priority must be excluded from its candidate set;
-- otherwise enabling it could promote a newer low-tier aura above an unknown.
run("generic native admission excludes all lower helpful exact IDs", function()
    local filters = R.CandidateFilters(R.TIER_BY_KEY.HostileHelpful)
    for _, key in ipairs({ "Gathering", "Tracking", "CampfireNearby" }) do
        local tier = R.TIER_BY_KEY[key]
        local exact = R.CandidateFilters(tier)
        for id in pairs(tier.spellIDs) do
            equal(filters.excludeSpellIDs[id], true, key .. " excluded from generic: " .. id)
            equal(exact.includeSpellIDs[id], true, key .. " remains in exact lane: " .. id)
        end
    end
    equal(filters.excludeSpellIDs[987654321], nil, "unclassified generic candidate admitted")
end)
run("newer nearby aura cannot displace older generic candidate", function()
    local filters = R.CandidateFilters(R.TIER_BY_KEY.HostileHelpful)
    local candidates = { aura(987654321, 1), aura(1283391, 20) }
    local selected
    -- A bounded model of native identity admission and instance-ID ordering,
    -- used only for readable fixture IDs, not a claim about restricted values.
    for _, candidate in ipairs(candidates) do
        if not filters.excludeSpellIDs[candidate.spellId]
            and (not selected or candidate.auraInstanceID > selected.auraInstanceID) then
            selected = candidate
        end
    end
    equal(selected and selected.spellId, 987654321, "generic selected candidate stays unclassified")
end)
-- Literal expectations follow policy, independent of the election implementation.
for _, f in ipairs({ { "Gathering", 2383, 42 }, { "Tracking", 1494, 44 },
    { "CampfireNearby", 1283391, 45 } }) do
    local key, id, level = f[1], f[2], f[3]
    for _, withGeneric in ipairs({ true, false }) do
        run(key .. (withGeneric and " with generic candidate" or " alone"), function()
            helpful = { aura(id, 1, 0) }
            if withGeneric then helpful[2] = aura(987654321, 2) end
            local h = host(); R.UpdateHost(h)
            presented(h, id, key, level, true); broad(h, true)
        end)
    end
end
run("higher exact priority replaces generic after presentation", function()
    controlled = true -- Make the native same-tier owner legal too.
    helpful = { aura(2383, 1, 0), aura(642, 2), aura(987654321, 3) }
    local h = host(); R.UpdateHost(h)
    presented(h, 642, "Immunity", 371, true); broad(h, false)
    equal(native(h, "Immunity").enabled, false, "complete helper replaces same-tier native")
end)
run("equal exact priority is sufficient", function()
    -- No shipped helpful exact tier equals 5. This public-policy fixture checks
    -- that boundary without inspecting or changing any production closure.
    local tier = { key = "EqualPriorityFixture", level = 5, helpful = true,
        exact = true, filter = "HELPFUL", spellIDs = { [987654320] = true } }
    R.HELPFUL_TIER_BY_SPELL[987654320], R.TIER_BY_KEY[tier.key] = tier, tier
    R.TIERS[#R.TIERS + 1] = tier
    helpful = { aura(987654320, 1), aura(987654321, 2) }
    local h = host()
    local ok, err = pcall(R.UpdateHost, h)
    R.HELPFUL_TIER_BY_SPELL[987654320], R.TIER_BY_KEY[tier.key] = nil, nil
    table.remove(R.TIERS)
    assert(ok, err)
    presented(h, 987654320, "EqualPriorityFixture", 46, true); broad(h, false)
end)
run("empty helpful scan retains generic", function()
    local h = host(); R.UpdateHost(h); absent(h); broad(h, true)
end)
run("unclassified helpful scan retains generic", function()
    helpful = { aura(987654321, 1) }
    local h = host(); R.UpdateHost(h); absent(h); broad(h, true)
end)
run("unreadable helpful object retains generic", function()
    helpful = { SECRET }
    local h = host(); R.UpdateHost(h); absent(h); broad(h, true)
end)
for _, f in ipairs({ { "Gathering", 2383, 42 }, { "Immunity", 642, 371 } }) do
    local key, id, level = f[1], f[2], f[3]
    run(key .. " partial positive retains generic", function()
        helpful = { aura(id, 1), SECRET }
        local h = host(); R.UpdateHost(h)
        presented(h, id, key, level, false); broad(h, true)
    end)
end
run("unreadable identity prevents high helper authority", function()
    helpful = { aura(642, 1), aura(SECRET, 2) }
    local h = host(); R.UpdateHost(h)
    presented(h, 642, "Immunity", 371, false); broad(h, true)
end)
run("read failure after high positive prevents authority", function()
    helpful, scanErrorAt = { aura(642, 1) }, 2
    local h = host(); R.UpdateHost(h)
    presented(h, 642, "Immunity", 371, false); broad(h, true)
end)
run("unterminated bounded scan retains generic", function()
    helpful[1] = aura(642, 1)
    for i = 2, 80 do helpful[i] = aura(987654321, i) end
    local h = host(); R.UpdateHost(h)
    presented(h, 642, "Immunity", 371, false); broad(h, true)
end)
run("unreadable same-tier order retains generic", function()
    helpful = { aura(642, 1), aura(642, SECRET) }
    local h = host(); R.UpdateHost(h); absent(h); broad(h, true)
end)
run("partial presentation cannot compete with legal native exact owner", function()
    controlled = true
    helpful = { aura(642, 1), SECRET }
    local h = host(); R.UpdateHost(h); absent(h); broad(h, true)
    equal(native(h, "Immunity").enabled, true, "partial witness retains native exact owner")
end)
run("missing aura API retains generic", function()
    C_UnitAuras.GetAuraDataByIndex = nil
    local h = host(); R.UpdateHost(h); absent(h); broad(h, true)
end)
for _, failure in ipairs({ "texture", "cooldown", "show", "level" }) do
    run("failed " .. failure .. " revokes prior authority", function()
        controlled = true; helpful = { aura(642, 1) }
        local h = host(); R.UpdateHost(h); broad(h, false)
        h.readableHostileFrame.fail = failure
        R.UpdateHost(h); absent(h); broad(h, true)
        equal(native(h, "Immunity").enabled, true, "failed presentation restores native exact")
    end)
end
run("unreadable timing prevents high presentation", function()
    helpful = { aura(642, 1, SECRET) }
    local h = host(); R.UpdateHost(h); absent(h); broad(h, true)
end)
run("high to low transition relinquishes generic suppression", function()
    helpful = { aura(642, 1) }
    local h = host(); R.UpdateHost(h); broad(h, false)
    helpful = { aura(1494, 2, 0), aura(987654321, 3) }
    R.UpdateHost(h); presented(h, 1494, "Tracking", 44, true); broad(h, true)
    equal(h._readableTierOwners.Immunity, nil, "old higher ownership cleared")
end)
run("hostile to friendly clears hostile helper and generic", function()
    helpful = { aura(642, 1) }
    local h = host(); R.UpdateHost(h); friendly = true
    R.UpdateHost(h); absent(h); broad(h, false)
    equal(native(h, "Immunity").enabled, true, "friendly native exact eligible")
end)
for _, mode in ipairs({ "disabled", "unit-disabled", "test-mode", "absent-unit" }) do
    run(mode .. " clears hostile authority", function()
        helpful = { aura(642, 1) }
        local h = host(); R.UpdateHost(h)
        if mode == "disabled" then R.db.enabled = false
        elseif mode == "unit-disabled" then R.db.target = false
        elseif mode == "test-mode" then R.testMode = true
        else exists = false end
        R.UpdateHost(h); absent(h); broad(h, false)
        for _, c in ipairs(h.containers) do equal(c.enabled, false, "inactive " .. c.tier.key) end
    end)
end
for _, failure in ipairs(failures) do print("FAIL " .. failure) end
assert(#failures == 0, "hostile helpful priority: " .. #failures .. " failed checks / "
    .. checks .. " checks in " .. cases .. " cases")
print("PASS hostile helpful priority: " .. checks .. " checks in " .. cases .. " cases")


