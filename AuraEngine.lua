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
    pet = { 0.25, 1 },
    party1 = { 0.25, 1 }, party2 = { 0.25, 1 },
    party3 = { 0.25, 1 }, party4 = { 0.25, 1 },
    target = { 3, -0.75 },
    focus = { 3, -0.75 },
    targettarget = { 0.25, 1 },
    focustarget = { 0.25, 1 },
}
local function currentPixelFactor()
    if not PixelUtil then return 0 end
    local getter,known=R.ReadAuraField(PixelUtil,"GetPixelToUIUnitFactor")
    if not known then return false end
    if type(getter)~="function" then return 0 end
    local ok,factor=pcall(getter)
    if ok and R.CanAccess(factor) and type(factor)=="number" and factor>0 and factor<math.huge then return factor end
    return false
end

local function timerOpticalOffset(text, unit, factor)
    local offset = timerInkOffsets[unit]
    if factor==nil then factor=currentPixelFactor() end
    if not offset or factor==0 then return 0,0,true end
    if not factor then return 0,0,false end
    local scaleGetter,known = R.ReadAuraField(text,"GetEffectiveScale")
    if not known then return 0, 0, false end
    if type(scaleGetter) ~= "function" then return 0, 0, true end
    local scaleOK, scale = pcall(scaleGetter, text)
    if not scaleOK or not R.CanAccess(scale) or type(scale) ~= "number"
        or scale ~= scale or scale <= 0 or scale == math.huge then return 0, 0, false end
    return offset[1] * factor / scale, offset[2] * factor / scale, true
end

local function matchesOffset(actual, requested)
    return actual == requested or math.abs(actual - requested) <= math.max(2^-150, math.abs(requested)*2^-24)
end

-- Validate the requested corners even if an earlier post-write read was denied.
-- Some clients omit these getters. Once a receiver exposes one, a temporary
-- absence is unknown until the next safe verification.
local function anchorsChanged(region, relativeTo, dx, dy, receipt, key)
    local count, get = region.GetNumPoints, region.GetPoint
    if not R.CanAccess(count) or not R.CanAccess(get) then return nil end
    if type(count) ~= "function" or type(get) ~= "function" then
        if receipt[key] then return nil end
        return false
    end
    receipt[key] = true
    local n = count(region)
    if not R.CanAccess(n) or type(n) ~= "number" or n < 0 or n > 32 or n % 1 ~= 0 then return nil end
    if n ~= 2 then return true end
    local firstCorner
    for i = 1, 2 do
        local corner, ref, relativeCorner, x, y = get(region, i)
        if not R.CanAccess(corner) or not R.CanAccess(ref) or not R.CanAccess(relativeCorner)
            or not R.CanAccess(x) or not R.CanAccess(y) or type(corner) ~= "string"
            or type(relativeCorner) ~= "string" or type(x) ~= "number" or type(y) ~= "number" then return nil end
        if (corner ~= "TOPLEFT" and corner ~= "BOTTOMRIGHT") or corner == firstCorner or relativeCorner ~= corner then return true end
        firstCorner = corner
        if ref ~= relativeTo then
            if ref ~= nil and relativeTo ~= nil then return true end
            local parent = region:GetParent()
            if not R.CanAccess(parent) then return nil end
            if (ref or parent) ~= (relativeTo or parent) then return true end
        end
        -- Native anchors can round Lua offsets to binary32.
        if not matchesOffset(x,dx) or not matchesOffset(y,dy) then return true end
    end
    return false
end

local function observedChange(check,...)
    local ok,changed=pcall(check,...)
    if ok then return changed end
end

local function labelPropertyChanged(text, method, wanted, receipt)
    local getter = text[method]
    if not R.CanAccess(getter) then return nil end
    if type(getter) ~= "function" then
        if receipt[method] then return nil end
        return false
    end
    receipt[method] = true
    if method == "GetTextColor" then
        local r,g,b,a=getter(text)
        if R.CanAccess(r) and R.CanAccess(g) and R.CanAccess(b) and R.CanAccess(a)
            and type(r)=="number" and type(g)=="number" and type(b)=="number" and (a==nil or type(a)=="number") then
            return r~=1 or g~=1 or b~=1 or (a~=nil and a~=1)
        end
    else
        local value=getter(text)
        if R.CanAccess(value) and type(value)=="string" then return value~=wanted end
    end
end

local function setAlignmentState(cooldown,host,state)
    cooldown._bjarkiAlignmentState=state
    local pending=host._pendingClockLayouts
    if state=="centered" then
        if pending and pending[cooldown] then
            pending[cooldown]=nil
            if not next(pending) then host._pendingClockLayouts=nil end
        end
    else
        if not pending then pending={};host._pendingClockLayouts=pending end
        pending[cooldown]=true
    end
end

local function alignmentChanged(cooldown, text, receipt)
    local clock = observedChange(anchorsChanged, cooldown, receipt.anchor, 0, 0, receipt, "clockReadable")
    local label = observedChange(anchorsChanged, text, cooldown, receipt.dx, receipt.dy, receipt, "labelReadable")
    local h = observedChange(labelPropertyChanged, text, "GetJustifyH", "CENTER", receipt)
    local v = observedChange(labelPropertyChanged, text, "GetJustifyV", "MIDDLE", receipt)
    local color = observedChange(labelPropertyChanged, text, "GetTextColor", nil, receipt)
    if clock or label or h or v or color then return true end
    if clock ~= nil and label ~= nil and h ~= nil and v ~= nil and color ~= nil then return false end
end

local function acceptedLayout(result)
    return R.CanAccess(result) and result~=false
end

local function alignCountdown(cooldown, host, routine, verifyLayout, pixelFactor)
    -- Operate only on the addon-created countdown, never read its text/time.
    -- Layout may be unavailable after secure initialization; retry at the next
    -- existing out-of-combat lifecycle boundary rather than attaching scripts
    -- to forbidden aura buttons or polling secret-valued geometry.
    local combat, readable = R.SafeBool(InCombatLockdown)
    if not readable or combat then
        if cooldown._bjarkiAlignmentState ~= "centered" then setAlignmentState(cooldown,host,"deferred") end
        return
    end
    local getter=R.ReadAuraField(cooldown,"GetCountdownFontString")
    local ok,text=pcall(getter,cooldown)
    if not ok or not R.CanAccess(text) or not text then
        setAlignmentState(cooldown,host,"label-unavailable")
        return
    end

    if R.SMALL_UNITS[host.unit] or host.unit == "pet" or R.PARTY_UNITS[host.unit] then
        local getFont=R.ReadAuraField(text,"GetFont")
        local setFont=R.ReadAuraField(text,"SetFont")
        local fontOK, file, size, flags = pcall(getFont, text)
        if fontOK and R.CanAccess(file) and R.CanAccess(size) and R.CanAccess(flags)
            and type(file) == "string" and type(size) == "number"
            and size == size and size > 2 and size < 100 then
            local saved = cooldown._bjarkiCompactFont
            if not saved or saved.text ~= text or saved.file~=file or saved.flags~=(flags or "")
                or (size~=saved.size and size~=saved.wanted and size~=saved.storedSize) then
                saved = {text=text, file=file, size=size, wanted=math.max(1, size-2), flags=flags or ""}
                cooldown._bjarkiCompactFont = saved
            end
            if setFont and size~=saved.wanted and size~=saved.storedSize then
                local wrote,result=pcall(setFont,text,saved.file,saved.wanted,saved.flags)
                if wrote and acceptedLayout(result) then
                    local found,face,stored=pcall(getFont,text)
                    if found and R.CanAccess(face) and face==file and R.CanAccess(stored)
                        and type(stored)=="number" and stored~=saved.size then saved.storedSize=stored end
                end
            end
        end
    end

    -- Keep the cooldown/swipe on its prior native reference. Only the label
    -- gets this ink-centering correction; the image's separate clipping mask
    -- never changes countdown values, formatting or swipe geometry.
    local dx,dy,scaleKnown=timerOpticalOffset(text,host.unit,pixelFactor)
    local anchor=host.portraitMask or host.portrait
    local saved=cooldown._bjarkiAlignment
    if not scaleKnown and saved and saved.text==text then dx,dy=saved.dx,saved.dy end
    if routine and saved and saved.text==text and saved.anchor==anchor and saved.dx==dx and saved.dy==dy then
        local changed = false
        if verifyLayout ~= false then changed = alignmentChanged(cooldown, text, saved) end
        if not changed then
            if changed == nil then setAlignmentState(cooldown,host,"verification-pending")
            else setAlignmentState(cooldown,host,scaleKnown and "centered" or "scale-unavailable") end
            return
        end
    end
    local wrote,centered=pcall(function()
        if not acceptedLayout(cooldown:ClearAllPoints()) or not acceptedLayout(cooldown:SetAllPoints(anchor))
            or not acceptedLayout(text:ClearAllPoints()) then return false end
        if dx == 0 and dy == 0 then
            if not acceptedLayout(text:SetAllPoints(cooldown)) then return false end
        else
            if not acceptedLayout(text:SetPoint("TOPLEFT",cooldown,"TOPLEFT",dx,dy))
                or not acceptedLayout(text:SetPoint("BOTTOMRIGHT",cooldown,"BOTTOMRIGHT",dx,dy)) then return false end
        end
        if not acceptedLayout(text:SetJustifyH("CENTER")) or not acceptedLayout(text:SetJustifyV("MIDDLE")) then return false end
        -- Preserve the separately calibrated primary font size; recolor
        -- only the addon-owned label to neutral white.
        return not text.SetTextColor or acceptedLayout(text:SetTextColor(1,1,1,1))
    end)
    if wrote and centered then
        if not saved or saved.text ~= text then saved = {text=text} end
        saved.anchor, saved.dx, saved.dy = anchor, dx, dy
        cooldown._bjarkiAlignment = saved
        local changed = alignmentChanged(cooldown, text, saved)
        if changed then
            setAlignmentState(cooldown,host,"layout-unavailable")
        elseif changed == nil then
            setAlignmentState(cooldown,host,"verification-pending")
        else
            setAlignmentState(cooldown,host,scaleKnown and "centered" or "scale-unavailable")
        end
    else
        setAlignmentState(cooldown,host,"layout-unavailable")
    end
end

local function countdownVisibility(cooldown)
    local getter,known=R.ReadAuraField(cooldown,"IsVisible")
    if known and not getter then getter,known=R.ReadAuraField(cooldown,"IsShown") end
    if known then return R.SafeBool(getter,cooldown) end
    return nil,false
end

local function alignVisibleCountdown(cooldown,host,verifyLayout,pixelFactor)
    -- Only visible out-of-combat clocks need physical alignment.
    local shown,readable=countdownVisibility(cooldown)
    if not readable or not shown then
        setAlignmentState(cooldown,host,readable and "hidden" or "visibility-unavailable")
        return
    end
    alignCountdown(cooldown,host,true,verifyLayout~=false or cooldown._bjarkiAlignmentState~="centered",pixelFactor)
end

local function applyClockFormat(cooldown, routine)
    local decimals=R.db and R.db.showDecimals==true
    local thresholdEpoch=cooldown._bjarkiThresholdEpoch
    if routine and cooldown._bjarkiFormattedDecimals==decimals
        and (not thresholdEpoch or thresholdEpoch==R.countdownFormatterEpoch) then return end
    local ok,applied,backend=pcall(R.ApplyCountdownFormat,cooldown)
    if ok and applied==true then
        cooldown._bjarkiFormattedDecimals=decimals
        cooldown._bjarkiThresholdEpoch=backend=="threshold" and R.countdownFormatterEpoch or nil
    else
        cooldown._bjarkiFormattedDecimals=nil
    end
end

local function applyClockPreferences(cooldown,routine)
    local swipe=R.db and R.db.showSwipe==true
    if not routine or cooldown._bjarkiSwipe~=swipe then
        local setter,known=R.ReadAuraField(cooldown,"SetDrawSwipe")
        if known and setter then
            local ok,result=pcall(setter,cooldown,swipe)
            if ok and R.CanAccess(result) and result~=false then cooldown._bjarkiSwipe=swipe
            else cooldown._bjarkiSwipe=nil end
        end
    end
    applyClockFormat(cooldown,routine)
end

local function configureCooldown(cooldown, host)
    if cooldown.SetMinimumCountdownDuration then cooldown:SetMinimumCountdownDuration(0) end
    cooldown:SetAllPoints()
    if cooldown.SetUsingParentLevel then cooldown:SetUsingParentLevel(true) end
    if cooldown.SetReverse then cooldown:SetReverse(true) end
    if cooldown.SetDrawBling then cooldown:SetDrawBling(false) end
    if cooldown.SetDrawEdge then cooldown:SetDrawEdge(false) end
    applyClockPreferences(cooldown,false)
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
    return cooldown
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
        if ok and R.CanAccess(durationObject) and durationObject ~= nil then
            local startOK, startTime = pcall(function() return durationObject:GetStartTime() end)
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

    local original = candidates
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
    end

    local best
    local unique = true
    if #candidates == 1 then
        -- A strictly later readable start requires no occurrence-ID tie break.
        best = candidates[1]
    else
        for _, candidate in ipairs(candidates) do
            if type(candidate.auraInstanceID) ~= "number" then return nil, false end
            if not best or candidate.auraInstanceID > best.auraInstanceID then
                best, unique = candidate, true
            elseif candidate.auraInstanceID == best.auraInstanceID then
                unique = false
            end
        end
    end
    if byApplicationTime and not unique then return nil, false end
    -- The native second ribbon sorts occurrences, even in lanes whose main
    -- presenter sorts by application time. Record a positive disagreement
    -- only from this election's readable candidates.
    local first, second, distinctRunner, ordered = nil, nil, nil, true
    for _, candidate in ipairs(original) do
        local id = candidate.auraInstanceID
        if candidate.tier ~= best.tier or type(id) ~= "number" then
            ordered = false
        elseif not first or id > first.auraInstanceID then
            second, first = first, candidate
        elseif id == first.auraInstanceID or (second and id == second.auraInstanceID) then
            ordered = false
        elseif not second or id > second.auraInstanceID then
            second = candidate
        end
        if type(id) == "number" and candidate.spellID ~= best.spellID
            and (not distinctRunner or (byApplicationTime and candidate.appliedAt > distinctRunner.appliedAt)
                or ((not byApplicationTime or candidate.appliedAt == distinctRunner.appliedAt)
                    and id > distinctRunner.auraInstanceID)) then
            distinctRunner = candidate
        end
    end
    if ordered and first and second then
        best.nativeFirstMismatch = first.auraInstanceID ~= best.auraInstanceID
        best.nativeOrderMismatch = byApplicationTime and distinctRunner and second.auraInstanceID ~= distinctRunner.auraInstanceID
        best.nativeRepeatsWinner = second.spellID == best.spellID
        best.runnerSpellID = distinctRunner and distinctRunner.spellID
        best.runnerInstanceID = distinctRunner and distinctRunner.auraInstanceID
    end
    return best, true
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

-- The generic harmful fallback must not promote a stream of known lower-tier
-- debuffs. This is a conservative, short-circuiting read: a single unrelated,
-- inaccessible or unterminated aura preserves the native fallback. Most
-- refreshes read only the first harmful entry (or one nil terminator).
local function onlyReadableExcludedHarmful(unit)
    local excluded = R.GENERIC_EXCLUDED_HARMFUL
    if not excluded or not C_UnitAuras
        or type(C_UnitAuras.GetAuraDataByIndex) ~= "function" then return false end
    local sawExcluded = false
    for index = 1, AURA_SCAN_LIMIT do
        local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex,
            unit, index, "HARMFUL|INCLUDE_NAME_PLATE_ONLY")
        if not ok or not R.CanAccess(aura) then return false end
        if aura == nil then return sawExcluded end
        local spellID, readable = R.ReadAuraField(aura, "spellId")
        if not readable or type(spellID) ~= "number" or not excluded[spellID] then
            return false
        end
        sawExcluded = true
    end
    return false
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

-- The main helper and the secondary ranker use the same direct player
-- occurrences even when the indexed list omits a Welcoming Campfire.
function R.GetPlayerCampfireWitnesses(reads)
    if reads and reads.playerCampfires then return reads.playerCampfires end
    local found = {auras={}, available=false, readable=false}
    for _, spellID in ipairs(WELCOMING_CAMPFIRE_DIRECT_IDS) do
        local aura, readable, available = getReadablePlayerAuraBySpellID(spellID)
        found.readable = found.readable or readable
        found.available = found.available or available
        if aura then found.auras[#found.auras+1] = {aura=aura, spellID=spellID} end
    end
    if reads then reads.playerCampfires = found end
    return found
end

local function scanReadableHonorlessWinner(unit, reads)
    local tier = findTierByKey("HonorlessTarget")
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
            seenInstances[auraInstanceID] = spellID
        elseif seenInstances[auraInstanceID] ~= spellID then
            return false
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

    -- Elect over the full readable Honorless/Campfire/Flag candidate set. The secure lane
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
    -- witness joins the SAME HonorlessTarget election instead of short-circuiting it.
    if unit == "player" then
        local direct = R.GetPlayerCampfireWitnesses(reads)
        meta.welcomingDirect, meta.welcomingReadable = direct.available, direct.readable
        for _, witness in ipairs(direct.auras) do
            if not addCandidate(witness.aura, witness.spellID, true) then
                return nil, false, meta
            end
        end
    end

    meta.welcomingReadable = meta.welcomingReadable or complete
    if #candidates == 0 then return nil, true, meta end

    local best, ordered = electReadableCandidate(candidates, false)
    return best, ordered, meta
end

-- Share one guarded attempt per filter for this update only. A false entry
-- means unknown, including a failed read or exhaustion of the bounded scan.
local function exactTierList(reads, filter)
    if reads[filter] ~= nil then return reads[filter] end
    reads[filter] = false
    if not C_UnitAuras or not C_UnitAuras.GetAuraDataByIndex then return end

    local list = {auras={}, spellIDs={}}
    for index = 1, AURA_SCAN_LIMIT do
        local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, reads.unit, index, filter)
        if not ok or not R.CanAccess(aura) then return end
        if aura == nil then
            reads[filter] = list
            return list
        end
        local spellID, readable = R.ReadAuraField(aura, "spellId")
        if not readable or type(spellID) ~= "number" then return end
        list.auras[index], list.spellIDs[index] = aura, spellID
    end
end

local function scanLatestReadableExactTierAura(reads, tierKey, filter)
    local tier = findTierByKey(tierKey)
    if not tier or not tier.spellIDs then return nil, false, false end
    local list = exactTierList(reads, filter)
    if not list then return nil, false, false end
    local candidates = {}
    for index, spellID in ipairs(list.spellIDs) do
        if tier.spellIDs[spellID] then
            candidates[#candidates + 1] = readableCandidate(reads.unit, list.auras[index], spellID, tier)
        end
    end
    local best, electionReadable = electReadableCandidate(candidates, usesApplicationTime(tier))
    return best, true, electionReadable
end

local function scanReadableHostileHelpful(unit, reads)
    if not C_UnitAuras or not C_UnitAuras.GetAuraDataByIndex then
        return nil, false, 0, false, false
    end

    local candidates, needsPlain, seen = {}, {}, {}
    local count, allIdentitiesReadable, complete = 0, true, true
    local inclusiveFilter = "HELPFUL|INCLUDE_NAME_PLATE_ONLY"
    local function scan(filter)
        local inclusive = filter == inclusiveFilter
        local list = {auras={},spellIDs={}}
        local readable, ended = true, false
        for index = 1, AURA_SCAN_LIMIT do
            local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, index, filter)
            if not ok then readable = false; break end
            if not R.CanAccess(aura) then
                readable = false
            elseif aura == nil then
                ended = true; break
            else
                if inclusive then count = count + 1 end
                local spellID = R.ReadAuraField(aura, "spellId")
                if type(spellID) ~= "number" then
                    readable = false
                else
                    list.auras[#list.auras+1], list.spellIDs[#list.spellIDs+1] = aura, spellID
                    local tier = findHelpfulTierForSpell(spellID)
                    local matches = tier and tier.filter == filter and (inclusive or needsPlain[spellID])
                    if inclusive and tier and tier.filter == "HELPFUL" then
                        local only = R.ReadAuraField(aura, "isNameplateOnly")
                        if type(only) == "boolean" then
                            matches = not only
                        else
                            needsPlain[spellID] = true
                        end
                    end
                    if matches then
                        local candidate = readableCandidate(unit, aura, spellID, tier)
                        local occurrence = candidate.auraInstanceID or aura
                        if not seen[occurrence] then
                            candidates[#candidates+1] = candidate
                            seen[occurrence] = true
                        end
                    end
                end
            end
        end
        -- A partial list can supply a positive, never an absence or authority.
        reads[filter] = readable and ended and list or false
        allIdentitiesReadable = allIdentitiesReadable and readable
        complete = complete and ended
    end
    scan(inclusiveFilter)
    if next(needsPlain) then scan("HELPFUL") end

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
    frame:Hide()
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

local function hideOwned(frame)
    return frame:Hide()
end

local function clearFrameCooldown(frame)
    clearReadableCooldown(frame.cooldown)
end

local function clearFrameIcon(frame)
    if frame.icon then frame.icon:SetTexture(nil) end
end

local function hideReadableExact(frame)
    if not frame then return end
    -- These cleanups may involve restricted members. Each is independent of
    -- revoking the helper itself, which is a sibling of the native anchor.
    pcall(clearFrameCooldown,frame)
    pcall(clearFrameIcon,frame)
    local ok,result=pcall(hideOwned,frame)
    return ok and R.CanAccess(result) and result~=false
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

-- The two public LoC occurrences are independent of aura instances. Preserve a
-- confirmed occurrence across native list reorders or fresh duration wrappers.
local function sameInterrupt(old, record)
    if not old or not record or old.spellID ~= record.spellID or old.icon ~= record.icon
        or old.auraInstanceID ~= record.auraInstanceID or old.lockoutSchool ~= record.lockoutSchool
        or old.startTime ~= record.startTime or old.requiresPlayer ~= record.requiresPlayer
        or old.duration ~= record.duration or not R.SameInterruptDeadline(old.expires,record.expires)
        or not R.SameSchoolInterruptGroup(old,record) then return false end
    return old.startTime ~= nil or old.auraInstanceID ~= nil or old.expires ~= nil
        or rawequal(old.durationObject, record.durationObject)
end

local function keepInterrupt(record, first, second)
    local old
    if sameInterrupt(first, record) then old = first
    elseif sameInterrupt(second, record) then old = second end
    if not old then return record, false end
    local rebindClock = not rawequal(old.durationObject, record.durationObject)
    old.durationObject = record.durationObject
    old.ownUnit = record.ownUnit
    old.bridgeWatch = record.bridgeWatch
    return old, rebindClock
end

local function scheduleInterruptExpiry(host, first, second)
    local expires = first.expires
    if second and second.expires then expires = math.min(expires or second.expires, second.expires) end
    if expires ~= host._schoolInterruptDeadline then
        host._schoolInterruptDeadline, host._schoolInterruptWake = expires, nil
        host._schoolInterruptEarlyWake = nil
    end
    if host._schoolInterruptWake then return end
    if not expires or not C_Timer or type(C_Timer.After) ~= "function" then return end
    local timed, now = pcall(GetTime)
    if timed and R.CanAccess(now) and type(now) == "number" and now < expires then
        local ticket, scheduling = {}, true
        host._schoolInterruptWake = ticket
        local ok, result = pcall(C_Timer.After, expires-now, function()
            if R.hosts[host.unit] ~= host or host._schoolInterruptWake ~= ticket then return end
            host._schoolInterruptWake = nil
            -- An inline timer implementation cannot recursively schedule itself.
            -- An ordinary early delivery rechecks and rearms the remaining time.
            if scheduling then return end
            local okTime, observed = pcall(GetTime)
            if okTime and R.CanAccess(observed) and type(observed) == "number" and observed < expires then
                if not host._schoolInterruptEarlyWake then
                    host._schoolInterruptEarlyWake = true
                    scheduleInterruptExpiry(host,host._schoolInterrupt,host._secondSchoolInterrupt)
                end
                return
            end
            host._schoolInterruptChecked = nil
            R.Refresh(host.unit)
        end)
        scheduling = false
        if (not ok or not R.CanAccess(result) or result == false) and host._schoolInterruptWake == ticket then
            host._schoolInterruptWake = nil
        end
    end
end

local function discardInterruptWatches(host)
    host._schoolInterruptAliasPending,host._schoolInterruptAliasOverflow,host._schoolInterruptAliasGUID=nil,nil,nil
    host._schoolInterruptOverflowSweep=nil
    host._schoolInterruptRetries=nil
end

function R.InterruptUsesPlayer(host)
    return host and (host._schoolInterruptRankUsesPlayer or (host._schoolInterrupt and host._schoolInterrupt.requiresPlayer)
        or (host._secondSchoolInterrupt and host._secondSchoolInterrupt.requiresPlayer))
end

function R.NoteUnresolvedInterruptAlias(host, sender)
    local guid=R.SafeString(UnitGUID,host.unit)
    if guid and guid~="" then
        if host._schoolInterruptAliasGUID and guid~=host._schoolInterruptAliasGUID then discardInterruptWatches(host) end
        host._schoolInterruptAliasGUID=guid
    end
    local aliases=host._schoolInterruptAliasPending or {}
    for _,token in ipairs(aliases) do if token==sender then return end end
    -- Keep this bounded in crowded nameplate scenes. Preserve the player
    -- token, whose own LoC interface can add evidence after identity settles.
    if #aliases==8 then
        table.remove(aliases,aliases[1]=="player" and 2 or 1)
        host._schoolInterruptAliasOverflow=true
    end
    aliases[#aliases+1]=sender
    host._schoolInterruptAliasPending=aliases
end

local function updateSchoolInterrupt(host, enabled, refresh, change, bindingChanged)
    local frame = host.schoolInterruptFrame
    local bindingBarrier = bindingChanged or host._schoolInterruptSettling
    host._schoolInterruptSettling = nil
    if not frame then return false, bindingBarrier end
    local previous, previousSecond = host._schoolInterrupt, host._secondSchoolInterrupt
    local guid
    local targetOrFocus = host.unit == "target" or host.unit == "focus"
    if enabled and targetOrFocus then
        local token, known = R.ReadAuraField(host.unitFrame,"unit")
        enabled = known and token == host.unit
    end
    if enabled and (previous or host._schoolInterruptAliasPending) and host.unit ~= "player" then
        guid = R.SafeString(UnitGUID, host.unit)
        if guid == "" then guid = nil end
        -- Target and Focus have explicit binding, settling, removal and native
        -- frame barriers. A bounded timer between those events need not be
        -- rediscovered on every unrelated aura update during GUID restrictions.
        if previous and (guid ~= host._schoolInterruptGUID or (not guid and not targetOrFocus)) then refresh = true end
        if guid and ((previous and host._schoolInterruptGUID and guid ~= host._schoolInterruptGUID)
            or (host._schoolInterruptAliasGUID and guid ~= host._schoolInterruptAliasGUID)) then bindingBarrier=true end
    end
    local observed = change and change.host == host
    if enabled and R.InterruptUsesPlayer(host) and not R.SafeBool(UnitIsUnit,host.unit,"player") then
        bindingBarrier=true
    end
    if bindingBarrier then
        discardInterruptWatches(host)
        refresh=true
    end
    if observed and enabled then
        if change.unresolvedSelf then R.NoteUnresolvedInterruptAlias(host,"player") end
        if change.alias then R.NoteUnresolvedInterruptAlias(host,change.alias) end
    end
    local aliases = host._schoolInterruptAliasPending
    if enabled and aliases and not observed then
        -- After the bounded native retries, only recheck identity. Recovery
        -- to a true alias warrants a fresh scan of this host's own recipient.
        for index = #aliases, 1, -1 do
            local same, known = R.SafeBool(UnitIsUnit,host.unit,aliases[index])
            if known then
                table.remove(aliases,index)
                if same or host._schoolInterruptAliasOverflow then refresh = true end
            end
        end
        if #aliases == 0 then
            host._schoolInterruptAliasPending,host._schoolInterruptAliasGUID=nil,nil
            host._schoolInterruptAliasOverflow,host._schoolInterruptOverflowSweep=nil,nil
        end
    end
    local unbounded = (previous and not previous.expires) or (previousSecond and not previousSecond.expires)
    if enabled and host._schoolInterruptDeadline and not (observed or refresh) then
        local ok, now = pcall(GetTime)
        refresh = ok and R.CanAccess(now) and type(now) == "number" and now >= host._schoolInterruptDeadline
    end
    local opportunity = refresh or observed or not host._schoolInterruptChecked
    local retries = host._schoolInterruptRetries or 0
    if enabled and not opportunity and retries == 0 and not unbounded then
        local overflowChanged
        if host._schoolInterruptAliasOverflow then
            overflowChanged,host._schoolInterruptOverflowSweep=R.ProbeSchoolInterrupt(host.unit,
                host._schoolInterruptOverflowSweep,previous,previousSecond)
        end
        if not overflowChanged then
            if previous and host._schoolInterruptDeadline and not host._schoolInterruptWake then
                scheduleInterruptExpiry(host,previous,previousSecond)
            end
            return false, bindingBarrier
        end
    end
    host._schoolInterruptOverflowSweep=nil
    host._schoolInterruptChecked = enabled or nil
    local record, second, complete, rankUsesPlayer
    if enabled then
        if observed then record, second, complete, rankUsesPlayer = change.record, change.second, change.complete, change.rankUsesPlayer
        else
            local unresolvedSelf
            record, second, complete, unresolvedSelf, rankUsesPlayer = R.GetSchoolInterrupt(host.unit)
            if unresolvedSelf and (previous or record or retries>0 or bindingBarrier or host._schoolInterruptAliasPending) then
                R.NoteUnresolvedInterruptAlias(host,"player")
                complete = false
            end
        end
    end
    host._schoolInterruptRankUsesPlayer = rankUsesPlayer
    local retryBudget = opportunity and 2 or math.max(0, retries - 1)
    host._schoolInterruptRetries = enabled and (complete == false or host._schoolInterruptAliasPending)
        and retryBudget or nil
    if record then
        if host.unit ~= "player" and not previous then
            guid = R.SafeString(UnitGUID, host.unit)
            if guid == "" then guid = nil end
        end
        local sameVictim = host.unit == "player" or (guid and guid ~= "" and guid == host._schoolInterruptGUID)
        local changedObject, changedSecondObject
        -- With an unreadable GUID the new observation belongs to the current
        -- token. Reuse only a known cleared art-only receiver, identical
        -- numeric output, or exactly the same bound native clock.
        local sameSink = targetOrFocus and not guid and not host._schoolInterruptGUID and not bindingBarrier
            and sameInterrupt(previous,record)
            and ((host._schoolInterruptClockSource == "numeric" and record.expires)
                or (host._schoolInterruptClockSource == "object" and record.durationObject
                    and rawequal(host._schoolInterruptClockObject,record.durationObject))
                or (not record.expires and not record.durationObject and not host._schoolInterruptClockPending
                    and not host._schoolInterruptClockSource))
        -- Both rows have been freshly read from the currently bound token.
        -- In a sealed GUID window preserve identical public observations only
        -- between binding barriers and with the same accepted clock output.
        if (sameVictim or sameSink) and not bindingBarrier then
            record, changedObject = keepInterrupt(record, previous, previousSecond)
            second, changedSecondObject = keepInterrupt(second, previous, previousSecond)
        end
        local sameMain = not bindingBarrier and (record == previous or sameSink)
        local retryClock = (host._schoolInterruptClockSource=="object"
            and not rawequal(host._schoolInterruptClockObject,record.durationObject))
            or (host._schoolInterruptClockPending and (opportunity or retries > 0))
        local painted = sameMain
        if not sameMain or retryClock then
            painted = sameMain or setReadableSpellIcon(frame, record.spellID, record)
            if painted then
                local timed, source
                painted, timed, source = R.SetSchoolInterruptClock(frame.cooldown, record)
                host._schoolInterruptClockSource = painted and source or nil
                host._schoolInterruptClockObject = painted and source == "object" and record.durationObject or nil
                host._schoolInterruptClockPending = painted and not timed and (record.expires or record.durationObject) and true or nil
                if host._schoolInterruptClockPending then host._schoolInterruptRetries = retryBudget end
            end
            if painted and not sameMain then
                local ok, shown = pcall(frame.Show, frame)
                painted = ok and R.CanAccess(shown) and shown ~= false
            end
        end
        if painted then
            host._schoolInterrupt, host._secondSchoolInterrupt = record, second
            host._schoolInterruptGUID, host._schoolInterruptHidePending = guid, nil
            scheduleInterruptExpiry(host, record, second)
            local secondaryObjectChanged = host._secondaryInterruptClockSource=="object"
                and ((changedObject and host._secondaryAuraSpellID==record.spellID)
                    or (changedSecondObject and second and host._secondaryAuraSpellID==second.spellID))
            return previous ~= record or previousSecond ~= second or retryClock or secondaryObjectChanged, bindingBarrier
        end
    end
    host._schoolInterrupt, host._secondSchoolInterrupt, host._schoolInterruptGUID = nil, nil, nil
    host._schoolInterruptDeadline, host._schoolInterruptWake, host._schoolInterruptClockPending = nil, nil, nil
    host._schoolInterruptClockSource, host._schoolInterruptClockObject, host._schoolInterruptEarlyWake = nil, nil, nil
    if previous or record or host._schoolInterruptHidePending then
        host._schoolInterruptHidePending = not hideReadableExact(frame) or nil
        if record or host._schoolInterruptHidePending then host._schoolInterruptChecked = nil end
        return true, bindingBarrier
    end
    return false, bindingBarrier
end

function R.RecheckSchoolInterruptLinks(host,current,auraUnit)
    local first,second,complete,unresolved,playerRank=R.GetSchoolInterrupt(host.unit,current,auraUnit)
    updateSchoolInterrupt(host,true,false,{host=host,record=first,second=second,complete=complete,
        unresolvedSelf=unresolved,rankUsesPlayer=playerRank})
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
        spellID = candidate.spellID,
        auraInstanceID = candidate.auraInstanceID,
        runnerSpellID = candidate.runnerSpellID, runnerInstanceID = candidate.runnerInstanceID,
        nativeFirstMismatch = candidate.nativeFirstMismatch == true,
        nativeOrderMismatch = candidate.nativeOrderMismatch == true,
        nativeRepeatsWinner = candidate.nativeRepeatsWinner == true,
    }
    return true
end

-- A positive, independent form-state witness for hostile *players* only.
-- Opposite-faction HELPFUL identities can become inaccessible during CC,
-- but unit class and active primary power may remain readable. These are
-- public unit facts, not proof of a particular aura instance. Do not infer
-- any form when the class, power or alive state is unknown; do not reopen the
-- permanent-buff fallback (which would also admit Find Minerals).
local function updateObservedDruidForm(host, baseEnabled, hostilePlayer, presentedTier)
    host._formStateActive = false
    host._formStateSpellID = nil
    host._formStateReason = "ineligible"
    local frame = host and host.readableFormStateFrame
    if not frame then return end
    -- The static form sits just below SelfState. A lower readable aura can
    -- remain presented underneath it, while an elected SelfState or higher wins.
    if not baseEnabled or R.testMode or not hostilePlayer
        or (presentedTier and presentedTier.level >= R.TIER_BY_KEY.SelfState.level) then
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

-- Share the existing below-SelfState frame; Warrior proof has no Druid
-- relation/low-helpful gates and never claims an aura lane or clock.
local function updateFormState(host, baseEnabled, hostilePlayer, presentedTier)
    if baseEnabled and not R.testMode and R.ResolveWarriorStance then
        local result = R.ResolveWarriorStance(host.unit)
        if result.reason ~= "not-warrior" then
            host._formStateActive = false
            host._formStateSpellID = result.spellID
            host._formStateReason = result.source .. ":" .. result.reason
            if result.spellID then
                host._formStateActive = showStaticSpell(host.readableFormStateFrame, result.spellID)
                if not host._formStateActive then host._formStateReason = "presentation-failed" end
            else
                hideReadableExact(host.readableFormStateFrame)
            end
            return
        end
    end
    updateObservedDruidForm(host, baseEnabled, hostilePlayer, presentedTier)
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

local function updateReadableHarmfulTier(host, baseEnabled, tierKey, frameKey, prefix, exactReads)
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
    -- Applied stuns and silences are the two control categories whose
    -- native exact-ID filters have been observed to miss expected effects.
    -- A complete readable election may replace their native owner even when
    -- relation-based native filtering was nominally permitted. An incomplete
    -- scan leaves the native frame authoritative and makes no inference.
    local controlWitness = tierKey == "Stun" or tierKey == "InterruptSilence"
    if not controlWitness and not tier.directWitnessSpellIDs and not usesApplicationTime(tier)
        and R.ExactFilterAllowed(host.unit, false, tier.spellIDs, tier.allowNeverSecret) then
        clearReadableHarmfulTier(host, frameKey, prefix)
        return
    end

    local best, complete, electionReadable = scanLatestReadableExactTierAura(
        exactReads, tierKey, tier.filter
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
    host._hostileAuraInstanceID = nil
end

local function updateReadableHostile(host, baseEnabled, reads)
    if not host or not baseEnabled or R.testMode then
        clearReadableHostile(host)
        return nil
    end

    local best, authoritative, count, auraListComplete, electionReadable =
        scanReadableHostileHelpful(host.unit, reads)
    host._hostileReadable = authoritative
    host._hostileElectionReadable = electionReadable
    host._hostileAuraListComplete = auraListComplete
    host._hostileCount = count
    host._hostileSpellID = best and best.spellID or nil
    host._hostileTierKey = best and best.tier and best.tier.key or nil
    -- A second public projection may only claim a distinct aura once it can
    -- prove that the primary native/readable aura is the very same instance.
    host._hostileAuraInstanceID = best and best.auraInstanceID or nil
    host._hostileActive = false

    local frame = host.readableHostileFrame
    if not frame or not best then
        hideReadableExact(frame)
        return nil
    end
    -- A partial readable witness is useful only when it cannot compete with an
    -- eligible native owner of the same tier. It never suppresses that owner.
    if not authoritative and R.NativeExactContainerAllowed(host.unit, best.tier) then
        hideReadableExact(frame)
        return nil
    end

    host._hostileActive = showReadableTier(host, "readableHostileFrame", best, authoritative)
    if authoritative and host._hostileActive then return best.tier end
end

local function updateReadableDivineProtection(host, baseEnabled, hostileUnit, secureAllowed, exactReads)
    -- Same immunity tier, without a separate Divine Protection priority.
    local tier = findTierByKey("Immunity")
    host._divineProtectionSecureAllowed = secureAllowed and true or false
    host._divineProtectionReadable = false
    host._divineProtectionActive = false
    host._divineProtectionSpellID = nil

    local frame = host.readableDivineProtectionFrame
    if not frame or not baseEnabled or R.testMode or not hostileUnit or secureAllowed or not tier
        or host._readableTierOwners.Immunity
        or R.NativeExactContainerAllowed(host.unit, tier)
    then
        if frame then hideReadableExact(frame) end
        return
    end

    -- A positive lookup is not a complete election. Do not display Divine
    -- Protection above a different immunity aura whose native identity is
    -- unavailable: read all candidates and elect the actual latest member.
    local best, complete, readable = scanLatestReadableExactTierAura(
        exactReads, "Immunity", "HELPFUL"
    )
    local spellID = best and best.spellID or nil
    host._divineProtectionReadable = complete and readable
    host._divineProtectionSpellID = spellID
    if not complete or not readable or not best
        or not (BP.categories and BP.categories.buffs_divine_protection
            and BP.categories.buffs_divine_protection[spellID]) then
        hideReadableExact(frame)
        return
    end

    host._divineProtectionActive = showReadableTier(host,
        "readableDivineProtectionFrame", best, false)
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

local function updateReadableRecency(host, baseEnabled, tierKey, frameKey, prefix, exactReads)
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
        exactReads, tierKey, tier.filter
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
        host._honorlessReadable = false
        host._honorlessWinnerSpellID = nil
        host._honorlessWinnerInstanceID = nil
        host._honorlessRunnerSpellID, host._honorlessRunnerInstanceID = nil, nil
        host._welcomingCampfireReadable = false
        host._welcomingCampfireActive = false
        host._welcomingCampfireDirect = false
        host._welcomingCampfireDirectFound = false
        host._welcomingCampfirePresent = false
        host._welcomingCampfireAppliedAt = nil
        host._welcomingCampfireTimingSource = nil
    end
end

local function updateReadableWelcomingCampfire(host, baseEnabled, reads)
    if not host or not baseEnabled or R.testMode or host._readableTierOwners.HonorlessTarget then
        clearReadableWelcomingCampfire(host)
        return
    end

    local best, readable, meta = scanReadableHonorlessWinner(host.unit, reads)
    host._honorlessReadable = readable
    host._honorlessWinnerSpellID = best and best.spellID or nil
    host._honorlessWinnerInstanceID = best and best.auraInstanceID or nil
    host._honorlessRunnerSpellID = best and best.runnerSpellID or nil
    host._honorlessRunnerInstanceID = best and best.runnerInstanceID or nil
    host._welcomingCampfireReadable = meta and meta.welcomingReadable or false
    host._welcomingCampfireDirect = meta and meta.welcomingDirect or false
    host._welcomingCampfireDirectFound = meta and meta.welcomingDirectFound or false
    host._welcomingCampfirePresent = meta and meta.welcomingPresent or false
    host._welcomingCampfireAppliedAt = meta and meta.welcomingAppliedAt or nil
    host._welcomingCampfireTimingSource = meta and meta.welcomingTimingSource or nil
    host._welcomingCampfireActive = false

    -- The helper may suppress native HonorlessTarget only when complete
    -- readable recency establishes Campfire as this shared lane's true
    -- winner. A newer Honorless/flag aura keeps its native ownership.
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
    frame:Hide()
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

-- Secondary portrait/race fallback is isolated in SecondaryPortrait.lua.
-- Main portrait falls back directly to Blizzard's native class/model artwork.

local function hostStillCurrent(host)
    if not host or host._buildComplete ~= true or host._restorePending then return false,true end
    local portrait, mask, unitFrame, known = R.GetPortrait(host.unit)
    if not known then return false,false end
    return portrait == host.portrait and mask == host.portraitMask and unitFrame == host.unitFrame,true
end
R.IsCurrentPortraitHost = hostStillCurrent

local function nativeUnitTokenMatches(host)
    if host.unit ~= "player" and host.unit ~= "pet" and not R.PARTY_UNITS[host.unit] then
        return true
    end
    -- Native Player/Pet/Party frames may temporarily bind a vehicle, or the
    -- party Edit Mode preview may bind "player" to an unoccupied party slot.
    -- Only show a slot's real unit. No stale aura from an earlier party member.
    local binding,known = R.ReadAuraField(host.unitFrame,"unit")
    return known and binding == host.unit
end

local function hostHasSupportedBinding(host, tokenMatches)
    if tokenMatches == nil then tokenMatches = nativeUnitTokenMatches(host) end
    if not tokenMatches then return false end
    if R.PARTY_UNITS[host.unit] then
        local getter,available=R.ReadAuraField(host.unitFrame,"IsShown")
        if not available then return false end
        if getter then
            local visible, readable = R.SafeBool(getter, host.unitFrame)
            return readable and visible
        end
    end
    return true
end

local function turnOff(container, method)
    return container[method](container, false)
end

local function disableContainers(host)
    local pending = host._pendingContainerCleanup
    if not pending then
        pending = {}
        for _,container in ipairs(host.containers or {}) do
            pending[container] = {SetEnabled=true, SetShown=true}
        end
        host._pendingContainerCleanup = pending
    end
    for container,methods in pairs(pending) do
        for method in pairs(methods) do
            local ok,result = pcall(turnOff, container, method)
            if ok and R.CanAccess(result) and result~=false then methods[method]=nil end
        end
        if not next(methods) then pending[container]=nil end
    end
    return not next(pending)
end


local function sameAnchors(a,b,prefix)
    if not a or not b or #a>#b or (not prefix and #a~=#b) then return false end
    for i,point in ipairs(a) do
        for j=1,5 do if point[j]~=b[i][j] then return false end end
    end
    return true
end

local function finishRestore(host)
    host.reparented=false
    host._portraitRestore=nil
    return true
end

local function rememberFailedWrite(state,portrait)
    local ok,points=pcall(R.CapturePoints,portrait)
    state.observed=ok and points or nil
    return false
end

local function restoreNativePoints(host)
    if not host or not host.reparented then return true end
    local portrait = host.portrait
    local currentParent=portrait:GetParent()
    if not R.CanAccess(currentParent) then return false end
    local state,restored=host._portraitRestore,nil
    if currentParent~=host.layer then
        if currentParent~=host.originalParent or not state then
            return finishRestore(host) -- the physical owner has already changed
        end
        local current=R.CapturePoints(portrait)
        if not current then return false end
        if state.observed and not sameAnchors(current,state.observed) then
            return finishRestore(host) -- an external writer has superseded our interrupted replay
        end
        -- A failing point setter may have written its own point. Accept only
        -- the exact acknowledged prefix or that prefix plus the attempted
        -- point. A parent/clear write can retain its input or clear it.
        if state.point then
            if (#current~=state.point and #current~=state.point-1)
                or not sameAnchors(current,state.target,true) then return finishRestore(host) end
            restored=#current
        elseif sameAnchors(current,state.target) then
            return finishRestore(host)
        elseif #current==0 then
            restored=0
        elseif not sameAnchors(current,state.before) then
            return finishRestore(host)
        end
    else
        local before=R.CapturePoints(portrait)
        if not before then return false end
        local desired=host.originalPoints
        if host._portraitLayoutComplete then
            desired={}
            for i,existing in ipairs(before) do
                local point={unpack(existing,1,5)}
                if point[2]==host.layer then point[2]=host.originalParent end
                desired[i]=point
            end
        end
        state={before=before,target=desired}
        host._portraitRestore=state
        local ok,applied=pcall(portrait.SetParent,portrait,host.originalParent)
        if not ok or not R.CanAccess(applied) or applied==false then
            return rememberFailedWrite(state,portrait)
        end
    end
    local ok,applied=pcall(R.RestorePoints,portrait,state.target,state,restored)
    if not ok or applied==false then
        return rememberFailedWrite(state,portrait)
    end
    return finishRestore(host)
end

local function restorePortrait(host)
    local ok,restored=pcall(restoreNativePoints,host)
    return ok and restored==true
end

local ownedPresentations={
    "testFrame", "readableHostileFrame", "readableBaselineFrame",
    "readableHealingFrame", "readableSlowsFrame", "readableDoTsFrame",
    "readableDazedFrame", "readableForbearanceFrame", "readableStatusEffectsFrame",
    "readableResurrectionSicknessFrame", "readableDemoralizingFrame", "readablePassiveDebuffFrame",
    "readableBaselineHarmfulFrame", "readableNearbyHarmfulFrame", "readableBoostedRestFrame",
    "readableTrackingHarmfulFrame", "readableRootsFrame", "readableControlFrame",
    "readableStunFrame", "readableInterruptSilenceFrame", "schoolInterruptFrame", "readableWoundsFrame",
    "readableOffensiveHarmfulFrame", "readableWaitingToResurrectFrame", "readableDivineProtectionFrame",
    "readableGhostFrame", "readableFormStateFrame", "readableWelcomingCampfireFrame"
}

local function clearHostPresentation(host,reason,keepFoundation)
    host._schoolInterrupt, host._schoolInterruptGUID, host._schoolInterruptDeadline = nil, nil, nil
    host._secondSchoolInterrupt, host._schoolInterruptChecked = nil, nil
    host._schoolInterruptRankUsesPlayer=nil
    host._schoolInterruptRetries, host._schoolInterruptClockPending = nil, nil
    host._schoolInterruptWake, host._schoolInterruptAliasPending = nil, nil
    host._schoolInterruptAliasGUID, host._schoolInterruptAliasOverflow = nil, nil
    host._schoolInterruptOverflowSweep = nil
    host._schoolInterruptClockSource, host._schoolInterruptClockObject, host._schoolInterruptEarlyWake = nil, nil, nil
    host._schoolInterruptSettling = nil
    local done=host._revokedPresentation or {}
    host._revokedPresentation=done
    local function revoke(key,fn,object)
        if not key or not fn then return true end
        if not done[key] then
            local ok,result=pcall(fn,object,reason)
            done[key]=ok and R.CanAccess(result) and result~=false
        end
        return done[key]
    end
    -- The anchor owns the native groups; hiding it does not touch their
    -- unit, enabled state, or the separately parented native portrait.
    revoke(host.anchor,hideOwned,host.anchor)
    for key,owner in pairs(host._readableTierOwners or {}) do
        if revoke(owner.frame,hideReadableExact,owner.frame) then host._readableTierOwners[key]=nil end
    end
    for _,key in ipairs(ownedPresentations) do
        local frame=host[key]
        local hidden=revoke(frame,hideReadableExact,frame)
        if frame and frame==host.schoolInterruptFrame then host._schoolInterruptHidePending=not hidden or nil end
    end
    revoke("public",R.HideSecondaryPortrait,host)
    revoke("native",R.HideNativeSecondProbe,host)
    revoke("pet",R.HidePetSecondaryFallback,host)
    if not keepFoundation then revoke("foundation",R.HidePetFoundation,host) end
end

local function suspendHost(host,reason,forceRefresh,bindingChanged)
    host._staleBinding=true
    host._suspendedRefresh=host._suspendedRefresh or forceRefresh
    host._suspendedBindingChange=host._suspendedBindingChange or bindingChanged
    R.buildQueued=true
    clearHostPresentation(host,reason)
end
R.SuspendPortraitHost=suspendHost

local function presentationWrite(fn,object)
    if not fn then return true end
    local ok,result=pcall(fn,object)
    return ok and R.CanAccess(result) and result~=false
end

function R.DestroyHost(unit)
    local host = R.hosts[unit]
    if not host then return true end
    host._restorePending = true
    clearHostPresentation(host, "host-destroy")
    local combat,known=R.SafeBool(InCombatLockdown)
    if not known or combat then
        R.buildQueued = true
        return false
    end
    local containersReleased = disableContainers(host)
    if not restorePortrait(host) then
        R.buildQueued = true
        return false
    end
    if host.secondaryBadge and host._revokedPresentation.public==false then
        R.buildQueued=true
        return false
    end
    if not presentationWrite(R.ReleaseSecondaryPortrait,host)
        or not presentationWrite(R.ReleaseNativeSecondProbe,host)
        or not presentationWrite(R.ReleasePetSecondaryFallback,host) then
        R.buildQueued = true
        return false
    end
    if host.ownsLayer and host.layer then
        if not presentationWrite(hideOwned,host.layer) then
            local getter=R.ReadAuraField(host.layer,"IsShown")
            local shown,known=R.SafeBool(getter,host.layer)
            if not known or shown then
                R.buildQueued=true
                return false
            end
        end
        host.ownsLayer=false
    end
    if not containersReleased then
        R.buildQueued=true
        return false
    end
    R.hosts[unit] = nil
    return true
end

function R.DestroyAll()
    local combat,known=R.SafeBool(InCombatLockdown)
    if not known or combat then
        if not R.db or not R.db.enabled then
            for _,host in pairs(R.hosts) do
                host._restorePending=true
                clearHostPresentation(host,"host-destroy")
            end
        end
        R.forceRebuildQueued = true
        R.buildQueued = true
        return false
    end
    local restored = true
    for _, unit in ipairs(R.TRACKED_UNITS) do
        if not R.DestroyHost(unit) then restored = false end
    end
    return restored
end

-- An in-progress host is private to its constructor. Keep at most one build
-- failure per unit; ordinary UNIT_AURA refreshes must not accumulate abandoned
-- frame trees or spam errors. An explicit BuildAll (e.g. /bp on) retries.
local hostBuildFailures, hostBuildInProgress = {}, {}

local visibilityHooks = setmetatable({}, {__mode="k"})
local function observeSecondaryOwner(frame)
    local ok, hook = pcall(function() return frame.HookScript end)
    if not ok or not R.CanAccess(hook) or type(hook) ~= "function" then return end
    local state = visibilityHooks[frame]
    if not state then state = {}; visibilityHooks[frame] = state end
    local function currentHost(owner)
        for _, host in pairs(R.hosts) do
            if host.unitFrame == owner and host._buildComplete and not host._restorePending then
                return host
            end
        end
    end
    if not state.hide then
        state.hide = pcall(hook, frame, "OnHide", function(owner)
            state.pendingHost = nil
            local host = currentHost(owner)
            if not host then return end
            if host._staleBinding then
                clearHostPresentation(host,"native-frame-hidden")
                return
            end
            if R.HideSecondaryPortrait then R.HideSecondaryPortrait(host, "native-frame-hidden") end
            if R.HideNativeSecondProbe then R.HideNativeSecondProbe(host, "native-frame-hidden") end
            if R.HidePetSecondaryFallback then R.HidePetSecondaryFallback(host, "native-frame-hidden") end
        end)
    end
    if not state.show then
        state.show = pcall(hook, frame, "OnShow", function(owner)
            state.pendingHost = currentHost(owner)
            if not state.pendingHost or state.queued or not C_Timer or type(C_Timer.After) ~= "function" then return end
            state.queued = true
            local scheduled = pcall(C_Timer.After, 0, function()
                local host = state.pendingHost
                state.pendingHost, state.queued = nil, false
                if host and currentHost(owner) == host and R.SecondaryOwnerVisible(host) then
                    R.Refresh(host.unit,false,nil,true)
                    R.ApplyPresentation(host.unit,true,true)
                end
            end)
            if not scheduled then state.pendingHost, state.queued = nil, false end
        end)
    end
end

local function buildHost(unit, host)
    -- Events and commands can reach this boundary without going through BuildAll.
    if not R.db or not R.db.enabled then return nil end
    local existing = R.hosts[unit]
    if existing then
        local current,known=hostStillCurrent(existing)
        if not known then suspendHost(existing,"native-binding-unreadable");return nil end
        if current then return existing end
    end
    local combat, combatReadable = R.SafeBool(InCombatLockdown)
    if not combatReadable or combat then
        R.buildQueued = true
        return nil
    end
    if existing and not R.DestroyHost(unit) then return nil end
    if not R.SORT_METHOD or not R.SORT_DIRECTION then return nil end

    -- Do not allocate 4 complete aura-container stacks for Edit Mode's fake
    -- player clones. They become hosts when real party unit tokens exist.
    if R.PARTY_UNITS[unit] then
        local exists, readable = R.UnitExistsState(unit)
        if not readable or not exists then return nil end
    end
    local portrait, portraitMask, unitFrame, known = R.GetPortrait(unit)
    if not known then R.buildQueued=true;return nil end
    if not portrait or not unitFrame then return nil end
    if R.PARTY_UNITS[unit] then
        -- Blizzard reassigns pooled member frames to indices. Restore the
        -- previous owner's native parent before capturing this slot's baseline.
        for other in pairs(R.PARTY_UNITS) do
            local previous = R.hosts[other]
            if other ~= unit and previous and previous.portrait == portrait then
                local current,known=hostStillCurrent(previous)
                if not known or current or not R.DestroyHost(other) then return nil end
            end
        end
    end
    local parentOK,originalParent=pcall(function() return portrait:GetParent() end)
    if not parentOK or not R.CanAccess(originalParent) or not originalParent then return nil end
    local captured,originalPoints=pcall(R.CapturePoints,portrait)
    if not captured or not originalPoints or #originalPoints==0 then return nil end

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
    local strataGetter,knownStrata=R.ReadAuraField(originalParent,"GetFrameStrata")
    if not knownStrata then return nil end
    if strataGetter then
        local ok, value = pcall(strataGetter, originalParent)
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
    local parentWrite=portrait:SetParent(layer)
    if not R.CanAccess(parentWrite) or parentWrite==false then error("portrait parent unavailable") end
    assert(R.RestorePoints(portrait, originalPoints),"portrait anchors unavailable")
    host._portraitLayoutComplete=true

    host._buildStage = "anchor"
    anchor = CreateFrame("Frame", nil, layer, R.AURA_ANCHOR_TEMPLATE)
    host.anchor = anchor
    -- Only the addon image rectangle receives the measured translation.
    -- Native masks and the independent cooldown/timer anchors remain unchanged.
    R.ApplyPortraitImageLayout(anchor, host)
    anchor:SetFrameStrata(strata)
    anchor:SetFrameLevel(0)
    R.CreatePortraitImageMask(host)
    -- PetFrame uses verified family art as its fallback, never a player race.
    -- Secondary badges belong only on full/regular party frames. Compact
    -- ToT/ToF and pet retain their independent primary portrait aura engines.
    if unit ~= "pet" and not R.SMALL_UNITS[unit] and R.CreateSecondaryPortrait then
        R.CreateSecondaryPortrait(host, parentStrata)
    end
    -- Native NPC runner-up groups are created on first eligible out-of-combat
    -- target, not eagerly for every session. UpdateHost owns the safe trigger.

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
            initializeFrame = function(button)
                host.slotClocks[container] = initializeButton(host, button, tier)
            end,
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

    local honorlessTier = findTierByKey("HonorlessTarget")
    host.readableWelcomingCampfireFrame = createReadableExactFrame(
        host, honorlessTier and honorlessTier.level or 257
    )

    -- Control/status IDs may be restricted from secure exact filtering even
    -- when the complete indexed harmful aura set is readable. Separate
    -- evidence-gated visual helpers never infer an unobserved cast or silence.
    for _, spec in ipairs({
        { "BoostedRest", "readableBoostedRestFrame", 0 },
        { "CampfireNearbyHarmful", "readableNearbyHarmfulFrame", 4 },
        { "TrackingHarmful", "readableTrackingHarmfulFrame", 3 },
        { "PassiveDebuff", "readablePassiveDebuffFrame", 59 },
        { "BaselineClassHarmful", "readableBaselineHarmfulFrame", 90 },
        { "Slows", "readableSlowsFrame", 278 },
        { "Roots", "readableRootsFrame", 300 },
        { "Control", "readableControlFrame", 310 },
        { "Stun", "readableStunFrame", 320 },
        { "InterruptSilence", "readableInterruptSilenceFrame", 306 },
        { "Wounds", "readableWoundsFrame", 230 },
    }) do
        local tier = findTierByKey(spec[1])
        host[spec[2]] = createReadableExactFrame(host, tier and tier.level or spec[3])
    end

    -- The independent lockout wins a tie with its silence aura and remains below CC.
    if R.GetSchoolInterrupt then
        local interrupts = findTierByKey("InterruptSilence")
        host.schoolInterruptFrame = createReadableExactFrame(host, (interrupts and interrupts.level or 306) + 1)
    end
    -- Same-tier status recency applies on every portrait host.
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
        local demoralizingTier = findTierByKey("Demoralizing")
        host.readableDemoralizingFrame = createReadableExactFrame(
            host, demoralizingTier and demoralizingTier.level or 185
        )

        local forbearanceTier = findTierByKey("Forbearance")
        host.readableForbearanceFrame = createReadableExactFrame(
            host, forbearanceTier and forbearanceTier.level or 240
        )

        local offensiveHarmfulTier = findTierByKey("OffensiveHarmful")
        host.readableOffensiveHarmfulFrame = createReadableExactFrame(
            host, offensiveHarmfulTier and offensiveHarmfulTier.level or 280
        )

        local waitingTier = findTierByKey("WaitingToResurrect")
        host.readableWaitingToResurrectFrame = createReadableExactFrame(
            host, waitingTier and waitingTier.level or 332
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

        local immunityTier = findTierByKey("Immunity")
        host.readableDivineProtectionFrame = createReadableExactFrame(
            host, immunityTier and immunityTier.level or 330
        )
    end

    -- Publish only after every native slot and required helper exists.
    host._buildStage, host._buildComplete = "ready", true
    R.hosts[unit] = host
    if unit ~= "pet" and not R.SMALL_UNITS[unit] then observeSecondaryOwner(unitFrame) end
    return host
end

local function abandonHost(host)
    -- Recovery ownership is reachable even when construction never published a
    -- usable host. DestroyHost retains it until native parent AND points return.
    R.hosts[host.unit] = host
    return R.DestroyHost(host.unit)
end

local function needsHost(unit)
    -- The pet foundation also uses the four observed target/focus frames
    -- and PetFrame when their independent aura switches are off.
    return R.db and R.db.enabled and (R.IsUnitEnabled(unit)
        or (R.db.petPortraits and unit ~= "player" and not R.PARTY_UNITS[unit]))
end

local function updateHostFoundation(unit)
    if unit == "pet" and R.UpdateLocalPetPortrait then
        R.UpdateLocalPetPortrait()
    elseif unit ~= "player" and not R.PARTY_UNITS[unit] and R.UpdateObservedPetPortrait then
        R.UpdateObservedPetPortrait(unit)
    end
end

function R.CreateHost(unit)
    if not needsHost(unit) or hostBuildInProgress[unit] or hostBuildFailures[unit] then return nil end
    local pending = { unit = unit, containers = {}, cooldowns = {}, slotClocks = {}, _buildStage = "preflight" }
    hostBuildInProgress[unit] = true
    local ok, host = pcall(buildHost, unit, pending)
    if not ok then
        -- Constructor preflight may be retiring a different physical owner.
        -- Keep its cleanup record, and retry before taking any new ownership.
        if (R.hosts[unit] and R.hosts[unit]~=pending) or pending._buildStage=="preflight" then
            hostBuildInProgress[unit]=nil
            R.buildQueued=true
            return nil
        end
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
    -- Family art is an independent foundation, not a separate aura
    -- presenter. Every tracked unit, including PetFrame, uses these hosts.
    if host == pending then
        updateHostFoundation(unit)
    end
    return host
end

local function callSlot(container, method, ...)
    local fn,readable=R.ReadAuraField(container,method)
    if not readable then return false end
    if not fn and method=="UpdateAllAuras" then return true end
    local ok,result=pcall(fn,container,...)
    return ok and R.CanAccess(result) and result~=false
end

local function setContainer(container, shown, forceRefresh)
    if not container then return end
    shown = shown and true or false

    -- This addon exclusively owns the native tier containers. Repeating
    -- SetEnabled/SetShown on ALL of them at every combat UNIT_AURA/FLAGS event
    -- adds protected frame writes without changing their intended state.
    -- The last *successfully applied* state is enough to avoid those writes.
    -- Real transitions and explicitly forced aura refreshes still execute.
    local refresh = shown and (forceRefresh or container._bjarkiRefreshPending)
    if container._bjarkiAppliedShown == shown and not refresh then return true end
    if container._bjarkiAppliedShown ~= shown then
        if refresh and not container._bjarkiRefreshPending then
            -- Enabling a positively disabled group already refreshes it.
            -- An unknown state cannot confirm that a rebind will be serviced.
            local getter=R.ReadAuraField(container,"IsEnabled")
            local enabled,known=R.SafeBool(getter,container)
            refresh=not known or enabled
        end
        -- Either setter may take effect even when the other rejects the write.
        -- The old committed pair cannot authorize an A/B/A shortcut.
        container._bjarkiAppliedShown=nil
        local enabledOK=callSlot(container,"SetEnabled",shown)
        local shownOK=callSlot(container,"SetShown",shown)
        if not enabledOK or not shownOK then
            container._bjarkiRefreshPending=refresh or nil
            return false
        end
        container._bjarkiAppliedShown=shown
    end
    if refresh and not callSlot(container,"UpdateAllAuras") then
        container._bjarkiRefreshPending=true
        return false
    end
    container._bjarkiRefreshPending=nil
    return true
end

local function retryClockLayouts(host)
    local pending=host._pendingClockLayouts
    if not pending then return end
    local factor=currentPixelFactor()
    for cooldown in pairs(pending) do alignVisibleCountdown(cooldown,host,true,factor) end
end

-- The native assignment can expose a clock one frame after UNIT_AURA, even
-- if the addon last observed it centered. Check only enabled native slots
-- before that assignment, without reading their aura or label geometry.
function R.NoteAuraClockVisibility(host)
    for container,clock in pairs(host.slotClocks or {}) do
        if container._bjarkiAppliedShown == true and clock._bjarkiAlignmentState == "centered" then
            local shown,known=countdownVisibility(clock)
            if not known or not shown then
                setAlignmentState(clock,host,known and "hidden" or "visibility-unavailable")
            end
        end
    end
end

function R.RetryPostAuraLayouts(host)
    if R.hosts[host.unit]~=host or not host._pendingClockLayouts or host._restorePending or host._staleBinding
        or host._unitAuraSuppressed or not R.IsUnitEnabled(host.unit) then return end
    local combat,known=R.SafeBool(InCombatLockdown)
    if known and not combat and hostStillCurrent(host) and nativeUnitTokenMatches(host) then
        retryClockLayouts(host)
    end
end

function R.UpdateHost(host, forceContainerRefresh, bindingChanged, presentationFollows, interruptChange)
    if not host or host._buildComplete ~= true or host._restorePending or host._staleBinding then return end
    local tokenMatches=nativeUnitTokenMatches(host)
    if tokenMatches and host._unitTokenUnverified then
        host._unitTokenUnverified=nil
        if host._revokedPresentation then host._revokedPresentation.foundation=nil end
        if host.unit=="pet" then updateHostFoundation(host.unit) end
    end
    local unitDisabled=not R.IsUnitEnabled(host.unit)
    local suppressAura=unitDisabled or not tokenMatches
    local deferDisable=false
    if suppressAura then
        -- The aura anchor and its sibling presenters can be concealed while
        -- the independent native portrait and family texture remain visible.
        local alreadySuppressed=host._unitAuraSuppressed
        host._unitAuraSuppressed=true
        if not tokenMatches then host._unitTokenUnverified=true end
        clearHostPresentation(host,tokenMatches and "unit-disabled" or "native-unit-mismatch",tokenMatches)
        local combat,known=R.SafeBool(InCombatLockdown)
        deferDisable=not known or combat
        if alreadySuppressed then
            if not deferDisable then
                host._containerWriteFailures=0
                for _,container in ipairs(host.containers or {}) do
                    if not setContainer(container,false) then host._containerWriteFailures=host._containerWriteFailures+1 end
                end
            end
            return
        end
        -- On the transition, discard the previous aura election and activity
        -- flags through the normal disabled update. Its native writes can wait.
    elseif host._unitAuraSuppressed then
        local combat,known=R.SafeBool(InCombatLockdown)
        if not known or combat then
            clearHostPresentation(host,"unit-enable-deferred",true)
            R.buildQueued=true
            return
        end
        -- A token may have changed while disabled. Refresh each current slot
        -- before exposing the independent anchor or any secondary presenter.
        forceContainerRefresh,bindingChanged=true,true
        host._revokedPresentation=nil
    end
    local unitExists, existsReadable = R.UnitExistsState(host.unit)
    local present = not UnitExists or (existsReadable and unitExists)
    local base = R.IsUnitEnabled(host.unit) and not R.testMode and present
        and (not R.PARTY_UNITS[host.unit] or hostStillCurrent(host))
        and hostHasSupportedBinding(host,tokenMatches)
    host._unitExists = present and true or false
    host._unitExistsReadable = existsReadable
    local interruptChanged, bindingBarrier = updateSchoolInterrupt(host, base, bindingChanged or forceContainerRefresh, interruptChange, bindingChanged)
    if interruptChange and interruptChange.host == host and base and not interruptChanged
        and not bindingBarrier and not forceContainerRefresh and not host._unitAuraSuppressed
        and not host._secondaryInterruptClockPending then return end
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
    local hostileUnit, hostileRelationReadable = R.HostileUnitState(host.unit)
    local isPlayer, playerReadable = R.PlayerUnitState(host.unit)
    local hostilePlayer = hostileUnit and playerReadable and isPlayer or false
    local assistable, assistReadable = R.SafeBool(
        UnitCanAssist, "player", host.unit, true, true
    )
    -- A readable friendly relation is *false*, not unknown. The historical
    -- `readable and value or nil` idiom converts false into nil and prevented
    -- every friendly unit from passing the secondary portrait relation gate.
    if hostileRelationReadable then
        host._hostileUnit = hostileUnit
    else
        host._hostileUnit = nil
    end
    host._hostileRelationReadable = hostileRelationReadable
    host._hostilePlayer = hostilePlayer
    if playerReadable then host._isPlayer = isPlayer else host._isPlayer = nil end
    host._playerReadable = playerReadable
    if assistReadable then host._assistable = assistable else host._assistable = nil end
    host._assistReadable = assistReadable

    local presentedHostileTier
    local exactReads = {unit=host.unit, bindingBarrier=bindingBarrier or nil, interruptRefresh=(bindingBarrier or forceContainerRefresh
        or (interruptChange and interruptChange.host == host)) and true or nil}
    if hostileUnit then
        -- Readable exact hostile helpful auras are useful for both players and
        -- NPCs. The broad secure fallback below also covers hostile NPCs such
        -- as totems when this client hides their aura identities from Lua.
        presentedHostileTier = updateReadableHostile(host, base, exactReads)
    else
        clearReadableHostile(host)
    end
    updateFormState(host, base, hostilePlayer, presentedHostileTier)

    local divineProtectionTier = findTierByKey("Immunity")
    local divineProtectionSecureAllowed = divineProtectionTier and R.ExactFilterAllowed(
        host.unit, true, divineProtectionTier.spellIDs, divineProtectionTier.allowNeverSecret
    ) or false
    updateReadableDivineProtection(
        host, base, hostileUnit, divineProtectionSecureAllowed, exactReads
    )

    -- Native stun/silence filters can be relation-restricted. Use only a
    -- complete, directly readable exact-ID election; silence/interrupt casts
    -- without an applied aura never become a positive portrait witness.
    updateReadableHarmfulTier(host, base, "BoostedRest",
        "readableBoostedRestFrame", "_boostedRest", exactReads)
    updateReadableHarmfulTier(host, base, "CampfireNearbyHarmful",
        "readableNearbyHarmfulFrame", "_nearbyHarmful", exactReads)
    updateReadableHarmfulTier(host, base, "TrackingHarmful",
        "readableTrackingHarmfulFrame", "_trackingHarmful", exactReads)
    updateReadableHarmfulTier(host, base, "Roots",
        "readableRootsFrame", "_roots", exactReads)
    updateReadableHarmfulTier(host, base, "Control",
        "readableControlFrame", "_control", exactReads)
    updateReadableHarmfulTier(host, base, "Stun",
        "readableStunFrame", "_stun", exactReads)
    updateReadableHarmfulTier(host, base, "InterruptSilence",
        "readableInterruptSilenceFrame", "_interruptSilence", exactReads)
    updateReadableHarmfulTier(host, base, "Wounds",
        "readableWoundsFrame", "_wounds", exactReads)
    updateReadableHarmfulTier(host, base, "Demoralizing", "readableDemoralizingFrame", "_demoralizing", exactReads)
    updateReadableHarmfulTier(host, base, "PassiveDebuff", "readablePassiveDebuffFrame", "_passiveDebuff", exactReads)
    updateReadableHarmfulTier(host, base, "BaselineClassHarmful", "readableBaselineHarmfulFrame", "_baselineHarmful", exactReads)
    updateReadableHarmfulTier(host, base, "DoTs", "readableDoTsFrame", "_dots", exactReads)
    updateReadableHarmfulTier(host, base, "Dazed", "readableDazedFrame", "_dazed", exactReads)
    updateReadableHarmfulTier(host, base, "Slows", "readableSlowsFrame", "_slows", exactReads)
    updateReadableHarmfulTier(host, base, "Forbearance", "readableForbearanceFrame", "_forbearance", exactReads)
    updateReadableHarmfulTier(host, base, "StatusEffects", "readableStatusEffectsFrame", "_statusEffects", exactReads)
    updateReadableHarmfulTier(host, base, "ResurrectionSickness", "readableResurrectionSicknessFrame", "_resurrectionSickness", exactReads)
    updateReadableHarmfulTier(host, base, "OffensiveHarmful", "readableOffensiveHarmfulFrame", "_offensiveHarmful", exactReads)

    -- Waiting to Resurrect is a helpful aura on ghosted units. Keep its secure
    -- exact lane authoritative when legal; otherwise require a complete ordered
    -- election above the state-derived Ghost frame.
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
        local best, complete, electionReadable = scanLatestReadableExactTierAura(
            exactReads, waitingTier.key, waitingTier.filter
        )
        host._waitingToResurrectReadable = complete and electionReadable
        if complete and electionReadable and best then
            host._waitingToResurrectSpellID = best.spellID
            host._waitingToResurrectActive = showReadableTier(
                host, "readableWaitingToResurrectFrame",
                best, true
            )
        else
            hideReadableExact(host.readableWaitingToResurrectFrame)
        end
    elseif host.readableWaitingToResurrectFrame then
        hideReadableExact(host.readableWaitingToResurrectFrame)
    end

    -- Ghost is a state-derived Immunity-tier witness. This is required on
    -- self/friendly units where exact harmful aura identity may be unavailable.
    updateGhostState(host, base)

    -- BaselineClass and Healing share application-time evidence and election.
    updateReadableRecency(host, base, "BaselineClass", "readableBaselineFrame", "_baseline", exactReads)
    updateReadableRecency(host, base, "Healing", "readableHealingFrame", "_healing", exactReads)

    -- Welcoming Campfire shares the 257 Honorless/Flag tier; a complete
    -- readable election determines its winner rather than guessing priority.
    updateReadableWelcomingCampfire(host, base, exactReads)

    local exactHarmfulAllowed = R.ExactFilterAllowed(host.unit, false, nil, false)
    host._exactHarmfulAllowed = exactHarmfulAllowed
    host._smallHarmfulEnabled = false
    host._containerWriteFailures = 0

    for index, tier in ipairs(R.TIERS or {}) do
        local enabled = base

        if tier.key == "HostileHelpful" then
            -- A complete readable winner suppresses the generic lane only
            -- when its priority reaches that lane. Informational witnesses
            -- must leave higher, unclassified helpful auras eligible.
            local replacesGeneric = presentedHostileTier and presentedHostileTier.level >= tier.level
            enabled = enabled and hostileUnit and not replacesGeneric
            host._hostileHelpfulEnabled = enabled and true or false
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
            if enabled and not R.testMode and onlyReadableExcludedHarmful(host.unit) then
                enabled = false
            end
            host._smallHarmfulEnabled = enabled and true or false
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

        if not deferDisable and not setContainer(host.containers[index], enabled, forceContainerRefresh) then
            host._containerWriteFailures = host._containerWriteFailures + 1
        end
    end
    if suppressAura then return end
    if host._unitAuraSuppressed then
        if host._containerWriteFailures~=0 or
            (host.anchor and not presentationWrite(function(frame) return frame:Show() end,host.anchor)) then
            clearHostPresentation(host,"unit-enable-pending",true)
            return
        end
        host._unitAuraSuppressed=nil
    end
    -- Native cooldowns may create labels after initial construction.
    -- Recover unresolved alignment only on an existing safe OOC host
    -- update, never with an OnUpdate script or hidden aura inspection.
    local inCombat, combatReadable = R.SafeBool(InCombatLockdown)
    if combatReadable and not inCombat and not presentationFollows then
        retryClockLayouts(host)
    end
    -- Only a *complete, readable* public election can project a real second
    -- aura onto the badge. The native tier stack remains the main presenter.
    if R.ReconcileSecondaryPortrait then
        R.ReconcileSecondaryPortrait(host, base, playerReadable and isPlayer, exactReads)
    elseif R.UpdateSecondaryPortrait then
        R.UpdateSecondaryPortrait(host, base and playerReadable and isPlayer)
    end
    if R.UpdateNativeSecondProbe then
        R.UpdateNativeSecondProbe(host, base, hostileUnit, playerReadable, isPlayer,
            forceContainerRefresh, bindingChanged, exactReads)
    end
    -- The pet-family fallback uses native HELPFUL/HARMFUL presence groups,
    -- not private aura enumeration. It stays behind genuine second-aura art.
    if R.UpdatePetSecondaryFallback then
        R.UpdatePetSecondaryFallback(host, base)
    end
end

local function showTest(host)
    if not host or not host.testFrame or host._unitAuraSuppressed then return end
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
    if R.PreviewSecondaryPortrait then R.PreviewSecondaryPortrait(host) end
end

-- A completed native rebind/name/portrait callback can precede the queued
-- presenter update. Revoke the old token immediately even during lockdown.
function R.CheckNativeUnitBinding(unit)
    local host=R.hosts[unit]
    if host and not nativeUnitTokenMatches(host) then R.Refresh(unit) end
end

function R.CheckOutgoingPartyFrame(frame,incoming)
    if not R.CanAccess(frame) or not frame then return end
    for unit in pairs(R.PARTY_UNITS) do
        local host=R.hosts[unit]
        if host and host.unitFrame==frame then
            if (incoming and incoming~=unit) or not hostStillCurrent(host) then
                suspendHost(host,"native-party-binding-changed",true,true)
            elseif not nativeUnitTokenMatches(host) then
                R.Refresh(unit,true,true)
            end
            return unit
        end
    end
end

function R.Refresh(unit, forceContainerRefresh, bindingChanged, presentationFollows, interruptChange)
    local host = R.hosts[unit]
    if not needsHost(unit) then
        -- A stale host may still await combat-safe restoration. Hide its
        -- disabled presentation before any replacement/construction path.
        if host then
            if host._restorePending or not R.db or not R.db.enabled then
                R.DestroyHost(unit)
            else
                R.UpdateHost(host)
            end
        end
        return
    end
    if host then
        local current,known=hostStillCurrent(host)
        if not known then
            suspendHost(host,"native-binding-unreadable",forceContainerRefresh,bindingChanged)
            return
        elseif not current then
            local combat,combatKnown=R.SafeBool(InCombatLockdown)
            if not combatKnown or combat then
                suspendHost(host,"native-binding-changed",forceContainerRefresh,bindingChanged)
                return
            end
            if not R.DestroyHost(unit) then return end
            host=nil
        elseif host._staleBinding then
            -- The same physical owner returned after an unreadable snapshot.
            local combat,combatKnown=R.SafeBool(InCombatLockdown)
            if not combatKnown or combat then
                suspendHost(host,"native-binding-deferred",forceContainerRefresh,bindingChanged)
                return
            end
            if host.anchor and not host._unitAuraSuppressed and R.IsUnitEnabled(unit) and nativeUnitTokenMatches(host) then
                local shown,result=pcall(function() return host.anchor:Show() end)
                if not shown or not R.CanAccess(result) or result==false then return end
            end
            forceContainerRefresh=forceContainerRefresh or host._suspendedRefresh
            bindingChanged=bindingChanged or host._suspendedBindingChange
            host._staleBinding,host._revokedPresentation=nil,nil
            host._suspendedRefresh,host._suspendedBindingChange=nil,nil
            updateHostFoundation(unit)
        end
    end
    host = host or R.CreateHost(unit)
    if not host then return end

    if R.testMode and R.IsUnitEnabled(unit) and hostHasSupportedBinding(host) then
        R.UpdateHost(host, forceContainerRefresh, bindingChanged, presentationFollows, interruptChange)
        showTest(host)
    else
        if R.IsUnitEnabled(unit) and host.testFrame then presentationWrite(hideOwned,host.testFrame) end
        R.UpdateHost(host, forceContainerRefresh, bindingChanged, presentationFollows, interruptChange)
    end
    if host._presentationDeferred and not host._unitAuraSuppressed then R.ApplyPresentation(unit) end
end

function R.RefreshAll(forceContainerRefresh, presentationFollows)
    for _, unit in ipairs(R.TRACKED_UNITS) do R.Refresh(unit, forceContainerRefresh,nil,presentationFollows) end
end

function R.BuildAll(deferRefresh)
    local combat,known=R.SafeBool(InCombatLockdown)
    if not known or combat then
        R.buildQueued = true
        -- Existing hosts can reconcile presentation while structural work waits.
        if not deferRefresh then R.RefreshAll() end
        return
    end
    if not R.db or not R.db.enabled then
        R.buildQueued = not R.DestroyAll()
        return
    end
    R.buildQueued = false
    for _, unit in ipairs(R.TRACKED_UNITS) do
        local failure = hostBuildFailures[unit]
        -- An explicit build retries recovery first; construction can resume only
        -- after the old native parent and points have been restored.
        if failure and R.hosts[unit] then R.DestroyHost(unit) end
        if failure and not R.hosts[unit] then hostBuildFailures[unit] = nil end
        R.CreateHost(unit)
    end
    -- Combat exit refreshes once with force after the pet foundations are ready.
    if not deferRefresh then R.RefreshAll() end
end

function R.ApplyPresentation(unit,routine,verifyLayout)
    local combat,known=R.SafeBool(InCombatLockdown)
    local pixelFactor
    if known and not combat then pixelFactor=currentPixelFactor() end
    for token, host in pairs(R.hosts) do
        local selected=not unit or token==unit
        if selected and (host._staleBinding or host._restorePending or host._unitAuraSuppressed) then
            host._presentationDeferred=true
        elseif selected then
            host._presentationDeferred=nil
            for _, cooldown in ipairs(host.cooldowns or {}) do
                applyClockPreferences(cooldown,routine)
                if known and not combat then
                    if routine then alignVisibleCountdown(cooldown,host,verifyLayout,pixelFactor)
                    else alignCountdown(cooldown,host,false,true,pixelFactor) end
                end
            end
            if host.secondaryCooldown then
                applyClockFormat(host.secondaryCooldown,routine)
            end
            if R.ApplyNativeSecondPresentation then R.ApplyNativeSecondPresentation(host) end
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
    local raceToken, raceSex = "unknown", "unknown"
    if type(UnitRace) == "function" then
        local ok, _, token = pcall(UnitRace, unit)
        if ok and R.CanAccess(token) and type(token) == "string" then raceToken = token end
    end
    if type(UnitSex) == "function" then
        local ok, sex = pcall(UnitSex, unit)
        if ok and R.CanAccess(sex) and type(sex) == "number" then raceSex = sex end
    end
    local raceArt = host._raceBaselineAtlas or "none"
    local raceAtlasPixels = "unavailable"
    if type(raceArt) == "string" and raceArt:sub(1, 6) == "atlas:" then
        local getInfo = C_Texture and C_Texture.GetAtlasInfo or GetAtlasInfo
        if type(getInfo) == "function" then
            local ok, info = pcall(getInfo, raceArt:sub(7))
            if ok and R.CanAccess(info) and type(info) == "table" then
                local fieldsOK, w, h = pcall(function() return info.width, info.height end)
                if fieldsOK and R.CanAccess(w) and R.CanAccess(h)
                    and type(w) == "number" and type(h) == "number" then
                    raceAtlasPixels = tostring(w) .. "x" .. tostring(h)
                end
            end
        end
    end
    return unit .. " host=present enabled=" .. tostring(R.IsUnitEnabled(unit) == true)
        .. " build=" .. (host._buildComplete and "ready" or "incomplete")
        .. " ghostFrame=" .. tostring(host.readableGhostFrame ~= nil)
        .. " statusFrame=" .. tostring(host.readableStatusEffectsFrame ~= nil)
        .. " nativeShown=" .. shownState(host.unitFrame) .. " layerShown=" .. shownState(host.layer)
        .. " binding=" .. bindingState .. " portraitParent=" .. parentState
        .. " nativeRefresh=" .. tostring(host._nativeRefreshReason or "none")
        .. " existsReadable=" .. tostring(host._unitExistsReadable)
        .. " exists=" .. tostring(host._unitExists)
        .. " hostileReadable=" .. tostring(host._hostileRelationReadable)
        .. " hostile=" .. tostring(host._hostileUnit)
        .. " assistReadable=" .. tostring(host._assistReadable)
        .. " assist=" .. tostring(host._assistable)
        .. " ghost=" .. tostring(host._ghostActive) .. ":" .. tostring(host._ghostSource or "none")
        .. " secondary=" .. tostring(host._secondaryMode or "unavailable")
        .. " secondSpell=" .. tostring(host._secondaryAuraSpellID or "none")
        .. " secondTier=" .. tostring(host._secondaryAuraTier or "none")
        .. " secondReason=" .. tostring(host._secondaryElectionReason or "none")
        .. " hostileMain=" .. tostring(host._hostileActive) .. ":"
        .. tostring(host._hostileSpellID) .. ":" .. tostring(host._hostileTierKey)
        .. ":" .. tostring(host._hostileAuraInstanceID)
        .. " hostileList=" .. tostring(host._hostileAuraListComplete)
        .. ":" .. tostring(host._hostileElectionReadable)
        .. " raceBaseline=" .. tostring(host._raceBaselineActive) .. ":"
        .. tostring(host._raceBaselineReason or "unavailable")
        .. " raceToken=" .. tostring(raceToken) .. " raceSex=" .. tostring(raceSex)
        .. " raceArt=" .. tostring(raceArt) .. " racePixels=" .. tostring(raceAtlasPixels)
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
