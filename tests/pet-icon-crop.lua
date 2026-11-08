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

-- The local compact PetFrame's source icon has its square border inside the
-- native circular mask if trimmed by just 1/64. Crop 3/64 on all four edges.
assertCrop("pet", 3 / 64)
-- These accepted calibrations must NOT follow the pet's tighter crop.
assertCrop("player", 1 / 128)
for _, unit in ipairs({"target", "focus", "party1", "party2", "party3", "party4", "targettarget", "focustarget"}) do
    assertCrop(unit, 1 / 64)
end

-- An unavailable/rejected graphics operation is not a reason to break a unit
-- update. The existing pcall boundary remains intact.
R.ApplyPortraitIconCrop({SetTexCoord = function() error("mock texture failure") end}, {unit="pet"})
R.ApplyPortraitIconCrop({}, {unit="pet"})
checks = checks + 2

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
-- The native clipping mask and framing offsets are unchanged by the helper.
eq(contents("Core.lua"):find('pet = { -0.6, -0.6 }', 1, true) ~= nil,
    true, "pet image translation remains calibrated")

local version = assert(contents("Core.lua"):match('R%.VERSION%s*=%s*"([^"]+)"'))
for _, manifest in ipairs({"bjarkiPortraits.toc", "bjarkiPortraits_Camelot.toc"}) do
    eq(contents(manifest):match("## Version: ([^\r\n]+)"), version, manifest .. " version")
end
print("bjarkiPortraits pet icon border crop: " .. checks .. " checks passed")
