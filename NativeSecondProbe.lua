local addonName, BP = ...
local R = assert(BP.Runtime, "Core.lua must load first")

-- Best-effort native second cell for Player, Target and Focus when the
-- public reader cannot present a verified runner-up. Native rendering
-- does not disclose secret aura identities to Lua. Different occurrences
-- of a hidden spell can share art, including across the first two cells.
--
-- A single native CustomAuraContainer owns multiple groups, ordered by the
-- existing R.TIERS. Each group contributes at most TWO native aura buttons.
-- The first button is physically outside a fixed clipping viewport; the
-- SECOND globally ordered button occupies the small portrait's position.
-- No addon Lua value is read from a secure aura button or aura group.
--
-- Each host initializes once eligible out of combat and can reuse a pooled
-- container. The readable election owns the badge wherever it succeeds.

local CELL, IMAGE, RIM, RIM_X, RIM_Y = R.SecondaryCircleGeometry("target")
local MAX_GROUPS = 80
local pool = {}
local constructionQueue = {}
local constructionTimer
local queueConstruction

local function cancelConstruction(probe)
    if not probe then return end
    probe.constructionTicket=nil
    for i=#constructionQueue,1,-1 do
        if constructionQueue[i].probe==probe then table.remove(constructionQueue,i) end
    end
end

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

local function anchorClip(clip, host)
    clip:ClearAllPoints()
    local corner, dx, dy = R.SecondaryCirclePlacement(host.unit)
    clip:SetPoint("CENTER", host.portrait, corner, dx, dy)
    clip:SetFrameStrata(usableStrata(host))
    local badge = host.secondaryBadge
    if badge and type(badge.GetFrameLevel) == "function" then
        local ok, level = pcall(badge.GetFrameLevel, badge)
        if ok and R.CanAccess(level) and type(level) == "number" then
            clip:SetFrameLevel(level+2)
        end
    end
end

local function needsFormatterRecovery(backend)
    return backend=="hidden" or (R.ApplyPortraitTimer and backend~="cells")
end

local function makeButton(parts, probe)
    -- Invoked by Blizzard during the group frame-provider's initial
    -- preallocation. Never use aura existence/count/ID in this callback.
    -- Keep completed allocations when a native setter interrupts setup.
    local button = parts.button
    button:SetSize(CELL, CELL)
    button:EnableMouse(false)

    local icon = parts.icon or button:CreateTexture(nil, "ARTWORK")
    parts.icon = icon
    icon:SetSize(IMAGE, IMAGE)
    icon:SetPoint("CENTER", button, "CENTER")
    -- The secure renderer changes the spell texture, not its source UVs.
    -- Trim classic square artwork borders without changing native ordering.
    R.ApplySecondaryIconCrop(icon)
    local mask = parts.mask or button:CreateMaskTexture(nil, "ARTWORK")
    parts.mask = mask
    mask:SetAtlas("CircleMask", false)
    mask:SetAllPoints(icon)
    if not parts.masked then
        icon:AddMaskTexture(mask)
        parts.masked = true
    end
    button:SetIcon(icon)

    local border = parts.border or button:CreateTexture(nil, "OVERLAY")
    parts.border = border
    border:SetAtlas("UI-HUD-UnitFrame-TotemFrame", false)
    border:SetSize(RIM, RIM)
    border:SetPoint("CENTER", button, "CENTER", RIM_X, RIM_Y)

    local cooldown = parts.cooldown or CreateFrame("Cooldown", nil, button,
        "CooldownFrameTemplate," .. R.AURA_ANCHOR_TEMPLATE)
    parts.cooldown = cooldown
    cooldown:SetAllPoints(icon)
    if cooldown.SetDrawBling then cooldown:SetDrawBling(false) end
    if cooldown.SetDrawEdge then cooldown:SetDrawEdge(false) end
    if cooldown.SetDrawSwipe then cooldown:SetDrawSwipe(false) end
    if cooldown.SetReverse then cooldown:SetReverse(true) end
    if cooldown.SetUsingParentLevel then cooldown:SetUsingParentLevel(true) end
    if not parts.clockListed then
        probe.cooldowns[#probe.cooldowns+1] = cooldown
        parts.clockListed = true
    end
    button:SetDurationCooldown(cooldown)
    local ok,applied,backend=pcall(R.ApplySecondaryCountdownPresentation,cooldown)
    if R.AttachPortraitAuraClock then
        -- The native button owns a stable opaque duration. Attach only after
        -- its source label has the final font and placement used by the cells.
        pcall(R.AttachPortraitAuraClock,button,cooldown)
        ok,applied,backend=pcall(R.ApplyCountdownFormat,cooldown)
    end
    if not ok or applied~=true then
        probe.formatRetries[#probe.formatRetries+1] = cooldown
    elseif needsFormatterRecovery(backend) then
        probe.fallbackClocks[#probe.fallbackClocks+1]=cooldown
    end
    parts.button = nil
end

function R.ApplyNativeSecondPresentation(host,verifyFonts)
    local probe = host and host._nativeSecondProbe
    if not probe or not probe.ready then return end
    local decimals = R.db.showDecimals == true
    local changed=probe.decimals~=decimals
    if verifyFonts then probe.verifyTimerFormats=true end
    local reselect=probe.verifyTimerFormats
    local fallback=probe.fallbackClocks or {}
    local recover=probe.formatterEpoch~=R.countdownFormatterEpoch
        and #fallback>0
    local pending=(changed or reselect) and probe.cooldowns or probe.formatRetries or {}
    if #pending==0 and not recover then return end
    local combat, readable = R.SafeBool(InCombatLockdown)
    if not readable or combat then
        return
    end
    if changed or reselect then
        fallback={} -- all clocks will be classified again under the new preference
    elseif recover and (R.ApplyPortraitTimer or R.GetCountdownFormatter()) then
        for _,clock in ipairs(fallback) do pending[#pending+1]=clock end
        fallback={}
    end
    local retries = {}
    for _, cooldown in ipairs(pending) do
        local ok,applied,backend
        if R.ApplyPortraitTimer then
            ok,applied,backend=pcall(R.ApplySecondaryCountdownPresentation,cooldown,reselect,true)
        else
            ok,applied,backend=pcall(R.ApplyCountdownFormat,cooldown,nil,reselect)
        end
        if not ok or applied~=true then retries[#retries+1]=cooldown
        elseif needsFormatterRecovery(backend) then fallback[#fallback+1]=cooldown end
    end
    probe.decimals,probe.formatRetries,probe.fallbackClocks=decimals,retries,fallback
    probe.formatterEpoch=R.countdownFormatterEpoch
    probe.verifyTimerFormats=nil
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
        local filterString = tier.filter
        -- Blizzard's AuraGroups are independent: one aura could occupy
        -- two groups and be painted as its own runner-up in combat.
        -- Keep overlapping semantic groups disjoint with supported negative
        -- aura filter flags; do NOT change the primary R.TIERS.
        if tier.key == "HostileHelpful" then
            filterString = "HELPFUL|INCLUDE_NAME_PLATE_ONLY|!IMPORTANT"
                .. "|!BIG_DEFENSIVE|!EXTERNAL_DEFENSIVE"
        elseif tier.key == "ExternalDef" then
            filterString = tier.filter .. "|!BIG_DEFENSIVE"
        elseif tier.key == "CrowdControl" then
            filterString = tier.filter .. "|INCLUDE_NAME_PLATE_ONLY"
            filters.maxDuration = R.TIER_BY_KEY.SmallFriendlyHarmful.candidateFilters.maxDuration
        elseif tier.key == "PriorityDebuff" then
            filterString = tier.filter .. "|INCLUDE_NAME_PLATE_ONLY|!CROWD_CONTROL"
            filters.maxDuration = R.TIER_BY_KEY.SmallFriendlyHarmful.candidateFilters.maxDuration
        elseif tier.key == "SmallFriendlyHarmful" then
            filterString = tier.filter .. "|!CROWD_CONTROL"
        end
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
            local plan = {
                tier=tier, key="tier"..entry.index, filter=filterString,
                candidateFilters=filters,
            }
            if tier.key == "Important" or tier.key == "BigDef" or tier.key == "ExternalDef" then
                plan.hostileFilter = filterString .. "|INCLUDE_NAME_PLATE_ONLY"
                plan.hostileCandidates = {}
                for key, value in pairs(filters or {}) do plan.hostileCandidates[key] = value end
                plan.hostileCandidates.maxDuration = R.TIER_BY_KEY.HostileHelpful.candidateFilters.maxDuration
            end
            result[#result+1] = plan
        end
    end
    return result
end

local function clearStaticExpiry(probe)
    local ticket = probe.staticExpiry
    probe.staticExpiry = nil
    if ticket and ticket.timer then pcall(function() ticket.timer:Cancel() end) end
end

local function hide(host, reason)
    if not host or not host._nativeSecondProbe then return true end
    local probe = host._nativeSecondProbe
    clearStaticExpiry(probe)
    local hidden = true
    if probe.clip then
        local ok, result = pcall(function() return probe.clip:Hide() end)
        hidden = ok and R.CanAccess(result) and result ~= false
    end
    host._nativeSecondProbeReason = reason or "hidden"
    return hidden
end

function R.HideNativeSecondProbe(host, reason)
    return hide(host, reason)
end

function R.ReleaseNativeSecondProbe(host)
    if not host or not host._nativeSecondProbe then return true end
    local probe = host._nativeSecondProbe
    cancelConstruction(probe)
    local hidden = hide(host, "host-released")
    -- Blizzard AuraContainerSharedMixin:SetUnit asserts STRING and rejects
    -- nil. The previous pcall(SetUnit,nil) silently failed, leaving the old
    -- target's auras and event registration in a pooled native container.
    -- Disabling requests a native rebuild. A hidden viewport can retain a
    -- failed disable in the pool; no later owner may bind it until that
    -- disable actually succeeds. A failed hide retains the current owner.
    local combat,known=R.SafeBool(InCombatLockdown)
    local disabled=not probe.container
    if probe.container and known and not combat then
        local ok,result=pcall(probe.container.SetEnabled,probe.container,false)
        disabled=ok and R.CanAccess(result) and result~=false
    end
    probe.needsDisable = not disabled
    if not hidden then
        host._nativeSecondProbeReason = "native-release-pending"
        return false
    end
    pool[#pool+1] = probe
    probe.boundUnit, probe.boundGUID, probe.rebindPending = nil, nil, nil
    probe.needsBind, probe.quarantined, probe.failedAt = true, false, nil
    host._nativeSecondProbe = nil
    return true
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

-- The generic hostile filter includes nameplate-only effects; its negated
-- flags therefore also exclude nameplate-only Important/defensive auras.
-- Let the corresponding semantic group receive them only while hostile.
-- Forever exposes an inclusive filter but no nameplate-only-only filter.
-- Its duration predicate must follow the inclusive generic lane as well.
-- During opaque reads this can omit an ordinary permanent semantic effect,
-- since the native API cannot exempt ordinary effects from this predicate.
local function setHostileGroups(probe, wanted)
    if probe.hostileHelpfulEnabled == wanted then return end
    -- A partial write must not authorize showing a friendly unit's ribbon.
    -- A later safe pass rewrites the entire affected group set.
    probe.hostileHelpfulEnabled = nil
    for _, group in ipairs(probe.relationFilters) do
        probe.container:SetAuraGroupFilterString(group.key,
            wanted and group.hostileFilter or group.friendlyFilter)
        probe.container:SetAuraGroupCandidateFilters(group.key,
            wanted and group.hostileCandidates or group.friendlyCandidates)
    end
    probe.container:SetAuraGroupEnabled(probe.hostileHelpfulKey, wanted)
    probe.hostileHelpfulEnabled = wanted
end

local function prepareGroupTree(probe, host)
    if not probe.structureReady then
        if not probe.clip then
            probe.clip = CreateFrame("Frame", nil, UIParent, R.AURA_ANCHOR_TEMPLATE)
        end
        local clip = probe.clip
        local hidden=clip:Hide()
        assert(R.CanAccess(hidden) and hidden~=false,"native construction viewport hide declined")
        clip:SetSize(CELL, CELL)
        anchorClip(clip, host)
        clip:EnableMouse(false)
        clip:SetClipsChildren(true)

        if not probe.container then
            probe.container = CreateFrame("AuraContainer", nil, clip, "CustomAuraContainerTemplate")
        end
        local c = probe.container
        local disabled=c:SetEnabled(false)
        assert(R.CanAccess(disabled) and disabled~=false,"native construction disable declined")
        c:ClearAllPoints()
        c:SetPoint("TOPLEFT", clip, "TOPLEFT", -CELL, 0)
        c:SetFrameLevel(clip:GetFrameLevel()+1)
        probe.structureReady=true
    end
    local c=probe.container

    local rank=probe.groups+1
    if rank<=#probe.plans then
        local plan = probe.plans[rank]
        local layout = {
            layoutIndex = rank, elementWidth = CELL, elementHeight = CELL,
            elementSpacing = 0, groupSpacing = 0, forceNewLine = false,
        }
        -- A setter can register the group before a later native operation
        -- throws. HasAuraGroup checks our fixed configuration key only.
        if c:HasAuraGroup(plan.key) then
            -- Forever installs layout after it registers the group.
            local result=c:SetAuraGroupLayout(plan.key, layout)
            assert(R.CanAccess(result) and result~=false,"native group layout declined")
            -- The native provider catches initializer exceptions separately
            -- from AddAuraGroup. Repair only the unfinished fixed recipients;
            -- never inspect the group's protected aura or frame population.
            local pending=probe.pendingButtons
            while pending and #pending>0 do
                makeButton(pending[1],probe)
                table.remove(pending,1)
            end
        else
            local result=c:AddAuraGroup(plan.key, plan.filter, {
                maxFrameCount = 2, candidateFilters = plan.candidateFilters,
                sortMethod = R.SORT_METHOD, sortDirection = R.SORT_DIRECTION,
                layout = layout,
                initializeFrame = function(button)
                    local parts={button=button}
                    if not pcall(makeButton,parts,probe) then
                        probe.pendingButtons=probe.pendingButtons or {}
                        probe.pendingButtons[#probe.pendingButtons+1]=parts
                    end
                end,
            })
            assert(R.CanAccess(result) and result~=false,"native group creation declined")
        end
        assert(not probe.pendingButtons or #probe.pendingButtons==0,"native button initialization incomplete")
        probe.pendingButtons=nil
        if plan.tier.key == "HostileHelpful" then
            probe.hostileHelpfulKey = plan.key
        elseif plan.hostileFilter then
            probe.relationFilters[#probe.relationFilters+1] = {
                key=plan.key, friendlyFilter=plan.filter,
                hostileFilter=plan.hostileFilter,
                friendlyCandidates=plan.candidateFilters, hostileCandidates=plan.hostileCandidates,
            }
        end
        probe.groups = rank
        probe.failedAt = nil
    end
    if probe.groups<#probe.plans then return false end
    probe.witnessPlans, probe.plans, probe.failedAt = probe.plans, nil, nil
    probe.ready = true
    return true
end

local function currentConstruction(ticket)
    local host,probe=ticket.host,ticket.probe
    return probe.constructionTicket==ticket and host._nativeSecondProbe==probe
        and R.hosts[host.unit]==host and R.db and R.db.enabled==true
        and R.db.secondaryPortrait~=false and not R.testMode
        and (not R.IsUnitEnabled or R.IsUnitEnabled(host.unit))
        and R.SecondaryOwnerVisible(host)
end

local function scheduleConstruction()
    if constructionTimer or #constructionQueue==0 then return end
    local combat,known=R.SafeBool(InCombatLockdown)
    if not known or combat or not C_Timer or type(C_Timer.After)~="function" then return end
    local timer={scheduling=true}
    constructionTimer=timer
    local ok,result=pcall(C_Timer.After,.01,function()
        if constructionTimer~=timer then return end
        constructionTimer=nil
        -- A synchronous timer implementation cannot turn the bounded queue
        -- into one recursive burst. Leave work for the next safe event.
        if timer.scheduling then return end
        local combat,known=R.SafeBool(InCombatLockdown)
        if not known or combat then return end
        local ticket
        while #constructionQueue>0 do
            local candidate=table.remove(constructionQueue,1)
            if currentConstruction(candidate) then ticket=candidate;break end
            if candidate.probe.constructionTicket==candidate then candidate.probe.constructionTicket=nil end
        end
        if not ticket then return end
        local host,probe=ticket.host,ticket.probe
        local built,complete=pcall(prepareGroupTree,probe,host)
        if not built then
            cancelConstruction(probe)
            if probe.failedAt==probe.groups then probe.quarantined=true end
            probe.failedAt=probe.groups
            hide(host,probe.quarantined and "native-group-retry-exhausted" or "native-group-construction-failed")
        elseif complete then
            local current=currentConstruction(ticket)
            probe.constructionTicket=nil
            -- Never replay eligibility or a recipient captured when queued.
            -- The normal refresh binds and exposes only the current owner.
            if current and R.Refresh then
                pcall(R.Refresh,host.unit,true)
            end
        elseif currentConstruction(ticket) then
            table.insert(constructionQueue,ticket)
        end
        scheduleConstruction()
    end)
    timer.scheduling=nil
    if not ok or not R.CanAccess(result) or result==false then
        if constructionTimer==timer then constructionTimer=nil end
    end
end

queueConstruction=function(probe,host)
    if not probe.constructionTicket then
        local ticket={probe=probe,host=host}
        probe.constructionTicket=ticket
        table.insert(constructionQueue,ticket)
    end
    host._nativeSecondProbeReason="native-group-construction-pending"
    scheduleConstruction()
end

local function bindProbe(probe, host)
    probe.clip:Hide()
    if probe.needsDisable then
        probe.container:SetEnabled(false)
        probe.needsDisable = false
    end
    anchorClip(probe.clip, host)
    probe.container:SetFrameLevel(probe.clip:GetFrameLevel()+1)
    setHostileGroups(probe, false)
    local source = nativeSourceUnit(host)
    probe.container:SetUnit(source)
    probe.container:SetEnabled(true)
    probe.boundUnit = source
    probe.boundGUID = select(1, readableHostGUID(host.unit))
    probe.needsBind, probe.rebindPending = false, false
end

function R.CreateNativeSecondProbe(host)
    if not host or not supportedUnit(host.unit) or not host.portrait
        or not R.db or R.db.enabled ~= true or R.db.secondaryPortrait == false
    then return false end
    local combat, known = R.SafeBool(InCombatLockdown)
    if not known or combat then return false end

    local probe = host._nativeSecondProbe or table.remove(pool)
    if not probe then
        local plans = groupPlans()
        if not plans then
            host._nativeSecondProbeReason = "tiers-unavailable"
            return false
        end
        probe = {plans=plans, ready=false, groups=0, cooldowns={}, formatRetries={},fallbackClocks={},
            formatterEpoch=R.countdownFormatterEpoch,
            decimals=R.db.showDecimals == true, relationFilters={}, needsBind=true}
    end
    local reused=probe.ready and probe.needsBind
    -- Publish ownership before the first operation that can partially succeed.
    host._nativeSecondProbe = probe
    if probe.quarantined then return false end
    if not probe.ready then
        queueConstruction(probe,host)
        return false
    end
    if probe.needsBind then
        if not pcall(bindProbe, probe, host) then
            hide(host, "native-bind-failed")
            probe.needsDisable = not pcall(function() probe.container:SetEnabled(false) end)
            probe.boundUnit, probe.boundGUID = nil, nil
            return false
        end
    end
    host._nativeSecondProbeReason = "ready"
    R.ApplyNativeSecondPresentation(host,reused)
    return true
end

local function knownOrderConflict(host, reads)
    local owners = host._readableTierOwners or {}
    local lowestConflict
    for key, owner in pairs(owners) do
        if owner.complete and (owner.nativeFirstMismatch or owner.nativeOrderMismatch or owner.nativeRepeatsWinner) then
            local level = R.TIER_BY_KEY[key].level
            lowestConflict = math.min(lowestConflict or level, level)
        end
    end
    if not lowestConflict then return false end
    local levels = R.KnownHigherAuraLevels and R.KnownHigherAuraLevels(host, reads, lowestConflict) or {}
    for key, owner in pairs(owners) do
        if owner.complete and owner.spellID then
            local level = R.TIER_BY_KEY[key].level
            levels[owner.spellID] = math.max(levels[owner.spellID] or level, level)
        end
    end
    for key, owner in pairs(owners) do
        if owner.complete and (owner.nativeFirstMismatch or owner.nativeOrderMismatch or owner.nativeRepeatsWinner) then
            local level = R.TIER_BY_KEY[key].level
            local higher = 0
            for _, observedLevel in pairs(levels) do
                if observedLevel > level then
                    higher = higher+1
                    if higher == 2 then break end
                end
            end
            -- Two higher effects already fill both cells. With exactly one
            -- higher effect, this lane supplies its first occurrence to cell 2.
            if higher == 1 and owner.nativeFirstMismatch then return true end
            if higher == 0 and (owner.nativeOrderMismatch or owner.nativeRepeatsWinner) then return true end
        end
    end
    return false
end

-- Inspect only the positively readable snapshot and the addon's group
-- configuration. The native cells themselves can contain secret values.
local function knownRibbonMismatch(probe, witness)
    if not witness or not R.NativeRibbonGroupMatches then return false end
    if witness.second.sourceUnit and witness.second.sourceUnit~=probe.boundUnit then return true end
    if witness.second.physicalClockConflict and witness.second.physicalUnit~=probe.boundUnit then return true end
    local plans = probe.witnessPlans or groupPlans()
    if not plans then return false end
    local guaranteed, possible = 0, 0
    local unresolvedCC
    for _, plan in ipairs(plans) do
        if plan.tier.key ~= "HostileHelpful" or probe.hostileHelpfulEnabled then
            local useHostile = probe.hostileHelpfulEnabled and plan.hostileFilter
            local filter = useHostile or plan.filter
            local predicates = useHostile and plan.hostileCandidates or plan.candidateFilters
            -- These exact filter strings differ only in the CC bit. Once
            -- both groups' independent predicates pass, this occurrence is
            -- guaranteed in one group even if the shared bit is sealed.
            local ccGroup = filter == "HARMFUL|CROWD_CONTROL|INCLUDE_NAME_PLATE_ONLY"
            local nonCCGroup = filter == "HARMFUL|INCLUDE_NAME_PLATE_ONLY|!CROWD_CONTROL"
            local groupKnown, groupPossible = 0, 0
            local beforeKnown, beforePossible = 0, 0
            local canIncludeRunner = false
            for _, candidate in ipairs(witness.current) do
                local matches = R.NativeRibbonGroupMatches(witness, candidate, filter, predicates)
                if ccGroup and matches ~= true and
                    R.NativeRibbonGroupMatches(witness,candidate,"HARMFUL|INCLUDE_NAME_PLATE_ONLY",predicates) == true then
                    unresolvedCC = unresolvedCC or {}
                    unresolvedCC[candidate] = true
                elseif nonCCGroup and unresolvedCC and unresolvedCC[candidate] then
                    local base = "HARMFUL|INCLUDE_NAME_PLATE_ONLY"
                    local admitted = R.NativeRibbonGroupMatches(witness,candidate,base,predicates)
                    if admitted == nil and predicates and type(predicates.isPriorityAura)=="boolean"
                        and R.NativeRibbonGroupMatches(witness,candidate,base,predicates,true) == true then
                        -- Forever's priority predicate is boolean: both possible
                        -- !CC branches together cover a hidden priority result.
                        local branch = predicates.isPriorityAura and "priority" or "ordinary"
                        local previous = unresolvedCC[candidate]
                        admitted = previous ~= true and previous ~= branch
                        unresolvedCC[candidate] = branch
                    end
                    if admitted == true then
                        unresolvedCC[candidate] = nil
                        if matches ~= true then
                            groupKnown = groupKnown + 1
                            if matches == false or candidate.auraInstanceID > witness.second.auraInstanceID then
                                beforeKnown = beforeKnown + 1
                            end
                        end
                    end
                end
                if matches ~= false then
                    groupPossible = groupPossible + 1
                    if matches then groupKnown = groupKnown + 1 end
                    -- Inside each group, the higher instance IDs come first.
                    if candidate.auraInstanceID > witness.second.auraInstanceID then
                        beforePossible = beforePossible + 1
                        if matches then beforeKnown = beforeKnown + 1 end
                    elseif candidate == witness.second then
                        canIncludeRunner = true
                    end
                end
            end
            -- The desired occurrence can occupy cell two if exactly one
            -- earlier member is compatible with the available evidence.
            if canIncludeRunner and guaranteed + beforeKnown <= 1 and possible + beforePossible >= 1 then
                return false
            end
            guaranteed = guaranteed + groupKnown
            if guaranteed >= 2 then return true end
            possible = math.min(2, possible + groupPossible)
        end
    end
    return false
end

local function auraDeadline(candidate)
    local aura=candidate.physicalClockConflict and candidate.physicalAura or candidate.aura
    if R.ReadAuraField(aura,"duration") == 0 then return math.huge end
    local expires = R.ReadAuraField(aura,"expirationTime")
    if type(expires) == "number" and expires > 0 and expires < math.huge then return expires end
    local getter = C_UnitAuras and C_UnitAuras.GetAuraDuration
    if type(getter) == "function" then
        local unit=candidate.physicalClockConflict and candidate.physicalUnit or candidate.sourceUnit
        local ok, object = pcall(getter,unit,candidate.auraInstanceID)
        if ok and R.CanAccess(object) and object then
            local found, value = pcall(function() return object:GetEndTime() end)
            if found and R.CanAccess(value) and type(value)=="number" and value > 0 and value < math.huge then
                return value
            end
        end
    end
end

local function boundStaticFallback(host, probe, witness)
    local a,b = auraDeadline(witness.primary),auraDeadline(witness.second)
    if not a or not b then return false end
    local deadline = math.min(a,b)
    if deadline == math.huge then clearStaticExpiry(probe); return true end
    local ok, now = pcall(GetTime)
    if not ok or not R.CanAccess(now) or type(now) ~= "number" or not (now >= 0 and now < deadline) then return false end
    if probe.staticExpiry and probe.staticExpiry.deadline == deadline then return true end
    if not C_Timer then return false end
    clearStaticExpiry(probe)
    local ticket = {deadline=deadline}
    probe.staticExpiry = ticket
    local function expire()
        if probe.staticExpiry ~= ticket or host._nativeSecondProbe ~= probe or R.hosts[host.unit] ~= host then return end
        probe.staticExpiry = nil
        hide(host,"static-fallback-expired")
        R.Refresh(host.unit)
    end
    if type(C_Timer.NewTimer) == "function" then
        local created,timer = pcall(C_Timer.NewTimer,deadline-now,expire)
        if created and R.CanAccess(timer) and timer then ticket.timer=timer; return true end
    end
    local scheduled,result = pcall(C_Timer.After,deadline-now,expire)
    return scheduled and R.CanAccess(result) and result ~= false
end

function R.UpdateNativeSecondProbe(host, enabled, hostile, playerReadable, isPlayer,
    forceContainerRefresh, bindingChanged, exactReads)
    if not host or not supportedUnit(host.unit) then return end

    local existing = host._nativeSecondProbe
    if existing and bindingChanged and host.unit ~= "player" then existing.rebindPending = true end
    local visible, visibilityReason = R.SecondaryOwnerVisible(host)
    if not visible then
        cancelConstruction(existing)
        hide(host, visibilityReason)
        return
    end
    local base = R.db and R.db.enabled == true
        and R.db.secondaryPortrait ~= false
        and enabled == true and not R.testMode

    -- PlayerFrame prepares the native second out of combat.
    local playerEligible = host.unit == "player" and base
        and hostile == false and host._assistable == true
        and playerReadable == true and isPlayer == true

    -- Target and Focus share the exact same guarded mechanism. The public
    -- election may read an effect on PlayerFrame but not its Target/Focus
    -- alias, or fail on an unrelated protected HARMFUL aura.
    local otherEligible = (host.unit == "target" or host.unit == "focus")
        and base and type(hostile) == "boolean"
        and playerReadable == true and type(isPlayer) == "boolean"

    if not playerEligible and not otherEligible then cancelConstruction(existing) end

    local newlyConstructed = false
    if (playerEligible or otherEligible) and
        (not existing or not existing.ready or existing.needsBind) then
        if existing and (existing.quarantined or
            (existing.failedAt ~= nil and not forceContainerRefresh)) then return end
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
    if not probe or not probe.ready or probe.needsBind or not probe.clip then return end
    local retryEpoch=probe.formatterEpoch~=R.countdownFormatterEpoch
        and ((probe.fallbackClocks and #probe.fallbackClocks>0) or (probe.formatRetries and #probe.formatRetries>0))
    if probe.decimals ~= (R.db.showDecimals == true) or forceContainerRefresh or probe.verifyTimerFormats or retryEpoch then
        R.ApplyNativeSecondPresentation(host)
    end

    -- Relation may change while "target" still names the same unit.
    -- A disabled low-priority HostileHelpful group is OPTIONAL for a
    -- hostile unit: when Fear/CC ends and the public election becomes
    -- unreadable in combat, native harmful/exact groups can still draw a
    -- genuine second. Don't hide the ENTIRE clip just because the helpful
    -- group cannot be enabled until combat ends.
    --
    -- Conversely, an ENABLED hostile group must be disabled before a
    -- friendly/self unit can use this ribbon: keeping it could count one
    -- helpful aura twice. That direction remains fail-closed in combat.
    -- Never call protected SetAuraGroupEnabled during lockdown.
    local deferredHostileHelpful = false
    if playerEligible or otherEligible then
        local wanted = otherEligible and hostile == true or false
        if probe.hostileHelpfulKey and probe.hostileHelpfulEnabled ~= wanted then
            local combat, known = R.SafeBool(InCombatLockdown)
            if not known then
                hide(host,"hostile-group-combat-unknown")
                return
            end
            if combat then
                if wanted and probe.hostileHelpfulEnabled == false then
                    -- Explicitly known disabled; keep it disabled. The
                    -- container's OTHER native aura groups remain current.
                    deferredHostileHelpful = true
                else
                    hide(host,"hostile-group-change-deferred-combat")
                    return
                end
            else
                if not pcall(setHostileGroups,probe,wanted) then
                    hide(host,"hostile-group-change-failed")
                    return
                end
            end
        end
    end

    if playerEligible or otherEligible then
        -- On PLAYER_TARGET_CHANGED/PLAYER_FOCUS_CHANGED the bound unit TOKEN
        -- normally stays "target"/"focus", even though the actual GUID
        -- changes. The primary native containers already receive forced
        -- UpdateAllAuras on those transitions; the SECONDARY ribbon must do
        -- so too or it can display the previous mob's timed aura.
        local source = nativeSourceUnit(host)
        local guid, guidReadable = readableHostGUID(host.unit)
        if host._verifySettledBinding then
            -- The immediate target/focus event may have refreshed the old
            -- referent. Use this same GUID read to verify the settling pass.
            if not guidReadable then probe.rebindPending=true end
            host._verifySettledBinding=nil
        end
        local changedSource = probe.boundUnit ~= source
        local changedIdentity = guidReadable and probe.boundGUID ~= nil
            and probe.boundGUID ~= guid
        local newlyReadableIdentity = guidReadable and probe.boundGUID == nil
        local forced = forceContainerRefresh == true and not newlyConstructed
            and (host.unit == "target" or host.unit == "focus")

        if (changedSource or changedIdentity) and host.unit ~= "player" then
            probe.rebindPending = true
        end
        -- A target binding event persists across unrelated aura and flag
        -- events until a readable current identity can be refreshed safely.
        if host.unit ~= "player" and not guidReadable
            and (probe.rebindPending or probe.boundGUID == nil) then
            probe.rebindPending = true
            hide(host, "unit-identity-unreadable")
            return
        end
        local needsBinding = changedSource or changedIdentity or newlyReadableIdentity
            or probe.rebindPending
        if needsBinding or forced then
            -- Force-refreshing the built-in group may change its protected
            -- layout. Do not attempt it in combat: hide the independent
            -- viewport and retry from the next normal OOC refresh.
            local combat, known = R.SafeBool(InCombatLockdown)
            if (not known or combat) and needsBinding then
                hide(host, changedSource and "source-rebind-deferred-combat"
                    or "unit-rebind-deferred-combat")
                return
            end
            -- A routine flags/portrait refresh with the same binding can
            -- leave native UNIT_AURA processing active during lockdown.
            if known and not combat then
                local refreshed = pcall(function()
                    if changedSource then
                        probe.container:SetUnit(source)
                    else
                        -- Rebinding the same token cannot request a full parse.
                        probe.container:UpdateAllAuras()
                    end
                end)
                if not refreshed then
                    probe.rebindPending = true
                    hide(host, "unit-refresh-failed")
                    return
                end
                probe.boundUnit = source
                if guidReadable then probe.boundGUID = guid end
                probe.rebindPending = false
            end
        end
    end

    local playerFallback = playerEligible
        and ((host._secondaryMode == "race" and host._raceBaselineActive == true)
            or (host._secondaryMode=="hidden" and host._raceArtUnavailable==true))
        and host._ghostActive ~= true and host._formStateActive ~= true

    -- On nonhostile Target/Focus, a complete, public second-aura or form
    -- selection wins. Only race/hidden fallback can expose the native
    -- second cell; Ghost and form-state primaries must not be guessed
    -- past by a generic aura ribbon.
    local publicSecond = host._secondaryMode == "aura"
        or host._secondaryMode == "interrupt"
        or host._secondaryMode == "form"
        or host._secondaryMode == "ghost"
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
    -- The ribbon contains aura occurrences only. A confirmed form or Ghost
    -- can occupy either spot on a hostile target as well as a friendly one.
    local witness = exactReads and exactReads.nativeSecondWitness
    if witness and witness.unit ~= probe.boundUnit then witness = nil end
    local aboveStatic = witness and exactReads.auraPairAboveStatic
    local hostileFallback = hostile == true and
        ((host._ghostActive ~= true and host._formStateActive ~= true)
            or aboveStatic)
    local otherShow = otherEligible and not publicSecond and (hostileFallback or otherFallback)
    local show = otherShow or playerFallback

    -- Native groups count only auras. A current school lockout can occupy
    -- either place. Permit the ribbon only with two proven higher real
    -- effects, and expire that proof with their existing bounded fallback.
    if show and (host._schoolInterruptHidePending or (host._schoolInterrupt and not aboveStatic)) then
        hide(host,"school-interrupt-rank-unverified")
        return
    end

    if show then
        if host._secondaryElectionReason == "alias-no-physical-runner" or host._secondaryOnlyRepeatedSpell
            or knownOrderConflict(host, exactReads) or knownRibbonMismatch(probe,witness) then
            hide(host, "readable-native-order-conflict")
            return
        end
        if aboveStatic then
            if not boundStaticFallback(host,probe,witness) then
                hide(host,"static-fallback-expiry-unverified")
                return
            end
        else
            clearStaticExpiry(probe)
        end
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
                and (host._secondaryMode=="race" and "player-native-race-fallback" or "player-native-without-race-art")
                or otherFallback and "friendly-secondary-native-fallback"
                or "other-unit-native-ribbon"
            if deferredHostileHelpful then
                host._nativeSecondProbeReason =
                    host._nativeSecondProbeReason .. ":hostile-helpful-deferred"
            end
        end
    else
        hide(host, playerEligible and "readable-second-or-static-owner"
            or otherEligible and "readably-ranked-or-static"
            or "unit-ineligible")
    end
end
