local addonName, BP = ...
BP.Runtime = BP.Runtime or {}
local R = BP.Runtime

R.VERSION = "0.1.38-clean"
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
    return ok and secret == true
end

function R.CanAccess(value)
    if R.IsSecret(value) then return false end
    if canaccessvalue then
        local ok, accessible = pcall(canaccessvalue, value)
        if ok and not R.IsSecret(accessible) and accessible == false then return false end
    end
    return true
end

function R.SafeBool(fn, ...)
    if type(fn) ~= "function" then return nil, false end
    local ok, value = pcall(fn, ...)
    if not ok or R.IsSecret(value) or type(value) ~= "boolean" then return nil, false end
    return value, true
end

function R.SafeString(fn, ...)
    if type(fn) ~= "function" then return nil, false end
    local ok, value = pcall(fn, ...)
    if not ok or R.IsSecret(value) or type(value) ~= "string" then return nil, false end
    return value, true
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
    if not unit or (UnitExists and not UnitExists(unit)) then return false end

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

function R.IsPlayerUnit(unit)
    local player, readable = R.PlayerUnitState(unit)
    return readable and player or false
end

function R.IsHostileUnit(unit)
    if not unit or (UnitExists and not UnitExists(unit)) then return false end

    local assist, assistReadable = R.SafeBool(UnitCanAssist, "player", unit, true, true)
    if assistReadable then return not assist end

    local attack, attackReadable = R.SafeBool(UnitCanAttack, "player", unit)
    return attackReadable and attack or false
end

function R.IsHostilePlayer(unit)
    return R.IsPlayerUnit(unit) and R.IsHostileUnit(unit)
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
    if key == 1 then
        formatter:SetBreakpoints({
            { threshold = 0, format = "%.1f" },
            { threshold = 10, format = "%.0f" },
            { threshold = 45.000001, format = "" },
        })
    else
        formatter:SetBreakpoints({
            { threshold = 0, format = "%.0f" },
            { threshold = 45.000001, format = "" },
        })
    end
    R._formatter, R._formatterKey = formatter, key
    return formatter
end
