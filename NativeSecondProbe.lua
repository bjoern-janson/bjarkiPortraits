local addonName, BP = ...
local R = assert(BP.Runtime, "Core.lua must load first")

-- Experimental secure-ribbon runner-up on hostile targets plus a guarded
-- PlayerFrame fallback when public secondary election loses aura evidence.
-- Opposite-faction players and hostile NPCs share the native Target path;
-- on Player, the native second is visible ONLY while the ordinary reader
-- falls back to race and no independently presented static state competes.
-- Native rendering does not disclose secret aura identities to Lua.
--
-- A single native CustomAuraContainer owns multiple groups, ordered by the
-- existing R.TIERS. Each group contributes at most TWO native aura buttons.
-- The first button is physically outside a fixed clipping viewport; the
-- SECOND globally ordered button occupies the small portrait's position.
-- No addon Lua value is read from a secure aura button or aura group.
--
-- Both supported hosts initialize automatically while out of combat:
-- PlayerFrame prepares once at the first eligible update, Target lazily
-- initializes on the first hostile unit. No command or saved toggle.
-- Unverified native layout/semantic overlap remain experimental; this does
-- not replace the primary native tier stack or the readable election.

local CELL = 37
local IMAGE = 22
local RIM = 30
local MAX_GROUPS = 80
local pool = {}

local function usableStrata(host)
    local badge = host and host.secondaryBadge
    if badge and type(badge.GetFrameStrata) == "function" then
        local ok, strata = pcall(badge.GetFrameStrata, badge)
        if ok and R.CanAccess(strata) and type(strata) == "string" then
            return strata
        end
    end
    return "HIGH"
end

local function makeButton(button)
    -- Invoked by Blizzard during the group frame-provider's initial
    -- preallocation. Never use aura existence/count/ID in this callback.
    button:SetSize(CELL, CELL)
    button:EnableMouse(false)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(IMAGE, IMAGE)
    icon:SetPoint("CENTER", button, "CENTER")
    local mask = button:CreateMaskTexture(nil, "ARTWORK")
    mask:SetAtlas("CircleMask", false)
    mask:SetAllPoints(icon)
    icon:AddMaskTexture(mask)
    button:SetIcon(icon)

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetAtlas("UI-HUD-UnitFrame-TotemFrame", false)
    border:SetSize(RIM, RIM)
    border:SetPoint("CENTER", button, "CENTER", 1, -1.5)

    local cooldown = CreateFrame("Cooldown", nil, button,
        "CooldownFrameTemplate," .. R.AURA_ANCHOR_TEMPLATE)
    cooldown:SetAllPoints(icon)
    if cooldown.SetDrawBling then cooldown:SetDrawBling(false) end
    if cooldown.SetDrawEdge then cooldown:SetDrawEdge(false) end
    if cooldown.SetDrawSwipe then cooldown:SetDrawSwipe(false) end
    if cooldown.SetReverse then cooldown:SetReverse(true) end
    if cooldown.SetUsingParentLevel then cooldown:SetUsingParentLevel(true) end
    if R.ApplyCountdownFormat then R.ApplyCountdownFormat(cooldown) end
    button:SetDurationCooldown(cooldown)
end

local function orderedTiers()
    local result = {}
    for index, tier in ipairs(R.TIERS or {}) do
        result[#result+1] = {index=index, tier=tier}
    end
    table.sort(result, function(a, b)
        if a.tier.level ~= b.tier.level then
            return a.tier.level > b.tier.level
        end
        return a.index < b.index
    end)
    return result
end

-- Primary slots may share an aura in different lanes because ONLY their
-- highest visual owner is drawn. A native runner-up strip must not count
-- that same known occurrence twice. Assign every *known exact* spell ID to
-- its highest numeric exact lane and exclude all known exact IDs from the
-- lower generic fallback groups. Higher semantic predicates remain native.
local function groupPlans()
    local ordered = orderedTiers()
    if #ordered == 0 or #ordered > MAX_GROUPS then return nil end
    local exactSeen = {HELPFUL={}, HARMFUL={}}
    local allExact = {HELPFUL={}, HARMFUL={}}
    for _, entry in ipairs(ordered) do
        local tier = entry.tier
        if tier.exact then
            local pol = tier.helpful and "HELPFUL" or "HARMFUL"
            for id in pairs(tier.spellIDs or {}) do allExact[pol][id] = true end
        end
    end
    local result = {}
    for _, entry in ipairs(ordered) do
        local tier = entry.tier
        local filters = R.CandidateFilters and R.CandidateFilters(tier)
        if tier.exact then
            local pol = tier.helpful and "HELPFUL" or "HARMFUL"
            local ids = {}
            for id in pairs(tier.spellIDs or {}) do
                if not exactSeen[pol][id] then ids[id] = true end
                exactSeen[pol][id] = true
            end
            filters = {includeSpellIDs=ids}
        elseif tier.key == "SmallFriendlyHarmful" or tier.key == "HostileHelpful" then
            local pol = tier.key == "HostileHelpful" and "HELPFUL" or "HARMFUL"
            local excluded = {}
            for id in pairs(filters and filters.excludeSpellIDs or {}) do excluded[id] = true end
            for id in pairs(allExact[pol]) do excluded[id] = true end
            local copy = {}
            for key, val in pairs(filters or {}) do copy[key] = val end
            copy.excludeSpellIDs = excluded
            -- The separate priority-debuff semantic group ranks above the
            -- generic harmful fallback and must not reappear below itself.
            if tier.key == "SmallFriendlyHarmful" then
                copy.isPriorityAura = false
            end
            filters = copy
        end
        if not tier.exact or next(filters.includeSpellIDs or {}) ~= nil then
            result[#result+1] = {
                tier=tier, key="tier"..entry.index,
                candidateFilters=filters,
            }
        end
    end
    return result
end

local function hide(host, reason)
    if not host or not host._nativeSecondProbe then return end
    local probe = host._nativeSecondProbe
    if probe.clip then pcall(probe.clip.Hide, probe.clip) end
    host._nativeSecondProbeReason = reason or "hidden"
end

function R.HideNativeSecondProbe(host, reason)
    hide(host, reason)
end

function R.ReleaseNativeSecondProbe(host)
    if not host or not host._nativeSecondProbe then return end
    local probe = host._nativeSecondProbe
    hide(host, "host-released")
    if probe.ready and probe.container then
        pcall(probe.container.SetUnit, probe.container, nil)
        pool[#pool+1] = probe
    elseif probe.container then
        pcall(probe.container.SetUnit, probe.container, nil)
    end
    host._nativeSecondProbe = nil
end

local function supportedUnit(unit)
    return unit == "player" or unit == "target"
end

local function secondCorner(host)
    if host.unit == "player" then return "TOPLEFT", 5 end
    return "TOPRIGHT", -5
end

function R.CreateNativeSecondProbe(host)
    if not host or not supportedUnit(host.unit) or not host.portrait
        or not R.db or R.db.enabled ~= true or R.db.secondaryPortrait == false
    then return false end

    local plans = groupPlans()
    if not plans then
        host._nativeSecondProbeReason = "tiers-unavailable"
        return false
    end

    local probe = table.remove(pool)
    if probe then
        local ok = pcall(function()
            probe.clip:Hide()
            probe.clip:ClearAllPoints()
            local corner, offset = secondCorner(host)
            probe.clip:SetPoint("CENTER", host.portrait, corner, offset, 0)
            probe.clip:SetFrameStrata(usableStrata(host))
            probe.container:SetUnit(host.unit)
        end)
        if not ok then
            host._nativeSecondProbeReason = "reuse-failed"
            return false
        end
        host._nativeSecondProbe = probe
        host._nativeSecondProbeReason = "ready"
        return true
    end

    probe = {ready=false, groups=0}
    host._nativeSecondProbe = probe
    local ok = pcall(function()
        -- The viewport is an independent, noninteractive UIParent sibling.
        -- Its fixed 37px aperture never receives secret geometry.
        local clip = CreateFrame("Frame", nil, UIParent, R.AURA_ANCHOR_TEMPLATE)
        probe.clip = clip
        clip:Hide()
        clip:SetSize(CELL, CELL)
        local corner, offset = secondCorner(host)
        clip:SetPoint("CENTER", host.portrait, corner, offset, 0)
        clip:SetFrameStrata(usableStrata(host))
        local badge = host.secondaryBadge
        if badge and type(badge.GetFrameLevel) == "function" then
            local levelOK, level = pcall(badge.GetFrameLevel, badge)
            if levelOK and R.CanAccess(level) and type(level) == "number" then
                clip:SetFrameLevel(level+2)
            end
        end
        clip:EnableMouse(false)
        clip:SetClipsChildren(true)

        local c = CreateFrame("AuraContainer", nil, clip, "CustomAuraContainerTemplate")
        probe.container = c
        -- Native layout flows rightward: its first child is [-37,0] and
        -- gets clipped. The second child is [0,37], inside the viewport.
        -- The engine's own secret layout moves its children when auras change.
        c:SetPoint("TOPLEFT", clip, "TOPLEFT", -CELL, 0)
        c:SetFrameLevel(clip:GetFrameLevel()+1)
        -- Delay the unit binding until all groups exist. AddAuraGroup
        -- refreshes immediately; binding first would rescan the same live
        -- unit (Player or Target) for every registered priority group.
        for rank, plan in ipairs(plans) do
            c:AddAuraGroup(plan.key, plan.tier.filter, {
                maxFrameCount = 2,
                candidateFilters = plan.candidateFilters,
                sortMethod = R.SORT_METHOD,
                sortDirection = R.SORT_DIRECTION,
                layout = {
                    layoutIndex = rank,
                    elementWidth = CELL,
                    elementHeight = CELL,
                    elementSpacing = 0,
                    groupSpacing = 0,
                    forceNewLine = false,
                },
                initializeFrame = makeButton,
            })
            probe.groups = probe.groups + 1
        end
        c:SetUnit(host.unit)
        probe.ready = true
    end)
    if not ok then
        hide(host, "native-group-construction-failed")
        return false
    end
    host._nativeSecondProbeReason = "ready"
    return true
end

function R.UpdateNativeSecondProbe(host, enabled, hostile, playerReadable, isPlayer)
    if not host or not supportedUnit(host.unit) then return end

    local base = R.db and R.db.enabled == true
        and R.db.secondaryPortrait ~= false
        and enabled == true and not R.testMode

    -- The player host must be READY before an incoming combat debuff seals
    -- public aura indexing. Construct it on the first ordinary OOC host
    -- update, but show it only if the readable second has fallen back to
    -- race. Keep independently presented Ghost and form/stance ranking as
    -- the older authoritative implementation.
    local playerEligible = host.unit == "player" and base
        and hostile == false and host._assistable == true
        and playerReadable == true and isPlayer == true

    -- Opposite-faction players and hostile NPCs share the same Target proof.
    -- Unknown class identity/relation is never promoted to a native ribbon.
    local targetEligible = host.unit == "target" and base
        and hostile == true and playerReadable == true
        and type(isPlayer) == "boolean"

    if (playerEligible or targetEligible) and not host._nativeSecondProbe then
        -- Native groups preallocate a batch per tier. Never construct new
        -- protected layout frames while combat-locked. A normal OOC
        -- refresh will retry automatically; no slash command is needed.
        local combat, readable = R.SafeBool(InCombatLockdown)
        if not readable or combat then
            host._nativeSecondProbeReason = "setup-deferred-until-out-of-combat"
            return
        end
        if not R.CreateNativeSecondProbe(host) then return end
    end

    local probe = host._nativeSecondProbe
    if not probe or not probe.ready or not probe.clip then return end

    local playerFallback = playerEligible
        and host._secondaryMode == "race"
        and host._raceBaselineActive == true
        and host._ghostActive ~= true and host._formStateActive ~= true
    local show = targetEligible or playerFallback

    if show then
        -- Target NPCs have no legitimate race baseline; hide their legacy
        -- badge. Player and hostile-player badges remain underneath the
        -- native second cell, so zero/one eligible auras still show race.
        -- No native button/secret frame geometry is inspected by Lua.
        if targetEligible and isPlayer == false and host.secondaryBadge then
            pcall(host.secondaryBadge.Hide, host.secondaryBadge)
        end
        if not pcall(probe.clip.Show, probe.clip) then
            host._nativeSecondProbeReason = "clip-show-failed"
        else
            host._nativeSecondProbeReason = playerFallback
                and "player-native-race-fallback"
                or "target-native-ribbon"
        end
    else
        hide(host, playerEligible and "readable-second-or-static-owner"
            or "unit-ineligible")
    end
end
