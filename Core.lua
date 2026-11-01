local addonName, BP = ...
BP.Runtime = BP.Runtime or {}
local R = BP.Runtime

R.VERSION = "0.1.160-class-aura-fixes-test"
R.PREFIX = "|cff74c7ecbjarkiPortraits|r"
R.TRACKED_UNITS = { "player", "target", "focus", "targettarget", "focustarget" }
R.SMALL_UNITS = { targettarget = true, focustarget = true }
R.hosts = {}
R.testMode = false
R.buildQueued = false
R.forceRebuildQueued = false
R.AURA_ANCHOR_TEMPLATE = "DisableUntrustedLayoutScriptsTemplate"
R.SORT_METHOD = AuraContainerSortMethod and AuraContainerSortMethod.AuraInstanceIDOnly
R.SORT_DIRECTION = AuraContainerSortDirection and AuraContainerSortDirection.Reverse
R.SWIPE_TEXTURE = "Interface\\CHARACTERFRAME\\TempPortraitAlphaMask"

local defaults = {
    enabled = true,
    player = true,
    target = true,
    focus = true,
    targettarget = true,
    focustarget = true,
    showSwipe = false,
    showDecimals = true,
    petPortraits = true,
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

function R.GetSmallFrame(unit)
    if unit == "targettarget" then
        return (_G.TargetFrame and _G.TargetFrame.totFrame) or _G.TargetFrameToT
    elseif unit == "focustarget" then
        return (_G.FocusFrame and _G.FocusFrame.totFrame) or _G.FocusFrameToT
    end
end

function R.GetPortrait(unit)
    if unit == "player" then
        local frame = _G.PlayerFrame
        local container = frame and frame.PlayerFrameContainer
        return (container and container.PlayerPortrait) or _G.PlayerPortrait or _G.PlayerFramePortrait,
            (container and container.PlayerPortraitMask), frame
    elseif unit == "target" then
        local frame = _G.TargetFrame
        local container = frame and frame.TargetFrameContainer
        return (container and container.Portrait) or _G.TargetFramePortrait or _G.TargetPortrait,
            (container and container.PortraitMask), frame
    elseif unit == "focus" then
        local frame = _G.FocusFrame
        local container = frame and frame.TargetFrameContainer
        return (container and container.Portrait) or _G.FocusFramePortrait or _G.FocusPortrait,
            (container and container.PortraitMask), frame
    elseif R.SMALL_UNITS[unit] then
        local frame = R.GetSmallFrame(unit)
        if not frame then return nil, nil, nil end
        local portrait = frame.Portrait
            or (unit == "targettarget" and (_G.TargetFrameToTPortrait or _G.TargetFrameToTPortraitTexture))
            or (unit == "focustarget" and (_G.FocusFrameToTPortrait or _G.FocusFrameToTPortraitTexture))
        local mask = frame.PortraitMask
            or (unit == "targettarget" and _G.TargetFrameToTPortraitMask)
            or (unit == "focustarget" and _G.FocusFrameToTPortraitMask)
        return portrait, mask, frame
    end
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

-- Forever ships native Skyborne race icons. Never substitute Blood Elf for
-- Skyborne. The raceicon naming matches the client character-creation atlas
-- convention; where the local player exposes its authoritative atlas, prefer
-- that. If an atlas is not available, leave Blizzard's portrait visible.
local function validatedRaceAtlas(atlas)
    if type(atlas) ~= "string" or atlas == "" or not R.CanAccess(atlas) then return nil end
    local getInfo = C_Texture and C_Texture.GetAtlasInfo or GetAtlasInfo
    if type(getInfo) ~= "function" then return nil end
    local ok, info = pcall(getInfo, atlas)
    if ok and R.CanAccess(info) and type(info) == "table" then return atlas end
    return nil
end

local function skyborneRaceAtlas(unit, sex)
    if unit == "player" and C_PlayerInfo and type(C_PlayerInfo.GetPlayerCharacterData) == "function" then
        local ok, data = pcall(C_PlayerInfo.GetPlayerCharacterData)
        if ok and R.CanAccess(data) and type(data) == "table" then
            local got, art = pcall(function() return data.createScreenIconAtlas end)
            if got then
                local verified = validatedRaceAtlas(art)
                if verified then return verified end
            end
        end
    end
    return validatedRaceAtlas("raceicon-skyborne-" .. (sex == 2 and "male" or "female"))
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
        if not atlas then return nil, "skyborne-atlas-unavailable" end
        return atlas, nil, true
    end
    local row=tile[2]+(sex==3 and 2 or 0)
    return CLASSIC_RACE_TEXTURE, {tile[1]/8,(tile[1]+1)/8,row/4,(row+1)/4}
end

-- The Wisdom fixture separates source-art centering from the native aperture.
-- Player's source ring was slightly larger relative to its bezel; halving its
-- old 1/64 trim matches the other apertures without adding zoom anywhere.
function R.ApplyPortraitIconCrop(icon, host)
    if icon.SetTexCoord then
        local inset = host and host.unit == "player" and 1 / 128 or 1 / 64
        pcall(icon.SetTexCoord, icon, inset, 1 - inset, inset, 1 - inset)
    end
end

-- Physical-pixel source-image offsets: .119 Wisdom calibration, then the
-- approved .120 horizontal finishing pass. Y offsets and crop stay fixed.
-- These adjust the image, NOT the circular opening or native frame artwork.
-- Quarter-pixel values limit the correction to what the raster supports.
local portraitImageOffsets = {
    player = { -1, -1.25 },
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
    region:ClearAllPoints()
    if dx == 0 and dy == 0 then
        region:SetAllPoints(reference)
    else
        region:SetPoint("TOPLEFT", reference, "TOPLEFT", dx, dy)
        region:SetPoint("BOTTOMRIGHT", reference, "BOTTOMRIGHT", dx, dy)
    end
end

function R.ApplyPortraitImageLayout(region, host)
    applyPortraitLayout(region, host, false)
end

function R.CreatePortraitImageMask(host)
    -- Native masks are never edited. Only the four existing owned apertures
    -- are reused by aura/test/helper/pet textures; no extra per-tier masks.
    local moved = host.unit == "target" or host.unit == "focus" or R.SMALL_UNITS[host.unit]
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
    if not region or not region.GetNumPoints or not region.GetPoint then return points end
    local count = region:GetNumPoints() or 0
    for i = 1, count do points[#points + 1] = { region:GetPoint(i) } end
    return points
end

function R.RestorePoints(region, points)
    if not region or not region.ClearAllPoints or not region.SetPoint then return end
    region:ClearAllPoints()
    for _, point in ipairs(points or {}) do region:SetPoint(unpack(point)) end
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

function R.GetCountdownFormatter()
    local key = R.db and R.db.showDecimals and 1 or 0
    if R._formatter and R._formatterKey == key then return R._formatter end
    if not C_StringUtil or not C_StringUtil.CreateNumericRuleFormatter then return nil end
    local formatter = C_StringUtil.CreateNumericRuleFormatter()
    if not formatter or not formatter.SetBreakpoints then return nil end

    -- Match native aura whole seconds by truncating, not rounding to nearest.
    -- Show decimals strictly below 10 seconds; preserve the native whole-second
    -- rounding and 60-second hide boundary.
    if key == 1 then
        formatter:SetBreakpoints({
            { threshold = 0, format = "%.1f" },
            { threshold = 10, step = 1, rounding = Enum.NumericRuleFormatRounding.Down, format = "%.0f" },
            { threshold = 60.000001, format = "" },
        })
    else
        formatter:SetBreakpoints({
            { threshold = 0, step = 1, rounding = Enum.NumericRuleFormatRounding.Down, format = "%.0f" },
            { threshold = 60.000001, format = "" },
        })
    end

    R._formatter, R._formatterKey = formatter, key
    return formatter
end

function R.ApplyCountdownFormat(cooldown)
    if cooldown.SetHideCountdownNumbers then
        pcall(cooldown.SetHideCountdownNumbers, cooldown, false)
    end

    local formatter = R.GetCountdownFormatter()
    local applied = false
    if formatter and cooldown.SetCountdownFormatter then
        applied = pcall(cooldown.SetCountdownFormatter, cooldown, formatter)
    end

    -- Compatibility fallback: if this client does not accept the formatter,
    -- retain the user's decimal preference through the native millisecond
    -- threshold. The 60s cutoff is guaranteed by the formatter path.
    if not applied and cooldown.SetCountdownMillisecondsThreshold then
        pcall(
            cooldown.SetCountdownMillisecondsThreshold,
            cooldown,
            R.db and R.db.showDecimals and 10 or 0
        )
    end
end
