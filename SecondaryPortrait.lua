local addonName, BP = ...
local R = assert(BP.Runtime, "Core.lua must load first")

-- P1/P2-readable prototype. Forever's native secure AuraContainer offers no
-- public cross-tier second winner. A bounded, complete public aura scan can
-- nevertheless elect two distinct effects when *every* relevant candidate,
-- native filter, identity and timing is positively readable. Otherwise this
-- badge falls back to verified race art. Never read forbidden secure winners.
-- The main native/class portrait remains untouched.

local MIRROR_LEFT = {
    target = true, focus = true, focustarget = true,
}
local STRATA_ABOVE = {
    BACKGROUND = "LOW", LOW = "MEDIUM", MEDIUM = "HIGH", HIGH = "DIALOG",
    DIALOG = "FULLSCREEN_DIALOG", FULLSCREEN = "FULLSCREEN_DIALOG",
    FULLSCREEN_DIALOG = "FULLSCREEN_DIALOG", TOOLTIP = "TOOLTIP",
}
-- Frame widgets parented to UIParent cannot be destroyed; pool them across
-- host rebuilds so repeated party swaps do not accumulate permanent children.
local badgePool = {}
local AURA_SCAN_LIMIT = 48
local MAX_FILTER_PROBES = 192 -- bounded per host refresh; no polling
local COMPACT = {
    targettarget = true, focustarget = true,
    party1 = true, party2 = true, party3 = true, party4 = true,
}

local function clearSecondaryCooldown(host)
    local cooldown = host and host.secondaryCooldown
    if not cooldown then return end
    if cooldown.Clear then pcall(cooldown.Clear, cooldown)
    elseif cooldown.SetCooldown then pcall(cooldown.SetCooldown, cooldown, 0, 0) end
    if cooldown.Hide then pcall(cooldown.Hide, cooldown) end
end

local function clearSecondaryAura(host)
    if not host then return end
    host._secondaryAuraInstanceID = nil
    host._secondaryAuraSpellID = nil
    host._secondaryAuraTier = nil
    clearSecondaryCooldown(host)
end

local function hideBadge(host, reason)
    if not host then return end
    clearSecondaryAura(host)
    host._secondaryMode = "hidden"
    host._raceBaselineActive = false
    host._raceBaselineReason = reason or "not-eligible"
    if host.secondaryBadge and host.secondaryBadge.Hide then
        pcall(host.secondaryBadge.Hide, host.secondaryBadge)
    end
    -- Revoke previous textures, even on the same host with a new unit GUID.
    if host.racePortrait and host.racePortrait.SetTexture then
        pcall(host.racePortrait.SetTexture, host.racePortrait, nil)
    end
    host._secondaryArtKey = nil
    host._raceBaselineAtlas = nil
end

function R.HideSecondaryPortrait(host, reason)
    hideBadge(host, reason)
end

function R.ReleaseSecondaryPortrait(host)
    if not host or not host.secondaryBadge then return end
    local badge = host.secondaryBadge
    hideBadge(host, "host-released")
    if badge.ClearAllPoints then pcall(badge.ClearAllPoints, badge) end
    host.secondaryBadge = nil
    host.racePortrait, host.secondaryBorder = nil, nil
    host.secondaryMask, host.secondaryCooldown = nil, nil
    if not badge._bjarkiInPool then
        badge._bjarkiInPool = true
        badgePool[#badgePool+1] = badge
    end
end

function R.CreateSecondaryPortrait(host, nativeStrata)
    if not host or host.unit == "pet" or not host.layer or not host.portrait
        or not host.unitFrame then return false end
    local compact = COMPACT[host.unit] == true
    local width, imageSize, borderSize = compact and 29 or 37,
        compact and 18 or 22, compact and 24 or 30
    local badge = table.remove(badgePool)
    if badge then badge._bjarkiInPool = false end
    local ok = pcall(function()
        -- Native unit frames are protected. Their children can inherit
        -- restrictions that forbid live Show/Hide in combat; use a reusable
        -- independent UIParent sibling anchored to current portrait geometry.
        if not badge then
            badge = CreateFrame("Frame", nil, UIParent, R.AURA_ANCHOR_TEMPLATE)
        end
        host.secondaryBadge = badge
        badge:Hide()
        if badge.ClearAllPoints then badge:ClearAllPoints() end
        badge:SetSize(width, width)
        local frameStrata = nativeStrata or host.strata or "LOW"
        if type(host.unitFrame.GetFrameStrata) == "function" then
            local strataOK, actual = pcall(host.unitFrame.GetFrameStrata, host.unitFrame)
            if strataOK and R.CanAccess(actual) and STRATA_ABOVE[actual] then
                frameStrata = actual
            end
        end
        badge:SetFrameStrata(STRATA_ABOVE[frameStrata] or "HIGH")
        local nativeLevel = 0
        if type(host.unitFrame.GetFrameLevel) == "function" then
            local levelOK, level = pcall(host.unitFrame.GetFrameLevel, host.unitFrame)
            if levelOK and R.CanAccess(level) and type(level) == "number"
                and level >= 0 and level < 10000 then nativeLevel = level end
        end
        badge:SetFrameLevel(nativeLevel + 12)
        badge:EnableMouse(false)
        local side = MIRROR_LEFT[host.unit] and "TOPLEFT" or "TOPRIGHT"
        badge:SetPoint("CENTER", host.portrait, side, 0, compact and 2 or 0)

        local icon = badge._bjarkiIcon
        if not icon then
            icon = badge:CreateTexture(nil, "ARTWORK")
            icon:SetPoint("CENTER", badge, "CENTER", 0, 0)
            local mask = badge:CreateMaskTexture(nil, "ARTWORK")
            mask:SetAtlas("CircleMask", false)
            mask:SetAllPoints(icon)
            icon:AddMaskTexture(mask)
            badge._bjarkiMask = mask
            badge._bjarkiIcon = icon
        end
        icon:SetSize(imageSize, imageSize)
        host.racePortrait = icon
        host.secondaryMask = badge._bjarkiMask

        local rim = badge._bjarkiBorder
        if not rim then
            rim = badge:CreateTexture(nil, "OVERLAY")
            rim:SetAtlas("UI-HUD-UnitFrame-TotemFrame", false)
            badge._bjarkiBorder = rim
        end
        rim:SetSize(borderSize, borderSize)
        if rim.ClearAllPoints then rim:ClearAllPoints() end
        rim:SetPoint("CENTER", badge, "CENTER", compact and 0.5 or 1,
            compact and -1 or -1.5)
        host.secondaryBorder = rim

        local cooldown = badge._bjarkiCooldown
        if not cooldown then
            cooldown = CreateFrame("Cooldown", nil, badge,
                "CooldownFrameTemplate," .. R.AURA_ANCHOR_TEMPLATE)
            cooldown:SetAllPoints(icon)
            if cooldown.SetDrawBling then cooldown:SetDrawBling(false) end
            if cooldown.SetDrawEdge then cooldown:SetDrawEdge(false) end
            if cooldown.SetDrawSwipe then cooldown:SetDrawSwipe(false) end
            if cooldown.SetReverse then cooldown:SetReverse(true) end
            badge._bjarkiCooldown = cooldown
        end
        if R.ApplyCountdownFormat then R.ApplyCountdownFormat(cooldown) end
        cooldown:Hide()
        host.secondaryCooldown = cooldown
    end)
    if not ok then
        R.ReleaseSecondaryPortrait(host)
        return false
    end
    hideBadge(host, "not-yet-eligible")
    return true
end

function R.UpdateSecondaryPortrait(host, permitted)
    if not host or host.unit == "pet" then return end
    if not R.db or R.db.secondaryPortrait == false then
        hideBadge(host, "disabled")
        return
    end
    if not host.secondaryBadge or not host.racePortrait then return end
    if not permitted then
        hideBadge(host, "ineligible")
        return
    end

    local art, coords, isAtlas = R.ResolveRaceBaselineAtlas(host.unit, true)
    if not art then
        hideBadge(host, coords or "race-unavailable")
        return
    end
    local key = (isAtlas and "atlas:" or "texture:") .. art
        .. (coords and ":" .. table.concat(coords, ",") or "")
    if host._secondaryMode == "race" and host._secondaryArtKey == key then return end

    clearSecondaryAura(host)
    local icon = host.racePortrait
    local ok, result
    if isAtlas then
        -- The atlas's texcoords are already the exact race tile coordinates.
        -- Never apply generic SetTexCoord after SetAtlas.
        ok, result = pcall(icon.SetAtlas, icon, art, false)
    else
        ok, result = pcall(icon.SetTexture, icon, art)
        if ok and result ~= false then
            ok = pcall(icon.SetTexCoord, icon, coords[1], coords[2], coords[3], coords[4])
        end
    end
    if not ok or result == false then
        hideBadge(host, "texture-unavailable")
        return
    end
    if not pcall(host.secondaryBadge.Show, host.secondaryBadge) then
        hideBadge(host, "show-unavailable")
        return
    end
    host._secondaryMode = "race"
    host._secondaryArtKey = key
    host._raceBaselineAtlas = key
    host._raceBaselineReason = "ready"
    host._raceBaselineActive = true
end

-- Existing /bp test mode is deliberately synthetic. This makes it possible
-- to calibrate the new circle against a second spell icon before a secure
-- second-place election has been proven. There is no live-aura inference.
function R.PreviewSecondaryPortrait(host)
    if not host or host.unit == "pet" or not host.secondaryBadge or not host.racePortrait
        or not R.db or R.db.secondaryPortrait == false then return end
    clearSecondaryAura(host)
    clearSecondaryAura(host)
    local icon = host.racePortrait
    local ok, result = pcall(icon.SetTexture, icon, "Interface\\Icons\\Spell_Holy_SealOfWisdom")
    if ok and result ~= false then
        ok = pcall(icon.SetTexCoord, icon, 0, 1, 0, 1)
    end
    if not ok or not pcall(host.secondaryBadge.Show, host.secondaryBadge) then
        hideBadge(host, "preview-unavailable")
        return
    end
    host._secondaryArtKey = nil
    host._raceBaselineAtlas = nil
    host._secondaryMode = "test-only"
    host._raceBaselineActive = false
    host._raceBaselineReason = "test-only"
end
 
-- A public-only top-two election is possible on *some* readable friendly units.
-- The native global runner-up cannot be queried, so never infer one when a
-- semantic filter, aura identity or native eligibility is inaccessible.
-- The per-tier native set remains the authoritative MAIN portrait presentation.
local function read(aura, key)
    if not R.ReadAuraField then return nil, false end
    return R.ReadAuraField(aura, key)
end

local function validIcon(icon)
    return (type(icon) == "number" and icon > 0 and icon < math.huge)
        or (type(icon) == "string" and icon ~= "")
end

local function collectCurrentAuras(unit)
    if not C_UnitAuras or type(C_UnitAuras.GetAuraDataByIndex) ~= "function" then
        return nil, "no-index-api"
    end
    local result, byInstance = {}, {}
    for _, entry in ipairs({{ "HELPFUL|INCLUDE_NAME_PLATE_ONLY", true },
        { "HARMFUL|INCLUDE_NAME_PLATE_ONLY", false }}) do
        local filter, helpful = entry[1], entry[2]
        local complete = false
        for index = 1, AURA_SCAN_LIMIT do
            local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, index, filter)
            if not ok or not R.CanAccess(aura) then return nil, "inaccessible-index" end
            if aura == nil then complete = true; break end
            local id, idOK = read(aura, "auraInstanceID")
            local spellID, spellOK = read(aura, "spellId")
            if not idOK or not spellOK or type(id) ~= "number" or id <= 0
                or type(spellID) ~= "number" or byInstance[id] then
                return nil, "incomplete-identity"
            end
            local candidate = {aura=aura, auraInstanceID=id, spellID=spellID,
                helpful=helpful}
            result[#result+1], byInstance[id] = candidate, true
        end
        if not complete then return nil, "aura-limit" end
    end
    return result, "complete"
end

local function nativeSlotMatches(unit, candidate, filter, cache)
    if not C_UnitAuras or type(C_UnitAuras.IsAuraFilteredOutByInstanceID) ~= "function" then
        return nil
    end
    local key = tostring(candidate.auraInstanceID) .. "|" .. filter
    if cache[key] ~= nil then return cache[key] end
    cache.probes = cache.probes + 1
    if cache.probes > MAX_FILTER_PROBES then return nil end
    local result, filtered = pcall(C_UnitAuras.IsAuraFilteredOutByInstanceID,
        unit, candidate.auraInstanceID, filter)
    if not result or not R.CanAccess(filtered) or type(filtered) ~= "boolean" then
        return nil
    end
    cache[key] = not filtered
    return cache[key]
end

local function semanticFilterMatches(candidate, filters)
    if not filters then return true end
    if filters.excludeSpellIDs and filters.excludeSpellIDs[candidate.spellID] then return false end
    if filters.includeSpellIDs and not filters.includeSpellIDs[candidate.spellID] then return false end
    if filters.maxDuration then
        local duration, readable = read(candidate.aura, "duration")
        if not readable or type(duration) ~= "number" then return nil end
        if duration == 0 or duration > filters.maxDuration then return false end
    end
    if filters.isPriorityAura ~= nil then
        if not AuraUtil or type(AuraUtil.IsPriorityDebuff) ~= "function" then return nil end
        local priority, readable = R.SafeBool(AuraUtil.IsPriorityDebuff, candidate.spellID)
        if not readable then return nil end
        if priority ~= filters.isPriorityAura then return false end
    end
    -- Keep other predicate additions from silently admitting the wrong aura.
    for key in pairs(filters) do
        if key ~= "excludeSpellIDs" and key ~= "includeSpellIDs"
            and key ~= "maxDuration" and key ~= "isPriorityAura" then return nil end
    end
    return true
end

local function candidateRank(host, candidate, cache)
    local winner, tied = nil, false
    for _, tier in ipairs(R.TIERS or {}) do
        local matchingPolarity = tier.filter and
            ((tier.filter:sub(1,7) == "HELPFUL") == candidate.helpful)
        if matchingPolarity then
            local allowed = false
            if tier.exact and tier.spellIDs and tier.spellIDs[candidate.spellID] then
                -- A direct restricted lookup alone is not proof of a native
                -- winner. Require a permitted native slot or a completed,
                -- positively presented readable election of this lane.
                local owner = host._readableTierOwners and host._readableTierOwners[tier.key]
                allowed = owner and owner.complete == true or false
                if not allowed then
                    if R.ExactFilterAllowed then
                        allowed = R.ExactFilterAllowed(host.unit, tier.helpful,
                            tier.spellIDs, tier.allowNeverSecret)
                        if not allowed and tier.allowNeverSecret and R.AuraIsNeverSecret then
                            -- Mixed NeverSecret tiers may be *enabled* because
                            -- another member is safe. Permission must be
                            -- established for this particular aura identity.
                            allowed = R.AuraIsNeverSecret(candidate.spellID)
                        end
                    elseif R.NativeExactContainerAllowed then
                        -- Compatibility only for simple modeled clients.
                        allowed = R.NativeExactContainerAllowed(host.unit, tier)
                    end
                end
            elseif tier.semantic then
                if tier.key == "HostileHelpful" then
                    allowed = host._hostileUnit == true
                        and not host._hostileActive
                elseif tier.key == "SmallFriendlyHarmful" then
                    allowed = host._smallHarmfulEnabled == true
                else
                    allowed = true
                end
                if allowed then allowed = semanticFilterMatches(candidate, R.CandidateFilters(tier)) end
                if allowed == nil then return nil, "filter-unreadable" end
            end
            if allowed then
                local yes = nativeSlotMatches(host.unit, candidate, tier.filter, cache)
                if yes == nil then return nil, "native-filter-unreadable" end
                if yes then
                    if not winner or tier.level > winner.level then
                        winner, tied = tier, false
                    elseif tier.level == winner.level and tier.key ~= winner.key then
                        tied = true
                    end
                end
            end
        end
    end
    if tied then return nil, "same-level-lanes" end
    return winner
end

local RECENCY_TIERS = {BaselineClass=true, Healing=true, StatusEffects=true}
local function compareCandidates(a,b)
    if a.tier.level ~= b.tier.level then return a.tier.level > b.tier.level end
    if a.tier.key ~= b.tier.key then return nil end
    if RECENCY_TIERS[a.tier.key] then
        -- Complete native duration-start evidence is required for this tier's
        -- user-approved recency rule; missing starts are not estimated.
        if a.start == nil or b.start == nil then return nil end
        if a.start ~= b.start then return a.start > b.start end
    end
    return a.auraInstanceID > b.auraInstanceID
end

local function tryGetAuraStart(unit, candidate)
    if C_UnitAuras and type(C_UnitAuras.GetAuraDuration) == "function" then
        local ok, duration = pcall(C_UnitAuras.GetAuraDuration, unit, candidate.auraInstanceID)
        if ok and R.CanAccess(duration) and duration and type(duration.GetStartTime) == "function" then
            local startOK, startTime = pcall(duration.GetStartTime, duration)
            if startOK and R.CanAccess(startTime) and type(startTime) == "number"
                then return startTime end
        end
    end
    local duration, durOK = read(candidate.aura,"duration")
    local expiration, expOK = read(candidate.aura,"expirationTime")
    if durOK and expOK and type(duration)=="number" and duration>0
        and type(expiration)=="number" then return expiration-duration end
end

function R.GetReadableSecondaryAura(host)
    if not host or host.unit == "pet" or not host._buildComplete
        or not R.db or R.db.secondaryPortrait == false
        or R.testMode or host._hostileUnit ~= false
        or host._assistable ~= true or host._formStateActive
        or host._ghostActive or host._hostileActive then
        return nil, "not-eligible"
    end
    -- A host with failed presentation writes or an uncertain live binding
    -- cannot certify that the native first-place view is current.
    if (host._containerWriteFailures or 0) ~= 0 then return nil, "native-update-failed" end
    local current, reason = collectCurrentAuras(host.unit)
    if not current then return nil, reason end
    local ranked, cache = {}, {probes=0}
    for _, candidate in ipairs(current) do
        local tier, why = candidateRank(host, candidate, cache)
        if why then return nil, why end
        if tier then
            candidate.tier = tier
            if RECENCY_TIERS[tier.key] then
                candidate.start = tryGetAuraStart(host.unit, candidate)
            end
            ranked[#ranked+1] = candidate
        end
    end
    if #ranked < 2 then return nil, "not-two-presentable" end
    -- Insertion sort, bounded to 2 * 48 auras. Tied independent lanes are
    -- indeterminate because native frame levels need not share one owner.
    for index = 2, #ranked do
        local cand, j = ranked[index], index-1
        while j >= 1 do
            local greater = compareCandidates(cand, ranked[j])
            if greater == nil then return nil, "cross-lane-tie" end
            if not greater then break end
            ranked[j+1] = ranked[j]
            j = j-1
        end
        ranked[j+1] = cand
    end
    if ranked[1].auraInstanceID == ranked[2].auraInstanceID then
        return nil, "duplicate-aura"
    end
    return ranked[2], "verified-readable"
end

local function showSecondaryAura(host, candidate)
    local icon, cooldown = host.racePortrait, host.secondaryCooldown
    local texture, readable = read(candidate.aura, "icon")
    if not readable or not validIcon(texture) then return false end
    local duration, durOK = read(candidate.aura, "duration")
    if not durOK or type(duration) ~= "number" or duration < 0 then return false end
    local expiration, expOK, timeMod, modOK
    if duration > 0 then
        expiration, expOK = read(candidate.aura, "expirationTime")
        timeMod, modOK = read(candidate.aura, "timeMod")
        if not expOK or not modOK or type(expiration) ~= "number" then return false end
        if timeMod == nil then timeMod = 1 end
        if type(timeMod) ~= "number" or timeMod <= 0 or timeMod == math.huge then return false end
    end
    local success, wrote = pcall(icon.SetTexture, icon, texture)
    if not success or wrote == false then return false end
    if not pcall(icon.SetTexCoord, icon, 0, 1, 0, 1) then return false end
    if cooldown then
        clearSecondaryCooldown(host)
        if duration > 0 then
            local ok = cooldown.SetCooldown and pcall(cooldown.SetCooldown,
                cooldown, expiration-duration, duration, timeMod)
            if not ok then return false end
            if R.ApplyCountdownFormat then R.ApplyCountdownFormat(cooldown) end
            if not pcall(cooldown.Show, cooldown) then return false end
        end
    end
    if not pcall(host.secondaryBadge.Show, host.secondaryBadge) then return false end
    host._secondaryArtKey = nil
    host._secondaryMode = "aura"
    host._secondaryAuraInstanceID = candidate.auraInstanceID
    host._secondaryAuraSpellID = candidate.spellID
    host._secondaryAuraTier = candidate.tier.key
    host._raceBaselineAtlas, host._raceBaselineActive = nil, false
    host._raceBaselineReason = "secondary-aura"
    return true
end

function R.ReconcileSecondaryPortrait(host, enabled, isPlayer)
    if not host or host.unit == "pet" then return end
    if not enabled or not R.db or R.db.secondaryPortrait == false then
        hideBadge(host, "ineligible")
        return
    end
    -- The independent UIParent overlay must not outlive its native frame's
    -- visibility. This includes disabled ToT/ToF and pooled party frames.
    if host.unitFrame and type(host.unitFrame.IsShown) == "function" then
        local shown, known = R.SafeBool(host.unitFrame.IsShown, host.unitFrame)
        if not known or not shown then
            hideBadge(host, "native-frame-hidden")
            return
        end
    end
    if R.testMode then
        -- /bp test owns a clearly synthetic small icon, not live evidence.
        R.PreviewSecondaryPortrait(host)
        return
    end
    local second, reason = R.GetReadableSecondaryAura(host)
    if second and showSecondaryAura(host, second) then return end
    R.UpdateSecondaryPortrait(host, isPlayer)
    host._secondaryElectionReason = reason or "presentation-unavailable"
end
