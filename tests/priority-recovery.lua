-- Run from the addon source root: lua tests/priority-recovery.lua
-- Portable Lua 5.1/5.4 behavioral regression against real R.UpdateHost.
-- WoW API/frame doubles expose enablement and presentation; they do not model
-- the native engine or establish live-game behavior. No debug/upvalue access.
-- Breaks caught: missing control presentation, promoted nearby debuffs,
-- and first-match waiting selection.
local BP, SECRET = {}, {}
local helpful, harmful, scanErrorAt, harmfulErrorAt = {}, {}, nil, nil
local friendly, controlled, exists, combat = false, false, true, false
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
InCombatLockdown = function() return combat end
C_Spell = { GetSpellTexture = function() return 999 end }
local function readAura(_, index, filter)
    if filter:find("HARMFUL", 1, true) then
        if harmfulErrorAt == index then error("modeled harmful read failure") end
        return harmful[index]
    end
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
local function host(unit)
    unit = unit or "target"
    local h = { unit = unit, unitFrame = { unit = unit }, smallBaseLevel = 40,
        _buildComplete = true, containers = {}, cooldowns = {} }
    for _, key in ipairs({ "Hostile", "Baseline", "Healing", "WelcomingCampfire",
        "NearbyHarmful", "TrackingHarmful", "Roots", "Control", "Stun", "InterruptSilence", "Wounds", "StatusEffects",
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
    for index, c in ipairs(h.containers) do if R.TIERS[index].key == key then return c end end
    error("missing native container " .. key)
end
local function run(name, body)
    current, cases = name, cases + 1
    helpful, harmful, scanErrorAt, harmfulErrorAt = {}, {}, nil, nil
    friendly, controlled, exists, combat = false, false, true, false
    C_UnitAuras.GetAuraDataByIndex = readAura
    R.db.enabled, R.testMode = true, false
    for _, unit in ipairs(R.TRACKED_UNITS) do R.db[unit] = true end
    local ok, err = pcall(body)
    if not ok then failures[#failures + 1] = name .. ": unexpected error: " .. tostring(err) end
end
-- Missing registration or update of either helper leaves Arcane Power at 280
-- above the broad 175 harmful fallback on friendly and self portraits.
for _, unit in ipairs({ "player", "target", "focus", "targettarget", "focustarget" }) do
    for _, f in ipairs({ { "Roots", 339, 341 }, { "Control", 118, 351 } }) do
        local key, id, level = f[1], f[2], f[3]
        run(unit .. " " .. key .. " outranks offensive cooldown", function()
            friendly = true
            helpful, harmful = { aura(12042, 10) }, { aura(id, 20) }
            local h = host(unit); R.UpdateHost(h)
            local presentation = h["readable" .. key .. "Frame"]
            equal(presentation.shown, true, "classified harmful is visible")
            equal(presentation.level, level, "existing exact tier above Arcane Power")
            equal(presentation.texture, 12345, "actual aura icon")
            check(presentation.level > 320, "helper outranks base40 plus offense280")
            equal(native(h, key).enabled, false, "native harmful permission stays denied")
            equal(native(h, "Offensive").enabled, true, "helpful exact lane remains eligible")
            local owner = h._readableTierOwners[key]
            check(owner and owner.complete, "complete successful presentation owns tier")
            harmful = {}; R.UpdateHost(h)
            equal(presentation.shown, false, "removal hides helper")
            equal(presentation.cooldown.duration, nil, "removal clears cooldown")
            equal(h._readableTierOwners[key], nil, "removal relinquishes ownership")
        end)
    end
end
local harmfulHelpers = {
    { "Roots", 339, "Roots" }, { "Control", 118, "Control" },
    { "CampfireNearbyHarmful", 1299099, "NearbyHarmful" },
    { "TrackingHarmful", 2096, "TrackingHarmful" },
}
for _, f in ipairs(harmfulHelpers) do
    local key, id, frameKey = f[1], f[2], "readable" .. f[3] .. "Frame"
    for _, mode in ipairs({ "secret-object", "secret-identity", "read-error", "bounded",
        "missing-timing", "missing-ordering", "texture" }) do
        run(key .. " " .. mode .. " relinquishes readable authority", function()
            friendly = true; harmful = { aura(id, 20) }
            local h = host(); R.UpdateHost(h)
            equal(h[frameKey].shown, true, "initial presentation")
            if mode == "secret-object" then harmful[2] = SECRET
            elseif mode == "secret-identity" then harmful[2] = aura(SECRET, 30)
            elseif mode == "read-error" then harmfulErrorAt = 2
            elseif mode == "bounded" then for i = 2,80 do harmful[i] = aura(987654321, i) end
            elseif mode == "missing-timing" then harmful[1].duration = SECRET
            elseif mode == "missing-ordering" then harmful[2] = aura(id, SECRET)
            else h[frameKey].fail = "texture" end
            R.UpdateHost(h)
            equal(h[frameKey].shown, false, "failed helper is hidden")
            equal(h._readableTierOwners[key], nil, "failed helper owns no tier")
            equal(R.TIER_BY_KEY[key] and native(h, key).enabled, false,
                "native exact permission is not relaxed")
            -- Missing timing/ordering or a texture failure does not change
            -- identity: a known informational effect still cannot use175.
            local excludedOnly = (key == "CampfireNearbyHarmful" or key == "TrackingHarmful")
                and (mode == "missing-timing" or mode == "missing-ordering" or mode == "texture")
            equal(native(h, "SmallFriendlyHarmful").enabled, not excludedOnly,
                "generic fallback respects readable informational exclusions")
        end)
    end
    run(key .. " hostile rebind retains permitted native fallback", function()
        friendly = true; harmful = { aura(id, 20) }
        local h = host(); R.UpdateHost(h)
        friendly = false; R.UpdateHost(h, true)
        equal(h[frameKey].shown, false, "native-permitted rebind hides helper")
        equal(h._readableTierOwners[key], nil, "old ownership cleared")
        equal(R.TIER_BY_KEY[key] and native(h, key).enabled, true,
            "native harmful exact lane eligible")
    end)
end
-- The exclusion boundary and actual UpdateHost eligibility must both prevent
-- informational tracking/nearby auras from winning at175 over Cat Form150.
for _, f in ipairs({ { "Quitter", 1299099, "NearbyHarmful", "CampfireNearbyHarmful", 45 },
    { "Mind Vision rank1", 2096, "TrackingHarmful", "TrackingHarmful", 44 },
    { "Mind Vision rank2", 10909, "TrackingHarmful", "TrackingHarmful", 44 } }) do
run(f[1] .. " cannot be promoted above Cat Form", function()
    friendly = true; helpful, harmful = { aura(768, 10, 0) }, { aura(f[2], 20) }
    local h = host(); R.UpdateHost(h)
    equal(native(h, "SelfState").enabled, true, "Cat Form native eligible")
    local actual = h["readable" .. f[3] .. "Frame"]
    equal(actual.shown, true, "informational harmful is visible")
    equal(actual.level, f[5], "informational priority remains below Cat Form")
    equal(actual.texture, 12345, "observed harmful aura icon")
    local owner = h._readableTierOwners[f[4]]
    check(owner and owner.complete, "complete successful presentation owns tier")
    equal(R.TIER_BY_KEY[f[4]] and native(h, f[4]).enabled, false,
        "native harmful permission stays denied")
    equal(native(h, "SmallFriendlyHarmful").enabled, false,
        "informational aura alone cannot enter broad175 lane")
    local filters = R.CandidateFilters(R.TIER_BY_KEY.SmallFriendlyHarmful)
    equal(filters.excludeSpellIDs[f[2]], true, "native broad candidate excludes informational aura")
    equal(filters.excludeSpellIDs[987654321], nil, "unrelated harmful is admitted")
    harmful[2] = aura(987654321, 30); R.UpdateHost(h)
    equal(native(h, "SmallFriendlyHarmful").enabled, true, "unrelated harmful retains fallback")
    harmful = {}; R.UpdateHost(h)
    equal(actual.shown, false, "removal hides helper")
    equal(actual.cooldown.duration, nil, "removal clears cooldown")
    equal(h._readableTierOwners[f[4]], nil, "removal relinquishes ownership")
end)
end
for _, f in ipairs({ { "CampfireNearbyHarmful", 1299099, "NearbyHarmful" },
    { "TrackingHarmful", 2096, "TrackingHarmful" } }) do
    for _, inCombat in ipairs({ false, true }) do
        for _, mode in ipairs({ "disabled", "unit-disabled", "test-mode", "absent-unit" }) do
            run(f[1] .. " " .. mode .. (inCombat and " in combat" or " out of combat"), function()
                friendly = true; harmful = { aura(f[2], 20) }
                local h = host(); R.UpdateHost(h)
                local actual = h["readable" .. f[3] .. "Frame"]
                equal(actual.shown, true, "initial informational presentation")
                combat = inCombat
                if mode == "disabled" then R.db.enabled = false
                elseif mode == "unit-disabled" then R.db.target = false
                elseif mode == "test-mode" then R.testMode = true
                else exists = false end
                R.UpdateHost(h)
                equal(actual.shown, false, "inactive helper hidden")
                equal(actual.cooldown.duration, nil, "inactive cooldown cleared")
                equal(h._readableTierOwners[f[1]], nil, "inactive helper relinquishes ownership")
            end)
        end
    end
end
-- The independent hostile helper can fail presentation (e.g. SetTexture), so
-- Waiting must make its own complete election instead of choosing the first ID.
local function waitingHost()
    local h = host(); h.readableHostileFrame.fail = "texture"; return h
end
run("waiting chooses second instance20 over first10", function()
    helpful = { aura(2584, 10), aura(21989, 20) }
    helpful[1].icon, helpful[2].icon = 111, 222
    local h = waitingHost(); R.UpdateHost(h)
    equal(h._waitingToResurrectSpellID, 21989, "newest waiting spell")
    equal(h.readableWaitingToResurrectFrame.texture, 222, "winning aura icon")
    equal(h.readableWaitingToResurrectFrame.shown, true, "waiting presentation")
    check(h._readableTierOwners.WaitingToResurrect
        and h._readableTierOwners.WaitingToResurrect.complete, "complete ordered waiting owner")
    helpful = {}; R.UpdateHost(h)
    equal(h.readableWaitingToResurrectFrame.shown, false, "waiting removal hides presentation")
    equal(h.readableWaitingToResurrectFrame.cooldown.duration, nil, "waiting removal clears cooldown")
    equal(h._readableTierOwners.WaitingToResurrect, nil, "waiting removal clears authority")
end)
for _, mode in ipairs({ "secret-object", "secret-identity", "read-error", "bounded",
    "missing-ordering", "newest-unknown-timing", "texture" }) do
    run("waiting " .. mode .. " cannot guess older candidate", function()
        helpful = { aura(2584, 10), aura(21989, 20) }
        local h = waitingHost()
        if mode == "secret-object" then helpful[3] = SECRET
        elseif mode == "secret-identity" then helpful[3] = aura(SECRET, 30)
        elseif mode == "read-error" then scanErrorAt = 3
        elseif mode == "bounded" then for i = 3,80 do helpful[i] = aura(987654321, i) end
        elseif mode == "missing-ordering" then helpful[2].auraInstanceID = SECRET
        elseif mode == "newest-unknown-timing" then helpful[2].duration = SECRET
        else h.readableWaitingToResurrectFrame.fail = "texture" end
        R.UpdateHost(h)
        equal(h.readableWaitingToResurrectFrame.shown, false, "incomplete/unpresentable waiting hidden")
        equal(h._readableTierOwners.WaitingToResurrect, nil, "waiting has no authority")
        equal(native(h, "HostileHelpful").enabled, true, "generic native remains eligible")
    end)
end
run("waiting friendly rebind leaves permitted native selection authoritative", function()
    helpful = { aura(2584, 10), aura(21989, 20) }
    local h = waitingHost(); R.UpdateHost(h)
    friendly = true; R.UpdateHost(h, true)
    equal(h.readableWaitingToResurrectFrame.shown, false, "rebound waiting helper hidden")
    equal(h._readableTierOwners.WaitingToResurrect, nil, "rebind clears waiting owner")
    equal(native(h, "WaitingToResurrect").enabled, true, "native waiting eligible")
end)
-- Exercise construction and cleanup too: manually supplied UpdateHost frames
-- alone would miss a helper that was never created on a real portrait host.
-- Only native UI operations are doubled; the real resolver/constructor/election
-- and DestroyHost remain in use.
local function ui(parent)
    local f = frame()
    f.parent = parent
    local function noop() end
    for _, method in ipairs({ "SetAllPoints", "SetFrameStrata", "ClearAllPoints", "SetPoint",
        "SetTexCoord", "AddMaskTexture", "EnableMouse" }) do f[method] = noop end
    f.SetTexture = function(self, texture) self.texture = texture; return true end
    f.GetParent = function(self) return self.parent end
    f.SetParent = function(self, value) self.parent = value end
    f.GetFrameStrata = function() return "MEDIUM" end
    f.GetPoint = function(self) return "CENTER", self.parent, "CENTER", 0, 0 end
    f.GetNumPoints = function() return 1 end
    f.CreateTexture = function(self) return ui(self) end
    f.Clear = function(self) self.duration = nil end
    f.SetCooldown = function(self, startTime, duration) self.duration = duration end
    f.SetUnit = function(self, value) self.unit = value end
    f.SetEnabled = function(self, value) self.enabled = value end
    f.SetShown = function(self, value) self.shown = value end
    f.AddAuraSlot = function(self, _, filter, options) self.options = options end
    return f
end
unpack = unpack or table.unpack -- WoW Lua supplies this global.
CreateFrame = function(_, _, parent) return ui(parent) end
for _, unit in ipairs({ "player", "target", "focus", "targettarget", "focustarget" }) do
    run(unit .. " constructs and clears harmful helpers", function()
        local nativeParent, unitFrame = ui(), { unit = unit }
        local portrait = ui(nativeParent)
        if unit == "player" then PlayerFrame, PlayerPortrait = unitFrame, portrait
        elseif unit == "target" then TargetFrame, TargetFramePortrait = unitFrame, portrait
        elseif unit == "focus" then FocusFrame, FocusFramePortrait = unitFrame, portrait
        elseif unit == "targettarget" then TargetFrameToT = unitFrame; unitFrame.Portrait = portrait
        else FocusFrameToT = unitFrame; unitFrame.Portrait = portrait end
        friendly = true
        local h = R.CreateHost(unit)
        check(h ~= nil, "host constructor completes")
        if not h then return end
        for _, f in ipairs(harmfulHelpers) do
            harmful = { aura(f[2], 20) }; R.UpdateHost(h)
            local actual = h["readable" .. f[3] .. "Frame"]
            check(actual ~= nil, "constructor creates " .. f[1])
            if actual then equal(actual.shown, true, "constructed helper presents " .. f[1]) end
        end
        local roots, control = h.readableRootsFrame, h.readableControlFrame
        if not roots or not control then R.DestroyHost(unit); return end
        roots:Show(); roots.cooldown:SetCooldown(100, 20)
        for _, key in ipairs({ "NearbyHarmful", "TrackingHarmful" }) do
            local actual = h["readable" .. key .. "Frame"]
            if actual then actual:Show(); actual.cooldown:SetCooldown(100, 20) end
        end
        local waiting = h.readableWaitingToResurrectFrame
        if waiting then waiting:Show(); waiting.cooldown:SetCooldown(100, 20) end
        -- Cleanup must hide/clear even a stale presentation without ownership.
        h._readableTierOwners = {}
        equal(R.DestroyHost(unit), true, "host destruction succeeds")
        equal(roots.shown, false, "Roots cleanup hides helper")
        equal(control.shown, false, "Control cleanup hides helper")
        equal(roots.cooldown.duration, nil, "Roots cleanup clears cooldown")
        equal(control.cooldown.duration, nil, "Control cleanup clears cooldown")
        for _, key in ipairs({ "NearbyHarmful", "TrackingHarmful" }) do
            local actual = h["readable" .. key .. "Frame"]
            if actual then
                equal(actual.shown, false, key .. " cleanup hides helper")
                equal(actual.cooldown.duration, nil, key .. " cleanup clears cooldown")
            end
        end
        if waiting then
            equal(waiting.shown, false, "Waiting cleanup hides helper")
            equal(waiting.cooldown.duration, nil, "Waiting cleanup clears cooldown")
        end
    end)
end
for _, failure in ipairs(failures) do print("FAIL " .. failure) end
assert(#failures == 0, "priority recovery: " .. #failures .. " failed checks / "
    .. checks .. " checks in " .. cases .. " cases")
print("PASS priority recovery: " .. checks .. " checks in " .. cases .. " cases")
