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

local function petButton(button, textures, art)
    -- This callback runs for a fixed preallocated batch, not for each
    -- observed aura. No aura data or native button count is examined.
    button:SetSize(CELL,CELL)
    button:EnableMouse(false)

    -- Blizzard still needs its normal icon receiver. Keep it permanently
    -- transparent; this button's PURPOSE is to conditionally show the pet's
    -- artwork, not to show a duplicate first aura as its fallback.
    local nativeIcon = button:CreateTexture(nil,"BACKGROUND")
    nativeIcon:SetSize(1,1)
    nativeIcon:SetPoint("CENTER",button,"CENTER")
    nativeIcon:SetAlpha(0)
    button:SetIcon(nativeIcon)

    local image = button:CreateTexture(nil,"ARTWORK")
    image:SetSize(ICON,ICON)
    image:SetPoint("CENTER",button,"CENTER")
    image:SetTexture(art)
    local mask = button:CreateMaskTexture(nil,"ARTWORK")
    mask:SetAtlas("CircleMask",false)
    mask:SetAllPoints(image)
    image:AddMaskTexture(mask)
    textures[#textures+1] = image

    local rim = button:CreateTexture(nil,"OVERLAY")
    rim:SetAtlas("UI-HUD-UnitFrame-TotemFrame",false)
    rim:SetSize(RIM,RIM)
    rim:SetPoint("CENTER",button,"CENTER",RIM_X,RIM_Y)
end

local function construct(host, art, guid)
    local state = table.remove(familyPool)
    if state then
        local ok = pcall(function()
            state.root:Hide()
            anchoredFrame(host,state.root)
            -- A pooled native container was disabled on release. The
            -- original SetUnit(nil) was rejected by Blizzard and could
            -- retain the old target's presence even after the art changed.
            for _,texture in ipairs(state.textures) do texture:SetTexture(art) end
            for _,c in ipairs(state.containers) do
                c:SetUnit(host.unit)
                c:SetEnabled(true)
            end
        end)
        if not ok then
            host._petSecondaryReason = "rebind-failed"
            return nil
        end
        state.guid, state.art = guid, art
        state.unit = host.unit
        state.ready = true
        return state
    end

    state = {containers={},textures={},art=art,guid=guid,
        unit=host.unit,ready=false}
    host._petSecondaryFallback = state
    local ok = pcall(function()
        local root = CreateFrame("Frame",nil,UIParent,R.AURA_ANCHOR_TEMPLATE)
        state.root = root
        root:Hide()
        root:SetSize(CELL,CELL)
        root:EnableMouse(false)
        anchoredFrame(host,root)

        -- Separate native containers intentionally overlap. Each contributes
        -- the SAME family art if its polarity has any aura. If both are
        -- present the opaque image overlaps itself, still one small circle.
        for _,filter in ipairs({"HELPFUL|INCLUDE_NAME_PLATE_ONLY",
            "HARMFUL|INCLUDE_NAME_PLATE_ONLY"}) do
            local container = CreateFrame("AuraContainer",nil,root,
                "CustomAuraContainerTemplate")
            state.containers[#state.containers+1] = container
            container:SetPoint("TOPLEFT",root,"TOPLEFT",0,0)
            container:SetFrameLevel(root:GetFrameLevel()+1)
            container:AddAuraGroup("PetPresent",filter,{
                maxFrameCount=1,
                sortMethod=R.SORT_METHOD,
                sortDirection=R.SORT_DIRECTION,
                layout={elementWidth=CELL,elementHeight=CELL,
                    elementSpacing=0,groupSpacing=0},
                initializeFrame=function(button)
                    petButton(button,state.textures,art)
                end,
            })
        end
        -- Binding after group registration avoids repeated live aura parsing
        -- for each preallocated group; Blizzard owns all future aura updates.
        for _,c in ipairs(state.containers) do
            c:SetUnit(host.unit)
            -- New custom aura containers are born disabled. Without this,
            -- even a confirmed pet with a real helpful/harmful aura never
            -- draws its native presence-gated family fallback.
            c:SetEnabled(true)
        end
        state.ready=true
    end)
    if not ok then
        state.ready=false
        if state.root then pcall(state.root.Hide,state.root) end
        host._petSecondaryReason="native-presence-build-failed"
        return nil
    end
    return state
end

function R.HidePetSecondaryFallback(host, reason)
    if not host then return end
    local state=host._petSecondaryFallback
    if state and state.root then pcall(state.root.Hide,state.root) end
    host._petSecondaryReason=reason or "hidden"
end

function R.ReleasePetSecondaryFallback(host)
    local state=host and host._petSecondaryFallback
    if not state then return end
    R.HidePetSecondaryFallback(host,"host-released")
    if state.ready then
        local disabled = true
        -- On Forever, SetUnit(nil) asserts instead of clearing native
        -- aura groups. SetEnabled(false) fully drops frame assignments
        -- and unregisters unit events; the next owner re-enables them.
        for _,c in ipairs(state.containers) do
            if type(c.SetEnabled) ~= "function"
                or not pcall(c.SetEnabled,c,false) then
                disabled = false
            end
        end
        if disabled then
            state.guid=nil
            state.unit=nil
            familyPool[#familyPool+1]=state
        end
    end
    host._petSecondaryFallback=nil
end

function R.UpdatePetSecondaryFallback(host,enabled)
    if not host or not UNITS[host.unit] then return end
    if not enabled or not R.db or not R.db.enabled
        or R.db.secondaryPortrait==false or R.db.petPortraits==false then
        R.HidePetSecondaryFallback(host,"disabled-or-ineligible")
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
        state=construct(host,art,guid)
        if not state then return end
        host._petSecondaryFallback=state
    end
    if not state.ready then
        R.HidePetSecondaryFallback(host,"construction-failed")
        return
    end

    if state.guid~=guid or state.art~=art or state.unit~=host.unit then
        -- Updating the image on native aura buttons in combat would be a
        -- protected operation and could leak stale art after a target swap.
        -- Hide now, resume automatically on the first safe out-of-combat pass.
        if combatBlocked() then
            R.HidePetSecondaryFallback(host,"family-change-deferred-combat")
            return
        end
        local ok=pcall(function()
            for _,c in ipairs(state.containers) do c:SetEnabled(false) end
            for _,tex in ipairs(state.textures) do tex:SetTexture(art) end
            for _,c in ipairs(state.containers) do
                c:SetUnit(host.unit)
                c:SetEnabled(true)
            end
        end)
        if not ok then
            R.HidePetSecondaryFallback(host,"family-update-failed")
            return
        end
        state.guid,state.art,state.unit=guid,art,host.unit
    end

    -- This Show does NOT mean an aura is present! The two native group frame
    -- providers decide that themselves, including for secret aura data.
    -- On a naked pet the root is visible but has zero rendered children.
    if not pcall(state.root.Show,state.root) then
        R.HidePetSecondaryFallback(host,"presentation-failed")
        return
    end
    host._petSecondaryReason="confirmed-pet-native-aura-presence"
end
