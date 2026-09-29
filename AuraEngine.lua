local addonName, BP = ...
local R = assert(BP.Runtime, "Core.lua must load first")

local STRATA_BELOW = {
    BACKGROUND = "BACKGROUND", LOW = "BACKGROUND", MEDIUM = "LOW", HIGH = "MEDIUM",
    DIALOG = "HIGH", FULLSCREEN = "DIALOG", FULLSCREEN_DIALOG = "FULLSCREEN", TOOLTIP = "FULLSCREEN_DIALOG",
}

local SMALL_GEOMETRY = {
    targettarget = { iconX = 2, iconY = 0, timerX = 0, timerY = -1 },
    focustarget = { iconX = 1, iconY = 0, timerX = 1, timerY = -1 },
}

-- Small Blizzard derived frames do not expose a reliable PortraitMask on every
-- Forever build.  The icon therefore owns a local circular mask when Blizzard
-- does not provide one.  This masks only addon artwork; native frame regions are
-- never mutated.
local function applyIconMask(host, owner, icon)
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
    if cooldown.SetHideCountdownNumbers then cooldown:SetHideCountdownNumbers(false) end
    local formatter = R.GetCountdownFormatter()
    if formatter and cooldown.SetCountdownFormatter then
        pcall(cooldown.SetCountdownFormatter, cooldown, formatter)
    elseif cooldown.SetCountdownMillisecondsThreshold then
        pcall(cooldown.SetCountdownMillisecondsThreshold, cooldown, R.db and R.db.showDecimals and 10 or 0)
    end
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
    applyIconMask(host, button, icon)
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
    local best
    for _, tier in ipairs(R.TIERS or {}) do
        if tier.exact and tier.helpful and tier.spellIDs and tier.spellIDs[spellID] then
            if not best or (tier.level or 0) > (best.level or 0) then best = tier end
        end
    end
    return best
end

local RES_SICKNESS_SPELL_ID = 15007

local function findTierByKey(key)
    for _, tier in ipairs(R.TIERS or {}) do
        if tier.key == key then return tier end
    end
end

-- BaselineClass has a stronger within-tier contract than AuraInstanceID sorting
-- alone can provide: a refreshed aura should become the visible winner even when
-- Forever preserves that aura's instance ID.  When every competing baseline aura
-- exposes duration/expiration time, derive application time directly.  If any
-- candidate lacks readable timing, fall back to AuraInstanceID across the entire
-- tier so mixed readability never biases the winner toward the timed subset.
local function scanLatestReadableBaselineAura(unit)
    local tier = findTierByKey("BaselineClass")
    if not tier or not tier.spellIDs then return nil, false end
    if not C_UnitAuras or not C_UnitAuras.GetAuraDataByIndex then return nil, false end

    local candidates = {}
    local allTimingReadable = true

    for index = 1, 80 do
        local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex,
            unit, index, "HELPFUL|INCLUDE_NAME_PLATE_ONLY")
        if not ok or not R.CanAccess(aura) then return nil, false end
        if aura == nil then break end

        local spellID, spellReadable = R.ReadAuraField(aura, "spellId")
        if not spellReadable or type(spellID) ~= "number" then
            -- We cannot prove that an unreadable aura is outside BaselineClass.
            -- Relinquish the readable override and let the secure container win.
            return nil, false
        end

        if tier.spellIDs[spellID] then
            local auraInstanceID, instanceReadable = R.ReadAuraField(aura, "auraInstanceID")
            if not instanceReadable or type(auraInstanceID) ~= "number" then
                return nil, false
            end

            local duration, durationReadable = R.ReadAuraField(aura, "duration")
            local expirationTime, expirationReadable = R.ReadAuraField(aura, "expirationTime")
            local timingReadable = durationReadable and expirationReadable
                and type(duration) == "number" and type(expirationTime) == "number"
                and duration > 0

            if not timingReadable then allTimingReadable = false end
            candidates[#candidates + 1] = {
                aura = aura,
                spellID = spellID,
                auraInstanceID = auraInstanceID,
                appliedAt = timingReadable and (expirationTime - duration) or nil,
            }
        end
    end

    if #candidates == 0 then return nil, true end

    local best = candidates[1]
    for i = 2, #candidates do
        local candidate = candidates[i]
        local newer
        if allTimingReadable then
            newer = candidate.appliedAt > best.appliedAt
                or (candidate.appliedAt == best.appliedAt
                    and candidate.auraInstanceID > best.auraInstanceID)
        else
            newer = candidate.auraInstanceID > best.auraInstanceID
        end
        if newer then best = candidate end
    end

    best.timingReadable = allTimingReadable
    return best, true
end

local function scanReadableExactAura(unit, filter, spellID)
    if not C_UnitAuras or not C_UnitAuras.GetAuraDataByIndex then return nil, false end

    for index = 1, 80 do
        local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, index, filter)
        if not ok or not R.CanAccess(aura) then return nil, false end
        if aura == nil then return nil, true end

        local auraSpellID, readable = R.ReadAuraField(aura, "spellId")
        if not readable or type(auraSpellID) ~= "number" then return nil, false end
        if auraSpellID == spellID then return aura, true end
    end

    return nil, true
end

local function scanReadableHostileHelpful(unit)
    if not C_UnitAuras or not C_UnitAuras.GetAuraDataByIndex then
        return nil, false, 0
    end

    local best
    local count = 0
    local allReadable = true

    for index = 1, 80 do
        local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex,
            unit, index, "HELPFUL|INCLUDE_NAME_PLATE_ONLY")
        if not ok then
            allReadable = false
            break
        end

        -- Never compare/index an inaccessible aura object. If Forever seals the
        -- object itself, the secure HostileHelpful lane remains authoritative.
        if not R.CanAccess(aura) then
            allReadable = false
            break
        end
        if aura == nil then break end
        count = count + 1

        local spellID, idReadable = R.ReadAuraField(aura, "spellId")
        if not idReadable or type(spellID) ~= "number" then
            allReadable = false
        else
            local tier = findHelpfulTierForSpell(spellID)
            if tier then
                local auraInstanceID, instanceReadable = R.ReadAuraField(aura, "auraInstanceID")
                if not instanceReadable or type(auraInstanceID) ~= "number" then auraInstanceID = 0 end
                local candidate = {
                    aura = aura,
                    spellID = spellID,
                    tier = tier,
                    auraInstanceID = auraInstanceID,
                }
                if not best
                    or (tier.level or 0) > (best.tier.level or 0)
                    or ((tier.level or 0) == (best.tier.level or 0)
                        and candidate.auraInstanceID > best.auraInstanceID)
                then
                    best = candidate
                end
            end
        end
    end

    return best, allReadable and count > 0, count
end

local function createReadableHostileFrame(host)
    local frame = CreateFrame("Frame", nil, host.layer)
    placeAtPortrait(frame, host)
    frame:SetFrameStrata(host.strata)
    frame:SetFrameLevel((host.smallBaseLevel or 0) + 152)

    local icon = frame:CreateTexture(nil, "BACKGROUND")
    icon:SetAllPoints(frame)
    icon:SetTexCoord(0, 1, 0, 1)
    applyIconMask(host, frame, icon)
    frame.icon = icon

    local cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
    configureCooldown(cooldown, host.unit)
    frame.cooldown = cooldown
    host.cooldowns[#host.cooldowns + 1] = cooldown
    frame:Hide()
    return frame
end

local function createReadableExactFrame(host, level)
    local frame = CreateFrame("Frame", nil, host.layer)
    placeAtPortrait(frame, host)
    frame:SetFrameStrata(host.strata)
    frame:SetFrameLevel((host.smallBaseLevel or 0) + (level or 1) + 1)

    local icon = frame:CreateTexture(nil, "BACKGROUND")
    icon:SetAllPoints(frame)
    icon:SetTexCoord(0, 1, 0, 1)
    applyIconMask(host, frame, icon)
    frame.icon = icon

    local cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
    configureCooldown(cooldown, host.unit)
    frame.cooldown = cooldown
    host.cooldowns[#host.cooldowns + 1] = cooldown
    frame:Hide()
    return frame
end

local function hideReadableExact(frame)
    if not frame then return end
    if frame.cooldown then
        if frame.cooldown.Clear then
            pcall(frame.cooldown.Clear, frame.cooldown)
        elseif frame.cooldown.SetCooldown then
            pcall(frame.cooldown.SetCooldown, frame.cooldown, 0, 0)
        end
    end
    frame:Hide()
end

local function showReadableAura(frame, aura, spellID)
    if not frame or not aura then return false end

    local texture
    if C_Spell and C_Spell.GetSpellTexture then
        local ok, value = pcall(C_Spell.GetSpellTexture, spellID)
        if ok and R.CanAccess(value) then texture = value end
    elseif GetSpellTexture then
        local ok, value = pcall(GetSpellTexture, spellID)
        if ok and R.CanAccess(value) then texture = value end
    end
    if texture then pcall(frame.icon.SetTexture, frame.icon, texture) end

    local duration, durationReadable = R.ReadAuraField(aura, "duration")
    local expirationTime, expirationReadable = R.ReadAuraField(aura, "expirationTime")
    if frame.cooldown then
        if durationReadable and expirationReadable
            and type(duration) == "number" and type(expirationTime) == "number"
            and duration > 0 and frame.cooldown.SetCooldown
        then
            pcall(frame.cooldown.SetCooldown, frame.cooldown, expirationTime - duration, duration)
        elseif frame.cooldown.Clear then
            pcall(frame.cooldown.Clear, frame.cooldown)
        elseif frame.cooldown.SetCooldown then
            pcall(frame.cooldown.SetCooldown, frame.cooldown, 0, 0)
        end
    end

    frame:Show()
    return true
end

local function clearReadableHostile(host)
    local frame = host and host.readableHostileFrame
    if not frame then return end
    if frame.cooldown then
        if frame.cooldown.Clear then
            pcall(frame.cooldown.Clear, frame.cooldown)
        elseif frame.cooldown.SetCooldown then
            pcall(frame.cooldown.SetCooldown, frame.cooldown, 0, 0)
        end
    end
    frame:Hide()
    host._hostileReadable = false
    host._hostileCount = 0
    host._hostileSpellID = nil
end

local function updateReadableHostile(host, baseEnabled, hostilePlayer)
    if not host or not baseEnabled or not hostilePlayer or R.testMode then
        clearReadableHostile(host)
        return false
    end

    local best, allReadable, count = scanReadableHostileHelpful(host.unit)
    host._hostileReadable = allReadable
    host._hostileCount = count
    host._hostileSpellID = best and best.spellID or nil

    local frame = host.readableHostileFrame
    if not frame or not best then
        if frame then frame:Hide() end
        return allReadable
    end

    local texture
    if C_Spell and C_Spell.GetSpellTexture then
        local ok, value = pcall(C_Spell.GetSpellTexture, best.spellID)
        if ok and R.CanAccess(value) then texture = value end
    elseif GetSpellTexture then
        local ok, value = pcall(GetSpellTexture, best.spellID)
        if ok and R.CanAccess(value) then texture = value end
    end
    if texture then pcall(frame.icon.SetTexture, frame.icon, texture) end

    -- +2 puts the readable exact witness above the secure button for the same
    -- priority lane, while higher-priority secure lanes still outrank it.
    if frame.SetFrameLevel then pcall(frame.SetFrameLevel, frame, (host.smallBaseLevel or 0) + (best.tier.level or 1) + 2) end

    local duration, durationReadable = R.ReadAuraField(best.aura, "duration")
    local expirationTime, expirationReadable = R.ReadAuraField(best.aura, "expirationTime")
    if frame.cooldown then
        if durationReadable and expirationReadable
            and type(duration) == "number" and type(expirationTime) == "number"
            and duration > 0 and frame.cooldown.SetCooldown
        then
            pcall(frame.cooldown.SetCooldown, frame.cooldown, expirationTime - duration, duration)
        elseif frame.cooldown.Clear then
            pcall(frame.cooldown.Clear, frame.cooldown)
        elseif frame.cooldown.SetCooldown then
            pcall(frame.cooldown.SetCooldown, frame.cooldown, 0, 0)
        end
    end

    frame:Show()
    return allReadable
end

local function clearReadableBaseline(host)
    local frame = host and host.readableBaselineFrame
    if frame then hideReadableExact(frame) end
    if host then
        host._baselineReadable = false
        host._baselineSpellID = nil
        host._baselineTimingReadable = false
    end
end

local function updateReadableBaseline(host, baseEnabled)
    if not host or not baseEnabled or R.testMode then
        clearReadableBaseline(host)
        return
    end

    local tier = findTierByKey("BaselineClass")
    if not tier or not R.ExactFilterAllowed(
        host.unit, true, tier.spellIDs, tier.allowNeverSecret
    ) then
        clearReadableBaseline(host)
        return
    end

    local best, complete = scanLatestReadableBaselineAura(host.unit)
    host._baselineReadable = complete
    host._baselineSpellID = best and best.spellID or nil
    host._baselineTimingReadable = best and best.timingReadable or false

    if not complete or not best then
        hideReadableExact(host.readableBaselineFrame)
        return
    end

    showReadableAura(host.readableBaselineFrame, best.aura, best.spellID)
end

local function createTestFrame(host)
    local frame = CreateFrame("Frame", nil, host.layer)
    placeAtPortrait(frame, host)
    frame:SetFrameStrata(host.strata)
    frame:SetFrameLevel((host.smallBaseLevel or 0) + 900)
    local icon = frame:CreateTexture(nil, "OVERLAY")
    icon:SetAllPoints(frame)
    icon:SetTexCoord(0, 1, 0, 1)
    applyIconMask(host, frame, icon)
