local addonName, BP = ...
local R = assert(BP.Runtime, "Core.lua must load first")

-- P1 visual prototype. This file deliberately does NOT claim to elect the
-- second-highest aura: Forever's public secure slot API returns one native
-- winner but cannot safely expose or exclude the winner across all tiers.
-- It renders only positively identified race art, or explicit /bp test art.
-- The main native/class portrait remains untouched when no aura is selected.

local MIRROR_LEFT = {
    target = true, focus = true, focustarget = true,
}
local COMPACT = {
    targettarget = true, focustarget = true,
    party1 = true, party2 = true, party3 = true, party4 = true,
}

local function hideBadge(host, reason)
    if not host then return end
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

function R.CreateSecondaryPortrait(host, nativeStrata)
    if not host or host.unit == "pet" or not host.layer or not host.portrait then return false end
    local compact = COMPACT[host.unit] == true
    local width, imageSize, borderSize = compact and 29 or 37,
        compact and 18 or 22, compact and 24 or 30
    local badge
    local ok = pcall(function()
        -- Opt in to forbidden-layout-safe anchoring at allocation. Do not use
        -- the native interactive totem widget or acquire protected unit clicks.
        badge = CreateFrame("Frame", nil, host.layer, R.AURA_ANCHOR_TEMPLATE)
        host.secondaryBadge = badge
        badge:Hide()
        badge:SetSize(width, width)
        badge:SetFrameStrata(nativeStrata or host.strata or "LOW")
        local nativeLevel = 0
        if host.unitFrame and type(host.unitFrame.GetFrameLevel) == "function" then
            local levelOK, level = pcall(host.unitFrame.GetFrameLevel, host.unitFrame)
            if levelOK and R.CanAccess(level) and type(level) == "number"
                and level >= 0 and level < 10000 then nativeLevel = level end
        end
        badge:SetFrameLevel(nativeLevel + 5)
        badge:EnableMouse(false)
        local side = MIRROR_LEFT[host.unit] and "TOPLEFT" or "TOPRIGHT"
        -- The portrait, not the health fill, is the non-secret geometry anchor.
        badge:SetPoint("CENTER", host.portrait, side, 0, compact and 2 or 0)

        local icon = badge:CreateTexture(nil, "ARTWORK")
        icon:SetSize(imageSize, imageSize)
        icon:SetPoint("CENTER", badge, "CENTER", 0, 0)
        host.racePortrait = icon
        local mask = badge:CreateMaskTexture(nil, "ARTWORK")
        mask:SetAtlas("CircleMask", false)
        mask:SetAllPoints(icon)
        icon:AddMaskTexture(mask)
        host.secondaryMask = mask

        local rim = badge:CreateTexture(nil, "OVERLAY")
        rim:SetSize(borderSize, borderSize)
        rim:SetPoint("CENTER", badge, "CENTER", compact and 0.5 or 1,
            compact and -1 or -1.5)
        rim:SetAtlas("UI-HUD-UnitFrame-TotemFrame", false)
        host.secondaryBorder = rim
    end)
    if not ok then
        hideBadge(host, "creation-unavailable")
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

    local icon = host.racePortrait
    local ok, result
    if isAtlas then
        -- The atlas's texcoords are already the exact race tile coordinates.
        -- Never apply generic SetTexCoord after SetAtlas.
        ok, result = pcall(icon.SetAtlas, icon, art, false)
    else
        ok, result = pcall(icon.SetTexture, icon, art)
        if ok and result ~= false then
            ok = pcall(icon.SetTexCoord, icon, unpack(coords))
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
