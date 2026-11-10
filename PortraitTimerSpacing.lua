-- Each character has its own centered native DurationTextBinding. Lua only
-- samples public constants while building glyph rules; it never reads a clock.
local _,BP=...
local R=BP.Runtime
local states=setmetatable({},{__mode="k"})
local formats=setmetatable({},{__mode="k"})
local probe
local metricCache,metricKeys,metricSlot={},{},1
local bridgeProbe,bridgeReady,bridgeEpoch
local function readable(v)return R.CanAccess(v) end
local function accessible(v)assert(readable(v),"unreadable value");return v end
local function accepted(v)assert(accessible(v)~=false,"native method declined");return true end
local function field(o,k)
    if not readable(o) or o==nil then return end
    local ok,v=pcall(function()return o[k]end)
    if ok and readable(v) then return v end
end
local function method(o,k)local v=field(o,k);if type(v)=="function"then return v end end
local function call(o,k,...)
    local fn=method(o,k);if not fn then return false end
    local ok,v=pcall(fn,o,...);return ok and readable(v) and v~=false
end
local function outOfCombat()
    local v,known=R.SafeBool(InCombatLockdown);return known and not v
end
local function number(v)return readable(v) and type(v)=="number" and v==v and v>-math.huge and v<math.huge end
local function positive(v)return number(v) and v>0 end
local function safe(o)
    if not readable(o) or not o then return false end
    local fn=method(o,"IsForbidden")
    if not fn then return true end
    local ok,v=pcall(fn,o);return ok and readable(v) and v==false
end
-- Preserve the client's actual printf rounding, including ties, 10.0 just
-- below ten, and the last visible second at the native formatter's precision.
local function readSamples(base)
    local limit,hideAt=R.PORTRAIT_TIMER_LIMIT,R.PORTRAIT_TIMER_HIDE_AT
    local points,seen={},{}
    local function add(value)
        if not seen[value] then points[#points+1]=value;seen[value]=true end
    end
    add(0)
    local function boundary(x)
        local scale=2^math.floor(math.log(x)/math.log(2))
        if scale>x then scale=scale/2 elseif 2*scale<=x then scale=scale*2 end
        local step=scale*2^-52
        add(x-(x==scale and step/2 or step))
        add(x)
        add(x+step)
        -- Some native number paths can quantize both the input and rule to
        -- binary32. Adjacent Lua doubles would all probe the same native time.
        local floatStep=scale*2^-23
        local units=x/floatStep
        local nearest=math.floor(units)
        local fraction=units-nearest
        if fraction>0.5 or (fraction==0.5 and nearest%2~=0) then nearest=nearest+1 end
        local center=nearest*floatStep
        add(center-(center==scale and floatStep/2 or floatStep))
        add(center)
        add(center+(center==2*scale and 2*floatStep or floatStep))
    end
    if R.db and R.db.showDecimals then
        for tenth=1,100 do boundary((2*tenth-1)/20) end
    end
    for second=1,limit do boundary(second) end
    boundary(hideAt)
    table.sort(points)
    local texts={}
    for i,value in ipairs(points) do
        local text=accessible(base:FormatNumber(value))
        assert(type(text)=="string" and (text=="" or text:match("^%d%d?$") or text:match("^%d%d?[.,]%d$")),
            "unsupported native countdown format")
        if value==limit then assert(text==tostring(limit),"native formatter hid the last visible second") end
        if value>=hideAt then assert(text=="","native formatter exceeded the portrait timer limit") end
        texts[i]=text
    end
    -- These interior values never select a breakpoint. They independently
    -- check that a rule did not accidentally retain a neighboring glyph.
    local interior={9.999,limit+0.1,limit+1,48*60}
    if R.db and R.db.showDecimals then
        for tenth=0,99 do
            interior[#interior+1]=(tenth+0.25)/10
            interior[#interior+1]=(tenth+0.75)/10
        end
    end
    for second=0,limit-1 do interior[#interior+1]=second+0.5 end
    local expected={}
    for i,value in ipairs(interior) do expected[i]=accessible(base:FormatNumber(value)) end
    return {points=points,texts=texts,interior=interior,expected=expected}
end

-- Cell order: decimal tens, ones, separator, tenths; whole tens and ones.
-- Match bjarkiUI's centered decimal and slightly right-shifted whole tracks.
local function glyphs(text)
    if text=="" then return {"","","","","",""} end
    local whole,point,fraction=text:match("^(%d%d?)([.,])(%d)$")
    if whole then return {#whole==2 and whole:sub(1,1) or "",whole:sub(-1),point,fraction,"",""} end
    assert(text:match("^%d%d?$"),"unsupported glyph vocabulary")
    if #text==1 then return {"","",text,"","",""} end
    return {"","","","",#text==2 and text:sub(1,1) or "",text:sub(-1)}
end
local function buildFormats(base)
    local samples=readSamples(base)
    local rules,previous,result={},{},{}
    for i=1,6 do rules[i]={} end
    for n,value in ipairs(samples.points)do
        local chars=glyphs(samples.texts[n])
        for i=1,6 do
            if chars[i]~=previous[i]then
                rules[i][#rules[i]+1]={threshold=value,format=chars[i]};previous[i]=chars[i]
            end
        end
    end
    for i=1,6 do
        local f=accessible(C_StringUtil.CreateNumericRuleFormatter())
        accepted(f:SetBreakpoints(rules[i]));result[i]=f
    end
    local function check(value,text)
        local chars=glyphs(text)
        for i=1,6 do assert(accessible(result[i]:FormatNumber(value))==chars[i],"native glyph rule mismatch")end
    end
    for i,v in ipairs(samples.points)do check(v,samples.texts[i])end
    for i,v in ipairs(samples.interior)do check(v,samples.expected[i])end
    return result
end
local function currentFormats()
    local base=R.GetCountdownFormatter()
    if not safe(base)then return end
    local saved=formats[base]
    if saved and (saved.value or saved.epoch==R.countdownFormatterEpoch)then return saved.value end
    if not outOfCombat()then return end
    saved={epoch=R.countdownFormatterEpoch};formats[base]=saved
    local ok,v=pcall(buildFormats,base);if ok then saved.value=v end
    return saved.value
end
local function deactivate(state)
    -- Hide our own group first: even a refused binding shutdown cannot repaint
    -- a stale digit above the ordinary countdown during fallback.
    local hidden=not state.group or call(state.group,"Hide")
    for i,b in ipairs(state.bindings)do
        call(b,"SetEnabled",false)
        local cell=state.cells[i]
        if cell then call(cell,"SetText","");if not hidden then call(cell,"Hide")end end
    end
    state.active=false;state.bound=nil;state.hidden=nil
    return hidden
end
local function getState(cd)
    local state=states[cd]
    if state then return state end
    state={cooldown=cd,cells={},bindings={},hooks={}}
    states[cd]=state
    return state
end
local function fallback(state)
    deactivate(state)
    if state.fallingBack then return end
    state.fallingBack=true
    if type(R.ApplyCountdownFormat)=="function"then pcall(R.ApplyCountdownFormat,state.cooldown)end
    state.fallingBack=nil
end
local function changedClock(state,clock)
    state.duration=clock;state.bound=nil
    if not R.ApplyPortraitTimer(state.cooldown)then fallback(state)end
end
local function installHooks(state)
    if type(hooksecurefunc)~="function"then return false end
    local cd=state.cooldown
    local callbacks={
        SetCooldownFromDurationObject=function(_,object)
            if not state.native then changedClock(state,safe(object) and object or nil)end
        end,
        SetCooldown=function(_,start,total,rate)
            if state.native then return end
            local valid=number(start)and number(total)and total>=0 and (rate==nil or positive(rate))
            local object=valid and state.numeric
            if object and call(object,"SetTimeFromStart",start,total,rate)then changedClock(state,object)
            else changedClock(state,nil)end
        end,
        Clear=function()
            if not state.native then state.duration=nil;state.bound=nil;fallback(state)end
        end,
    }
    for name,fn in pairs(callbacks)do
        if not state.hooks[name] and method(cd,name)then
            local ok,result=pcall(hooksecurefunc,cd,name,fn)
            if not ok or not readable(result)or result==false then return false end
            state.hooks[name]=true
        end
    end
    return true
end
local stylePairs={{"GetTextColor","SetTextColor"},{"GetShadowColor","SetShadowColor"},{"GetShadowOffset","SetShadowOffset"}}
local function configureStyle(state,label,verify)
    assert(safe(label),"missing font")
    local file,size,flags=label:GetFont()
    local scale=label:GetEffectiveScale()
    local textScale=method(label,"GetTextScale") and label:GetTextScale()or 1
    assert(readable(file)and type(file)=="string"and file~=""and positive(size)
        and readable(flags)and(flags==nil or type(flags)=="string")and positive(scale)and positive(textScale),"unreadable font")
    local cd=state.cooldown
    local parentScale=cd:GetEffectiveScale()
    assert(positive(parentScale),"unreadable scale")
    local signature=string.format("%s\031%s\031%.17g\031%.17g\031%.17g",file,flags or "",size,scale,textScale)
    local colors={}
    local style=signature.."\031"..tostring(parentScale)
    for i,pair in ipairs(stylePairs)do
        local get=method(label,pair[1])
        if get then
            colors[i]={get(label)}
            for _,v in ipairs(colors[i])do assert(number(v),"unreadable font color");style=style.."\031"..string.format("%.17g",v)end
        end
    end
    if not verify and state.styled and state.label==label and state.style==style then return end
    state.styled=false
    local metrics=metricCache[signature]
    if not metrics then
        if not probe then probe=accessible(UIParent:CreateFontString(nil,"ARTWORK"))end
        accepted(probe:Hide());accepted(probe:SetFont(file,size,flags))
        if method(probe,"SetTextScale")then accepted(probe:SetTextScale(textScale))else assert(textScale==1)end
        if method(probe,"SetScale")then accepted(probe:SetScale(scale/UIParent:GetEffectiveScale()))end
        local function width(t)
            local v
            if method(probe,"GetUnboundedStringWidthForText")then v=probe:GetUnboundedStringWidthForText(t)
            else accepted(probe:SetText(t));v=probe:GetStringWidth()end
            assert(positive(v),"unmeasurable glyph");return v
        end
        local digit=0
        for i=0,9 do digit=math.max(digit,width(tostring(i)))end
        metrics={digit+.5,math.max(width("."),width(","))+.5}
        if metricKeys[metricSlot]then metricCache[metricKeys[metricSlot]]=nil end
        metricKeys[metricSlot]=signature;metricSlot=metricSlot%32+1;metricCache[signature]=metrics
    end
    local digit,dot=metrics[1],metrics[2]
    local decimal=math.max(1,math.min((digit+dot)/2-.45,size*textScale*.53))
    local whole=math.min(digit+.15,size*textScale*.71)
    local positions={-decimal-whole,-decimal,0,decimal,-whole/2+.45,whole/2+.45}
    if not state.group then
        state.group=accessible(CreateFrame("Frame",nil,cd))
        accepted(state.group:Hide())
    end
    for i=1,6 do
        local cell=state.cells[i]
        if not cell then cell=accessible(state.group:CreateFontString(nil,"OVERLAY"));state.cells[i]=cell end
        accepted(cell:SetFont(file,size,flags))
        if method(cell,"SetTextScale")then accepted(cell:SetTextScale(textScale))else assert(textScale==1)end
        accepted(cell:SetScale(scale/parentScale))
        accepted(cell:ClearAllPoints())
        accepted(cell:SetPoint("CENTER",label,"CENTER",positions[i],0))
        accepted(cell:SetJustifyH("CENTER"));accepted(cell:SetJustifyV("MIDDLE"))
        if method(cell,"SetWordWrap")then accepted(cell:SetWordWrap(false))end
        if method(cell,"SetMaxLines")then accepted(cell:SetMaxLines(1))end
        for j,pair in ipairs(stylePairs)do
            local set=method(cell,pair[2])
            if colors[j]and set then accepted(set(cell,(unpack or table.unpack)(colors[j])))end
        end
        accepted(cell:Show())
    end
    state.label=label;state.style=style;state.styled=true
end
local function prepare(state,label,verify)
    if not state.numeric and C_DurationUtil and type(C_DurationUtil.CreateDuration)=="function"then
        state.numeric=accessible(C_DurationUtil.CreateDuration())
    end
    assert(installHooks(state),"clock hooks unavailable")
    if label then configureStyle(state,label,verify)end
    if not state.styled then return false end
    for i=1,6 do
        local binding=state.bindings[i]
        if not binding then binding=accessible(C_DurationUtil.CreateDurationTextBinding());state.bindings[i]=binding end
        if i>(state.configured or 0)then
            accepted(binding:SetEnabled(false))
            accepted(binding:SetUpdateInterval(.1))
            accepted(binding:SetZeroDurationText(""))
            accepted(binding:SetExpiredText(""))
            state.configured=i
        end
    end
    return true
end
local function bridgeSupported()
    if bridgeReady then return true end
    if bridgeEpoch==R.countdownFormatterEpoch then return false end
    bridgeEpoch=R.countdownFormatterEpoch
    local ok=pcall(function()
        if not bridgeProbe then bridgeProbe=accessible(CreateFrame("StatusBar",nil,UIParent))end
        accepted(bridgeProbe:Hide())
        local synthetic=accessible(C_DurationUtil.CreateDuration())
        accepted(synthetic:SetTimeFromStart(0,1))
        accepted(bridgeProbe:SetTimerDuration(synthetic))
        local received=accessible(bridgeProbe:GetTimerDuration())
        assert(accessible(received:GetTotalDuration())==1,"duration transport unavailable")
        accepted(synthetic:SetTimeFromStart(0,2))
        assert(accessible(received:GetTotalDuration())==2,"duration transport copied its source")
    end)
    bridgeReady=ok
    return ok
end
local function attach(state)
    if state.native then return true end
    local button=state.button
    if not safe(button)or not method(button,"SetDurationBar")or not bridgeSupported()then return false end
    if not state.bar then
        local ok,bar=pcall(CreateFrame,"StatusBar",nil,button)
        if not ok or not safe(bar)then return false end
        state.bar=bar
    end
    if not call(state.bar,"Hide")then return false end
    -- This is the public bridge to the forbidden button's stable mutable
    -- auraDuration. GetTimerDuration returns the object, not its secret value.
    if not state.registered then
        if not call(button,"SetDurationBar",state.bar,{})then return false end
        state.registered=true
    end
    local ok,duration=pcall(method(state.bar,"GetTimerDuration"),state.bar)
    if not ok or not safe(duration)then return false end
    state.duration=duration;state.native=true;state.bound=nil
    return true
end
function R.AttachPortraitAuraClock(button,cooldown)
    if not safe(cooldown)or not safe(button)then return false end
    local state=getState(cooldown)
    if state.button and not rawequal(state.button,button)then return false end
    state.button=button
    if state.native then return true end
    if not outOfCombat()then return false end
    state.attachEpoch=R.countdownFormatterEpoch
    local okay=attach(state)
    if okay then R.ApplyPortraitTimer(cooldown)end
    return okay
end
function R.ApplyPortraitTimer(cooldown,label,verify)
    if not safe(cooldown)then return false end
    local state=getState(cooldown)
    if state.fallingBack or state.applying then return false end
    state.applying=true
    local okay=pcall(function()
        if label==false then state.styled=false;error("font unavailable")end
        if outOfCombat()then
            if label or not state.styled or state.configured~=6 then
                local prepared,result=pcall(prepare,state,label,verify)
                assert(prepared and result,"cell preparation unavailable")
            end
            if state.button and not state.native and (verify or state.attachEpoch~=R.countdownFormatterEpoch)then
                state.attachEpoch=R.countdownFormatterEpoch
                assert(attach(state),"native bridge unavailable")
            end
        end
        assert(state.styled and state.configured==6 and safe(state.duration),"current clock unavailable")
        local desired=currentFormats()
        assert(desired,"native glyph rules unavailable")
        if not state.active or state.bound~=state.duration or state.formatters~=desired or verify then
            -- SetEnabled(false) can disconnect its receiver. Always restore
            -- each cell before restarting, including reuse after Clear.
            for i,binding in ipairs(state.bindings)do
                accepted(binding:SetFontString(state.cells[i]))
                accepted(binding:SetFormatter(desired[i]))
                accepted(binding:SetDuration(state.duration))
                accepted(binding:SetEnabled(true))
            end
            state.bound=state.duration;state.formatters=desired
        end
        local hidden=state.hidden
        if verify and method(cooldown,"GetHideCountdownNumbers")then
            local ok,v=pcall(cooldown.GetHideCountdownNumbers,cooldown)
            hidden=ok and readable(v)and v==true
        end
        if not hidden then
            assert(call(cooldown,"SetHideCountdownNumbers",true),"stock countdown visibility denied")
            if method(cooldown,"GetHideCountdownNumbers")then
                local ok,v=pcall(cooldown.GetHideCountdownNumbers,cooldown);assert(ok and readable(v)and v==true,"stock countdown still visible")
            end
        end
        state.hidden=true
        cooldown._bjarkiTimerNumbersShown=false
        if not state.active then assert(call(state.group,"Show"),"cell visibility denied")end
        state.active=true
    end)
    state.applying=nil
    if not okay then
        deactivate(state)
        state.hidden=nil
        if method(cooldown,"GetHideCountdownNumbers")then
            local ok,v=pcall(cooldown.GetHideCountdownNumbers,cooldown)
            if ok and readable(v)and type(v)=="boolean"then cooldown._bjarkiTimerNumbersShown=not v end
        end
        cooldown._bjarkiTimerSpacingReason="cells-unavailable"
        return false
    end
    cooldown._bjarkiTimerBackend="cells"
    cooldown._bjarkiTimerDecimals=R.db and R.db.showDecimals==true or false
    cooldown._bjarkiTimerSpacingReason="fixed-cells"
    return true,"cells"
end

