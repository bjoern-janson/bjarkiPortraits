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

-- Drive full and incremental UNIT_AURA through Main. A hostile/friendly
-- relation, token rebind or nested refresh must never reuse a previous list.
local auraFrames = {}
function region:SetScript(script, fn) self[script] = fn end
function region:RegisterEvent() end
function region:RegisterUnitEvent(event, first, second)
    if event == 'UNIT_AURA' then
        auraFrames[first] = self
        if second then auraFrames[second] = self end
    end
end
assert(loadfile('Main.lua'))('bjarkiPortraits', BP)
local function dispatch(unit, changes)
    local frame = assert(auraFrames[unit])
    frame:OnEvent('UNIT_AURA', unit, changes)
end
TargetFrame = {unit='target', TargetFrameContainer={Portrait=compactUnitFrame('target').Portrait}}
FocusFrame = {unit='focus', TargetFrameContainer={Portrait=compactUnitFrame('focus').Portrait}}
UnitIsGhost = function() return false end
local target, focus = assert(R.CreateHost('target')), assert(R.CreateHost('focus'))
local H, HNP, BNP = 'HARMFUL', 'HARMFUL|INCLUDE_NAME_PLATE_ONLY', 'HELPFUL|INCLUDE_NAME_PLATE_ONLY'
local calls, perUnit = {}, {target={}, focus={}}
local function aura(id, instance)
    return {spellId=id, auraInstanceID=instance, duration=8, expirationTime=108, icon=id}
end
for _, filter in ipairs({H, HNP, BNP}) do
    local list = {}
    for i=1,20 do list[i] = aura(800000+i, i) end
    perUnit.target[filter] = list
end
perUnit.target[H][2] = aura(118, 2)       -- Control only on the plain harmful stream.
perUnit.target[HNP][3] = aura(116, 3)     -- Slows only on the nameplate-inclusive stream.
perUnit.target[BNP][2] = aura(6673, 2)    -- BaselineClass and Healing elect independently.
perUnit.target[BNP][3] = aura(139, 3)
perUnit.focus[HNP] = {aura(116, 20)}
local nested, fault
local secret = {}
issecretvalue = function(v) return v == secret end
canaccessvalue = function(v) return v ~= secret end
C_UnitAuras.GetAuraDataByIndex = function(unit, index, filter)
    calls[filter] = (calls[filter] or 0) + 1
    if nested and unit == 'target' and filter == HNP and index == 2 then
        nested = false
        dispatch('focus', {isFullUpdate=true})
    end
    if fault and unit == 'target' and filter == HNP and index == 4 then
        if fault == 'error' then error('modeled unreadable slot') end
        if fault == 'secret' then return secret end
        return {spellId=secret}
    end
    return (perUnit[unit][filter] or {})[index]
end
for _, payload in ipairs({{isFullUpdate=true}, {updatedAuraInstanceIDs={3}}}) do
    calls = {}
    dispatch('target', payload)
    assert(target._controlSpellID == 118 and target._slowsSpellID == 116
        and target._healingSpellID == 139 and target._baselineSpellID == 6673,
        'independent filters and elections must retain their own winners')
    assert(calls[H] == 21, 'twenty plain harmful records should be indexed once per event, got '..calls[H])
    assert(calls[HNP] <= 23 and calls[BNP] <= 42,
        'nameplate-inclusive exact tiers should share one enumeration per filter')
end
perUnit.target[HNP][3] = aura(800003, 3)
nested = true
dispatch('target', {updatedAuraInstanceIDs={3}})
assert(not nested and not target._slowsActive and focus._slowsActive,
    'nested focus refresh must see its own slow and leave the target refresh independent')

perUnit.target[HNP][3] = aura(116, 3)
local direct = aura(15007, 99)
C_UnitAuras.GetUnitAuraBySpellID = function(unit, id)
    if unit == 'target' and id == direct.spellId then return direct end
end
for _, failure in ipairs({'secret', 'secretID', 'error'}) do
    fault = failure
    dispatch('target', {isFullUpdate=true})
    assert(not target._slowsActive and nativeContainer(target, 'SmallFriendlyHarmful').enabled,
        'a partial stream cannot establish a slow winner or suppress the generic fallback')
    assert(target._resurrectionSicknessDirectWitness and not target._resurrectionSicknessReadable,
        'a direct positive remains independent and cannot establish completeness')
end
fault = nil
local normalList = perUnit.target[HNP]
local capped = {aura(116, 3)}
for i=2,80 do capped[i] = aura(800000+i, i) end
perUnit.target[HNP] = capped
dispatch('target', {isFullUpdate=true})
assert(not target._slowsActive and target._resurrectionSicknessDirectWitness
    and not target._resurrectionSicknessReadable, 'a capped list has no proof of completeness')
perUnit.target[HNP] = normalList
dispatch('target', {updatedAuraInstanceIDs={3}})
assert(target._slowsActive and target._slowsSpellID == 116, 'recovered scan must elect again')
print('PASS scoped exact-tier enumeration, independent election and restricted direct fallback')
