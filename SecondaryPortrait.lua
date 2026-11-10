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

-- All second-circle renderers share Core.SecondaryCirclePlacement: the
-- unified raised TOPLEFT anchor applies to Player, Target, Focus and party.
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

-- The shipped TOC always loads Core first. Some deliberately isolated
-- regression fixtures load only SecondaryPortrait.lua, so accept the same
-- bounded 2/64 crop without requiring a full Core simulator. This fallback
-- must never be applied to race atlases/sprite sheets.
local function applySecondaryArtCrop(icon)
    if R.ApplySecondaryIconCrop then return R.ApplySecondaryIconCrop(icon) end
    if not icon or type(icon.SetTexCoord) ~= "function" then return false end
    local inset = R.AURA_ART_EDGE_INSET or 2 / 64
    return pcall(icon.SetTexCoord, icon, inset, 1-inset, inset, 1-inset)
end

local function cooldownWrite(setter,cooldown,...)
    if not R.CanAccess(setter) or type(setter)~="function" then return false end
    local ok,result=pcall(setter,cooldown,...)
    return ok and R.CanAccess(result) and result~=false
end

local function clearSecondaryCooldown(host)
    local cooldown = host and host.secondaryCooldown
    if not cooldown then return true end
    local cleared=cooldownWrite(cooldown.Clear,cooldown)
    local hidden=cooldownWrite(cooldown.Hide,cooldown)
    return cleared or hidden or cooldownWrite(cooldown.SetCooldown,cooldown,0,0)
end

local function clearSecondaryAura(host)
    if not host then return end
    host._secondaryAuraInstanceID = nil
    host._secondaryAuraSpellID = nil
    host._secondaryAuraTier = nil
    host._secondaryPrimaryAuraInstanceID = nil
    -- A retained positive belongs only to the exact unit/instance and ends
    -- on the next aura event or known expiration. A previous one-shot expiry
    -- callback must not affect the next candidate.
    host._secondaryPositiveExpiry = nil
    host._secondaryPositiveHostile, host._secondaryPositiveAssist = nil, nil
    host._secondaryPrimarySource, host._secondarySecondSource = nil, nil
    host._secondaryExcludedHigher = nil
    host._secondaryClockDuration, host._secondaryClockExpiry, host._secondaryClockRate = nil, nil, nil
    host._secondaryClockSource, host._secondaryAuraTexture = nil, nil
    host._secondaryPositiveGUID = nil
    host._secondaryPositiveInterrupt, host._secondaryPositiveSecondInterrupt = nil, nil
    host._secondaryDisplayedInterrupt, host._secondaryHigherOwners = nil, nil
    host._secondaryInterruptClockObject,host._secondaryInterruptClockSource=nil,nil
    host._secondaryAuraClockObject=nil
    host._secondaryInterruptClockPending,host._secondaryInterruptClockRetries=nil,nil
    host._secondaryPositiveLevel,host._secondaryPrimarySpellID=nil,nil
    host._secondaryAuraEventDirty = nil
    host._secondaryExpiryTicket = nil
    return clearSecondaryCooldown(host)
end

local function hideBadge(host, reason)
    if not host then return true end
    clearSecondaryAura(host)
    host._secondaryMode = "hidden"
    host._raceArtUnavailable = nil
    host._raceBaselineActive = false
    host._raceBaselineReason = reason or "not-eligible"
    local hidden = true
    if host.secondaryBadge then
        local ok, result = pcall(function() return host.secondaryBadge:Hide() end)
        hidden = ok and R.CanAccess(result) and result ~= false
    end
    -- Revoke previous textures, even on the same host with a new unit GUID.
    if host.racePortrait and host.racePortrait.SetTexture then
        pcall(host.racePortrait.SetTexture, host.racePortrait, nil)
    end
    host._secondaryArtKey = nil
    host._raceBaselineAtlas = nil
    return hidden
end

function R.HideSecondaryPortrait(host, reason)
    return hideBadge(host, reason)
end

local function visibleOwner(host)
    local visible, reason = R.SecondaryOwnerVisible(host)
    if not visible then
        hideBadge(host, reason)
        host._secondaryElectionReason = reason
    end
    return visible
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
    local width, imageSize, borderSize, rimX, rimY =
        R.SecondaryCircleGeometry(host.unit)
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
        local side, dx, dy = R.SecondaryCirclePlacement(host.unit)
        -- Use the same anchor as the native fallback and pet-family art.
        -- Target is raised above the bar edge, avoiding the vertical
        -- combo-point column right of its main portrait.
        badge:SetPoint("CENTER", host.portrait, side, dx, dy)

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
        rim:SetPoint("CENTER", badge, "CENTER", rimX, rimY)
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
        if R.ApplySecondaryCountdownFont then
            R.ApplySecondaryCountdownFont(cooldown)
        end
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
    if not host.secondaryBadge or not host.racePortrait or not visibleOwner(host) then return end
    if not permitted then
        hideBadge(host, "ineligible")
        return
    end

    local art, coords, isAtlas = R.ResolveRaceBaselineAtlas(host.unit, true)
    if not art then
        host._raceArtUnavailable = hideBadge(host, coords or "race-unavailable")
        return
    end
    local key = (isAtlas and "atlas:" or "texture:") .. art
        .. (coords and ":" .. table.concat(coords, ",") or "")
    if host._secondaryMode == "race" and host._secondaryArtKey == key then return end

    if not clearSecondaryAura(host) then
        hideBadge(host, "cooldown-unavailable")
        return
    end
    local icon = host.racePortrait
    local ok, result
    if isAtlas then
        -- The atlas's texcoords are already the exact race tile coordinates.
        -- Never apply generic SetTexCoord after SetAtlas.
        ok, result = pcall(icon.SetAtlas, icon, art, false)
    else
        ok, result = pcall(icon.SetTexture, icon, art)
        if ok and R.CanAccess(result) and result ~= false then
            ok = pcall(icon.SetTexCoord, icon, coords[1], coords[2], coords[3], coords[4])
        end
    end
    if not ok or not R.CanAccess(result) or result == false then
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
        or not R.db or R.db.secondaryPortrait == false or not visibleOwner(host) then return end
    if not clearSecondaryAura(host) then
        hideBadge(host, "cooldown-unavailable")
        return
    end
    local icon = host.racePortrait
    local ok, result = pcall(icon.SetTexture, icon, "Interface\\Icons\\Spell_Holy_SealOfWisdom")
    if ok and R.CanAccess(result) and result ~= false then
        ok = applySecondaryArtCrop(icon)
    end
    if not ok or not R.CanAccess(result) or result == false or not pcall(host.secondaryBadge.Show, host.secondaryBadge) then
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

local function nativeFlag(native, method)
    local getter = read(native, method)
    if type(getter) == "function" then
        local flag, known = R.SafeBool(getter, native)
        if known then return flag end
    end
end

local function nativeSlotState(native, verifyShown)
    if not native then return nil end
    local enabled = nativeFlag(native, "IsEnabled")
    local shown
    if verifyShown then shown = nativeFlag(native, "IsShown") end
    if enabled == false or shown == false then return false end
    if enabled and (not verifyShown or shown) then return true end
    -- Only a successful joint assignment still consistent with every
    -- readable flag supplies a missing flag.
    local applied = read(native, "_bjarkiAppliedShown")
    if type(applied) == "boolean" and (enabled == nil or enabled == applied)
        and (shown == nil or shown == applied) then return applied end
end

local function nativeTierEnabled(host, tier, verifyShown)
    for index, configured in ipairs(R.TIERS) do
        if configured == tier then return nativeSlotState(host.containers and host.containers[index], verifyShown) end
    end
end

local function differentClockField(alias, physical, key, default)
    local a, aKnown=read(alias,key)
    local b, bKnown=read(physical,key)
    if not aKnown or not bKnown then return false end
    if a==nil then a=default end
    if b==nil then b=default end
    return type(a)=="number" and a>=0 and a<math.huge
        and type(b)=="number" and b>=0 and b<math.huge and a~=b
end

-- On a self alias the primary helpers read the physical token. Their
-- completed elections can expose a different application, or an occurrence
-- absent from the player index. Keep its identity and clock on that token.
local function mergePhysicalOwners(host, unit, reads, current, byInstance)
    for key,owner in pairs(host._readableTierOwners or {}) do
        local tier = R.TIER_BY_KEY and R.TIER_BY_KEY[key]
        if tier and tier.exact and owner.complete and owner.frame and host[owner.frameKey] == owner.frame
            and owner.frame.cooldown == owner.cooldown then
            for place=1,2 do
                local id,spell = owner.auraInstanceID,owner.spellID
                if place==2 then id,spell=owner.runnerInstanceID,owner.runnerSpellID end
                if type(id)=="number" and id>0 and type(spell)=="number" then
                    local row=byInstance[id]
                    if row and (row.spellID~=spell or row.helpful~=tier.helpful) then return false end
                    local aura
                    local list=reads and reads.unit==host.unit and reads[tier.filter]
                    if type(list)=="table" then
                        for i,listed in ipairs(list.auras) do
                            if list.spellIDs[i]==spell and read(listed,"auraInstanceID")==id then aura=listed;break end
                        end
                    end
                    if not row then
                        if not aura and C_UnitAuras and C_UnitAuras.GetAuraDataByAuraInstanceID then
                            local ok,found=pcall(C_UnitAuras.GetAuraDataByAuraInstanceID,host.unit,id)
                            if ok and R.CanAccess(found) and found then
                                local foundSpell=read(found,"spellId")
                                if foundSpell and foundSpell~=spell then return false end
                                if foundSpell==spell and read(found,"auraInstanceID")==id then aura=found end
                            end
                        end
                        row={aura=aura,sourceUnit=host.unit,readUnit=unit,spellID=spell,auraInstanceID=id,
                            helpful=tier.helpful,directOnly=true}
                        current[#current+1],byInstance[id]=row,row
                    else
                        row.physicalUnit,row.physicalAura=host.unit,aura
                        if aura then
                            row.physicalClockConflict=differentClockField(row.aura,aura,"duration")
                                or differentClockField(row.aura,aura,"expirationTime")
                                or differentClockField(row.aura,aura,"timeMod",1)
                        end
                    end
                    row.physicalTier,row.physicalPlace=tier,place
                end
            end
        end
    end
    return true
end

local function collectCurrentAuras(unit, reads, host)
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
            local candidate = {aura=aura, sourceUnit=unit, auraInstanceID=id, spellID=spellID,
                helpful=helpful}
            result[#result+1], byInstance[id] = candidate, candidate
        end
        if not complete then return nil, "aura-limit" end
    end
    -- A direct player occurrence must also occupy one of the first two
    -- places in the self alias's own complete Honorless election. The
    -- Campfire helper does not take over when Honorless Target wins.
    local owner = host._welcomingCampfireActive and host._readableTierOwners
        and host._readableTierOwners.HonorlessTarget
    local nativeHonorless = unit == "player" and host.unit ~= "player" and host._honorlessReadable
        and host._welcomingCampfirePresent and nativeTierEnabled(host,R.TIER_BY_KEY.HonorlessTarget,true)
    if unit == "player" and (host.unit == "player" or owner or nativeHonorless) and R.GetPlayerCampfireWitnesses then
        for _, witness in ipairs(R.GetPlayerCampfireWitnesses(reads).auras) do
            local id = read(witness.aura, "auraInstanceID")
            if type(id) ~= "number" or id <= 0 then return nil, "incomplete-identity" end
            local indexed = byInstance[id]
            if indexed then
                if not indexed.helpful or indexed.spellID ~= witness.spellID then
                    return nil, "conflicting-direct-identity"
                end
            elseif host.unit == "player" or
                ((nativeHonorless or (owner and owner.complete and owner.frame == host.readableWelcomingCampfireFrame))
                    and ((host._honorlessWinnerSpellID == witness.spellID and host._honorlessWinnerInstanceID == id)
                        or (host._honorlessRunnerSpellID == witness.spellID and host._honorlessRunnerInstanceID == id))) then
                local candidate = {aura=witness.aura, sourceUnit=unit, auraInstanceID=id, directOnly=true,
                    spellID=witness.spellID, helpful=true}
                result[#result+1], byInstance[id] = candidate, candidate
            end
        end
    end
    if unit ~= host.unit and not mergePhysicalOwners(host,unit,reads,result,byInstance) then
        return nil,"conflicting-physical-identity"
    end
    return result, "complete"
end

local function rankCache(reads, unit)
    if not reads then return {probes=0} end
    reads.rankBudget = reads.rankBudget or {probes=0}
    reads.rankCaches = reads.rankCaches or {}
    if not reads.rankCaches[unit] then reads.rankCaches[unit] = {budget=reads.rankBudget} end
    return reads.rankCaches[unit]
end

local function nativeSlotMatches(unit, candidate, filter, cache)
    if not C_UnitAuras or type(C_UnitAuras.IsAuraFilteredOutByInstanceID) ~= "function" then
        return nil
    end
    local key = unit .. "|" .. tostring(candidate.auraInstanceID) .. "|" .. filter
    if cache[key] ~= nil then return cache[key] end
    local budget = cache.budget or cache
    if budget.probes >= MAX_FILTER_PROBES then return nil end
    budget.probes = budget.probes + 1
    local result, filtered = pcall(C_UnitAuras.IsAuraFilteredOutByInstanceID,
        unit, candidate.auraInstanceID, filter)
    if not result or not R.CanAccess(filtered) or type(filtered) ~= "boolean" then
        return nil
    end
    cache[key] = not filtered
    return cache[key]
end

local function semanticFilterMatches(candidate, filters, skipIdentity, skipPriority)
    if not filters then return true end
    if not skipIdentity then
        if filters.excludeSpellIDs and filters.excludeSpellIDs[candidate.spellID] then return false end
        if filters.includeSpellIDs and not filters.includeSpellIDs[candidate.spellID] then return false end
    end
    if filters.maxDuration then
        local duration, readable = read(candidate.aura, "duration")
        if not readable or type(duration) ~= "number" then return nil end
        if duration == 0 or duration > filters.maxDuration then return false end
    end
    if filters.isPriorityAura ~= nil and not skipPriority then
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
    local key=unit.."|"..polarity
    local state = cache.plainMembership[key]
    if not state then
        state = {byInstance={}, complete=false, valid=true}
        cache.plainMembership[key] = state
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

-- Forever rejects an include-ID entry, but ignores an exclude-ID entry,
-- when identity filtering is prohibited. Missing secrecy or relation data
-- cannot prove that a native exact group will reject a known public spell.
local function nativeIdentityPermission(unit, candidate)
    if R.ExactFilterAllowed and R.ExactFilterAllowed(unit,candidate.helpful,nil,false) then return true end
    if R.AuraIsNeverSecret and R.AuraIsNeverSecret(candidate.spellID) then return true end
    if not C_Secrets or not C_Secrets.GetSpellAuraSecrecy or not Enum or not Enum.SecrecyLevel then return nil end
    local ok, value = pcall(C_Secrets.GetSpellAuraSecrecy, candidate.spellID)
    if not ok or not R.CanAccess(value) or type(value) ~= "number" then return nil end
    if value == Enum.SecrecyLevel.NeverSecret then return true end
    local assist, known = R.SafeBool(UnitCanAssist,"player",unit,true,true)
    if candidate.helpful then
        local controlled, readable = R.SafeBool(UnitIsPlayerControlledOrGroupMember,unit)
        if controlled or assist then return true end
        if known and readable then return false end
    elseif known then return not assist end
end

-- Evaluate a public occurrence against an actual ribbon plan after a failed
-- badge paint. Unknown membership leaves the native best-effort path intact.
function R.NativeRibbonGroupMatches(witness, candidate, filter, predicates, skipPriority)
    -- A physical-only helper occurrence was absent from the completed
    -- ribbon-token index. It cannot prove a member of this native group.
    if candidate.sourceUnit and candidate.sourceUnit~=witness.unit then return false end
    local base = candidate.helpful and "HELPFUL" or "HARMFUL"
    if filter:sub(1,7) ~= base then return false end
    if predicates then
        local included = predicates.includeSpellIDs
        local excluded = predicates.excludeSpellIDs and predicates.excludeSpellIDs[candidate.spellID]
        if included and not included[candidate.spellID] then return false end
        if included or excluded then
            if not candidate.ribbonPermissionChecked then
                candidate.ribbonPermission = nativeIdentityPermission(witness.unit,candidate)
                candidate.ribbonPermissionChecked = true
            end
            local allowed = candidate.ribbonPermission
            if allowed == nil then
                -- Other public predicates can still rule out this occurrence.
                if semanticFilterMatches(candidate,predicates,true,skipPriority) == false then return false end
                local matches=nativeSlotMatches(witness.unit,candidate,filter,witness.cache)
                if matches == false then return false end
                return nil
            end
            if (included and not allowed) or (excluded and allowed) then return false end
        end
        local passed = semanticFilterMatches(candidate,predicates,true,skipPriority)
        if passed ~= true then return passed end
    end
    if not candidate.directOnly then
        if filter == base .. "|INCLUDE_NAME_PLATE_ONLY" then return true end
        if filter == base then
            local only = read(candidate.aura,"isNameplateOnly")
            if type(only) == "boolean" then return not only end
            local plain=plainPolarityMembership(witness.unit,candidate,witness.cache)
            if plain ~= nil then return plain end
        end
    end
    return nativeSlotMatches(witness.unit,candidate,filter,witness.cache)
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

local function candidateRank(host, candidate, cache, auraUnit, floor, checkHostileHelpfulCompetition)
    local tiers = getRankTiers()
    if not tiers then return nil, "tiers-not-ready" end
    local winner, tied = nil, false
    for _, entry in ipairs(tiers) do
        local tier = entry.tier
        if floor and tier.level <= floor then break end
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
                    and ((host._hostileAuraListComplete == true and host._hostileElectionReadable == true)
                        or checkHostileHelpfulCompetition) then
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
                        allowed = R.ExactFilterAllowed(auraUnit, tier.helpful,
                            tier.spellIDs, tier.allowNeverSecret)
                        if not allowed and tier.allowNeverSecret and R.AuraIsNeverSecret then
                            -- Mixed NeverSecret tiers may be *enabled* because
                            -- another member is safe. Permission must be
                            -- established for this particular aura identity.
                            allowed = R.AuraIsNeverSecret(candidate.spellID)
                        end
                    elseif R.NativeExactContainerAllowed then
                        -- Compatibility only for simple modeled clients.
                        allowed = R.NativeExactContainerAllowed(auraUnit, tier)
                    end
                end
                if allowed and auraUnit == "player" and host.unit ~= "player" and tier.key ~= "BoostedRest" then
                    local physical = nativeSlotState(host.containers and host.containers[entry.index],true)
                    local presented = owner and owner.complete and owner.frame and host[owner.frameKey] == owner.frame
                        and ((owner.spellID == candidate.spellID and owner.auraInstanceID == candidate.auraInstanceID)
                            or (owner.runnerSpellID == candidate.spellID and owner.runnerInstanceID == candidate.auraInstanceID))
                    if not presented and (physical == false or
                        (physical == true and nativeIdentityPermission(host.unit,candidate) == false)) then
                        candidate.unavailableExactTier = tier
                    end
                end
            elseif tier.semantic then
                if tier.key == "HostileHelpful" then
                    allowed = host._hostileHelpfulEnabled == true
                elseif tier.key == "SmallFriendlyHarmful" then
                    allowed = host._smallHarmfulEnabled == true
                else
                    allowed = true
                end
                if allowed then allowed = semanticFilterMatches(candidate, R.CandidateFilters(tier)) end
                if allowed == nil then return nil, "filter-unreadable", tier.level end
            end
            if allowed then
                -- A verified exact ID in a compatible indexed polarity scan
                -- needs no redundant native identity filter call. That call
                -- can be inaccessible to ordinary add-ons even for own buffs.
                local yes
                if tier.exact then
                    yes = candidate.physicalTier == tier or exactFilterProven(candidate, tier)
                    -- In clients where isNameplateOnly is omitted, use a
                    -- same-polarity public filter to establish the exact ID.
                    if yes == nil and (tier.filter == "HELPFUL"
                        or tier.filter == "HARMFUL") then
                        yes = plainPolarityMembership(candidate.sourceUnit or auraUnit, candidate, cache)
                    end
                elseif (tier.key == "SmallFriendlyHarmful" and not candidate.helpful
                    and tier.filter == "HARMFUL|INCLUDE_NAME_PLATE_ONLY")
                    or (tier.key == "HostileHelpful" and candidate.helpful
                    and tier.filter == "HELPFUL|INCLUDE_NAME_PLATE_ONLY") then
                    -- Duration/ID predicates were checked above. The candidate
                    -- came from this exact inclusive polarity stream.
                    yes = true
                end
                if yes == nil then
                    yes = nativeSlotMatches(candidate.sourceUnit or auraUnit, candidate, tier.filter, cache)
                end
                if yes == nil then return nil, "native-filter-unreadable", tier.level end
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
    if tied then return nil, "same-level-lanes", winner.level end
    return winner
end

-- Count higher *observed effects*, including native-only lanes. Reuse the
-- current main update's completed indexed lists. A sealed list supplies no
-- rank; it does not invalidate positives from the other polarity.
function R.KnownHigherAuraLevels(host, reads, floor)
    local levels = {}
    if not reads then return levels end
    local cache = rankCache(reads, reads.unit)
    for _,polarity in ipairs({"HELPFUL","HARMFUL"}) do
        local list = reads[polarity .. "|INCLUDE_NAME_PLATE_ONLY"] or reads[polarity]
        if list then
            for i,spell in ipairs(list.spellIDs) do
                local aura = list.auras[i]
                local id = read(aura, "auraInstanceID")
                if type(id) == "number" and id > 0 then
                    local candidate = {aura=aura, spellID=spell, auraInstanceID=id,
                        helpful=polarity=="HELPFUL"}
                    local tier = candidateRank(host, candidate, cache, reads.unit, floor)
                    if tier and (not levels[spell] or tier.level > levels[spell]) then
                        levels[spell] = tier.level
                    end
                end
            end
        end
    end
    return levels
end

local RECENCY_TIERS = {BaselineClass=true, Healing=true, StatusEffects=true}
local function compareCandidates(a,b)
    if a.schoolInterrupt and b.schoolInterrupt then return a.schoolPlace < b.schoolPlace end
    if a.tier.level ~= b.tier.level then return a.tier.level > b.tier.level end
    if a.tier.key ~= b.tier.key then return nil end
    local placeA = a.physicalTier == a.tier and a.physicalPlace or 3
    local placeB = b.physicalTier == b.tier and b.physicalPlace or 3
    if placeA ~= placeB then return placeA < placeB end
    if RECENCY_TIERS[a.tier.key] then
        -- Complete native duration-start evidence is required for this tier's
        -- user-approved recency rule; missing starts are not estimated.
        if a.start == nil or b.start == nil then return nil end
        if a.start ~= b.start then return a.start > b.start end
    end
    return a.auraInstanceID > b.auraInstanceID
end

-- Only the two highest distinct effects need an ordering. Resolve the
-- highest numeric band before comparing its members, so an ambiguous
-- lower band (including a missing application time) cannot veto the pair.
local function sameEffect(a,b)
    if not a or not b then return false end
    return a.spellID==b.spellID or (a.lockoutIdentity and a.lockoutIdentity==b.lockoutIdentity)
end

local function canOccupyPlace(candidate, primary)
    if sameEffect(candidate,primary) then return false end
    if candidate.unavailableExactTier ~= candidate.tier then return true end
    -- An ineligible physical lane cannot own the main. Its positively
    -- observed lower effects can still be painted on the independent badge.
    return primary and candidate.tier.level < (primary.rankLevel or primary.tier.level)
end

local function nextRanked(candidates, unknown, primary, physicalHost)
    local top, topTier, sharedLevel
    for _,candidate in ipairs(candidates) do
        if canOccupyPlace(candidate, primary) then
            local level = candidate.rankLevel or candidate.tier.level
            if not top or level > top then
                top, topTier, sharedLevel = level, candidate.tier, false
            elseif level == top and candidate.tier.key ~= topTier.key then
                sharedLevel = true
            end
        end
    end
    for _,pending in ipairs(unknown) do
        if not sameEffect(pending,primary) and (not top or pending.level >= top) then
            return nil, pending.reason
        end
    end
    -- Only the first place belongs to the physical native renderer. When a
    -- sole recency lane has no active helper, native occurrence order proves
    -- its winner even for permanent auras without application timestamps.
    if physicalHost and topTier and not sharedLevel and RECENCY_TIERS[topTier.key] then
        local owner = physicalHost._readableTierOwners and physicalHost._readableTierOwners[topTier.key]
        local hasOwner = owner and owner.complete and owner.frame and physicalHost[owner.frameKey] == owner.frame
        if not hasOwner and nativeTierEnabled(physicalHost, topTier, true) == true then
            local best, uncertainID
            for _, candidate in ipairs(candidates) do
                if candidate.tier == topTier and canOccupyPlace(candidate, nil) then
                    local permission = nativeIdentityPermission(physicalHost.unit,candidate)
                    if permission and (not best or candidate.auraInstanceID > best.auraInstanceID) then
                        best = candidate
                    elseif permission == nil then
                        uncertainID = math.max(uncertainID or 0,candidate.auraInstanceID)
                    end
                end
            end
            if not best or (uncertainID and uncertainID > best.auraInstanceID) then return nil,"native-recency-unverified" end
            return best
        end
    end
    local best
    for _,candidate in ipairs(candidates) do
        if canOccupyPlace(candidate, primary) and (candidate.rankLevel or candidate.tier.level) == top then
            if not best then
                best = candidate
            elseif candidate.staticGhost or best.staticGhost then return nil, "ghost-rank-tie"
            elseif candidate.staticForm or best.staticForm then return nil, "form-rank-tie"
            else
                local higher = compareCandidates(candidate, best)
                if higher == nil then return nil, "cross-lane-tie" end
                if higher then best = candidate end
            end
        end
    end
    return best
end

local function tryGetAuraStart(unit, candidate)
    if C_UnitAuras and type(C_UnitAuras.GetAuraDuration) == "function" then
        local ok, duration = pcall(C_UnitAuras.GetAuraDuration, unit, candidate.auraInstanceID)
        if ok and R.CanAccess(duration) and duration ~= nil then
            local startOK, startTime = pcall(function() return duration:GetStartTime() end)
            if startOK and R.CanAccess(startTime) and type(startTime) == "number"
                then return startTime end
        end
    end
    local duration, durOK = read(candidate.aura,"duration")
    local expiration, expOK = read(candidate.aura,"expirationTime")
    if durOK and expOK and type(duration)=="number" and duration>0
        and type(expiration)=="number" then return expiration-duration end
end

-- UnitIsUnit is a positive, public identity witness: a Target/Focus frame
-- actually bound to the local player can use the same "player" aura reader
-- as PlayerFrame. This is essential for helpful effects that are readable
-- on self but relation-gated on other unit tokens. Names or matching models
-- are NEVER sufficient; unknown/secret results keep the original token.
local function currentAuraReadUnit(host)
    local unit = host.unit
    if (unit == "target" or unit == "focus")
        and type(UnitIsUnit) == "function" and type(R.SafeBool) == "function" then
        local same, readable = R.SafeBool(UnitIsUnit, unit, "player")
        if readable and same then return "player", true end
    end
    return unit, false
end

local function matchesReadableOwner(host, primary)
    local owner = host._readableTierOwners and host._readableTierOwners[primary.tier.key]
    return owner and owner.complete == true and owner.spellID == primary.spellID
        and type(primary.auraInstanceID) == "number" and owner.auraInstanceID == primary.auraInstanceID
        and owner.frame ~= nil and host[owner.frameKey] == owner.frame
        and owner.frame.cooldown == owner.cooldown
end

local function captureTierSource(host, candidate)
    if not candidate or not candidate.auraInstanceID then return nil end
    local owner = host._readableTierOwners and host._readableTierOwners[candidate.tier.key]
    local owned = matchesReadableOwner(host, candidate)
    local runner = owner and owner.complete and owner.runnerSpellID == candidate.spellID
        and owner.runnerInstanceID == candidate.auraInstanceID
    local native = not owned and (candidate.tier.semantic or nativeTierEnabled(host, candidate.tier, true) == true)
    if owned or runner or native then
        return {tier=candidate.tier, spellID=candidate.spellID, auraInstanceID=candidate.auraInstanceID,
            helpful=candidate.helpful,soleNative=candidate.soleNative,
            owned=owned == true, native=native == true, nativeFirstMismatch=owned and owner.nativeFirstMismatch}
    end
end

local function tierSourceContradicted(host, source, primary)
    if not source or matchesReadableOwner(host, source) then return false end
    local owner = host._readableTierOwners and host._readableTierOwners[source.tier.key]
    -- A complete main helper intentionally disables the shared native slot.
    -- Its verified first and distinct runner can certify both old occurrences.
    if primary and primary.tier == source.tier and matchesReadableOwner(host,primary) then
        return owner.runnerSpellID ~= source.spellID or owner.runnerInstanceID ~= source.auraInstanceID
    end
    if source.owned and owner and owner.complete then return true end
    if source.nativeFirstMismatch and nativeTierEnabled(host, source.tier, true) == true then return true end
    return source.native and nativeTierEnabled(host, source.tier, true) == false
end

local function matchesGenericHelpful(host, primary, current, unit)
    if not host._hostileHelpfulEnabled or not nativeTierEnabled(host, primary.tier, true) then return false end
    if host._hostileActive then
        local presented = R.TIER_BY_KEY[host._hostileTierKey]
        if not presented or presented.level >= primary.tier.level then return false end
    end
    local filters = R.CandidateFilters(primary.tier)
    for _, candidate in ipairs(current) do
        if candidate.helpful and candidate.auraInstanceID > primary.auraInstanceID then
            local duration = read(candidate.aura, "duration")
            if duration ~= 0 then
                -- The native generic slot can ignore an ID exclusion on a
                -- restricted hostile aura. A newer timed/unknown occurrence
                -- must be *provably* excluded to certify the actual first.
                if not filters or not filters.excludeSpellIDs
                    or not filters.excludeSpellIDs[candidate.spellID]
                    or not (R.ExactFilterAllowed(unit,true,nil,false)
                        or R.AuraIsNeverSecret(candidate.spellID)) then return false end
            end
        end
    end
    return true
end

local hostileSemanticTiers = {
    Important=true, BigDef=true, ExternalDef=true, CrowdControl=true, PriorityDebuff=true,
}

local function couldPrecede(tier, candidate, place)
    local level = place.rankLevel or place.tier.level
    if tier.level ~= level then return tier.level > level end
    return tier.key ~= place.tier.key or candidate.auraInstanceID > place.auraInstanceID
end

local function couldChangePair(tier, candidate, first, second)
    if sameEffect(candidate,first) or (first.staticGhost and ghostAura(candidate.spellID)) then
        -- A lower presentation of the same first spell cannot fill second.
        return candidate.auraInstanceID ~= first.auraInstanceID and couldPrecede(tier,candidate,first)
    end
    if sameEffect(candidate,second) or (second.staticGhost and ghostAura(candidate.spellID)) then
        return couldPrecede(tier,candidate,first) or
            (candidate.auraInstanceID ~= second.auraInstanceID and couldPrecede(tier,candidate,second))
    end
    return couldPrecede(tier,candidate,second)
end

-- Inspect both distinct places. A newer occurrence can also change the
-- clock even when the spell art is identical. Disabled slots cannot draw;
-- a slot with unknown state remains a possible competitor.
local function nativeExclusionsAgree(host, primary, second, current, unit, cache)
    local identityAllowed = {}
    for _, entry in ipairs(getRankTiers()) do
        local tier = entry.tier
        if tier.level < (second.rankLevel or second.tier.level) then break end
        if tier.semantic then
            local filters = R.CandidateFilters(tier)
            local excluded = filters and filters.excludeSpellIDs
            local helpful = tier.filter:sub(1,7) == "HELPFUL"
            if excluded then
                local checked, state
                for _, candidate in ipairs(current) do
                    if candidate.helpful == helpful and excluded[candidate.spellID]
                        and couldChangePair(tier,candidate,primary,second)
                        and semanticFilterMatches(candidate, tier.candidateFilters) ~= false then
                        if candidate.nativeExclusionAllowed == nil then
                            if identityAllowed[helpful] == nil then
                                identityAllowed[helpful] = R.ExactFilterAllowed and
                                    R.ExactFilterAllowed(host.unit, helpful, nil, false) or false
                            end
                            candidate.nativeExclusionAllowed = identityAllowed[helpful] or
                                (R.AuraIsNeverSecret and R.AuraIsNeverSecret(candidate.spellID)) or false
                        end
                        if not candidate.nativeExclusionAllowed then
                            if not checked then
                                state = nativeSlotState(host.containers and host.containers[entry.index],true)
                                checked = true
                            end
                            if state ~= false and nativeSlotMatches(candidate.sourceUnit or unit, candidate, tier.filter, cache) ~= false then
                                return false
                            end
                        end
                    end
                end
            end
        end
    end
    return true
end

local function matchesHostileSemantic(host, primary, unit, cache)
    if not nativeTierEnabled(host, primary.tier, true)
        or nativeSlotMatches(unit, primary, primary.tier.filter, cache) ~= true then return false end
    if host._hostileActive then
        local helper = R.TIER_BY_KEY[host._hostileTierKey]
        if not helper or helper.level >= primary.tier.level then return false end
    end
    return true
end

local function soleNativeHarmful(host, primary, current, cache)
    local tier=primary.tier
    if not primary.aura or not primary.auraInstanceID or not tier.exact or primary.helpful~=false
        or not tier.spellIDs or not tier.spellIDs[primary.spellID]
        or host._hostileAuraListComplete~=true or host._hostileElectionReadable~=true
        or nativeTierEnabled(host,tier,true)~=true or nativeIdentityPermission(host.unit,primary)~=true
        or nativeSlotMatches(host.unit,primary,tier.filter,cache)~=true then return false end
    if host._hostileActive then
        local helpful=R.TIER_BY_KEY[host._hostileTierKey]
        if not helpful or helpful.level>=tier.level then return false end
    end
    -- Only one positively permitted occurrence may occupy this native slot.
    -- Even a second application of the same spell can own a different clock.
    for _,other in ipairs(current) do
        if other~=primary and other.helpful==false and tier.spellIDs[other.spellID]
            and nativeSlotMatches(host.unit,other,tier.filter,cache)~=false then return false end
    end
    return true
end

local function retainedSoleNative(host,source,reads)
    if not source or not source.soleNative then return true end
    local unit,tier=host.unit,source.tier
    local cache=rankCache(reads,unit)
    local enabled=nativeTierEnabled(host,tier,true)
    local permitted=nativeIdentityPermission(unit,source)
    local member=nativeSlotMatches(unit,source,tier.filter,cache)
    if enabled==false or permitted==false or member==false then return false end
    local list=reads and reads.unit==unit and (reads[tier.filter] or reads["HARMFUL|INCLUDE_NAME_PLATE_ONLY"])
    if type(list)~="table" then return true end -- no new complete index; ordinary hold limits still apply
    if enabled~=true or permitted~=true or member~=true then return false end
    local found=false
    for index,spell in ipairs(list.spellIDs) do
        if tier.spellIDs[spell] then
            local id=read(list.auras[index],"auraInstanceID")
            if type(id)~="number" or id<=0 then return false end
            if spell==source.spellID and id==source.auraInstanceID then found=true
            elseif nativeSlotMatches(unit,{auraInstanceID=id},tier.filter,cache)~=false then return false end
        end
    end
    return found
end

local function matchesLockout(record,spell,id)
    return record and (record.spellID==spell or (record.linkedSpells and record.linkedSpells[spell])
        or (id~=nil and (record.auraInstanceID==id or (record.linkedInstances and record.linkedInstances[id]))))
end

local function extraNativeAboveSchool(host,reads)
    local runner=host._secondaryDisplayedInterrupt
    if not runner or not reads or reads.unit~=host.unit then return false end
    local firstSpell,firstID=host._secondaryPrimarySpellID,host._secondaryPrimaryAuraInstanceID
    local other=host._schoolInterrupt
    if other==runner then other=host._secondSchoolInterrupt end
    local firstLockout=matchesLockout(other,firstSpell,firstID) and other or nil
    local cache=rankCache(reads,host.unit)
    -- One distinct native effect above the school runner can disprove the
    -- old pair, regardless of whether a helper or a native slot owns first.
    -- Use only complete per-polarity snapshots already obtained in this pass.
    for _,polarity in ipairs({"HELPFUL","HARMFUL"}) do
        local list=reads[polarity.."|INCLUDE_NAME_PLATE_ONLY"] or reads[polarity]
        if type(list)=="table" then
            for index,spell in ipairs(list.spellIDs) do
                local aura=list.auras[index]
                local id=read(aura,"auraInstanceID")
                if type(id)=="number" and id>0 and spell~=firstSpell and id~=firstID
                    and not matchesLockout(runner,spell,id) and not matchesLockout(firstLockout,spell,id) then
                    local candidate={aura=aura,spellID=spell,auraInstanceID=id,helpful=polarity=="HELPFUL",sourceUnit=host.unit}
                    local higher=candidateRank(host,candidate,cache,host.unit,host._secondaryPositiveLevel)
                    if higher and nativeTierEnabled(host,higher,true)==true
                        and (not higher.exact or nativeIdentityPermission(host.unit,candidate)==true) then return true end
                end
            end
        end
    end
    return false
end

local function interruptClockCurrent(record)
    local expiry=read(record,"expires")
    if not expiry then return true end
    local ok,now=pcall(GetTime)
    return ok and R.CanAccess(now) and type(now)=="number" and type(expiry)=="number"
        and now>=0 and now<expiry and expiry<math.huge
end

local function currentSchoolRunner(host,first)
    local other=first and host._secondSchoolInterrupt
    if other and not matchesLockout(first,other.spellID,other.auraInstanceID) and interruptClockCurrent(other) then
        return other
    end
end

function R.GetReadableSecondaryAura(host, reads)
    if reads then reads.nativeSecondWitness,reads.auraPairAboveStatic = nil,nil end
    if not supportsSecondary(host) then return nil, "unit-excluded" end
    if not host._buildComplete then return nil, "host-incomplete" end
    if host._schoolInterruptHidePending then return nil,"school-interrupt-hide-pending" end
    if not R.db or R.db.secondaryPortrait == false then return nil, "disabled" end
    if R.testMode then return nil, "test-mode" end
    if not getRankTiers() then return nil, "tiers-not-ready" end
    local auraUnit, verifiedSelf = currentAuraReadUnit(host)
    if host._hostileUnit == nil and not verifiedSelf then
        return nil, "relation-unreadable"
    end
    -- A positively identified self alias is friendly even when the target
    -- relation helper is temporarily unavailable. It is strictly stronger
    -- evidence than an untrusted name, faction or tooltip comparison.
    local hostile = not verifiedSelf and host._hostileUnit == true
    local ghostActive = provenGhost(host)
    local interrupt=host._schoolInterrupt
    local interruptTier=interrupt and R.TIER_BY_KEY.InterruptSilence
    if interrupt and not interruptTier then return nil,"school-interrupt-tier-unavailable" end
    if interrupt and not interruptClockCurrent(interrupt) then return nil,"school-interrupt-clock-unverified" end
    local otherInterrupt=currentSchoolRunner(host,interrupt)
    local npcHarmfulProjection = false
    local needsHarmfulOwner
    local knownHostileTarget = hostile and (host.unit == "target" or host.unit == "focus")
        and host._playerReadable == true and type(host._isPlayer) == "boolean"
    if hostile then
        if host._hostileRelationReadable ~= true then
            return nil, "hostile-relation-unreadable"
        end
        -- A positively identified NPC can be checked directly against the
        -- secondary reader's *own* complete helpful+harmful public snapshot.
        -- The separate hostile HELPFUL-only helper may be incomplete or its
        -- same-tier winner may be unorderable even though a higher harmful
        -- primary wins the combined election. Do not make its outcome a
        -- prerequisite for this independent NPC projection.
        --
        -- A hostile player needs an independently presented winner. When
        -- only an exact harmful helper can supply that witness, check it
        -- against both ranked occurrences below.
        local provenNPC = knownHostileTarget and not host._isPlayer
        npcHarmfulProjection = provenNPC
            -- Native generic harmful display is a valid NPC path when exact
            -- relation permission is missing; verify its real slot below.
            and (host._exactHarmfulAllowed == true
                or host._smallHarmfulEnabled == true)
        if not provenNPC and not ghostActive and (host._hostileAuraListComplete ~= true or
            host._hostileElectionReadable ~= true) then
            needsHarmfulOwner = "hostile-list-unreadable"
        elseif not npcHarmfulProjection and not (knownHostileTarget and host._hostileHelpfulEnabled == true)
            and not host._hostileActive
            and not host._formStateActive and not ghostActive then
            needsHarmfulOwner = "hostile-primary-unverified"
        end
        if needsHarmfulOwner then
            local possible=knownHostileTarget and interrupt~=nil
            if knownHostileTarget and host._isPlayer then
                for key, owner in pairs(host._readableTierOwners or {}) do
                    local tier = R.TIER_BY_KEY[key]
                    if tier and tier.exact and not tier.helpful and owner.complete then possible = true; break end
                end
            end
            if not possible then return nil, needsHarmfulOwner end
        end
    elseif host._assistable ~= true and not verifiedSelf then
        return nil, "assist-unreadable"
    end
    if host._ghostActive and not ghostActive then
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
    local current, reason = collectCurrentAuras(auraUnit, reads, host)
    if not current then return nil, reason end
    if interrupt and interrupt.bridgeWatch and R.SchoolInterruptLinksChanged(interrupt,current,auraUnit) then
        if not reads or not R.RecheckSchoolInterruptLinks then return nil,"school-interrupt-links-changed" end
        R.RecheckSchoolInterruptLinks(host,current,auraUnit)
        interrupt=host._schoolInterrupt
        if not interrupt or host._schoolInterruptHidePending or not interruptClockCurrent(interrupt) then
            return nil,"school-interrupt-links-changed"
        end
        otherInterrupt=currentSchoolRunner(host,interrupt)
    end
    -- A cast ID on one record and an applied aura ID on the other can
    -- identify one occurrence. Keep its highest school rank only.
    local otherIdentity=otherInterrupt
    if otherInterrupt and (interrupt.auraInstanceID or otherInterrupt.auraInstanceID) then
        for _,candidate in ipairs(current) do
            if (candidate.spellID==interrupt.spellID and candidate.auraInstanceID==otherInterrupt.auraInstanceID)
                or (candidate.spellID==otherInterrupt.spellID and candidate.auraInstanceID==interrupt.auraInstanceID) then
                otherIdentity=interrupt
                break
            end
        end
    end
    -- Rank the complete public union, including any NPC helpful auras.
    -- A harmful first-place projection is permitted only when it outranks
    -- every helpful candidate and its corresponding native slot is enabled.
    local ranked, unknown, seenSpellIDs, cache = {}, {}, {}, rankCache(reads, auraUnit)
    for _, candidate in ipairs(current) do
        if matchesLockout(interrupt,candidate.spellID,candidate.auraInstanceID) then
            candidate.lockoutIdentity=interrupt
        end
        if matchesLockout(otherInterrupt,candidate.spellID,candidate.auraInstanceID) then
            candidate.lockoutIdentity=otherIdentity
        end
        if not (ghostActive and ghostAura(candidate.spellID)) then
            -- All observed helpful exact competitors in this complete public
            -- snapshot must be counted even if the separate helper couldn't
            -- order them. Only the winning harmful helper can use this proof.
            local tier, why, ceiling = candidateRank(host, candidate, cache, auraUnit, nil, needsHarmfulOwner)
            if why then
                unknown[#unknown+1] = {spellID=candidate.spellID,lockoutIdentity=candidate.lockoutIdentity,
                    reason=why, level=ceiling or math.huge}
            elseif tier then
                candidate.tier = tier
                if RECENCY_TIERS[tier.key] then
                    if candidate.physicalTier ~= tier then candidate.start = tryGetAuraStart(candidate.sourceUnit, candidate) end
                end
                ranked[#ranked+1] = candidate
                if candidate.unavailableExactTier ~= tier then seenSpellIDs[candidate.spellID] = true end
            end
        end
    end
    local staticLevel
    if ghostActive then
        -- Aura buttons draw at level+1, Ghost at Immunity+2.
        local immunity = R.TIER_BY_KEY and R.TIER_BY_KEY.Immunity
        local ghostLevel = (immunity and immunity.level or 330) + 2
        staticLevel = ghostLevel-1
        ranked[#ranked+1] = {staticGhost=true, spellID=8326, rankLevel=staticLevel,
            tier={key="GhostState", level=ghostLevel}}
    elseif host._formStateActive then
        staticLevel = (R.TIER_BY_KEY and R.TIER_BY_KEY.SelfState
            and R.TIER_BY_KEY.SelfState.level or 150) - 1
        if not seenSpellIDs[host._formStateSpellID] then
            ranked[#ranked+1] = {staticForm=true, spellID=host._formStateSpellID,
                tier={key="FormState", level=staticLevel}}
        end
    end
    if interrupt then
        -- Only the successfully painted LOC helper sets this record. Its
        -- physical priority is one above the ordinary silence aura lane.
        -- The optional linked occurrence is for deduplication, never an
        -- invented aura identity for the event or its cooldown.
        local rank=interruptTier.level+1
        staticLevel=math.max(staticLevel or rank,rank)
        for place,record in ipairs({interrupt,otherIdentity~=interrupt and otherInterrupt or nil}) do
            ranked[#ranked+1]={schoolInterrupt=record,schoolPlace=place,spellID=record.spellID,helpful=false,
                tier=interruptTier,rankLevel=rank,lockoutIdentity=record}
        end
    end
    local primary, why = nextRanked(ranked, unknown, nil, host)
    if why then return nil, why end
    if not primary then return nil, "not-two-presentable" end
    local second, secondWhy = nextRanked(ranked, unknown, primary)
    if secondWhy then return nil, secondWhy end
    if not second then
        if #ranked > 1 then
            for _,other in ipairs(ranked) do
                if not sameEffect(other,primary) then return nil,"alias-no-physical-runner" end
            end
            host._secondaryOnlyRepeatedSpell = primary.spellID
        end
        return nil, "not-two-presentable"
    end
    local formPrimary = primary.staticForm
    local electionReason = primary.staticGhost and "verified-ghost-then-aura"
        or second.staticGhost and "verified-aura-then-ghost"
        or formPrimary and "verified-form-then-aura"
        or second.staticForm and "verified-aura-then-form" or "verified-readable"
    if primary.schoolInterrupt then electionReason="verified-school-interrupt-primary"
    elseif second.schoolInterrupt then electionReason="verified-school-interrupt-secondary" end
    if primary.auraInstanceID and second.auraInstanceID
        and primary.auraInstanceID == second.auraInstanceID then
        return nil, "duplicate-aura"
    end
    local harmfulOwner = knownHostileTarget and primary.helpful == false and primary.tier.exact
        and matchesReadableOwner(host, primary)
    local nativeBeforeInterrupt=knownHostileTarget and host._isPlayer and second.schoolInterrupt
        and not harmfulOwner and soleNativeHarmful(host,primary,current,cache)
    if needsHarmfulOwner and not harmfulOwner and not primary.schoolInterrupt and not nativeBeforeInterrupt then
        return nil, needsHarmfulOwner
    end
    if primary.schoolInterrupt then
        if host._schoolInterrupt~=primary.schoolInterrupt then return nil,"school-interrupt-replaced" end
    elseif knownHostileTarget and hostileSemanticTiers[primary.tier.key] then
        if not matchesHostileSemantic(host, primary, auraUnit, cache) then
            return nil, "hostile-semantic-unverified"
        end
        electionReason = "hostile-native-semantic-projection"
    elseif harmfulOwner then
        electionReason = host._isPlayer and "hostile-readable-helper-projection" or "npc-readable-helper-projection"
    elseif nativeBeforeInterrupt then
        primary.soleNative=true
        electionReason="hostile-native-harmful-before-interrupt"
    elseif npcHarmfulProjection and primary.helpful == false then
        local generic = primary.tier.key == "SmallFriendlyHarmful" and host._smallHarmfulEnabled == true
        if not primary.tier.exact and not generic then return nil, "npc-primary-not-native-proven" end
        if nativeTierEnabled(host, primary.tier) then
            electionReason = "npc-readable-harmful-projection"
        else
            return nil, "npc-native-slot-unreadable"
        end
    elseif hostile and primary.tier.key == "HostileHelpful" then
        if not knownHostileTarget or not matchesGenericHelpful(host, primary, current, auraUnit) then
            return nil, "hostile-generic-unverified"
        end
        electionReason = "hostile-generic-helpful-projection"
    elseif hostile and not formPrimary and not primary.staticGhost then
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
    if knownHostileTarget then
        if second.tier.semantic and not nativeTierEnabled(host, second.tier, true) then
            return nil, "hostile-second-slot-unverified"
        end
    end
    -- Harmful IDs on assistable units have the same native exclusion
    -- limitation as helpful IDs on hostile units.
    if (knownHostileTarget or not hostile) and not nativeExclusionsAgree(host, primary, second, current, auraUnit, cache) then
        return nil, hostile and "hostile-native-pair-unverified" or "friendly-native-pair-unverified"
    end
    -- This self-alias result also depends on higher exact lanes that could
    -- not present a known occurrence. Retain only public identity/slot data.
    if verifiedSelf then
        local firstLevel=primary.rankLevel or primary.tier.level
        for _,candidate in ipairs(ranked) do
            if candidate.unavailableExactTier == candidate.tier and candidate.tier.level >= firstLevel then
                second.excludedHigher=second.excludedHigher or {}
                second.excludedHigher[#second.excludedHigher+1]={tier=candidate.tier,spellID=candidate.spellID,
                    auraInstanceID=candidate.auraInstanceID,helpful=candidate.helpful}
            end
        end
    end
    -- An art write may subsequently fail. Preserve this update's rank proof
    -- for the native fallback only when two real auras outrank the state.
    if reads and primary.aura and second.aura then
        reads.nativeSecondWitness = {unit=auraUnit,current=current,cache=cache,primary=primary,second=second}
        reads.auraPairAboveStatic = staticLevel and second.tier.level > staticLevel
    end
    return second, electionReason, primary
end

-- A form icon is an independent, currently displayed *state*, not an aura.
-- Prefer the image already proved and drawn by our form presenter; use the
-- public spell texture only when the icon cannot be read from that presenter.
-- Neither path can authorize a fabricated cooldown or aura instance.
local function publicSpellTexture(spellID)
    local getter = C_Spell and C_Spell.GetSpellTexture or GetSpellTexture
    if type(getter) == "function" then
        local ok, value = pcall(getter, spellID)
        if ok and R.CanAccess(value) and validIcon(value) then return value end
    end
end

local function currentStateTexture(host, candidate)
    local spellID = candidate.spellID
    local frame
    if candidate.staticGhost and provenGhost(host) then
        frame = host.readableGhostFrame
    elseif candidate.staticForm and host._formStateActive and host._formStateSpellID == spellID then
        frame = host.readableFormStateFrame
    else
        return nil
    end
    local formIcon = frame and frame.icon
    if formIcon and type(formIcon.GetTexture) == "function" then
        local ok, value = pcall(formIcon.GetTexture, formIcon)
        if ok and R.CanAccess(value) and validIcon(value) then return value end
    end
    return publicSpellTexture(spellID)
end

local function positiveFinite(value)
    return type(value) == "number" and value > 0 and value < math.huge
end

local function auraClockObject(candidate,unit)
    if candidate.clockObjectUnit~=unit then
        candidate.clockObjectUnit,candidate.clockObject=unit,nil
        local getter=C_UnitAuras and C_UnitAuras.GetAuraDuration
        if type(getter)=="function" then
            local ok,object=pcall(getter,unit,candidate.auraInstanceID)
            if ok and R.CanAccess(object) then candidate.clockObject=object end
        end
    end
    return candidate.clockObject
end

local function trySecondaryAuraClock(host, candidate, aura, source, readUnit)
    if currentAuraReadUnit(host) ~= readUnit then return false end
    local cooldown = host.secondaryCooldown
    local duration = read(aura, "duration")
    if duration == 0 then return true,nil,0 end -- clearSecondaryCooldown already hid the old timer.
    if not cooldown then return false end
    local expires = read(aura, "expirationTime")
    local timeMod, modReadable = read(aura, "timeMod")
    if modReadable and timeMod == nil then timeMod = 1 end
    local expiry = positiveFinite(duration) and positiveFinite(expires) and expires or nil
    local applied = false
    local numericSetter = read(cooldown, "SetCooldown")
    if expiry and positiveFinite(timeMod) and type(numericSetter) == "function" then
        local ok, result = pcall(numericSetter, cooldown, expiry-duration, duration, timeMod)
        applied = ok and R.CanAccess(result) and result ~= false
    end
    local numericClock = applied
    local object
    if not applied then
        -- The current election supplies both the public source and instance.
        -- Pass the fresh LuaDurationObject straight through, including zero
        -- durations, without asking for its start, duration, or remaining time.
        local nativeSetter = read(cooldown, "SetCooldownFromDurationObject")
        if type(nativeSetter) ~= "function"
            or currentAuraReadUnit(host) ~= readUnit then return false end
        object=auraClockObject(candidate,source)
        if object==nil then return false end
        local ok, result = pcall(nativeSetter, cooldown, object, true)
        if not ok or not R.CanAccess(result) or result == false then return false end
    end
    if R.ApplyCountdownFormat then R.ApplyCountdownFormat(cooldown) end
    if R.ApplySecondaryCountdownFont then R.ApplySecondaryCountdownFont(cooldown) end
    local show = read(cooldown, "Show")
    local ok, result = pcall(show, cooldown)
    return ok and R.CanAccess(result) and result ~= false, expiry,
        numericClock and duration or nil, numericClock and timeMod or nil,object
end

local function setSecondaryAuraClock(host, candidate)
    local unit=candidate.readUnit or candidate.sourceUnit
    if candidate.physicalClockConflict then
        local ok,expiry,duration,rate,object=trySecondaryAuraClock(host,candidate,candidate.physicalAura,candidate.physicalUnit,unit)
        return ok,expiry,duration,rate,candidate.physicalUnit,object
    end
    local applied,expiry,duration,rate,object=trySecondaryAuraClock(host,candidate,candidate.aura,candidate.sourceUnit,unit)
    if applied or not candidate.physicalUnit then return applied,expiry,duration,rate,candidate.sourceUnit,object end
    -- Both tokens positively identified this same spell and occurrence.
    -- Use the physical helper's readable timing or its own native handle.
    applied,expiry,duration,rate,object=trySecondaryAuraClock(host,candidate,candidate.physicalAura,candidate.physicalUnit,unit)
    return applied,expiry,duration,rate,candidate.physicalUnit,object
end

local function rankDeadline(primary, secondaryExpiry)
    if not primary or not positiveFinite(secondaryExpiry) then return nil end
    if primary.staticGhost or primary.staticForm then return secondaryExpiry end
    if primary.schoolInterrupt then
        local expires=read(primary.schoolInterrupt,"expires")
        if positiveFinite(expires) then return math.min(expires,secondaryExpiry) end
        return nil
    end
    local aura=primary.physicalClockConflict and primary.physicalAura or primary.aura
    local duration = read(aura, "duration")
    if duration == 0 then return secondaryExpiry end
    local expiry = read(aura, "expirationTime")
    if positiveFinite(duration) and positiveFinite(expiry) then
        return math.min(secondaryExpiry, expiry)
    end
end

local function relevantOwner(host,key,owner)
    local tier=R.TIER_BY_KEY[key]
    return tier and tier.level >= host._secondaryPositiveLevel and owner.complete and owner.frame
        and host[owner.frameKey]==owner.frame and owner.frame.cooldown==owner.cooldown
end

local function currentBadgeGUID(host)
    if host.unit~="player" and type(UnitGUID)=="function" then
        local ok,guid=pcall(UnitGUID,host.unit)
        if ok and R.CanAccess(guid) and type(guid)=="string" and guid~="" then return guid end
    end
end

local function interruptRelevant(host,record)
    if not record then return false end
    local tier=R.TIER_BY_KEY and R.TIER_BY_KEY.InterruptSilence
    if not tier or not host._secondaryPositiveLevel or host._secondaryPositiveLevel<=tier.level+1 then return true end
    -- A lower lockout can still join the two higher spells through its
    -- reported spell or linked occurrence; that evidence needs re-election.
    return record.spellID==host._secondaryPrimarySpellID or record.spellID==host._secondaryAuraSpellID
        or (record.auraInstanceID and (record.auraInstanceID==host._secondaryPrimaryAuraInstanceID
            or record.auraInstanceID==host._secondaryAuraInstanceID))
end

local function changedRelevantInterrupt(host,previous,current)
    return previous~=current and (interruptRelevant(host,previous) or interruptRelevant(host,current))
end

local function rememberSecondaryElection(host,candidate,primary,expiry,guid,reused)
    local deadline=rankDeadline(primary,expiry)
    -- The callback closes over this host and the absolute deadline. Keep
    -- its accepted ticket only for the same binding and ranked pair. The
    -- current election below still replaces every retained source witness.
    local sameWake=reused and host._secondaryExpiryTicket and deadline==host._secondaryPositiveExpiry
        and guid==host._secondaryPositiveGUID and primary.spellID==host._secondaryPrimarySpellID
        and primary.auraInstanceID==host._secondaryPrimaryAuraInstanceID
        and (not host._secondaryPrimarySource or primary.tier==host._secondaryPrimarySource.tier)
        and (candidate.rankLevel or candidate.tier.level)==host._secondaryPositiveLevel
        and host._secondaryPositiveHostile==host._hostileUnit and host._secondaryPositiveAssist==host._assistable
        and host._secondaryPositiveGhost==(host._ghostActive==true)
        and host._secondaryPositiveForm==(host._formStateActive and host._formStateSpellID or nil)
        and not changedRelevantInterrupt(host,host._secondaryPositiveInterrupt,host._schoolInterrupt)
        and not changedRelevantInterrupt(host,host._secondaryPositiveSecondInterrupt,host._secondSchoolInterrupt)
    if not sameWake then host._secondaryExpiryTicket=nil end
    -- Only a timed positive has a clock that can bound temporary retention.
    -- A permanent/unreadable lifetime is never kept on old evidence alone.
    host._secondaryPositiveExpiry = deadline
    host._secondaryPositiveInterrupt,host._secondaryPositiveSecondInterrupt=host._schoolInterrupt,host._secondSchoolInterrupt
    host._secondaryPrimarySpellID,host._secondaryPrimaryAuraInstanceID=primary.spellID,primary.auraInstanceID
    host._secondaryPositiveLevel=candidate.rankLevel or candidate.tier.level
    host._secondaryHigherOwners=nil
    if host._secondaryPositiveExpiry then
        for key,owner in pairs(host._readableTierOwners or {}) do
            if relevantOwner(host,key,owner) then
                host._secondaryHigherOwners=host._secondaryHigherOwners or {}
                host._secondaryHigherOwners[key]={first=owner.auraInstanceID,runner=owner.runnerInstanceID}
            end
        end
    end
    host._secondaryPositiveHostile, host._secondaryPositiveAssist = host._hostileUnit, host._assistable
    host._secondaryPrimarySource = host._secondaryPositiveExpiry and captureTierSource(host, primary)
    host._secondarySecondSource = host._secondaryPositiveExpiry and captureTierSource(host, candidate)
    host._secondaryExcludedHigher = host._secondaryPositiveExpiry and candidate.excludedHigher
    host._secondaryPositiveGhost = host._ghostActive == true
    host._secondaryPositiveForm = host._formStateActive and host._formStateSpellID or nil
    host._secondaryAuraEventDirty = false
    host._secondaryPositiveGUID=guid
end

local function bindSchoolClock(host,record,retries)
    if not host.secondaryCooldown or not R.SetSchoolInterruptClock then return false end
    local applied,timed,source=R.SetSchoolInterruptClock(host.secondaryCooldown,record)
    if not applied then return false end
    host._secondaryInterruptClockSource=source
    host._secondaryInterruptClockObject=source=="object" and record.durationObject or nil
    host._secondaryInterruptClockPending=not timed and (record.expires or record.durationObject) and true or nil
    host._secondaryInterruptClockRetries=host._secondaryInterruptClockPending and retries or nil
    return true
end

local function schoolObjectChanged(host,record)
    if host._secondaryInterruptClockSource=="object" then
        return not rawequal(host._secondaryInterruptClockObject,record.durationObject)
    end
    if host._secondaryInterruptClockSource=="numeric" then return false end
    if host._secondaryInterruptClockPending then return not record.expires and not record.durationObject end
    return record.durationObject~=nil
end

local function sameSchoolOutput(host,record)
    local old=host._secondaryDisplayedInterrupt
    return old and host._secondaryAuraTexture==record.icon and host._secondaryClockExpiry==record.expires
        and old.spellID==record.spellID and old.auraInstanceID==record.auraInstanceID
        and old.startTime==record.startTime and old.duration==record.duration
        and old.lockoutSchool==record.lockoutSchool and old.requiresPlayer==record.requiresPlayer
end

local function sameAuraOutput(host,candidate)
    if not candidate.aura or host._secondaryMode~="aura" or candidate.spellID~=host._secondaryAuraSpellID
        or candidate.auraInstanceID~=host._secondaryAuraInstanceID or candidate.tier.key~=host._secondaryAuraTier
        or currentAuraReadUnit(host)~=(candidate.readUnit or candidate.sourceUnit) then return false end
    local texture=read(candidate.aura,"icon")
    if not validIcon(texture) then texture=publicSpellTexture(candidate.spellID) end
    if texture~=host._secondaryAuraTexture then return false end
    local aura,unit=candidate.aura,candidate.sourceUnit
    if candidate.physicalUnit and (candidate.physicalClockConflict or candidate.physicalUnit==host._secondaryClockSource) then
        aura,unit=candidate.physicalAura,candidate.physicalUnit
    end
    if unit~=host._secondaryClockSource then return false end
    local duration=read(aura,"duration")
    local expiry=read(aura,"expirationTime")
    if host._secondaryAuraClockObject then
        local numericExpiry=positiveFinite(duration) and positiveFinite(expiry) and expiry or nil
        return duration~=0 and numericExpiry==host._secondaryClockExpiry
            and rawequal(auraClockObject(candidate,unit),host._secondaryAuraClockObject)
    end
    if duration==0 then return host._secondaryClockDuration==0 end
    local rate,known=read(aura,"timeMod")
    return positiveFinite(duration) and duration==host._secondaryClockDuration and expiry==host._secondaryClockExpiry
        and known and (rate==nil and 1 or rate)==host._secondaryClockRate
end

local function showSecondaryAura(host, candidate, primary, guid)
    local icon = host.racePortrait
    if not icon or not host.secondaryBadge or not candidate then return false end
    local texture, expiry, duration, rate, clockSource, clockObject
    local static = candidate.staticGhost or candidate.staticForm
    if candidate.schoolInterrupt then
        if host._schoolInterrupt~=candidate.schoolInterrupt and host._secondSchoolInterrupt~=candidate.schoolInterrupt then return false end
        texture=read(candidate.schoolInterrupt,"icon")
    elseif static then
        texture = currentStateTexture(host, candidate)
    else
        texture = read(candidate.aura, "icon")
        if not validIcon(texture) then texture = publicSpellTexture(candidate.spellID) end
    end
    if not validIcon(texture) then return false end
    -- Clock, crop and texture share this region with the race fallback. A
    -- failed partial handoff must never leave its old cache key committed.
    host._secondaryArtKey = nil
    local cleared = clearSecondaryCooldown(host)
    if not cleared and (static or read(candidate.aura, "duration") == 0) then return false end
    if candidate.schoolInterrupt then
        if not cleared or not bindSchoolClock(host,candidate.schoolInterrupt,2) then return false end
        if R.ApplyCountdownFormat then R.ApplyCountdownFormat(host.secondaryCooldown) end
        if R.ApplySecondaryCountdownFont then R.ApplySecondaryCountdownFont(host.secondaryCooldown) end
        local ok,result=pcall(host.secondaryCooldown.Show,host.secondaryCooldown)
        if not ok or not R.CanAccess(result) or result==false then return false end
        expiry=read(candidate.schoolInterrupt,"expires")
    elseif not static then
        local applied
        applied, expiry, duration, rate, clockSource, clockObject = setSecondaryAuraClock(host, candidate)
        if not applied then return false end
    end
    if host._secondaryAuraTexture ~= texture then
        host._secondaryAuraTexture = nil
        local success, wrote = pcall(icon.SetTexture, icon, texture)
        if not success or not R.CanAccess(wrote) or wrote == false then return false end
        if not applySecondaryArtCrop(icon) then return false end
    end
    local shown,result=pcall(host.secondaryBadge.Show,host.secondaryBadge)
    if not shown or not R.CanAccess(result) or result==false then return false end
    host._secondaryAuraTexture = texture
    host._secondaryClockDuration, host._secondaryClockExpiry, host._secondaryClockRate = duration, expiry, rate
    host._secondaryClockSource = clockSource or candidate.sourceUnit
    host._secondaryAuraClockObject=clockObject
    host._secondaryDisplayedInterrupt = candidate.schoolInterrupt
    if not candidate.schoolInterrupt then
        host._secondaryInterruptClockSource,host._secondaryInterruptClockObject=nil,nil
        host._secondaryInterruptClockPending,host._secondaryInterruptClockRetries=nil,nil
    end
    host._secondaryMode = candidate.schoolInterrupt and "interrupt" or candidate.staticGhost and "ghost"
        or candidate.staticForm and "form" or "aura"
    host._secondaryAuraInstanceID = candidate.auraInstanceID
    host._secondaryAuraSpellID = candidate.spellID
    host._secondaryAuraTier = candidate.tier.key
    rememberSecondaryElection(host,candidate,primary,expiry,guid)
    host._raceBaselineAtlas, host._raceBaselineActive = nil, false
    host._raceBaselineReason = "secondary-aura"
    return true
end

-- UNIT_AURA does not always mean the *two elected* effects changed.
-- A precise incremental update describing ONLY removal of other aura IDs
-- leaves the current top two unchanged. In particular, an unrelated aura
-- can expire as combat begins while the public full aura list becomes secret.
-- All additions, updates, full/unknown/secret payloads, and removals of
-- either winner still revoke the previous ranking. No inferred spell data.
local function deltaSize(list)
    if list==nil then return 0 end
    if not R.CanAccess(list) or type(list)~="table" then return nil end
    local ok,length=pcall(function() return #list end)
    if ok and R.CanAccess(length) and type(length)=="number" and length>=0 and length<=AURA_SCAN_LIMIT*2 then
        return length
    end
end

local function changesSchoolLinks(watch,info)
    if not watch then return false end
    local full,known=read(info,"isFullUpdate")
    if not known or full~=false then return true end
    for _,key in ipairs({"addedAuras","updatedAuraInstanceIDs","removedAuraInstanceIDs"}) do
        local list,ok=read(info,key)
        local count=ok and deltaSize(list)
        if not count then return true end
        for i=1,count do
            local value,readable=read(list,i)
            if not readable then return true end
            local id=value
            if key=="addedAuras" then id=read(value,"auraInstanceID") end
            if type(id)~="number" or id<=0 then return true end
            if key=="removedAuraInstanceIDs" then
                if watch.links and watch.links[id] then return true end
            elseif watch.instances[id] then return true end
        end
    end
    return false
end

local function onlyUnrelatedRemovals(host, updateInfo)
    if not R.CanAccess(updateInfo) or type(updateInfo) ~= "table"
        or (not host._secondaryAuraInstanceID and host._secondaryMode~="interrupt") then return false end
    local full, fullOK = read(updateInfo, "isFullUpdate")
    local added, addedOK = read(updateInfo, "addedAuras")
    local changed, changedOK = read(updateInfo, "updatedAuraInstanceIDs")
    local removed, removedOK = read(updateInfo, "removedAuraInstanceIDs")
    if not (fullOK and addedOK and changedOK and removedOK)
        or full ~= false then return false end

    local addedCount, changedCount, removedCount = deltaSize(added), deltaSize(changed), deltaSize(removed)
    if addedCount ~= 0 or changedCount ~= 0 or not removedCount
        or removedCount == 0 then return false end
    for index = 1, removedCount do
        local ok, id = pcall(function() return removed[index] end)
        if not ok or not R.CanAccess(id) or type(id) ~= "number"
            or id <= 0 or id == host._secondaryAuraInstanceID
            or id == host._secondaryPrimaryAuraInstanceID
            or (interruptRelevant(host,host._secondaryPositiveInterrupt) and id==read(host._secondaryPositiveInterrupt,"auraInstanceID"))
            or (interruptRelevant(host,host._secondaryPositiveSecondInterrupt) and id==read(host._secondaryPositiveSecondInterrupt,"auraInstanceID")) then
            return false
        end
        local excluded=host._secondaryExcludedHigher
        if excluded then
            for i=#excluded,1,-1 do
                if excluded[i].auraInstanceID==id then table.remove(excluded,i) end
            end
        end
    end
    return true
end

-- Call before the UNIT_AURA refresh, using its guarded public delta when
-- available. This function never reads secret aura spell IDs or durations.
function R.NoteSecondaryAuraEvent(unit, updateInfo)
    if not SECONDARY_UNITS[unit] then return end
    local host = R.hosts and R.hosts[unit]
    if host and changesSchoolLinks(host._schoolInterrupt and host._schoolInterrupt.bridgeWatch,updateInfo) then
        host._schoolInterruptChecked=nil
        host._secondaryAuraEventDirty=true
        host._secondaryLastEventEffect="school-link-change"
        return
    end
    if not host or (host._secondaryMode~="aura" and host._secondaryMode~="interrupt") then return end
    if onlyUnrelatedRemovals(host, updateInfo) then
        host._secondaryLastEventEffect = "unrelated-removal"
        return
    end
    host._secondaryLastEventEffect = "changed-or-unreadable"
    host._secondaryAuraEventDirty = true
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
    ["unchanged-current-positive"] = true,
}
local function newHigherOccurrence(host,spell,id,previous)
    return id and id~=previous
        and not (spell==host._secondaryPrimarySpellID and id==host._secondaryPrimaryAuraInstanceID)
        and not (spell==host._secondaryAuraSpellID and id==host._secondaryAuraInstanceID)
end

local function armRetainedExpiry(host,now,expires)
    if host._secondaryExpiryTicket then return true end
    local function schedule(delay,allowEarlyRetry)
        local after=C_Timer and C_Timer.After
        if type(after)~="function" then return false end
        local ticket={}
        host._secondaryExpiryTicket=ticket
        local scheduling=true
        local function wake()
            if host._secondaryExpiryTicket~=ticket or (R.hosts and R.hosts[host.unit]~=host) then return end
            host._secondaryExpiryTicket=nil
            -- A synchronous callback cannot promise a future wakeup.
            if scheduling then return end
            if allowEarlyRetry then
                local ok,current=pcall(GetTime)
                if ok and R.CanAccess(current) and type(current)=="number" and current>=0
                    and current<expires and schedule(expires-current,false) then return end
            end
            host._secondaryAuraEventDirty=true
            if R.Refresh then R.Refresh(host.unit) else hideBadge(host,"combat-positive-expired") end
        end
        local ok,result=pcall(after,delay,wake)
        scheduling=false
        if ok and R.CanAccess(result) and result~=false and host._secondaryExpiryTicket==ticket then return true end
        if host._secondaryExpiryTicket==ticket then host._secondaryExpiryTicket=nil end
        return false
    end
    return schedule(expires-now,true)
end

local function retainCombatPositive(host, reason, reads)
    if not HOLD_READ_FAILURE[reason] or (host._secondaryMode~="aura" and host._secondaryMode~="interrupt")
        or changedRelevantInterrupt(host,host._secondaryPositiveInterrupt,host._schoolInterrupt)
        or changedRelevantInterrupt(host,host._secondaryPositiveSecondInterrupt,host._secondSchoolInterrupt)
        or host._secondaryAuraEventDirty or (not host._secondaryAuraInstanceID and host._secondaryMode~="interrupt")
        or not host.secondaryBadge or not host.secondaryCooldown
        or not host._secondaryPositiveExpiry then return false end
    if host._secondaryPositiveGhost ~= (host._ghostActive == true)
        or host._secondaryPositiveForm ~= (host._formStateActive and host._formStateSpellID or nil) then
        return false
    end
    -- A secret read can leave previous evidence intact. A current, readable
    -- relation change or revoked display source contradicts that election.
    if (type(host._secondaryPositiveHostile) == "boolean" and type(host._hostileUnit) == "boolean"
        and host._secondaryPositiveHostile ~= host._hostileUnit)
        or (type(host._secondaryPositiveAssist) == "boolean" and type(host._assistable) == "boolean"
        and host._secondaryPositiveAssist ~= host._assistable)
        or tierSourceContradicted(host, host._secondaryPrimarySource)
        or not retainedSoleNative(host,host._secondaryPrimarySource,reads)
        or extraNativeAboveSchool(host,reads)
        or tierSourceContradicted(host, host._secondarySecondSource, host._secondaryPrimarySource) then return false end
    if host._secondaryPositiveLevel then
        for key,owner in pairs(host._readableTierOwners or {}) do
            if relevantOwner(host,key,owner) then
                local old=host._secondaryHigherOwners and host._secondaryHigherOwners[key]
                if newHigherOccurrence(host,owner.spellID,owner.auraInstanceID,old and old.first) then return false end
                -- If the retained secondary heads this lane, its runner is
                -- necessarily below it. Otherwise check both distinct places.
                if owner.auraInstanceID~=host._secondaryAuraInstanceID
                    and newHigherOccurrence(host,owner.runnerSpellID,owner.runnerInstanceID,old and old.runner) then
                    return false
                end
            end
        end
    end
    if host._secondaryExcludedHigher then
        for _,source in ipairs(host._secondaryExcludedHigher) do
            if matchesReadableOwner(host,source) or (nativeTierEnabled(host,source.tier,true) == true
                and nativeIdentityPermission(host.unit,source) == true) then return false end
        end
    end
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
    if not armRetainedExpiry(host,now,expires) then return false end
    local record=host._secondaryDisplayedInterrupt
    if record and schoolObjectChanged(host,record) and not bindSchoolClock(host,record,2) then return false end
    host._secondaryElectionReason = "combat-positive-retained:" .. reason
    return true
end

function R.ReconcileSecondaryPortrait(host, enabled, isPlayer, reads)
    if not supportsSecondary(host) then return end
    host._secondaryOnlyRepeatedSpell = nil
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
    if not visibleOwner(host) then return end
    if R.testMode then
        -- /bp test owns a clearly synthetic small icon, not live evidence.
        R.PreviewSecondaryPortrait(host)
        return
    end
    local second, reason, primary = R.GetReadableSecondaryAura(host, reads)
    local guid=second and currentBadgeGUID(host)
    local sameBinding=not (reads and reads.bindingBarrier) and
        (host.unit=="player" or (guid==host._secondaryPositiveGUID
            and (guid~=nil or host.unit=="target" or host.unit=="focus")))
    -- The fresh, complete election authorizes this visible output for the
    -- current recipient. A future timer is necessary only for a sealed hold.
    if second and sameBinding and second.schoolInterrupt and host._secondaryMode=="interrupt"
        and sameSchoolOutput(host,second.schoolInterrupt) then
        local record=second.schoolInterrupt
        local changedObject=schoolObjectChanged(host,record)
        local rebound=false
        if changedObject or host._secondaryInterruptClockPending then
            local explicit=reads and reads.interruptRefresh
            local retries=host._secondaryInterruptClockRetries or 0
            if changedObject or explicit or retries>0 then
                if not bindSchoolClock(host,record,(changedObject or explicit) and 2 or retries-1) then
                    R.UpdateSecondaryPortrait(host,isPlayer)
                    host._secondaryElectionReason="school-interrupt-clock-unavailable"
                    return
                end
                rebound=true
            end
        end
        host._secondaryDisplayedInterrupt=record
        rememberSecondaryElection(host,second,primary,record.expires,guid,not rebound)
        host._secondaryElectionReason=reason
        return
    end
    if second and sameBinding and sameAuraOutput(host,second) then
        rememberSecondaryElection(host,second,primary,host._secondaryClockExpiry,guid,true)
        host._secondaryElectionReason=reason
        return
    end
    if second and showSecondaryAura(host, second, primary, guid) then
        host._secondaryPrimaryAuraInstanceID =
            primary and primary.auraInstanceID or nil
        host._secondaryElectionReason = reason
        return
    end
    -- Entering combat may seal an otherwise readable aura list. Retain only
    -- the last verified timed aura without an unproven ranking change.
    if not second and not (reads and reads.bindingBarrier) and retainCombatPositive(host, reason, reads) then return end
    if host._secondaryMode == "aura" then
        host._secondaryLastFallback = {
            reason = second and "presentation-unavailable" or reason,
            spellID = host._secondaryAuraSpellID,
            event = host._secondaryLastEventEffect or "none",
            dirty = host._secondaryAuraEventDirty == true,
            writes = host._containerWriteFailures or 0,
        }
    end
    R.UpdateSecondaryPortrait(host, isPlayer)
    host._secondaryElectionReason = second and "presentation-unavailable" or reason
end
