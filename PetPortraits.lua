local addonName, BP = ...
local R = assert(BP.Runtime, "Core.lua must load first")

-- This module is presentation-only. It has no AuraContainer access and it does
-- not run on targettarget/focustarget. Its texture sits between the native
-- portrait and secure aura buttons on target/focus.
local observed = setmetatable({}, { __mode = "k" })
local localPet

local HUNTER_IDS = {
    [1]=true,[2]=true,[3]=true,[4]=true,[5]=true,[6]=true,[7]=true,[8]=true,[9]=true,
    [11]=true,[12]=true,[20]=true,[21]=true,[24]=true,[25]=true,[26]=true,[27]=true,
}
local HUNTER_NAMES = {
    ["Wolf"]=true,["Cat"]=true,["Spider"]=true,["Bear"]=true,["Boar"]=true,["Crocolisk"]=true,
    ["Carrion Bird"]=true,["Crab"]=true,["Gorilla"]=true,["Raptor"]=true,["Tallstrider"]=true,
    ["Scorpid"]=true,["Turtle"]=true,["Bat"]=true,["Hyena"]=true,["Owl"]=true,["Wind Serpent"]=true,
}
local WARLOCK_IDS = { [23]=688, [16]=697, [17]=712, [15]=691 }
local WARLOCK_NAMES = { Imp=true, Voidwalker=true, Succubus=true, Incubus=true, Felhunter=true, Infernal=true, Doomguard=true }

local function classToken(unit)
    if UnitClassBase then
        local token, readable = R.SafeString(UnitClassBase, unit)
        if readable then return token end
    end
    if UnitClass then
        local ok, _, token = pcall(UnitClass, unit)
        if ok and not R.IsSecret(token) and type(token) == "string" then return token end
    end
end

local function creatureFamily(unit)
    if not UnitCreatureFamily then return nil, nil end
    local ok, name, id = pcall(UnitCreatureFamily, unit)
    if not ok or R.IsSecret(name) or R.IsSecret(id) then return nil, nil end
    return type(name) == "string" and name or nil, type(id) == "number" and id or nil
end

local function spellTexture(spellID)
    if not spellID then return nil end
    if C_Spell and C_Spell.GetSpellTexture then
        local ok, texture = pcall(C_Spell.GetSpellTexture, spellID)
        if ok and not R.IsSecret(texture) then return texture end
    elseif GetSpellTexture then
        local ok, texture = pcall(GetSpellTexture, spellID)
        if ok and not R.IsSecret(texture) then return texture end
    end
end

local function familyTexture(familyID)
    if familyID and C_CreatureInfo and C_CreatureInfo.GetCreatureFamilyInfo then
        local ok, info = pcall(C_CreatureInfo.GetCreatureFamilyInfo, familyID)
        if ok and info and not R.IsSecret(info) then
            local icon = info.iconFile
            if icon and not R.IsSecret(icon) then return icon end
        end
    end
end

local function petActionTexture()
    if not GetPetActionInfo then return nil end
    for slot = 1, (NUM_PET_ACTION_SLOTS or 10) do
        local ok, _, texture, isToken = pcall(GetPetActionInfo, slot)
        if ok and texture and not R.IsSecret(texture) and isToken ~= true then return texture end
    end
end

local function classify(unit)
    local samePet, sameReadable = R.SafeBool(UnitIsUnit, unit, "pet")
    if sameReadable and samePet then return classToken("player"), true end

    local controlled, controlledReadable = R.SafeBool(UnitPlayerControlled, unit)
    if not controlledReadable or not controlled then return nil, false end
    local name, id = creatureFamily(unit)
    if WARLOCK_IDS[id] or WARLOCK_NAMES[name] then return "WARLOCK", false end
    if HUNTER_IDS[id] or HUNTER_NAMES[name] then return "HUNTER", false end
    return nil, false
end

local function foundationTexture(unit)
    local owner, own = classify(unit)
    if owner ~= "HUNTER" and owner ~= "WARLOCK" then return nil end
    local name, id = creatureFamily(unit)
    if owner == "HUNTER" then
        return familyTexture(id) or (own and petActionTexture()) or spellTexture(2649)
    end
    local summon = name == "Incubus" and 713 or WARLOCK_IDS[id]
    return spellTexture(summon)
end

local function createHostTexture(host)
    local texture = host.layer:CreateTexture(nil, "ARTWORK", nil, 1)
    texture:SetAllPoints(host.portrait)
    texture:SetTexCoord(0, 1, 0, 1)
    if host.portraitMask and texture.AddMaskTexture then
        pcall(texture.AddMaskTexture, texture, host.portraitMask)
    end
    texture:Hide()
    return texture
end

function R.UpdateObservedPetPortraits()
    for _, unit in ipairs({ "target", "focus" }) do
        local host = R.hosts[unit]
        if host then
            local texture = observed[host]
            local icon = R.db and R.db.petPortraits and foundationTexture(unit) or nil
            if icon then
                if not texture then texture = createHostTexture(host); observed[host] = texture end
                texture:SetTexture(icon)
                texture:Show()
            elseif texture then
                texture:Hide()
            end
        end
    end
end

local function getPetPortrait()
    local frame = _G.PetFrame
    local portrait = _G.PetPortrait or (frame and frame.Portrait)
    local mask = frame and (frame.PortraitMask or frame.portraitMask)
    return portrait, mask, frame
end

local function ensureLocalPetTexture()
    if localPet then return localPet end
    local portrait, mask, frame = getPetPortrait()
    if not portrait or not frame then return nil end
    local parent = portrait.GetParent and portrait:GetParent() or frame
    -- PetFrame's native chrome is on the BORDER draw layer. Keep the custom
    -- family foundation above the native BACKGROUND portrait but below that
    -- chrome so the addon does not paint over the ring.
    local texture = parent:CreateTexture(nil, "BACKGROUND", nil, 1)
    texture:SetAllPoints(portrait)
    texture:SetTexCoord(0, 1, 0, 1)
    if mask and texture.AddMaskTexture then pcall(texture.AddMaskTexture, texture, mask) end
    texture:Hide()
    localPet = texture
    return texture
end

function R.UpdateLocalPetPortrait()
    local texture = ensureLocalPetTexture()
    if not texture then return end
    local icon = R.db and R.db.petPortraits and foundationTexture("pet") or nil
    if icon then texture:SetTexture(icon); texture:Show() else texture:Hide() end
end

function R.UpdatePetPortraits()
    R.UpdateLocalPetPortrait()
    R.UpdateObservedPetPortraits()
end
