local addonName, BP = ...
local R = assert(BP.Runtime, "Core.lua must load first")

local STRATA_BELOW = {
    BACKGROUND = "BACKGROUND", LOW = "BACKGROUND", MEDIUM = "LOW", HIGH = "MEDIUM",
    DIALOG = "HIGH", FULLSCREEN = "DIALOG", FULLSCREEN_DIALOG = "FULLSCREEN", TOOLTIP = "FULLSCREEN_DIALOG",
}

local AURA_SCAN_LIMIT = 80

local function applyIconMask(host, icon)
    R.ApplyPortraitIconCrop(icon, host)
    local mask = host.imageMask or host.portraitMask
    if mask and icon.AddMaskTexture then
        pcall(icon.AddMaskTexture, icon, mask)
    end
end

-- Wisdom text is calibrated separately from the icon's circles. The .120
-- finishing pass changes only Target/Focus and ToF label X offsets.
-- Keep the existing font sizes, native swipe rectangles and countdown values.
-- The small residual ink correction still needs checking across other digits.
local timerInkOffsets = {
    player = { 1, -0.25 },
    target = { 3, -0.75 },
    focus = { 3, -0.75 },
    targettarget = { 0.25, 1 },
    focustarget = { 0.25, 1 },
}
local function timerOpticalOffset(text, unit)
    local offset = timerInkOffsets[unit]
    if not offset then return 0, 0 end
    if not PixelUtil or type(PixelUtil.GetPixelToUIUnitFactor) ~= "function"
        or type(text.GetEffectiveScale) ~= "function" then return 0, 0 end
    local factorOK, factor = pcall(PixelUtil.GetPixelToUIUnitFactor)
    local scaleOK, scale = pcall(text.GetEffectiveScale, text)
    if not factorOK or not scaleOK or not R.CanAccess(factor) or not R.CanAccess(scale)
        or type(factor) ~= "number" or type(scale) ~= "number"
        or factor ~= factor or scale ~= scale or factor <= 0 or scale <= 0
        or factor == math.huge or scale == math.huge then return 0, 0 end
    return offset[1] * factor / scale, offset[2] * factor / scale
end

local function alignCountdown(cooldown, host)
    -- Operate only on the addon-created countdown, never read its text/time.
    -- Layout may be unavailable after secure initialization; retry at the next
    -- existing out-of-combat lifecycle boundary rather than attaching scripts
    -- to forbidden aura buttons or polling secret-valued geometry.
    local combat, readable = R.SafeBool(InCombatLockdown)
    if not readable or combat then
        cooldown._bjarkiAlignmentState = "deferred"
        return
    end
    local ok, text = false, nil
    if type(cooldown.GetCountdownFontString) == "function" then
        ok, text = pcall(cooldown.GetCountdownFontString, cooldown)
    end
    if not ok or not R.CanAccess(text) or not text then
        cooldown._bjarkiAlignmentState = "label-unavailable"
        return
    end

    if R.SMALL_UNITS[host.unit] and text.GetFont and text.SetFont then
        local fontOK, file, size, flags = pcall(text.GetFont, text)
        if fontOK and R.CanAccess(file) and R.CanAccess(size) and R.CanAccess(flags)
            and type(file) == "string" and type(size) == "number"
            and size == size and size > 2 and size < 100 then
            local saved = cooldown._bjarkiCompactFont
            if not saved or saved.text ~= text then
                saved = {text=text, file=file, size=size, wanted=math.max(1, size-2), flags=flags or ""}
                cooldown._bjarkiCompactFont = saved
            end
            if saved.file == file and (size == saved.size or size == saved.wanted) then
                pcall(text.SetFont, text, saved.file, saved.wanted, saved.flags)
            end
        end
    end

    -- Keep the cooldown/swipe on its prior native reference. Only the label
    -- gets this ink-centering correction; the image's separate clipping mask
    -- never changes countdown values, formatting or swipe geometry.
    local dx, dy = timerOpticalOffset(text, host.unit)
    local centered = pcall(function()
        cooldown:ClearAllPoints()
        cooldown:SetAllPoints(host.portraitMask or host.portrait)
        text:ClearAllPoints()
        if dx == 0 and dy == 0 then
            text:SetAllPoints(cooldown)
        else
            text:SetPoint("TOPLEFT", cooldown, "TOPLEFT", dx, dy)
            text:SetPoint("BOTTOMRIGHT", cooldown, "BOTTOMRIGHT", dx, dy)
        end
        text:SetJustifyH("CENTER")
        text:SetJustifyV("MIDDLE")
    end)
    cooldown._bjarkiAlignmentState = centered and "centered" or "layout-unavailable"
end

local function configureCooldown(cooldown, host)
    if cooldown.SetMinimumCountdownDuration then cooldown:SetMinimumCountdownDuration(0) end
    cooldown:SetAllPoints()
    if cooldown.SetUsingParentLevel then cooldown:SetUsingParentLevel(true) end
    if cooldown.SetReverse then cooldown:SetReverse(true) end
    if cooldown.SetDrawBling then cooldown:SetDrawBling(false) end
    if cooldown.SetDrawEdge then cooldown:SetDrawEdge(false) end
    if cooldown.SetDrawSwipe then cooldown:SetDrawSwipe(R.db and R.db.showSwipe or false) end
    R.ApplyCountdownFormat(cooldown)
    if cooldown.SetSwipeTexture then cooldown:SetSwipeTexture(R.SWIPE_TEXTURE) end
    alignCountdown(cooldown, host)
end

local function initializeButton(host, button, tier)
    button:SetAllPoints(host.anchor)
    if button.SetFrameLevel then button:SetFrameLevel((host.smallBaseLevel or 0) + (tier.level or 1) + 1) end

    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetAllPoints(button)
    icon:SetTexCoord(0, 1, 0, 1)
    applyIconMask(host, icon)
    button:SetIcon(icon)

    local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate," .. R.AURA_ANCHOR_TEMPLATE)
    configureCooldown(cooldown, host)
    button:SetDurationCooldown(cooldown)
    alignCountdown(cooldown, host)
    button:EnableMouse(false)
    host.cooldowns[#host.cooldowns + 1] = cooldown
end

local function firstPoint(region)
    if not region or not region.GetPoint then return nil end
    return region:GetPoint(1)
end

local function placeAtPortrait(frame, host)
    frame:SetAllPoints(host.anchor or host.portrait)
end

local function findHelpfulTierForSpell(spellID)
    if type(spellID) ~= "number" then return nil end
    local indexed = R.HELPFUL_TIER_BY_SPELL and R.HELPFUL_TIER_BY_SPELL[spellID]
    if indexed then return indexed end

    -- Defensive fallback if load order is ever changed outside the shipped TOC.
    local best
    for _, tier in ipairs(R.TIERS or {}) do
        if tier.exact and tier.helpful and tier.spellIDs and tier.spellIDs[spellID] then
            if not best or (tier.level or 0) > (best.level or 0) then best = tier end
        end
    end
    return best
end

local BOOSTED_REST_SPELL_ID = 1229451
local GHOST_SPELL_ID = 8326
local WELCOMING_CAMPFIRE_SPELL_IDS = {
    [1229739] = true,
    [1289723] = true,
}
local WELCOMING_CAMPFIRE_DIRECT_IDS = { 1289723, 1229739 }

local function isWelcomingCampfireSpellID(spellID)
    return WELCOMING_CAMPFIRE_SPELL_IDS[spellID] == true
end

local function findTierByKey(key)
    local indexed = R.TIER_BY_KEY and R.TIER_BY_KEY[key]
    if indexed then return indexed end

    -- Defensive fallback if load order is ever changed outside the shipped TOC.
    for _, tier in ipairs(R.TIERS or {}) do
        if tier.key == key then return tier end
    end
end

-- BaselineClass, Healing and StatusEffects use application-time recency: a refreshed aura
-- should win within its tier even when Forever preserves its instance ID.
-- auraInstanceID is an identity/deterministic sort key, not application time.
--
-- Prefer Blizzard's DurationObject start time when it is readable. Fall back to
-- the legacy expiration-duration witness only when needed.
local function readAuraStartTime(unit, aura, auraInstanceID)
    if C_UnitAuras and C_UnitAuras.GetAuraDuration and auraInstanceID then
        local ok, durationObject = pcall(C_UnitAuras.GetAuraDuration, unit, auraInstanceID)
        if ok and R.CanAccess(durationObject) and durationObject ~= nil
            and durationObject.GetStartTime
        then
            local startOK, startTime = pcall(durationObject.GetStartTime, durationObject)
            if startOK and R.CanAccess(startTime) and type(startTime) == "number" then
                return startTime, true, "durationObject"
            end
        end
    end

    local duration, durationReadable = R.ReadAuraField(aura, "duration")
    local expirationTime, expirationReadable = R.ReadAuraField(aura, "expirationTime")
    if durationReadable and expirationReadable
        and type(duration) == "number" and type(expirationTime) == "number"
        and duration > 0
    then
        return expirationTime - duration, true, "fields"
    end

    return nil, false, nil
end

local function usesApplicationTime(tier)
    return tier and (tier.key == "BaselineClass" or tier.key == "Healing"
        or tier.key == "StatusEffects")
end

local function readableCandidate(unit, aura, spellID, tier)
    local auraInstanceID, instanceReadable = R.ReadAuraField(aura, "auraInstanceID")
    if not instanceReadable or type(auraInstanceID) ~= "number" then auraInstanceID = nil end
    local candidate = { aura = aura, spellID = spellID, auraInstanceID = auraInstanceID, tier = tier }
    if usesApplicationTime(tier) then
        candidate.appliedAt, candidate.timingReadable, candidate.timingSource =
            readAuraStartTime(unit, aura, auraInstanceID)
    end
    return candidate
end

local function electReadableCandidate(candidates, byApplicationTime)
    if #candidates == 0 then return nil, true end
    -- A single candidate needs identity evidence, but no ordering evidence.
    if #candidates == 1 then return candidates[1], true end

    if byApplicationTime then
        local latest
        for _, candidate in ipairs(candidates) do
            if not candidate.timingReadable then return nil, false end
            if latest == nil or candidate.appliedAt > latest then latest = candidate.appliedAt end
        end
        -- Only ties at the latest start need native instance ordering. An
        -- unreadable ID in an older tie cannot veto a strictly newer aura.
        local newest = {}
        for _, candidate in ipairs(candidates) do
            if candidate.appliedAt == latest then newest[#newest + 1] = candidate end
        end
        candidates = newest
        if #candidates == 1 then return candidates[1], true end
    end

    local best
    local unique = true
    for _, candidate in ipairs(candidates) do
        if type(candidate.auraInstanceID) ~= "number" then return nil, false end
        if not best or candidate.auraInstanceID > best.auraInstanceID then
            best, unique = candidate, true
        elseif candidate.auraInstanceID == best.auraInstanceID then
            unique = false
        end
    end
    if byApplicationTime and not unique then return nil, false end
    return best, true
end

local function scanReadableExactAura(unit, filter, spellID)
    if not C_UnitAuras or not C_UnitAuras.GetAuraDataByIndex then return nil, false end

    for index = 1, AURA_SCAN_LIMIT do
        local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, index, filter)
        if not ok or not R.CanAccess(aura) then return nil, false end
        if aura == nil then return nil, true end

        local auraSpellID, readable = R.ReadAuraField(aura, "spellId")
        if not readable or type(auraSpellID) ~= "number" then return nil, false end
        if auraSpellID == spellID then return aura, true end
    end

    -- No nil terminator was observed within the bounded scan, so absence is
    -- unproven even though the requested spell was not found.
    return nil, false
end

local function scanReadableExactAuraSet(unit, filter, spellIDs)
    if not C_UnitAuras or not C_UnitAuras.GetAuraDataByIndex or type(spellIDs) ~= "table" then
        return nil, nil, false
    end

    for index = 1, AURA_SCAN_LIMIT do
        local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, index, filter)
        if not ok or not R.CanAccess(aura) then return nil, nil, false end
        if aura == nil then return nil, nil, true end

        local spellID, readable = R.ReadAuraField(aura, "spellId")
        if not readable or type(spellID) ~= "number" then return nil, nil, false end
        if spellIDs[spellID] then return aura, spellID, true end
    end

    -- The bounded scan did not reach a nil terminator, so absence is unproven.
    return nil, nil, false
end

-- A positive exact result is a witness, not proof that every other aura is
-- absent. Direct getters can omit inaccessible auras. Never use their nil
-- results to suppress a secure tier or infer the state of another unit.
local function getDirectExactAura(unit, spellID)
    if not C_UnitAuras then return nil end
    local ok, aura
    if type(C_UnitAuras.GetUnitAuraBySpellID) == "function" then
        ok, aura = pcall(C_UnitAuras.GetUnitAuraBySpellID, unit, spellID)
    end
    if (not ok or not R.CanAccess(aura) or aura == nil)
        and unit == "player" and type(C_UnitAuras.GetPlayerAuraBySpellID) == "function" then
        ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, spellID)
    end
    if not ok or not R.CanAccess(aura) or aura == nil then return nil end
    local id, readable = R.ReadAuraField(aura, "spellId")
    if readable and type(id) == "number" and id == spellID then return aura end
end

local function directTierWitness(unit, tier, spellIDs)
    local candidates = {}
    for id in pairs(spellIDs or {}) do
        local aura = getDirectExactAura(unit, id)
        if aura then candidates[#candidates + 1] = readableCandidate(unit, aura, id, tier) end
    end
    return electReadableCandidate(candidates, usesApplicationTime(tier))
end

local function getReadablePlayerAuraBySpellID(spellID)
    if not C_UnitAuras or not C_UnitAuras.GetPlayerAuraBySpellID then
        return nil, false, false
    end

    local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, spellID)
    if not ok then return nil, false, true end
    if not R.CanAccess(aura) then return nil, false, true end
    if aura == nil then return nil, true, true end

    local auraSpellID, readable = R.ReadAuraField(aura, "spellId")
    if not readable or type(auraSpellID) ~= "number" then
        return nil, false, true
    end
    if auraSpellID ~= spellID then
        return nil, false, true
    end

    return aura, true, true
end

local function scanReadableUtilityWinner(unit)
    local tier = findTierByKey("Utility")
    local meta = {
        welcomingDirect = false,
        welcomingDirectFound = false,
        welcomingPresent = false,
        welcomingReadable = false,
        welcomingAppliedAt = nil,
        welcomingTimingSource = nil,
    }
    if not tier or not tier.spellIDs then return nil, false, meta end
    if not C_UnitAuras or not C_UnitAuras.GetAuraDataByIndex then
        return nil, false, meta
    end

    local candidates = {}
    local seenInstances = {}
    local complete = false

    local function addCandidate(aura, spellID, direct)
        local auraInstanceID, instanceReadable = R.ReadAuraField(aura, "auraInstanceID")
        if not instanceReadable or type(auraInstanceID) ~= "number" then
            return false
        end

        if not seenInstances[auraInstanceID] then
            candidates[#candidates + 1] = {
                aura = aura,
                spellID = spellID,
                auraInstanceID = auraInstanceID,
                tier = tier,
            }
            seenInstances[auraInstanceID] = true
        end

        if isWelcomingCampfireSpellID(spellID) then
            local expirationTime, expirationReadable = R.ReadAuraField(aura, "expirationTime")
            local appliedAt, timingReadable, timingSource
            if expirationReadable and type(expirationTime) == "number" and expirationTime > 0 then
                appliedAt = expirationTime - 60
                timingReadable = true
                timingSource = "welcomingExpiration60"
            else
                appliedAt, timingReadable, timingSource = readAuraStartTime(
                    unit, aura, auraInstanceID
                )
            end

            meta.welcomingPresent = true
            meta.welcomingAppliedAt = timingReadable and appliedAt or nil
            meta.welcomingTimingSource = timingReadable and timingSource or nil
            if direct then meta.welcomingDirectFound = true end
        end

        return true
    end

    -- First enumerate the full readable Utility candidate set. The secure lane
    -- uses AuraInstanceIDOnly/Reverse, so readable arbitration must use the same
    -- ordering before it is allowed to suppress that secure owner.
    for index = 1, AURA_SCAN_LIMIT do
        local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex,
            unit, index, "HELPFUL|INCLUDE_NAME_PLATE_ONLY")
        if not ok or not R.CanAccess(aura) then return nil, false, meta end
        if aura == nil then
            complete = true
            break
        end

        local spellID, readable = R.ReadAuraField(aura, "spellId")
        if not readable or type(spellID) ~= "number" then
            return nil, false, meta
        end

        if tier.spellIDs[spellID] and not addCandidate(aura, spellID, false) then
            return nil, false, meta
        end
    end

    if not complete then return nil, false, meta end

    -- Forever has exposed Welcoming Campfire through a direct player lookup on
    -- builds where the indexed stream was inconsistent. A positive direct
    -- witness joins the SAME Utility election instead of short-circuiting it.
    if unit == "player" then
        for _, spellID in ipairs(WELCOMING_CAMPFIRE_DIRECT_IDS) do
            local aura, readable, directAvailable = getReadablePlayerAuraBySpellID(spellID)
            meta.welcomingDirect = meta.welcomingDirect or directAvailable
            meta.welcomingReadable = meta.welcomingReadable or readable
            if aura and not addCandidate(aura, spellID, true) then
                return nil, false, meta
            end
        end
    end

    meta.welcomingReadable = meta.welcomingReadable or complete
    if #candidates == 0 then return nil, true, meta end

    local best = candidates[1]
    for i = 2, #candidates do
        if candidates[i].auraInstanceID > best.auraInstanceID then
            best = candidates[i]
        end
    end

    return best, true, meta
end

local function scanLatestReadableExactTierAura(unit, tierKey, filter)
    local tier = findTierByKey(tierKey)
    if not tier or not tier.spellIDs then return nil, false, false end
    if not C_UnitAuras or not C_UnitAuras.GetAuraDataByIndex then return nil, false, false end

    local candidates = {}
    local complete = false
    for index = 1, AURA_SCAN_LIMIT do
        local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, index, filter)
        if not ok or not R.CanAccess(aura) then return nil, false, false end
        if aura == nil then
            complete = true
            break
        end

        local spellID, readable = R.ReadAuraField(aura, "spellId")
        if not readable or type(spellID) ~= "number" then return nil, false, false end

        if tier.spellIDs[spellID] then
            candidates[#candidates + 1] = readableCandidate(unit, aura, spellID, tier)
        end
    end

    if not complete then return nil, false, false end
    local best, electionReadable = electReadableCandidate(candidates, usesApplicationTime(tier))
    return best, true, electionReadable
end

local function scanReadableHostileHelpful(unit)
    if not C_UnitAuras or not C_UnitAuras.GetAuraDataByIndex then
        return nil, false, 0, false, false
    end

    local candidates = {}
    local count = 0
    local allIdentitiesReadable = true
    local complete = false

    for index = 1, AURA_SCAN_LIMIT do
        -- Include ordinary helpful auras plus otherwise omitted nameplate-only
        -- auras. Drink and other ordinary recovery effects remain in this list.
        local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex,
            unit, index, "HELPFUL|INCLUDE_NAME_PLATE_ONLY")
        if not ok then
            allIdentitiesReadable = false
            break
        end

        -- Never compare/index an inaccessible aura object. Skip that slot and
        -- keep looking for readable category witnesses; unreadability still
        -- prevents this pass from suppressing the secure fallback lane.
        if not R.CanAccess(aura) then
            allIdentitiesReadable = false
        else
            if aura == nil then
                complete = true
                break
            end
            count = count + 1

            local spellID, idReadable = R.ReadAuraField(aura, "spellId")
            if not idReadable or type(spellID) ~= "number" then
                allIdentitiesReadable = false
            else
                local tier = findHelpfulTierForSpell(spellID)
                if tier then
                    candidates[#candidates + 1] = readableCandidate(unit, aura, spellID, tier)
                end
            end
        end
    end

    local best
    local electionReadable = true
    if #candidates > 0 then
        local topLevel = candidates[1].tier.level or 0
        for i = 2, #candidates do
            topLevel = math.max(topLevel, candidates[i].tier.level or 0)
        end

        local top = {}
        for _, candidate in ipairs(candidates) do
            if (candidate.tier.level or 0) == topLevel then
                top[#top + 1] = candidate
            end
        end

        best, electionReadable = electReadableCandidate(top, usesApplicationTime(top[1].tier))
    end

    -- A complete Lua-visible stream still does not prove the secure plane empty.
    -- It can, however, authorize this readable projection when at least one aura
    -- was exposed, every identity was readable, and any same-tier winner is
    -- actually ordered by readable evidence.
    -- This reader may only replace secure fallback lanes when it found a
    -- tracked aura, the full readable helpful list terminated, every aura ID
    -- was readable, and the highest category winner was elected safely.
    local authoritative = best ~= nil and allIdentitiesReadable and complete
        and count > 0 and electionReadable
    return best, authoritative, count, complete, electionReadable
end

local function createReadableExactFrame(host, level)
    host._buildStage = "readable-helper:" .. tostring(level)
    -- These sibling frames anchor to host.anchor, which has forbidden layout
    -- scripts. Opt in at creation; SetAllPoints cannot inherit that aspect.
    local frame = CreateFrame("Frame", nil, host.layer, R.AURA_ANCHOR_TEMPLATE)
    placeAtPortrait(frame, host)
    frame:SetFrameStrata(host.strata)
    frame:SetFrameLevel((host.smallBaseLevel or 0) + (level or 1) + 1)

    local icon = frame:CreateTexture(nil, "BACKGROUND")
    icon:SetAllPoints(frame)
    icon:SetTexCoord(0, 1, 0, 1)
    applyIconMask(host, icon)
    frame.icon = icon

    local cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate," .. R.AURA_ANCHOR_TEMPLATE)
    configureCooldown(cooldown, host)
    frame.cooldown = cooldown
    host.cooldowns[#host.cooldowns + 1] = cooldown
    frame:Hide()
    return frame
end

local function clearReadableCooldown(cooldown)
    if not cooldown then return false end
    if cooldown.Clear then
        if pcall(cooldown.Clear, cooldown) then return true end
        -- A failed clear revokes the replacement. Still try the supported reset
        -- so the previously displayed countdown does not remain behind it.
        if cooldown.SetCooldown then pcall(cooldown.SetCooldown, cooldown, 0, 0) end
        return false
    elseif cooldown.SetCooldown then
        return pcall(cooldown.SetCooldown, cooldown, 0, 0)
    end
    return false
end

local function setReadableAuraCooldown(cooldown, unit, aura)
    if not cooldown then return false end

    -- Transport the current winner's native duration without reading its
    -- timing components or retaining it across aura/unit assignments.
    if C_UnitAuras and C_UnitAuras.GetAuraDuration and cooldown.SetCooldownFromDurationObject then
        local auraInstanceID, instanceReadable = R.ReadAuraField(aura, "auraInstanceID")
        if instanceReadable and type(auraInstanceID) == "number" then
            local ok, durationObject = pcall(C_UnitAuras.GetAuraDuration, unit, auraInstanceID)
            if ok and R.CanAccess(durationObject) and durationObject ~= nil
                -- Each presentation assigns the current winner. A zero object
                -- must clear a previous timed aura, including same-ID refreshes.
                and pcall(cooldown.SetCooldownFromDurationObject, cooldown, durationObject, true)
            then
                return true
            end
        end
    end

    local duration, durationReadable = R.ReadAuraField(aura, "duration")
    if not durationReadable or type(duration) ~= "number" then return false end
    if duration == 0 then return clearReadableCooldown(cooldown) end

    local expirationTime, expirationReadable = R.ReadAuraField(aura, "expirationTime")
    local timeMod, timeModReadable = R.ReadAuraField(aura, "timeMod")
    if duration > 0 and expirationReadable and type(expirationTime) == "number" and timeModReadable then
        -- Missing timeMod uses the native default. A supplied unreadable or
        -- invalid modifier cannot authorize an inaccurate owned countdown.
        if timeMod == nil then timeMod = 1 end
        if type(timeMod) == "number" and timeMod > 0 and timeMod < math.huge then
            return cooldown.SetCooldown and pcall(
                cooldown.SetCooldown, cooldown, expirationTime - duration, duration, timeMod
            ) or false
        end
    end
    -- Unknown timing is not a permanent-aura witness. Relinquish presentation
    -- so a successful clear alone cannot suppress the native tier.
    return false
end

local function hideReadableExact(frame)
    if not frame then return end
    clearReadableCooldown(frame.cooldown)
    if frame.icon and frame.icon.SetTexture then
        pcall(frame.icon.SetTexture, frame.icon, nil)
    end
    if frame.Hide then pcall(frame.Hide, frame) end
end

local function setReadableSpellIcon(frame, spellID, aura)
    if not frame or not frame.icon or not frame.icon.SetTexture then
        hideReadableExact(frame)
        return false
    end

    local texture
    if aura then
        local value, readable = R.ReadAuraField(aura, "icon")
        if readable and ((type(value) == "number" and value > 0 and value < math.huge)
            or (type(value) == "string" and value ~= "")) then texture = value end
    end
    if texture == nil and C_Spell and C_Spell.GetSpellTexture then
        local ok, value = pcall(C_Spell.GetSpellTexture, spellID)
        if ok and R.CanAccess(value) then texture = value end
    elseif texture == nil and GetSpellTexture then
        local ok, value = pcall(GetSpellTexture, spellID)
        if ok and R.CanAccess(value) then texture = value end
    end
    local usable = (type(texture) == "number" and texture > 0)
        or (type(texture) == "string" and texture ~= "")
    if not usable then
        hideReadableExact(frame)
        return false
    end
    -- SetTexture reports a boolean success independently of pcall succeeding.
    local ok, success = pcall(frame.icon.SetTexture, frame.icon, texture)
    if not ok or not R.CanAccess(success) or success ~= true then
        hideReadableExact(frame)
        return false
    end
    return true
end

local function showReadableAura(frame, aura, spellID, unit)
    if not R.CanAccess(aura) or aura == nil then
        hideReadableExact(frame)
        return false
    end
    if not setReadableSpellIcon(frame, spellID, aura) then return false end

    if not setReadableAuraCooldown(frame.cooldown, unit, aura) then
        hideReadableExact(frame)
        return false
    end

    if not frame.Show or not pcall(frame.Show, frame) then
        hideReadableExact(frame)
        return false
    end
    return true
end

local function showStaticSpell(frame, spellID, aura)
    if not setReadableSpellIcon(frame, spellID, aura) then return false end
    if not clearReadableCooldown(frame.cooldown) then
        hideReadableExact(frame)
        return false
    end

    if not frame.Show or not pcall(frame.Show, frame) then
        hideReadableExact(frame)
        return false
    end
    return true
end

local function showReadableTier(host, frameKey, candidate, complete)
    local frame = host[frameKey]
    if not frame or not frame.SetFrameLevel or not pcall(
        frame.SetFrameLevel, frame,
        (host.smallBaseLevel or 0) + (candidate.tier.level or 1) + 1
    ) then
        hideReadableExact(frame)
        return false
    end
    if not showReadableAura(frame, candidate.aura, candidate.spellID, host.unit) then return false end
    host._readableTierOwners[candidate.tier.key] = {
        frame = frame, frameKey = frameKey, cooldown = frame.cooldown,
        complete = complete and true or false,
    }
    return true
end

-- A positive, independent form-state witness for hostile *players* only.
-- Opposite-faction HELPFUL identities can become inaccessible during CC,
-- but unit class and active primary power may remain readable. These are
-- public unit facts, not proof of a particular aura instance. Do not infer
-- any form when the class, power or alive state is unknown; do not reopen the
-- permanent-buff fallback (which would also admit Find Minerals).
local function updateObservedDruidForm(host, baseEnabled, hostilePlayer, hostileReadable)
    host._formStateActive = false
    host._formStateSpellID = nil
    host._formStateReason = "ineligible"
    local frame = host and host.readableFormStateFrame
    if not frame then return end
    if not baseEnabled or R.testMode or not hostilePlayer or hostileReadable then
        hideReadableExact(frame)
        return
    end
    local dead, deadReadable = R.SafeBool(UnitIsDeadOrGhost, host.unit)
    if not deadReadable or dead then
        host._formStateReason = deadReadable and "dead" or "dead-unknown"
        hideReadableExact(frame)
        return
    end
    if type(UnitClass) ~= "function" then
        host._formStateReason = "class-unavailable"
        hideReadableExact(frame)
        return
    end
    local classOK, _localized, classFile = pcall(UnitClass, host.unit)
    if not classOK or not R.CanAccess(classFile) or type(classFile) ~= "string" then
        host._formStateReason = "class-unreadable"
        hideReadableExact(frame)
        return
    end
    if classFile ~= "DRUID" then
        host._formStateReason = "not-druid"
        hideReadableExact(frame)
        return
    end
    if type(UnitPowerType) ~= "function" then
        host._formStateReason = "power-unavailable"
        hideReadableExact(frame)
        return
    end
    local powerOK, _powerID, token = pcall(UnitPowerType, host.unit)
    if not powerOK or not R.CanAccess(token) or type(token) ~= "string" then
        host._formStateReason = "power-unreadable"
        hideReadableExact(frame)
        return
    end
    -- Energy uniquely identifies a cat-form Druid's active resource; Rage
    -- identifies the bear family (Bear/Dire Bear share an icon). Mana does
    -- NOT identify Moonkin, Travel Form, or an ordinary caster and cannot
    -- authorize a synthetic aura. The icon has no fabricated countdown.
    local spellID = token == "ENERGY" and 768 or token == "RAGE" and 5487 or nil
    if not spellID then
        host._formStateReason = "no-form-witness"
        hideReadableExact(frame)
        return
    end
    host._formStateSpellID = spellID
    host._formStateActive = showStaticSpell(frame, spellID)
    host._formStateReason = host._formStateActive and "unit-power" or "presentation-failed"
end

local function updateGhostState(host, baseEnabled)
    host._ghostReadable = false
    host._ghostActive = false
    host._ghostSource = "none"

    local frame = host and host.readableGhostFrame
    if not frame then return end
    if not baseEnabled then
        hideReadableExact(frame)
        return
    end

    -- Ghost is a directly observable unit state. Prefer that state witness over
    -- harmful aura identity, which Forever may relation-gate on self/friendly
    -- units. UNKNOWN remains UNKNOWN; do not infer Ghost from "dead".
    local isGhost, readable = R.SafeBool(UnitIsGhost, host.unit)
    host._ghostReadable = readable
    -- A readable negative state wins; death alone is not a Ghost witness.
    if readable and not isGhost then hideReadableExact(frame); return end

    local aura
    for _, id in ipairs({8326, 9036, 1278162}) do
        aura = getDirectExactAura(host.unit, id)
        if aura then break end
    end
    if not aura then
        aura = scanReadableExactAuraSet(host.unit, "HARMFUL|INCLUDE_NAME_PLATE_ONLY",
            BP.categories and BP.categories.immunities_harmful)
    end
    if (readable and isGhost) or aura then
        host._ghostSource = readable and "unit-state" or "aura"
        host._ghostActive = showStaticSpell(frame, GHOST_SPELL_ID, aura)
    else
        hideReadableExact(frame)
    end
end

local function clearReadableHarmfulTier(host, frameKey, prefix)
    local frame = host and host[frameKey]
    if frame then hideReadableExact(frame) end
    if host then
        host[prefix .. "DirectWitness"] = false
        host[prefix .. "Readable"] = false
        host[prefix .. "ElectionReadable"] = false
        host[prefix .. "SpellID"] = nil
        host[prefix .. "Active"] = false
    end
end

local function updateReadableHarmfulTier(host, baseEnabled, tierKey, frameKey, prefix)
    if not host or not baseEnabled or R.testMode or not host[frameKey] then
        clearReadableHarmfulTier(host, frameKey, prefix)
        return
    end

    local tier = findTierByKey(tierKey)
    if not tier then
        clearReadableHarmfulTier(host, frameKey, prefix)
        return
    end

    -- Only a complete, ordered election can replace native selection. A tier's
    -- explicit small direct-witness subset can preserve a known positive effect
    -- on an incomplete read, below the native slot and without disabling it.
    if not tier.directWitnessSpellIDs and not usesApplicationTime(tier)
        and R.ExactFilterAllowed(host.unit, false, tier.spellIDs, tier.allowNeverSecret) then
        clearReadableHarmfulTier(host, frameKey, prefix)
        return
    end

    local best, complete, electionReadable = scanLatestReadableExactTierAura(
        host.unit, tierKey, tier.filter
    )
    local direct = false
    if tier.directWitnessSpellIDs and (not complete or not electionReadable or not best) then
        best, electionReadable = directTierWitness(host.unit, tier, tier.directWitnessSpellIDs)
        direct = best ~= nil and electionReadable == true
        -- Positive member lookup is not an exhaustive aura election.
        complete = false
    end
    host[prefix .. "DirectWitness"] = direct
    host[prefix .. "Readable"] = complete
    host[prefix .. "ElectionReadable"] = electionReadable
    host[prefix .. "SpellID"] = best and best.spellID or nil

    if (not complete and not direct) or not electionReadable or not best then
        hideReadableExact(host[frameKey])
        host[prefix .. "Active"] = false
        return
    end

    host[prefix .. "Active"] = showReadableTier(host, frameKey, best, not direct)
    if direct and host[prefix .. "Active"] then
        -- The known effect may beat lower bands, but a native winner in this
        -- band must remain above it. Do not turn a partial lookup into authority.
        local lowered = pcall(host[frameKey].SetFrameLevel, host[frameKey],
            (host.smallBaseLevel or 0) + (tier.level or 1))
        if not lowered then
            hideReadableExact(host[frameKey])
            host[prefix .. "Active"] = false
            host._readableTierOwners[tierKey] = nil
        end
    end
end

local function clearReadableHostile(host)
    if not host then return end
    local frame = host and host.readableHostileFrame
    hideReadableExact(frame)
    host._hostileReadable = false
    host._hostileActive = false
    host._hostileElectionReadable = false
    host._hostileAuraListComplete = false
    host._hostileCount = 0
    host._hostileSpellID = nil
    host._hostileTierKey = nil
end

local function updateReadableHostile(host, baseEnabled)
    if not host or not baseEnabled or R.testMode then
        clearReadableHostile(host)
        return false
    end

    local best, authoritative, count, auraListComplete, electionReadable =
        scanReadableHostileHelpful(host.unit)
    host._hostileReadable = authoritative
    host._hostileElectionReadable = electionReadable
    host._hostileAuraListComplete = auraListComplete
    host._hostileCount = count
    host._hostileSpellID = best and best.spellID or nil
    host._hostileTierKey = best and best.tier and best.tier.key or nil
    host._hostileActive = false

    local frame = host.readableHostileFrame
    if not frame or not best then
        hideReadableExact(frame)
        return false
    end
    -- A partial readable witness is useful only when it cannot compete with an
    -- eligible native owner of the same tier. It never suppresses that owner.
    if not authoritative and R.NativeExactContainerAllowed(host.unit, best.tier) then
        hideReadableExact(frame)
        return false
    end

    host._hostileActive = showReadableTier(host, "readableHostileFrame", best, authoritative)
    return authoritative and host._hostileActive
end

local function updateReadableDivineProtection(host, baseEnabled, hostileUnit, secureAllowed)
    local tier = findTierByKey("DivineProtection")
    host._divineProtectionSecureAllowed = secureAllowed and true or false
    host._divineProtectionReadable = false
    host._divineProtectionActive = false
    host._divineProtectionSpellID = nil

    local frame = host.readableDivineProtectionFrame
    if not frame or not baseEnabled or R.testMode or not hostileUnit or secureAllowed or not tier
        or host._readableTierOwners.DivineProtection
        or R.NativeExactContainerAllowed(host.unit, tier)
    then
        if frame then hideReadableExact(frame) end
        return
    end

    -- Retain a directly readable exact witness only where a native owner cannot
    -- run and the general hostile presenter did not already claim this tier.
    local aura, spellID, readable = scanReadableExactAuraSet(
        host.unit, "HELPFUL", tier.spellIDs
    )
    host._divineProtectionReadable = readable
    host._divineProtectionSpellID = spellID
    if not aura then
        hideReadableExact(frame)
        return
    end

    host._divineProtectionActive = showReadableTier(host, "readableDivineProtectionFrame",
        { aura = aura, spellID = spellID, tier = tier }, false)
end

local function clearReadableRecency(host, frameKey, prefix)
    local frame = host and host[frameKey]
    if frame then hideReadableExact(frame) end
    if host then
        host[prefix .. "Readable"] = false
        host[prefix .. "ElectionReadable"] = false
        host[prefix .. "SpellID"] = nil
        host[prefix .. "TimingReadable"] = false
        host[prefix .. "TimingSource"] = nil
        host[prefix .. "AppliedAt"] = nil
        host[prefix .. "Active"] = false
    end
end

local function updateReadableRecency(host, baseEnabled, tierKey, frameKey, prefix)
    if not host or not baseEnabled or R.testMode or host._readableTierOwners[tierKey] then
        clearReadableRecency(host, frameKey, prefix)
        return
    end

    local tier = findTierByKey(tierKey)
    if not tier or not R.ExactFilterAllowed(
        host.unit, true, tier.spellIDs, tier.allowNeverSecret
    ) then
        clearReadableRecency(host, frameKey, prefix)
        return
    end

    local best, complete, electionReadable = scanLatestReadableExactTierAura(
        host.unit, tierKey, "HELPFUL|INCLUDE_NAME_PLATE_ONLY"
    )
    host[prefix .. "Readable"] = complete
    host[prefix .. "ElectionReadable"] = electionReadable
    host[prefix .. "SpellID"] = best and best.spellID or nil
    host[prefix .. "TimingReadable"] = best and best.timingReadable or false
    host[prefix .. "TimingSource"] = best and best.timingSource or nil
    host[prefix .. "AppliedAt"] = best and best.appliedAt or nil
    host[prefix .. "Active"] = false

    if not complete or not electionReadable or not best then
        hideReadableExact(host[frameKey])
        return
    end

    host[prefix .. "Active"] = showReadableTier(host, frameKey, best, true)
end

local function clearReadableWelcomingCampfire(host)
    local frame = host and host.readableWelcomingCampfireFrame
    if frame then hideReadableExact(frame) end
    if host then
        host._utilityReadable = false
        host._utilityWinnerSpellID = nil
        host._welcomingCampfireReadable = false
        host._welcomingCampfireActive = false
        host._welcomingCampfireDirect = false
        host._welcomingCampfireDirectFound = false
        host._welcomingCampfirePresent = false
        host._welcomingCampfireAppliedAt = nil
        host._welcomingCampfireTimingSource = nil
    end
end

local function updateReadableWelcomingCampfire(host, baseEnabled)
    if not host or not baseEnabled or R.testMode or host._readableTierOwners.Utility then
        clearReadableWelcomingCampfire(host)
        return
    end

    local best, readable, meta = scanReadableUtilityWinner(host.unit)
    host._utilityReadable = readable
    host._utilityWinnerSpellID = best and best.spellID or nil
    host._welcomingCampfireReadable = meta and meta.welcomingReadable or false
    host._welcomingCampfireDirect = meta and meta.welcomingDirect or false
    host._welcomingCampfireDirectFound = meta and meta.welcomingDirectFound or false
    host._welcomingCampfirePresent = meta and meta.welcomingPresent or false
    host._welcomingCampfireAppliedAt = meta and meta.welcomingAppliedAt or nil
    host._welcomingCampfireTimingSource = meta and meta.welcomingTimingSource or nil
    host._welcomingCampfireActive = false

    -- This readable frame may suppress the merged secure Utility slot only
    -- when the complete readable election proves Campfire is that slot's actual
    -- AuraInstanceID winner. If another Utility buff is newer, leave secure
    -- Utility authoritative.
    if not readable or not best or not isWelcomingCampfireSpellID(best.spellID) then
        hideReadableExact(host.readableWelcomingCampfireFrame)
        return
    end

    host._welcomingCampfireActive = showReadableTier(
        host, "readableWelcomingCampfireFrame", best, true
    )
end

local function createTestFrame(host)
    host._buildStage = "test-helper"
    local frame = CreateFrame("Frame", nil, host.layer, R.AURA_ANCHOR_TEMPLATE)
    placeAtPortrait(frame, host)
    frame:SetFrameStrata(host.strata)
    frame:SetFrameLevel((host.smallBaseLevel or 0) + 900)
    local icon = frame:CreateTexture(nil, "OVERLAY")
    icon:SetAllPoints(frame)
    icon:SetTexCoord(0, 1, 0, 1)
    applyIconMask(host, icon)
    frame.icon = icon
    local cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate," .. R.AURA_ANCHOR_TEMPLATE)
    configureCooldown(cooldown, host)
    frame.cooldown = cooldown
    host.cooldowns[#host.cooldowns + 1] = cooldown
    frame:Hide()
    return frame
end

local function hostStillCurrent(host)
    if not host or host._buildComplete ~= true then return false end
    local portrait, mask, unitFrame = R.GetPortrait(host.unit)
    return portrait == host.portrait and mask == host.portraitMask and unitFrame == host.unitFrame
end

local function hostHasSupportedBinding(host)
    if host.unit ~= "player" then return true end
    -- The native PlayerFrame can temporarily display a vehicle. Missing or
    -- inaccessible bindings also leave that native portrait in control.
    local binding = host.unitFrame and host.unitFrame.unit
    return R.CanAccess(binding) and binding == "player"
end

local function disableContainers(host)
    for _, container in ipairs(host.containers or {}) do
        pcall(container.SetEnabled, container, false)
        pcall(container.SetShown, container, false)
    end
end


local function restorePortrait(host)
    if not host or not host.reparented or not host.portrait then return end
    if host.portrait.SetParent and host.originalParent then
        pcall(host.portrait.SetParent, host.portrait, host.originalParent)
    end
    R.RestorePoints(host.portrait, host.originalPoints)
    host.reparented = false
end

function R.DestroyHost(unit)
    local host = R.hosts[unit]
    if not host then return true end
    if InCombatLockdown and InCombatLockdown() then
        R.buildQueued = true
        return false
    end
    disableContainers(host)
    for _, owner in pairs(host._readableTierOwners or {}) do hideReadableExact(owner.frame) end
    host._readableTierOwners = {}
    if host.testFrame then host.testFrame:Hide() end
    if host.readableHostileFrame then host.readableHostileFrame:Hide() end
    if host.readableBaselineFrame then host.readableBaselineFrame:Hide() end
    if host.readableHealingFrame then hideReadableExact(host.readableHealingFrame) end
    if host.readableSlowsFrame then host.readableSlowsFrame:Hide() end
    if host.readableDoTsFrame then hideReadableExact(host.readableDoTsFrame) end
    if host.readableDazedFrame then hideReadableExact(host.readableDazedFrame) end
    if host.readableForbearanceFrame then hideReadableExact(host.readableForbearanceFrame) end
    if host.readableStatusEffectsFrame then hideReadableExact(host.readableStatusEffectsFrame) end
    if host.readableResurrectionSicknessFrame then hideReadableExact(host.readableResurrectionSicknessFrame) end
    if host.readableDemoralizingFrame then hideReadableExact(host.readableDemoralizingFrame) end
    if host.readableBaselineHarmfulFrame then hideReadableExact(host.readableBaselineHarmfulFrame) end
    if host.readableCampfireHarmfulFrame then hideReadableExact(host.readableCampfireHarmfulFrame) end
    if host.readableOffensiveHarmfulFrame then hideReadableExact(host.readableOffensiveHarmfulFrame) end
    if host.readableRecentlyBandagedFrame then host.readableRecentlyBandagedFrame:Hide() end
    if host.readableGhostFrame then host.readableGhostFrame:Hide() end
    if host.readableFormStateFrame then host.readableFormStateFrame:Hide() end
    if host.readableWelcomingCampfireFrame then host.readableWelcomingCampfireFrame:Hide() end
    restorePortrait(host)
    if host.ownsLayer and host.layer then host.layer:Hide() end
    R.hosts[unit] = nil
    return true
end

function R.DestroyAll()
    if InCombatLockdown and InCombatLockdown() then
        R.forceRebuildQueued = true
        R.buildQueued = true
        return false
    end
    for _, unit in ipairs(R.TRACKED_UNITS) do R.DestroyHost(unit) end
    return true
end

-- An in-progress host is private to its constructor. Keep at most one build
-- failure per unit; ordinary UNIT_AURA refreshes must not accumulate abandoned
-- frame trees or spam errors. An explicit BuildAll (e.g. /bp on) retries.
local hostBuildFailures, hostBuildInProgress = {}, {}

local function buildHost(unit, host)
    -- Events and commands can reach this boundary without going through BuildAll.
    if not R.db or not R.db.enabled then return nil end
    local existing = R.hosts[unit]
    if existing and hostStillCurrent(existing) then return existing end
    local combat, combatReadable = R.SafeBool(InCombatLockdown)
    if not combatReadable or combat then
        R.buildQueued = true
        return nil
    end
    if existing then R.DestroyHost(unit) end
    if not R.SORT_METHOD or not R.SORT_DIRECTION then return nil end

    local portrait, portraitMask, unitFrame = R.GetPortrait(unit)
    if not portrait or not portrait.GetParent or not unitFrame then return nil end
    local originalParent = portrait:GetParent()
    if not originalParent then return nil end
    local originalPoints = R.CapturePoints(portrait)
    local point, relativeTo, relativePoint, x, y = firstPoint(portrait)
    if not point then return nil end

    local layer, strata, anchor
    local smallBaseLevel = 0
    -- Save restoration state before the first owned-frame/native-parent write.
    host.unitFrame = unitFrame
    host.portrait = portrait
    host.portraitMask = portraitMask
    host.originalParent = originalParent
    host.originalPoints = originalPoints
    host.smallBaseLevel = smallBaseLevel

    -- Single visual primitive for every portrait: Blizzard's native portrait
    -- and the secure aura occupy the same addon-owned layer one strata below
    -- the native frame artwork.  The native ring/chrome therefore frames both
    -- naturally.  Small-frame offsets tune only aura placement, not ownership.
    local parentStrata = "MEDIUM"
    if originalParent.GetFrameStrata then
        local ok, value = pcall(originalParent.GetFrameStrata, originalParent)
        -- Native frame strata can be secret. Wait for a readable value before
        -- constructing or moving anything; an existing refresh can retry.
        if not ok or not R.CanAccess(value) or type(value) ~= "string" then return nil end
        parentStrata = value
    end
    strata = STRATA_BELOW[parentStrata] or "BACKGROUND"

    host._buildStage = "layer"
    layer = CreateFrame("Frame", nil, originalParent)
    host.layer, host.ownsLayer, host.strata = layer, true, strata
    layer:SetAllPoints(originalParent)
    layer:SetFrameStrata(strata)
    layer:SetFrameLevel(0)

    host._buildStage = "portrait-parent"
    host.reparented = true
    portrait:SetParent(layer)
    portrait:ClearAllPoints()
    portrait:SetPoint(point, relativeTo or layer, relativePoint or point, x or 0, y or 0)

    host._buildStage = "anchor"
    anchor = CreateFrame("Frame", nil, layer, R.AURA_ANCHOR_TEMPLATE)
    host.anchor = anchor
    -- Only the addon image rectangle receives the measured translation.
    -- Native masks and the independent cooldown/timer anchors remain unchanged.
    R.ApplyPortraitImageLayout(anchor, host)
    anchor:SetFrameStrata(strata)
    anchor:SetFrameLevel(0)
    R.CreatePortraitImageMask(host)

    for index, tier in ipairs(R.TIERS or {}) do
        host._buildStage = "native-slot:" .. tostring(tier.key)
        local container = CreateFrame("AuraContainer", nil, anchor, "CustomAuraContainerTemplate")
        -- Retain ownership immediately, including an AddAuraSlot failure.
        host.containers[index] = container
        container:SetAllPoints(anchor)
        container:SetUnit(unit)
        container:SetFrameStrata(strata)
        container:SetFrameLevel((host.smallBaseLevel or 0) + (tier.level or index))
        container:SetEnabled(false)
        container:Hide()
        container:AddAuraSlot("Aura", tier.filter, {
            sortMethod = R.SORT_METHOD,
            sortDirection = R.SORT_DIRECTION,
            candidateFilters = R.CandidateFilters(tier),
            initializeFrame = function(button) initializeButton(host, button, tier) end,
        })
    end

    host.testFrame = createTestFrame(host)
    host.readableHostileFrame = createReadableExactFrame(host, 151)
    local baselineTier = findTierByKey("BaselineClass")
    host.readableBaselineFrame = createReadableExactFrame(
        host, baselineTier and baselineTier.level or 90
    )
    local healingTier = findTierByKey("Healing")
    host.readableHealingFrame = createReadableExactFrame(
        host, healingTier and healingTier.level or 251
    )

    local utilityTier = findTierByKey("Utility")
    host.readableWelcomingCampfireFrame = createReadableExactFrame(
        host, utilityTier and utilityTier.level or 270
    )

    -- Same-tier status recency applies on all five portrait hosts. These use
    -- the existing portrait placement helper; no native frame geometry changes.
    local statusEffectsTier = findTierByKey("StatusEffects")
    host.readableStatusEffectsFrame = createReadableExactFrame(
        host, statusEffectsTier and statusEffectsTier.level or 253
    )
    local resSicknessTier = findTierByKey("ResurrectionSickness")
    host.readableResurrectionSicknessFrame = createReadableExactFrame(
        host, resSicknessTier and resSicknessTier.level or 255
    )

    -- Moonfire/other DoTs and Dazed need the same checked readable path on
    -- Player, self/friendly Target/Focus and compact derived portraits. Reuse
    -- the restricted-anchor-safe constructor and the shared election logic.
    local dotsTier = findTierByKey("DoTs")
    host.readableDoTsFrame = createReadableExactFrame(host, dotsTier and dotsTier.level or 190)
    local selfStateTier = findTierByKey("SelfState")
    -- Exactly one level below the native SelfState slot. An actual permitted
    -- Cat/Bear aura always wins over this independent observed-state fallback.
    host.readableFormStateFrame = createReadableExactFrame(
        host, (selfStateTier and selfStateTier.level or 150) - 1
    )
    local dazedTier = findTierByKey("Dazed")
    host.readableDazedFrame = createReadableExactFrame(host, dazedTier and dazedTier.level or 279)

    -- Other large-frame-only helpers retain their existing scope. Pox
    -- remains inside StatusEffects, while actual Resurrection Sickness has an
    -- independent higher lane on every host, with no shared candidate ID.
    if not R.SMALL_UNITS[unit] then
        -- Only the requested low-world and NPC-demoralizing categories need
        -- these additional readable helpers on the three primary portraits.
        for _, spec in ipairs({
            { "Demoralizing", "readableDemoralizingFrame" },
            { "BaselineClassHarmful", "readableBaselineHarmfulFrame" },
            { "CampfireNearbyHarmful", "readableCampfireHarmfulFrame" },
        }) do
            local tier = findTierByKey(spec[1])
            if tier then host[spec[2]] = createReadableExactFrame(host, tier.level) end
        end

        local boostedRestTier = findTierByKey("BoostedRest")
        host.readableBoostedRestFrame = createReadableExactFrame(
            host, boostedRestTier and boostedRestTier.level or 1
        )

        local slowsTier = findTierByKey("Slows")
        host.readableSlowsFrame = createReadableExactFrame(host, slowsTier and slowsTier.level or 278)

        local forbearanceTier = findTierByKey("Forbearance")
        host.readableForbearanceFrame = createReadableExactFrame(
            host, forbearanceTier and forbearanceTier.level or 240
        )

        local offensiveHarmfulTier = findTierByKey("OffensiveHarmful")
        host.readableOffensiveHarmfulFrame = createReadableExactFrame(
            host, offensiveHarmfulTier and offensiveHarmfulTier.level or 281
        )

        local waitingTier = findTierByKey("WaitingToResurrect")
        host.readableWaitingToResurrectFrame = createReadableExactFrame(
            host, waitingTier and waitingTier.level or 332
        )

        local recentlyBandagedTier = findTierByKey("RecentlyBandaged")
        host.readableRecentlyBandagedFrame = createReadableExactFrame(
            host, recentlyBandagedTier and recentlyBandagedTier.level or 229
        )

        local immunityTier = findTierByKey("Immunity")
        host.readableGhostFrame = createReadableExactFrame(
            host, immunityTier and immunityTier.level or 330
        )
        if host.readableGhostFrame and host.readableGhostFrame.SetFrameLevel then
            -- Ghost stays above ordinary aura lanes; WaitingToResurrect is the
            -- explicit helpful-aura exception with a strictly higher level.
            host.readableGhostFrame:SetFrameLevel(
                (host.smallBaseLevel or 0) + (immunityTier and immunityTier.level or 330) + 2
            )
        end

        local divineProtectionTier = findTierByKey("DivineProtection")
        host.readableDivineProtectionFrame = createReadableExactFrame(
            host, divineProtectionTier and divineProtectionTier.level or 331
        )
    end

    -- Publish only after every native slot and required helper exists.
    host._buildStage, host._buildComplete = "ready", true
    R.hosts[unit] = host
    return host
end

local function abandonHost(host)
    disableContainers(host)
    -- Hiding the owned layer also hides any helper that threw before it could
    -- be assigned to a host field. Never leave that partial tree rendering.
    if host.layer then pcall(host.layer.Hide, host.layer) end
    local restored = true
    if host.reparented and host.portrait then
        local parentOK = pcall(host.portrait.SetParent, host.portrait, host.originalParent)
        local pointsOK = pcall(R.RestorePoints, host.portrait, host.originalPoints)
        restored = parentOK and pointsOK
        if restored then host.reparented = false end
    end
    return restored
end

function R.CreateHost(unit)
    if not R.db or not R.db.enabled or hostBuildInProgress[unit]
        or hostBuildFailures[unit] then return nil end
    local pending = { unit = unit, containers = {}, cooldowns = {}, _buildStage = "preflight" }
    hostBuildInProgress[unit] = true
    local ok, host = pcall(buildHost, unit, pending)
    if not ok then
        local cleanOK, restored = pcall(abandonHost, pending)
        local message = R.CanAccess(host) and type(host) == "string" and host or "unreadable construction error"
        -- Keep the exact readable failure locally for /bp layout; never inspect
        -- native aura data or stringify a secret error object.
        hostBuildFailures[unit] = {
            stage = pending._buildStage,
            message = message,
            restored = cleanOK and restored == true,
        }
        hostBuildInProgress[unit] = nil
        pcall(R.Print, "host build failed for " .. tostring(unit) .. " at " .. pending._buildStage
            .. "; /bp layout " .. tostring(unit) .. " reports the error")
        return nil
    end
    hostBuildInProgress[unit] = nil
    -- This callback needs a published host. Keep it outside the construction
    -- transaction: pet-art refresh is not a prerequisite for aura helpers.
    if host == pending and unit ~= "player" and R.UpdateObservedPetPortrait then
        R.UpdateObservedPetPortrait(unit)
    end
    return host
end

local function setContainer(container, shown, forceRefresh)
    if not container then return end

    local wasEnabled
    if forceRefresh and shown and container.IsEnabled then
        local ok, value = pcall(container.IsEnabled, container)
        if ok and R.CanAccess(value) and type(value) == "boolean" then wasEnabled = value end
    end

    local enabledOK = pcall(container.SetEnabled, container, shown)
    local shownOK = pcall(container.SetShown, container, shown)
    local refreshedOK = true

    -- SetEnabled and Show/Hide already refresh when state changes. Only force a
    -- full refresh when the unit token's referent/relation changed underneath an
    -- already-enabled container (target/focus/derived-token lifecycle events).
    if forceRefresh and shown and wasEnabled == true and container.UpdateAllAuras then
        refreshedOK = pcall(container.UpdateAllAuras, container)
    end
    return enabledOK and shownOK and refreshedOK
end

function R.UpdateHost(host, forceContainerRefresh)
    if not host or host._buildComplete ~= true then return end
    local owners = host._readableTierOwners or {}
    for key, owner in pairs(owners) do
        -- A missing/replaced addon frame must revoke its previous presentation.
        if host[owner.frameKey] ~= owner.frame or owner.frame.cooldown ~= owner.cooldown then
            clearReadableCooldown(owner.cooldown)
            hideReadableExact(owner.frame)
        end
        owners[key] = nil
    end
    host._readableTierOwners = owners
    local unitExists, existsReadable = R.UnitExistsState(host.unit)
    local present = not UnitExists or (existsReadable and unitExists)
    local base = R.IsUnitEnabled(host.unit) and not R.testMode and present and hostHasSupportedBinding(host)
    host._unitExists = present and true or false
    host._unitExistsReadable = existsReadable
    local hostileUnit, hostileRelationReadable = R.HostileUnitState(host.unit)
    local isPlayer, playerReadable = R.PlayerUnitState(host.unit)
    local hostilePlayer = hostileUnit and playerReadable and isPlayer or false
    local assistable, assistReadable = R.SafeBool(
        UnitCanAssist, "player", host.unit, true, true
    )
    host._hostileUnit = hostileRelationReadable and hostileUnit or nil
    host._hostileRelationReadable = hostileRelationReadable
    host._hostilePlayer = hostilePlayer
    if playerReadable then host._isPlayer = isPlayer else host._isPlayer = nil end
    host._playerReadable = playerReadable
    if assistReadable then host._assistable = assistable else host._assistable = nil end
    host._assistReadable = assistReadable

    local hostileReadable = false
    if hostileUnit then
        -- Readable exact hostile helpful auras are useful for both players and
        -- NPCs. The broad secure fallback below also covers hostile NPCs such
        -- as totems when this client hides their aura identities from Lua.
        hostileReadable = updateReadableHostile(host, base)
    else
        clearReadableHostile(host)
    end
    updateObservedDruidForm(host, base, hostilePlayer, hostileReadable)

    local divineProtectionTier = findTierByKey("DivineProtection")
    local divineProtectionSecureAllowed = divineProtectionTier and R.ExactFilterAllowed(
        host.unit, true, divineProtectionTier.spellIDs, divineProtectionTier.allowNeverSecret
    ) or false
    updateReadableDivineProtection(
        host, base, hostileUnit, divineProtectionSecureAllowed
    )

    -- These friendly/self harmful lanes can be relation-restricted. Use only
    -- complete, directly readable same-tier elections; partial/secret lists
    -- cannot replace a permitted native owner or invent an aura's identity.
    updateReadableHarmfulTier(host, base, "Demoralizing", "readableDemoralizingFrame", "_demoralizing")
    updateReadableHarmfulTier(host, base, "BaselineClassHarmful", "readableBaselineHarmfulFrame", "_baselineHarmful")
    updateReadableHarmfulTier(host, base, "CampfireNearbyHarmful", "readableCampfireHarmfulFrame", "_campfireHarmful")
    updateReadableHarmfulTier(host, base, "DoTs", "readableDoTsFrame", "_dots")
    updateReadableHarmfulTier(host, base, "Dazed", "readableDazedFrame", "_dazed")
    updateReadableHarmfulTier(host, base, "Slows", "readableSlowsFrame", "_slows")
    updateReadableHarmfulTier(host, base, "Forbearance", "readableForbearanceFrame", "_forbearance")
    updateReadableHarmfulTier(host, base, "StatusEffects", "readableStatusEffectsFrame", "_statusEffects")
    updateReadableHarmfulTier(host, base, "ResurrectionSickness", "readableResurrectionSicknessFrame", "_resurrectionSickness")
    updateReadableHarmfulTier(host, base, "OffensiveHarmful", "readableOffensiveHarmfulFrame", "_offensiveHarmful")

    -- Boosted Rest is a harmful camping cooldown that can be directly readable
    -- on friendly/self units even when exact harmful-ID AuraContainer filtering
    -- is relation-gated. Keep the secure exact lane authoritative when legal;
    -- otherwise render only a directly readable exact 1229451 witness.
    local boostedRestTier = findTierByKey("BoostedRest")
    local boostedRestSecureAllowed = boostedRestTier and R.ExactFilterAllowed(
        host.unit, false, boostedRestTier.spellIDs, boostedRestTier.allowNeverSecret
    ) or false
    host._boostedRestReadable = false
    host._boostedRestActive = false
    if not R.SMALL_UNITS[host.unit] and base and boostedRestTier and not boostedRestSecureAllowed then
        local aura, readable = scanReadableExactAura(
            host.unit, "HARMFUL|INCLUDE_NAME_PLATE_ONLY", BOOSTED_REST_SPELL_ID
        )
        host._boostedRestReadable = readable
        if aura then
            host._boostedRestActive = showReadableAura(
                host.readableBoostedRestFrame, aura, BOOSTED_REST_SPELL_ID, host.unit
            )
        else
            hideReadableExact(host.readableBoostedRestFrame)
        end
    elseif host.readableBoostedRestFrame then
        hideReadableExact(host.readableBoostedRestFrame)
    end

    -- Waiting to Resurrect is a helpful aura on ghosted units. Keep its secure
    -- exact lane authoritative when legal; otherwise show only a directly
    -- readable exact-ID witness above the state-derived Ghost frame.
    local waitingTier = findTierByKey("WaitingToResurrect")
    local waitingSecureAllowed = waitingTier and R.ExactFilterAllowed(
        host.unit, true, waitingTier.spellIDs, waitingTier.allowNeverSecret
    ) or false
    host._waitingToResurrectSecureAllowed = waitingSecureAllowed
    host._waitingToResurrectReadable = false
    host._waitingToResurrectActive = false
    host._waitingToResurrectSpellID = nil
    if not R.SMALL_UNITS[host.unit] and base and waitingTier and not waitingSecureAllowed
        and not host._readableTierOwners.WaitingToResurrect
        and not R.NativeExactContainerAllowed(host.unit, waitingTier)
    then
        local aura, spellID, readable = scanReadableExactAuraSet(
            host.unit, "HELPFUL", waitingTier.spellIDs
        )
        host._waitingToResurrectReadable = readable
        if aura then
            host._waitingToResurrectSpellID = spellID
            host._waitingToResurrectActive = showReadableTier(
                host, "readableWaitingToResurrectFrame",
                { aura = aura, spellID = spellID, tier = waitingTier }, false
            )
        else
            hideReadableExact(host.readableWaitingToResurrectFrame)
        end
    elseif host.readableWaitingToResurrectFrame then
        hideReadableExact(host.readableWaitingToResurrectFrame)
    end

    -- RecentlyBandaged now includes Wandering Plague. Elect over the entire
    -- readable band instead of a singleton 11196 lookup that cannot see it.
    updateReadableHarmfulTier(host, base, "RecentlyBandaged", "readableRecentlyBandagedFrame", "_recentlyBandaged")

    -- Ghost is a state-derived Immunity-tier witness. This is required on
    -- self/friendly units where exact harmful aura identity may be unavailable.
    updateGhostState(host, base)

    -- BaselineClass and Healing share application-time evidence and election.
    updateReadableRecency(host, base, "BaselineClass", "readableBaselineFrame", "_baseline")
    updateReadableRecency(host, base, "Healing", "readableHealingFrame", "_healing")

    -- Welcoming Campfire is a Utility-tier state at 270. Its separate readable
    -- witness exists only for Forever visibility and stays on the same visual
    -- priority surface as ordinary Utility buffs.
    updateReadableWelcomingCampfire(host, base)

    local slowsTier = findTierByKey("Slows")
    local slowsSecureAllowed = slowsTier and R.ExactFilterAllowed(
        host.unit, false, slowsTier.spellIDs, slowsTier.allowNeverSecret
    ) or false
    local weakenedSoulTier = findTierByKey("WeakenedSoul")
    local weakenedSoulSecureAllowed = weakenedSoulTier and R.ExactFilterAllowed(
        host.unit, false, weakenedSoulTier.spellIDs, weakenedSoulTier.allowNeverSecret
    ) or false
    local exactHarmfulAllowed = R.ExactFilterAllowed(host.unit, false, nil, false)
    host._exactHarmfulAllowed = exactHarmfulAllowed
    host._smallHarmfulEnabled = false
    host._containerWriteFailures = 0

    for index, tier in ipairs(R.TIERS or {}) do
        local enabled = base

        if tier.key == "FrostArmorSignature" then
            -- Use the semantic Frost Armor equivalence class only for a hostile
            -- unit that is positively established as non-player. UNKNOWN player
            -- identity is not permission to classify the unit as an NPC.
            enabled = enabled
                and hostileUnit
                and playerReadable
                and not isPlayer
                and not hostileReadable
        elseif tier.key == "HostileHelpful" then
            -- Exact readable identities win when available. If Forever seals
            -- them, fall back to Blizzard's broad secure HELPFUL stream, but
            -- for any positively established hostile unit, including totems.
            enabled = enabled and hostileUnit and not hostileReadable
        elseif tier.key == "SmallFriendlyHarmful" then
            -- Preserve a low-priority, identity-blind native harmful stream for
            -- hostile units too. Exact-ID filtering may be permitted on the
            -- opponent while all *listed* CC tiers are empty or temporarily
            -- unreadable after stun/DR transitions; an unrelated timed debuff
            -- must not vanish solely because it has no classified owner.
            -- On friendly/self units retain the relation-gated rule. Native
            -- classified CC, StatusEffects, and DoTs all outrank this fallback.
            -- Never identify or promote a generic aura based on its presence.
            enabled = enabled and (hostileUnit or not exactHarmfulAllowed)
            host._smallHarmfulEnabled = enabled and true or false
        elseif tier.key == "ChilledSignature" then
            -- Chilled's semantic signature is the last resort: exact secure
            -- identity first, then the readable exact Slows witness, then shape.
            enabled = enabled and not slowsSecureAllowed and not host._slowsActive
        elseif tier.key == "WeakenedSoulFallback" then
            -- Do not run the broad short-harmful approximation where exact
            -- Weakened Soul identity filtering is already legal.
            enabled = enabled and not weakenedSoulSecureAllowed
        elseif tier.exact then
            local owner = host._readableTierOwners[tier.key]
            if (owner and owner.complete) or (tier.key == "ImmunityHarmful" and host._ghostActive) then
                -- Only a complete, successfully presented same-tier election
                -- replaces a native exact owner. Ghost keeps its state rule.
                enabled = false
            else
                -- Native filtering checks permission per aura. A mixed opted-in
                -- set may run for its NeverSecret members without authorizing
                -- Lua to treat the whole set as readable.
                enabled = enabled and R.NativeExactContainerAllowed(host.unit, tier)
            end
        end

        if not setContainer(host.containers[index], enabled, forceContainerRefresh) then
            host._containerWriteFailures = host._containerWriteFailures + 1
        end
    end
end

local function showTest(host)
    if not host or not host.testFrame then return end
    local texture = "Interface\\Icons\\Spell_Holy_SealOfWisdom"
    if C_Spell and C_Spell.GetSpellTexture then
        local ok, value = pcall(C_Spell.GetSpellTexture, 19742)
        if ok and R.CanAccess(value) and value ~= nil then texture = value end
    elseif GetSpellTexture then
        local ok, value = pcall(GetSpellTexture, 19742)
        if ok and R.CanAccess(value) and value ~= nil then texture = value end
    end
    host.testFrame.icon:SetTexture(texture)
    if host.testFrame.cooldown and host.testFrame.cooldown.SetCooldown then
        pcall(host.testFrame.cooldown.SetCooldown, host.testFrame.cooldown, GetTime(), 10)
    end
    host.testFrame:Show()
end

function R.Refresh(unit, forceContainerRefresh)
    local host = R.hosts[unit]
    if not R.IsUnitEnabled(unit) then
        -- A stale host may still await combat-safe restoration. Hide its
        -- disabled presentation before any replacement/construction path.
        if host then
            if host.testFrame then host.testFrame:Hide() end
            R.UpdateHost(host)
        end
        return
    end
    if host and not hostStillCurrent(host) then
        if InCombatLockdown and InCombatLockdown() then
            R.buildQueued = true
            return
        end
        R.DestroyHost(unit)
        host = nil
    end
    host = host or R.CreateHost(unit)
    if not host then return end

    if R.testMode and R.IsUnitEnabled(unit) and hostHasSupportedBinding(host) then
        R.UpdateHost(host, forceContainerRefresh)
        showTest(host)
    else
        if host.testFrame then host.testFrame:Hide() end
        R.UpdateHost(host, forceContainerRefresh)
    end
end

function R.RefreshAll(forceContainerRefresh)
    for _, unit in ipairs(R.TRACKED_UNITS) do R.Refresh(unit, forceContainerRefresh) end
end

function R.BuildAll()
    if InCombatLockdown and InCombatLockdown() then
        R.buildQueued = true
        -- Existing hosts can reconcile presentation while structural work waits.
        R.RefreshAll()
        return
    end
    if not R.db or not R.db.enabled then
        R.DestroyAll()
        R.buildQueued = false
        return
    end
    R.buildQueued = false
    for _, unit in ipairs(R.TRACKED_UNITS) do
        local failure = hostBuildFailures[unit]
        -- Failed restoration requires a reload, not nested ownership on retry.
        if failure and failure.restored then hostBuildFailures[unit] = nil end
        R.CreateHost(unit)
    end
    R.RefreshAll()
end

function R.ApplyPresentation(unit)
    for token, host in pairs(R.hosts) do
        if not unit or token == unit then
            for _, cooldown in ipairs(host.cooldowns or {}) do
                if cooldown.SetDrawSwipe then pcall(cooldown.SetDrawSwipe, cooldown, R.db.showSwipe) end
                R.ApplyCountdownFormat(cooldown)
                alignCountdown(cooldown, host)
            end
        end
    end
end

-- Read-only layout evidence. This inspects bounds of ONE sample cooldown, not
-- its aura identity, time, visibility or text. A successful setter is not proof
-- of visible glyph centering. Unknown/secret geometry remains unknown.
function R.GetLayoutDebug(unit)
    local host = R.hosts[unit]
    if not host then
        local failure = hostBuildFailures[unit]
        if failure then
            return unit .. " host=missing build=failed stage=" .. failure.stage
                .. " restored=" .. tostring(failure.restored) .. " error=" .. failure.message
        end
        return unit .. " host=missing"
    end
    local function center(region)
        if not R.CanAccess(region) or not region or type(region.GetCenter) ~= "function"
            or type(region.GetEffectiveScale) ~= "function" then return nil end
        local ok, x, y = pcall(region.GetCenter, region)
        local scaleOK, scale = pcall(region.GetEffectiveScale, region)
        if not ok or not scaleOK or not R.CanAccess(x) or not R.CanAccess(y)
            or not R.CanAccess(scale) or type(x) ~= "number" or type(y) ~= "number"
            or type(scale) ~= "number" or x ~= x or y ~= y or scale ~= scale
            or math.abs(x) == math.huge or math.abs(y) == math.huge
            or scale <= 0 or scale == math.huge then return nil end
        return x * scale, y * scale
    end
    local parentState = "unknown"
    if host.portrait and type(host.portrait.GetParent) == "function" then
        local ok, parent = pcall(host.portrait.GetParent, host.portrait)
        if ok and R.CanAccess(parent) then
            parentState = parent == host.layer and "owned" or "native-or-other"
        end
    end
    local function shownState(frame)
        local shown, readable = R.SafeBool(frame and frame.IsShown, frame)
        return readable and tostring(shown) or "unknown"
    end
    local binding = host.unitFrame and host.unitFrame.unit
    local bindingState = R.CanAccess(binding) and type(binding) == "string" and binding or "unknown"
    local sample = host.cooldowns and host.cooldowns[1]
    local text
    if sample and type(sample.GetCountdownFontString) == "function" then
        local ok, value = pcall(sample.GetCountdownFontString, sample)
        if ok and R.CanAccess(value) then text = value end
    end
    local x, y = center(host.portraitMask or host.portrait)
    local tx, ty = center(text)
    local delta = x and tx and string.format("%.3f,%.3f", tx-x, ty-y) or "unknown"
    return unit .. " host=present enabled=" .. tostring(R.IsUnitEnabled(unit) == true)
        .. " build=" .. (host._buildComplete and "ready" or "incomplete")
        .. " ghostFrame=" .. tostring(host.readableGhostFrame ~= nil)
        .. " statusFrame=" .. tostring(host.readableStatusEffectsFrame ~= nil)
        .. " nativeShown=" .. shownState(host.unitFrame) .. " layerShown=" .. shownState(host.layer)
        .. " binding=" .. bindingState .. " portraitParent=" .. parentState
        .. " nativeRefresh=" .. tostring(host._nativeRefreshReason or "none")
        .. " existsReadable=" .. tostring(host._unitExistsReadable)
        .. " exists=" .. tostring(host._unitExists)
        .. " assistReadable=" .. tostring(host._assistReadable)
        .. " assist=" .. tostring(host._assistable)
        .. " ghost=" .. tostring(host._ghostActive) .. ":" .. tostring(host._ghostSource or "none")
        .. " form=" .. tostring(host._formStateActive) .. ":" .. tostring(host._formStateSpellID)
        .. ":" .. tostring(host._formStateReason or "none")
        .. " statusEffects=" .. tostring(host._statusEffectsActive)
        .. " statusDirect=" .. tostring(host._statusEffectsDirectWitness or false)
        .. " resSicknessFrame=" .. tostring(host.readableResurrectionSicknessFrame ~= nil)
        .. " resSickness=" .. tostring(host._resurrectionSicknessActive)
        .. " resSicknessDirect=" .. tostring(host._resurrectionSicknessDirectWitness or false)
        .. " writeErrors=" .. tostring(host._containerWriteFailures or 0)
        .. " sampleLayout=" .. tostring(sample and sample._bjarkiAlignmentState or "missing")
        .. " timerDelta=" .. delta
end

-- Geometry evidence only: no presentation setter, aura query, or refresh.
-- Distinguish the image's full source rectangle from the mask rectangle;
-- neither the source artwork's optical center nor its alpha aperture can be
-- inferred from SetAllPoints alone. Report actual pixels, including scale.
function R.GetGeometryDebug(unit)
    local host = R.hosts[unit]
    if not host then return unit .. " host=missing" end
    local function number(value)
        return R.CanAccess(value) and type(value) == "number" and value == value
            and math.abs(value) ~= math.huge
    end
    local factor
    if PixelUtil and type(PixelUtil.GetPixelToUIUnitFactor) == "function" then
        local ok, value = pcall(PixelUtil.GetPixelToUIUnitFactor)
        if ok and number(value) and value > 0 then factor = value end
    end
    local function bounds(region)
        if not factor or not R.CanAccess(region) or not region
            or type(region.GetCenter) ~= "function" or type(region.GetSize) ~= "function"
            or type(region.GetEffectiveScale) ~= "function" then return nil end
        local ok, x, y = pcall(region.GetCenter, region)
        local sized, w, h = pcall(region.GetSize, region)
        local scaled, scale = pcall(region.GetEffectiveScale, region)
        if not ok or not sized or not scaled or not number(x) or not number(y)
            or not number(w) or not number(h) or not number(scale) or scale <= 0
            or w <= 0 or h <= 0 then return nil end
        local multiplier = scale / factor
        return {x*multiplier, y*multiplier, w*multiplier, h*multiplier}
    end
    local function describe(rect)
        if not rect then return "unknown" end
        return string.format("(%.2f,%.2f)%.2fx%.2f", rect[1], rect[2], rect[3], rect[4])
    end
    local quad, mask, image = bounds(host.portrait), bounds(host.portraitMask), bounds(host.anchor)
    local delta = image and mask and string.format("%.2f,%.2f", image[1]-mask[1], image[2]-mask[2]) or "unknown"
    local clip = bounds(host.imageMask or host.portraitMask)
    local clipDelta = image and clip and string.format("%.2f,%.2f", image[1]-clip[1], image[2]-clip[2]) or "unknown"
    return unit .. " quad=" .. describe(quad) .. " mask=" .. describe(mask)
        .. " image=" .. describe(image) .. " image-mask=" .. delta
        .. " clipKind=" .. tostring(host.imageClipKind or "native")
        .. " clip=" .. describe(clip) .. " image-clip=" .. clipDelta
end
