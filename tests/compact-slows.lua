-- Exercise the production compact portrait constructor with Frostbolt and Renew.
-- The offline frame model records which icon, level, and timer the addon presents.
unpack = unpack or table.unpack
local friendly, combat = true, false
local frostbolt = {spellId=116, auraInstanceID=1, icon=101, duration=8, expirationTime=108}
local renew = {spellId=139, auraInstanceID=2, icon=102, duration=15, expirationTime=115}
local harmful = {frostbolt}
AuraContainerSortMethod = {AuraInstanceIDOnly=1}
AuraContainerSortDirection = {Reverse=1}
Enum = {SecrecyLevel={NeverSecret=0}}
C_Secrets = {GetSpellAuraSecrecy=function() return 1 end}
GetTime = function() return 100 end
InCombatLockdown = function() return combat end
UnitExists = function() return true end
UnitIsPlayer = function() return true end
UnitCanAssist = function() return friendly end
C_UnitAuras = {
    GetAuraDataByIndex=function(_, index, filter)
        if filter:find('HARMFUL', 1, true) then return harmful[index] end
        if index == 1 then return renew end
    end,
}

local region = {}
region.__index = region
local function newRegion(parent)
    return setmetatable({parent=parent, points={}, shown=true}, region)
end
function region:GetParent() return self.parent end
function region:SetParent(parent) self.parent = parent end
function region:GetNumPoints() return #self.points end
function region:GetPoint(index) return unpack(self.points[index]) end
function region:ClearAllPoints() self.points = {} end
function region:SetPoint(...) self.points[#self.points+1] = {...} end
function region:SetAllPoints(other)
    self.points = {{'TOPLEFT', other, 'TOPLEFT', 0, 0}, {'BOTTOMRIGHT', other, 'BOTTOMRIGHT', 0, 0}}
end
function region:Show() self.shown = true end
function region:Hide() self.shown = false end
function region:SetShown(shown) self.shown = shown end
function region:SetEnabled(enabled) self.enabled = enabled end
function region:SetFrameLevel(level) self.level = level end
function region:SetTexture(texture) self.texture = texture; return true end
function region:CreateTexture() return newRegion(self) end
function region:SetCooldown(_, duration) self.duration = duration end
function region:Clear() self.duration = nil end
function region:SetFrameStrata() end
function region:SetTexCoord() end
function region:SetUnit() end
function region:AddAuraSlot() end
CreateFrame = function(_, _, parent) return newRegion(parent) end

local function compactUnitFrame(unit)
    local parent = newRegion()
    local portrait = newRegion(parent)
    portrait:SetAllPoints(parent)
    return {unit=unit, Portrait=portrait}
end
TargetFrameToT = compactUnitFrame('targettarget')
FocusFrameToT = compactUnitFrame('focustarget')
local BP = {}
for _, file in ipairs({'Spells', 'Core', 'Priority', 'AuraEngine'}) do
    assert(loadfile(file .. '.lua'))('bjarkiPortraits', BP)
end
local R = BP.Runtime
R.ApplyDefaults()

local function nativeContainer(host, key)
    for i, tier in ipairs(R.TIERS) do
        if tier.key == key then return host.containers[i] end
    end
    error('missing native tier ' .. key)
end

for _, unit in ipairs({'targettarget', 'focustarget'}) do
    friendly, harmful = true, {frostbolt}
    local host = assert(R.CreateHost(unit), unit .. ' host construction failed')
    local native = nativeContainer(host, 'Slows')
    R.UpdateHost(host)
    assert(not native.enabled, unit .. ' native slow ID filter must be unavailable on this friendly unit')
    local healing = host.readableHealingFrame
    assert(healing.shown and healing.icon.texture == renew.icon, unit .. ' should present concurrently active Renew')
    local slow = host.readableSlowsFrame
    assert(slow and slow.shown and slow.icon.texture == frostbolt.icon and slow.level > healing.level,
        unit .. ' should present readable Frostbolt above Renew')
    assert(slow.cooldown.duration == 8, unit .. ' should present Frostbolt duration')

    combat = true
    harmful = {}
    R.UpdateHost(host)
    assert(not slow.shown and slow.cooldown.duration == nil and healing.shown, unit .. ' combat removal left a stale slow')
    harmful = {frostbolt, {auraInstanceID=3}} -- incomplete harmful identity stream
    R.UpdateHost(host)
    assert(not slow.shown and nativeContainer(host, 'SmallFriendlyHarmful').enabled,
        unit .. ' incomplete election should yield to generic harmful presentation')
    friendly, harmful = false, {frostbolt}
    R.UpdateHost(host, true)
    assert(not slow.shown and native.enabled, unit .. ' hostile rebind should restore the native exact lane')
    friendly = true
    R.UpdateHost(host, true)
    assert(slow.shown and slow.icon.texture == frostbolt.icon, unit .. ' friendly rebind should recover the slow')
    assert(R.DestroyHost(unit) == false, unit .. ' teardown should defer in combat')
    assert(not slow.shown and slow.cooldown.duration == nil, unit .. ' deferred teardown left a stale slow')
    combat = false
    assert(R.DestroyHost(unit), unit .. ' post-combat teardown failed')
end
print('PASS compact friendly slow priority, rebind and combat cleanup on targettarget and focustarget')
