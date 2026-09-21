--[[---------------------------------------------------------------------------
    Addon:  CursorTrail
    File:   CursorTrail.lua
    Desc:   This file contains the core implementation for this addon.

    Original addon: CursorTrail by UppyDan (DJU)
    Original Legion release: 7.3.5.1
    This branch: CursorTrail 7.3.5 Extended
    Adaptation version: 1.0.0

    This branch preserves the original authorship and adapts the addon for
    World of Warcraft: Legion 7.3.5, including compatibility fixes and selected backports.
-----------------------------------------------------------------------------]]
              
--:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
--[[                       Saved (Persistent) Variables                      ]]
--:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

CursorTrail_PlayerConfig = CursorTrail_PlayerConfig or {}
CursorTrail_ProfilesDB = CursorTrail_ProfilesDB or {}

--:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
--[[                       Aliases to Globals                                ]]
--:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

local Globals = _G
local assert = _G.assert
local print = _G.print
local CreateFrame = _G.CreateFrame
local floor = _G.floor
local CopyTable = _G.CopyTable
local pairs = _G.pairs
local ipairs = _G.ipairs
local next = _G.next
local DEFAULT_CHAT_FRAME = _G.DEFAULT_CHAT_FRAME
local GetAddOnMetadata = _G.GetAddOnMetadata
local string = _G.string
local table = _G.table
local tonumber = _G.tonumber
local type = _G.type
local GetCursorPosition = _G.GetCursorPosition
local IsMouselooking = _G.IsMouselooking
local IsMouseButtonDown = _G.IsMouseButtonDown
local UnitAffectingCombat = _G.UnitAffectingCombat

--:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
--[[                       Declare Namespace                                 ]]
--:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

local CursorTrail = _G.CursorTrail or {}
if (not _G.CursorTrail) then _G.CursorTrail = CursorTrail end
local CursorPreviewMode = false

--:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
--[[                       Remap Global Environment                          ]]
--:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

setfenv(1, _G.CursorTrail)  -- Everything after this uses our namespace rather than _G.


--:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
--[[                       Constants                                         ]]
--:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

kTheTitle = ...  -- (i.e.  "CursorTrail")
kTheVersion = GetAddOnMetadata(kTheTitle, "Version"):match("^([%d.]+)")
kDisplayTitle = "CursorTrail 7.3.5 Extended"  -- Public/display name; internal addon ID stays CursorTrail.
kBaseMult = 0.0001  -- A mulitplier applied to base values to reduce the # of decimal positions needed.

kDefaultConfig = 
{
    Version = kTheVersion,
    TrailKey = "electric_blue_long",
    UserScale = 1.0,
    UserAlpha = 1.00,  -- (Solid = 1.0.  Transparent = 0.0)
    UserOfsX = 0, UserOfsY = 0,
    UserShowOnlyInCombat = false,
    ModelEnabled = true,

    -- Independent 2D cursor marker and ring halo.
    MarkerEnabled = false,
    MarkerName = "circle_1",
    MarkerColorR = 1.0, MarkerColorG = 1.0, MarkerColorB = 1.0,
    MarkerScale = 1.0,
    MarkerOfsX = 0, MarkerOfsY = 0,
    MarkerAlpha = 1.0,

    HaloEnabled = false,
    -- 0.0.6.0 halo system. HaloName is retained only for downgrade compatibility.
    HaloName = "ring_soft_1",
    HaloShape = "circle",
    HaloStyle = "solid",
    HaloThickness = 1,
    HaloColorR = 1.0, HaloColorG = 1.0, HaloColorB = 1.0,
    HaloScale = 1.0,
    HaloAlpha = 1.0,
    -- 0.0.6.3: rotation is an independent halo property for both styles.
    HaloRotationEnabled = false,
    HaloRotationInverted = false,
    HaloRotationSeconds = 8
}

kDefaultConfig2 = CopyTable(kDefaultConfig)
kDefaultConfig2.UserScale = 1.33
kDefaultConfig2.UserOfsX = 2.8
kDefaultConfig2.UserOfsY = -2.0
kDefaultConfig2.UserAlpha = 0.50

kDefaultConfig3 = CopyTable(kDefaultConfig)
kDefaultConfig3.UserScale = 0.50
kDefaultConfig3.UserOfsX = 2.7
kDefaultConfig3.UserOfsY = -2.2
kDefaultConfig3.UserAlpha = 1.0

kDefaultConfig4 = CopyTable(kDefaultConfig)
kDefaultConfig4.UserScale = 0.10
kDefaultConfig4.UserOfsX = 0
kDefaultConfig4.UserOfsY = 0
kDefaultConfig4.UserAlpha = 1.0

--:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
--[[                       Switches                                          ]]
--:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

kAlwaysUseDefaults = false  -- Set to true to prevent using saved settings.

--:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
--[[                       Variables                                         ]]
--:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

LButtonDownCount = 0

-- Timer variables:
Timer1 = 0
kTimer1Interval = 0.250 -- seconds

--:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
--[[                       Helper Functions                                  ]]
--:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

-------------------------------------------------------------------------------
function PlayerConfig_Save()
    assert(PlayerConfig)
    Globals.CursorTrail_PlayerConfig = PlayerConfig
end

-- 0.0.5.12 migrates the single legacy Shape layer by semantics. Ring shapes
-- become Halo settings; Circle/Glow/Cross/Swirl become Marker settings.
-- Legacy fields are intentionally left intact so rolling back to 0.0.5.11
-- does not destroy the player's previous Shape selection.
local kLegacyHaloKeys = {
    ring_1 = true, ring_2 = true, ring_3 = true, ring_4 = true,
    ring_soft_1 = true, ring_soft_2 = true,
}

local function MigrateLegacyShapeConfig(config)
    if type(config) ~= "table" then return end

    local alreadyMigrated = (config.MarkerEnabled ~= nil or config.MarkerName ~= nil
        or config.HaloEnabled ~= nil or config.HaloName ~= nil)
    if alreadyMigrated or config.ShapeName == nil then return end

    local enabled = (config.ShapeEnabled == true)
    local r = config.ShapeColorR or 1.0
    local g = config.ShapeColorG or 1.0
    local b = config.ShapeColorB or 1.0
    local scale = config.ShapeScale or 1.0
    local alpha = config.ShapeAlpha or 1.0

    if kLegacyHaloKeys[config.ShapeName] then
        config.HaloEnabled = enabled
        config.HaloName = config.ShapeName
        config.HaloColorR, config.HaloColorG, config.HaloColorB = r, g, b
        config.HaloScale, config.HaloAlpha = scale, alpha
        config.MarkerEnabled = false
    else
        config.MarkerEnabled = enabled
        config.MarkerName = config.ShapeName
        config.MarkerColorR, config.MarkerColorG, config.MarkerColorB = r, g, b
        config.MarkerScale, config.MarkerAlpha = scale, alpha
        config.MarkerOfsX, config.MarkerOfsY = 0, 0
        config.HaloEnabled = false
    end
end

-- 0.0.6.0 converts the old ring-name selector into the new semantic halo
-- controls.  The legacy HaloName field is intentionally preserved, so a user
-- can return to the stable 0.0.5.20 branch without losing the old selection.
local kLegacyHaloThickness = {
    ring_1 = 1, ring_2 = 2, ring_3 = 3, ring_4 = 4,
    ring_soft_1 = 1, ring_soft_2 = 2,
}

local function MigrateHalo600Config(config)
    if type(config) ~= "table" then return end
    if config.HaloShape == nil then config.HaloShape = "circle" end
    if config.HaloStyle == nil then config.HaloStyle = "solid" end
    if config.HaloThickness == nil then
        config.HaloThickness = kLegacyHaloThickness[config.HaloName] or 1
    end
end

-- 0.0.6.3 makes rotation an explicit halo option instead of an automatic
-- spectral-only behavior.  When upgrading 0.0.6.2 data, preserve what the
-- player previously saw: spectral halos start with rotation enabled, while
-- solid/one-color halos stay static until the user enables rotation.
local function NormalizeHaloRotationSeconds(value)
    value = tonumber(value) or 8
    if value < 4 then value = 4 end
    if value > 12 then value = 12 end
    value = 4 + floor(((value - 4) / 2) + 0.5) * 2
    if value < 4 then value = 4 end
    if value > 12 then value = 12 end
    return value
end

local function MigrateHalo603Config(config)
    if type(config) ~= "table" then return end
    if config.HaloRotationEnabled == nil then
        config.HaloRotationEnabled = (config.HaloStyle == "spectral")
    else
        config.HaloRotationEnabled = (config.HaloRotationEnabled == true)
    end
    config.HaloRotationSeconds = NormalizeHaloRotationSeconds(config.HaloRotationSeconds)
end

-- 0.0.6.4 adds an optional direction inversion.  Existing configurations keep
-- the validated counter-clockwise direction unless the user explicitly enables it.
local function MigrateHalo604Config(config)
    if type(config) ~= "table" then return end
    config.HaloRotationInverted = (config.HaloRotationInverted == true)
end

-------------------------------------------------------------------------------
function PlayerConfig_Load()
    local savedConfig = Globals.CursorTrail_PlayerConfig

    -- SavedVariables are external data.  If the file is missing/corrupt,
    -- rebuild a valid table instead of allowing PlayerConfig to stay nil.
    if (type(savedConfig) ~= "table") then
        savedConfig = {}
    end

    PlayerConfig = savedConfig
    MigrateLegacyShapeConfig(PlayerConfig)
    MigrateHalo600Config(PlayerConfig)
    MigrateHalo603Config(PlayerConfig)
    MigrateHalo604Config(PlayerConfig)

    -- Migrate/repair old or incomplete profiles without overwriting settings
    -- that are still valid.
    for key, defaultValue in pairs(kDefaultConfig) do
        if (PlayerConfig[key] == nil) then
            PlayerConfig[key] = defaultValue
        end
    end

    PlayerConfig.Version = kTheVersion
    PlayerConfig_Save()

    ----HandleToolSwitches("test1")  -- EXPERIMENT
end

-------------------------------------------------------------------------------
-- Shared user profiles are deliberately separate from the per-character
-- CursorTrail_PlayerConfig table.  Only values exposed by the options UI are
-- copied, never the service Version field or model calibration fields.
local kProfileFields = {
    "TrailKey", "UserScale", "UserOfsX", "UserOfsY", "UserAlpha",
    "UserShowOnlyInCombat", "ModelEnabled",
    "MarkerEnabled", "MarkerName", "MarkerColorR", "MarkerColorG", "MarkerColorB",
    "MarkerScale", "MarkerOfsX", "MarkerOfsY", "MarkerAlpha",
    "HaloEnabled", "HaloName", "HaloShape", "HaloStyle", "HaloThickness",
    "HaloColorR", "HaloColorG", "HaloColorB", "HaloScale", "HaloAlpha",
    "HaloRotationEnabled", "HaloRotationInverted", "HaloRotationSeconds"
}

function ProfilesDB_Load()
    local db = Globals.CursorTrail_ProfilesDB
    if (type(db) ~= "table") then
        db = {}
        Globals.CursorTrail_ProfilesDB = db
    end
    if (type(db.Profiles) ~= "table") then
        db.Profiles = {}
    end
    if (db.Version == nil) then
        db.Version = 1
    end
    for _, profile in pairs(db.Profiles) do
        MigrateLegacyShapeConfig(profile)
        MigrateHalo600Config(profile)
        MigrateHalo603Config(profile)
        MigrateHalo604Config(profile)
        -- 0.0.5.13 adds independent 2D-marker offsets.  Old profiles are
        -- centered by default instead of inheriting offsets from another profile.
        if (profile.MarkerOfsX == nil) then profile.MarkerOfsX = 0 end
        if (profile.MarkerOfsY == nil) then profile.MarkerOfsY = 0 end
    end
    return db
end

function Profile_NormalizeName(name)
    if (type(name) ~= "string") then return nil end
    name = string.gsub(name, "^%s+", "")
    name = string.gsub(name, "%s+$", "")
    if (name == "") then return nil end
    return name
end

function Profile_CreateFromConfig(config)
    local profile = {}
    for _, key in ipairs(kProfileFields) do
        profile[key] = config[key]
    end
    return profile
end

function Profile_ApplyToConfig(profile, config)
    if (type(profile) ~= "table" or type(config) ~= "table") then return false end
    MigrateLegacyShapeConfig(profile)
    MigrateHalo600Config(profile)
    MigrateHalo603Config(profile)
    MigrateHalo604Config(profile)
    for _, key in ipairs(kProfileFields) do
        if (profile[key] ~= nil) then
            config[key] = profile[key]
        end
    end
    return true
end

function Profile_Get(name)
    name = Profile_NormalizeName(name)
    if (not name) then return nil end
    local profile = ProfilesDB_Load().Profiles[name]
    if (type(profile) ~= "table") then return nil end
    return profile
end

function Profile_GetNames()
    local names = {}
    for name, profile in pairs(ProfilesDB_Load().Profiles) do
        if (type(name) == "string" and type(profile) == "table") then
            table.insert(names, name)
        end
    end
    table.sort(names)
    return names
end

function Profile_Save(name, config)
    name = Profile_NormalizeName(name)
    if (not name or type(config) ~= "table") then return false end
    ProfilesDB_Load().Profiles[name] = Profile_CreateFromConfig(config)
    return true, name
end

function Profile_Delete(name)
    name = Profile_NormalizeName(name)
    if (not name) then return false end
    local profiles = ProfilesDB_Load().Profiles
    if (profiles[name] == nil) then return false end
    profiles[name] = nil
    return true
end

-------------------------------------------------------------------------------
function isEmpty(var)  -- Returns true if the variable is nil, or is an empty table {}.
    if (var == nil or next(var) == nil) then return true else return false end
end

-------------------------------------------------------------------------------
function setGameFrame()
    local w1, h1 = Globals.WorldFrame:GetSize()
    local scale1 = Globals.WorldFrame:GetEffectiveScale()
    w1, h1 = floor(w1*scale1), floor(h1*scale1)

    local w2, h2 = Globals.UIParent:GetSize()
    local scale2 = Globals.UIParent:GetEffectiveScale()
    w2, h2 = floor(w2*scale2), floor(h2*scale2)

    if (w1 ~= w2 or h1 ~= h2) then 
        -- Use UIParent to be compatible with addons that change game's view port size.
        kGameFrame = Globals.UIParent
        ----print(kTheTitle.." using UIParent.")
    else
        -- Use WorldFrame so fullscreen world map doesn't break this addon.
        kGameFrame = Globals.WorldFrame  
        ----print(kTheTitle.." using WorldFrame.")
    end
end
setGameFrame() -- Sets kGameFrame.
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - --
function getScreenSize()        return kGameFrame:GetSize()           end
function getScreenScale()       return kGameFrame:GetEffectiveScale() end
function getScreenScaledSize()
    local uiScale = getScreenScale()
    local w, h =  getScreenSize()
    w = w * uiScale
    h = h * uiScale
    local midX = w / 2
    local midY = h / 2
    local hypotenuse = (w^2 + h^2) ^ 0.5
    return w, h, midX, midY, uiScale, hypotenuse
end


--:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
--[[                    Register for Slash Commands                          ]]
--:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

-------------------------------------------------------------------------------
Globals.SLASH_CursorTrail1 = "/"..kTheTitle
Globals.SLASH_CursorTrail2 = "/ct"
Globals.SlashCmdList["CursorTrail"] = function (params)
    local usageMsg = kDisplayTitle.." "..kTheVersion.." "..L("COMMANDS").."\n"
                    .. "  /ct reload - "..L("CMD_RELOAD").."\n"
                    .. "  /ct reset - "..L("CMD_RESET").."\n"
                    .. "  /ct combat - "..L("CMD_COMBAT").."\n"
                    .. "  /ct screen - "..L("CMD_SCREEN").."\n"
                    .. "  /ct camera - "..L("CMD_CAMERA").."\n"
                    .. "  /ct config - "..L("CMD_CONFIG").."\n"
                    .. "  /ct model - "..L("CMD_MODEL").."\n"
                    .. "  /ct cal - "..L("CMD_CAL").."\n"
    -- - - - - - - - - - - - - - - - - - - - - - - - - - -
    if (params == nil or params == "") then
        if OptionsFrame:IsShown() then OptionsFrame:Hide() else OptionsFrame:Show() end
        ----print(usageMsg)
        return
    end

    params = string.lower(params)
    paramAsNum = tonumber(params)

    -- Hidden localization test switch.  It is intentionally omitted from the
    -- normal help text.  The selected language is applied on the next /reload.
    if (params == "english" or params == "en") then
        Locale_SetOverride("en")
        print(kTheTitle..": English interface selected. Type /reload to apply.")
        return
    elseif (params == "ru" or params == "russian") then
        Locale_SetOverride("ru")
        print(kTheTitle..": выбран русский интерфейс. Введите /reload для применения.")
        return
    end

    -- - - - - - - - - - - - - - - - - - - - - - - - - - -
    if (params == "help" or params == "?") then
        print(usageMsg)
    -- - - - - - - - - - - - - - - - - - - - - - - - - - -
    elseif (params == "reset") then
        PlayerConfig_SetDefaults()
        CursorModel_Load()
        print(kTheTitle.." "..L("RESET_DONE"))
    -- - - - - - - - - - - - - - - - - - - - - - - - - - -
    elseif (params == "reload") then
        CursorModel_Load()
        print(kTheTitle.." "..L("RELOAD_DONE"))
    -- - - - - - - - - - - - - - - - - - - - - - - - - - -
    elseif (params == "combat") then
        if (PlayerConfig.UserShowOnlyInCombat == true) then
            PlayerConfig.UserShowOnlyInCombat = false
            print(kTheTitle.." "..L("MODE_ALWAYS"))
        else
            PlayerConfig.UserShowOnlyInCombat = true
            print(kTheTitle.." "..L("MODE_COMBAT"))
        end
        PlayerConfig_Save()
        CursorModel_Load(PlayerConfig)
    -- - - - - - - - - - - - - - - - - - - - - - - - - - -
    elseif (HandleToolSwitches(params) ~= true) then
        print(kTheTitle..": "..L("INVALID_COMMAND").." ("..params..").")
    end
    -- - - - - - - - - - - - - - - - - - - - - - - - - - -
end

--:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
--[[                       Event Handlers                                    ]]
--:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

local EventFrame = CreateFrame("Frame")

-------------------------------------------------------------------------------
EventFrame:SetScript("OnEvent", function(self, event, ...)
	-- This calls a method named after the event, passing in all the relevant args.
    -- Example:  MyAddon.frame:RegisterEvent("XYZ") calls function MyAddon.frame:XYZ()
    --           with arguments named arg1, arg2, etc.
	self[event](self, ...)
end)

-------------------------------------------------------------------------------
EventFrame:RegisterEvent("ADDON_LOADED")
function       EventFrame:ADDON_LOADED(addonName)
    if (addonName ~= kTheTitle) then return end
    self:UnregisterEvent("ADDON_LOADED")

    -- ADDON_LOADED is the first reliable point at which this addon's
    -- SavedVariablesPerCharacter are available.  Load the visual settings,
    -- then refresh the hidden locale override before showing any user text.
    Addon_Initialize()
    if Locale_RefreshFromSaved then Locale_RefreshFromSaved() end
    print("|c7f7f7fff".. kDisplayTitle .." ".. kTheVersion .." "..L("LOADED").."|r") -- Color format = xRGB.
end

-------------------------------------------------------------------------------
EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
function       EventFrame:PLAYER_ENTERING_WORLD()
    -- SavedVariables are already loaded by ADDON_LOADED.  Screen geometry,
    -- however, belongs to the world/UI stage and must be initialized before
    -- CursorModel_ApplyUserSettings() uses ScreenHypotenuse.
    setGameFrame()
    ScreenW, ScreenH, ScreenMidX, ScreenMidY, ScreenScale, ScreenHypotenuse = getScreenScaledSize()
    CursorModel_Load()
end

-------------------------------------------------------------------------------
EventFrame:RegisterEvent("UI_SCALE_CHANGED")
function       EventFrame:UI_SCALE_CHANGED()
    setGameFrame()
    ScreenW, ScreenH, ScreenMidX, ScreenMidY, ScreenScale, ScreenHypotenuse = getScreenScaledSize()
    if CursorModel then
        -- Reload the cursor model to apply the new UI scale.
        CursorModel_Load() 
    end
end

-------------------------------------------------------------------------------
EventFrame:RegisterEvent("PLAYER_LOGOUT")
function       EventFrame:PLAYER_LOGOUT()
    PlayerConfig_Save()
end

-------------------------------------------------------------------------------
EventFrame:RegisterEvent("CINEMATIC_START")
function       EventFrame:CINEMATIC_START() CursorModel_Hide() end

-------------------------------------------------------------------------------
EventFrame:RegisterEvent("CINEMATIC_STOP")
function       EventFrame:CINEMATIC_STOP() CursorModel_Show() end

-------------------------------------------------------------------------------
EventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")  -- Combat started.
function       EventFrame:PLAYER_REGEN_DISABLED() 
    if (PlayerConfig.UserShowOnlyInCombat == true) then CursorModel_Show() end
end

-------------------------------------------------------------------------------
EventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")  -- Combat ended.
function       EventFrame:PLAYER_REGEN_ENABLED()  
    if (PlayerConfig.UserShowOnlyInCombat == true) then CursorModel_Hide() end
end

-------------------------------------------------------------------------------
EventFrame:SetScript("OnUpdate", function(self, elapsedSeconds)
    if (not CursorModel) then return end

    -- 0.0.6.4: do not spend cursor-tracking work on layers the user disabled.
    -- If every visual layer is off, skip GetCursorPosition() entirely.
    local modelEnabled = not (CursorModel.Config and CursorModel.Config.ModelEnabled == false)
    local shapeEnabled = (Shape_HasEnabledLayer and Shape_HasEnabledLayer()) or false
    if not modelEnabled and not shapeEnabled then return end

    Timer1 = Timer1 + elapsedSeconds
    local cursorX, cursorY = GetCursorPosition()
    if (cursorX ~= PreviousX or cursorY ~= PreviousY) then
        -- Cursor position changed.  Keep only enabled layers in sync with it.
        PreviousX, PreviousY = cursorX, cursorY

        if shapeEnabled and Shape_UpdatePosition then Shape_UpdatePosition(cursorX, cursorY) end

        if modelEnabled and Calibrating ~= true then
            ----cursorX, cursorY = Unrotate(cursorX, cursorY)  -- EXPERIMENT
            
            -- Only the selected 3D trail receives the donor's unskew compensation.
            local modelCursorX, modelCursorY = cursorX, cursorY
            local trailConfig = CursorModel.TrailConfig
            if trailConfig and trailConfig.IsSkewed == true then
                modelCursorX, modelCursorY = CursorModel_Unskew(modelCursorX, modelCursorY,
                    trailConfig.HorizontalSlope, trailConfig.SkewTopMult, trailConfig.SkewBottomMult)
            end

            local modelX = ((modelCursorX - ScreenMidX) / CursorModel.StepX) + CursorModel.OfsX
            local modelY = ((modelCursorY - ScreenMidY) / CursorModel.StepY) + CursorModel.OfsY
            CursorModel:SetPosition(0, modelX, modelY)
        end
    end
    
    -- Hide cursor effect during "mouse look" mode.
    if (Calibrating == true) then return end

    -- electric_blue_long only: while the options window is open, dragging a
    -- slider holds the left mouse button down.  The legacy mouselook heuristic
    -- can mistake that UI drag for mouselook, temporarily force alpha to zero,
    -- and then restore an older alpha value.  Do not apply this bypass to any
    -- other trail; their original 0.0.5.18 behavior is intentionally preserved.
    if (CursorPreviewMode == true
        and CursorModel
        and CursorModel.TrailConfig
        and CursorModel.TrailConfig.key == "electric_blue_long"
       ) then
        LButtonDownCount = 0
        return
    end

    if (Timer1 >= kTimer1Interval) then
        Timer1 = 0

        if IsMouseButtonDown("LeftButton") then
            LButtonDownCount = LButtonDownCount + 1
        else
            LButtonDownCount = 0
        end
        
        local bHide = (IsMouselooking() or (IsMouseButtonDown("LeftButton") and LButtonDownCount > 1))
        if bHide then
            if (CursorModel.IsHidden ~= true or (ShapeTexture and ShapeTexture:IsShown())) then
                CursorModel_Hide()
            end
        else
            if (CursorModel.IsHidden == true or (ShapeTexture and not ShapeTexture:IsShown())) then
                CursorModel_Show()
            end
        end
    end    
end)


--:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
--[[                            Hooks                                        ]]
--:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

-------------------------------------------------------------------------------
-- Hide during movies.
Globals.MovieFrame:HookScript("OnShow", function() CursorModel_Hide() end)
Globals.MovieFrame:HookScript("OnHide", function() CursorModel_Show() end)

--:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
--[[                            Functions                                    ]]
--:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

-------------------------------------------------------------------------------
function Addon_Initialize()
    -- Initialize persistent variables only.  The cursor model itself is
    -- created from PLAYER_ENTERING_WORLD, after screen geometry is valid.
    if (kAlwaysUseDefaults == true) then
        PlayerConfig_SetDefaults()
    else
        -- Always bind/validate PlayerConfig from SavedVariables now that
        -- ADDON_LOADED guarantees they are available.
        PlayerConfig_Load()
    end
    ProfilesDB_Load()
end

-------------------------------------------------------------------------------
function PlayerConfig_SetDefaults()
    PlayerConfig = {}  -- Must clear all existing fields first!
    PlayerConfig = CopyTable(kDefaultConfig)
    PlayerConfig_Save()
end

-------------------------------------------------------------------------------
function CursorModel_Init()
    if CursorModel then
        CursorModel:ClearModel()
        CursorModel:SetScale(1)  -- Very important!
        CursorModel:SetPosition(0, 0, 0)  -- Very Important!
        CursorModel:SetAlpha(1.0)

        CursorModel.Config = nil
        CursorModel.TrailConfig = nil
        CursorModel.OfsX = nil
        CursorModel.OfsY = nil
        CursorModel.StepX = nil
        CursorModel.StepY = nil
        CursorModel.IsHidden = nil
    end        
end

-------------------------------------------------------------------------------
function CursorModel_Unskew(inX, inY, inHorizontalSlope, topMult, bottomMult)
    -- Exact 8.2.0.6 donor math for models with baked-in perimeter skewing.
    local x, y = inX, inY
    local dx = inX - ScreenMidX
    local dy = inY - ScreenMidY

    topMult = topMult or 0.985
    bottomMult = bottomMult or 1.105
    inHorizontalSlope = inHorizontalSlope or 0

    local vertRange = topMult - bottomMult
    local multX = bottomMult + (vertRange * inY / ScreenH)
    x = ScreenMidX + (dx * multX)

    if (dy < 0) then
        y = ScreenMidY + (dy * 1.11)
    else
        y = ScreenMidY + (dy * 0.99)
    end

    y = y - (inHorizontalSlope * dx / ScreenMidX)
    return x, y
end

-------------------------------------------------------------------------------
function CursorModel_Load(config)
    -- Handle nil parameter.
    if (not config) then config = PlayerConfig end
    config.UserScale = config.UserScale or 1

    local trailConfig = Trail_GetConfig(config.TrailKey)

    -- Keep trails that need an explicit 3D orientation on a separate
    -- PlayerModel frame.  SetPitch/SetRoll/SetFacing state survives
    -- ClearModel()/SetModel() on Legion, so reusing the same frame lets the
    -- Light/Freedom transform contaminate the proven native orientation of
    -- electric_blue_long.  Two persistent frames avoid that state leak while
    -- still keeping frame creation bounded.
    local needsOrientation = (trailConfig.BasePitch ~= nil
        or trailConfig.BaseRoll ~= nil
        or trailConfig.BaseFacing ~= nil)

    if needsOrientation then
        if not CursorModelOriented then
            CursorModelOriented = CreateFrame("PlayerModel", nil, kGameFrame)
            CursorModelOriented:SetAllPoints()
            CursorModelOriented:SetFrameStrata("TOOLTIP")
        end
        -- IMPORTANT (Legion 7.3.5): do not use frame:Hide() to park an
        -- inactive PlayerModel.  CursorTrail's original implementation already
        -- avoids Show()/Hide() for the visual effect because PlayerModel does
        -- not reliably recover from it.  0.0.5.3 used :Hide() while swapping
        -- the dedicated Light frame and the normal frame; after selecting
        -- Light the native frame stayed hidden, so every normal trail became
        -- invisible until /reload.  Park the inactive frame with alpha only.
        if CursorModelNative then
            CursorModelNative:SetAlpha(0)
            CursorModelNative.IsHidden = true
        end
        CursorModel = CursorModelOriented
    else
        if not CursorModelNative then
            CursorModelNative = CreateFrame("PlayerModel", nil, kGameFrame)
            CursorModelNative:SetAllPoints()
            CursorModelNative:SetFrameStrata("TOOLTIP")
        end
        if CursorModelOriented then
            CursorModelOriented:SetAlpha(0)
            CursorModelOriented.IsHidden = true
        end
        CursorModel = CursorModelNative
    end

    -- Recover cleanly even if this session previously ran a 0.0.5.3 frame
    -- that had been hidden.  From this point on visibility is alpha-driven.
    if CursorModel.Show then CursorModel:Show() end
    CursorModel_Init()
    -- Do not substitute a different trail if this specific spell model is
    -- unavailable in the Legion client.  The diagnostic selection remains
    -- visible to the player and SetModel does not raise a Lua error.
    CursorModel:SetModel(trailConfig.Path)
    CursorModel:SetCustomCamera(1)  -- Very important! (CursorModel:SetCamera(1) doesn't work here.)

    -- Only apply orientation transforms on the dedicated oriented frame.
    -- The native frame never receives Pitch/Roll/Facing calls, preserving the
    -- original long-blue orientation even after the player tested Light.
    if trailConfig.BasePitch ~= nil and CursorModel.SetPitch then
        CursorModel:SetPitch(trailConfig.BasePitch)
    end
    if trailConfig.BaseRoll ~= nil and CursorModel.SetRoll then
        CursorModel:SetRoll(trailConfig.BaseRoll)
    end
    if trailConfig.BaseFacing ~= nil and CursorModel.SetFacing then
        CursorModel:SetFacing(trailConfig.BaseFacing)
    end

    CursorModel.Config = CopyTable(config)
    CursorModel.Config.TrailKey = trailConfig.key
    CursorModel.TrailConfig = trailConfig
    CursorModel_ApplyUserSettings(config.UserScale, config.UserOfsX, config.UserOfsY, config.UserAlpha)
    if Shape_Load then Shape_Load(config) end
    CursorModel_Show()
end

-------------------------------------------------------------------------------
function CursorModel_ApplyUserSettings(userScale, userOfsX, userOfsY, userAlpha)
    ----print("userScale="..(userScale or "NIL")..", userOfs=("..(userOfsX or "NIL")..", "..(userOfsY or "NIL")..")")
    local config = CursorModel.Config
    local trailConfig = CursorModel.TrailConfig
    assert(config)
    assert(trailConfig)

    if (userScale == nil or userScale <= 0) then 
        userScale = PlayerConfig.UserScale
    end
    userOfsX = userOfsX or PlayerConfig.UserOfsX
    userOfsY = userOfsY or PlayerConfig.UserOfsY
    if (userAlpha == nil or userAlpha <= 0) then
        userAlpha = PlayerConfig.UserAlpha or 1.0
    end

    -- electric_blue_long only: CursorModel_Show() restores opacity from the
    -- model's copied config after a temporary hide.  Keep that one model's
    -- copied alpha synchronized with the live slider value so Size/X/Y drags
    -- cannot make it latch onto an older opacity.  Other trails deliberately
    -- retain the exact 0.0.5.18 update behavior.
    if trailConfig.key == "electric_blue_long" then
        config.UserAlpha = userAlpha
    end

    -- Compute step size and offset.
    local finalScale = userScale * trailConfig.BaseScale
    CursorModel:SetScale(finalScale)
    CursorModel.StepX = trailConfig.BaseStepX * kBaseMult * finalScale * ScreenHypotenuse
    CursorModel.StepY = trailConfig.BaseStepY * kBaseMult * finalScale * ScreenHypotenuse

    -- Normalize the user's -20..+20 offset controls to the proven long-blue
    -- lightning.  In 0.0.5 the same UI +1 moved models with BaseStep ~= 3400
    -- roughly an order of magnitude farther than the long lightning because
    -- physical displacement is proportional to BaseStep * BaseScale.
    -- Keeping one reference product makes +1 feel equally small/smooth on all
    -- trails without changing the UI range.
    local referenceStepScaleX = 471 * 0.05
    local referenceStepScaleY = 471 * 0.05
    local modelStepScaleX = trailConfig.BaseStepX * trailConfig.BaseScale
    local modelStepScaleY = trailConfig.BaseStepY * trailConfig.BaseScale
    local userOfsMultX = 1
    local userOfsMultY = 1
    if modelStepScaleX ~= 0 then userOfsMultX = referenceStepScaleX / modelStepScaleX end
    if modelStepScaleY ~= 0 then userOfsMultY = referenceStepScaleY / modelStepScaleY end

    -- CalOfsX/Y are hidden factory calibration values measured with the old
    -- raw offset behavior.  They center a trail at UI X=0/Y=0 and are never
    -- stored in character settings or profiles.
    local calOfsX = trailConfig.CalOfsX or 0
    local calOfsY = trailConfig.CalOfsY or 0
    local normalizedUserOfsX = userOfsX * userOfsMultX
    local normalizedUserOfsY = userOfsY * userOfsMultY

    CursorModel.OfsX = ((trailConfig.BaseOfsX * kBaseMult * ScreenHypotenuse) + calOfsX + normalizedUserOfsX) / userScale
    CursorModel.OfsY = ((trailConfig.BaseOfsY * kBaseMult * ScreenHypotenuse) + calOfsY + normalizedUserOfsY) / userScale

    CursorModel:SetAlpha(userAlpha)

    PreviousX = nil  -- Forces model to refresh during the next OnUpdate().
end

-------------------------------------------------------------------------------
function CursorModel_SetPreviewMode(enabled)
    CursorPreviewMode = (enabled == true)
end

-------------------------------------------------------------------------------
function CursorModel_SetEnabled(enabled)
    if CursorModel and CursorModel.Config then
        CursorModel.Config.ModelEnabled = (enabled ~= false)
    end
end

-------------------------------------------------------------------------------
function CursorModel_Show(bForceShow)
    if (bForceShow ~= true
        and CursorPreviewMode ~= true
        and PlayerConfig.UserShowOnlyInCombat == true
        and not UnitAffectingCombat("player")
       ) then
        -- Only show the cursor model during combat.
        return CursorModel_Hide()  
    end

    -- Note: The normal Show() and Hide() don't work right (reason unknown).
    if CursorModel then
        if CursorModel.Config and CursorModel.Config.ModelEnabled == false then
            CursorModel:SetAlpha(0)
            CursorModel.IsHidden = true
        elseif CursorModel.IsHidden ~= false then
            local alpha = CursorModel.Config.UserAlpha or 1.0
            CursorModel:SetAlpha(alpha)
            CursorModel.IsHidden = false
        end
    end

    if Shape_Show then Shape_Show() end
end

-------------------------------------------------------------------------------
function CursorModel_Hide()
    -- Note: The normal Show() and Hide() don't work right (reason unknown).
    if (CursorModel and CursorModel.IsHidden ~= true) then
        CursorModel:SetAlpha(0)
        CursorModel.IsHidden = true
    end
    if Shape_Hide then Shape_Hide() end
end

--- End of File ---
