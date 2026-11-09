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

local CELL = 44
local IMAGE = 31
local RIM = 36
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
    if R.ApplySecondaryCountdownFont then
        R.ApplySecondaryCountdownFont(cooldown)
    end
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
    -- Blizzard AuraContainerSharedMixin:SetUnit asserts STRING and rejects
    -- nil. The previous pcall(SetUnit,nil) silently failed, leaving the old
    -- target's auras and event registration in a pooled native container.
    -- Disable instead: this unregisters unit events and forces a full clear.
    -- Pool only after the reset succeeded; re-enable on the next owner.
    local reusable = probe.ready and probe.container
        and type(probe.container.SetEnabled) == "function"
        and pcall(probe.container.SetEnabled, probe.container, false)
    if reusable then pool[#pool+1] = probe end
    probe.boundUnit = nil
    probe.boundGUID = nil
    host._nativeSecondProbe = nil
end

local function supportedUnit(unit)
    return unit == "player" or unit == "target" or unit == "focus"
end

-- A visibly separate Target/Focus portrait may refer to the local Player.
-- Use the native "player" aura unit in that case, which has the same secure
-- self-helpful access as the existing PlayerFrame strip. Require a *positive*
-- UnitIsUnit witness; names, GUID guesses and inaccessible results do not
-- authorize an alias. Never read native aura-button data to determine it.
local function nativeSourceUnit(host)
    if host.unit == "player" then return "player" end
    if type(UnitIsUnit) == "function" and type(R.SafeBool) == "function" then
        local same, readable = R.SafeBool(UnitIsUnit, host.unit, "player")
        if readable and same then return "player" end
    end
    return host.unit
end

-- The unit TOKEN can remain "target" across multiple different creatures.
-- A separate positively readable GUID detects that change without reading
-- or inferring any private aura count, duration or spell ID.
local function readableHostGUID(unit)
    if type(UnitGUID) ~= "function" or type(R.SafeString) ~= "function" then
        return nil, false
    end
    local guid, readable = R.SafeString(UnitGUID, unit)
    if readable and guid ~= "" then return guid, true end
    return nil, false
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
            local corner, dx, dy = R.SecondaryCirclePlacement(host.unit)
            probe.clip:SetPoint("CENTER", host.portrait, corner, dx, dy)
            probe.clip:SetFrameStrata(usableStrata(host))
            local source = nativeSourceUnit(host)
            -- SetUnit does nothing when reusing the same token ("target"
            -- -> new "target"), so enabling the previously disabled
            -- container MUST trigger a fresh full aura parse first.
            probe.container:SetUnit(source)
            probe.container:SetEnabled(true)
            probe.boundUnit = source
            probe.boundGUID = select(1, readableHostGUID(host.unit))
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
        -- Its fixed 44px aperture never receives secret geometry.
        local clip = CreateFrame("Frame", nil, UIParent, R.AURA_ANCHOR_TEMPLATE)
        probe.clip = clip
        clip:Hide()
        clip:SetSize(CELL, CELL)
        local corner, dx, dy = R.SecondaryCirclePlacement(host.unit)
        clip:SetPoint("CENTER", host.portrait, corner, dx, dy)
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
        local source = nativeSourceUnit(host)
        c:SetUnit(source)
        -- CRITICAL: AuraContainerSharedMixin starts with enabled=nil and
        -- IsEnabled() only accepts EXACTLY true. 0.1.216 enabled pooled
        -- containers on reuse, but forgot to enable FIRST-CONSTRUCTION
        -- containers. All their secure groups were inert; a friendly
        -- player's race never got covered and an NPC never got a second.
        c:SetEnabled(true)
        probe.boundUnit = source
        probe.boundGUID = select(1, readableHostGUID(host.unit))
        probe.ready = true
    end)
    if not ok then
        hide(host, "native-group-construction-failed")
        return false
    end
    host._nativeSecondProbeReason = "ready"
    return true
end

function R.UpdateNativeSecondProbe(host, enabled, hostile, playerReadable, isPlayer,
    forceContainerRefresh)
    if not host or not supportedUnit(host.unit) then return end

    local base = R.db and R.db.enabled == true
        and R.db.secondaryPortrait ~= false
        and enabled == true and not R.testMode

    -- PlayerFrame prepares the native second out of combat. Its readable
    -- winner remains authoritative; this strip is a combat/race fallback.
    local playerEligible = host.unit == "player" and base
        and hostile == false and host._assistable == true
        and playerReadable == true and isPlayer == true

    -- Target and Focus share the exact same guarded mechanism. The public
    -- election may read an effect on PlayerFrame but not its Target/Focus
    -- alias, or fail on an unrelated protected HARMFUL aura.
    local otherEligible = (host.unit == "target" or host.unit == "focus")
        and base and type(hostile) == "boolean"
        and playerReadable == true and type(isPlayer) == "boolean"

    local newlyConstructed = false
    if (playerEligible or otherEligible) and not host._nativeSecondProbe then
        -- Native groups preallocate frames per priority tier. Construct
        -- automatically on the first eligible OOC update; never during
        -- combat, and never require a slash command.
        local combat, readable = R.SafeBool(InCombatLockdown)
        if not readable or combat then
            host._nativeSecondProbeReason = "setup-deferred-until-out-of-combat"
            return
        end
        if not R.CreateNativeSecondProbe(host) then return end
        newlyConstructed = true
    end

    local probe = host._nativeSecondProbe
    if not probe or not probe.ready or not probe.clip then return end

    if playerEligible or otherEligible then
        -- On PLAYER_TARGET_CHANGED/PLAYER_FOCUS_CHANGED the bound unit TOKEN
        -- normally stays "target"/"focus", even though the actual GUID
        -- changes. The primary native containers already receive forced
        -- UpdateAllAuras on those transitions; the SECONDARY ribbon must do
        -- so too or it can display the previous mob's timed aura.
        local source = nativeSourceUnit(host)
        local guid, guidReadable = readableHostGUID(host.unit)
        local changedSource = probe.boundUnit ~= source
        local changedIdentity = guidReadable and probe.boundGUID ~= nil
            and probe.boundGUID ~= guid
        local newlyReadableIdentity = guidReadable and probe.boundGUID == nil
        local forced = forceContainerRefresh == true and not newlyConstructed
            and (host.unit == "target" or host.unit == "focus")

        -- A forced retarget with a previously known but currently unreadable
        -- identity cannot authorize reusing the prior native second cell.
        if forced and probe.boundGUID ~= nil and not guidReadable then
            hide(host, "unit-identity-unreadable")
            return
        end
        if changedSource or changedIdentity or newlyReadableIdentity or forced then
            -- Force-refreshing the built-in group may change its protected
            -- layout. Do not attempt it in combat: hide the independent
            -- viewport and retry from the next normal OOC refresh.
            local combat, known = R.SafeBool(InCombatLockdown)
            if not known or combat then
                hide(host, changedSource and "source-rebind-deferred-combat"
                    or "unit-rebind-deferred-combat")
                return
            end
            local refreshed = pcall(function()
                if changedSource then
                    probe.container:SetUnit(source)
                elseif type(probe.container.UpdateAllAuras) == "function" then
                    probe.container:UpdateAllAuras()
                else
                    -- SetUnit(nil) is invalid, and SetUnit(source) cannot
                    -- refresh an unchanged token. Fail closed rather than
                    -- retain a previous creature's aura behind a fake reset.
                    error("native-aura-refresh-unavailable")
                end
            end)
            if not refreshed then
                hide(host, "unit-refresh-failed")
                return
            end
            probe.boundUnit = source
            probe.boundGUID = guidReadable and guid or nil
        end
    end

    local playerFallback = playerEligible
        and host._secondaryMode == "race"
        and host._raceBaselineActive == true
        and host._ghostActive ~= true and host._formStateActive ~= true

    -- On nonhostile Target/Focus, a complete, public second-aura or form
    -- selection wins. Only race/hidden fallback can expose the native
    -- second cell; Ghost and form-state primaries must not be guessed
    -- past by a generic aura ribbon.
    local publicSecond = host._secondaryMode == "aura"
        or host._secondaryMode == "form"
    local otherFallback = otherEligible and hostile == false
        and not publicSecond
        and host._ghostActive ~= true and host._formStateActive ~= true
    -- "not-two-presentable" means the public reader could not positively
    -- RANK two auras; it does NOT prove the native secure groups lack a
    -- second aura. Earlier revisions mistook that uncertainty for absence,
    -- hiding real NPC debuffs and leaving friendly-player race art up.
    -- Let Blizzard's ordered, clipped second native BUTTON decide whether
    -- a second aura exists; an empty native cell draws nothing. A complete
    -- public second aura still wins and keeps the native clip hidden.
    local otherShow = otherEligible and not publicSecond
        and (hostile == true or otherFallback)
    local show = otherShow or playerFallback

    if show then
        -- A confirmed NPC has no valid player-race baseline. Player
        -- targets retain race under the empty native second cell;
        -- positively identified pets have their own family underlay.
        if otherShow and isPlayer == false and host.secondaryBadge then
            pcall(host.secondaryBadge.Hide, host.secondaryBadge)
        end
        if not pcall(probe.clip.Show, probe.clip) then
            host._nativeSecondProbeReason = "clip-show-failed"
        else
            host._nativeSecondProbeReason = playerFallback
                and "player-native-race-fallback"
                or otherFallback and "friendly-secondary-native-fallback"
                or "other-unit-native-ribbon"
        end
    else
        hide(host, playerEligible and "readable-second-or-static-owner"
            or otherEligible and "readably-ranked-or-static"
            or "unit-ineligible")
    end
end
