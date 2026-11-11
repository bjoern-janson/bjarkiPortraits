local addonName, BP = ...
BP.Runtime = BP.Runtime or {}
local R = BP.Runtime

R.VERSION = "0.1.249-performance-recovery"
R.PREFIX = "|cff74c7ecbjarkiPortraits|r"
-- Four native Blizzard party portraits share the same aura engine as player/pet.
-- Avoid name-based frame discovery: PartyFrame pools/recycles member frames.
R.PARTY_UNITS = {party1=true, party2=true, party3=true, party4=true}
R.TRACKED_UNITS = { "player", "pet", "target", "focus", "targettarget", "focustarget",
    "party1", "party2", "party3", "party4" }
R.SMALL_UNITS = { targettarget = true, focustarget = true }
R.hosts = {}
R.testMode = false
R.buildQueued = false
R.forceRebuildQueued = false
R.AURA_ANCHOR_TEMPLATE = "DisableUntrustedLayoutScriptsTemplate"
R.SORT_METHOD = AuraContainerSortMethod and AuraContainerSortMethod.AuraInstanceIDOnly
R.SORT_DIRECTION = AuraContainerSortDirection and AuraContainerSortDirection.Reverse
R.SWIPE_TEXTURE = "Interface\\CHARACTERFRAME\\TempPortraitAlphaMask"

-- Shared geometry for public race/aura badges, native ranked-second ribbons
-- and pet-family fallbacks. The full unit frames face opposite ways:
-- Player and party1-4 show their bars to the RIGHT of the portrait;
-- Target/Focus bars sit LEFT of the portrait. Mirror the 0.1.213 raised
-- inset so badges sit on each portrait's bar side without hiding combo points.
-- Decisions depend on the stable public unit token, never aura data.
function R.SecondaryCirclePlacement(unit)
    if unit == "player" or R.PARTY_UNITS[unit] then
        return "TOPRIGHT", -10, 12
    end
    if unit == "target" or unit == "focus" then
        return "TOPLEFT", 10, 12
    end
    return nil
end

-- In full-size unit frames, the actual spell/race artwork should match
-- Blizzard's 30x30 regular buff icon. The *circular rim*, not the artwork,
-- grows around that 30px icon. Scale native TotemButtonTemplate's original
-- 37px cell / 30px rim / 22px art by 30/22 ~= 1.364, giving a
-- 50px cell / 41px rim / 30px icon. This preserves the familiar
-- rim-to-art breathing room without zooming/cropping the source texture.
-- Party frames scale the same ratio down to 40/33/24.
-- Native Totem atlas optical offsets scale proportionally too; the actual
-- masked art remains centered on the cell. All three renderers consume
-- this shared geometry, including native clipping and pooled reuse.
function R.SecondaryCircleGeometry(unit)
    if R.PARTY_UNITS[unit] then return 40, 24, 33, 0.75, -1.5 end
    return 50, 30, 41, 1.35, -2
end

local defaults = {
    enabled = true,
    player = true,
    pet = true,
    target = true,
    focus = true,
    targettarget = true,
    focustarget = true,
    party1 = true, party2 = true, party3 = true, party4 = true,
    showSwipe = false,
    showDecimals = true,
    petPortraits = true,
    secondaryPortrait = true, -- Race fallback or guarded complete-readable runner-up; never guess secret auras.
}

function R.Print(message)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(R.PREFIX .. ": " .. tostring(message))
    end
end

function R.ApplyDefaults()
    if type(BjarkiPortraitsDB) ~= "table" then BjarkiPortraitsDB = {} end
    for key, value in pairs(defaults) do
        if BjarkiPortraitsDB[key] == nil then BjarkiPortraitsDB[key] = value end
    end
    R.db = BjarkiPortraitsDB
end

function R.IsSecret(value)
    if not issecretvalue then return false end
    local ok, secret = pcall(issecretvalue, value)
    -- Only a successful literal false proves nonsecrecy. Treat failed or
    -- malformed available checks as secret so callers cannot certify access.
    return not ok or secret ~= false
end

function R.CanAccess(value)
    if R.IsSecret(value) then return false end
    if canaccessvalue then
        local ok, accessible = pcall(canaccessvalue, value)
        -- An available checker must positively establish access. Failed or
        -- unreadable results are UNKNOWN, never permission to inspect value.
        return ok and not R.IsSecret(accessible) and accessible == true
    end
    return true
end

function R.SafeBool(fn, ...)
    if type(fn) ~= "function" then return nil, false end
    local ok, value = pcall(fn, ...)
    if not ok or not R.CanAccess(value) or type(value) ~= "boolean" then return nil, false end
    return value, true
end

function R.SafeString(fn, ...)
    if type(fn) ~= "function" then return nil, false end
    local ok, value = pcall(fn, ...)
    if not ok or not R.CanAccess(value) or type(value) ~= "string" then return nil, false end
    return value, true
end

-- Existence is evidence, not a prerequisite we are allowed to truth-test
-- directly. Forever can protect otherwise ordinary unit API results, so callers
-- must be able to distinguish ABSENT from UNKNOWN.
function R.UnitExistsState(unit)
    if not unit then return false, true end
    return R.SafeBool(UnitExists, unit)
end

function R.IsUnitEnabled(unit)
    return R.db and R.db.enabled and R.db[unit] ~= false
end

-- The secondary renderers are UIParent siblings. IsShown only tests a
-- widget's own flag; a locally shown frame can still have a hidden ancestor.
function R.SecondaryOwnerVisible(host)
    local owner = host and host.unitFrame
    for _ = 1, 32 do
        if not R.CanAccess(owner) or not owner then break end
        local ok, visible = pcall(function() return owner.IsVisible end)
        if not ok or not R.CanAccess(visible) then break end
        if type(visible) == "function" then
            local shown, known = R.SafeBool(visible, owner)
            if known then
                if shown then return true end
                return false, "native-frame-hidden"
            end
            break
        end
        local methodsOK, isShown, getParent = pcall(function() return owner.IsShown, owner.GetParent end)
        if not methodsOK or not R.CanAccess(isShown) or not R.CanAccess(getParent) then break end
        local shown, known = R.SafeBool(isShown, owner)
        if not known then break end
        if not shown then return false, "native-frame-hidden" end
        if type(getParent) ~= "function" then break end
        local parentOK, parent = pcall(getParent, owner)
        if not parentOK or not R.CanAccess(parent) then break end
        if parent == nil then return true end
        owner = parent
    end
    return false, "native-visibility-unreadable"
end

-- Read physical ownership as a single observation. A denied intermediate
-- must not be confused with a readable, absent native frame.
local function accessibleMember(owner,key)
    if not owner then return nil end
    local value=owner[key]
    if not R.CanAccess(value) then error("native frame member unavailable") end
    return value
end

local function smallFrame(unit)
    local name=unit=="targettarget" and "TargetFrame" or unit=="focustarget" and "FocusFrame"
    if name then return accessibleMember(accessibleMember(_G,name),"totFrame") or accessibleMember(_G,name.."ToT") end
end

local function partyMember(index)
    local frame=accessibleMember(_G,"PartyFrame")
    if not frame or type(index)~="number" or index<1 or index>4 then return nil end
    local get=accessibleMember(frame,"GetPartyMemberFrame")
    if type(get)=="function" then
        local result=get(frame,index)
        if not R.CanAccess(result) then error("native party frame unavailable") end
        return result
    end
    return accessibleMember(frame,"MemberFrame"..index)
end

function R.GetSmallFrame(unit)
    local ok,frame=pcall(smallFrame,unit)
    if ok then return frame end
end

function R.GetPartyMemberFrame(index)
    local ok,frame=pcall(partyMember,index)
    if ok then return frame end
end

local function resolvePortrait(unit)
    if unit=="player" then
        local frame=accessibleMember(_G,"PlayerFrame")
        local art=accessibleMember(frame,"PlayerFrameContainer")
        return accessibleMember(art,"PlayerPortrait") or accessibleMember(_G,"PlayerPortrait")
            or accessibleMember(_G,"PlayerFramePortrait"),accessibleMember(art,"PlayerPortraitMask"),frame
    elseif unit=="pet" then
        local frame=accessibleMember(_G,"PetFrame")
        return accessibleMember(_G,"PetPortrait") or accessibleMember(frame,"Portrait"),
            accessibleMember(frame,"PortraitMask") or accessibleMember(frame,"portraitMask"),frame
    elseif R.PARTY_UNITS[unit] then
        local frame=partyMember(tonumber(unit:match("^party([1-4])$")))
        return accessibleMember(frame,"Portrait"),accessibleMember(frame,"PortraitMask"),frame
    elseif unit=="target" or unit=="focus" then
        local name=unit=="target" and "Target" or "Focus"
        local frame=accessibleMember(_G,name.."Frame")
        local art=accessibleMember(frame,"TargetFrameContainer")
        return accessibleMember(art,"Portrait") or accessibleMember(_G,name.."FramePortrait")
            or accessibleMember(_G,name.."Portrait"),accessibleMember(art,"PortraitMask"),frame
    elseif R.SMALL_UNITS[unit] then
        local frame=smallFrame(unit)
        if not frame then return nil end
        local name=unit=="targettarget" and "TargetFrameToT" or "FocusFrameToT"
        return accessibleMember(frame,"Portrait") or accessibleMember(_G,name.."Portrait")
            or accessibleMember(_G,name.."PortraitTexture"),
            accessibleMember(frame,"PortraitMask") or accessibleMember(_G,name.."PortraitMask"),frame
    end
end

function R.GetPortrait(unit)
    local ok,portrait,mask,frame=pcall(resolvePortrait,unit)
    if ok then return portrait,mask,frame,true end
    return nil,nil,nil,false
end

-- Classic character-create sprite sheet: EIGHT columns, four gender/race rows.
-- Each face occupies 1/8 texture width. Using 1/4 incorrectly displayed two
-- adjacent faces within each ring (reported in the 0.1.133 screenshots).
-- Race portraits are an addon-owned FOUNDATION only, never an inferred aura.
local CLASSIC_RACE_TILE = {
    Human={0,0}, Dwarf={1,0}, Gnome={2,0}, NightElf={3,0},
    Tauren={0,1}, Scourge={1,1}, Undead={1,1}, Troll={2,1}, Orc={3,1},
    BloodElf={4,1},
}
local CLASSIC_RACE_TEXTURE = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Races"

-- The early Forever low-resolution raceicon-skyborne-* atlases may exist
-- while only containing a blank/blue gradient (observed in the live client).
-- Atlas existence alone is not proof of usable *face* artwork. Prefer the
-- higher-resolution raceicon128 artwork, if it is actually registered as a
-- square face-sized atlas. For the local player only, the game may supply its
-- own create-screen icon; accept that as a final option if face-sized. Otherwise
-- preserve the native 3D portrait. Never substitute Blood Elf artwork.
local function validatedSkyborneFaceAtlas(atlas, minPixels)
    if type(atlas) ~= "string" or atlas == "" or not R.CanAccess(atlas) then return nil end
    local getInfo = C_Texture and C_Texture.GetAtlasInfo or GetAtlasInfo
    if type(getInfo) ~= "function" then return nil end
    local ok, info = pcall(getInfo, atlas)
    if not ok or not R.CanAccess(info) or type(info) ~= "table" then return nil end
    local fieldsOK, width, height = pcall(function() return info.width, info.height end)
    if not fieldsOK or not R.CanAccess(width) or not R.CanAccess(height)
        or type(width) ~= "number" or type(height) ~= "number"
        or width ~= width or height ~= height or width < minPixels or height < minPixels
        or width > 1024 or height > 1024
        or width > height * 1.1 or height > width * 1.1 then
        return nil
    end
    return atlas
end

local function skyborneRaceAtlas(unit, sex)
    local sexName = sex == 2 and "male" or "female"
    -- The 128px atlas has a different name from the scuffed low-resolution
    -- raceicon-skyborne-* asset, which is intentionally not considered here.
    -- TODO: recheck official Skyborne SD face portraits when Blizzard ships them.
    local atlas = validatedSkyborneFaceAtlas("raceicon128-skyborne-" .. sexName, 64)
    if atlas then return atlas end

    if unit == "player" and C_PlayerInfo and type(C_PlayerInfo.GetPlayerCharacterData) == "function" then
        local ok, data = pcall(C_PlayerInfo.GetPlayerCharacterData)
        if ok and R.CanAccess(data) and type(data) == "table" then
            local got, art = pcall(function() return data.createScreenIconAtlas end)
            if got and R.CanAccess(art) and type(art) == "string"
                and not art:match("^raceicon%-skyborne%-") then
                return validatedSkyborneFaceAtlas(art, 48)
            end
        end
    end
    return nil
end
function R.ResolveRaceBaselineAtlas(unit, confirmedPlayer)
    if confirmedPlayer ~= true then return nil, "not-player" end
    if type(UnitRace) ~= "function" or type(UnitSex) ~= "function" then
        return nil, "race-api-unavailable"
    end
    local ok, _, race = pcall(UnitRace, unit)
    if not ok or not R.CanAccess(race) or type(race) ~= "string" then
        return nil, "race-unavailable"
    end
    local tile=CLASSIC_RACE_TILE[race]
    if not tile and race ~= "Skyborne" then return nil, "no-classic-art" end
    local sexOK, sex=pcall(UnitSex, unit)
    if not sexOK or not R.CanAccess(sex) or (sex ~= 2 and sex ~= 3) then
        return nil, "sex-unavailable"
    end
    if race == "Skyborne" then
        local atlas=skyborneRaceAtlas(unit, sex)
        if not atlas then return nil, "skyborne-face-atlas-unavailable" end
        return atlas, nil, true
    end
    local row=tile[2]+(sex==3 and 2 or 0)
    return CLASSIC_RACE_TEXTURE, {tile[1]/8,(tile[1]+1)/8,row/4,(row+1)/4}
end

-- Some classic spell icons contain thin square edges baked into their
-- 64x64 artwork. A circle mask clips shape, not source-image border pixels.
-- Symmetric 2px inset trims those edges with no change to our masks,
-- native frame coordinates or original Blizzard icon artwork.
R.AURA_ART_EDGE_INSET = 2 / 64
function R.ApplyPortraitIconCrop(icon, host)
    if not icon or type(icon.SetTexCoord) ~= "function" then return false end
    -- The previously calibrated small local PetFrame keeps its 3px crop.
    local inset = host and host.unit == "pet"
        and 3 / 64 or R.AURA_ART_EDGE_INSET
    return pcall(icon.SetTexCoord, icon, inset, 1-inset, inset, 1-inset)
end

-- Use the same mild source trim for real secondary spell/form artwork
-- and confirmed pet-family images, including the secure native receiver.
-- NEVER call this for race sprite sheets or registered race atlases:
-- they already have exact tile/atlas texture coordinates.
function R.ApplySecondaryIconCrop(icon)
    if not icon or type(icon.SetTexCoord) ~= "function" then return false end
    local inset = R.AURA_ART_EDGE_INSET
    return pcall(icon.SetTexCoord, icon, inset, 1-inset, inset, 1-inset)
end

-- Physical-pixel source-image offsets: .119 Wisdom calibration, then the
-- approved .120 horizontal finishing pass. Y offsets and crop stay fixed.
-- These adjust the image, NOT the circular opening or native frame artwork.
-- Quarter-pixel values limit the correction to what the raster supports.
local portraitImageOffsets = {
    player = { -1, -1.25 },
    -- PetFrame is a 37px compact version of the Target portrait. Match
    -- its source-to-circle offset proportionally; the native mask/ring
    -- remain stationary and every pet family uses the same adjustment.
    pet = { -0.6, -0.6 },
    -- Party portraits use the same native 37x37 circular opening as PetFrame.
    party1 = { -0.6, -0.6 }, party2 = { -0.6, -0.6 },
    party3 = { -0.6, -0.6 }, party4 = { -0.6, -0.6 },
    target = { 2, -1 },
    focus = { 2, -1 },
    targettarget = { -0.75, 1 },
    focustarget = { -1.25, 1 },
}

local function portraitLayoutOffset(region, unit, aperture)
    local x, y = 0, 0
    if aperture then
        -- Keep the accepted .118 clipping circles stationary inside the rings.
        -- Translating a source image does not authorize translating its clip.
        if unit == "target" or unit == "focus" then x = 3
        elseif R.SMALL_UNITS[unit] then y = 2 end
    else
        local offset = portraitImageOffsets[unit]
        if offset then x, y = offset[1], offset[2] end
    end
    if x == 0 and y == 0 then return 0, 0 end
    if not PixelUtil or type(PixelUtil.GetPixelToUIUnitFactor) ~= "function"
        or type(region.GetEffectiveScale) ~= "function" then return 0, 0 end
    local factorOK, factor = pcall(PixelUtil.GetPixelToUIUnitFactor)
    local scaleOK, scale = pcall(region.GetEffectiveScale, region)
    if not factorOK or not scaleOK or not R.CanAccess(factor) or not R.CanAccess(scale)
        or type(factor) ~= "number" or type(scale) ~= "number"
        or factor ~= factor or scale ~= scale or factor <= 0 or scale <= 0
        or factor == math.huge or scale == math.huge then return 0, 0 end
    return x * factor / scale, y * factor / scale
end

local function applyPortraitLayout(region, host, aperture)
    local reference = ((host.unit == "target" or host.unit == "focus")
        and host.portraitMask) or host.portrait
    local dx, dy = portraitLayoutOffset(region, host.unit, aperture)
    local cleared=region:ClearAllPoints()
    if not R.CanAccess(cleared) or cleared==false then return false end
    if dx == 0 and dy == 0 then
        return region:SetAllPoints(reference)
    else
        local first=region:SetPoint("TOPLEFT", reference, "TOPLEFT", dx, dy)
        if not R.CanAccess(first) or first==false then return false end
        return region:SetPoint("BOTTOMRIGHT", reference, "BOTTOMRIGHT", dx, dy)
    end
end

function R.ApplyPortraitImageLayout(region, host)
    return applyPortraitLayout(region, host, false)
end

function R.CreatePortraitImageMask(host)
    -- Native masks are never edited. Only the owned apertures
    -- are reused by aura/test/helper/pet textures; no extra per-tier masks.
    local moved = host.unit == "target" or host.unit == "focus"
        or host.unit == "pet" or R.SMALL_UNITS[host.unit] or R.PARTY_UNITS[host.unit]
    if not moved or not host.portraitMask or not host.layer
        or type(host.layer.CreateMaskTexture) ~= "function" then
        host.imageMask = host.portraitMask
        host.imageClipKind = "native"
        return
    end
    host._buildStage = "image-mask"
    local mask = host.layer:CreateMaskTexture(nil, "BACKGROUND")
    mask:SetAtlas("CircleMask", false)
    applyPortraitLayout(mask, host, true)
    host.imageMask = mask
    host.imageClipKind = "owned"
end

function R.CapturePoints(region)
    local points = {}
    if not region or type(region.GetNumPoints)~="function" or type(region.GetPoint)~="function" then return nil end
    local count = region:GetNumPoints()
    if not R.CanAccess(count) or type(count)~="number" or count<0 or count>32 or count%1~=0 then return nil end
    for i = 1, count do
        local point={region:GetPoint(i)}
        for j=1,5 do if not R.CanAccess(point[j]) then return nil end end
        if type(point[1])~="string" or type(point[3])~="string"
            or type(point[4])~="number" or type(point[5])~="number" then return nil end
        if point[2]~=nil and type(point[2])~="table" and type(point[2])~="userdata" then return nil end
        if point[4]~=point[4] or point[5]~=point[5]
            or math.abs(point[4])==math.huge or math.abs(point[5])==math.huge then return nil end
        points[i]=point
    end
    return points
end

function R.RestorePoints(region, points, progress, restored)
    if not region or not region.ClearAllPoints or not region.SetPoint then return false end
    points=points or {}
    if not restored then
        if progress then progress.point=nil end
        local result=region:ClearAllPoints()
        if not R.CanAccess(result) or result==false then return false end
    end
    for i=(restored or 0)+1,#points do
        if progress then progress.point=i end
        local result=region:SetPoint(unpack(points[i],1,5))
        if not R.CanAccess(result) or result==false then return false end
    end
    return true
end

local neverSecret = {}
function R.AuraIsNeverSecret(spellID)
    if neverSecret[spellID] ~= nil then return neverSecret[spellID] end
    if not C_Secrets or not C_Secrets.GetSpellAuraSecrecy
        or not Enum or not Enum.SecrecyLevel
    then
        return false
    end

    local ok, secrecy = pcall(C_Secrets.GetSpellAuraSecrecy, spellID)
    if not ok or not R.CanAccess(secrecy) or secrecy == nil then
        -- UNKNOWN fails closed for this check, but remains eligible for a later
        -- correction if the API becomes readable. Do not cache UNKNOWN as false.
        return false
    end

    local result = secrecy == Enum.SecrecyLevel.NeverSecret
    neverSecret[spellID] = result
    return result
end

function R.SetIsNeverSecret(spellIDs)
    local any = false
    for spellID in pairs(spellIDs or {}) do
        any = true
        if not R.AuraIsNeverSecret(spellID) then return false end
    end
    return any
end

function R.ExactFilterAllowed(unit, helpful, spellIDs, allowNeverSecret)
    local exists, existsReadable = R.UnitExistsState(unit)
    if not existsReadable or not exists then return false end

    if allowNeverSecret and R.SetIsNeverSecret(spellIDs) then return true end

    -- Our own helpful auras are always on the permitted side of the relation
    -- boundary. Keep this explicit rather than depending on a broader helper.
    if helpful and unit == "player" then return true end

    if helpful and UnitIsPlayerControlledOrGroupMember then
        local controlled, readable = R.SafeBool(UnitIsPlayerControlledOrGroupMember, unit)
        if readable and controlled then return true end
    end

    local assist, readable = R.SafeBool(UnitCanAssist, "player", unit, true, true)
    if not readable then return false end

    -- Do NOT use `helpful and assist or not assist` here. For helpful=true and
    -- assist=false that Lua idiom falls through to `not assist` and returns true,
    -- incorrectly authorizing exact helpful-ID filters on hostile players.
    if helpful then return assist end
    return not assist
end

-- Scheduling a native exact container is weaker than proving that its entire
-- candidate set is readable. Blizzard checks identity permission per aura and
-- rejects forbidden candidates when an includeSpellIDs map is present.
function R.NativeExactContainerAllowed(unit, tier)
    if not tier then return false end
    if R.ExactFilterAllowed(unit, tier.helpful, tier.spellIDs, tier.allowNeverSecret) then
        return true
    end
    if not tier.allowNeverSecret then return false end
    local exists, readable = R.UnitExistsState(unit)
    if not readable or not exists then return false end
    for spellID in pairs(tier.spellIDs or {}) do
        if R.AuraIsNeverSecret(spellID) then return true end
    end
    return false
end

function R.PlayerUnitState(unit)
    if not unit then return nil, false end

    local player, readable = R.SafeBool(UnitIsPlayer, unit)
    if readable then return player, true end

    -- Forever can protect UnitIsPlayer while leaving the GUID type readable.
    -- A readable non-player GUID is positive evidence of "not a player"; an
    -- inaccessible/missing GUID is UNKNOWN and must not be collapsed to false.
    if UnitGUID then
        local ok, guid = pcall(UnitGUID, unit)
        if ok and R.CanAccess(guid) and type(guid) == "string" then
            return guid:match("^Player%-") ~= nil, true
        end
    end

    -- UnitPlayerControlled is deliberately not an identity fallback: pets and
    -- other controlled units can satisfy it without being players. If neither
    -- UnitIsPlayer nor GUID type is readable, player identity is UNKNOWN.
    return nil, false
end

function R.HostileUnitState(unit)
    local exists, existsReadable = R.UnitExistsState(unit)
    if not existsReadable or not exists then return nil, false end

    local assist, assistReadable = R.SafeBool(UnitCanAssist, "player", unit, true, true)
    if assistReadable then return not assist, true end

    local attack, attackReadable = R.SafeBool(UnitCanAttack, "player", unit)
    if attackReadable then return attack, true end

    return nil, false
end

-- Compatibility helper for call sites that only need a positive witness.
-- UNKNOWN deliberately collapses to false here; use HostileUnitState when the
-- distinction itself matters.
function R.IsHostileUnit(unit)
    local hostile, readable = R.HostileUnitState(unit)
    return readable and hostile or false
end

function R.ReadAuraField(aura, key)
    -- Check accessibility before any comparison/index operation on aura.
    if not R.CanAccess(aura) then return nil, false end
    if aura == nil then return nil, false end
    local ok, value = pcall(function() return aura[key] end)
    if not ok or not R.CanAccess(value) then return nil, false end
    return value, true
end

-- 60 seconds remain visible; only values ABOVE 60 hide the digits.
-- At 60, next representable double is 2^-47 away, not 2^-48
-- (the latter rounds back to exactly 60 under IEEE-754 ties-to-even).
-- Binary32's adjacent step at 60 is 2^-18, not the 30s step 2^-19.
R.PORTRAIT_TIMER_LIMIT=60
local nextDouble=R.PORTRAIT_TIMER_LIMIT+2^-47
local nextFloat=R.PORTRAIT_TIMER_LIMIT+2^-18
R.PORTRAIT_TIMER_HIDE_AT=nextDouble

local function buildCountdownFormatter(key)
    local rounding=Enum and Enum.NumericRuleFormatRounding
    local down=rounding and rounding.Down
    if not R.CanAccess(down) or type(down)~="number" then return nil end
    if not C_StringUtil or type(C_StringUtil.CreateNumericRuleFormatter)~="function" then return nil end
    local formatter = C_StringUtil.CreateNumericRuleFormatter()
    if not R.CanAccess(formatter) or not formatter or type(formatter.SetBreakpoints)~="function"
        or type(formatter.FormatNumber)~="function" then return nil end

    -- Match native aura whole seconds by truncating, not rounding to nearest.
    local cutoff={threshold=nextDouble,format=""}
    local whole={threshold=key==1 and 10 or 0,step=1,rounding=down,format="%.0f"}
    local rules=key==1 and {{threshold=0,format="%.1f"},whole,cutoff} or {whole,cutoff}
    local accepted=formatter:SetBreakpoints(rules)
    if not R.CanAccess(accepted) or accepted==false then return nil end
    -- Sample public constants. Native inputs or thresholds can be single precision.
    local function renders(value,expected)
        local text=formatter:FormatNumber(value)
        return R.CanAccess(text) and text==expected
    end
    if not renders(R.PORTRAIT_TIMER_LIMIT,tostring(R.PORTRAIT_TIMER_LIMIT))
        or not renders(nextDouble,"") then
        cutoff.threshold=nextFloat
        accepted=formatter:SetBreakpoints(rules)
        if not R.CanAccess(accepted) or accepted==false then return nil end
    end
    if not renders(R.PORTRAIT_TIMER_LIMIT,tostring(R.PORTRAIT_TIMER_LIMIT))
        or not renders(cutoff.threshold,"") or not renders(2880,"") then return nil end
    R.PORTRAIT_TIMER_HIDE_AT=cutoff.threshold
    return formatter
end

local failedFormatterKey
R.countdownFormatterEpoch=0
function R.RetryCountdownFormatter()
    failedFormatterKey=nil
    R.countdownFormatterEpoch=R.countdownFormatterEpoch+1
end

function R.GetCountdownFormatter()
    local key=R.db and R.db.showDecimals and 1 or 0
    if R._formatter and R._formatterKey==key then return R._formatter end
    if failedFormatterKey==key then return nil end
    local ok,formatter=pcall(buildCountdownFormatter,key)
    if not ok or not R.CanAccess(formatter) or not formatter then
        failedFormatterKey=key -- share the failure across this round of native button creation
        return nil
    end
    failedFormatterKey=nil
    R._formatter, R._formatterKey = formatter, key
    return formatter
end

-- Forever's Blizzard AuraButtonArtTemplate.Duration inherits
-- GameFontNormalSmall. Use THAT FontObject to match ordinary buff
-- countdown size, not a guessed number or a different default font.
-- The badge owns its countdown label: center it over the icon and keep
-- its ink neutral white, including on safe out-of-combat reuse.
function R.ApplySecondaryCountdownFont(cooldown, styleOnly, verify)
    if not cooldown or type(cooldown.GetCountdownFontString) ~= "function" then
        return false
    end
    local auraFont = GameFontNormalSmall or DEFAULT_AURA_DURATION_FONT
    if not auraFont or not R.CanAccess(auraFont) then return false end
    local combat, known = R.SafeBool(InCombatLockdown)
    if not known or combat then return false end
    local ok, label = pcall(cooldown.GetCountdownFontString, cooldown)
    if not ok or not R.CanAccess(label) or not label
        or type(label.SetFontObject) ~= "function"
        or type(label.ClearAllPoints) ~= "function"
        or type(label.SetPoint) ~= "function"
        or type(label.SetTextColor) ~= "function" then
        return false
    end
    local same=cooldown._bjarkiSecondaryFontLabel==label and cooldown._bjarkiSecondaryFontObject==auraFont
    if same and verify then
        local found,font=pcall(label.GetFontObject,label)
        same=found and R.CanAccess(font) and font==auraFont
    end
    if same and styleOnly then return true,label end
    if not same then
        local wrote,result=pcall(label.SetFontObject,label,auraFont)
        if not wrote or not R.CanAccess(result) or result==false then return false end
    end
    -- A native cooldown may reposition its FontString after the first aura.
    -- Reassert label layout when safely revisited without reading its text.
    local centered = pcall(function()
        label:ClearAllPoints()
        label:SetPoint("CENTER", cooldown, "CENTER", 0, 0)
        if label.SetJustifyH then label:SetJustifyH("CENTER") end
        if label.SetJustifyV then label:SetJustifyV("MIDDLE") end
        label:SetTextColor(1, 1, 1, 1)
    end)
    if not centered then return false end
    cooldown._bjarkiSecondaryFontLabel = label
    cooldown._bjarkiSecondaryFontObject = auraFont
    return true,label
end

local formatterProbes={1.1,11,30,59.99,60,nextFloat,61,2880}
local function sameCountdownFormatter(active,wanted)
    if rawequal(active,wanted) then return true end
    local activeMethod=R.ReadAuraField(active,"FormatNumber")
    local wantedMethod=R.ReadAuraField(wanted,"FormatNumber")
    if type(activeMethod)~="function" or type(wantedMethod)~="function" then return false end
    -- Some getters expose a separate Lua handle. Compare its public output,
    -- including long durations, without inspecting the widget's current time.
    for _,value in ipairs(formatterProbes) do
        local got,a=pcall(activeMethod,active,value)
        local expected,b=pcall(wantedMethod,wanted,value)
        if not got or not expected or not R.CanAccess(a) or not R.CanAccess(b)
            or type(a)~="string" or a~=b or (value>R.PORTRAIT_TIMER_LIMIT and a~="") then return false end
    end
    return true
end

local function showCountdown(cooldown,shown)
    if cooldown._bjarkiTimerNumbersShown==shown then return true end
    if type(cooldown.SetHideCountdownNumbers)~="function" then return shown and cooldown._bjarkiTimerNumbersShown~=false end
    local ok,result=pcall(cooldown.SetHideCountdownNumbers,cooldown,not shown)
    if not ok or not R.CanAccess(result) or result==false then return false end
    if type(cooldown.GetHideCountdownNumbers)=="function" then
        local read,hidden=pcall(cooldown.GetHideCountdownNumbers,cooldown)
        if read and R.CanAccess(hidden) and type(hidden)=="boolean" and hidden==shown then return false end
    end
    cooldown._bjarkiTimerNumbersShown=shown
    return true
end

local function installCountdownFormatter(cooldown,formatter,decimals,backend)
    if not formatter or not cooldown.SetCountdownFormatter then return false end
    if not cooldown._bjarkiTimerReinstall and rawequal(cooldown._bjarkiTimerFormatter,formatter)
        and cooldown._bjarkiTimerDecimals==decimals then
        cooldown._bjarkiTimerBackend=backend
        return showCountdown(cooldown,true)
    end
    local ok,result=pcall(cooldown.SetCountdownFormatter,cooldown,formatter)
    local read,active
    if type(cooldown.GetCountdownFormatter)=="function" then read,active=pcall(cooldown.GetCountdownFormatter,cooldown) end
    local observed=read and R.CanAccess(active)
    if not ok or not R.CanAccess(result) or result==false or (observed and not sameCountdownFormatter(active,formatter)) then
        if observed then cooldown._bjarkiTimerFormatter=active end
        cooldown._bjarkiTimerReinstall=true
        return false
    end
    cooldown._bjarkiTimerFormatter,cooldown._bjarkiTimerDecimals,cooldown._bjarkiTimerBackend=formatter,decimals,backend
    cooldown._bjarkiTimerReinstall=nil
    return showCountdown(cooldown,true)
end

-- Prepare fixed-position cells from the final native label style. Native aura
-- clocks arrive through their duration-bar bridge; public projection setters
-- feed the same cells. Fall back only after the cell owner has disabled them.
function R.ApplyCountdownFormat(cooldown,label,verify)
    local decimals=R.db and R.db.showDecimals==true or false
    -- A native second ribbon preallocates ten buttons per tier, even when
    -- hidden. Its 6-cell / 0.1s binding would run thousands of times.
    -- Native second buttons use Blizzard's own CAPPED formatter instead.
    -- Preserve fixed glyphs on primary and publicly rendered secondary art.
    if not cooldown._bjarkiLightNativeSecond
        and R.ApplyPortraitTimer and R.ApplyPortraitTimer(cooldown,label,verify) then
        cooldown._bjarkiTimerBackend="cells"
        cooldown._bjarkiTimerDecimals=decimals
        cooldown._bjarkiTimerSpacingReason="fixed-cells"
        return true,"cells"
    end
    if verify then
        if type(cooldown.GetHideCountdownNumbers)=="function" then
            local ok,hidden=pcall(cooldown.GetHideCountdownNumbers,cooldown)
            cooldown._bjarkiTimerNumbersShown=nil
            if ok and R.CanAccess(hidden) and type(hidden)=="boolean" then cooldown._bjarkiTimerNumbersShown=not hidden end
        end
        local found,active=pcall(cooldown.GetCountdownFormatter,cooldown)
        cooldown._bjarkiTimerReinstall=not (found and R.CanAccess(active) and sameCountdownFormatter(active,cooldown._bjarkiTimerFormatter)) or nil
    end
    local formatter = R.GetCountdownFormatter()
    if installCountdownFormatter(cooldown,formatter,decimals,"formatter") then return true,"formatter" end

    -- The stock countdown has no upper time limit. Hide only its numbers until
    -- a capped rule can be installed. The icon and swipe retain their native clock.
    cooldown._bjarkiTimerFormatter=nil
    cooldown._bjarkiTimerBackend="hidden"
    cooldown._bjarkiTimerDecimals=decimals
    return showCountdown(cooldown,false),"hidden"
end

function R.ApplySecondaryCountdownPresentation(cooldown,verify,styleOnly)
    local styled,label=R.ApplySecondaryCountdownFont(cooldown,styleOnly,verify)
    if not styled and R.ApplyPortraitTimer then
        local combat,known=R.SafeBool(InCombatLockdown)
        if known and not combat then label=false end
    end
    return R.ApplyCountdownFormat(cooldown,label,verify)
end
