-- Fixed cells use real module entry points; the native aura private receiver
-- bypasses every public clock setter and only mutates its stable duration.
local root=arg and arg[1] or "."
local BP={}
assert(loadfile(root.."/Core.lua"))("bjarkiPortraits",BP)
local R=BP.Runtime
R.ApplyDefaults()
local combat=false
InCombatLockdown=function()return combat end
local secret={}
issecretvalue=function(v)return rawequal(v,secret)end
local count={font=0,anchor=0,bindings=0,frames=0,reads=0,stock=0}
local single=false
local function native(x)
    if not single or x==0 then return x end
    local s=2^math.floor(math.log(x)/math.log(2))
    if s>x then s=s/2 elseif 2*s<=x then s=2*s end
    local step=s*2^-23;local n=x/step;local lo=math.floor(n)
    if n-lo>0.5 or (n-lo==0.5 and lo%2~=0)then lo=lo+1 end
    return lo*step
end
Enum={NumericRuleFormatRounding={Down=2}}
C_StringUtil={CreateNumericRuleFormatter=function()
    return {SetBreakpoints=function(self,rules)
        self.rules={};for i,r in ipairs(rules)do self.rules[i]={threshold=native(r.threshold),format=r.format,step=r.step}end
    end,FormatNumber=function(self,v)
        v=native(v);local rule
        for _,r in ipairs(self.rules)do if v>=r.threshold then rule=r else break end end
        if not rule then return "" end
        if rule.step then v=math.floor(v/rule.step)*rule.step end
        return rule.format:find("%%") and string.format(rule.format,v) or rule.format
    end}
end}
local all={}
local denyBinding,denyHide,denyFont=false,false,false
local function label(parent)
    return {parent=parent,path="font.ttf",size=16,flags="OUTLINE",scale=1,textScale=1,shown=true,
        IsForbidden=function()return false end,
        GetFont=function(self)return self.path,self.size,self.flags end,
        SetFont=function(self,p,s,f)assert(not combat);count.font=count.font+1;if denyFont then return false end;self.path,self.size,self.flags=p,s,f end,
        GetEffectiveScale=function(self)return self.scale*(self.parent and self.parent:GetEffectiveScale()or 1)end,
        SetScale=function(self,v)assert(not combat);self.scale=v end,
        GetTextScale=function(self)return self.textScale end,SetTextScale=function(self,v)assert(not combat);self.textScale=v end,
        SetPoint=function(self,...)assert(not combat);count.anchor=count.anchor+1;self.point={...}end,
        ClearAllPoints=function(self)assert(not combat);self.point=nil end,
        SetSize=function(self,w,h)assert(not combat);self.width,self.height=w,h end,
        SetWidth=function(self,v)self.width=v end,SetHeight=function(self,v)self.height=v end,
        SetJustifyH=function()end,SetJustifyV=function()end,SetWordWrap=function()end,SetMaxLines=function()end,
        SetText=function(self,v)self.text=v end,GetText=function()error("must not read displayed text")end,
        GetStringWidth=function(self)count.reads=count.reads+1;return self.text=="." and 3 or self.text=="1" and 4 or 9 end,
        GetUnboundedStringWidthForText=function(self,t)count.reads=count.reads+1;return t=="." and 3 or t=="1" and 4 or 9 end,
        GetTextColor=function()return 1,.9,.8,1 end,SetTextColor=function(self,...)self.color={...}end,
        GetShadowColor=function()return 0,0,0,1 end,SetShadowColor=function()end,
        GetShadowOffset=function()return 1,-1 end,SetShadowOffset=function()end,
        Hide=function(self)self.shown=false end,Show=function(self)self.shown=true end,IsShown=function(self)return self.shown end}
end
local function frame(parent)
    return {parent=parent,scale=1,IsForbidden=function()return false end,
        GetEffectiveScale=function(self)return self.scale*(self.parent and self.parent:GetEffectiveScale()or 1)end,
        GetParent=function(self)return self.parent end,
        CreateFontString=function(self)local f=label(self);self.labels=self.labels or {};self.labels[#self.labels+1]=f;return f end,
        Hide=function(self)self.hidden=true end,Show=function(self)self.hidden=false end,
        SetSize=function()end,SetPoint=function()end,
        SetTimerDuration=function(self,d)self.duration=d end,GetTimerDuration=function(self)return self.duration end,
        GetValue=function()error("secret bar value")end,GetMinMaxValues=function()error("secret bar value")end}
end
UIParent=frame()
CreateFrame=function(kind,name,parent)count.frames=count.frames+1;local f=frame(parent);f.kind=kind;return f end
local function duration()
    return {SetTimeFromStart=function(self,start,total,rate)assert(start~=secret and total~=secret);self.start,self.total,self.rate=start,total,rate end,
        GetRemainingDuration=function()error("secret duration read")end,GetTotalDuration=function(self)assert(not self.opaque,"secret duration read");return self.total end}
end
C_DurationUtil={CreateDuration=duration,CreateDurationTextBinding=function()
    count.bindings=count.bindings+1
    local b={SetFontString=function(self,f)self.label=f end,GetFontString=function(self)return self.label end,
        SetFormatter=function(self,f)self.formatter=f end,GetFormatter=function(self)return self.formatter end,
        SetDuration=function(self,d)if denyBinding then return false end;self.duration=d end,
        SetEnabled=function(self,v)self.enabled=v;if not v then self.label=nil end end,
        SetZeroDurationText=function(self,t)self.zero=t end,SetExpiredText=function(self,t)self.expired=t end,
        SetUpdateInterval=function(self,v)self.interval=v end}
    all[#all+1]=b;return b
end}
hooksecurefunc=function(obj,name,fn)local original=assert(obj[name]);obj[name]=function(self,...)local r=original(self,...);fn(self,...);return r end end
local function cooldown()
    local f=frame(UIParent);f.SetCooldownFromDurationObject=function(self,d)self.native=d end
    f.SetCooldown=function(self,...)self.numeric={...}end;f.Clear=function(self)self.native=nil;self.numeric=nil end
    f.SetHideCountdownNumbers=function(self,v)count.stock=count.stock+1;if denyHide then return false end;self.hiddenNumbers=v end
    f.GetHideCountdownNumbers=function(self)return self.hiddenNumbers or false end
    f.SetCountdownFormatter=function(self,v)self.formatter=v end;f.GetCountdownFormatter=function(self)return self.formatter end
    return f
end
local function eq(a,b,msg)assert(a==b,(msg or "mismatch")..": "..tostring(a).." vs "..tostring(b))end
assert(loadfile(root.."/PortraitTimerSpacing.lua"))("bjarkiPortraits",BP)
assert(type(R.ApplyPortraitTimer)=="function","fixed portrait cells must expose their production entry point")
assert(type(R.AttachPortraitAuraClock)=="function","native aura clocks need the public bar bridge")
local function text(first,v)
    local out=""
    for i=first,first+5 do local t=all[i].formatter:FormatNumber(v);assert(#t<=1,"one character per binding");out=out..t end
    return out
end
local cd=cooldown();local source=label(cd);source.textScale=1.25
assert(not R.ApplyPortraitTimer(cd,source,true),"prepare cannot claim an unknown clock")
eq(count.bindings,6,"six cells")
local d=duration();d.opaque=true
cd:SetCooldownFromDurationObject(d,true)
assert(R.ApplyPortraitTimer(cd));eq(cd.hiddenNumbers,true)
for i=1,6 do local b=all[i];assert(b.enabled and b.label and b.duration==d);eq(b.zero,"");eq(b.expired,"");eq(b.label.textScale,1.25)end
eq(text(1,9.99),"10.0","carry");eq(text(1,10),"10");eq(text(1,30),"30");eq(text(1,31),"31")
eq(text(1,59.99),"59");eq(text(1,60),"60");eq(text(1,R.PORTRAIT_TIMER_HIDE_AT),"")
eq(all[3].label.point[4],0,"decimal point and single whole digit use the fixed center")
assert(math.abs(all[5].label.point[4]+all[6].label.point[4]-.9)<1e-8,"two whole digits retain their compact placement")
local nf,na,nb,nr,ns=count.font,count.anchor,count.bindings,count.reads,count.stock
combat=true
for i=1,20 do assert(R.ApplyPortraitTimer(cd))end
eq(count.font,nf);eq(count.anchor,na);eq(count.bindings,nb);eq(count.reads,nr);eq(count.stock,ns,"no steady visibility churn")
cd:Clear();for i=1,6 do assert(not all[i].enabled)end
cd:SetCooldownFromDurationObject(d,true)
for i=1,6 do assert(all[i].enabled and all[i].label,"restart reattaches disconnected label")end
cd:SetCooldown(100,7.5,2)
for i=1,6 do eq(all[i].duration.start,100);eq(all[i].duration.total,7.5);eq(all[i].duration.rate,2)end
cd:SetCooldown(secret,secret,secret);for i=1,6 do assert(not all[i].enabled,"no secret arithmetic")end
combat=false;cd:SetCooldownFromDurationObject(d,true)
denyBinding=true;cd:SetCooldownFromDurationObject(duration(),true)
for i=1,6 do assert(not all[i].enabled,"failed rebind leaves no mixed digits")end
eq(cd.hiddenNumbers,false,"hook failure restores capped stock")
denyBinding=false
assert(R.ApplyPortraitTimer(cd,source,true),"explicit presentation retries")
cd.hiddenNumbers=false;assert(R.ApplyPortraitTimer(cd,source,true));eq(cd.hiddenNumbers,true)
local nativeClock=duration();nativeClock.opaque=true
local button={SetDurationBar=function(self,bar)assert(bar.parent==self);self.bar=bar;bar.duration=nativeClock end,GetEffectiveScale=function()return 1 end}
local nc=cooldown()
R.ApplyPortraitTimer(nc,label(nc),true);local at=#all-5
assert(R.AttachPortraitAuraClock(button,nc));assert(button.bar.hidden)
for i=at,at+5 do assert(all[i].duration==nativeClock and all[i].enabled)end
local frames=count.frames
combat=true;nativeClock.remaining=12
assert(R.ApplyPortraitTimer(nc));eq(text(at,12),"12")
nativeClock.remaining=0;for i=at,at+5 do eq(all[i].zero,"")end
nativeClock.remaining=8.1;assert(R.ApplyPortraitTimer(nc));eq(text(at,8.1),"8.1")
eq(count.frames,frames,"native reuse needs no extra bridge")
combat=false
for _,precision in ipairs({false,true})do
    single=precision;R._formatter=nil;R.RetryCountdownFormatter()
    for _,decimals in ipairs({false,true})do
        R.db.showDecimals=decimals;R._formatter=nil;R.RetryCountdownFormatter()
        local target=cooldown();local start=#all+1
        R.ApplyPortraitTimer(target,label(target),true);target:SetCooldownFromDurationObject(d)
        assert(R.ApplyPortraitTimer(target));local base=R.GetCountdownFormatter()
        for i=1,60001 do local v=i/1000;eq(text(start,v),base:FormatNumber(v),"native equality "..v)end
        eq(text(start,30),"30");eq(text(start,31),"31");eq(text(start,60),"60")
        eq(text(start,R.PORTRAIT_TIMER_HIDE_AT),"")
    end
end
-- SetDurationBar registers a stable native duration receiver once. Its private
-- mutations never need public SetCooldown hooks, new bindings or font work.
local oldBindings,oldFrames=count.bindings,count.frames
assert(R.AttachPortraitAuraClock(button,nc));eq(count.bindings,oldBindings);eq(count.frames,oldFrames)
-- Refusing stock suppression cannot leave a partial fixed overlay active.
local bad=cooldown();local badLabel=label(bad);local badStart=#all+1
denyHide=true
R.ApplyPortraitTimer(bad,badLabel,true);bad:SetCooldownFromDurationObject(d)
assert(not R.ApplyPortraitTimer(bad,badLabel,true))
for i=badStart,badStart+5 do assert(not all[i].enabled)end
denyHide=false
assert(R.ApplyPortraitTimer(bad,badLabel,true))
-- Repeated public-duration reuse keeps the native mutable object, including
-- 30s remains visible; the real new cutoff is immediately past 60s.
for _,v in ipairs({0,.05,1.15,9.949,9.95,9.99,10,29.999,30,30.001,
    31,59.999,60,R.PORTRAIT_TIMER_HIDE_AT,61,2880})do
 eq(text(badStart,v),R.GetCountdownFormatter():FormatNumber(v))
end
print("portrait native timer cells: passed")
