-- Source-backed regression for the local PetFrame's 37px icon aperture.
-- Executes Core.lua's actual texture crop; no game UI APIs required.
local BP = {}
assert(loadfile("Core.lua"))("bjarkiPortraits", BP)
local R = assert(BP.Runtime)
local checks = 0
local function eq(a, b, label)
    assert(a == b, (label or "mismatch") .. ": got " .. tostring(a) .. ", expected " .. tostring(b))
    checks = checks + 1
end
local function assertCrop(unit, expected)
    local icon = {coords = nil}
    function icon:SetTexCoord(...)
        self.coords = {...}
    end
    R.ApplyPortraitIconCrop(icon, {unit = unit})
    assert(icon.coords, "crop was not applied to " .. unit)
    for i, target in ipairs({ expected, 1 - expected, expected, 1 - expected }) do
        eq(icon.coords[i], target, unit .. " coord " .. i)
    end
end

-- The 2/64 source trim removes light square icon edges in both
-- main and secondary circles; preserve PetFrame's existing 3/64 crop.
eq(R.AURA_ART_EDGE_INSET,2/64,"common source trim")
assertCrop("pet",3/64)
for _,unit in ipairs({"player","target","focus","party1","party2",
    "party3","party4","targettarget","focustarget"}) do
    assertCrop(unit,2/64)
end
local secondary={}
function secondary:SetTexCoord(...) self.coords={...} end
eq(R.ApplySecondaryIconCrop(secondary),true,"secondary source crop supported")
for i,want in ipairs({2/64,1-2/64,2/64,1-2/64}) do
    eq(secondary.coords[i],want,"secondary normalized UV "..i)
end

-- An unavailable/rejected graphics operation is not a reason to break a unit
-- update. The existing pcall boundary remains intact.
eq(R.ApplyPortraitIconCrop({SetTexCoord = function() error("mock texture failure") end},
    {unit="pet"}),false,"main source crop failure safely handled")
eq(R.ApplyPortraitIconCrop({}, {unit="pet"}),false,"missing main setter handled")
eq(R.ApplySecondaryIconCrop({SetTexCoord = function() error("mock texture failure") end}),
    false,"secondary crop failure safely handled")
eq(R.ApplySecondaryIconCrop({}),false,"missing secondary setter handled")
eq(R.ApplySecondaryIconCrop(nil),false,"nil secondary handled")

local function contents(path)
    local f = assert(io.open(path, "rb"))
    local s = assert(f:read("*a"))
    f:close()
    return s
end
-- Both native exact/readable aura icons and the pet-family foundation use
-- the same crop function; do not solve this for only one rendering lane.
eq(contents("AuraEngine.lua"):find("R.ApplyPortraitIconCrop(icon, host)", 1, true) ~= nil,
    true, "aura icons use shared icon crop")
eq(contents("PetPortraits.lua"):find("R.ApplyPortraitIconCrop(texture, host)", 1, true) ~= nil,
    true, "pet-family foundation uses shared crop")
eq(contents("SecondaryPortrait.lua"):find("R.ApplySecondaryIconCrop(icon)",1,true) ~= nil,
    true,"readable second aura has source border crop")
eq(contents("NativeSecondProbe.lua"):find("R.ApplySecondaryIconCrop(icon)",1,true) ~= nil,
    true,"native secure runner-up has source border crop")
eq(contents("PetSecondary.lua"):find("R.ApplySecondaryIconCrop(image)",1,true) ~= nil,
    true,"pet-family secondary has source border crop")
-- The native clipping mask and framing offsets are unchanged by the helper.
eq(contents("Core.lua"):find('pet = { -0.6, -0.6 }', 1, true) ~= nil,
    true, "pet image translation remains calibrated")

local version = assert(contents("Core.lua"):match('R%.VERSION%s*=%s*"([^"]+)"'))
for _, manifest in ipairs({"bjarkiPortraits.toc", "bjarkiPortraits_Camelot.toc"}) do
    eq(contents(manifest):match("## Version: ([^\r\n]+)"), version, manifest .. " version")
end
print("bjarkiPortraits pet icon border crop: " .. checks .. " checks passed")
