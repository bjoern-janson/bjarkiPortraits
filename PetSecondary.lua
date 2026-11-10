local addonName, BP = ...
local R = assert(BP.Runtime, "Core.lua must load first")

-- A confirmed Hunter/Warlock pet's family artwork is the secondary fallback,
-- but ONLY while the pet has at least one actual native aura. The visual gate
-- is two native aura groups (HELPFUL and HARMFUL), with maxFrameCount=1:
-- Blizzard creates/shows an art-covered button while that polarity has an
-- aura, and creates no visible button for a completely aura-free pet.
-- The public addon never reads protected aura existence, identity or counts.
-- When there is a genuine second aura, the existing aura/ribbon renders ABOVE
-- this family fallback. Do not modify the main pet-family portrait.
--
-- This is a targeted-unit feature (Target and Focus), NOT local PetFrame.
-- Never infer that a wild beast, totem or unknown creature is a player pet.

local CELL, ICON, RIM, RIM_X, RIM_Y = R.SecondaryCircleGeometry("target")
local UNITS = {target=true, focus=true}
local familyPool = {}

local function combatBlocked()
    local combat, readable = R.SafeBool(InCombatLockdown)
    return not readable or combat
end

local function anchoredFrame(host, frame)
    frame:ClearAllPoints()
    local corner, dx, dy = R.SecondaryCirclePlacement(host.unit)
    frame:SetPoint("CENTER", host.portrait, corner, dx, dy)
    local badge = host.secondaryBadge
    local strata = "HIGH"
    local level = 40
    if badge then
        if type(badge.GetFrameStrata) == "function" then
            local ok, value = pcall(badge.GetFrameStrata, badge)
            if ok and R.CanAccess(value) and type(value) == "string" then
                strata = value
            end
        end
        if type(badge.GetFrameLevel) == "function" then
            local ok, value = pcall(badge.GetFrameLevel, badge)
            if ok and R.CanAccess(value) and type(value) == "number"
                and value >= 0 and value < 10000 then
                level = value
            end
        end
    end
    frame:SetFrameStrata(strata)
    -- Render beneath the existing public second aura and the secure native
    -- second-cell viewport, so neither gets obscured by the family fallback.
    frame:SetFrameLevel(math.max(0,level-3))
end

local function petButton(parts)
    local button=parts.button
    -- This callback runs for a fixed preallocated batch, not for each
    -- observed aura. No aura data or native button count is examined.
    button:SetSize(CELL,CELL)
    button:EnableMouse(false)

    -- Blizzard still needs its normal icon receiver. Keep it permanently
    -- transparent; this button's PURPOSE is to conditionally show the pet's
    -- artwork, not to show a duplicate first aura as its fallback.
    local nativeIcon = parts.nativeIcon or button:CreateTexture(nil,"BACKGROUND")
    parts.nativeIcon = nativeIcon
    nativeIcon:SetSize(1,1)
    nativeIcon:SetPoint("CENTER",button,"CENTER")
    nativeIcon:SetAlpha(0)
    button:SetIcon(nativeIcon)

    local image = parts.image or button:CreateTexture(nil,"ARTWORK")
    parts.image = image
    image:SetSize(ICON,ICON)
    image:SetPoint("CENTER",button,"CENTER")
    if not R.ApplySecondaryIconCrop(image) then error("pet icon crop unavailable") end
    local mask = parts.mask or button:CreateMaskTexture(nil,"ARTWORK")
    parts.mask = mask
    mask:SetAtlas("CircleMask",false)
    mask:SetAllPoints(image)
    if not parts.masked then
        image:AddMaskTexture(mask)
        parts.masked = true
    end

    local rim = parts.rim or button:CreateTexture(nil,"OVERLAY")
    parts.rim = rim
    rim:SetAtlas("UI-HUD-UnitFrame-TotemFrame",false)
    rim:SetSize(RIM,RIM)
    rim:SetPoint("CENTER",button,"CENTER",RIM_X,RIM_Y)
    parts.button = nil
    return image
end

local function invoke(object, method, ...)
    return object[method](object,...)
end

local function callFrame(object, method, ...)
    local ok, result = pcall(invoke,object,method,...)
    return ok and R.CanAccess(result) and result ~= false
end

local function hideRoot(state)
    if not state or not state.root or callFrame(state.root,"Hide") then return true,true end
    if callFrame(state.root,"SetAlpha",0) then
        state.muted = true
        return true,false
    end
    return false
end

local function disableGroups(state)
    local disabled = true
    for _,container in ipairs(state.containers) do
        if not callFrame(container,"SetEnabled",false) then disabled = false end
    end
    return disabled
end

local FILTERS = {"HELPFUL|INCLUDE_NAME_PLATE_ONLY", "HARMFUL|INCLUDE_NAME_PLATE_ONLY"}

local function prepareGroups(state)
    for i,filter in ipairs(FILTERS) do
        if not state.groups[i] then
            local root = state.root
            local container = state.containers[i]
            if not container then
                container = CreateFrame("AuraContainer",nil,root,"CustomAuraContainerTemplate")
                state.containers[i] = container
            end
            local firstImage = state.groupStart[i]
            local registered = false
            if firstImage then
                -- An exception may follow registration. Query only our own
                -- declared group key, never its assigned frames or aura count.
                local known
                registered, known = R.SafeBool(container.HasAuraGroup,container,"PetPresent")
                if not known then return false end
                if not registered then
                    for j=#state.parts,firstImage,-1 do
                        state.parts[j],state.textures[j]=nil,nil
                    end
                end
            end
            if not registered then
                container:SetPoint("TOPLEFT",root,"TOPLEFT",0,0)
                container:SetFrameLevel(root:GetFrameLevel()+1)
                state.groupStart[i] = #state.parts+1
                container:AddAuraGroup("PetPresent",filter,{
                    maxFrameCount=1,
                    sortMethod=R.SORT_METHOD,
                    sortDirection=R.SORT_DIRECTION,
                    layout={elementWidth=CELL,elementHeight=CELL,elementSpacing=0,groupSpacing=0},
                    initializeFrame=function(button)
                        -- Blizzard preallocates a fixed batch. Keep a partial
                        -- visual setup repairable even if its secure callback
                        -- reports an error independently of AddAuraGroup.
                        local index=#state.parts+1
                        local parts={button=button}
                        state.parts[index]=parts
                        local ok,image=pcall(petButton,parts)
                        if ok then state.textures[index]=image end
                    end,
                })
            end
            state.groups[i] = true
            state.groupStart[i] = nil
        end
    end
    for i,parts in ipairs(state.parts) do
        if parts.button then state.textures[i]=petButton(parts) end
    end
    state.ready = true
    return true
end

local function bindFamily(host,state,art,guid)
    -- Invalidate before the first mutation. Even a return to the old GUID
    -- must repair both textures and both groups after a partial change.
    state.guid,state.art,state.unit = nil,nil,nil
    if not state.root then state.root=CreateFrame("Frame",nil,UIParent,R.AURA_ANCHOR_TEMPLATE) end
    if not hideRoot(state) or not disableGroups(state) then return false end
    if not state.anchored then
        state.root:SetSize(CELL,CELL)
        state.root:EnableMouse(false)
        anchoredFrame(host,state.root)
        state.anchored=true
    end
    if not state.ready and not prepareGroups(state) then return false end
    for _,texture in ipairs(state.textures) do
        local success=texture:SetTexture(art)
        if not R.CanAccess(success) or success~=true then return false end
    end
    for _,container in ipairs(state.containers) do
        if not callFrame(container,"SetUnit",host.unit) or not callFrame(container,"SetEnabled",true) then
            return false
        end
    end
    state.guid,state.art,state.unit=guid,art,host.unit
    return true
end

function R.HidePetSecondaryFallback(host, reason)
    if not host then return true end
    host._petSecondaryReason=reason or "hidden"
    return hideRoot(host._petSecondaryFallback)
end

function R.ReleasePetSecondaryFallback(host)
    local state=host and host._petSecondaryFallback
    if not state then return true end
    state.guid,state.art,state.unit=nil,nil,nil
    local suppressed,hidden=R.HidePetSecondaryFallback(host,"host-released")
    if combatBlocked() then return false end
    local disabled=disableGroups(state)
    -- An actually hidden root may retain a failed disable in the pool.
    -- bindFamily must disable every old group before any later assignment.
    -- Alpha-only suppression still needs positive group deactivation.
    if not suppressed or (not hidden and not disabled) then return false end
    state.anchored=false
    familyPool[#familyPool+1]=state
    host._petSecondaryFallback=nil
    return true
end

function R.UpdatePetSecondaryFallback(host,enabled)
    if not host or not UNITS[host.unit] then return end
    if not enabled or not R.db or not R.db.enabled
        or R.db.secondaryPortrait==false or R.db.petPortraits==false then
        R.HidePetSecondaryFallback(host,"disabled-or-ineligible")
        return
    end
    local visible, reason = R.SecondaryOwnerVisible(host)
    if not visible then
        R.HidePetSecondaryFallback(host, reason)
        return
    end

    local art,guid,reason=R.ResolveObservedPetSecondaryArt(host.unit)
    if not art or not guid then
        -- Inaccessible identity or a new non-pet target may NEVER display
        -- the previous pet's family picture.
        R.HidePetSecondaryFallback(host,reason or "not-pet")
        return
    end

    local state=host._petSecondaryFallback
    if not state then
        if combatBlocked() then
            host._petSecondaryReason="construction-deferred-combat"
            return
        end
        state=table.remove(familyPool) or {containers={},textures={},parts={},groups={},groupStart={}}
        host._petSecondaryFallback=state
    end

    if state.guid~=guid or state.art~=art or state.unit~=host.unit then
        -- Updating the image on native aura buttons in combat would be a
        -- protected operation and could leak stale art after a target swap.
        -- Hide now, resume automatically on the first safe out-of-combat pass.
        if combatBlocked() then
            R.HidePetSecondaryFallback(host,"family-change-deferred-combat")
            return
        end
        local ok,applied=pcall(bindFamily,host,state,art,guid)
        if not ok or not applied then
            R.HidePetSecondaryFallback(host,"family-update-failed")
            return
        end
    end

    -- This Show does NOT mean an aura is present! The two native group frame
    -- providers decide that themselves, including for secret aura data.
    -- On a naked pet the root is visible but has zero rendered children.
    if not callFrame(state.root,"Show") or (state.muted and not callFrame(state.root,"SetAlpha",1)) then
        R.HidePetSecondaryFallback(host,"presentation-failed")
        return
    end
    state.muted=false
    host._petSecondaryReason="confirmed-pet-native-aura-presence"
end
