local addonName, BP = ...
local R = assert(BP.Runtime, "Core.lua must load first")

-- P1/P2-readable prototype. Forever's native secure AuraContainer offers no
-- public cross-tier second winner. A bounded, complete public aura scan can
-- nevertheless elect two distinct effects when *every* relevant candidate,
-- native filter, identity and timing is positively readable. Otherwise this
-- badge falls back to verified race art. Never read forbidden secure winners.
-- The main native/class portrait remains untouched.

-- The optional circle is intentionally limited to full and regular party
-- portraits. ToT/ToF retain their existing PRIMARY aura engine unchanged.
local SECONDARY_UNITS = {
    player = true, target = true, focus = true,
    party1 = true, party2 = true, party3 = true, party4 = true,
}
local function supportsSecondary(host)
    return host and SECONDARY_UNITS[host.unit] == true
end

-- The secondary badge lives on the OUTER top edge. The inner edge is
-- reserved for native rested Zs, party-leader/raid-role indicators and bars.
-- Player and regular party health bars extend right; target/focus extend left.
local MIRROR_LEFT = {
    player = true, party1 = true, party2 = true, party3 = true,
    party4 = true,
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
    -- A retained positive belongs only to the exact unit/instance and ends
    -- on the next aura event or known expiration. A previous one-shot expiry
    -- callback must not affect the next candidate.
    host._secondaryPositiveGeneration = (host._secondaryPositiveGeneration or 0) + 1
    host._secondaryPositiveExpiry = nil
    host._secondaryPositiveGUID = nil
    host._secondaryAuraEventDirty = nil
    host._secondaryExpiryTimerGeneration = nil
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
    if not supportsSecondary(host) or not host.layer or not host.portrait
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
        local outwardLeft = MIRROR_LEFT[host.unit] == true
        local side = outwardLeft and "TOPLEFT" or "TOPRIGHT"
        -- Tuck the badge's centre in by 5px so a near-edge PlayerFrame
        -- does not clip the circular border off the monitor.
        badge:SetPoint("CENTER", host.portrait, side,
            outwardLeft and 5 or -5, compact and 2 or 0)

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
    if not supportsSecondary(host) then return end
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
    if not supportsSecondary(host) or not host.secondaryBadge or not host.racePortrait
        or not R.db or R.db.secondaryPortrait == false then return end
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

-- All exact portrait lanes use either HELPFUL/HARMFUL or the same
-- polarity with INCLUDE_NAME_PLATE_ONLY. The complete indexed scan already
-- certifies that a candidate belongs to its *inclusive* polarity set.
-- For ordinary polarity-only lanes, a positively readable nameplate-only
-- bit must also be false; if unreadable/missing, ask the native oracle.
-- Never bypass the native oracle for semantic filters (IMPORTANT/CC/etc.).
local function exactFilterProven(candidate, tier)
    local base = candidate.helpful and "HELPFUL" or "HARMFUL"
    if tier.filter == base .. "|INCLUDE_NAME_PLATE_ONLY" then return true end
    if tier.filter ~= base then return nil end
    local nameplateOnly, known = read(candidate.aura, "isNameplateOnly")
    if known and type(nameplateOnly) == "boolean" then
        return not nameplateOnly
    end
    -- Optional field unavailable: cannot claim normal HELPFUL/HARMFUL
    -- membership solely from the wider INCLUDE_NAME_PLATE_ONLY scan.
    return nil
end

-- IMPORTANT: The production TOC used to load SecondaryPortrait.lua BEFORE
-- Priority.lua. Building this table at module load therefore cached an EMPTY
-- rank list for the entire session. Every aura was silently ignored and the
-- badge consistently returned not-two-presentable. Resolve only after the
-- tiers have actually been registered, and rebuild if a new table replaces it.
-- This cache is per source tier table, not per unit or aura, so no polling or
-- repeated sort is introduced during ordinary refreshes.
local rankTiers, rankTiersSource
local function getRankTiers()
    local source = R.TIERS
    if type(source) ~= "table" or #source == 0 then return nil end
    if rankTiers and rankTiersSource == source then return rankTiers end
    local sorted = {}
    for index, tier in ipairs(source) do
        sorted[#sorted+1] = { tier = tier, index = index }
    end
    table.sort(sorted, function(a, b)
        if a.tier.level ~= b.tier.level then return a.tier.level > b.tier.level end
        return a.index < b.index
    end)
    rankTiers, rankTiersSource = sorted, source
    return sorted
end

-- Some Forever AuraData expose the instance/spell IDs but omit the optional
-- isNameplateOnly boolean. The inclusive indexed scan alone cannot certify
-- membership in a plain HELPFUL/HARMFUL exact lane. Rather than relying on a
-- separate (sometimes inaccessible) native identity-filter oracle, ask the
-- *public* plain-polarity indexed list. A matching current occurrence is
-- positive native membership evidence. Cache at most one bounded list per
-- polarity for this reconciliation, never across unit/aura events.
local function plainPolarityMembership(unit, candidate, cache)
    if not C_UnitAuras or type(C_UnitAuras.GetAuraDataByIndex) ~= "function" then
        return nil
    end
    local polarity = candidate.helpful and "HELPFUL" or "HARMFUL"
    cache.plainMembership = cache.plainMembership or {}
    local state = cache.plainMembership[polarity]
    if not state then
        state = {byInstance={}, complete=false, valid=true}
        cache.plainMembership[polarity] = state
        for index = 1, AURA_SCAN_LIMIT do
            local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, index, polarity)
            if not ok or not R.CanAccess(aura) then
                state.valid = false
                break
            end
            if aura == nil then
                state.complete = true
                break
            end
            local id, idKnown = read(aura, "auraInstanceID")
            local spellID, spellKnown = read(aura, "spellId")
            if not idKnown or not spellKnown or type(id) ~= "number"
                or id <= 0 or type(spellID) ~= "number" then
                state.valid = false
                break
            end
            if state.byInstance[id] ~= nil then
                -- A reused occurrence ID with a contradictory source entry
                -- cannot be admitted as a positive membership witness.
                state.byInstance = {}
                state.valid = false
                break
            end
            state.byInstance[id] = spellID
        end
    end
    -- A matched positive is enough to prove membership; a missing entry is
    -- negative evidence ONLY if the entire list was readable and terminated.
    local matched = state.byInstance[candidate.auraInstanceID]
    if matched ~= nil then
        return matched == candidate.spellID and true or nil
    end
    if state.valid and state.complete then return false end
    return nil
end

-- Current Ghost is a positively rendered *state* (the main portrait owns
-- this already), not a second aura inferred from death or HP. Its harmful
-- spell IDs may also appear in an indexed list: they are the SAME Ghost.
local function provenGhost(host)
    return host._ghostActive == true
        and ((host._ghostSource == "unit-state" and host._ghostReadable == true)
            or host._ghostSource == "aura")
end

local function ghostAura(spellID)
    local set = BP.categories and BP.categories.immunities_harmful
    return set and set[spellID] == true
end

local function candidateRank(host, candidate, cache)
    local tiers = getRankTiers()
    if not tiers then return nil, "tiers-not-ready" end
    local winner, tied = nil, false
    for _, entry in ipairs(tiers) do
        local tier = entry.tier
        -- Native visual priority is numeric. A lower tier cannot displace
        -- an already-proven higher owner, so don't require unnecessary lower
        -- semantic filter reads to classify the same aura.
        if winner and tier.level < winner.level then break end
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
                -- The main engine already has a positively completed, public
                -- HELPFUL election for a hostile unit. Its exact spell IDs are
                -- also publicly observable here. Exact native filter access is
                -- a different permission: it must not veto a separate *readable*
                -- presentation whose public identity and full list are proven.
                -- No such relaxation is granted for semantic/unknown auras.
                if not allowed and candidate.helpful and host._hostileUnit == true
                    and host._hostileAuraListComplete == true
                    and host._hostileElectionReadable == true then
                    allowed = true
                end
                -- A complete public aura scan can positively prove a
                -- friendly harmful Boosted Rest instance even if the native
                -- harmful exact filter is relation-gated on self/friendlies.
                -- Rank that *observed* effect at its existing priority zero
                -- when another higher aura becomes primary on combat entry.
                -- Its plain HARMFUL membership is checked independently below;
                -- this never admits unavailable/secret aura identities.
                if not allowed and tier.key == "BoostedRest"
                    and candidate.helpful == false and host._hostileUnit == false
                    and host._assistable == true then
                    allowed = true
                end
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
                -- A verified exact ID in a compatible indexed polarity scan
                -- needs no redundant native identity filter call. That call
                -- can be inaccessible to ordinary add-ons even for own buffs.
                local yes
                if tier.exact then
                    yes = exactFilterProven(candidate, tier)
                    -- In clients where isNameplateOnly is omitted, use a
                    -- same-polarity public filter to establish the exact ID.
                    if yes == nil and (tier.filter == "HELPFUL"
                        or tier.filter == "HARMFUL") then
                        yes = plainPolarityMembership(host.unit, candidate, cache)
                    end
                elseif tier.key == "SmallFriendlyHarmful"
                    and not candidate.helpful
                    and tier.filter == "HARMFUL|INCLUDE_NAME_PLATE_ONLY" then
                    -- semanticFilterMatches already checked the duration cap
                    -- and excluded IDs. This is the identical public polarity
                    -- filter used to produce the complete indexed candidate;
                    -- an additional secret native oracle adds no information.
                    yes = true
                end
                if yes == nil then
                    yes = nativeSlotMatches(host.unit, candidate, tier.filter, cache)
                end
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
    if not supportsSecondary(host) then return nil, "unit-excluded" end
    if not host._buildComplete then return nil, "host-incomplete" end
    if not R.db or R.db.secondaryPortrait == false then return nil, "disabled" end
    if R.testMode then return nil, "test-mode" end
    if not getRankTiers() then return nil, "tiers-not-ready" end
    if host._hostileUnit == nil then return nil, "relation-unreadable" end
    local hostile = host._hostileUnit == true
    local npcHarmfulProjection = false
    if hostile then
        if host._hostileRelationReadable ~= true then
            return nil, "hostile-relation-unreadable"
        end
        -- Hostile PLAYER units still need the independently verified
        -- helpful/form primary. An identified NPC may have both helpful and
        -- harmful public auras; only after ranking the *entire* complete
        -- snapshot can we determine whether the first aura is harmful.
        if host._hostileAuraListComplete ~= true or
            host._hostileElectionReadable ~= true then
            return nil, "hostile-list-unreadable"
        end
        npcHarmfulProjection = (host.unit == "target" or host.unit == "focus")
            and host._playerReadable == true and host._isPlayer == false
            -- Native generic harmful display is a valid NPC path when exact
            -- relation permission is missing; verify its real slot below.
            and (host._exactHarmfulAllowed == true
                or host._smallHarmfulEnabled == true)
        if not npcHarmfulProjection and not host._hostileActive
            and not host._formStateActive then
            return nil, "hostile-primary-unverified"
        end
    elseif host._assistable ~= true then
        return nil, "assist-unreadable"
    end
    if host._ghostActive and not provenGhost(host) then
        return nil, "ghost-unproven"
    end
    if host._ghostActive and host._formStateActive then
        return nil, "ghost-form-conflict"
    end
    if host._formStateActive and
        (type(host._formStateSpellID) ~= "number" or
            (host._formStateReason ~= "unit-power" and
             not (type(host._formStateReason) == "string" and
                host._formStateReason:match(":proven$")))) then
        return nil, "form-unproven"
    end
    if host._hostileActive and not hostile then
        return nil, "other-presentation-witness"
    end
    -- A host with failed presentation writes or an uncertain live binding
    -- cannot certify that the native first-place view is current.
    if (host._containerWriteFailures or 0) ~= 0 then return nil, "native-update-failed" end
    local current, reason = collectCurrentAuras(host.unit)
    if not current then return nil, reason end
    -- Rank the complete public union, including any NPC helpful auras.
    -- A harmful first-place projection is permitted only when it outranks
    -- every helpful candidate and its corresponding native slot is enabled.
    local ranked, cache = {}, {probes=0}
    local ghostActive = provenGhost(host)
    for _, candidate in ipairs(current) do
        -- When the existing static main Ghost presenter is authoritative,
        -- suppress its redundant harmful aura IDs from the second-place list.
        if not (ghostActive and ghostAura(candidate.spellID)) then
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
    end
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
    -- A positively displayed Warrior stance/Druid form is a real, static
    -- portrait candidate at level 149 (just below the SelfState native lane).
    -- It is NOT automatically primary: a higher-level aura can cover it. A
    -- previous implementation incorrectly rejected that common case and
    -- returned the race badge whenever a buff outranked the active stance.
    -- Rank the state alongside auras without inventing an aura instance ID or
    -- treating the state as an applied timed aura.
    local form, formPrimary = nil, false
    if host._formStateActive then
        local stateLevel = (R.TIER_BY_KEY and R.TIER_BY_KEY.SelfState
            and R.TIER_BY_KEY.SelfState.level or 150) - 1
        form = {staticForm = true, spellID = host._formStateSpellID,
            tier = {key = "FormState", level = stateLevel}}
        if ranked[1] and ranked[1].tier.level == stateLevel then
            -- No assumed tie break between native aura and static presenter.
            return nil, "form-rank-tie"
        end
        formPrimary = not ranked[1] or ranked[1].tier.level < stateLevel
    end

    local primary, second, electionReason
    if ghostActive then
        -- Match the current Ghost presenter's Immunity+2 frame level.
        -- WaitingToResurrect can tie that level; an unproven tie fails closed.
        local immunity = R.TIER_BY_KEY and R.TIER_BY_KEY.Immunity
        local ghostLevel = (immunity and immunity.level or 330) + 2
        if ranked[1] and ranked[1].tier.level >= ghostLevel then
            return nil, ranked[1].tier.level == ghostLevel
                and "ghost-rank-tie" or "ghost-not-primary"
        end
        primary = {staticGhost=true, spellID=8326,
            tier={key="GhostState", level=ghostLevel}}
        second, electionReason = ranked[1], "verified-ghost-then-aura"
    elseif formPrimary then
        -- No higher aura: the observed form is visible as the first portrait;
        -- a *lower* aura becomes second, if any.
        primary, second, electionReason = form, ranked[1], "verified-form-then-aura"
    else
        primary, second, electionReason = ranked[1], ranked[2], "verified-readable"
        if form and primary and primary.tier.level > form.tier.level then
            if not second or second.tier.level < form.tier.level then
                -- One stronger aura covers the form; the form sits between
                -- that aura and weaker buffs such as Camp Benefits (90).
                second, electionReason = form, "verified-aura-then-form"
            elseif second.tier.level == form.tier.level then
                return nil, "form-rank-tie"
            end
        end
    end
    if not primary or not second then return nil, "not-two-presentable" end
    if primary.auraInstanceID and second.auraInstanceID
        and primary.auraInstanceID == second.auraInstanceID then
        return nil, "duplicate-aura"
    end
    if npcHarmfulProjection and not primary.helpful then
        -- A hostile NPC's primary harmful winner may be drawn by a native
        -- exact slot *or* the existing identity-blind SmallFriendlyHarmful
        -- fallback. Both use filters whose eligibility was checked against
        -- the same complete indexed public harmful stream. Do not extend this
        -- to other semantic tiers that need unreadable private metadata.
        local genericHarmful = primary.tier.key == "SmallFriendlyHarmful"
            and host._smallHarmfulEnabled == true
        if primary.helpful or (not primary.tier.exact and not genericHarmful) then
            return nil, "npc-primary-not-native-proven"
        end
        local nativeIndex
        for index, tier in ipairs(R.TIERS or {}) do
            if tier == primary.tier then nativeIndex = index; break end
        end
        local native = nativeIndex and host.containers and host.containers[nativeIndex]
        if not native or type(native.IsEnabled) ~= "function" then
            return nil, "npc-native-slot-unreadable"
        end
        local enabled, known = R.SafeBool(native.IsEnabled, native)
        if not known or not enabled then
            return nil, "npc-native-slot-unreadable"
        end
        electionReason = "npc-readable-harmful-projection"
    elseif hostile and not formPrimary then
        -- Hostile players and hostile NPCs with an independently displayed
        -- helpful winner retain strict correspondence with the main helper.
        if not host._hostileActive or host._hostileReadable ~= true
            or type(host._hostileAuraInstanceID) ~= "number" then
            return nil, "hostile-primary-unverified"
        end
        if primary.spellID ~= host._hostileSpellID
            or primary.tier.key ~= host._hostileTierKey
            or primary.auraInstanceID ~= host._hostileAuraInstanceID then
            return nil, "hostile-primary-mismatch"
        end
    end
    return second, electionReason
end

-- A form icon is an independent, currently displayed *state*, not an aura.
-- Prefer the image already proved and drawn by our form presenter; use the
-- public spell texture only when the icon cannot be read from that presenter.
-- Neither path can authorize a fabricated cooldown or aura instance.
local function currentFormTexture(host, spellID)
    if not host._formStateActive or host._formStateSpellID ~= spellID then return nil end
    local frame = host.readableFormStateFrame
    local formIcon = frame and frame.icon
    if formIcon and type(formIcon.GetTexture) == "function" then
        local ok, value = pcall(formIcon.GetTexture, formIcon)
        if ok and R.CanAccess(value) and validIcon(value) then return value end
    end
    local getter = C_Spell and C_Spell.GetSpellTexture or GetSpellTexture
    if type(getter) == "function" then
        local ok, value = pcall(getter, spellID)
        if ok and R.CanAccess(value) and validIcon(value) then return value end
    end
    return nil
end

local function showSecondaryAura(host, candidate)
    local icon, cooldown = host.racePortrait, host.secondaryCooldown
    if not icon or not host.secondaryBadge or not candidate then return false end
    local texture, duration, expiration, timeMod
    local staticForm = candidate.staticForm == true
    if staticForm then
        texture = currentFormTexture(host, candidate.spellID)
        if not texture then return false end
        duration = 0 -- no fabricated aura duration or cooldown for a stance
    else
        local readable
        texture, readable = read(candidate.aura, "icon")
        if not readable or not validIcon(texture) then return false end
        local durOK
        duration, durOK = read(candidate.aura, "duration")
        if not durOK or type(duration) ~= "number" or duration < 0 then return false end
        if duration > 0 then
            local expOK, modOK
            expiration, expOK = read(candidate.aura, "expirationTime")
            timeMod, modOK = read(candidate.aura, "timeMod")
            if not expOK or not modOK or type(expiration) ~= "number" then return false end
            if timeMod == nil then timeMod = 1 end
            if type(timeMod) ~= "number" or timeMod <= 0 or timeMod == math.huge then return false end
        end
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
    host._secondaryMode = staticForm and "form" or "aura"
    host._secondaryAuraInstanceID = staticForm and nil or candidate.auraInstanceID
    host._secondaryAuraSpellID = candidate.spellID
    host._secondaryAuraTier = candidate.tier.key
    host._secondaryPositiveGeneration = (host._secondaryPositiveGeneration or 0) + 1
    -- Only a timed positive has a clock that can bound temporary retention.
    -- A permanent/unreadable lifetime is never kept on old evidence alone.
    host._secondaryPositiveExpiry = (not staticForm and duration > 0) and expiration or nil
    host._secondaryAuraEventDirty = false
    host._secondaryExpiryTimerGeneration = nil
    host._secondaryPositiveGUID = nil
    if host.unit ~= "player" and type(UnitGUID) == "function" then
        local guidOK, guid = pcall(UnitGUID, host.unit)
        if guidOK and R.CanAccess(guid) and type(guid) == "string" and guid ~= "" then
            host._secondaryPositiveGUID = guid
        end
    end
    host._raceBaselineAtlas, host._raceBaselineActive = nil, false
    host._raceBaselineReason = "secondary-aura"
    return true
end

-- This event is not a negative observation about every buff, but if combat
-- seals the new aura list, we can no longer prove the cached *ranking* after
-- ANY UNIT_AURA change. Revoke that temporary trust until a new full election.
-- Call before the normal UNIT_AURA host refresh, not after it.
function R.NoteSecondaryAuraEvent(unit)
    if not SECONDARY_UNITS[unit] then return end
    local host = R.hosts and R.hosts[unit]
    if host and host._secondaryMode == "aura" then
        host._secondaryAuraEventDirty = true
    end
end

local HOLD_READ_FAILURE = {
    ["inaccessible-index"] = true,
    ["incomplete-identity"] = true,
    ["relation-unreadable"] = true,
    ["assist-unreadable"] = true,
    ["filter-unreadable"] = true,
    ["native-filter-unreadable"] = true,
    ["hostile-list-unreadable"] = true,
    ["hostile-relation-unreadable"] = true,
}
local function retainCombatPositive(host, reason)
    if not HOLD_READ_FAILURE[reason] or host._secondaryMode ~= "aura"
        or host._secondaryAuraEventDirty or not host._secondaryAuraInstanceID
        or not host.secondaryBadge or not host.secondaryCooldown
        or not host._secondaryPositiveExpiry then return false end
    if type(R.SafeBool) ~= "function" then return false end
    local inCombat, combatReadable = R.SafeBool(InCombatLockdown)
    if not combatReadable or not inCombat then return false end
    local now, nowReadable = nil, false
    if type(GetTime) == "function" then
        local ok, value = pcall(GetTime)
        nowReadable = ok and R.CanAccess(value) and type(value) == "number"
            and value == value and value ~= math.huge
        if nowReadable then now = value end
    end
    local expires = host._secondaryPositiveExpiry
    if not nowReadable or type(expires) ~= "number" or expires <= now
        or expires == math.huge then return false end

    -- The player's identity cannot switch. Target/focus and pooled party
    -- tokens CAN switch: require the exact same positively readable GUID.
    if host.unit ~= "player" then
        if not host._secondaryPositiveGUID or type(UnitGUID) ~= "function" then
            return false
        end
        local ok, guid = pcall(UnitGUID, host.unit)
        if not ok or not R.CanAccess(guid) or guid ~= host._secondaryPositiveGUID then
            return false
        end
    end

    -- The native aura timer is already counting down. A single one-shot
    -- callback revokes this evidence at expiry even if no aura event arrives.
    -- No polling, no old-cast inference and no changes to the main portrait.
    local generation = host._secondaryPositiveGeneration
    if host._secondaryExpiryTimerGeneration ~= generation then
        if not C_Timer or type(C_Timer.After) ~= "function" then return false end
        local delay = expires - now
        local ok = pcall(C_Timer.After, delay, function()
            if host._secondaryPositiveGeneration ~= generation then return end
            if R.hosts and R.hosts[host.unit] ~= host then return end
            host._secondaryAuraEventDirty = true
            if R.Refresh then R.Refresh(host.unit)
            else hideBadge(host, "combat-positive-expired") end
        end)
        if not ok then return false end
        host._secondaryExpiryTimerGeneration = generation
    end
    host._secondaryElectionReason = "combat-positive-retained:" .. reason
    return true
end

function R.ReconcileSecondaryPortrait(host, enabled, isPlayer)
    if not supportsSecondary(host) then return end
    -- The new public reader must never attempt to write a visible aura into
    -- a host that is not carrying a fully constructed secondary badge. Partial
    -- or mocked native host trees are still valid for main portrait updates.
    if not host.secondaryBadge or not host.racePortrait then
        hideBadge(host, "badge-unavailable")
        host._secondaryElectionReason = "badge-unavailable"
        return
    end
    if not enabled or not R.db or R.db.secondaryPortrait == false then
        hideBadge(host, "ineligible")
        host._secondaryElectionReason = "ineligible"
        return
    end
    -- The independent UIParent overlay must not outlive its native frame's
    -- visibility. This includes disabled ToT/ToF and pooled party frames.
    if host.unitFrame and type(host.unitFrame.IsShown) == "function" then
        local shown, known = R.SafeBool(host.unitFrame.IsShown, host.unitFrame)
        if not known or not shown then
            local reason = known and "native-frame-hidden" or "native-visibility-unreadable"
            hideBadge(host, reason)
            host._secondaryElectionReason = reason
            return
        end
    end
    if R.testMode then
        -- /bp test owns a clearly synthetic small icon, not live evidence.
        R.PreviewSecondaryPortrait(host)
        return
    end
    local second, reason = R.GetReadableSecondaryAura(host)
    if second and showSecondaryAura(host, second) then
        host._secondaryElectionReason = reason
        return
    end
    -- Entering combat can seal otherwise readable values without an aura
    -- mutation. Preserve ONLY the last positive, timed secondary until its
    -- first UNIT_AURA event or known expiration. Never freeze a stale rank
    -- over a new aura event, a unit switch, or a failed native frame write.
    if not second and retainCombatPositive(host, reason) then return end
    R.UpdateSecondaryPortrait(host, isPlayer)
    host._secondaryElectionReason = second and "presentation-unavailable" or reason
end
