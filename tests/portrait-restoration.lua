-- Offline UI boundary model; the shipped constructors and lifecycle run unchanged.
-- Catches lost recovery ownership, hidden native art and nested retry ownership.
unpack = unpack or table.unpack -- WoW compatibility global on the Lua 5.4 model.
local function eq(actual, expected, label)
    label=label or "value"
    assert(actual == expected, label .. ': expected ' .. tostring(expected) .. ', got ' .. tostring(actual))
end
local function setup()
    BjarkiPortraitsDB = nil
    issecretvalue, issecrettable, canaccessvalue = nil, nil, nil
    PlayerFrame, FocusFrame, TargetFrameToT, FocusFrameToT = nil, nil, nil, nil
    local s = {frames={}, combat=false, failParent=false, failPoints=false, failCreate=false}
    InCombatLockdown = function() return s.combat end
    GetTime = function() return 100 end
    UnitExists = function() return false end
    local function region(parent)
        local r = {parent=parent, points={}, shown=true, hides=0}
        function r:GetParent() return self.parent end
        function r:SetParent(value)
            if self == s.portrait and value == s.original and s.failParent then error('parent restore unavailable') end
            self.parent = value
        end
        function r:GetNumPoints() return #self.points end
        function r:GetPoint(i) return (unpack or table.unpack)(self.points[i]) end
        function r:ClearAllPoints() self.points = {} end
        function r:SetPoint(...)
            if self == s.portrait and self.parent == s.original and s.failPoints then error('point restore unavailable') end
            self.points[#self.points + 1] = {...}
        end
        function r:SetAllPoints(value)
            if s.failHelper and self == s.frames[3] then error('helper layout unavailable') end
            self.points = {{'TOPLEFT', value, 'TOPLEFT', 0, 0}, {'BOTTOMRIGHT', value, 'BOTTOMRIGHT', 0, 0}}
        end
        function r:Hide() self.shown=false; self.hides=self.hides+1 end
        function r:Show() self.shown=true end
        function r:IsShown() return self.shown end
        function r:SetShown(value) self.shown=value end
        function r:SetEnabled(value) self.enabled=value end
        function r:IsEnabled() return self.enabled end
        function r:GetFrameStrata() return 'MEDIUM' end
        function r:CreateTexture(_,layer,_,sub)
            local texture=region(self)
            if s.captureFoundation and layer=='ARTWORK' and sub==1 then s.captureFoundation(self,texture) end
            return texture
        end
        for _, method in ipairs({'SetFrameStrata','SetFrameLevel','SetTexCoord','SetTexture',
            'SetUsingParentLevel','SetReverse','SetDrawBling','SetDrawEdge','SetDrawSwipe',
            'SetHideCountdownNumbers','SetCountdownMillisecondsThreshold','SetSwipeTexture',
            'AddAuraSlot','Clear','SetCooldown','SetMinimumCountdownDuration'}) do
            r[method] = function() end
        end
        return r
    end
    s.original = region(nil)
    s.portrait = region(s.original)
    s.portrait.points = {{'TOPLEFT', s.original, 'TOPLEFT', 3, 4}, {'BOTTOMRIGHT', s.original, 'BOTTOMRIGHT', -5, -6}}
    TargetFrame = {unit='target', TargetFrameContainer={Portrait=s.portrait}}
    CreateFrame = function(_, _, parent)
        if s.failCreate and #s.frames == 1 then error('anchor unavailable') end
        local frame = region(parent)
        s.frames[#s.frames+1] = frame
        return frame
    end
    local bp = {}
    for _, file in ipairs({'Core','Spells','Priority','AuraEngine'}) do
        assert(loadfile(file .. '.lua'))('bjarkiPortraits', bp)
    end
    s.R = bp.Runtime
    s.R.ApplyDefaults()
    -- No aura slots are required to exercise ownership; retain real helper construction.
    s.R.TIERS = {}
    s.R.SORT_METHOD, s.R.SORT_DIRECTION = 1, 1
    s.R.Print = function() end
    function s:build()
        return assert(self.R.CreateHost('target'), 'host construction must succeed')
    end
    function s:restored()
        eq(self.portrait.parent, self.original, 'native parent restored')
        eq(#self.portrait.points, 2, 'both original points restored')
        local a, b = self.portrait.points[1], self.portrait.points[2]
        eq(a[1], 'TOPLEFT', 'first anchor'); eq(a[2], self.original, 'first reference')
        eq(a[4], 3, 'first x'); eq(a[5], 4, 'first y')
        eq(b[1], 'BOTTOMRIGHT', 'second anchor'); eq(b[2], self.original, 'second reference')
        eq(b[4], -5, 'second x'); eq(b[5], -6, 'second y')
    end
    return s
end
local failures, passed = {}, 0
local function installEvents(s)
    local frames={}
    local createFrame=CreateFrame
    CreateFrame=function()
        local frame={events={}}
        function frame:RegisterEvent(event) self.events[event]=true end
        function frame:RegisterUnitEvent(event,...) self.events[event]={...} end
        function frame:SetScript(_,cb) self.cb=cb end
        frames[#frames+1]=frame
        return frame
    end
    s.deferred=nil
    C_Timer={After=function(_,fn) s.deferred=fn end}
    assert(loadfile('Main.lua'))('bjarkiPortraits',{Runtime=s.R})
    CreateFrame=createFrame
    return function(event,token)
        for _,frame in ipairs(frames) do
            local units=frame.events[event]
            if units==true then frame.cb(frame,event,token)
            elseif units then
                for _,u in ipairs(units) do if u==token then frame.cb(frame,event,token) end end
            end
        end
    end
end
local function test(name, body)
    local ok, err = pcall(body)
    if ok then passed=passed+1; print('PASS ' .. name)
    else failures[#failures+1]=name .. ': ' .. tostring(err); print('FAIL ' .. failures[#failures]) end
end

test('build skips disabled hosts unless pet art needs their foundation', function()
    local s=setup()
    s.R.db.target, s.R.db.petPortraits=false,false
    s.R.BuildAll()
    eq(s.R.hosts.target,nil,'disabled target never allocates aura containers')
    eq(s.portrait.parent,s.original,'native parent kept')
    s.R.db.petPortraits=true
    s.R.BuildAll()
    eq(s.R.hosts.target~=nil,true,'independently enabled pet art can use target foundation')
end)
test('normal teardown restores parent and every point exactly once', function()
    local s=setup(); local host=s:build()
    eq(#s.portrait.points,2,'active native portrait retains both sizing constraints')
    eq(s.portrait.points[2][2],s.original,'active second anchor still references native owner')
    eq(s.R.DestroyHost('target'), true, 'teardown succeeds'); s:restored()
    eq(s.R.hosts.target, nil, 'ownership removed'); eq(host.reparented, false, 'restoration completed')
    eq(host.layer.shown, false, 'detached layer hidden')
    local hides=host.layer.hides
    eq(s.R.DestroyHost('target'), true, 'second teardown is harmless')
    eq(host.layer.hides, hides, 'completed layer not cleaned again')
end)

test('parent failure preserves visible native portrait and recovery state', function()
    local s=setup(); local host=s:build(); s.failParent=true
    eq(s.R.DestroyHost('target'), false, 'failed restore reported')
    eq(s.R.hosts.target, host, 'recovery ownership retained')
    eq(host.reparented, true, 'restoration still required')
    eq(s.portrait.parent, host.layer, 'native stays under owned layer')
    eq(host.layer.shown, true, 'native layer remains visible')
    eq(s.R.buildQueued, true, 'existing lifecycle retry requested')
    eq(s.R.DestroyAll(), false, 'bulk teardown propagates restoration failure')
    s.failParent=false
    eq(s.R.DestroyHost('target'), true, 'later retry succeeds'); s:restored()
    eq(s.R.hosts.target, nil, 'successful retry releases ownership')
    eq(host.layer.shown, false, 'successful retry hides layer')
end)

test('point failure retains recovery until all original points succeed', function()
    local s=setup(); local host=s:build(); s.failPoints=true
    local ok, result=pcall(s.R.DestroyHost, 'target')
    eq(ok, true, 'restore exception contained'); eq(result, false, 'point failure reported')
    eq(s.R.hosts.target, host, 'point recovery retained'); eq(host.reparented, true, 'points still pending')
    eq(host.layer.shown, true, 'owned layer not discarded before full restore')
    s.failPoints=false
    eq(s.R.DestroyHost('target'), true, 'point retry succeeds'); s:restored()
end)

test('stale refresh blocks replacement while restoration fails', function()
    local s=setup(); local host=s:build(); local count=#s.frames
    TargetFrame.TargetFrameContainer.Portrait=nil; s.failParent=true
    s.R.Refresh('target')
    eq(s.R.hosts.target, host, 'stale host remains recoverable')
    eq(#s.frames, count, 'no replacement frames allocated')
    TargetFrame.TargetFrameContainer.Portrait=s.portrait
    eq(s.R.CreateHost('target'), nil, 'pending restoration cannot reuse or wrap old owner')
    eq(s.portrait.parent, host.layer, 'no nested ownership')
    s.failParent=false; s.R.BuildAll()
    local replacement=assert(s.R.hosts.target, 'build lifecycle creates replacement after restore')
    assert(replacement ~= host, 'pending teardown cannot revive the old host')
    eq(replacement.originalParent, s.original, 'replacement captures actual native parent')
    eq(host.layer.shown, false, 'old layer cleaned')
end)

test('disabled BuildAll retains failure and Refresh retries cleanup', function()
    local s=setup(); local host=s:build(); s.R.db.enabled=false; s.failParent=true
    s.R.BuildAll()
    eq(s.R.hosts.target, host, 'disabled restoration retained'); eq(s.R.buildQueued, true, 'disabled retry not cleared')
    eq(host.layer.shown, true, 'disabled state preserves native art')
    s.failParent=false; s.R.Refresh('target'); s:restored()
    eq(s.R.hosts.target, nil, 'disabled event completes cleanup')
end)

test('ordinary per-unit disable keeps the existing reusable host', function()
    local s=setup(); local host=s:build(); s.R.db.target=false
    s.R.Refresh('target')
    eq(s.R.hosts.target, host, 'ordinary disabled host retained')
    eq(s.portrait.parent, host.layer, 'ordinary disable does not change native ownership')
    eq(host.layer.shown, true, 'ordinary disabled native layer remains visible')
end)

test('combat defers restoration and existing BuildAll retries out of combat', function()
    local s=setup(); local host=s:build(); s.R.db.enabled=false; s.combat=true
    eq(s.R.DestroyHost('target'), false, 'combat teardown deferred')
    eq(s.portrait.parent, host.layer, 'combat does not reparent'); eq(host.layer.shown, true, 'combat native visible')
    eq(s.R.buildQueued, true, 'combat queues existing retry')
    s.combat=false; s.R.BuildAll(); s:restored()
    eq(s.R.hosts.target, nil, 'out of combat cleanup completes'); eq(s.R.buildQueued, false, 'completed queue consumed')
end)

test('partial construction failure remains recoverable without nested retry', function()
    local s=setup(); s.failCreate=true; s.failParent=true
    eq(s.R.CreateHost('target'), nil, 'failed constructor returns no usable host')
    local pending=assert(s.R.hosts.target, 'partly reparented host retained for recovery')
    eq(pending._buildComplete, nil, 'partial host cannot present')
    eq(pending.layer.shown, true, 'failed cleanup never hides native portrait')
    local count=#s.frames
    s.R.Refresh('target'); s.R.BuildAll()
    eq(#s.frames, count, 'failed retries cannot build more layers')
    eq(s.portrait.parent, pending.layer, 'pending portrait is never nested')
    s.failCreate=false; s.failParent=false; s.R.BuildAll()
    local host=assert(s.R.hosts.target, 'explicit lifecycle retries recovered constructor')
    eq(host._buildComplete, true, 'retry fully builds')
    eq(host.originalParent, s.original, 'retry preserves original native parent')
    eq(pending.layer.shown, false, 'abandoned layer cleaned after success')
end)

test('partial helper failure hides unfinished art while native restore waits', function()
    local s=setup(); s.failHelper=true; s.failParent=true
    eq(s.R.CreateHost('target'), nil, 'helper construction fails')
    eq(s.frames[1].shown, true, 'native layer stays visible')
    eq(s.frames[3].shown, false, 'unpublished helper art hidden')
end)

test('failed restoration suppresses all owned helpers while keeping native art visible', function()
    local s=setup(); local host=s:build()
    host.readableWaitingToResurrectFrame:Show()
    host.readableDivineProtectionFrame:Show()
    s.failParent=true
    eq(s.R.DestroyHost('target'), false, 'restoration still pending')
    eq(host.layer.shown, true, 'native layer remains visible')
    eq(host.readableWaitingToResurrectFrame.shown, false, 'waiting presentation disabled')
    eq(host.readableDivineProtectionFrame.shown, false, 'immunity presentation disabled')
end)

test('pooled party permutation restores only native parents in either refresh order', function()
    for _, order in ipairs({{1,2}, {2,1}, {1,3,2}}) do
        local s, native, members = setup(), {}, {}
        UnitExists = function(unit) return unit:match('^party') ~= nil end
        UnitIsPlayer = function() return true end
        local function token(i) return 'party' .. i end
        PartyFrame = {GetPartyMemberFrame=function(_, index) return members[index] end}
        for i=1,#order do
            local member = CreateFrame('Button', nil, nil)
            member.Portrait = CreateFrame('Texture', nil, member)
            member.Portrait:SetPoint('CENTER', member, 'CENTER', 0, 0)
            member.unit = token(i)
            native[i], members[i] = member, member
            assert(s.R.CreateHost(token(i)))
        end
        for i=1,#order do
            members[i] = native[i % #order + 1]
            members[i].unit = token(i)
        end
        for _, i in ipairs(order) do s.R.Refresh(token(i)) end
        for i=1,#order do
            local host = assert(s.R.hosts[token(i)])
            eq(host.layer.parent, members[i], 'replacement sits directly under the Blizzard member')
            eq(host.portrait.parent, host.layer, 'replacement still owns native portrait')
        end
        assert(s.R.DestroyAll())
        for _, f in ipairs(native) do eq(f.Portrait.parent, f, 'original native parent on release') end
    end
end)

test('format updates include the prepared native secondary for the requested host only', function()
    local s=setup()
    local target=s:build()
    s.R.hosts.focus={cooldowns={}}
    local formatted={}
    s.R.ApplyNativeSecondPresentation=function(host) formatted[host]=true end
    s.R.ApplyPresentation('target')
    eq(formatted[target],true,'target native second is updated')
    eq(formatted[s.R.hosts.focus],nil,'other owner is untouched')
end)

test('combat and a failed peer restore defer a party takeover, then recover', function()
    local s=setup()
    local members={}
    PartyFrame={GetPartyMemberFrame=function(_,index) return members[index] end}
    UnitExists=function(unit) return unit=='party1' or unit=='party2' end
    for i=1,2 do
        local f=CreateFrame('Button',nil,nil)
        f.Portrait=CreateFrame('Texture',nil,f)
        f.Portrait:SetPoint('CENTER',f,'CENTER',0,0)
        f.unit='party'..i
        members[i]=f
        assert(s.R.CreateHost(f.unit))
    end
    local oldParty2=s.R.hosts.party2
    local a,b=members[1],members[2]
    members[1],members[2]=b,a
    a.unit,b.unit='party2','party1'
    s.combat=true
    s.R.Refresh('party1')
    eq(b.Portrait.parent,oldParty2.layer,'combat does not seize the incoming physical portrait')
    s.combat=false
    local setParent=b.Portrait.SetParent
    b.Portrait.SetParent=function(self,parent)
        if parent==b then error('native parent temporarily denied') end
        return setParent(self,parent)
    end
    s.R.Refresh('party1')
    eq(s.R.hosts.party1,nil,'no replacement built against unrecovered peer')
    eq(s.R.hosts.party2,oldParty2,'failed peer keeps its restoration state')
    eq(b.Portrait.parent,oldParty2.layer,'peer still owns its native texture')
    b.Portrait.SetParent=setParent
    s.R.Refresh('party1')
    s.R.Refresh('party2')
    eq(s.R.hosts.party1.layer.parent,b,'safe retry after peer recovery')
    eq(s.R.hosts.party2.layer.parent,a,'other replacement retains native baseline')
    assert(s.R.DestroyAll())
    eq(b.Portrait.parent,b,'native B restored')
    eq(a.Portrait.parent,a,'native A restored')
end)

test('detached secondary renderers follow native effective visibility between aura events', function()
    local s=setup()
    local owner=TargetFrame
    local callbacks={}
    function owner:HookScript(script, callback) callbacks[script]=callback end
    function owner:IsVisible() return self.visible end
    owner.visible=true
    local host=s:build()
    local hidden={}
    s.R.HideSecondaryPortrait=function(h) hidden.public=h end
    s.R.HideNativeSecondProbe=function(h) hidden.native=h end
    s.R.HidePetSecondaryFallback=function(h) hidden.pet=h end
    owner.visible=false
    assert(callbacks.OnHide, 'native owner hide must be observed')(owner)
    eq(hidden.public,host,'public badge revoked without an aura event')
    eq(hidden.native,host,'native viewport revoked without an aura event')
    eq(hidden.pet,host,'family overlay revoked without an aura event')
    local pending, refreshes={},0
    C_Timer={After=function(_,fn) pending[#pending+1]=fn end}
    s.R.Refresh=function(unit) eq(unit,'target','current visible owner'); refreshes=refreshes+1 end
    owner.visible=true
    callbacks.OnShow(owner); callbacks.OnShow(owner)
    eq(#pending,1,'two show callbacks coalesce')
    pending[1]()
    eq(refreshes,1,'visible current owner recovers on the next safe event turn')
    callbacks.OnShow(owner)
    assert(s.R.DestroyHost('target'))
    pending[2]()
    eq(refreshes,1,'queued callback cannot revive a retired host')
end)

test('target and focus physical replacements revoke old presentation before combat-safe reconstruction',function()
    for _,unit in ipairs({'target','focus'}) do
        local s=setup()
        if unit=='focus' then FocusFrame=TargetFrame; TargetFrame=nil end
        local host=assert(s.R.CreateHost(unit))
        assert(loadfile('PetPortraits.lua'))('bjarkiPortraits',{Runtime=s.R})
        UnitIsUnit=function()return false end
        UnitIsOtherPlayersPet=function()return true end
        UnitCreatureFamily=function()return 'Owl',26 end
        C_CreatureInfo={GetCreatureFamilyInfo=function()return {name='Owl',iconFile=26626} end}
        local foundation
        local createTexture=host.layer.CreateTexture
        host.layer.CreateTexture=function(...)
            foundation=createTexture(...)
            foundation.SetTexture=function(texture,art) texture.art=art;return true end
            return foundation
        end
        s.R.UpdateObservedPetPortrait(unit)
        eq(foundation and foundation.shown,true,'current physical host has real pet art')
        local fire=installEvents(s)
        local nextParent=CreateFrame('Frame')
        local nextPortrait=nextParent:CreateTexture()
        nextPortrait:SetPoint('CENTER',nextParent,'CENTER',0,0)
        local replacement={unit=unit,TargetFrameContainer={Portrait=nextPortrait}}
        s.R.HideSecondaryPortrait=function(h) h.publicRevoked=true end
        s.R.HideNativeSecondProbe=function(h) h.stripRevoked=true end
        s.R.HidePetSecondaryFallback=function(h) h.petRevoked=true end
        local original=unit=='target' and TargetFrame or FocusFrame
        local denied=setmetatable({},{__index=function() error('unavailable physical frame') end})
        if unit=='target' then TargetFrame=denied else FocusFrame=denied end
        fire('UNIT_PORTRAIT_UPDATE',unit)
        eq(foundation.shown,false,'unreadable member hides old art without aborting the event')
        eq(type(s.deferred),'function','denied member still schedules the normal deferred reconciliation')
        s.deferred()
        eq(s.R.hosts[unit],host,'deferred unknown cannot replace the host')
        if unit=='target' then TargetFrame=original else FocusFrame=original end
        fire('UNIT_NAME_UPDATE',unit);s.deferred()
        eq(foundation.shown,true,'same positive physical owner resumes its pet foundation')
        if unit=='target' then TargetFrame=replacement else FocusFrame=replacement end
        host.readableGhostFrame:Show()
        s.combat=true
        fire('UNIT_PORTRAIT_UPDATE',unit)
        eq(foundation.shown,false,'portrait update before host refresh revokes obsolete family art')
        fire(unit=='target' and 'PLAYER_TARGET_CHANGED' or 'PLAYER_FOCUS_CHANGED')
        eq(foundation.shown,false,'post-refresh pet lookup cannot repaint the obsolete frame')
        eq(host.publicRevoked,true,'public overlay revoked')
        eq(host.stripRevoked,true,'native viewport revoked')
        eq(host.petRevoked,true,'pet fallback revoked')
        eq(host.readableGhostFrame.shown,false,'old static primary is hidden')
        eq(host.testFrame.shown,false,'old test overlay stays hidden')
        eq(host.layer.shown,true,'native portrait layer remains visible during combat')
        eq(host.portrait.parent,host.layer,'no native ownership change in combat')
        eq(nextPortrait.parent,nextParent,'no replacement constructed during combat')
        s.combat=false
        s.R.BuildAll()
        local new=assert(s.R.hosts[unit])
        eq(new.unitFrame,replacement,'replacement reconstructed after combat')
        eq(host.portrait.parent,s.original,'old portrait restored')
    end
end)

test('unknown physical binding defers ownership, successful hides coalesce and denied ones retry',function()
    local s=setup();local native=TargetFrame
    local h=s:build()
    local publicHides,stripHides=0,0
    s.R.HideSecondaryPortrait=function() publicHides=publicHides+1;return true end
    s.R.HideNativeSecondProbe=function() stripHides=stripHides+1;return stripHides>1 end
    h.readableGhostFrame:Show()
    local ghostHides=h.readableGhostFrame.hides
    local styleWrites=0
    s.R.ApplyCountdownFormat=function()styleWrites=styleWrites+1 end
    TargetFrame=setmetatable({},{__index=function()error('restricted native member')end})
    s.R.Refresh('target');s.R.Refresh('target');s.R.Refresh('target')
    s.R.ApplyPresentation('target')
    eq(styleWrites,0,'deferred presentation does not format suspended cooldowns')
    eq(s.R.hosts.target,h,'unknown does not destroy original host')
    eq(h.portrait.parent,h.layer,'unknown leaves the native parent alone')
    eq(publicHides,1,'successful independent surface is not revoked again')
    eq(stripHides,2,'denied independent surface is retried until successful')
    eq(h.readableGhostFrame.hides,ghostHides+1,'successful helper hide is not repeated')
    TargetFrame=native; s.combat=true; s.R.Refresh('target',true,true)
    eq(h.anchor.shown,false,'secure group parent stays suspended through lockdown')
    local update=s.R.UpdateHost
    local recoveredChange
    s.R.UpdateHost=function(h,force,bindingChanged)
        recoveredChange=force and bindingChanged
        return update(h,force,bindingChanged)
    end
    s.combat=false; s.R.Refresh('target')
    eq(s.R.hosts.target,h,'confirmed original identity restores the same host')
    eq(h.anchor.shown,true,'secure presenter resumes after verified recovery')
    eq(recoveredChange,true,'binding change signal is replayed after recovery')
    eq(styleWrites>0,true,'recovery reconciles the current presentation settings')
end)
test('never-built inaccessible physical frame remains eligible for a normal retry',function()
    local s=setup();local native=TargetFrame
    TargetFrame=setmetatable({},{__index=function()error('denied')end})
    s.R.Refresh('target');eq(s.R.hosts.target,nil)
    TargetFrame=native;s.R.Refresh('target')
    eq(s.R.hosts.target~=nil,true,'transient identity read does not latch constructor failure')
end)
test('pending teardown never writes native groups in combat or unknown lockdown',function()
    local s=setup();local h=s:build();s.R.db.enabled=false;s.failParent=true
    local writes=0
    h.containers={{SetEnabled=function() writes=writes+1 end,SetShown=function() writes=writes+1 end}}
    eq(s.R.DestroyHost('target'),false);writes=0
    s.combat=true;s.R.Refresh('target');s.R.Refresh('target')
    InCombatLockdown=function()return nil end;s.R.Refresh('target')
    eq(writes,0,'denied safety state does not invoke native setters')
    s.failParent=false;InCombatLockdown=function()return false end
    s.R.Refresh('target');s:restored()
    eq(s.R.hosts.target,nil,'safe event completes recorded restoration')
end)
test('restore preserves externally adopted parent and points, including after a partial attempt',function()
    for _,phase in ipairs({'external','partial','anchors'}) do
        local s=setup();local h=s:build();local newer=CreateFrame('Frame')
        if phase=='partial' then
            s.failPoints=true;eq(s.R.DestroyHost('target'),false);s.failPoints=false
        end
        if phase~='anchors' then s.portrait:SetParent(newer) end
        s.portrait:ClearAllPoints();s.portrait:SetPoint('CENTER',newer,'CENTER',27,14)
        eq(s.R.DestroyHost('target'),true)
        eq(s.portrait.parent,phase=='anchors' and s.original or newer,'newer parent policy')
        eq(#s.portrait.points,1,'keep external anchor count')
        eq(s.portrait.points[1][4],27,'external anchor survives')
    end
end)
test('unavailable geometry cannot authorize taking or restoring a native portrait',function()
    local s=setup()
    local original=s.portrait.GetPoint
    s.portrait.GetPoint=nil
    eq(s.R.CreateHost('target'),nil,'no takeover with no point reader')
    eq(s.portrait.parent,s.original)
    s.portrait.GetPoint=original
    local h=s:build()
    local count=s.portrait.GetNumPoints
    s.portrait.GetNumPoints=nil
    eq(s.R.DestroyHost('target'),false,'missing point count cannot authorize restoration')
    eq(s.portrait.parent,h.layer)
    s.portrait.GetNumPoints=count
    s.portrait.points={{'CENTER',nil,'TOPLEFT',27,14}}
    s.portrait.GetPoint=function(self,i) return unpack(self.points[i],1,5) end
    eq(s.R.DestroyHost('target'),true)
    eq(s.portrait.parent,s.original);eq(s.portrait.points[1][2],nil)
    eq(s.portrait.points[1][5],14,'last offset preserved across a nil relative frame')
end)
test('parent setter that moves then raises retains pending anchor restoration',function()
    local s=setup();local h=s:build()
    local setter=s.portrait.SetParent
    s.portrait.SetParent=function(p,parent)
        setter(p,parent)
        p:ClearAllPoints()
        error('after native parent write')
    end
    eq(s.R.DestroyHost('target'),false)
    eq(s.portrait.parent,s.original)
    s.portrait.SetParent=setter
    eq(s.R.DestroyHost('target'),true)
    s:restored()
end)
test('failed native group writes retain cleanup ownership independently of the native portrait',function()
    local s=setup()
    local host=s:build()
    local blocked=true
    local function makeGroup(failEnable,failHide)
        local group={enabled=true,shown=true,disables=0,hides=0}
        function group:SetEnabled(enabled)
            self.disables=self.disables+1
            if failEnable and blocked then error('disable denied') end
            self.enabled=enabled
        end
        function group:SetShown(shown)
            self.hides=self.hides+1
            if failHide and blocked then return false end
            self.shown=shown
        end
        return group
    end
    local lateDisable,lateHide,healthy=makeGroup(true,false),makeGroup(false,true),makeGroup(false,false)
    host.containers={lateDisable,lateHide,healthy}
    s.R.db.enabled=false
    eq(s.R.DestroyHost('target'),false,'failed native group cleanup remains pending')
    eq(s.R.hosts.target,host,'the old groups still have a cleanup owner')
    eq(host._restorePending,true,'regular events cannot reacquire incomplete groups')
    s:restored()
    eq(s.portrait.shown,true,'native art is restored independently of group cleanup')
    eq(lateDisable.enabled,true,'fault model actually refused the disable')
    eq(lateHide.enabled,false,'other group disable still occurs')
    s.combat=true;s.R.Refresh('target')
    eq(lateDisable.disables,1,'pending disables wait for out-of-combat')
    eq(lateHide.hides,1,'pending hides wait for out-of-combat')
    blocked=false;s.combat=false
    s.R.Refresh('target')
    eq(healthy.disables,1);eq(healthy.hides,1)
    eq(lateDisable.disables,2);eq(lateDisable.hides,1)
    eq(lateHide.disables,1);eq(lateHide.hides,2)
    eq(lateDisable.enabled,false);eq(lateHide.shown,false)
    eq(s.R.hosts.target,nil,'final acknowledgment releases the host')
end)
for _,stage in ipairs({'parent','second point'}) do
    test('interrupted '..stage..' write recovers after denied readback',function()
        for _,takeover in ipairs({false,true}) do
            local s=setup();s:build()
            local p=s.portrait
            local setParent,setPoint,getParent,count=p.SetParent,p.SetPoint,p.GetParent,p.GetNumPoints
            if stage=='parent' then
                p.SetParent=function(self,parent)
                    setParent(self,parent);self:ClearAllPoints()
                    self.GetParent=function()error('parent temporarily unreadable')end
                    error('parent changed before exception')
                end
            else
                p.SetPoint=function(self,...)
                    if #self.points==0 then return setPoint(self,...) end
                    self.GetNumPoints=function()error('points temporarily unreadable')end
                    error('second anchor rejected')
                end
            end
            eq(s.R.DestroyHost('target'),false,'retain uncertain restore')
            p.SetParent,p.SetPoint,p.GetParent,p.GetNumPoints=setParent,setPoint,getParent,count
            if takeover then
                p:ClearAllPoints();p:SetPoint('CENTER',s.original,'CENTER',77,23)
            end
            eq(s.R.DestroyHost('target'),true,'release after readable retry')
            if takeover then
                eq(#p.points,1);eq(p.points[1][4],77,'external geometry preserved')
            else s:restored() end
        end
    end)
end
test('unreadable optional cooldown cleanup cannot leave a retired helper visible',function()
    local s=setup();local h=s:build();local helper=h.readableGhostFrame
    helper:Show()
    helper.cooldown=setmetatable({},{__index=function()error('cooldown member unavailable')end})
    TargetFrame=nil;s.combat=true;s.R.Refresh('target')
    eq(helper.shown,false,'sibling helper independently hidden')
    local hides=helper.hides
    s.R.Refresh('target');eq(helper.hides,hides,'successful revoke acknowledged')
end)
test('pet foundation defers first combat setup and reuses a partially configured texture',function()
    local s=setup();local h=s:build()
    assert(loadfile('PetPortraits.lua'))('bjarkiPortraits',{Runtime=s.R})
    UnitIsUnit=function()return false end
    UnitIsOtherPlayersPet=function()return true end
    UnitCreatureFamily=function()return 'Owl',26 end
    C_CreatureInfo={GetCreatureFamilyInfo=function()return {name='Owl',iconFile=26626} end}
    local create=h.layer.CreateTexture
    local allocations,layouts,denied=0,0,true
    local texture
    h.layer.CreateTexture=function(...)
        allocations=allocations+1;texture=create(...)
        local layout=texture.SetAllPoints
        texture.SetAllPoints=function(...)
            layouts=layouts+1
            if denied then error('geometry unavailable') end
            return layout(...)
        end
        texture.SetTexture=function(self,icon)self.art=icon;return true end
        return texture
    end
    local fire=installEvents(s)
    s.combat=true
    for i=1,3 do fire('UNIT_NAME_UPDATE','target') end
    eq(type(s.deferred),'function','normal Main recovery is scheduled')
    s.deferred()
    eq(allocations,0,'first combat event cannot allocate');eq(s.R.buildQueued,true)
    s.combat=false;s.R.UpdateObservedPetPortrait('target');s.R.UpdateObservedPetPortrait('target')
    eq(allocations,1,'retry owns original allocation');eq(texture.shown,false,'incomplete stays hidden')
    denied=false;s.R.UpdateObservedPetPortrait('target')
    eq(texture.shown,true);eq(texture.art,26626)
    local complete=layouts;s.combat=true;s.R.UpdateObservedPetPortrait('target')
    eq(allocations,1);eq(layouts,complete,'ready foundation reusable in combat')
end)
test('local pet foundation honors PetFrame owner on immediate and queued event paths',function()
    local s=setup()
    TargetFrame=nil
    PetFrame={unit='pet',Portrait=s.portrait}
    local host=assert(s.R.CreateHost('pet'))
    assert(loadfile('PetPortraits.lua'))('bjarkiPortraits',{Runtime=s.R})
    UnitIsUnit=function(a,b)return a==b end
    UnitClassBase=function()return 'HUNTER' end
    UnitCreatureFamily=function()return 'Owl',26 end
    C_CreatureInfo={GetCreatureFamilyInfo=function()return {iconFile=26626} end}
    local texture
    local create=host.layer.CreateTexture
    host.layer.CreateTexture=function(...)
        texture=create(...);texture.SetTexture=function()return true end;return texture
    end
    local fire=installEvents(s)
    s.combat=true;fire('UNIT_PORTRAIT_UPDATE','pet');s.deferred()
    eq(texture,nil,'first local pet in combat never allocates')
    s.combat=false;fire('PLAYER_REGEN_ENABLED')
    eq(texture.shown,true,'regen presents retained local pet')
    PetFrame.unit='vehicle';fire('UNIT_NAME_UPDATE','pet')
    eq(texture.shown,false,'immediate vehicle event hides pet art')
    s.deferred()
    eq(texture.shown,false,'queued event keeps vehicle native')
    PetFrame.unit='pet';fire('UNIT_PORTRAIT_UPDATE','pet');s.deferred()
    eq(texture.shown,true,'same pet frame recovers on positive binding')
    PetFrame=nil
end)
test('a declined or partial native slot transition repairs the next requested state',function()
    for _,failedMethod in ipairs({'SetEnabled','SetShown'}) do
        for _,denial in ipairs({'false','throws'}) do
            for _,initial in ipairs({false,true}) do
                for _,revert in ipairs({false,true}) do
                    local s=setup();local h=s:build();local active=initial
                    UnitExists=function() return active end
                    s.R.TIERS={{key='FixtureTier'}}
                    local writes,blocked=0,true
                    local group={enabled=initial,shown=initial,_bjarkiAppliedShown=initial}
                    local function setter(method,field)
                        return function(self,value)
                            writes=writes+1
                            if method==failedMethod and blocked then
                                if denial=='throws' then error('set denied') end
                                return false
                            end
                            self[field]=value
                        end
                    end
                    group.SetEnabled=setter('SetEnabled','enabled');group.SetShown=setter('SetShown','shown')
                    h.containers={group};active=not initial
                    s.R.Refresh('target')
                    eq(h._containerWriteFailures,1,'native refusal counted')
                    blocked=false;if revert then active=initial end
                    s.R.Refresh('target')
                    eq(group.enabled,active,'enable agrees with latest request');eq(group.shown,active,'visibility agrees')
                    local committed=writes;s.R.Refresh('target');eq(writes,committed,'completed state has no extra writes')
                end
            end
        end
    end
end)
test('global off in combat revokes independent presentation without mutating native slots',function()
    local s=setup();local R=s.R;local h=s:build()
    local writes=0;local group={enabled=true,shown=true,_bjarkiAppliedShown=true}
    function group:SetEnabled(value) writes=writes+1;self.enabled=value end
    function group:SetShown(value) writes=writes+1;self.shown=value end
    R.TIERS={{key='FixtureTier'}};h.containers={group}
    h.readableGhostFrame:Show()
    assert(loadfile('PetPortraits.lua'))('bjarkiPortraits',{Runtime=R})
    SlashCmdList={};assert(loadfile('Commands.lua'))('bjarkiPortraits',{Runtime=R})
    local fire=installEvents(s)
    s.combat=true;SlashCmdList.BJARKIPORTRAITS('off')
    eq(writes,0,'off defers protected native setters');eq(h.anchor.shown,false,'native presenter hidden')
    eq(h.readableGhostFrame.shown,false,'sibling helper hidden')
    eq(h.portrait.parent,h.layer,'native portrait still owns its visible foundation')
    local hides=h.anchor.hides
    R.Refresh('target');R.RefreshAll();eq(writes,0);eq(h.anchor.hides,hides,'completed hide coalesces')
    s.combat=false;fire('PLAYER_REGEN_ENABLED')
    eq(group.enabled,false);eq(group.shown,false);eq(R.hosts.target,nil);s:restored()
end)
test('off then on in combat stays suspended until safe reconstruction',function()
    local s=setup();local R=s.R;local old=s:build();local writes=0
    old.containers={{SetEnabled=function()writes=writes+1 end,SetShown=function()writes=writes+1 end}}
    assert(loadfile('PetPortraits.lua'))('bjarkiPortraits',{Runtime=R})
    SlashCmdList={};assert(loadfile('Commands.lua'))('bjarkiPortraits',{Runtime=R})
    local fire=installEvents(s)
    s.combat=true;SlashCmdList.BJARKIPORTRAITS('off');SlashCmdList.BJARKIPORTRAITS('on')
    eq(R.hosts.target,old);eq(old.anchor.shown,false);eq(writes,0)
    s.combat=false;fire('PLAYER_REGEN_ENABLED')
    assert(R.hosts.target and R.hosts.target~=old,'re-enabled target must reconstruct')
    eq(old.layer.shown,false);eq(writes,2)
end)
test('rejected forced aura refresh retries without rewriting an already committed slot',function()
    local s=setup();local R=s.R;local h=s:build()
    UnitExists=function()return true end
    R.TIERS={{key='FixtureTier'}}
    local writes,refreshes=0,0
    local slot={_bjarkiAppliedShown=true}
    function slot:SetEnabled()writes=writes+1 end
    function slot:SetShown()writes=writes+1 end
    function slot:UpdateAllAuras()refreshes=refreshes+1;return refreshes~=1 end
    h.containers={slot}
    R.Refresh('target',true);eq(h._containerWriteFailures,1)
    R.Refresh('target');eq(refreshes,2);eq(h._containerWriteFailures,0)
    R.Refresh('target');eq(refreshes,2);eq(writes,0)
    slot._bjarkiAppliedShown=nil -- a partial transition left this enabled state uncertain
    slot.IsEnabled=function()error('enabled state inaccessible')end
    R.Refresh('target',true,true)
    eq(refreshes,3,'binding change reaches the native receiver when old enabled state is unknown')
end)
test('pet-only hosts recover the same and replacement physical portrait on ordinary events',function()
    for _,unit in ipairs({'target','focus'}) do
        for _,kind in ipairs({'same','replacement'}) do
            local s=setup();local R=s.R
            if unit=='focus' then FocusFrame=TargetFrame;TargetFrame=nil end
            R.db[unit]=false;R.db.petPortraits=true
            local h=assert(R.CreateHost(unit));local original=h.unitFrame
            assert(loadfile('PetPortraits.lua'))('bjarkiPortraits',{Runtime=R})
            UnitIsUnit=function()return false end
            UnitIsOtherPlayersPet=function()return true end
            UnitCreatureFamily=function()return 'Owl',26 end
            C_CreatureInfo={GetCreatureFamilyInfo=function()return {iconFile=26626}end}
            local textures={}
            s.captureFoundation=function(layer,texture)
                textures[layer]=texture
                texture.SetTexture=function(_,value)return value==26626 end
            end
            R.UpdateObservedPetPortrait(unit);local old=assert(textures[h.layer]);eq(old.shown,true)
            local nextFrame=original
            local global=unit=='target' and 'TargetFrame' or 'FocusFrame'
            if kind=='same' then
                _G[global]=setmetatable({},{__index=function()error('native metadata unavailable')end})
            else
                local owner=CreateFrame('Frame');local p=owner:CreateTexture()
                p:SetPoint('CENTER',owner,'CENTER',0,0)
                nextFrame={unit=unit,TargetFrameContainer={Portrait=p}};_G[global]=nextFrame
            end
            local fire=installEvents(s)
            fire(unit=='target' and 'PLAYER_TARGET_CHANGED' or 'PLAYER_FOCUS_CHANGED');s.deferred()
            eq(old.shown,false,'old family revoked')
            _G[global]=nextFrame;R.Refresh(unit)
            eq(R.hosts[unit].unitFrame,nextFrame);eq(R.hosts[unit]._staleBinding,nil)
            eq(textures[R.hosts[unit].layer].shown,true,'current physical owner shows family art')
            eq(R.IsUnitEnabled(unit),false,'independent aura toggle preserved')
        end
    end
end)
test('unreadable parent strata member retries without allocating or latching constructor failure',function()
    local s=setup();local getter=s.original.GetFrameStrata
    s.original.GetFrameStrata=nil
    setmetatable(s.original,{__index=function(_,key) if key=='GetFrameStrata' then error('denied member') end end})
    s.R.Refresh('target');eq(s.R.hosts.target,nil);eq(#s.frames,0)
    setmetatable(s.original,nil);s.original.GetFrameStrata=getter
    s.R.Refresh('target');eq(s.R.hosts.target~=nil,true,'next ordinary refresh recovers')
end)
test('settling target and focus binds keep an unreadable new GUID out of the native viewport',function()
    for _,unit in ipairs({'target','focus'}) do
        local s=setup();local R=s.R
        if unit=='focus' then FocusFrame=TargetFrame;TargetFrame=nil end
        local h=assert(R.CreateHost(unit));h.unitFrame.IsVisible=function()return true end
        UnitExists=function(token)return token==unit end
        UnitCanAttack=function()return true end
        UnitIsPlayer=function()return false end
        UnitCanAssist=function()return false end
        UnitIsUnit=function()return false end
        local guid='Creature-A';UnitGUID=function()return guid end
        assert(loadfile('NativeSecondProbe.lua'))('bjarkiPortraits',{Runtime=R})
        R.UpdateObservedPetPortrait=function()end
        local calls=0
        local probe={ready=true,clip=s.original:CreateTexture(),boundUnit=unit,boundGUID=guid,
            cooldowns={},decimals=R.db.showDecimals}
        probe.container={UpdateAllAuras=function()calls=calls+1 end}
        h._nativeSecondProbe=probe
        local fire=installEvents(s)
        fire(unit=='target' and 'PLAYER_TARGET_CHANGED' or 'PLAYER_FOCUS_CHANGED')
        eq(probe.clip.shown,true,'old readable identity still observed at immediate callback')
        local before=calls;guid=nil;s.combat=true;s.deferred()
        eq(probe.clip.shown,false,'unreadable settled binding stays hidden')
        eq(probe.rebindPending,true);eq(calls,before,'no native rebuild during combat')
        R.Refresh(unit);eq(probe.clip.shown,false)
        guid='Creature-B';s.combat=false;R.Refresh(unit)
        eq(probe.boundGUID,guid);eq(probe.clip.shown,true,'positive safe rebound')
        fire(unit=='target' and 'PLAYER_TARGET_CHANGED' or 'PLAYER_FOCUS_CHANGED')
        s.combat=true;s.deferred()
        eq(probe.clip.shown,true,'stable positively matched owner keeps its working ribbon')
    end
end)
test('per-unit combat disable hides aura surfaces, leaves pet foundation and defers native writes',function()
    for _,unit in ipairs({'target','focus','player','pet','targettarget','focustarget','party1'}) do
        local s=setup();local R=s.R
        TargetFrame=nil;local native={unit=unit,Portrait=s.portrait,TargetFrameContainer={Portrait=s.portrait}}
        if unit=='target' then TargetFrame=native elseif unit=='focus' then FocusFrame=native
        elseif unit=='player' then PlayerFrame=native;PlayerPortrait=s.portrait
        elseif unit=='pet' then PetFrame=native
        elseif unit=='targettarget' then TargetFrameToT=native
        elseif unit=='focustarget' then FocusFrameToT=native
        else PartyFrame={GetPartyMemberFrame=function(_,i) if i==1 then return native end end} end
        UnitExists=function(token)return token==unit end
        native.IsShown=function() return true end
        local h=assert(R.CreateHost(unit),unit)
        assert(loadfile('PetPortraits.lua'))('bjarkiPortraits',{Runtime=R})
        UnitIsUnit=function(a,b)return a==b end;UnitIsOtherPlayersPet=function()return true end
        UnitClassBase=function()return 'HUNTER' end;UnitCreatureFamily=function()return 'Owl',26 end
        C_CreatureInfo={GetCreatureFamilyInfo=function()return {iconFile=26626}end}
        local family
        s.captureFoundation=function(_,texture)family=texture;texture.SetTexture=function()return true end end
        R.UpdatePetPortraits()
        if unit~='party1' and unit~='player' then assert(family and family.shown,'eligible family starts visible') end
        local writes=0;local group={enabled=true,shown=true,_bjarkiAppliedShown=true}
        function group:SetEnabled(v)writes=writes+1;if s.combat then return false end;self.enabled=v end
        function group:SetShown(v)writes=writes+1;if s.combat then return false end;self.shown=v end
        function group:UpdateAllAuras() end
        R.TIERS={{key='FixtureTier'}};h.containers={group}
        local public,nativeStrip,petGate=true,true,true
        R.HideSecondaryPortrait=function()public=false end
        R.HideNativeSecondProbe=function()nativeStrip=false end
        R.HidePetSecondaryFallback=function()petGate=false end
        h.testFrame:Show()
        SlashCmdList={};assert(loadfile('Commands.lua'))('bjarkiPortraits',{Runtime=R})
        local fire=installEvents(s)
        local command=unit=='targettarget' and 'tot' or unit=='focustarget' and 'fot' or unit
        s.combat=true;SlashCmdList.BJARKIPORTRAITS(command)
        eq(h.anchor.shown,false,'conceal only native aura region');eq(h.layer.shown,true)
        eq(h.testFrame.shown,false);eq(public,false);eq(nativeStrip,false);eq(petGate,false)
        if family then eq(family.shown,true,'independent family remains visible') end
        local hides=h.anchor.hides
        fire('UNIT_AURA',unit,{});R.Refresh(unit,true,true)
        eq(writes,0,'no repeated combat group writes');eq(h.anchor.hides,hides,'coalesced successful hide')
        s.combat=false;fire('PLAYER_REGEN_ENABLED')
        eq(group.enabled,false);eq(group.shown,false);eq(h.anchor.shown,false)
        SlashCmdList.BJARKIPORTRAITS(command)
        eq(h.anchor.shown,true,'reuse on safe re-enable');eq(group.enabled,true);eq(group.shown,true)
        PetFrame,PlayerPortrait,PartyFrame=nil,nil,nil
    end
end)
test('failed outgoing layer hide retains cleanup ownership through BuildAll and ordinary recovery',function()
    for _,deny in ipairs({'false','throw'}) do
        local s=setup();local R=s.R;local old=s:build()
        local nextParent=CreateFrame('Frame');local p=nextParent:CreateTexture()
        p:SetPoint('CENTER',nextParent,'CENTER',0,0)
        TargetFrame={unit='target',TargetFrameContainer={Portrait=p}}
        local hide=old.layer.Hide
        old.layer.Hide=function()if deny=='throw' then error('old layer unavailable') end;return false end
        R.BuildAll()
        eq(R.hosts.target,old,'outgoing owner retained');eq(old._restorePending,true)
        eq(old.layer.shown,true);eq(old.ownsLayer,true);s:restored()
        old.layer.Hide=hide;R.Refresh('target')
        assert(R.hosts.target and R.hosts.target~=old,'ordinary refresh rebuilds current native frame')
        eq(old.layer.shown,false);eq(R.hosts.target.portrait,p)
    end
end)
test('combat off/on keeps the old aura concealed until the current native refresh succeeds',function()
    local s=setup();local R=s.R;local h=s:build();UnitExists=function(u)return u=='target' end
    local writes,parses,ready=0,0,false
    local group={_bjarkiAppliedShown=true}
    group.SetEnabled=function()writes=writes+1 end;group.SetShown=group.SetEnabled
    group.UpdateAllAuras=function()parses=parses+1;return ready end
    R.TIERS={{key='FixtureTier'}};h.containers={group}
    R.UpdatePetPortraits=function()end;R.UpdateObservedPetPortrait=function()end
    SlashCmdList={};assert(loadfile('Commands.lua'))('bjarkiPortraits',{Runtime=R})
    local fire=installEvents(s);s.combat=true
    SlashCmdList.BJARKIPORTRAITS('target');fire('PLAYER_TARGET_CHANGED');s.deferred()
    SlashCmdList.BJARKIPORTRAITS('target');fire('UNIT_AURA','target',{})
    eq(writes,0);eq(parses,0);eq(h.anchor.shown,false)
    s.combat=false;fire('PLAYER_REGEN_ENABLED')
    eq(h.anchor.shown,false,'a declined refresh cannot expose stale slots')
    ready=true;fire('UNIT_AURA','target',{});eq(h.anchor.shown,true,'ordinary recovery exposes the fresh owner')
end)
test('unchanged combat name and flag callbacks preserve clock styles and forced binding refresh',function()
    local s=setup();local R=s.R;local h=s:build()
    UnitExists=function(u)return u=='target' end
    R.TIERS={{key='FixtureTier'}}
    local parses=0;h.containers={{_bjarkiAppliedShown=true,UpdateAllAuras=function()parses=parses+1 end}}
    R.UpdateObservedPetPortrait=function()end
    local writes=0
    for _,c in ipairs(h.cooldowns) do
        for _,method in ipairs({'SetDrawSwipe','SetHideCountdownNumbers','SetCountdownMillisecondsThreshold'}) do
            c[method]=function()writes=writes+1 end
        end
    end
    R.ApplyPresentation('target')
    for _,c in ipairs(h.cooldowns)do c._bjarkiAlignmentState='centered' end
    writes=0;local fire=installEvents(s);s.combat=true
    fire('UNIT_NAME_UPDATE','target');s.deferred();fire('UNIT_FLAGS','target');s.deferred()
    eq(writes,0,'unchanged native clocks are not restyled in combat')
    eq(h.cooldowns[1]._bjarkiAlignmentState,'centered','keep established alignment')
    assert(parses>0,'requested native binding refreshes still execute')
    local added={};local newWrites=0
    for _,method in ipairs({'SetDrawSwipe','SetHideCountdownNumbers','SetCountdownMillisecondsThreshold'}) do
        added[method]=function()newWrites=newWrites+1 end
    end
    h.cooldowns[#h.cooldowns+1]=added
    fire('UNIT_NAME_UPDATE','target');s.deferred()
    eq(writes,0);eq(newWrites,3,'newly registered clock receives current format')
    R.db.showDecimals=not R.db.showDecimals;R.ApplyPresentation('target')
    assert(writes>0 and newWrites>3,'changed preferences reach all clocks')
    writes,newWrites=0,0
    added.SetDrawSwipe=function()newWrites=newWrites+1;return false end
    R.db.showSwipe=not R.db.showSwipe;fire('UNIT_NAME_UPDATE','target');s.deferred()
    local settled=writes;added.SetDrawSwipe=function()newWrites=newWrites+1 end
    fire('UNIT_NAME_UPDATE','target');s.deferred()
    eq(writes,settled,'retry only the newly refused setting');eq(newWrites,2)
end)
test('native token changes revoke the aura anchor independently and require a fresh positive return',function()
    for _,unit in ipairs({'player','pet','party1'}) do
        for _,wrong in ipairs({'other','unknown'}) do
            local s=setup();local R=s.R;TargetFrame=nil
            local frame={unit=unit,Portrait=s.portrait,IsShown=function()return true end}
            if unit=='player' then PlayerFrame=frame;PlayerPortrait=s.portrait
            elseif unit=='pet' then PetFrame=frame
            else PartyFrame={GetPartyMemberFrame=function(_,n) if n==1 then return frame end end} end
            UnitExists=function(u)return u==unit end
            local h=assert(R.CreateHost(unit))
            assert(loadfile('PetPortraits.lua'))('bjarkiPortraits',{Runtime=R})
            local writes,parses,allow=0,0,false
            local group={_bjarkiAppliedShown=true,shown=true,enabled=true}
            function group:SetEnabled(v) writes=writes+1;if s.combat then return false end;self.enabled=v end
            function group:SetShown(v) writes=writes+1;if s.combat then return false end;self.shown=v end
            function group:UpdateAllAuras()parses=parses+1;return allow end
            R.TIERS={{key='FixtureTier'}};h.containers={group};h.testFrame:Show()
            local fire=installEvents(s);s.combat=true
            if wrong=='unknown' then
                frame.unit=nil
                setmetatable(frame,{__index=function(_,k)if k=='unit' then error('denied token') end end})
            else frame.unit=unit=='party1' and 'player' or 'vehicle' end
            fire('UNIT_PORTRAIT_UPDATE',unit)
            eq(h.anchor.shown,false,'known or suspected wrong occupant is concealed before next tick')
            eq(h.testFrame.shown,false);eq(h.layer.shown,true);eq(s.portrait.parent,h.layer)
            s.deferred();fire('UNIT_AURA',unit,{})
            eq(writes,0,'repeated events never try to disable protected native slots in combat')
            setmetatable(frame,nil);frame.unit=unit;fire('UNIT_AURA',unit,{})
            eq(h.anchor.shown,false,'restored token waits for safe native refresh')
            s.combat=false;fire('PLAYER_REGEN_ENABLED');eq(h.anchor.shown,false,'refused refresh remains concealed')
            allow=true;fire('UNIT_AURA',unit,{});eq(h.anchor.shown,true);assert(parses>0)
            PetFrame,PlayerPortrait,PartyFrame=nil,nil,nil
        end
    end
end)
test('settled OOC countdowns avoid all geometry writes and repair changed native receivers',function()
    local s=setup();local R=s.R;local h=s:build();local clock=h.cooldowns[1]
    local writes,geometryReads,receiverReads=0,0,0;local scale=1;local visible=true
    clock.IsVisible=function()return visible end
    local function observeLayout(region)
        for _,name in ipairs({'ClearAllPoints','SetAllPoints','SetPoint'}) do
            local setter=region[name]
            region[name]=function(self,...)writes=writes+1;return setter(self,...)end
        end
        for _,name in ipairs({'GetNumPoints','GetPoint'}) do
            local getter=region[name]
            region[name]=function(self,...)geometryReads=geometryReads+1;return getter(self,...)end
        end
    end
    local function label()
        local t=s.original:CreateTexture();observeLayout(t)
        t.SetJustifyH=function(self,v)writes=writes+1;self.h=v end
        t.SetJustifyV=function(self,v)writes=writes+1;self.v=v end
        t.SetTextColor=function(self,...)writes=writes+1;self.color={...} end
        t.GetJustifyH=function(self)return self.h end
        t.GetJustifyV=function(self)return self.v end
        t.GetTextColor=function(self)return unpack(self.color) end
        t.GetEffectiveScale=function()return scale end
        return t
    end
    local active=label();observeLayout(clock);clock.GetCountdownFontString=function()receiverReads=receiverReads+1;return active end
    PixelUtil={GetPixelToUIUnitFactor=function()return 1 end}
    R.ApplyPresentation('target');local initial=writes
    assert(initial>0 and active.h=='CENTER' and active.v=='MIDDLE')
    R.UpdateObservedPetPortrait=function()end;local fire=installEvents(s)
    geometryReads=0
    fire('UNIT_NAME_UPDATE','target');s.deferred();fire('UNIT_FLAGS','target');s.deferred()
    eq(writes,initial,'same native layout on normal OOC events')
    eq(geometryReads,0,'steady non-layout events do not walk the current anchors')
    visible=false;receiverReads=0
    fire('UNIT_NAME_UPDATE','target');s.deferred()
    eq(receiverReads,0,'hidden clocks require no font or geometry queries')
    active:ClearAllPoints();active:SetPoint('CENTER',s.original,'CENTER',14,9)
    visible=true;fire('UNIT_AURA','target',{})
    eq(active.points[1][2],clock,'first visible safe refresh repairs layout deferred while hidden')
    active=label();fire('UNIT_NAME_UPDATE','target');s.deferred();eq(active.points[1][2],clock)
    local rebound=writes;R.ApplyPresentation('target',true);eq(writes,rebound)
    active:ClearAllPoints();active:SetPoint('CENTER',s.original,'CENTER',44,19)
    R.ApplyPresentation('target',true);eq(active.points[1][2],clock,'physical anchors repaired')
    active.v='TOP';active.color={.2,.4,.6,1};R.ApplyPresentation('target',true)
    eq(active.v,'MIDDLE');eq(active.color[1],1)
    scale=2;R.ApplyPresentation('target',true);eq(active.points[1][4],1.5,'optical scale recalibrated')
    active.GetEffectiveScale=function()error('temporary scale denial')end
    local confirmed=writes;R.ApplyPresentation('target',true)
    eq(writes,confirmed,'unknown scale preserves the last confirmed offset')
    active.GetEffectiveScale=function()return scale end
    local get=clock.GetCountdownFontString;clock.GetCountdownFontString=function()return nil end
    R.ApplyPresentation('target',true);eq(clock._bjarkiAlignmentState,'label-unavailable')
    active=label();clock.GetCountdownFontString=get;R.ApplyPresentation('target',true)
    eq(active.v,'MIDDLE','temporarily unavailable receiver recovers normally')
    local anchor=s.original:CreateTexture();h.portraitMask=anchor;R.ApplyPresentation('target',true)
    eq(clock.points[1][2],anchor,'changed native reference is applied')
    PixelUtil=nil
end)
test('an unknown layout verification stays pending through the next ordinary event',function()
    local s=setup();local R=s.R;local h=s:build();local c=h.cooldowns[1]
    local label=s.original:CreateTexture()
    c.GetCountdownFontString=function()return label end
    label.SetJustifyH=function(self,v)self.h=v end;label.GetJustifyH=function(self)return self.h end
    label.SetJustifyV=function(self,v)self.v=v end;label.GetJustifyV=function(self)return self.v end
    label.SetTextColor=function()end
    local fire=installEvents(s);R.UpdateObservedPetPortrait=function()end
    R.ApplyPresentation('target');label.points[1][4]=80
    local get=label.GetPoint;label.GetPoint=function()error('temporarily unreadable anchor')end
    fire('UNIT_PORTRAIT_UPDATE','target');s.deferred()
    eq(label.points[1][4],80,'no destructive replay while geometry is unknown')
    assert(c._bjarkiAlignmentState~='centered','denial is not a confirmed alignment')
    label.GetPoint=get;fire('UNIT_NAME_UPDATE','target');s.deferred()
    eq(label.points[1][4],0,'ordinary event retries the unresolved full verification')
    label.v='TOP';local read=label.GetJustifyV;label.GetJustifyV=function()return nil end
    fire('UNIT_PORTRAIT_UPDATE','target');s.deferred();label.GetJustifyV=read
    fire('UNIT_AURA','target',{});eq(label.v,'MIDDLE','a temporarily unreadable style also retries')
end)
test('correct anchors observed after a denied readback do not need another write',function()
    local s=setup();local R=s.R;local h=s:build();local c=h.cooldowns[1]
    local t=s.original:CreateTexture();c.GetCountdownFontString=function()return t end
    local set, get=t.SetAllPoints,t.GetPoint
    local writes,deny=0,false
    t.SetAllPoints=function(self,ref)writes=writes+1;set(self,ref);deny=true end
    t.GetPoint=function(self,i)if deny then deny=false;error('first read unavailable') end;return get(self,i) end
    t.SetJustifyH=function()end;t.SetJustifyV=function()end;t.SetTextColor=function()end
    R.ApplyPresentation('target');eq(writes,1)
    for _=1,10 do R.ApplyPresentation('target',true,true) end
    eq(writes,1,'healthy delayed observation adopts the requested corners')
    eq(c._bjarkiAlignmentState,'centered')
end)
test('two wrong corners cannot confirm a write, and a missing known style getter stays pending',function()
    local s=setup();local R=s.R;local h=s:build();local c=h.cooldowns[1]
    local t=s.original:CreateTexture();c.GetCountdownFontString=function()return t end
    local set=t.SetAllPoints
    t.SetAllPoints=function(self) set(self,s.original) end
    t.SetJustifyH=function()end;t.SetJustifyV=function(self,v)self.v=v end
    local getV=function(self)return self.v end;t.GetJustifyV=getV
    R.ApplyPresentation('target')
    assert(c._bjarkiAlignmentState~='centered','corner count cannot verify a wrong reference')
    t.SetAllPoints=set;R.ApplyPresentation('target',true,true)
    eq(t.points[1][2],c);eq(c._bjarkiAlignmentState,'centered')
    t.v='TOP';t.GetJustifyV=nil;R.ApplyPresentation('target',true,true)
    assert(c._bjarkiAlignmentState~='centered','formerly readable property now unavailable')
    t.GetJustifyV=getV;R.Refresh('target');eq(t.v,'MIDDLE','next safe refresh repairs recovered property')
end)
test('aura bursts schedule one post-native recovery pass only for unresolved clocks and current hosts',function()
    local s=setup();local R=s.R;local interest
    UnitExists=function(unit)return unit=='target' end
    R.TIERS={{key='FixtureTier',filter='HARMFUL',level=10}}
    local create=CreateFrame
    CreateFrame=function(kind,...)
        local frame=create(kind,...)
        if kind=='AuraContainer' then
            frame.SetUnit=function(self,u)self.unit=u end
            frame.UpdateAllAuras=function()end
            function frame:AddAuraSlot(_,_,config)
                local b=create('Frame',nil,self)
                b.SetIcon=function()end
                b.EnableMouse=function()end
                b.SetDurationCooldown=function(_,clock)interest=clock end
                config.initializeFrame(b)
            end
        end
        return frame
    end
    local h=s:build();assert(interest,'native aura slot installed')
    local labels,visits={},{}
    local visible=true
    for _,c in ipairs(h.cooldowns) do
        local l=s.original:CreateTexture();labels[c]=l;visits[c]=0
        l.SetJustifyH=function()end;l.SetJustifyV=function()end;l.SetTextColor=function()end
        c.GetCountdownFontString=function()visits[c]=visits[c]+1;return l end
        c.IsVisible=function()return c~=interest or visible end
    end
    local fire=installEvents(s);R.UpdateObservedPetPortrait=function()end
    local timers={}
    C_Timer.After=function(_,cb)timers[#timers+1]=cb end
    local function tick()local batch=timers;timers={};for _,fn in ipairs(batch)do fn()end end
    R.ApplyPresentation('target')
    fire('UNIT_AURA','target',{});eq(#timers,0,'settled clocks schedule no follow-up')
    visible=false -- native can hide the slot without a name or layout event
    local label=labels[interest];label.points[1][4]=80
    for c in pairs(visits)do visits[c]=0 end
    for i=1,50 do fire('UNIT_AURA','target',{}) end
    eq(#timers,1,'one request per burst');tick()
    visible=true -- native dirty-state processing can happen after the first callback
    eq(#timers,1,'a bounded callback after the native update');tick()
    eq(label.points[1][4],0,'late-visible countdown repaired without another aura event')
    eq(#timers,0,'no self-poll');for c,n in pairs(visits)do if c~=interest then eq(n,0,'settled clock untouched') end end
    visible=false;label.points[1][4]=80
    fire('UNIT_AURA','target',{});tick()
    visible=true
    local before=visits[interest]
    for i=1,10 do fire('UNIT_AURA','target',{}) end
    eq(visits[interest],before,'new events let the outstanding post-native pass repair the clock')
    tick();eq(label.points[1][4],0);eq(#timers,0,'overlapping bursts finish together')
    visible=false;fire('UNIT_NAME_UPDATE','target');tick()
    fire('UNIT_AURA','target',{});tick();local retired=visits[interest]
    R.hosts.target=nil;visible=true;tick();eq(visits[interest],retired,'retired receiver untouched')
end)
test('a different host gets a full native frame even if already-due timers run in reverse order',function()
    local s=setup();local R=s.R
    local target,focus={unit='target'},{unit='focus'}
    R.hosts.target,R.hosts.focus=target,focus
    R.Refresh=function()end
    R.NoteAuraClockVisibility=function(host)host._pendingClockLayouts=true end
    local visible,aligned=false,false
    R.RetryPostAuraLayouts=function(host)
        if host==focus and visible then aligned=true end
    end
    local fire=installEvents(s);local timers={}
    C_Timer.After=function(_,cb)timers[#timers+1]=cb end
    fire('UNIT_AURA','target',{});table.remove(timers,1)()
    fire('UNIT_AURA','focus',{});eq(#timers,2)
    local lateTarget,earlyFocus=timers[1],timers[2];timers={}
    earlyFocus();lateTarget();visible=true
    eq(aligned,false);eq(#timers,1,'independent late pass for Focus')
    table.remove(timers,1)();eq(aligned,true);eq(#timers,0)
end)
test('party native rebind revokes the physical outgoing host independently of the incoming key',function()
    for _,mode in ipairs({'new-slot','no-token','sealed-token'}) do
        local s=setup();local R=s.R;TargetFrame=nil
        local slot=1;local frame={unit='party1',unitToken='party1',Portrait=s.portrait,IsShown=function()return true end}
        PartyFrame={GetPartyMemberFrame=function(_,i)if i==slot then return frame end end}
        UnitExists=function(unit)return unit=='party'..slot end
        local old=assert(R.CreateHost('party1'))
        local hook
        UnitFrame_SetUnit=function(f,u)f.unit=u end;hooksecurefunc=function(name,cb)if name=='UnitFrame_SetUnit' then hook=cb end end
        local fire=installEvents(s);fire('ADDON_LOADED','Blizzard_UnitFrame')
        s.combat=true
        if mode=='new-slot' then slot=2;frame.unitToken='party2';UnitFrame_SetUnit(frame,'party2')
        else
            frame.unitToken=nil;UnitFrame_SetUnit(frame,'vehicle')
            if mode=='sealed-token' then setmetatable(frame,{__index=function(_,key)if key=='unitToken' then error('denied')end end}) end
        end
        hook(frame)
        eq(old.anchor.shown,false,'physical outgoing art already hidden before the settling callback')
        eq(old.layer.shown,true);eq(s.portrait.parent,old.layer)
        s.combat=false;setmetatable(frame,nil)
        if mode=='new-slot' then s.deferred();eq(R.hosts.party2.unitFrame,frame);eq(R.hosts.party1,nil)
        else frame.unit='party1';R.Refresh('party1');eq(old.anchor.shown,true,'original owner reactivates') end
        PartyFrame,UnitFrame_SetUnit,hooksecurefunc=nil,nil,nil
    end
end)
test('landed school interrupts follow the victim and retire on removal, expiry or target recycling',function()
    local s=setup();local R=s.R
    local guid,active,reads,now='victim-A',nil,0,100
    GetTime=function()return now end
    UnitExists=function(unit)return unit=='target' end
    UnitGUID=function(unit)if unit=='target' then return guid end end
    UnitIsUnit=function(a,b)return a==b or (a=='target' and b=='party1') or (a=='party1' and b=='target') end
    assert(loadfile('Interrupts.lua'))('bjarkiPortraits',{Runtime=R})
    C_LossOfControl={
        GetActiveLossOfControlDataCountByUnit=function(unit)
            eq(unit,'target');reads=reads+1;return active and 1 or 0
        end,
        GetActiveLossOfControlDataByUnit=function()return active end,
    }
    local h=s:build()
    local frame=assert(h.schoolInterruptFrame,'missing independent lockout presenter')
    function frame.icon:SetTexture(icon)self.texture=icon;return true end
    function frame.cooldown:SetCooldown(start,duration)self.start=start;self.duration=duration end
    R.UpdateObservedPetPortrait=function()end
    local fire=installEvents(s);local timers={}
    C_Timer.After=function(delay,cb)if delay>0 then timers[#timers+1]=cb end end
    R.Refresh('target',true);local before=reads
    fire('UNIT_AURA','target',{});eq(reads,before,'ordinary aura event does not scan inactive LoC')
    fire('UNIT_SPELLCAST_SUCCEEDED','player');eq(frame.shown,false,'casting Kick is not a landed lockout')
    local refresh,updates=R.Refresh,0
    R.Refresh=function(...)updates=updates+1;return refresh(...)end
    active={locType='STUN',spellID=72,iconTexture=132357,startTime=100,duration=4}
    fire('LOSS_OF_CONTROL_ADDED','target');eq(updates,0,'unrelated control needs no full portrait rebuild')
    before=reads
    active={locType='SCHOOL_INTERRUPT',spellID=1766,iconTexture=132219,startTime=100,duration=4}
    fire('LOSS_OF_CONTROL_ADDED','party1');eq(h._schoolInterrupt.spellID,1766,'alias reaches the victim')
    eq(reads,before+1,'use the event snapshot once')
    eq(frame.icon.texture,132219);eq(frame.cooldown.duration,4);eq(frame.shown,true)
    fire('LOSS_OF_CONTROL_UPDATE','target');eq(#timers,1,'same deadline needs only one wakeup')
    active={locType='SCHOOL_INTERRUPT',spellID=2139,iconTexture=135856,startTime=100,duration=8}
    fire('LOSS_OF_CONTROL_UPDATE','target');now=104;timers[1]()
    eq(frame.shown,true);eq(frame.icon.texture,135856,'old expiry preserves newer lockout')
    now=108;timers[2]();eq(frame.shown,false,'expiry without a subsequent aura event');eq(h._schoolInterrupt,nil)
    active={locType='SCHOOL_INTERRUPT',spellID=6552,iconTexture=132938,startTime=108,duration=4}
    fire('LOSS_OF_CONTROL_ADDED','target');eq(frame.shown,true)
    guid='victim-B';active=nil;fire('UNIT_AURA','target',{});eq(frame.shown,false,'no old target art')
    active={locType='SCHOOL_INTERRUPT',spellID=6552,iconTexture=132938,startTime=108,duration=4}
    fire('LOSS_OF_CONTROL_UPDATE','target');active=nil;fire('LOSS_OF_CONTROL_UPDATE','target')
    eq(frame.shown,false,'server removal immediately releases the portrait')
    C_Timer.After=function()return false end
    active={locType='SCHOOL_INTERRUPT',spellID=72,iconTexture=132357,startTime=108,duration=4}
    fire('LOSS_OF_CONTROL_ADDED','target');eq(frame.shown,true)
    now=113;fire('UNIT_AURA','target',{});eq(frame.shown,false,'a refused expiry callback cannot pin an expired lockout')
    local clears=0
    frame.cooldown.Clear=function()clears=clears+1 end
    active={locType='SCHOOL_INTERRUPT',spellID=19647,iconTexture=136174}
    fire('LOSS_OF_CONTROL_ADDED','target');eq(frame.shown,true,'confirmed active effect keeps its art without a clock')
    eq(frame.icon.texture,136174);eq(clears,1,'old countdown cleared')
    fire('UNIT_AURA','target',{});eq(clears,1,'same clockless effect avoids repaint')
    active=nil;fire('UNIT_AURA','target',{});eq(frame.shown,false,'clockless evidence is revalidated')
    local get=C_LossOfControl.GetActiveLossOfControlDataByUnit
    active={locType='SCHOOL_INTERRUPT',spellID=1766,iconTexture=132219,startTime=113,duration=8}
    C_LossOfControl.GetActiveLossOfControlDataByUnit=function()error('restricted this event')end
    fire('LOSS_OF_CONTROL_ADDED','target')
    eq(h._schoolInterrupt,nil,'unreadable addition paints nothing')
    local deniedReads=reads
    for n=1,12 do fire('UNIT_AURA','target',{}) end
    assert(reads>deniedReads and reads<=deniedReads+3,'bounded ordinary retries after an unknown addition')
    fire('LOSS_OF_CONTROL_UPDATE','target')
    C_LossOfControl.GetActiveLossOfControlDataByUnit=get
    fire('UNIT_AURA','target',{});eq(frame.shown,true,'ordinary update recovers pending positive')
    local primary=h._schoolInterrupt
    local paints=0;local setTexture=frame.icon.SetTexture
    frame.icon.SetTexture=function(...)paints=paints+1;return setTexture(...)end
    fire('LOSS_OF_CONTROL_UPDATE','target');R.Refresh('target',true)
    eq(h._schoolInterrupt,primary,'stable occurrence survives public re-observation')
    eq(paints,0,'same school record performs no primary texture writes')
    local extra={locType='SCHOOL_INTERRUPT',spellID=72,iconTexture=132357,startTime=112,duration=4}
    C_LossOfControl.GetActiveLossOfControlDataCountByUnit=function()return extra and 2 or 1 end
    C_LossOfControl.GetActiveLossOfControlDataByUnit=function(_,i)if i==1 then return active else return extra end end
    C_Timer.After=function(delay,cb)if delay>0 then timers[#timers+1]=cb end end
    fire('LOSS_OF_CONTROL_UPDATE','target')
    eq(h._schoolInterrupt,primary,'unchanged main survives runner arrival')
    eq(h._secondSchoolInterrupt.spellID,72,'two overlapping schools reach their presenters')
    eq(h._schoolInterruptDeadline,116,'earlier runner expiry also schedules a wakeup')
    now=116;timers[#timers]();eq(h._secondSchoolInterrupt,nil,'runner retires without another aura event')
    eq(h._schoolInterrupt,primary,'primary clock continues unchanged')
    guid='victim-C';R.Refresh('target');assert(h._schoolInterrupt~=primary,'recycled target cannot inherit occurrence identity')
    active={locType='SCHOOL_INTERRUPT',spellID=2139,iconTexture=135856,startTime=116,duration=8}
    frame.cooldown.SetCooldown=function()return false end
    fire('LOSS_OF_CONTROL_UPDATE','target');local same=h._schoolInterrupt
    local transported
    local recoveredClock={}
    frame.cooldown.SetCooldownFromDurationObject=function(_,object)transported=object;return true end
    C_LossOfControl.GetActiveLossOfControlDuration=function()return recoveredClock end
    fire('LOSS_OF_CONTROL_UPDATE','target');eq(transported,recoveredClock,'new native clock repairs a previously declined numeric timer')
    eq(h._schoolInterrupt,same,'upgrading the clock preserves the proven occurrence')
    active={locType='SCHOOL_INTERRUPT',spellID=6552,iconTexture=132938}
    extra=nil;local object={};C_LossOfControl.GetActiveLossOfControlDuration=function()return object end
    frame.cooldown.SetCooldownFromDurationObject=function()return true end
    fire('LOSS_OF_CONTROL_ADDED','target');eq(frame.shown,true)
    UnitIsUnit=function()error('unresolved alias')end
    C_LossOfControl.GetActiveLossOfControlDataCountByUnit=function()return 0 end
    fire('LOSS_OF_CONTROL_UPDATE','nameplate1');eq(frame.shown,false,'opaque clock cannot strand art on unresolved alias removal')
    UnitIsUnit,UnitGUID,C_LossOfControl=nil,nil,nil
end)

local function interruptScene(unit)
    local s=setup();local R=s.R
    if unit=="focus" then FocusFrame=TargetFrame;FocusFrame.unit=unit;TargetFrame=nil end
    s.now,s.reads,s.textures,s.clocks,s.self=100,0,0,0,false
    GetTime=function()return s.now end
    UnitExists=function(u)return u==unit end
    UnitGUID=function()return s.guid end
    UnitIsUnit=function(a,b)if a==b then return true end;if b=="player" then return s.self end;return false end
    assert(loadfile("Interrupts.lua"))("bjarkiPortraits",{Runtime=R})
    C_LossOfControl={GetActiveLossOfControlDataCountByUnit=function(u)
        if u==unit then s.reads=s.reads+1;return s.row and 1 or 0 end
        return 0
    end,GetActiveLossOfControlDataByUnit=function(u)if u==unit then return s.row end end,
    GetActiveLossOfControlDataCount=function()return s.playerRow and 1 or 0 end,
    GetActiveLossOfControlData=function()return s.playerRow end,
    GetActiveLossOfControlDuration=function(u)if u==unit then return s.object end end}
    s.h=assert(R.CreateHost(unit));s.frame=s.h.schoolInterruptFrame
    s.frame.icon.SetTexture=function(_,art)s.textures=s.textures+1;s.art=art;return true end
    s.frame.cooldown.SetCooldown=function()s.clocks=s.clocks+1 end
    s.frame.cooldown.SetCooldownFromDurationObject=function(_,o)s.clocks=s.clocks+1;s.bound=o end
    R.UpdateObservedPetPortrait=function()end
    s.fire=installEvents(s);R.Refresh(unit,true)
    return s
end
local function lock(school)
    return {locType="SCHOOL_INTERRUPT",spellID=1766,iconTexture=22,startTime=99,duration=5,lockoutSchool=school}
end
test("queued combat-exit build performs one forced reconciliation",function()
    for _,queued in ipairs({false,true}) do
        local s=interruptScene("target")
        s.guid="recipient";s.row=lock(4)
        s.fire("LOSS_OF_CONTROL_ADDED","target")
        eq(s.frame.shown,true)
        local passes,forced=0,0
        local relation,refresh=s.R.HostileUnitState,s.R.RefreshAll
        s.R.HostileUnitState=function(unit,...)
            if unit=="target" then passes=passes+1 end
            return relation(unit,...)
        end
        s.R.RefreshAll=function(force,...)
            if force then forced=forced+1 end
            return refresh(force,...)
        end
        s.R.buildQueued=queued;s.row=nil
        s.R.UpdatePetPortraits=function()end
        s.fire("PLAYER_REGEN_ENABLED")
        eq(s.frame.shown,false,"forced pass releases the expired presentation")
        eq(forced,1,"one forced refresh")
        eq(passes,1,"one complete pass for the existing target")
    end
end)
test('unknown Target/Focus aliases recover additions and remove bounded locks using only their own recipient',function()
    for _,unit in ipairs({'target','focus'}) do
        local s=interruptScene(unit);s.guid="recipient";s.self=false
        s.playerRow=lock(4)
        local before=s.reads;s.fire('LOSS_OF_CONTROL_ADDED','player')
        eq(s.reads,before,'known foreign recipient costs no reads')
        s.self=nil;s.fire('LOSS_OF_CONTROL_ADDED','player')
        before=s.reads
        for i=1,12 do s.fire('UNIT_AURA',unit) end
        assert(s.reads-before<=2,'unresolved event does not cause repeated LoC enumeration')
        eq(s.frame.shown,false,'player data never leaks through unknown alias')
        s.self=true;s.fire('UNIT_AURA',unit)
        eq(s.frame.shown,true,'self identity recovered after bounded native retries')
        s.playerRow=nil;s.self=nil;s.fire('LOSS_OF_CONTROL_UPDATE','player')
        eq(s.frame.shown,false,'an ambiguous alias removal rechecks even before the public deadline')
        s.self=false;s.row=lock(16);s.fire('LOSS_OF_CONTROL_ADDED',unit);before=s.reads
        s.fire('LOSS_OF_CONTROL_UPDATE','player')
        eq(s.reads,before,'known foreign removal leaves a real target lock alone')
        eq(s.frame.shown,true)
        s=interruptScene(unit);s.self=nil;s.playerRow=lock(4)
        s.fire('LOSS_OF_CONTROL_ADDED',unit)
        before=s.reads
        for n=1,9 do s.fire('UNIT_AURA',unit) end
        assert(s.reads-before<=2,'direct event with unknown self keeps bounded source reads')
        s.self=true;s.fire('UNIT_AURA',unit)
        eq(s.frame.shown,true,'a direct unit event can also wait for its own self identity')
    end
end)
test('a bounded sealed-GUID clock stays stable until a real target binding or expiry barrier',function()
    for _,unit in ipairs({'target','focus'}) do
        local s=interruptScene(unit);s.self=false;s.guid={};issecretvalue=function(x)return rawequal(x,s.guid)end
        s.row=lock(4);s.object={};s.fire('LOSS_OF_CONTROL_ADDED',unit)
        local reads,paints,clocks=s.reads,s.textures,s.clocks
        for n=1,10 do s.fire('UNIT_AURA',unit) end
        eq(s.reads,reads,'stable event-bound public interval requires no scans')
        eq(s.textures,paints,'stable restricted-GUID texture');eq(s.clocks,clocks,'stable restricted-GUID clock')
        for n=1,5 do s.fire('LOSS_OF_CONTROL_UPDATE',unit) end
        eq(s.textures,paints,'fresh own evidence can keep identical art')
        eq(s.clocks,clocks,'the same verified native receiver does not rebind')
        s.object=nil;s.fire('LOSS_OF_CONTROL_UPDATE',unit);local numeric=s.clocks
        for n=1,5 do s.fire('LOSS_OF_CONTROL_UPDATE',unit) end
        eq(s.clocks,numeric,'identical positive numeric display does not rebind')
        local old=s.h._schoolInterrupt
        s.row=lock(16);s.object={}
        s.fire(unit=='target' and 'PLAYER_TARGET_CHANGED' or 'PLAYER_FOCUS_CHANGED')
        assert(s.reads>reads and s.h._schoolInterrupt~=old,'real binding is independently acquired')
        eq(s.h._schoolInterrupt.lockoutSchool,16);eq(s.bound,s.object,'replacement native clock is bound')
        s.row=nil;s.deferred();eq(s.frame.shown,false,'settled new recipient can revoke the immediate observation')
    end
end)
test('a changed school mask invalidates the prior native duration even on the same known victim',function()
    local s=interruptScene('target');s.guid='recipient';s.self=false;s.row=lock(4);s.object={}
    s.fire('LOSS_OF_CONTROL_ADDED','target');local old=s.h._schoolInterrupt
    s.row=lock(16);s.object={};s.fire('LOSS_OF_CONTROL_UPDATE','target')
    eq(s.h._schoolInterrupt.lockoutSchool,16);assert(s.h._schoolInterrupt~=old)
    eq(s.bound,s.object,'contradictory school requires fresh binding')
    s.object={};s.fire('PLAYER_TARGET_CHANGED')
    eq(s.bound,s.object,'a true binding barrier reinstalls the clock even when the GUID and public interval match')
end)
test('completed native Target and Focus rebinds immediately retire a former sealed-GUID interrupt',function()
    for _,unit in ipairs({'target','focus'}) do
        local s=interruptScene(unit);s.self=false;s.row=lock(4)
        s.fire('LOSS_OF_CONTROL_ADDED',unit);eq(s.frame.shown,true)
        local notify;UnitFrame_SetUnit=function(f,u)f.unit=u end
        hooksecurefunc=function(name,fn)if name=='UnitFrame_SetUnit' then notify=fn end end
        s.fire('ADDON_LOADED','Blizzard_UnitFrame');assert(notify)
        s.row=nil;local physical=s.h.unitFrame
        UnitFrame_SetUnit(physical,unit);notify(physical)
        eq(s.frame.shown,false,'completed native assignment cannot keep the former lock')
        s.row=lock(16);s.deferred();eq(s.frame.shown,true,'settled native assignment discovers new current lock')
        UnitFrame_SetUnit(physical,'vehicle');notify(physical)
        eq(s.frame.shown,false,'unsupported physical token retires its former timer')
        hooksecurefunc,UnitFrame_SetUnit=nil,nil
    end
end)
test('a rejected or early expiry callback can rearm on the next safe opportunity',function()
    local s=interruptScene('target');s.guid='recipient';s.self=false;s.row=lock(4)
    local ready=false;local timers={}
    C_Timer.After=function(delay,fn)
        if delay>0 then if not ready then return false end;timers[#timers+1]={delay,fn} end
    end
    s.fire('LOSS_OF_CONTROL_ADDED','target');eq(#timers,0)
    ready=true;s.now=101;s.fire('UNIT_AURA','target')
    eq(#timers,1,'accepted replacement for denied wakeup');eq(timers[1][1],3)
    s.now=102;timers[1][2]();eq(#timers,2,'early callback rearms only the remaining interval');eq(timers[2][1],2)
    local reads=s.reads;timers[2][2]();eq(#timers,2,'repeated early timers cannot self-poll')
    eq(s.reads,reads,'a repeated early timer does no native LoC reads')
    s.fire('UNIT_AURA','target');eq(#timers,3,'existing event supplies a new scheduling opportunity')
    s.now=104;timers[3][2]();eq(s.frame.shown,false,'idle clock retires at the true deadline')
    local inline=0;s.now=100;s.row=lock(4)
    C_Timer.After=function(delay,fn)if delay>0 then inline=inline+1;fn() end end
    s.fire('LOSS_OF_CONTROL_ADDED','target');eq(inline,1,'inline early wake cannot recurse')
    s.now=104;s.fire('UNIT_AURA','target');eq(s.frame.shown,false,'inline scheduler cannot pin expired art')
end)
test('self-backed identity, clock and runner revalidate when Target or Focus stops being player',function()
    for _,unit in ipairs({'target','focus'})do for _,part in ipairs({'main','numeric','object','runner'}) do
        local s=interruptScene(unit);s.guid=nil;s.self=true;s.playerRow=lock(4)
        if part=='numeric' or part=='object' then
            s.row=lock(4);s.row.auraInstanceID=22;s.row.duration=nil
            s.playerRow.auraInstanceID=22;s.playerRow.startTime=nil
            if part=='object' then
                -- This getter on the current token has no object; the corroborated player slot does.
                C_LossOfControl.GetActiveLossOfControlDuration=function(u)if u=='player' then return s end end
            end
        elseif part=='runner' then s.row=lock(16);s.row.spellID=72;s.row.startTime=100 end
        s.fire('LOSS_OF_CONTROL_ADDED','player')
        assert(s.frame.shown and (part~='runner' or s.h._secondSchoolInterrupt))
        s.fire(unit=='target' and 'PLAYER_TARGET_CHANGED' or 'PLAYER_FOCUS_CHANGED');s.deferred()
        local reads=s.reads;s.fire('UNIT_AURA',unit);eq(s.reads,reads,'confirmed stable alias remains cheap')
        s.self=false;s.fire('UNIT_AURA',unit);assert(s.reads>reads,'late self contradiction rereads current recipient')
        if part=='main' then eq(s.frame.shown,false,'no foreign art')
        elseif part=='runner' then eq(s.h._secondSchoolInterrupt,nil);eq(s.h._schoolInterrupt.spellID,72)
        else eq(s.h._schoolInterrupt.expires,nil,'foreign numeric timing removed');eq(s.h._schoolInterrupt.durationObject,nil,'foreign native handle removed') end
    end end
end)
test('current native clock replacements and unchanged restricted GUID reports use the installed receiver',function()
    local s=interruptScene('target');s.guid='A';s.row=lock(4);s.object={};s.fire('LOSS_OF_CONTROL_ADDED','target')
    s.object={};s.fire('LOSS_OF_CONTROL_UPDATE','target')
    eq(s.bound,s.object,'bounded clock receives replacement object')
    local clocks=s.clocks;s.object=nil;s.fire('LOSS_OF_CONTROL_UPDATE','target')
    eq(s.h._schoolInterruptClockSource,'numeric','withdrawn object replaced by public numeric clock')
    eq(s.clocks,clocks+1);s.object={};s.fire('LOSS_OF_CONTROL_UPDATE','target')
    eq(s.clocks,clocks+1,'unchanged numeric sink needs no native rebind')
    s.guid=nil;s.fire('LOSS_OF_CONTROL_UPDATE','target')
    local passes=0;local relation=s.R.HostileUnitState
    s.R.HostileUnitState=function(...)passes=passes+1;return relation(...)end
    for i=1,12 do s.fire('LOSS_OF_CONTROL_UPDATE','target') end
    eq(passes,0,'identical own snapshots do not repeat the entire host election')
    s.row=lock(16);s.fire('LOSS_OF_CONTROL_UPDATE','target');eq(passes,1,'a real change still updates the full host')
end)
test('player-only notifications revoke contradicted self evidence without scanning unrelated recipients',function()
    for _,unit in ipairs({'target','focus'}) do for _,event in ipairs({'UNIT_AURA','LOSS_OF_CONTROL_UPDATE'}) do
        local s=interruptScene(unit);s.self=true;s.playerRow=lock(4)
        s.fire('LOSS_OF_CONTROL_ADDED','player');eq(s.frame.shown,true)
        s.self=false;local reads=s.reads
        s.fire(event,'player')
        eq(s.frame.shown,false,'former alias revokes player-backed lockout on '..event)
        assert(s.reads>reads)
        s.row=lock(16);s.fire('LOSS_OF_CONTROL_ADDED',unit);reads=s.reads
        s.fire(event,'player')
        eq(s.frame.shown,true);eq(s.reads,reads,'independent target gets no player-driven LoC reads')
    end end
end)
test('independently reconfirmed art-only reports preserve a cleared receiver between real barriers',function()
    for _,known in ipairs({true,false}) do
        local s=interruptScene('target');s.guid=known and 'recipient' or nil
        s.row={locType='SCHOOL_INTERRUPT',spellID=1766,lockoutSchool=4,iconTexture=22}
        s.fire('LOSS_OF_CONTROL_ADDED','target')
        local passes=0;local relation=s.R.HostileUnitState
        s.R.HostileUnitState=function(...)passes=passes+1;return relation(...)end
        local paints=s.textures;local reads=s.reads
        for i=1,10 do s.fire('LOSS_OF_CONTROL_UPDATE','target') end
        eq(s.reads-reads,10,'unbounded art is still verified every time')
        eq(s.textures,paints,'identical verified art is not rewritten');eq(passes,0,'no repeated full election')
        s.row.lockoutSchool=16;s.fire('LOSS_OF_CONTROL_UPDATE','target');eq(passes,1,'changed school forces new election')
        s.fire('PLAYER_TARGET_CHANGED');assert(s.textures>paints,'physical binding barrier reinstalls art')
    end
end)
test('overflow recovery rereads the current token once and old alias watches end on binding turnover',function()
    local s=interruptScene('target');s.guid='A'
    local readable,checks=false,0
    UnitIsUnit=function(a,b)
        if b=='player' then return false end
        if b:match('^nameplate') then checks=checks+1;if readable then return b=='nameplate1' end end
        return a==b or nil
    end
    for i=1,12 do s.fire('LOSS_OF_CONTROL_ADDED','nameplate'..i) end
    for i=1,5 do s.fire('UNIT_AURA','target') end
    assert(#s.h._schoolInterruptAliasPending<=8)
    readable=true;s.row=lock(4);local before=s.reads;s.fire('UNIT_AURA','target')
    eq(s.frame.shown,true,'evicted real alias recovered on a bounded own-token pass');eq(s.reads-before,1)
    readable=false;for i=1,8 do s.fire('LOSS_OF_CONTROL_ADDED','nameplate'..i) end
    s.guid='B';s.row=nil;s.fire('PLAYER_TARGET_CHANGED');s.deferred()
    checks=0;before=s.reads;for i=1,20 do s.fire('UNIT_AURA','target') end
    eq(checks,0,'new recipient does not check old names');eq(s.reads,before,'complete new recipient has no inherited retries')
end)
test('an evicted alias can recover while all retained identity checks stay restricted',function()
    local s=interruptScene('target');s.guid='A'
    local evictedResolved=false
    UnitIsUnit=function(a,b)if a==b then return true end;if b=='player' then return false end
        if b=='nameplate1' and evictedResolved then return true end end
    for i=1,9 do s.fire('LOSS_OF_CONTROL_ADDED','nameplate'..i) end
    for i=1,4 do s.fire('UNIT_AURA','target') end
    local r=s.reads;for i=1,8 do s.fire('UNIT_AURA','target') end
    assert(s.reads-r<=8,'one native count per ordinary event for an overflowed empty list')
    evictedResolved=true;s.row=lock(4);s.fire('UNIT_AURA','target')
    eq(s.frame.shown,true,'own positive recovered without resolving any retained sender')
    r=s.reads;for i=1,8 do s.fire('UNIT_AURA','target') end
    assert(s.reads-r<=10,'an already verified overflow positive never forces repeated full acquisition')
end)
test('losing self releases exclusions for a cached empty, primary or runner election',function()
    for _,unit in ipairs({'target','focus'}) do for _,route in ipairs({'own','player-aura','player-loc'}) do
        for _,survivors in ipairs({0,1,2}) do
            local s=interruptScene(unit);s.self=true;s.guid=nil;s.now=105
            local kick={locType='SCHOOL_INTERRUPT',spellID=1766,iconTexture=22,startTime=100,auraInstanceID=22}
            local own={kick};s.playerRow={locType='SCHOOL_INTERRUPT',spellID=1766,iconTexture=22,duration=4,auraInstanceID=22}
            if survivors>=1 then own[#own+1]={locType='SCHOOL_INTERRUPT',spellID=6552,iconTexture=33,startTime=99,duration=10} end
            if survivors==2 then own[#own+1]={locType='SCHOOL_INTERRUPT',spellID=72,iconTexture=45,startTime=102,duration=9} end
            C_LossOfControl.GetActiveLossOfControlDataCountByUnit=function(u)if u==unit then s.reads=s.reads+1;return #own end;return 0 end
            C_LossOfControl.GetActiveLossOfControlDataByUnit=function(u,i)if u==unit then return own[i] end end
            s.fire('LOSS_OF_CONTROL_ADDED','player');eq(s.frame.shown,survivors>0)
            if survivors>0 then eq(s.h._schoolInterrupt.spellID,survivors==1 and 6552 or 72) end
            s.self=false;local reads=s.reads
            s.fire(route=='player-loc' and 'LOSS_OF_CONTROL_UPDATE' or 'UNIT_AURA',route=='own' and unit or 'player')
            assert(s.reads>reads,'lost excluding witness requires fresh own evidence even with no surviving record')
            eq(s.h._schoolInterrupt.spellID,survivors==2 and 72 or 1766)
            if survivors==2 then eq(s.h._secondSchoolInterrupt.spellID,1766,'former-self exclusion only altered runner') end
            reads=s.reads;s.fire('LOSS_OF_CONTROL_UPDATE','player');eq(s.reads,reads,'cleared rank dependency restores isolation')
        end
    end end
end)
test('overflow proves removal after a complete public rotation and ignores a stale earlier occurrence',function()
    for _,kind in ipairs({'stun','expired-old','unknown'}) do
        local s=interruptScene('target');s.guid='A'
        UnitIsUnit=function(u,v)if u==v then return true end;if v=='player' then return false end end
        local live=lock(4);live.auraInstanceID=22;live.duration=8
        local stale=lock(4);stale.auraInstanceID=11;stale.startTime=91;stale.duration=4
        local rows={live,stale};local indexed=0
        C_LossOfControl.GetActiveLossOfControlDataCountByUnit=function(u)if u=='target' then s.reads=s.reads+1;return #rows end;return 0 end
        C_LossOfControl.GetActiveLossOfControlDataByUnit=function(_,i)indexed=indexed+1;local d=rows[i];if d==false then error('denied')end;return d end
        s.fire('LOSS_OF_CONTROL_ADDED','target')
        for i=1,9 do s.fire('LOSS_OF_CONTROL_UPDATE','nameplate'..i) end
        for i=1,5 do s.fire('UNIT_AURA','target') end
        if kind=='stun' then rows={{locType='STUN',spellID=853},{locType='SILENCE',spellID=15487}}
        elseif kind=='unknown' then rows={{locType='STUN',spellID=853},false} end
        local c,n=s.reads,indexed
        for i=1,20 do s.fire('UNIT_AURA','target') end
        eq(s.frame.shown,kind~='stun','complete rotation distinguishes absent from unavailable')
        if kind=='expired-old' then eq(s.reads-c,20,'one count per unchanged event');eq(indexed-n,20,'one row per unchanged event') end
    end
end)
assert(#failures == 0, table.concat(failures, '\n'))
print('bjarkiPortraits restoration: ' .. passed .. ' scenarios passed')
