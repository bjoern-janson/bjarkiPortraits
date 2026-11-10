-- Only ambiguity capable of reaching the first two distinct spots can veto.
local BP={}
for _,file in ipairs({"Spells","Core","Priority","SecondaryPortrait"}) do
    assert(loadfile(file..".lua"))("bjarkiPortraits",BP)
end
local R=BP.Runtime
R.ApplyDefaults()
local h={unit="player",_buildComplete=true,_hostileUnit=false,_assistable=true}
local buffs,debuffs={},{}
R.ExactFilterAllowed=function()return true end
C_UnitAuras={GetAuraDataByIndex=function(_,i,filter)
    return (filter:sub(1,7)=="HELPFUL" and buffs or debuffs)[i]
end}
local function aura(id,n,start)
    return {spellId=id,auraInstanceID=n,isNameplateOnly=false,duration=start and 20,
        expirationTime=start and start+20}
end
local function pair(expectedA,expectedB)
    local second,reason,first=R.GetReadableSecondaryAura(h)
    assert(first and first.spellID==expectedA and second and second.spellID==expectedB,
        "expected "..expectedA.."/"..expectedB..", got "..tostring(reason))
end
-- The two bottom candidates have different spells and unknown application times.
buffs={aura(1126,1),aura(1243,2),aura(17,3,80),aura(22812,4,81)}
pair(22812,17)
buffs[4]=nil
assert(R.GetReadableSecondaryAura(h)==nil,"a tie at second must still fail")
-- Unknown helpful semantic filters peak at BigDef(289).
local immunity,spellImmune=642,8178 -- Divine Shield, Grounding Totem Effect
buffs={aura(7000000,1),aura(immunity,2,80),aura(spellImmune,3,81)}
pair(immunity,spellImmune)
buffs[3]=aura(17,3,82)
assert(R.GetReadableSecondaryAura(h)==nil,"unknown 289 can displace Shield")
-- Cross-polarity tied owners at Offensive(280) are beneath both winners.
local off,offHarm=5515,12328 -- Savagery / Death Wish, different 280 slots
buffs={aura(off,1,78),aura(immunity,2,80),aura(spellImmune,3,81)}
debuffs={aura(offHarm,4,80)}
pair(immunity,spellImmune)
buffs[3]=nil
assert(R.GetReadableSecondaryAura(h)==nil,"a cross-lane tie at second remains ambiguous")
-- A proven stance supplies the second position before an ambiguous lower tier.
debuffs={}
buffs={aura(1126,1),aura(1243,2),aura(17,3,80)}
h._formStateActive,h._formStateSpellID,h._formStateReason=true,2457,"player-forms:proven"
pair(17,2457)
print("PASS secondary ambiguity bounds and distinct global places")
