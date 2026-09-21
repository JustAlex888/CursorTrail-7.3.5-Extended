--[[---------------------------------------------------------------------------
    Addon:  CursorTrail
    File:   CursorTrailShapes.lua
    Desc:   Legion-compatible 2D cursor layers for CursorTrail 7.3.5 Extended.

    Original addon: CursorTrail by UppyDan (DJU)
    Shape textures are selected from the CursorTrail 10.1.0.1 donor release.
-----------------------------------------------------------------------------]]

local Globals = _G
local CreateFrame = _G.CreateFrame
local CopyTable = _G.CopyTable
local ipairs = _G.ipairs
local tonumber = _G.tonumber
local math = _G.math

local CursorTrail = _G.CursorTrail or {}
if (not _G.CursorTrail) then _G.CursorTrail = CursorTrail end

setfenv(1, _G.CursorTrail)

local kShapePath = "Interface\\AddOns\\CursorTrail\\Shapes\\"
local kShapeBaseSize = 48
-- 0.0.5.18: one 2D offset unit equals 2.5 UI points at 100% scale.
-- This halves the 0.0.5.17/0.0.5.16 displacement while still scaling with MarkerScale.
-- At the full +/-20 range the marker moves about one marker-width.
local kMarkerOffsetStep = 2.5

-- 0.0.6.3: rotation is an independent property of the complete halo texture.
-- The texture stays attached to the halo; only the whole halo rotates. Direction
-- remains fixed counter-clockwise. The user controls the revolution period.
local kHaloRotationDefaultSeconds = 8.0
local kHaloRotationDegrees = 360

-- Marker = 2D cursor body / marker.
-- Halo   = independent geometry surrounding the cursor.
local kMarkerOptions = {
    { key = "circle_1", nameKey = "MARKER_DISK",     file = "Circle 1.tga" },
    { key = "glow",     nameKey = "MARKER_GLOW",  file = "Glow.tga" },
    { key = "cross_1",  nameKey = "MARKER_CROSS_1",   file = "Cross 1.tga" },
    { key = "cross_2",  nameKey = "MARKER_CROSS_2",   file = "Cross 2.tga" },
    { key = "swirl",    nameKey = "MARKER_SWIRL",     file = "Swirl.tga" },
}

-- 0.0.6.0 halo system.  User-facing controls are now semantic:
-- Shape (circle/square), Style (solid/spectral), and Thickness (1..5).
local kHaloShapeOptions = {
    { key = "circle", nameKey = "HALO_CIRCLE" },
    { key = "square", nameKey = "HALO_SQUARE" },
}

local kHaloStyleOptions = {
    { key = "solid",    nameKey = "HALO_SOLID" },
    { key = "spectral", nameKey = "HALO_SPECTRAL" },
}

local kHaloTextureFiles = {
    circle = {
        solid = {
            "Ring 1.tga", "Ring 2.tga", "Ring 3.tga", "Ring 4.tga", "Ring 5.tga",
        },
        spectral = {
            "Ring Spectral 1.tga", "Ring Spectral 2.tga", "Ring Spectral 3.tga",
            "Ring Spectral 4.tga", "Ring Spectral 5.tga",
        },
    },
    square = {
        solid = {
            "Square 1.tga", "Square 2.tga", "Square 3.tga", "Square 4.tga", "Square 5.tga",
        },
        spectral = {
            "Square Spectral 1.tga", "Square Spectral 2.tga", "Square Spectral 3.tga",
            "Square Spectral 4.tga", "Square Spectral 5.tga",
        },
    },
}

-- Legacy halo keys are retained only for downgrade/migration compatibility.
local kLegacyHaloOptions = {
    { key = "ring_1",      nameKey = "HALO_RING_1",        file = "Ring 1.tga" },
    { key = "ring_2",      nameKey = "HALO_RING_2",        file = "Ring 2.tga" },
    { key = "ring_3",      nameKey = "HALO_RING_3",        file = "Ring 3.tga" },
    { key = "ring_4",      nameKey = "HALO_RING_4",        file = "Ring 4.tga" },
    { key = "ring_soft_1", nameKey = "HALO_RING_SOFT_1", file = "Ring Soft 1.tga" },
    { key = "ring_soft_2", nameKey = "HALO_RING_SOFT_2", file = "Ring Soft 2.tga" },
}

local kMarkerByKey = {}
local kLegacyHaloByKey = {}
local kHaloShapeByKey = {}
local kHaloStyleByKey = {}
for _, option in ipairs(kMarkerOptions) do kMarkerByKey[option.key] = option end
for _, option in ipairs(kLegacyHaloOptions) do kLegacyHaloByKey[option.key] = option end
for _, option in ipairs(kHaloShapeOptions) do kHaloShapeByKey[option.key] = option end
for _, option in ipairs(kHaloStyleOptions) do kHaloStyleByKey[option.key] = option end

local MarkerConfig
local HaloConfig
local HaloRotationGroup
local HaloRotation
local HaloRotationSecondsApplied
local HaloRotationDegreesApplied

local function GetTexturePath(option, fallbackFile)
    if option then return kShapePath..option.file end
    return kShapePath..fallbackFile
end

function Marker_GetOptions()
    return kMarkerOptions
end

function Marker_IsKey(key)
    return kMarkerByKey[key] ~= nil
end

function Marker_GetDisplayName(key)
    local option = kMarkerByKey[key]
    if option then return L(option.nameKey) end
    return L("MARKER_DISK")
end

function Marker_GetTexturePath(key)
    return GetTexturePath(kMarkerByKey[key], "Circle 1.tga")
end

-- New 0.0.6.0 halo helpers.
function Halo_GetShapeOptions()
    return kHaloShapeOptions
end

function Halo_GetStyleOptions()
    return kHaloStyleOptions
end

function Halo_NormalizeShape(key)
    if kHaloShapeByKey[key] then return key end
    return "circle"
end

function Halo_NormalizeStyle(key)
    if kHaloStyleByKey[key] then return key end
    return "solid"
end

function Halo_NormalizeThickness(value)
    value = tonumber(value) or 1
    value = math.floor(value + 0.5)
    if value < 1 then value = 1 end
    if value > 5 then value = 5 end
    return value
end

function Halo_NormalizeRotationSeconds(value)
    value = tonumber(value) or kHaloRotationDefaultSeconds
    if value < 4 then value = 4 end
    if value > 12 then value = 12 end
    value = 4 + math.floor(((value - 4) / 2) + 0.5) * 2
    if value < 4 then value = 4 end
    if value > 12 then value = 12 end
    return value
end

function Halo_GetShapeDisplayName(key)
    key = Halo_NormalizeShape(key)
    return L(kHaloShapeByKey[key].nameKey)
end

function Halo_GetStyleDisplayName(key)
    key = Halo_NormalizeStyle(key)
    return L(kHaloStyleByKey[key].nameKey)
end

function Halo_GetTexturePath(shapeKey, styleKey, thickness)
    shapeKey = Halo_NormalizeShape(shapeKey)
    styleKey = Halo_NormalizeStyle(styleKey)
    thickness = Halo_NormalizeThickness(thickness)
    local file = kHaloTextureFiles[shapeKey][styleKey][thickness]
    return kShapePath..file
end

-- Compatibility helpers retained for older internal calls / diagnostics.
function Halo_GetOptions() return kLegacyHaloOptions end
function Halo_IsKey(key) return kLegacyHaloByKey[key] ~= nil end
function Halo_GetDisplayName(key)
    local option = kLegacyHaloByKey[key]
    if option then return L(option.nameKey) end
    return L("HALO_RING_1")
end
function Shape_IsMarkerKey(key) return Marker_IsKey(key) end
function Shape_IsHaloKey(key) return Halo_IsKey(key) end

local function CreateLayer(frameName)
    local frame = CreateFrame("Frame", nil, kGameFrame)
    frame:SetAllPoints(kGameFrame)
    frame:SetFrameStrata("HIGH")
    local texture = frame:CreateTexture(nil, "OVERLAY")
    return frame, texture
end

local function Halo_CreateRotationAnimation()
    if HaloRotationGroup or not HaloTexture then return end

    HaloRotationGroup = HaloTexture:CreateAnimationGroup()
    HaloRotationGroup:SetLooping("REPEAT")

    HaloRotation = HaloRotationGroup:CreateAnimation("Rotation")
    HaloRotation:SetOrder(1)
    HaloRotation:SetDegrees(kHaloRotationDegrees)
    HaloRotation:SetDuration(kHaloRotationDefaultSeconds)
    HaloRotation:SetOrigin("CENTER", 0, 0)
    HaloRotationSecondsApplied = kHaloRotationDefaultSeconds
    HaloRotationDegreesApplied = kHaloRotationDegrees
end

local function Halo_UpdateRotationAnimation()
    if not HaloRotationGroup or not HaloRotation then return end

    local seconds = Halo_NormalizeRotationSeconds(HaloConfig and HaloConfig.HaloRotationSeconds)
    local degrees = kHaloRotationDegrees
    if HaloConfig and HaloConfig.HaloRotationInverted == true then
        degrees = -kHaloRotationDegrees
    end

    if HaloRotationSecondsApplied ~= seconds or HaloRotationDegreesApplied ~= degrees then
        -- Restart only when speed or direction really changes. Stop() also resets
        -- the transform, which keeps the texture aligned when rotation is disabled.
        if HaloRotationGroup:IsPlaying() then HaloRotationGroup:Stop() end
        HaloRotation:SetDuration(seconds)
        HaloRotation:SetDegrees(degrees)
        HaloRotationSecondsApplied = seconds
        HaloRotationDegreesApplied = degrees
    end

    local shouldRotate = (HaloConfig
        and HaloConfig.HaloEnabled == true
        and HaloConfig.HaloRotationEnabled == true
        and HaloTexture
        and HaloTexture:IsShown())

    if shouldRotate then
        if not HaloRotationGroup:IsPlaying() then
            HaloRotationGroup:Play()
        end
    elseif HaloRotationGroup:IsPlaying() then
        -- Stop resets the animation transform, so a disabled rotation is static.
        HaloRotationGroup:Stop()
    end
end

function Shape_Create()
    if not HaloFrame then
        HaloFrame, HaloTexture = CreateLayer("Halo")
        Halo_CreateRotationAnimation()
    end
    if not MarkerFrame then
        MarkerFrame, MarkerTexture = CreateLayer("Marker")
    end
end

local function ApplyTextureConfig(texture, texturePath, colorR, colorG, colorB, scale, alpha)
    texture:SetTexture(texturePath)
    texture:SetVertexColor(colorR, colorG, colorB)
    local size = kShapeBaseSize * scale
    texture:SetSize(size, size)
    texture:SetAlpha(alpha)
end

function Shape_ApplyConfig(config)
    if not MarkerTexture or not HaloTexture then return end

    MarkerConfig = {
        MarkerEnabled = (config.MarkerEnabled == true),
        MarkerName = Marker_IsKey(config.MarkerName) and config.MarkerName or "circle_1",
        MarkerColorR = config.MarkerColorR or 1.0,
        MarkerColorG = config.MarkerColorG or 1.0,
        MarkerColorB = config.MarkerColorB or 1.0,
        MarkerScale = config.MarkerScale or 1.0,
        MarkerOfsX = config.MarkerOfsX or 0,
        MarkerOfsY = config.MarkerOfsY or 0,
        MarkerAlpha = config.MarkerAlpha or 1.0,
    }

    HaloConfig = {
        HaloEnabled = (config.HaloEnabled == true),
        HaloShape = Halo_NormalizeShape(config.HaloShape),
        HaloStyle = Halo_NormalizeStyle(config.HaloStyle),
        HaloThickness = Halo_NormalizeThickness(config.HaloThickness),
        HaloColorR = config.HaloColorR or 1.0,
        HaloColorG = config.HaloColorG or 1.0,
        HaloColorB = config.HaloColorB or 1.0,
        HaloScale = config.HaloScale or 1.0,
        HaloAlpha = config.HaloAlpha or 1.0,
        HaloRotationEnabled = (config.HaloRotationEnabled == true),
        HaloRotationInverted = (config.HaloRotationInverted == true),
        HaloRotationSeconds = Halo_NormalizeRotationSeconds(config.HaloRotationSeconds),
    }

    ApplyTextureConfig(MarkerTexture, Marker_GetTexturePath(MarkerConfig.MarkerName),
        MarkerConfig.MarkerColorR, MarkerConfig.MarkerColorG, MarkerConfig.MarkerColorB,
        MarkerConfig.MarkerScale, MarkerConfig.MarkerAlpha)

    local haloR, haloG, haloB = HaloConfig.HaloColorR, HaloConfig.HaloColorG, HaloConfig.HaloColorB
    if HaloConfig.HaloStyle == "spectral" then
        -- Spectral textures contain their own RGB gradient; tinting must stay neutral.
        haloR, haloG, haloB = 1.0, 1.0, 1.0
    end
    ApplyTextureConfig(HaloTexture,
        Halo_GetTexturePath(HaloConfig.HaloShape, HaloConfig.HaloStyle, HaloConfig.HaloThickness),
        haloR, haloG, haloB, HaloConfig.HaloScale, HaloConfig.HaloAlpha)
    Halo_UpdateRotationAnimation()
end

function Shape_Load(config)
    if not config then config = PlayerConfig end
    Shape_Create()

    HaloFrame:SetParent(kGameFrame)
    HaloFrame:ClearAllPoints()
    HaloFrame:SetAllPoints(kGameFrame)
    HaloFrame:SetFrameStrata("HIGH")

    MarkerFrame:SetParent(kGameFrame)
    MarkerFrame:ClearAllPoints()
    MarkerFrame:SetAllPoints(kGameFrame)
    MarkerFrame:SetFrameStrata("HIGH")

    if CursorModel then
        HaloFrame:SetFrameLevel(CursorModel:GetFrameLevel() + 1)
        MarkerFrame:SetFrameLevel(CursorModel:GetFrameLevel() + 2)
    end

    Shape_ApplyConfig(config)
    PreviousX = nil
end

function Shape_Show()
    if HaloTexture and HaloConfig and HaloConfig.HaloEnabled == true then
        HaloTexture:SetAlpha(HaloConfig.HaloAlpha)
        HaloTexture:Show()
    elseif HaloTexture then
        HaloTexture:Hide()
    end
    Halo_UpdateRotationAnimation()

    if MarkerTexture and MarkerConfig and MarkerConfig.MarkerEnabled == true then
        MarkerTexture:SetAlpha(MarkerConfig.MarkerAlpha)
        MarkerTexture:Show()
    elseif MarkerTexture then
        MarkerTexture:Hide()
    end
end

function Shape_Hide()
    if HaloTexture then HaloTexture:Hide() end
    if MarkerTexture then MarkerTexture:Hide() end
    Halo_UpdateRotationAnimation()
end

function Shape_HasEnabledLayer()
    return (HaloConfig and HaloConfig.HaloEnabled == true)
        or (MarkerConfig and MarkerConfig.MarkerEnabled == true)
end

function Shape_UpdatePosition(cursorX, cursorY)
    if not ScreenScale then return end

    local x = (cursorX - ScreenMidX) / ScreenScale
    local y = (cursorY - ScreenMidY) / ScreenScale

    -- 0.0.6.4: disabled 2D layers no longer receive cursor-position updates.
    if HaloTexture and HaloConfig and HaloConfig.HaloEnabled == true then
        HaloTexture:ClearAllPoints()
        HaloTexture:SetPoint("CENTER", kGameFrame, "CENTER", x + 0.5, y - 0.5)
    end

    if MarkerTexture and MarkerConfig and MarkerConfig.MarkerEnabled == true then
        MarkerTexture:ClearAllPoints()
        local markerScale = MarkerConfig.MarkerScale or 1.0
        local markerOfsX = MarkerConfig.MarkerOfsX or 0
        local markerOfsY = MarkerConfig.MarkerOfsY or 0
        local offsetStep = kMarkerOffsetStep * markerScale
        MarkerTexture:SetPoint("CENTER", kGameFrame, "CENTER",
            x + 0.5 + (markerOfsX * offsetStep),
            y - 0.5 + (markerOfsY * offsetStep))
    end
end

--- End of File ---
