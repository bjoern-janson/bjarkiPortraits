local addonName, BP = ...
local R = assert(BP.Runtime, "Core.lua must load first")

-- This module is presentation-only. It has no AuraContainer access. Its texture
-- sits between the native portrait and secure aura buttons on target/focus and
-- the two derived target frames.
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
-- Creature-family IDs identify the demon; values are that demon's summon
-- spell. Keep this keyed by family ID so localized family names are optional.
local WARLOCK_IDS = { [15]=691, [16]=697, [17]=712, [19]=18540, [23]=688 }
local WARLOCK_NAMES = {
    Imp=688, Voidwalker=697, Succubus=712, Incubus=713, Felhunter=691,
    Infernal=1122, Doomguard=18540,
}
local KNOWN_FAMILY_IDS = {}
for familyID in pairs(HUNTER_IDS) do KNOWN_FAMILY_IDS[familyID] = true end
for familyID in pairs(WARLOCK_IDS) do KNOWN_FAMILY_IDS[familyID] = true end
local FAMILY_ID_BY_NAME = {}

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
    name = type(name) == "string" and name or nil
    id = type(id) == "number" and id or nil

    -- WoW: Forever's Classic API may expose only the localized family name.
    -- Resolve it against the client's own family table instead of comparing
    -- translated names with English literals or guessing from a pet ability.
    if not id and name then
        local cached = FAMILY_ID_BY_NAME[name]
        if cached ~= nil then
            id = cached ~= false and cached or nil
        elseif C_CreatureInfo and C_CreatureInfo.GetCreatureFamilyInfo then
            for familyID in pairs(KNOWN_FAMILY_IDS) do
                local infoOK, info = pcall(C_CreatureInfo.GetCreatureFamilyInfo, familyID)
                if infoOK and R.CanAccess(info) and info ~= nil then
                    local familyName = info.name
                    if R.CanAccess(familyName) and type(familyName) == "string" then
                        FAMILY_ID_BY_NAME[familyName] = familyID
                        if familyName == name then id = familyID end
                    end
                end
                if id then break end
            end
            FAMILY_ID_BY_NAME[name] = id or false
        else
            FAMILY_ID_BY_NAME[name] = false
        end
    end

    return name, id
end

local function hasPetGUID(unit)
    if not UnitGUID then return false end
    local guid, readable = R.SafeString(UnitGUID, unit)
    return readable and guid:match("^Pet%-") ~= nil
end

local function spellTexture(spellID)
    if not spellID then return nil end
    if C_Spell and C_Spell.GetSpellTexture then
        local ok, texture = pcall(C_Spell.GetSpellTexture, spellID)
        if ok and R.CanAccess(texture) then return texture end
    elseif GetSpellTexture then
        local ok, texture = pcall(GetSpellTexture, spellID)
        if ok and R.CanAccess(texture) then return texture end
    end
end

local function familyTexture(familyID)
    if familyID and C_CreatureInfo and C_CreatureInfo.GetCreatureFamilyInfo then
        local ok, info = pcall(C_CreatureInfo.GetCreatureFamilyInfo, familyID)
        if ok and R.CanAccess(info) and info ~= nil then
            local icon = info.iconFile
            if R.CanAccess(icon) and icon ~= nil then return icon end
        end
    end
end

local function petActionTexture()
    if not GetPetActionInfo then return nil end
    for slot = 1, (NUM_PET_ACTION_SLOTS or 10) do
        local ok, _, texture, isToken = pcall(GetPetActionInfo, slot)
        if ok and R.CanAccess(texture) and R.CanAccess(isToken)
            and texture ~= nil and isToken ~= true
        then
            return texture
        end
    end
end

local function classify(unit)
    local samePet, sameReadable = R.SafeBool(UnitIsUnit, unit, "pet")
    if sameReadable and samePet then
        local name, id = creatureFamily(unit)
        return classToken("player"), true, name, id, "local pet"
    end

    local name, id = creatureFamily(unit)
    local petGUID = hasPetGUID(unit)

    -- A positive pet API result is definitive. A negative result is not: some
    -- battleground unit tokens report false for pets owned by the other faction.
    -- Creature families then choose Hunter/Warlock art; an unfamiliar family
    -- remains a confirmed pet but does not get guessed into the Hunter class.
    local otherPet, otherReadable = R.SafeBool(UnitIsOtherPlayersPet, unit)
    if (otherReadable and otherPet) or petGUID then
        if WARLOCK_IDS[id] or WARLOCK_NAMES[name] then
            return "WARLOCK", false, name, id, "confirmed Warlock pet"
        end
        if HUNTER_IDS[id] or HUNTER_NAMES[name] then
            return "HUNTER", false, name, id, "confirmed player pet"
        end
        return "UNKNOWN_PET", false, name, id, "confirmed pet family unavailable"
    end

    -- If the pet API is negative or unavailable, use positive control evidence
    -- plus a recognized Hunter/Warlock family. This remains narrow enough to
    -- reject ordinary wild beasts and unknown charmed NPCs.
    local controlled, controlledReadable = R.SafeBool(UnitPlayerControlled, unit)
    if not petGUID and (not controlledReadable or not controlled) then
        local reason = controlledReadable and "not player-controlled"
            or "pet identity unavailable"
        return nil, false, name, id, reason
    end
    if WARLOCK_IDS[id] or WARLOCK_NAMES[name] then
        return "WARLOCK", false, name, id, "controlled Warlock family"
    end
    -- Creature family names are localized, so numeric family IDs are the
    -- language-independent allowlist whenever the client exposes them.
    if HUNTER_IDS[id] or HUNTER_NAMES[name] then
        return "HUNTER", false, name, id, "controlled Hunter family"
    end
    return nil, false, name, id, "unrecognized controlled family"
end

local function foundationTexture(unit)
    local owner, own, name, id = classify(unit)
    if owner == "UNKNOWN_PET" then
        -- A generic Growl icon falsely identifies every unknown pet as a Hunter
        -- pet. Leave the portrait art alone until the family is actually known.
        return nil
    end
    if owner ~= "HUNTER" and owner ~= "WARLOCK" then return nil end
    if owner == "HUNTER" then
        return familyTexture(id) or (own and petActionTexture()) or spellTexture(2649)
    end
    local summon = WARLOCK_NAMES[name] or WARLOCK_IDS[id]
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

local OBSERVED_UNITS = { "target", "focus", "targettarget", "focustarget" }

function R.UpdateObservedPetPortrait(unit)
    local host = R.hosts[unit]
    if not host then return end

    local texture = observed[host]
    local icon = R.db and R.db.enabled and R.db.petPortraits and foundationTexture(unit) or nil
    if icon then
        if not texture then texture = createHostTexture(host); observed[host] = texture end
        texture:SetTexture(icon)
        texture:Show()
    elseif texture then
        texture:Hide()
    end
end

function R.UpdateObservedPetPortraits()
    for _, unit in ipairs(OBSERVED_UNITS) do
        R.UpdateObservedPetPortrait(unit)
    end
end

function R.GetPetPortraitDebug(unit)
    local owner, own, name, id, reason = classify(unit)
    local samePet, sameReadable = R.SafeBool(UnitIsUnit, unit, "pet")
    local otherPet, otherReadable = R.SafeBool(UnitIsOtherPlayersPet, unit)
    local controlled, controlledReadable = R.SafeBool(UnitPlayerControlled, unit)
    local icon = foundationTexture(unit)
    local overlayShown = false
    if unit == "pet" then
        if localPet and localPet.IsShown then
            local ok, shown = pcall(localPet.IsShown, localPet)
            overlayShown = ok and shown == true
        end
    else
        local host = R.hosts[unit]
        local texture = host and observed[host]
        if texture and texture.IsShown then
            local ok, shown = pcall(texture.IsShown, texture)
            overlayShown = ok and shown == true
        end
    end
    return unit
        .. " owner=" .. tostring(owner or "none")
        .. " ownPet=" .. (sameReadable and tostring(samePet) or "unknown")
        .. " otherPet=" .. (otherReadable and tostring(otherPet) or "unknown")
        .. " guidPet=" .. tostring(hasPetGUID(unit))
        .. " controlled=" .. (controlledReadable and tostring(controlled) or "unknown")
        .. " family=" .. tostring(name or "unknown")
        .. " familyID=" .. tostring(id or "unknown")
        .. " reason=" .. tostring(reason)
        .. " icon=" .. tostring(icon ~= nil)
        .. " overlay=" .. tostring(overlayShown)
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
    if not R.db or not R.db.enabled or not R.db.petPortraits then
        if localPet then localPet:Hide() end
        return
    end
    local texture = ensureLocalPetTexture()
    if not texture then return end
    local icon = foundationTexture("pet")
    if icon then texture:SetTexture(icon); texture:Show() else texture:Hide() end
end

function R.UpdatePetPortraits()
    R.UpdateLocalPetPortrait()
    R.UpdateObservedPetPortraits()
end
