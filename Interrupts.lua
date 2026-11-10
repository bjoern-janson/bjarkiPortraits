local _, BP = ...
local R = BP.Runtime

local function field(owner, key)
    if not R.CanAccess(owner) or owner == nil then return nil, false end
    local ok, value = pcall(function() return owner[key] end)
    if ok and R.CanAccess(value) then return value, true end
    return nil, false
end

local function call(fn, ...)
    if not R.CanAccess(fn) or type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, ...)
    if ok and R.CanAccess(value) then return value end
end

local function time(value)
    if type(value) == "number" and value >= 0 and value < math.huge then return value end
end

local function identifier(value)
    if time(value) and value > 0 and value == math.floor(value) then return value end
end

local function texture(value)
    if identifier(value) or type(value) == "string" and value ~= "" then return value end
end

local function readTiming(data, now)
    local start = time(field(data, "startTime"))
    local duration = time(field(data, "duration"))
    local remaining = time(field(data, "timeRemaining"))
    if start and now and start > now then start = nil end
    if duration == 0 then duration = nil end
    local expires = start and duration and time(start + duration)
    if not expires and now and remaining then expires = time(now + remaining) end
    return start, duration, expires, remaining == 0 or (expires and now and expires <= now)
end

local function readRecord(data, now)
    local kind = field(data, "locType")
    if type(kind) ~= "string" then return nil, false end
    if kind ~= "SCHOOL_INTERRUPT" then return nil, true end
    local spellID = identifier(field(data, "spellID"))
    if not spellID then return nil, false end
    local start, duration, expires, ended = readTiming(data, now)
    local icon = not ended and texture(field(data, "iconTexture")) or nil
    if not icon and not ended then
        icon = texture(call(field(C_Spell, "GetSpellTexture") or GetSpellTexture, spellID))
    end
    return {spellID=spellID, icon=icon, startTime=start, duration=duration, expires=expires,
        auraInstanceID=identifier(field(data, "auraInstanceID")),
        lockoutSchool=identifier(field(data, "lockoutSchool")), ended=ended or nil}, ended == true or icon ~= nil
end

-- Prefer the latest proven application. For simultaneous or untimed records
-- use public identities so a native list reorder cannot change the artwork.
local function precedes(candidate, best)
    if not best then return true end
    if candidate.startTime ~= best.startTime then
        return (candidate.startTime or -1) > (best.startTime or -1)
    end
    if candidate.spellID ~= best.spellID then return candidate.spellID < best.spellID end
    if candidate.auraInstanceID ~= best.auraInstanceID then
        return (candidate.auraInstanceID or -1) > (best.auraInstanceID or -1)
    end
    if candidate.expires ~= best.expires then return (candidate.expires or -1) > (best.expires or -1) end
    return (candidate.lockoutSchool or math.huge) < (best.lockoutSchool or math.huge)
end

local function scan(api, unit, playerOnly, now, records)
    local suffix = playerOnly and "" or "ByUnit"
    local countFn, countReadable = field(api, "GetActiveLossOfControlDataCount" .. suffix)
    local getter, getterReadable = field(api, "GetActiveLossOfControlData" .. suffix)
    if not countReadable or not getterReadable then return false end
    if not countFn and not getter then return nil end -- optional alternate interface
    local count
    if playerOnly then count = call(countFn) else count = call(countFn, unit) end
    if count == 0 then return true end
    if not identifier(count) or count > 255 or type(getter) ~= "function" then return false end
    local complete = true
    for index = 1, count do
        local data
        if playerOnly then data = call(getter, index) else data = call(getter, unit, index) end
        local candidate, known = readRecord(data, now)
        if not known then complete = false end
        if candidate then
            candidate.unit, candidate.index, candidate.playerOnly = unit, index, playerOnly
            records[#records+1] = candidate
        end
    end
    return complete
end

local function different(a,b)
    return a ~= nil and b ~= nil and a ~= b
end

-- An absolute deadline can be formed from start + duration or now + remaining.
-- Allow rounding in those two sums only. Application starts and identities stay exact.
local function differentDeadline(a,b)
    return a~=nil and b~=nil and math.abs(a-b)>math.max(a,b)*2^-51
end

function R.SameInterruptDeadline(a,b)
    return a==b or (a~=nil and b~=nil and not differentDeadline(a,b))
end

-- Once more senders are unresolved than the host can remember, inspect at
-- most one indexed row on an existing unit event. Never borrow sender data.
function R.ProbeSchoolInterrupt(unit, sweep, first, second)
    local api=C_LossOfControl
    local count=call(field(api,"GetActiveLossOfControlDataCountByUnit"),unit)
    if count==0 then
        return (first and first.ownUnit) or (second and second.ownUnit) or false,nil
    end
    if not identifier(count) or count>255 then return false,nil end
    if not sweep or sweep.count~=count or sweep.first~=first or sweep.second~=second then
        sweep={count=count,index=0,first=first,second=second,complete=true}
    end
    sweep.index=sweep.index+1
    local data=call(field(api,"GetActiveLossOfControlDataByUnit"),unit,sweep.index)
    local row,known=readRecord(data,time(call(GetTime)))
    if not known then sweep.complete=false end
    if row then
        local old=first and first.spellID==row.spellID and first or second and second.spellID==row.spellID and second
        local compatible=old and not different(row.auraInstanceID,old.auraInstanceID)
            and not different(row.startTime,old.startTime) and not different(row.lockoutSchool,old.lockoutSchool)
        if row.ended then
            if compatible and ((row.auraInstanceID and row.auraInstanceID==old.auraInstanceID)
                or (row.startTime and row.startTime==old.startTime)) then return true,nil end
        elseif row.icon and compatible then
            if old==first then sweep.sawFirst=true else sweep.sawSecond=true end
            if row.icon~=old.icon or (row.startTime and not old.startTime)
                or different(row.duration,old.duration) or differentDeadline(row.expires,old.expires)
                or (row.auraInstanceID and not old.auraInstanceID) or (row.lockoutSchool and not old.lockoutSchool) then
                return true,nil
            end
        elseif row.icon then
            local linked=row.auraInstanceID and ((first and first.auraInstanceID==row.auraInstanceID and first)
                or (second and second.auraInstanceID==row.auraInstanceID and second))
            if precedes(row,old or linked or second) then return true,nil end
        end
    end
    if sweep.index<count then return false,sweep end
    -- Absence requires a complete readable rotation. A change is only a
    -- request to reread the current full list, never permission to hide art.
    local missing=(first and first.ownUnit and not sweep.sawFirst) or (second and second.ownUnit and not sweep.sawSecond)
    return sweep.complete and missing or false,nil
end

local function conflictingPlayerIndex(api, source, record, now)
    if source.unit ~= "player" then return false end
    local other
    if source.playerOnly then
        other = call(field(api, "GetActiveLossOfControlDataByUnit"), "player", source.index)
    else
        other = call(field(api, "GetActiveLossOfControlData"), source.index)
    end
    local kind = field(other, "locType")
    if type(kind) ~= "string" then return false end
    local spell = identifier(field(other, "spellID"))
    local instance = identifier(field(other, "auraInstanceID"))
    local school = identifier(field(other, "lockoutSchool"))
    local start, duration, expires, ended = readTiming(other, now)
    return kind ~= "SCHOOL_INTERRUPT" or ended or different(spell,record.spellID)
        or different(instance,record.auraInstanceID) or different(school,record.lockoutSchool)
        or different(start,record.startTime) or different(duration,record.duration) or differentDeadline(expires,record.expires)
end

local function sameApplication(selected, other)
    if selected.spellID ~= other.spellID then return false end
    local bothInstances = selected.auraInstanceID ~= nil and other.auraInstanceID ~= nil
    local bothStarts = selected.startTime ~= nil and other.startTime ~= nil
    if different(selected.auraInstanceID,other.auraInstanceID) or different(selected.startTime,other.startTime)
        or different(selected.lockoutSchool,other.lockoutSchool) then return false end
    return bothInstances or bothStarts
end

local function clockAtIndex(api, getter, source, record, now)
    if conflictingPlayerIndex(api, source, record, now) then return nil end
    local object = call(getter, source.unit, source.index)
    if type(object) == "table" or type(object) == "userdata" then return object end
end

local function mergeEvidence(record, peers, unit, now, checkExactExpiryOnly)
    local source = record.source
    local start, duration, expires = source.startTime, source.duration, source.expires
    local school, instance = source.lockoutSchool, source.auraInstanceID
    local ended, borrowedPlayerFields = false, false
    local function absorb(other)
        if different(school, other.lockoutSchool) or different(instance, other.auraInstanceID)
            or different(start, other.startTime) or different(duration, other.duration)
            or differentDeadline(expires, other.expires) then
            return false
        end
        if unit ~= "player" and other.unit == "player" then
            if (not start and other.startTime) or (not duration and other.duration)
                or (not expires and other.expires) or (not school and other.lockoutSchool)
                or (not instance and other.auraInstanceID) then
                borrowedPlayerFields = true
            end
        end
        start, duration, expires = start or other.startTime, duration or other.duration, expires or other.expires
        school, instance = school or other.lockoutSchool, instance or other.auraInstanceID
        ended = ended or other.ended
        return true
    end
    for _, other in ipairs(peers) do
        if other ~= source and (not checkExactExpiryOnly or source.auraInstanceID == other.auraInstanceID)
            and sameApplication(source, other) then
            if not absorb(other) then return false end
        end
    end
    if instance then
        -- A shared start can reveal an instance that the source omitted.
        -- Its exact observations carry timing and expiry even when they
        -- omitted the start. All must agree before any evidence is published.
        for _, other in ipairs(peers) do
            if other ~= source and other.auraInstanceID == instance and not absorb(other) then return false end
        end
    end
    local calculated = start and duration and time(start + duration)
    if differentDeadline(calculated, expires) then return false end
    expires = calculated or expires
    local expired = ended or (expires and now and expires <= now)
    -- Publish the combined fields only after the full set of peers agrees.
    -- The exact-instance retry only decides whether to discard an expired record.
    if not expired and not checkExactExpiryOnly then
        record.startTime, record.duration, record.expires = start, duration, expires
        record.lockoutSchool, record.auraInstanceID = school, instance
        if borrowedPlayerFields then record.requiresPlayer = true end
        record.canBorrowClock = true
    end
    return true, expired
end

local function rankableRecord(source, peers, unit, now)
    if source.ended or not source.icon then return nil end
    local record = {
        source = source, spellID = source.spellID, icon = source.icon,
        auraInstanceID = source.auraInstanceID, lockoutSchool = source.lockoutSchool,
        startTime = source.startTime, duration = source.duration, expires = source.expires,
        requiresPlayer = unit ~= "player" and source.unit == "player" or nil,
        ownUnit = source.unit == unit,
    }
    local agreed, expired = mergeEvidence(record, peers, unit, now)
    if not agreed and source.auraInstanceID then
        -- When broader evidence conflicts, check whether the exact-instance
        -- peers agree that this source has expired. Otherwise keep its own fields.
        agreed, expired = mergeEvidence(record, peers, unit, now, true)
    end
    if agreed and expired then return nil end
    return record
end

local function resolveClock(api, record, peers, unit, now)
    if not record then return end
    local source = record.source
    -- Each duration belongs to one physical (unit, index) in this snapshot.
    -- Duplicate player interfaces can expose the same address. Try it once.
    local getter = field(api, "GetActiveLossOfControlDuration")
    if type(getter) == "function" then
        record.durationObject = clockAtIndex(api, getter, source, record, now)
        if not record.durationObject and record.canBorrowClock and #peers > 1 then
            local tried = {[source.unit] = {[source.index] = true}}
            for _, other in ipairs(peers) do
                local exact=record.auraInstanceID and other.auraInstanceID==record.auraInstanceID
                if other ~= source and not other.ended and (exact or sameApplication(source,other)) then
                    local indices = tried[other.unit]
                    if not indices then indices = {}; tried[other.unit] = indices end
                    if not indices[other.index] then
                        indices[other.index] = true
                        record.durationObject = clockAtIndex(api, getter, other, record, now)
                        if record.durationObject then
                            if unit~="player" and other.unit=="player" then record.requiresPlayer=true end
                            break
                        end
                    end
                end
            end
        end
    end
    record.source, record.canBorrowClock = nil, nil
end

local function sameMap(a,b)
    if a==b then return true end
    if not a or not b then return false end
    for key,value in pairs(a) do if b[key]~=value then return false end end
    for key,value in pairs(b) do if a[key]~=value then return false end end
    return true
end

-- With three or more reported spell labels an indexed occurrence can join
-- the first two labels and promote a later lockout. No indices or native
-- handles for unelected LoC rows survive the acquisition.
local function bridgeWatch(ranked)
    if #ranked<3 then return end
    local a,b,third,linked
    for _,row in ipairs(ranked) do
        if not a then a=row.spellID
        elseif row.spellID~=a then
            if not b then b=row.spellID elseif row.spellID~=b then third=true end
        end
        if row.auraInstanceID then linked=true end
        if third and linked then break end
    end
    if not third or not linked then return end
    local watch={spells={},instances={}}
    for _,row in ipairs(ranked) do
        watch.spells[row.spellID]=true
        local id=row.auraInstanceID
        if id then
            local owner=watch.instances[id]
            watch.instances[id]=(not owner or owner==row.spellID) and row.spellID or true
        end
    end
    return watch
end

local function addLink(links,watch,id,spell)
    if id and spell and watch.spells[spell] and watch.instances[id] and watch.instances[id]~=spell then
        links=links or {}
        links[id]=spell
    end
    return links
end

local function publicLinks(watch,current)
    local links
    for _,aura in ipairs(current) do links=addLink(links,watch,aura.auraInstanceID,aura.spellID) end
    return links
end

local function indexedLinks(watch,unit)
    local getter=field(C_UnitAuras,"GetAuraDataByIndex")
    if type(getter)~="function" then return end
    local seen
    for _,filter in ipairs({"HELPFUL|INCLUDE_NAME_PLATE_ONLY","HARMFUL|INCLUDE_NAME_PLATE_ONLY"}) do
        for index=1,48 do -- same public index bound used by the secondary portrait
            local aura=call(getter,unit,index,filter)
            if not aura then break end
            local id=identifier(field(aura,"auraInstanceID"))
            if id and watch.instances[id] then
                local spell=identifier(field(aura,"spellId"))
                if spell then
                    seen=seen or {}
                    if seen[id]==nil then seen[id]=spell elseif seen[id]~=spell then seen[id]=false end
                end
            end
        end
    end
    local links
    if seen then
        for id,spell in pairs(seen) do links=addLink(links,watch,id,spell) end
    end
    return links
end

function R.SchoolInterruptLinksChanged(first,current,unit)
    local watch=first and first.bridgeWatch
    if not watch then return false end
    local links=publicLinks(watch,current)
    return not sameMap(links,watch.links) or (links and watch.unit~=unit)
end

function R.SameSchoolInterruptGroup(a,b)
    return sameMap(a.linkedSpells,b.linkedSpells) and sameMap(a.linkedInstances,b.linkedInstances)
end

local function rootSpell(parent,spell)
    while parent[spell] do spell=parent[spell] end
    return spell
end

local function join(parent,a,b)
    a,b=rootSpell(parent,a),rootSpell(parent,b)
    if a~=b then parent[a]=b end
end

local function rememberGroup(record,ranked,parent)
    if not record then return end
    local root=rootSpell(parent,record.spellID)
    for _,row in ipairs(ranked) do
        if rootSpell(parent,row.spellID)==root then
            if row.spellID~=record.spellID then
                record.linkedSpells=record.linkedSpells or {}
                record.linkedSpells[row.spellID]=true
            end
            if row.auraInstanceID and row.auraInstanceID~=record.auraInstanceID then
                record.linkedInstances=record.linkedInstances or {}
                record.linkedInstances[row.auraInstanceID]=true
            end
        end
    end
end

local function elect(records, count, unit, now, current, auraUnit, priorWatch)
    local bySpell, ranked = {}, {}
    for i=1,count do
        local source=records[i]
        local peers = bySpell[source.spellID]
        if not peers then peers={}; bySpell[source.spellID]=peers end
        peers[#peers+1]=source
    end
    local first, second
    for i=1,count do
        local source=records[i]
        local record=rankableRecord(source, bySpell[source.spellID], unit, now)
        if record then
            ranked[#ranked+1]=record
            if precedes(record, first) then first=record end
        end
    end
    local watch=bridgeWatch(ranked)
    local parent
    if watch then
        if priorWatch then
            if priorWatch.unit==unit then watch.links=priorWatch.links else watch.links=indexedLinks(watch,unit) end
        elseif current then
            watch.links=publicLinks(watch,current)
        else
            watch.links=indexedLinks(watch,auraUnit or unit)
        end
        watch.unit=auraUnit or unit
        first.bridgeWatch=watch
        if watch.links then
            parent={}
            local firstAt={}
            for _,row in ipairs(ranked) do
                local id=row.auraInstanceID
                if id then
                    local peer=watch.links[id]
                    if peer and watch.spells[peer] then join(parent,row.spellID,peer) end
                    if firstAt[id] then join(parent,row.spellID,firstAt[id]) else firstAt[id]=row.spellID end
                end
            end
        end
    end
    for _,record in ipairs(ranked) do
        if record.spellID~=first.spellID and (not record.auraInstanceID or record.auraInstanceID~=first.auraInstanceID)
            and (not parent or rootSpell(parent,record.spellID)~=rootSpell(parent,first.spellID))
            and precedes(record,second) then second=record end
    end
    if parent then
        rememberGroup(first,ranked,parent)
        rememberGroup(second,ranked,parent)
    end
    return first, second, bySpell,watch
end

local function samePublicRank(a,b)
    if not a or not b then return a==b end
    return a.spellID==b.spellID and a.auraInstanceID==b.auraInstanceID and a.lockoutSchool==b.lockoutSchool
        and a.startTime==b.startTime and a.duration==b.duration and R.SameInterruptDeadline(a.expires,b.expires)
        and a.icon==b.icon and R.SameSchoolInterruptGroup(a,b)
end

function R.GetSchoolInterrupt(unit,current,auraUnit)
    local api = C_LossOfControl
    if not R.CanAccess(unit) or type(unit) ~= "string" or unit == ""
        or not R.CanAccess(api) then return nil, nil, false end
    if type(api) ~= "table" then return nil, nil, false end
    local now = time(call(GetTime))
    local records = {}
    local direct = scan(api, unit, false, now, records)
    local directCount = #records
    local complete, available = direct ~= false, direct ~= nil
    local selfAlias, selfKnown
    if unit ~= "player" and type(UnitIsUnit) == "function" then
        selfAlias, selfKnown = R.SafeBool(UnitIsUnit, unit, "player")
    end
    local unresolvedSelf = (unit=="target" or unit=="focus") and selfKnown == false
    if unit == "player" or selfAlias then
        local player = scan(api, "player", true, now, records)
        local playerUnit
        if selfAlias then playerUnit = scan(api, "player", false, now, records) end
        complete = complete and player ~= false and playerUnit ~= false
        available = available or player ~= nil or playerUnit ~= nil
    end
    if current and auraUnit~=unit and not (auraUnit=="player" and selfAlias) then return nil,nil,false end
    local linkUnit=auraUnit or (selfAlias and "player" or unit)
    local first,second,bySpell,watch=elect(records,#records,unit,now,current,linkUnit)
    if second then resolveClock(api, second, bySpell[second.spellID], unit, now) end
    if first then resolveClock(api, first, bySpell[first.spellID], unit, now) end
    local rankUsesPlayer
    if selfAlias then
        -- A player row can exclude an otherwise eligible target occurrence,
        -- including when neither elected slot survives. Compare the already
        -- observed own rows, without rereading native lists or resolving clocks.
        if (#records>directCount or (watch and watch.links and watch.unit=="player"))
            and not ((first and first.requiresPlayer) or (second and second.requiresPlayer)) then
            local ownFirst,ownSecond=elect(records,directCount,unit,now,nil,nil,watch)
            rankUsesPlayer = not samePublicRank(first,ownFirst) or not samePublicRank(second,ownSecond) or nil
        end
        local stillSelf, known = R.SafeBool(UnitIsUnit, unit, "player")
        if not stillSelf then return nil, nil, false, (unit=="target" or unit=="focus") and not known end
    end
    return first, second, available and complete, unresolvedSelf, rankUsesPlayer
end

local function apply(cooldown, name, ...)
    local setter = field(cooldown, name)
    if type(setter) ~= "function" then return false end
    local ok, result = pcall(setter, cooldown, ...)
    return ok and R.CanAccess(result) and result ~= false
end

function R.SetSchoolInterruptClock(cooldown, record)
    if not R.CanAccess(record) or type(record) ~= "table" then return false end
    local expires = time(field(record, "expires"))
    local now = time(call(GetTime))
    if expires and now and expires <= now then return false end
    local object = field(record, "durationObject")
    if (type(object) == "table" or type(object) == "userdata")
        and apply(cooldown, "SetCooldownFromDurationObject", object, true) then return true, true, "object" end
    if expires then
        local start = time(field(record, "startTime"))
        local duration = time(field(record, "duration"))
        -- Draw only the observed remainder when the application time is absent.
        if not start then start = duration and time(expires - duration) or now end
        if start and expires > start and apply(cooldown, "SetCooldown", start, expires - start) then
            return true, true, "numeric"
        end
    end
    -- A refused clock does not revoke the landed spell, but its old digits
    -- must actually clear before this art-only presentation can be accepted.
    return apply(cooldown, "Clear"), false
end
