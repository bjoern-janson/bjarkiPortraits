-- Offline UI boundary model; the shipped constructors and lifecycle run unchanged.
-- Catches lost recovery ownership, hidden native art and nested retry ownership.
unpack = unpack or table.unpack -- WoW compatibility global on the Lua 5.4 model.
local function eq(actual, expected, label)
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
        function r:CreateTexture() return region(self) end
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
local function test(name, body)
    local ok, err = pcall(body)
    if ok then passed=passed+1; print('PASS ' .. name)
    else failures[#failures+1]=name .. ': ' .. tostring(err); print('FAIL ' .. failures[#failures]) end
end

test('normal teardown restores parent and every point exactly once', function()
    local s=setup(); local host=s:build()
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

assert(#failures == 0, table.concat(failures, '\n'))
print('bjarkiPortraits restoration: ' .. passed .. ' scenarios passed')
