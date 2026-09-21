--[[---------------------------------------------------------------------------
    Addon:  CursorTrail
    File:   CursorTrailTrails.lua
    Desc:   Legion-compatible catalog of selectable 3D cursor trails.

    Original addon: CursorTrail by UppyDan (DJU)
    Trail geometry is transcribed from the CursorTrail 8.2.0.6 donor catalog.
-----------------------------------------------------------------------------]]

local CopyTable = _G.CopyTable
local ipairs = _G.ipairs

local CursorTrail = _G.CursorTrail or {}
if (not _G.CursorTrail) then _G.CursorTrail = CursorTrail end

setfenv(1, _G.CursorTrail)

local kDefaultTrailKey = "electric_blue_long"

-- The donor stores these entries by ModelID and documents their spell paths in
-- comments.  Legion uses the corresponding spell .mdx paths below.  The first
-- entry intentionally retains the proven 0.0.4.1 geometry, not the donor's.
local kTrailOptions = {
    {
        key = "electric_blue_long", nameKey = "TRAIL_ELECTRIC_BLUE_LONG",
        Path = "spells\\lightningboltivus_missile.mdx",
        BaseScale = 0.05, BaseOfsX = -0.3, BaseOfsY = 4.3,
        BaseStepX = 471, BaseStepY = 471,
        IsSkewed = false, HorizontalSlope = 0,
        CalOfsX = 0, CalOfsY = 0,
    },
    {
        key = "electric_blue", nameKey = "TRAIL_ELECTRIC_BLUE_SHORT",
        Path = "spells\\lightning_precast_low_hand.mdx",
        BaseScale = 0.1, BaseOfsX = 0, BaseOfsY = 0,
        BaseStepX = 3430, BaseStepY = 3155,
        IsSkewed = true, HorizontalSlope = 0,
        -- 0.0.5.2 live test: UI Y=+2 is the visual center.
        CalOfsX = 0, CalOfsY = 0.1492868463,
    },
    {
        key = "electric_green", nameKey = "TRAIL_ELECTRIC_GREEN_SHORT",
        Path = "spells\\lightning_fel_precast_low_hand.mdx",
        BaseScale = 0.11, BaseOfsX = 0, BaseOfsY = 0,
        BaseStepX = 3430, BaseStepY = 3155,
        IsSkewed = true, HorizontalSlope = 0,
        -- 0.0.5.2 live test: UI Y=+2 is the visual center.
        CalOfsX = 0, CalOfsY = 0.1357153148,
    },
    {
        key = "electric_green_pulse", nameKey = "TRAIL_ELECTRIC_GREEN_PULSE",
        Path = "spells\\wrath_precast_hand.mdx",
        BaseScale = 0.08, BaseOfsX = 0, BaseOfsY = 0,
        BaseStepX = 3430, BaseStepY = 3155,
        IsSkewed = true, HorizontalSlope = 0,
        -- 0.0.5.2 live test: UI Y=+2 is the visual center.
        CalOfsX = 0, CalOfsY = 0.1866085578,
    },
    {
        key = "freedom", nameKey = "TRAIL_LIGHT",
        Path = "spells\\blessingoffreedom_state.mdx",
        BaseScale = 0.022, BaseOfsX = 0.12, BaseOfsY = 7.7,
        BaseStepX = 3570, BaseStepY = 3563,
        IsSkewed = true, HorizontalSlope = 0,
        SkewTopMult = 0.995, SkewBottomMult = 1.05,
        -- 0.0.5.1 video: after the 90-degree pitch the model axis is usable,
        -- but its own center/orb sits roughly one screen-height below the cursor.
        -- Bake that vertical displacement into the factory center so UI 0/0
        -- starts on the cursor; user X/Y remains only fine adjustment.
        -- 0.0.5.2 screenshot centers the orb at UI X=+2/Y=+16.
        -- Convert those normalized UI steps into hidden factory calibration.
        CalOfsX = 0.5996944232, CalOfsY = 47.3069808384,
        -- Live tests showed the 90-degree pitch is the correct axis change:
        -- it turns the model face-on while preserving its own rotating ring.
        -- Do NOT add a BaseFacing rotation here: 0.0.5.4/0.0.5.6 proved that
        -- the second rotation hides/edges the ring and changes the visual pivot.
        BasePitch = 1.5707963267949,
    },
    {
        key = "ghost", nameKey = "TRAIL_GHOST",
        Path = "spells\\zig_missile.mdx",
        BaseScale = 0.02, BaseOfsX = 0, BaseOfsY = 0,
        BaseStepX = 3430, BaseStepY = 3155,
        IsSkewed = true, HorizontalSlope = 0,
        CalOfsX = 0, CalOfsY = 0,
    },
    {
        key = "pulse_green", nameKey = "TRAIL_PULSE_GREEN",
        Path = "spells\\banish_chest.mdx",
        BaseScale = 0.03, BaseOfsX = 0, BaseOfsY = -1.875,
        BaseStepX = 3380, BaseStepY = 3060,
        IsSkewed = true, HorizontalSlope = 0,
        -- 0.0.5.2 refinement: UI Y=-2 from the previous factory center.
        CalOfsX = 0, CalOfsY = -8.5130718954,
    },
    {
        key = "pulse_yellow", nameKey = "TRAIL_PULSE_YELLOW",
        Path = "spells\\banish_chest_yellow.mdx",
        BaseScale = 0.02, BaseOfsX = 0, BaseOfsY = -1.875,
        BaseStepX = 3380, BaseStepY = 3050,
        IsSkewed = true, HorizontalSlope = 0,
        -- Live-test center was User Y=-13 in 0.0.5.
        CalOfsX = 0, CalOfsY = -13,
    },
    {
        key = "swirl_nature", nameKey = "TRAIL_SWIRL_NATURE",
        Path = "spells\\rejuvenation_impact_base.mdx",
        BaseScale = 0.022, BaseOfsX = -1.3, BaseOfsY = 8.075,
        BaseStepX = 3550, BaseStepY = 3600,
        IsSkewed = true, HorizontalSlope = -8,
        SkewTopMult = 0.995, SkewBottomMult = 1.05,
        -- 0.0.5.11 live refinement: relative to the current factory center,
        -- UI X=-2 / Y=-6 is the visual center. Bake those normalized
        -- user steps into factory calibration so UI 0/0 is centered.
        CalOfsX = -8.6030729834, CalOfsY = 51.1893939394,
    },
    {
        -- Keep the original key for profile compatibility; only the visible
        -- name changes.  This is the validated rotating translucent sphere.
        key = "swirl_orange", nameKey = "TRAIL_SPHERE_ORANGE",
        Path = "spells\\firebomb_missle.mdx",
        BaseScale = 0.01, BaseOfsX = 0, BaseOfsY = 0.1,
        BaseStepX = 3420, BaseStepY = 3150,
        IsSkewed = true, HorizontalSlope = 0,
        -- Estimated center lies between old UI Y=2 and Y=3.
        CalOfsX = 0, CalOfsY = 2.4,
    },

}
local kTrailByKey = {}
for _, option in ipairs(kTrailOptions) do
    kTrailByKey[option.key] = option
end

function Trail_GetOptions()
    return kTrailOptions
end

function Trail_GetDefaultKey()
    return kDefaultTrailKey
end

function Trail_NormalizeKey(key)
    if kTrailByKey[key] then return key end
    return kDefaultTrailKey
end

function Trail_GetConfig(key)
    return CopyTable(kTrailByKey[Trail_NormalizeKey(key)])
end

function Trail_GetDisplayName(key)
    return L(kTrailByKey[Trail_NormalizeKey(key)].nameKey)
end

--- End of File ---
