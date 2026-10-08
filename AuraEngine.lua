local addonName, BP = ...
local R = assert(BP.Runtime, "Core.lua must load first")

local STRATA_BELOW = {
    BACKGROUND = "BACKGROUND", LOW = "BACKGROUND", MEDIUM = "LOW", HIGH = "MEDIUM",
    DIALOG = "HIGH", FULLSCREEN = "DIALOG", FULLSCREEN_DIALOG = "FULLSCREEN", TOOLTIP = "FULLSCREEN_DIALOG",
}

local AURA_SCAN_LIMIT = 80

local SMALL_GEOMETRY = {
    targettarget = { iconX = 2, iconY = 0, timerX = 0, timerY = -1 },
    focustarget = { iconX = 1, iconY = 0, timerX = 1, timerY = -1 },
}

-- Use Blizzard's portrait mask when exposed. Small derived frames without one
-- rely on the native artwork above the shared lower layer for circular framing.
local function applyIconMask(host, icon)
    -- Reuse Blizzard's real portrait mask when exposed.  For ToT/FoT, the
    -- native frame artwork above the shared lower layer provides the visible
    -- circular framing; do not synthesize a second mask or cloned ring.
    if host.portraitMask and icon.AddMaskTexture then
        pcall(icon.AddMaskTexture, icon, host.portraitMask)
    end
end

local function configureCooldown(cooldown, unit)
    if cooldown.SetMinimumCountdownDuration then cooldown:SetMinimumCountdownDuration(0) end
    cooldown:SetAllPoints()
    if cooldown.SetUsingParentLevel then cooldown:SetUsingParentLevel(true) end
    if cooldown.SetReverse then cooldown:SetReverse(true) end
    if cooldown.SetDrawBling then cooldown:SetDrawBling(false) end
    if cooldown.SetDrawEdge then cooldown:SetDrawEdge(false) end
    if cooldown.SetDrawSwipe then cooldown:SetDrawSwipe(R.db and R.db.showSwipe or false) end
    R.ApplyCountdownFormat(cooldown)
    if cooldown.SetSwipeTexture then cooldown:SetSwipeTexture(R.SWIPE_TEXTURE) end

    local geometry = SMALL_GEOMETRY[unit]
    if geometry and cooldown.GetCountdownFontString then
        local ok, text = pcall(cooldown.GetCountdownFontString, cooldown)
        if ok and text then
            if not cooldown._bjarkiFontAdjusted and text.GetFont and text.SetFont then
                local fontOK, font, size, flags = pcall(text.GetFont, text)
                if fontOK and font and type(size) == "number" then
                    pcall(text.SetFont, text, font, math.max(1, size - 2), flags or "")
                    cooldown._bjarkiFontAdjusted = true
                end
            end
            if text.ClearAllPoints and text.SetPoint then
                pcall(text.ClearAllPoints, text)
                pcall(text.SetPoint, text, "CENTER", cooldown, "CENTER", geometry.timerX, geometry.timerY)
            end
        end
    end
end

local function initializeButton(host, button, tier)
    button:SetAllPoints(host.anchor)
    if button.SetFrameLevel then button:SetFrameLevel((host.smallBaseLevel or 0) + (tier.level or 1) + 1) end

    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetAllPoints(button)
    icon:SetTexCoord(0, 1, 0, 1)
    applyIconMask(host, icon)
    button:SetIcon(icon)

    local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    configureCooldown(cooldown, host.unit)
    button:SetDurationCooldown(cooldown)
    button:EnableMouse(false)
    host.cooldowns[#host.cooldowns + 1] = cooldown
end

local function firstPoint(region)
    if not region or not region.GetPoint then return nil end
    return region:GetPoint(1)
end

local function placeAtPortrait(frame, host)
    local point, relativeTo, relativePoint, x, y = firstPoint(host.portrait)
    local geometry = SMALL_GEOMETRY[host.unit]
    local ox, oy = geometry and geometry.iconX or 0, geometry and geometry.iconY or 0
    if point then
        frame:SetPoint(point, relativeTo or host.layer, relativePoint or point, (x or 0) + ox, (y or 0) + oy)
    else
        frame:SetPoint("CENTER", host.layer, "CENTER", ox, oy)
    end
    frame:SetSize(host.portrait:GetSize())
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
local RES_SICKNESS_SPELL_ID = 15007
local RECENTLY_BANDAGED_SPELL_ID = 11196
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

-- BaselineClass and Healing use application-time recency: a refreshed aura
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
    return tier and (tier.key == "BaselineClass" or tier.key == "Healing")
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
    local frame = CreateFrame("Frame", nil, host.layer)
    placeAtPortrait(frame, host)
    frame:SetFrameStrata(host.strata)
    frame:SetFrameLevel((host.smallBaseLevel or 0) + (level or 1) + 1)

    local icon = frame:CreateTexture(nil, "BACKGROUND")
    icon:SetAllPoints(frame)
    icon:SetTexCoord(0, 1, 0, 1)
    applyIconMask(host, icon)
    frame.icon = icon

    local cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
    configureCooldown(cooldown, host.unit)
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

local function setReadableSpellIcon(frame, spellID)
    if not frame or not frame.icon or not frame.icon.SetTexture then
        hideReadableExact(frame)
        return false
    end

    local texture
    if C_Spell and C_Spell.GetSpellTexture then
        local ok, value = pcall(C_Spell.GetSpellTexture, spellID)
        if ok and R.CanAccess(value) then texture = value end
    elseif GetSpellTexture then
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
    if not setReadableSpellIcon(frame, spellID) then return false end

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

local function showStaticSpell(frame, spellID)
    if not setReadableSpellIcon(frame, spellID) then return false end
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

local function updateGhostState(host, baseEnabled)
    host._ghostReadable = false
    host._ghostActive = false

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

    if readable and isGhost then
        host._ghostActive = showStaticSpell(frame, GHOST_SPELL_ID)
    else
        hideReadableExact(frame)
    end
end

local function clearReadableSlows(host)
    local frame = host and host.readableSlowsFrame
    if frame then hideReadableExact(frame) end
    if host then
        host._slowsReadable = false
        host._slowsElectionReadable = false
        host._slowsSpellID = nil
        host._slowsActive = false
    end
end

local function updateReadableSlows(host, baseEnabled)
    if not host or not baseEnabled or R.testMode or R.SMALL_UNITS[host.unit] then
        clearReadableSlows(host)
        return
    end

    local tier = findTierByKey("Slows")
    if not tier then
        clearReadableSlows(host)
        return
    end

    -- If the secure exact harmful filter is legal for this relation, leave the
    -- secure AuraContainer fully authoritative.
    if R.ExactFilterAllowed(host.unit, false, tier.spellIDs, tier.allowNeverSecret) then
        clearReadableSlows(host)
        return
    end

    local best, complete, electionReadable = scanLatestReadableExactTierAura(
        host.unit, "Slows", "HARMFUL|INCLUDE_NAME_PLATE_ONLY"
    )
    host._slowsReadable = complete
    host._slowsElectionReadable = electionReadable
    host._slowsSpellID = best and best.spellID or nil

    if not complete or not electionReadable or not best then
        hideReadableExact(host.readableSlowsFrame)
        host._slowsActive = false
        return
    end

    host._slowsActive = showReadableTier(host, "readableSlowsFrame", best, true)
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
    local frame = CreateFrame("Frame", nil, host.layer)
    placeAtPortrait(frame, host)
    frame:SetFrameStrata(host.strata)
    frame:SetFrameLevel((host.smallBaseLevel or 0) + 900)
    local icon = frame:CreateTexture(nil, "OVERLAY")
    icon:SetAllPoints(frame)
    icon:SetTexCoord(0, 1, 0, 1)
    applyIconMask(host, icon)
    frame.icon = icon
    local cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
    configureCooldown(cooldown, host.unit)
    frame.cooldown = cooldown
    host.cooldowns[#host.cooldowns + 1] = cooldown
    frame:Hide()
    return frame
end

local function hostStillCurrent(host)
    if not host then return false end
    local portrait, _, unitFrame = R.GetPortrait(host.unit)
    return portrait == host.portrait and unitFrame == host.unitFrame
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
    if host.readableResSicknessFrame then host.readableResSicknessFrame:Hide() end
    if host.readableRecentlyBandagedFrame then host.readableRecentlyBandagedFrame:Hide() end
    if host.readableGhostFrame then host.readableGhostFrame:Hide() end
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

function R.CreateHost(unit)
    -- Events and commands can reach this boundary without going through BuildAll.
    if not R.db or not R.db.enabled then return nil end
    local existing = R.hosts[unit]
    if existing and hostStillCurrent(existing) then return existing end
    if InCombatLockdown and InCombatLockdown() then
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

    local layer, strata, anchor, ownsLayer, reparented
    local smallBaseLevel = 0

    -- Single visual primitive for every portrait: Blizzard's native portrait
    -- and the secure aura occupy the same addon-owned layer one strata below
    -- the native frame artwork.  The native ring/chrome therefore frames both
    -- naturally.  Small-frame offsets tune only aura placement, not ownership.
    local parentStrata = originalParent.GetFrameStrata and originalParent:GetFrameStrata() or "MEDIUM"
    strata = STRATA_BELOW[parentStrata] or "BACKGROUND"

    layer = CreateFrame("Frame", nil, originalParent)
    ownsLayer = true
    layer:SetAllPoints(originalParent)
    layer:SetFrameStrata(strata)
    layer:SetFrameLevel(0)

    portrait:SetParent(layer)
    portrait:ClearAllPoints()
    portrait:SetPoint(point, relativeTo or layer, relativePoint or point, x or 0, y or 0)
    reparented = true

    anchor = CreateFrame("Frame", nil, layer, R.AURA_ANCHOR_TEMPLATE)
    local geometry = SMALL_GEOMETRY[unit]
    local ox, oy = geometry and geometry.iconX or 0, geometry and geometry.iconY or 0
    anchor:SetPoint(point, relativeTo or layer, relativePoint or point, (x or 0) + ox, (y or 0) + oy)
    anchor:SetSize(portrait:GetSize())
    anchor:SetFrameStrata(strata)
    anchor:SetFrameLevel(0)

    local host = {
        unit = unit,
        unitFrame = unitFrame,
        portrait = portrait,
        portraitMask = portraitMask,
        originalParent = originalParent,
        originalPoints = originalPoints,
        layer = layer,
        ownsLayer = ownsLayer,
        anchor = anchor,
        strata = strata,
        reparented = reparented,
        smallBaseLevel = smallBaseLevel,
        containers = {},
        cooldowns = {},
    }
    R.hosts[unit] = host


    for index, tier in ipairs(R.TIERS or {}) do
        local container = CreateFrame("AuraContainer", nil, anchor, "CustomAuraContainerTemplate")
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
        host.containers[index] = container
    end

    host.testFrame = createTestFrame(host)
    host.readableHostileFrame = createReadableExactFrame(host, 151)
    local baselineTier = findTierByKey("BaselineClass")
    host.readableBaselineFrame = createReadableExactFrame(
        host, baselineTier and baselineTier.level or 90
    )
    local healingTier = findTierByKey("Healing")
    host.readableHealingFrame = createReadableExactFrame(
        host, healingTier and healingTier.level or 255
    )

    local utilityTier = findTierByKey("Utility")
    host.readableWelcomingCampfireFrame = createReadableExactFrame(
        host, utilityTier and utilityTier.level or 270
    )

    -- Keep derived Blizzard target frames structurally identical to v0.1.1.
    -- They are lifecycle-sensitive; do not attach the ordinary readable
    -- Resurrection Sickness helper surface to ToT/FoT.
    if not R.SMALL_UNITS[unit] then
        local boostedRestTier = findTierByKey("BoostedRest")
        host.readableBoostedRestFrame = createReadableExactFrame(
            host, boostedRestTier and boostedRestTier.level or 20
        )

        local slowsTier = findTierByKey("Slows")
        host.readableSlowsFrame = createReadableExactFrame(host, slowsTier and slowsTier.level or 220)

        local resTier = findTierByKey("ResSickness")
        host.readableResSicknessFrame = createReadableExactFrame(host, resTier and resTier.level or 241)

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

    return host
end

local function setContainer(container, shown, forceRefresh)
    if not container then return end

    local wasEnabled
    if forceRefresh and shown and container.IsEnabled then
        local ok, value = pcall(container.IsEnabled, container)
        if ok and type(value) == "boolean" then wasEnabled = value end
    end

    pcall(container.SetEnabled, container, shown)
    pcall(container.SetShown, container, shown)

    -- SetEnabled and Show/Hide already refresh when state changes. Only force a
    -- full refresh when the unit token's referent/relation changed underneath an
    -- already-enabled container (target/focus/derived-token lifecycle events).
    if forceRefresh and shown and wasEnabled == true and container.UpdateAllAuras then
        pcall(container.UpdateAllAuras, container)
    end
end

function R.UpdateHost(host, forceContainerRefresh)
    if not host then return end
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
    local base = R.IsUnitEnabled(host.unit) and not R.testMode and present
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

    local divineProtectionTier = findTierByKey("DivineProtection")
    local divineProtectionSecureAllowed = divineProtectionTier and R.ExactFilterAllowed(
        host.unit, true, divineProtectionTier.spellIDs, divineProtectionTier.allowNeverSecret
    ) or false
    updateReadableDivineProtection(
        host, base, hostileUnit, divineProtectionSecureAllowed
    )

    -- Friendly/self exact harmful spell-ID filters can be relation-restricted.
    -- Directly readable Slows therefore get a narrow exact fallback.
    updateReadableSlows(host, base)

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

    -- Resurrection Sickness is a harmful aura commonly observed on self/friendly
    -- units, where exact harmful-ID AuraContainer filters may be relation-gated.
    -- If the secure exact lane is legal, it remains authoritative. Otherwise we
    -- render only a directly readable exact 15007 witness and make no inference
    -- when the aura stream or spell identity is inaccessible.
    local resTier = findTierByKey("ResSickness")
    local resSecureAllowed = resTier and R.ExactFilterAllowed(
        host.unit, false, resTier.spellIDs, resTier.allowNeverSecret
    ) or false
    host._resSicknessReadable = false
    host._resSicknessActive = false
    if not R.SMALL_UNITS[host.unit] and base and resTier and not resSecureAllowed then
        local aura, readable = scanReadableExactAura(host.unit, "HARMFUL", RES_SICKNESS_SPELL_ID)
        host._resSicknessReadable = readable
        if aura then
            host._resSicknessActive = showReadableAura(
                host.readableResSicknessFrame, aura, RES_SICKNESS_SPELL_ID, host.unit
            )
        else
            hideReadableExact(host.readableResSicknessFrame)
        end
    elseif host.readableResSicknessFrame then
        hideReadableExact(host.readableResSicknessFrame)
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

    -- Recently Bandaged is a self/friendly harmful state and therefore needs
    -- the same exact-readable escape hatch when harmful spell-ID filtering is
    -- relation-gated. Keep the exact secure lane whenever Blizzard permits it.
    local recentlyBandagedTier = findTierByKey("RecentlyBandaged")
    local recentlyBandagedSecureAllowed = recentlyBandagedTier and R.ExactFilterAllowed(
        host.unit, false, recentlyBandagedTier.spellIDs, recentlyBandagedTier.allowNeverSecret
    ) or false
    host._recentlyBandagedReadable = false
    host._recentlyBandagedActive = false
    if not R.SMALL_UNITS[host.unit] and base and recentlyBandagedTier
        and not recentlyBandagedSecureAllowed
    then
        local aura, readable = scanReadableExactAura(
            host.unit, "HARMFUL", RECENTLY_BANDAGED_SPELL_ID
        )
        host._recentlyBandagedReadable = readable
        if aura then
            host._recentlyBandagedActive = showReadableAura(
                host.readableRecentlyBandagedFrame, aura, RECENTLY_BANDAGED_SPELL_ID, host.unit
            )
        else
            hideReadableExact(host.readableRecentlyBandagedFrame)
        end
    elseif host.readableRecentlyBandagedFrame then
        hideReadableExact(host.readableRecentlyBandagedFrame)
    end

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
            -- Small derived frames need a generic harmful-state surface when
            -- exact harmful identity filtering is not authorized. The secure
            -- HARMFUL stream itself is enough warrant for "some harmful aura";
            -- do not require, or infer, a readable friendly relation.
            enabled = enabled
                and R.SMALL_UNITS[host.unit]
                and not exactHarmfulAllowed
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

        setContainer(host.containers[index], enabled, forceContainerRefresh)
    end
end

local function showTest(host)
    if not host or not host.testFrame then return end
    local texture = 132298
    if C_Spell and C_Spell.GetSpellTexture then
        local ok, value = pcall(C_Spell.GetSpellTexture, 408)
        if ok and R.CanAccess(value) and value ~= nil then texture = value end
    elseif GetSpellTexture then
        local ok, value = pcall(GetSpellTexture, 408)
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

    if R.testMode and R.IsUnitEnabled(unit) then
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
        return
    end
    if not R.db or not R.db.enabled then
        R.DestroyAll()
        R.buildQueued = false
        return
    end
    R.buildQueued = false
    for _, unit in ipairs(R.TRACKED_UNITS) do R.CreateHost(unit) end
    R.RefreshAll()
end

function R.ApplyPresentation()
    for _, host in pairs(R.hosts) do
        for _, cooldown in ipairs(host.cooldowns or {}) do
            if cooldown.SetDrawSwipe then pcall(cooldown.SetDrawSwipe, cooldown, R.db.showSwipe) end
            R.ApplyCountdownFormat(cooldown)
        end
    end
end
