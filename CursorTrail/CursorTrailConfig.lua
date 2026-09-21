--[[---------------------------------------------------------------------------
    Addon:  CursorTrail
    File:   CursorTrailConfig.lua
    Desc:   Configuration UI for CursorTrail 7.3.5 Extended.

    Original addon: CursorTrail by UppyDan (DJU)
    Extended adaptation: UI refresh for World of Warcraft: Legion 7.3.5 API.
-----------------------------------------------------------------------------]]

CursorTrail_PlayerConfig = CursorTrail_PlayerConfig or {}

-- Aliases to globals used by this file.
local Globals = _G
local assert = _G.assert
local CreateFrame = _G.CreateFrame
local CopyTable = _G.CopyTable
local ipairs = _G.ipairs
local PlaySound = _G.PlaySound
local SOUNDKIT = _G.SOUNDKIT
local tonumber = _G.tonumber
local tostring = _G.tostring
local string = _G.string
local math = _G.math
local GameTooltip = _G.GameTooltip
local ColorPickerFrame = _G.ColorPickerFrame
local UIParent = _G.UIParent
local UnitAffectingCombat = _G.UnitAffectingCombat
local InterfaceOptions_AddCategory = _G.InterfaceOptions_AddCategory
local UIDropDownMenu_CreateInfo = _G.UIDropDownMenu_CreateInfo
local UIDropDownMenu_Initialize = _G.UIDropDownMenu_Initialize
local UIDropDownMenu_AddButton = _G.UIDropDownMenu_AddButton
local UIDropDownMenu_SetText = _G.UIDropDownMenu_SetText
local UIDropDownMenu_SetWidth = _G.UIDropDownMenu_SetWidth
local UIDropDownMenu_SetButtonWidth = _G.UIDropDownMenu_SetButtonWidth
local UIDropDownMenu_JustifyText = _G.UIDropDownMenu_JustifyText
local CloseDropDownMenus = _G.CloseDropDownMenus
local StaticPopupDialogs = _G.StaticPopupDialogs
local StaticPopup_Show = _G.StaticPopup_Show

-- Namespace.
local CursorTrail = _G.CursorTrail or {}
if (not _G.CursorTrail) then _G.CursorTrail = CursorTrail end
setfenv(1, _G.CursorTrail)

-- ---------------------------------------------------------------------------
-- Layout constants.
-- ---------------------------------------------------------------------------
local WINDOW_W = 500
local WINDOW_H = 760
local MARGIN = 16
local CONTENT_LEFT = 28
local CONTROL_LEFT = 190
local CONTROL_W = 250
local ROW_GAP = 58

local function RoundToNearest(value)
    value = tonumber(value) or 0
    if value >= 0 then
        return math.floor(value + 0.5)
    end
    return math.ceil(value - 0.5)
end

-- ---------------------------------------------------------------------------
-- Small UI helpers.
-- ---------------------------------------------------------------------------
local function CreateText(parent, text, template, point, relativeTo, relativePoint, x, y)
    local fs = parent:CreateFontString(nil, "ARTWORK", template or "GameFontHighlight")
    fs:SetPoint(point or "TOPLEFT", relativeTo or parent, relativePoint or point or "TOPLEFT", x or 0, y or 0)
    fs:SetText(text or "")
    return fs
end

local function CreateSection(parent, title, topY, height)
    local section = CreateFrame("Frame", nil, parent)
    section:SetPoint("TOPLEFT", parent, "TOPLEFT", MARGIN, topY)
    section:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -MARGIN, topY)
    section:SetHeight(height)
    section:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    section:SetBackdropColor(0.035, 0.045, 0.06, 0.88)
    section:SetBackdropBorderColor(0.32, 0.36, 0.44, 0.9)

    local titleText = CreateText(section, title, "GameFontNormalLarge", "TOPLEFT", section, "TOPLEFT", 12, -8)
    titleText:SetTextColor(1.0, 0.82, 0.18)
    return section
end

local function CreateButton(parent, text, width, height)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(width or 90, height or 24)
    b:SetText(text)
    return b
end

local function CreateCheckBox(parent, label, tooltip)
    local cb = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    cb:SetSize(26, 26)
    cb.label = CreateText(parent, label, "GameFontHighlight", "LEFT", cb, "RIGHT", 4, 1)
    if tooltip and tooltip ~= "" then
        cb:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(label, 1, 0.82, 0.18)
            GameTooltip:AddLine(tooltip, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    return cb
end

local function CreateSlider(parent, label, minVal, maxVal, step, valueFormatter, tooltip, rangeText)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(CONTROL_W + 180, 38)

    holder.label = CreateText(holder, label, "GameFontHighlight", "LEFT", holder, "LEFT", 0, 6)
    holder.label:SetWidth(155)
    holder.label:SetJustifyH("LEFT")

    local slider = CreateFrame("Slider", nil, holder)
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetSize(CONTROL_W - 46, 16)
    slider:SetPoint("LEFT", holder, "LEFT", 160, 5)
    slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    slider:SetBackdrop({
        bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
        edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = { left = 3, right = 3, top = 6, bottom = 6 }
    })

    local editBox = CreateFrame("EditBox", nil, holder, "InputBoxTemplate")
    editBox:SetSize(54, 20)
    editBox:SetPoint("LEFT", slider, "RIGHT", 10, 0)
    editBox:SetAutoFocus(false)
    editBox:SetJustifyH("CENTER")

    if rangeText and rangeText ~= "" then
        local range = CreateText(holder, rangeText, "GameFontDisableSmall", "BOTTOMLEFT", holder, "BOTTOMLEFT", 160, 0)
        range:SetJustifyH("LEFT")
    end

    holder.slider = slider
    holder.editBox = editBox
    holder.formatValue = valueFormatter or function(v) return tostring(v) end
    holder.lastValidValue = minVal
    holder.suppressEditChanged = false

    function holder:NormalizeValue(v)
        if v < minVal then v = minVal end
        if v > maxVal then v = maxVal end
        if step and step > 0 then
            v = minVal + math.floor(((v - minVal) / step) + 0.5) * step
            if v < minVal then v = minVal end
            if v > maxVal then v = maxVal end
        end
        return v
    end

    function holder:ParseEditValue(text)
        text = string.gsub(text or "", "%s+", "")
        text = string.gsub(text, "%%", "")
        local value = tonumber(text)
        if not value then return nil end
        return self:NormalizeValue(value)
    end

    function holder:RefreshValue(v)
        v = self:NormalizeValue(v)
        self.lastValidValue = v
        self.suppressEditChanged = true
        self.editBox:SetText(self.formatValue(v))
        self.suppressEditChanged = false
    end

    function holder:CommitEditValue()
        local value = self:ParseEditValue(self.editBox:GetText())
        if value == nil then
            self:RefreshValue(self.lastValidValue or self.slider:GetValue())
            return false
        end
        self.slider:SetValue(value)
        self:RefreshValue(value)
        return true
    end

    slider:EnableMouseWheel(true)
    slider:SetScript("OnMouseWheel", function(self, delta)
        local v = self:GetValue() + (delta * step)
        if v < minVal then v = minVal end
        if v > maxVal then v = maxVal end
        self:SetValue(v)
    end)
    slider:SetScript("OnMouseUp", function()
        -- Restore the preview immediately after a long slider drag.
        CursorModel_Show(true)
    end)

    editBox:SetScript("OnTextChanged", function(self, userInput)
        if holder.suppressEditChanged or not userInput then return end
        local value = holder:ParseEditValue(self:GetText())
        if value ~= nil then
            holder.slider:SetValue(value)
        end
    end)
    editBox:SetScript("OnEnterPressed", function(self)
        holder:CommitEditValue()
        self:ClearFocus()
    end)
    editBox:SetScript("OnEditFocusLost", function()
        holder:CommitEditValue()
    end)
    editBox:SetScript("OnEscapePressed", function(self)
        holder:RefreshValue(holder.lastValidValue or holder.slider:GetValue())
        self:ClearFocus()
    end)
    holder:EnableMouse(true)
    if tooltip and tooltip ~= "" then
        local function ShowTip(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(label, 1, 0.82, 0.18)
            GameTooltip:AddLine(tooltip, 1, 1, 1, true)
            GameTooltip:Show()
        end
        holder:SetScript("OnEnter", ShowTip)
        holder:SetScript("OnLeave", function() GameTooltip:Hide() end)
        slider:SetScript("OnEnter", ShowTip)
        slider:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    return holder
end

local function CreateInlineSlider(parent, label, minVal, maxVal, step, valueFormatter, tooltip)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(215, 34)

    holder.label = CreateText(holder, label, "GameFontHighlight", "LEFT", holder, "LEFT", 0, 5)
    holder.label:SetWidth(82)
    holder.label:SetJustifyH("LEFT")

    local slider = CreateFrame("Slider", nil, holder)
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetSize(72, 16)
    slider:SetPoint("LEFT", holder, "LEFT", 84, 4)
    slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    slider:SetBackdrop({
        bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
        edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = { left = 3, right = 3, top = 6, bottom = 6 }
    })

    local editBox = CreateFrame("EditBox", nil, holder, "InputBoxTemplate")
    editBox:SetSize(48, 20)
    editBox:SetPoint("LEFT", slider, "RIGHT", 7, 0)
    editBox:SetAutoFocus(false)
    editBox:SetJustifyH("CENTER")

    holder.slider = slider
    holder.editBox = editBox
    holder.formatValue = valueFormatter or function(v) return tostring(v) end
    holder.lastValidValue = minVal
    holder.suppressEditChanged = false

    function holder:NormalizeValue(v)
        if v < minVal then v = minVal end
        if v > maxVal then v = maxVal end
        if step and step > 0 then
            v = minVal + math.floor(((v - minVal) / step) + 0.5) * step
            if v < minVal then v = minVal end
            if v > maxVal then v = maxVal end
        end
        return v
    end

    function holder:ParseEditValue(text)
        text = string.gsub(text or "", "%s+", "")
        text = string.gsub(text, "%%", "")
        local value = tonumber(text)
        if not value then return nil end
        return self:NormalizeValue(value)
    end

    function holder:RefreshValue(v)
        v = self:NormalizeValue(v)
        self.lastValidValue = v
        self.suppressEditChanged = true
        self.editBox:SetText(self.formatValue(v))
        self.suppressEditChanged = false
    end

    function holder:CommitEditValue()
        local value = self:ParseEditValue(self.editBox:GetText())
        if value == nil then
            self:RefreshValue(self.lastValidValue or self.slider:GetValue())
            return false
        end
        self.slider:SetValue(value)
        self:RefreshValue(value)
        return true
    end

    slider:EnableMouseWheel(true)
    slider:SetScript("OnMouseWheel", function(self, delta)
        local v = self:GetValue() + (delta * step)
        if v < minVal then v = minVal end
        if v > maxVal then v = maxVal end
        self:SetValue(v)
    end)
    slider:SetScript("OnMouseUp", function() CursorModel_Show(true) end)

    editBox:SetScript("OnTextChanged", function(self, userInput)
        if holder.suppressEditChanged or not userInput then return end
        local value = holder:ParseEditValue(self:GetText())
        if value ~= nil then holder.slider:SetValue(value) end
    end)
    editBox:SetScript("OnEnterPressed", function(self)
        holder:CommitEditValue()
        self:ClearFocus()
    end)
    editBox:SetScript("OnEditFocusLost", function() holder:CommitEditValue() end)
    editBox:SetScript("OnEscapePressed", function(self)
        holder:RefreshValue(holder.lastValidValue or holder.slider:GetValue())
        self:ClearFocus()
    end)

    if tooltip and tooltip ~= "" then
        local function ShowTip(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(label, 1, 0.82, 0.18)
            GameTooltip:AddLine(tooltip, 1, 1, 1, true)
            GameTooltip:Show()
        end
        holder:EnableMouse(true)
        holder:SetScript("OnEnter", ShowTip)
        holder:SetScript("OnLeave", function() GameTooltip:Hide() end)
        slider:SetScript("OnEnter", ShowTip)
        slider:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    return holder
end

-- Fine-tune compact two-column controls without changing their behavior.
-- labelWidth controls the visual gap after the label; sliderX is the slider's
-- horizontal anchor inside the 215px holder.
local function TuneInlineSlider(holder, labelWidth, sliderX)
    if not holder then return end
    holder.label:SetWidth(labelWidth)
    holder.slider:ClearAllPoints()
    holder.slider:SetPoint("LEFT", holder, "LEFT", sliderX, 4)
    holder.editBox:ClearAllPoints()
    holder.editBox:SetPoint("LEFT", holder.slider, "RIGHT", 7, 0)
end

local function SetColorSwatch(swatch, r, g, b)
    swatch.r, swatch.g, swatch.b = r, g, b
    swatch.texture:SetVertexColor(r, g, b)
end

local function CreateColorSwatch(parent, tooltip)
    local swatch = CreateFrame("Button", nil, parent)
    swatch:SetSize(24, 24)
    swatch:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    swatch.texture = swatch:CreateTexture(nil, "ARTWORK")
    swatch.texture:SetAllPoints()
    swatch.texture:SetTexture("Interface\\Buttons\\WHITE8X8")
    SetColorSwatch(swatch, 1, 1, 1)

    swatch:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L("COLOR"), 1, 0.82, 0.18)
        GameTooltip:AddLine(tooltip, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    swatch:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return swatch
end

local function SetMarkerDropDownValue(dropdown, key)
    if not Marker_IsKey(key) then key = "circle_1" end
    dropdown.shapeKey = key
    UIDropDownMenu_SetText(dropdown, Marker_GetDisplayName(key))
end

local function CreateMarkerDropDown(parent)
    local dropdown = CreateFrame("Frame", "CursorTrailMarkerDropDown", parent, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(dropdown, 150)
    UIDropDownMenu_SetButtonWidth(dropdown, 170)
    UIDropDownMenu_JustifyText(dropdown, "LEFT")
    UIDropDownMenu_Initialize(dropdown, function(_, level)
        level = level or 1
        if level ~= 1 then return end
        for _, option in ipairs(Marker_GetOptions()) do
            local shapeKey = option.key
            local info = UIDropDownMenu_CreateInfo()
            info.text = Marker_GetDisplayName(shapeKey)
            info.value = shapeKey
            info.checked = (dropdown.shapeKey == shapeKey)
            info.func = function()
                SetMarkerDropDownValue(dropdown, shapeKey)
                CloseDropDownMenus()
                if not OptionsFrame.updating then
                    OptionsFrame.modified = true
                    OptionsFrame_ApplyPreview()
                end
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    dropdown:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L("TT_MARKER_TITLE"), 1, 0.82, 0.18)
        GameTooltip:AddLine(L("TT_MARKER_TYPE"), 1, 1, 1, true)
        GameTooltip:Show()
    end)
    dropdown:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return dropdown
end

local function SetHaloShapeDropDownValue(dropdown, key)
    key = Halo_NormalizeShape(key)
    dropdown.shapeKey = key
    UIDropDownMenu_SetText(dropdown, Halo_GetShapeDisplayName(key))
end

local function CreateHaloShapeDropDown(parent)
    local dropdown = CreateFrame("Frame", "CursorTrailHaloShapeDropDown", parent, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(dropdown, 105)
    UIDropDownMenu_SetButtonWidth(dropdown, 125)
    UIDropDownMenu_JustifyText(dropdown, "LEFT")
    UIDropDownMenu_Initialize(dropdown, function(_, level)
        level = level or 1
        if level ~= 1 then return end
        for _, option in ipairs(Halo_GetShapeOptions()) do
            local shapeKey = option.key
            local info = UIDropDownMenu_CreateInfo()
            info.text = Halo_GetShapeDisplayName(shapeKey)
            info.value = shapeKey
            info.checked = (dropdown.shapeKey == shapeKey)
            info.func = function()
                SetHaloShapeDropDownValue(dropdown, shapeKey)
                CloseDropDownMenus()
                if not OptionsFrame.updating then
                    OptionsFrame.modified = true
                    OptionsFrame_ApplyPreview()
                end
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    dropdown:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L("TT_HALO_SHAPE_TITLE"), 1, 0.82, 0.18)
        GameTooltip:AddLine(L("TT_HALO_SHAPE"), 1, 1, 1, true)
        GameTooltip:Show()
    end)
    dropdown:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return dropdown
end

local function SetHaloStyleDropDownValue(dropdown, key)
    key = Halo_NormalizeStyle(key)
    dropdown.styleKey = key
    UIDropDownMenu_SetText(dropdown, Halo_GetStyleDisplayName(key))
end

local function CreateHaloStyleDropDown(parent)
    local dropdown = CreateFrame("Frame", "CursorTrailHaloStyleDropDown", parent, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(dropdown, 110)
    UIDropDownMenu_SetButtonWidth(dropdown, 130)
    UIDropDownMenu_JustifyText(dropdown, "LEFT")
    UIDropDownMenu_Initialize(dropdown, function(_, level)
        level = level or 1
        if level ~= 1 then return end
        for _, option in ipairs(Halo_GetStyleOptions()) do
            local styleKey = option.key
            local info = UIDropDownMenu_CreateInfo()
            info.text = Halo_GetStyleDisplayName(styleKey)
            info.value = styleKey
            info.checked = (dropdown.styleKey == styleKey)
            info.func = function()
                SetHaloStyleDropDownValue(dropdown, styleKey)
                CloseDropDownMenus()
                if OptionsFrame_UpdateHaloColorAvailability then
                    OptionsFrame_UpdateHaloColorAvailability()
                end
                if not OptionsFrame.updating then
                    OptionsFrame.modified = true
                    OptionsFrame_ApplyPreview()
                end
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    dropdown:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L("TT_HALO_STYLE_TITLE"), 1, 0.82, 0.18)
        GameTooltip:AddLine(L("TT_HALO_STYLE"), 1, 1, 1, true)
        GameTooltip:Show()
    end)
    dropdown:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return dropdown
end

local function SetTrailDropDownValue(dropdown, key)
    key = Trail_NormalizeKey(key)
    dropdown.trailKey = key
    UIDropDownMenu_SetText(dropdown, Trail_GetDisplayName(key))
end

local function CreateTrailDropDown(parent)
    local dropdown = CreateFrame("Frame", "CursorTrailTrailDropDown", parent, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(dropdown, 230)
    UIDropDownMenu_SetButtonWidth(dropdown, 250)
    UIDropDownMenu_JustifyText(dropdown, "LEFT")
    UIDropDownMenu_Initialize(dropdown, function(_, level)
        level = level or 1
        if level ~= 1 then return end
        for _, option in ipairs(Trail_GetOptions()) do
            local trailKey = option.key
            local info = UIDropDownMenu_CreateInfo()
            info.text = Trail_GetDisplayName(trailKey)
            info.value = trailKey
            info.checked = (dropdown.trailKey == trailKey)
            info.func = function()
                SetTrailDropDownValue(dropdown, trailKey)
                CloseDropDownMenus()
                if not OptionsFrame.updating then
                    OptionsFrame.modified = true
                    OptionsFrame_ApplyPreview()
                end
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    dropdown:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L("TT_MODEL_TYPE_TITLE"), 1, 0.82, 0.18)
        GameTooltip:AddLine(L("TT_MODEL_TYPE"), 1, 1, 1, true)
        GameTooltip:Show()
    end)
    dropdown:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return dropdown
end

-- ---------------------------------------------------------------------------
-- Shared profile UI.  These dialogs use the legacy StaticPopup API available
-- in Legion and deliberately alter only the shared profiles database.
-- ---------------------------------------------------------------------------
local function SetProfileDropDownValue(dropdown, name)
    dropdown.profileName = name
    UIDropDownMenu_SetText(dropdown, name or L("PROFILE_NONE"))
end

local function CreateProfileDropDown(parent)
    local dropdown = CreateFrame("Frame", "CursorTrailProfileDropDown", parent, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(dropdown, 155)
    UIDropDownMenu_SetButtonWidth(dropdown, 175)
    UIDropDownMenu_JustifyText(dropdown, "LEFT")
    UIDropDownMenu_Initialize(dropdown, function(_, level)
        level = level or 1
        if level ~= 1 then return end

        local names = Profile_GetNames()
        if #names == 0 then
            local emptyInfo = UIDropDownMenu_CreateInfo()
            emptyInfo.text = L("PROFILE_EMPTY")
            emptyInfo.disabled = true
            UIDropDownMenu_AddButton(emptyInfo, level)
            return
        end

        for _, name in ipairs(names) do
            local profileName = name
            local info = UIDropDownMenu_CreateInfo()
            info.text = profileName
            info.value = profileName
            info.checked = (dropdown.profileName == profileName)
            info.func = function()
                CloseDropDownMenus()
                OptionsFrame_SelectProfile(profileName)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    SetProfileDropDownValue(dropdown, nil)
    dropdown:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L("TT_PROFILE_TITLE"), 1, 0.82, 0.18)
        GameTooltip:AddLine(L("TT_PROFILE"), 1, 1, 1, true)
        GameTooltip:Show()
    end)
    dropdown:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return dropdown
end

local function ShowProfileMessage(message)
    StaticPopup_Show("CURSORTRAIL_PROFILE_MESSAGE", message)
end

function OptionsFrame_SetProfileSelection(name)
    SetProfileDropDownValue(OptionsFrame.ProfileDropDown, name)
end

function OptionsFrame_SaveProfileAs(name)
    local ok, normalizedName = Profile_Save(name, OptionsFrame_ReadConfigFromUI())
    if not ok then
        ShowProfileMessage(L("PROFILE_NAME_EMPTY"))
        return
    end
    OptionsFrame_SetProfileSelection(normalizedName)
end

function OptionsFrame_OnNewProfileName(name)
    name = Profile_NormalizeName(name)
    if not name then
        ShowProfileMessage(L("PROFILE_ENTER_NAME"))
    elseif Profile_Get(name) then
        StaticPopup_Show("CURSORTRAIL_OVERWRITE_PROFILE", name, nil, name)
    else
        OptionsFrame_SaveProfileAs(name)
    end
end

function OptionsFrame_SelectProfile(name)
    local profile = Profile_Get(name)
    if not profile then return end

    local config = CopyTable(PlayerConfig)
    if not Profile_ApplyToConfig(profile, config) then return end
    OptionsFrame_WriteConfigToUI(config)
    OptionsFrame_SetProfileSelection(name)
    OptionsFrame.modified = true
    OptionsFrame_ApplyPreview()
end

function OptionsFrame_OnSaveProfile()
    local name = OptionsFrame.ProfileDropDown.profileName
    if not name then
        ShowProfileMessage(L("PROFILE_SELECT_OR_CREATE"))
        return
    end
    OptionsFrame_SaveProfileAs(name)
end

function OptionsFrame_OnDeleteProfile()
    local name = OptionsFrame.ProfileDropDown.profileName
    if not name then
        ShowProfileMessage(L("PROFILE_SELECT_DELETE"))
        return
    end
    StaticPopup_Show("CURSORTRAIL_DELETE_PROFILE", name, nil, name)
end

local function ConfigureLocalizedProfilePopups()
    StaticPopupDialogs["CURSORTRAIL_PROFILE_MESSAGE"] = {
        text = "%s",
        button1 = L("OK"),
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1,
        preferredIndex = 3
    }

    StaticPopupDialogs["CURSORTRAIL_NEW_PROFILE"] = {
        text = L("NEW_PROFILE_PROMPT"),
        button1 = L("CREATE"),
        button2 = L("CANCEL"),
        hasEditBox = 1,
        maxLetters = 40,
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1,
        preferredIndex = 3,
        OnShow = function(self)
            self.editBox:SetText("")
            self.editBox:SetFocus()
        end,
        OnAccept = function(self)
            OptionsFrame_OnNewProfileName(self.editBox:GetText())
        end,
        EditBoxOnEnterPressed = function(self)
            self:GetParent().button1:Click()
        end
    }

    StaticPopupDialogs["CURSORTRAIL_OVERWRITE_PROFILE"] = {
        text = L("OVERWRITE_PROFILE"),
        button1 = L("OVERWRITE"),
        button2 = L("CANCEL"),
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1,
        preferredIndex = 3,
        OnAccept = function(_, name)
            OptionsFrame_SaveProfileAs(name)
        end
    }

    StaticPopupDialogs["CURSORTRAIL_DELETE_PROFILE"] = {
        text = L("DELETE_PROFILE_PROMPT"),
        button1 = L("DELETE"),
        button2 = L("CANCEL"),
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1,
        preferredIndex = 3,
        OnAccept = function(_, name)
            if Profile_Delete(name) then
                OptionsFrame_SetProfileSelection(nil)
            end
        end
    }

end

-- ---------------------------------------------------------------------------
-- Event setup.
-- ---------------------------------------------------------------------------
local EventFrame = CreateFrame("Frame")
EventFrame:SetScript("OnEvent", function(self, event, ...)
    self[event](self, ...)
end)

EventFrame:RegisterEvent("ADDON_LOADED")
function EventFrame:ADDON_LOADED(addonName)
    if (addonName ~= kTheTitle) then return end
    self:UnregisterEvent("ADDON_LOADED")
    if Locale_RefreshFromSaved then Locale_RefreshFromSaved() end
    ConfigureLocalizedProfilePopups()
    StandardPanel_Create()
    OptionsFrame_Create()
end

-- ---------------------------------------------------------------------------
-- Standard Interface Options entry.
-- ---------------------------------------------------------------------------
function StandardPanel_Create()
    if StandardPanel then return end

    StandardPanel = CreateFrame("Frame", kTheTitle.."StandardPanel", UIParent)
    StandardPanel.name = kDisplayTitle

    local heading = CreateText(StandardPanel, kDisplayTitle.."  "..kTheVersion, "GameFontNormalLarge", "TOPLEFT", StandardPanel, "TOPLEFT", 16, -16)
    local desc = CreateText(StandardPanel,
        L("STANDARD_DESC"),
        "GameFontHighlightSmall", "TOPLEFT", heading, "BOTTOMLEFT", 0, -10)
    desc:SetWidth(540)
    desc:SetJustifyH("LEFT")

    local open = CreateButton(StandardPanel, L("OPEN_SETTINGS"), 210, 26)
    open:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -18)
    open:SetScript("OnClick", function()
        if OptionsFrame:IsShown() then OptionsFrame:Hide() else OptionsFrame:Show() end
    end)

    InterfaceOptions_AddCategory(StandardPanel)
end

-- ---------------------------------------------------------------------------
-- Options window.
-- ---------------------------------------------------------------------------
function OptionsFrame_Create()
    if OptionsFrame then return end

    local frameName = kTheTitle.."OptionsFrame"
    OptionsFrame = CreateFrame("Frame", frameName, UIParent)
    Globals.tinsert(Globals.UISpecialFrames, frameName)

    OptionsFrame:SetSize(WINDOW_W, WINDOW_H)
    OptionsFrame:SetPoint("CENTER")
    OptionsFrame:SetFrameStrata("DIALOG")
    OptionsFrame:SetToplevel(true)
    OptionsFrame:SetClampedToScreen(true)
    OptionsFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 24,
        insets = { left = 7, right = 8, top = 8, bottom = 7 }
    })
    OptionsFrame:SetBackdropColor(0, 0, 0, 0.98)
    OptionsFrame:Hide()

    OptionsFrame:EnableMouse(true)
    OptionsFrame:SetMovable(true)
    OptionsFrame:RegisterForDrag("LeftButton")
    OptionsFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    OptionsFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- A long left-button hold temporarily hides the effect in the core's
        -- mouse-look guard.  Restore the active options preview immediately.
        CursorModel_Show(true)
    end)
    OptionsFrame:SetScript("OnShow", OptionsFrame_OnShow)
    OptionsFrame:SetScript("OnHide", OptionsFrame_OnHide)

    -- Header: version stays under the main title; authorship is moved to the
    -- former top-right version area to save vertical space.
    local title = CreateText(OptionsFrame, kDisplayTitle, "GameFontNormalLarge", "TOPLEFT", OptionsFrame, "TOPLEFT", 22, -15)
    title:SetTextColor(1.0, 0.82, 0.18)
    local version = CreateText(OptionsFrame, "v"..kTheVersion, "GameFontHighlightSmall", "TOPLEFT", title, "BOTTOMLEFT", 0, -1)
    version:SetTextColor(0.72, 0.74, 0.80)
    local author = CreateText(OptionsFrame, L("AUTHOR_ORIGINAL"), "GameFontHighlightSmall", "TOPRIGHT", OptionsFrame, "TOPRIGHT", -40, -17)
    author:SetTextColor(0.72, 0.74, 0.80)
    author:SetJustifyH("RIGHT")
    local adaptation = CreateText(OptionsFrame, L("ADAPTATION_EXTENDED"), "GameFontHighlightSmall", "TOPRIGHT", author, "BOTTOMRIGHT", 0, -2)
    adaptation:SetTextColor(0.72, 0.74, 0.80)
    adaptation:SetJustifyH("RIGHT")

    local close = CreateFrame("Button", nil, OptionsFrame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", OptionsFrame, "TOPRIGHT", -5, -5)

    -- Cursor effects section: independent animated 3D and flat 2D effects.
    local effect = CreateSection(OptionsFrame, L("CURSOR_EFFECTS"), -60, 310)
    OptionsFrame.EffectSection = effect

    -- 3D effects subgroup.  The checkbox is intentionally a short on/off
    -- control next to the subgroup heading instead of a separate "show" row.
    local modelHeading = CreateText(effect, L("EFFECTS_3D"), "GameFontNormal", "TOPLEFT", effect, "TOPLEFT", 14, -32)
    OptionsFrame.ModelCheckbox = CreateCheckBox(effect, L("ON_OFF"),
        L("TT_MODEL_TOGGLE"))
    OptionsFrame.ModelCheckbox:SetPoint("TOPLEFT", effect, "TOPLEFT", 96, -25)

    local trailLabel = CreateText(effect, L("TYPE"), "GameFontHighlight", "TOPLEFT", effect, "TOPLEFT", 14, -70)
    OptionsFrame.TrailDropDown = CreateTrailDropDown(effect)
    OptionsFrame.TrailDropDown:SetPoint("TOPLEFT", effect, "TOPLEFT", 58, -60)

    OptionsFrame.ScaleControl = CreateInlineSlider(effect, L("SIZE"), 4, 300, 1,
        function(v) return string.format("%d%%", v) end,
        L("TT_MODEL_SIZE"))
    OptionsFrame.ScaleControl:SetPoint("TOPLEFT", effect, "TOPLEFT", 14, -98)
    TuneInlineSlider(OptionsFrame.ScaleControl, 54, 72)

    OptionsFrame.OfsXControl = CreateInlineSlider(effect, L("OFFSET_X"), -20, 20, 1,
        function(v) return string.format("%d", v) end,
        L("TT_MODEL_X"))
    OptionsFrame.OfsXControl:SetPoint("TOPLEFT", effect, "TOPLEFT", 250, -98)
    TuneInlineSlider(OptionsFrame.OfsXControl, 60, 64)

    OptionsFrame.OfsYControl = CreateInlineSlider(effect, L("OFFSET_Y"), -20, 20, 1,
        function(v) return string.format("%d", v) end,
        L("TT_MODEL_Y"))
    OptionsFrame.OfsYControl:SetPoint("TOPLEFT", effect, "TOPLEFT", 250, -130)
    TuneInlineSlider(OptionsFrame.OfsYControl, 60, 64)

    OptionsFrame.AlphaControl = CreateInlineSlider(effect, L("OPACITY"), 0, 100, 1,
        function(v) return string.format("%d%%", v) end,
        L("TT_MODEL_ALPHA"))
    OptionsFrame.AlphaControl:SetPoint("TOPLEFT", effect, "TOPLEFT", 14, -130)
    TuneInlineSlider(OptionsFrame.AlphaControl, 70, 72)

    -- 2D effects subgroup.  Internal Marker* names are retained for backwards
    -- compatibility with 0.0.5.12/0.0.5.13 SavedVariables and profiles.
    local markerHeading = CreateText(effect, L("EFFECTS_2D"), "GameFontNormal", "TOPLEFT", effect, "TOPLEFT", 14, -169)
    OptionsFrame.MarkerCheckbox = CreateCheckBox(effect, L("ON_OFF"),
        L("TT_MARKER_TOGGLE"))
    OptionsFrame.MarkerCheckbox:SetPoint("TOPLEFT", effect, "TOPLEFT", 96, -162)

    local markerLabel = CreateText(effect, L("TYPE"), "GameFontHighlight", "TOPLEFT", effect, "TOPLEFT", 14, -205)
    OptionsFrame.MarkerDropDown = CreateMarkerDropDown(effect)
    OptionsFrame.MarkerDropDown:SetPoint("TOPLEFT", effect, "TOPLEFT", 58, -195)

    local markerColorLabel = CreateText(effect, L("COLOR"), "GameFontHighlight", "TOPLEFT", effect, "TOPLEFT", 285, -210)
    OptionsFrame.MarkerColorSwatch = CreateColorSwatch(effect, L("TT_MARKER_COLOR"))
    OptionsFrame.MarkerColorSwatch:SetPoint("TOPLEFT", effect, "TOPLEFT", 330, -199)
    OptionsFrame.MarkerColorSwatch:SetScript("OnClick", function(self)
        local previous = { self.r, self.g, self.b, r = self.r, g = self.g, b = self.b }
        local function ApplyColor(r, g, b)
            SetColorSwatch(self, r, g, b)
            if not OptionsFrame.updating then
                OptionsFrame.modified = true
                OptionsFrame_ApplyPreview()
            end
        end
        ColorPickerFrame.hasOpacity = false
        ColorPickerFrame.previousValues = previous
        ColorPickerFrame.func = function()
            local r, g, b = ColorPickerFrame:GetColorRGB()
            ApplyColor(r, g, b)
        end
        ColorPickerFrame.cancelFunc = function(values)
            values = values or previous
            ApplyColor(values.r or values[1], values.g or values[2], values.b or values[3])
        end
        ColorPickerFrame:SetColorRGB(self.r, self.g, self.b)
        ColorPickerFrame:Show()
    end)

    OptionsFrame.MarkerScaleControl = CreateInlineSlider(effect, L("SIZE"), 25, 300, 1,
        function(v) return string.format("%d%%", v) end,
        L("TT_MARKER_SIZE"))
    OptionsFrame.MarkerScaleControl:SetPoint("TOPLEFT", effect, "TOPLEFT", 14, -230)
    TuneInlineSlider(OptionsFrame.MarkerScaleControl, 54, 72)

    OptionsFrame.MarkerOfsXControl = CreateInlineSlider(effect, L("OFFSET_X"), -20, 20, 1,
        function(v) return string.format("%d", v) end,
        L("TT_MARKER_X"))
    OptionsFrame.MarkerOfsXControl:SetPoint("TOPLEFT", effect, "TOPLEFT", 250, -230)
    TuneInlineSlider(OptionsFrame.MarkerOfsXControl, 60, 64)

    OptionsFrame.MarkerOfsYControl = CreateInlineSlider(effect, L("OFFSET_Y"), -20, 20, 1,
        function(v) return string.format("%d", v) end,
        L("TT_MARKER_Y"))
    OptionsFrame.MarkerOfsYControl:SetPoint("TOPLEFT", effect, "TOPLEFT", 250, -262)
    TuneInlineSlider(OptionsFrame.MarkerOfsYControl, 60, 64)

    OptionsFrame.MarkerAlphaControl = CreateInlineSlider(effect, L("OPACITY"), 0, 100, 1,
        function(v) return string.format("%d%%", v) end,
        L("TT_MARKER_ALPHA"))
    OptionsFrame.MarkerAlphaControl:SetPoint("TOPLEFT", effect, "TOPLEFT", 14, -262)
    TuneInlineSlider(OptionsFrame.MarkerAlphaControl, 70, 72)

    -- Cursor halo section: 0.0.6.0 semantic form/style/thickness system.
    -- 0.0.6.6: the section is taller so rotation speed has its own row.
    local halo = CreateSection(OptionsFrame, L("CURSOR_HALO"), -380, 210)
    OptionsFrame.HaloSection = halo

    OptionsFrame.HaloCheckbox = CreateCheckBox(halo, L("ON_OFF"),
        L("TT_HALO_TOGGLE"))
    OptionsFrame.HaloCheckbox:SetPoint("TOPLEFT", halo, "TOPLEFT", 160, -5)

    local haloShapeLabel = CreateText(halo, L("SHAPE"), "GameFontHighlight", "TOPLEFT", halo, "TOPLEFT", 14, -46)
    OptionsFrame.HaloShapeDropDown = CreateHaloShapeDropDown(halo)
    OptionsFrame.HaloShapeDropDown:SetPoint("TOPLEFT", halo, "TOPLEFT", 72, -36)

    local haloStyleLabel = CreateText(halo, L("STYLE"), "GameFontHighlight", "TOPLEFT", halo, "TOPLEFT", 250, -46)
    OptionsFrame.HaloStyleDropDown = CreateHaloStyleDropDown(halo)
    OptionsFrame.HaloStyleDropDown:SetPoint("TOPLEFT", halo, "TOPLEFT", 300, -36)

    OptionsFrame.HaloThicknessControl = CreateInlineSlider(halo, L("THICKNESS"), 1, 5, 1,
        function(v) return string.format("%d", v) end,
        L("TT_HALO_THICKNESS"))
    OptionsFrame.HaloThicknessControl:SetPoint("TOPLEFT", halo, "TOPLEFT", 14, -68)
    TuneInlineSlider(OptionsFrame.HaloThicknessControl, 64, 72)

    OptionsFrame.HaloColorLabel = CreateText(halo, L("COLOR"), "GameFontHighlight", "TOPLEFT", halo, "TOPLEFT", 250, -80)
    OptionsFrame.HaloColorSwatch = CreateColorSwatch(halo, L("TT_HALO_COLOR"))
    OptionsFrame.HaloColorSwatch:SetPoint("TOPLEFT", halo, "TOPLEFT", 295, -72)
    OptionsFrame.HaloColorSwatch:SetScript("OnClick", function(self)
        if self.colorEnabled == false then return end
        local previous = { self.r, self.g, self.b, r = self.r, g = self.g, b = self.b }
        local function ApplyColor(r, g, b)
            SetColorSwatch(self, r, g, b)
            if not OptionsFrame.updating then
                OptionsFrame.modified = true
                OptionsFrame_ApplyPreview()
            end
        end
        ColorPickerFrame.hasOpacity = false
        ColorPickerFrame.previousValues = previous
        ColorPickerFrame.func = function()
            local r, g, b = ColorPickerFrame:GetColorRGB()
            ApplyColor(r, g, b)
        end
        ColorPickerFrame.cancelFunc = function(values)
            values = values or previous
            ApplyColor(values.r or values[1], values.g or values[2], values.b or values[3])
        end
        ColorPickerFrame:SetColorRGB(self.r, self.g, self.b)
        ColorPickerFrame:Show()
    end)

    function OptionsFrame_UpdateHaloColorAvailability()
        if not OptionsFrame or not OptionsFrame.HaloColorSwatch then return end
        local enabled = (not OptionsFrame.HaloStyleDropDown
            or OptionsFrame.HaloStyleDropDown.styleKey ~= "spectral")
        OptionsFrame.HaloColorSwatch.colorEnabled = enabled
        OptionsFrame.HaloColorSwatch:SetAlpha(enabled and 1.0 or 0.35)
        if OptionsFrame.HaloColorLabel then
            OptionsFrame.HaloColorLabel:SetAlpha(enabled and 1.0 or 0.45)
        end
    end

    OptionsFrame.HaloScaleControl = CreateInlineSlider(halo, L("SIZE"), 25, 300, 1,
        function(v) return string.format("%d%%", v) end,
        L("TT_HALO_SIZE"))
    OptionsFrame.HaloScaleControl:SetPoint("TOPLEFT", halo, "TOPLEFT", 14, -100)
    TuneInlineSlider(OptionsFrame.HaloScaleControl, 54, 72)

    OptionsFrame.HaloAlphaControl = CreateInlineSlider(halo, L("OPACITY"), 0, 100, 1,
        function(v) return string.format("%d%%", v) end,
        L("TT_HALO_ALPHA"))
    OptionsFrame.HaloAlphaControl:SetPoint("TOPLEFT", halo, "TOPLEFT", 250, -100)
    TuneInlineSlider(OptionsFrame.HaloAlphaControl, 70, 72)

    -- 0.0.6.5: rotation is exposed as an intuitive 1..5 speed scale.
    -- Internally the validated 12/10/8/6/4-second revolution periods are kept
    -- so existing SavedVariables and profiles remain fully compatible.
    OptionsFrame.HaloRotationCheckbox = CreateCheckBox(halo, L("ROTATION"),
        L("TT_HALO_ROTATION"))
    OptionsFrame.HaloRotationCheckbox:SetPoint("TOPLEFT", halo, "TOPLEFT", 14, -132)

    OptionsFrame.HaloRotationInvertCheckbox = CreateCheckBox(halo, L("REVERSE_ROTATION"),
        L("TT_HALO_REVERSE"))
    OptionsFrame.HaloRotationInvertCheckbox:SetPoint("TOPLEFT", halo, "TOPLEFT", 126, -132)

    OptionsFrame.HaloRotationControl = CreateInlineSlider(halo, L("ROTATION_SPEED"), 1, 5, 1,
        function(v) return string.format("%d", v) end,
        L("TT_HALO_SPEED"))
    OptionsFrame.HaloRotationControl:SetPoint("TOPLEFT", halo, "TOPLEFT", 14, -164)
    TuneInlineSlider(OptionsFrame.HaloRotationControl, 128, 136)

    function OptionsFrame_UpdateHaloRotationAvailability()
        if not OptionsFrame or not OptionsFrame.HaloRotationControl then return end
        local enabled = (OptionsFrame.HaloRotationCheckbox
            and OptionsFrame.HaloRotationCheckbox:GetChecked()) and true or false
        local control = OptionsFrame.HaloRotationControl
        control:SetAlpha(enabled and 1.0 or 0.45)
        control.slider:EnableMouse(enabled)
        control.slider:EnableMouseWheel(enabled)
        if control.editBox then
            if enabled then control.editBox:Enable() else control.editBox:Disable() end
        end
        if OptionsFrame.HaloRotationInvertCheckbox then
            OptionsFrame.HaloRotationInvertCheckbox:SetAlpha(enabled and 1.0 or 0.45)
            OptionsFrame.HaloRotationInvertCheckbox:EnableMouse(enabled)
            if OptionsFrame.HaloRotationInvertCheckbox.label then
                OptionsFrame.HaloRotationInvertCheckbox.label:SetAlpha(enabled and 1.0 or 0.45)
            end
        end
    end

    -- 0.0.6.6: visibility lives with the cursor-effect controls; the bottom
    -- section is now dedicated to shared profiles only.
    local displayHeading = CreateText(effect, L("DISPLAY"), "GameFontNormal", "TOPLEFT", effect, "TOPLEFT", 250, -8)
    OptionsFrame.CombatCheckbox = CreateCheckBox(effect, L("SHOW_ONLY_COMBAT"),
        L("TT_COMBAT"))
    OptionsFrame.CombatCheckbox:SetPoint("TOPLEFT", effect, "TOPLEFT", 250, -25)

    local general = CreateSection(OptionsFrame, L("PROFILES"), -596, 90)
    OptionsFrame.GeneralSection = general

    local profileLabel = CreateText(general, L("PROFILE"), "GameFontHighlight", "TOPLEFT", general, "TOPLEFT", 14, -42)
    OptionsFrame.ProfileDropDown = CreateProfileDropDown(general)
    OptionsFrame.ProfileDropDown:SetPoint("TOPLEFT", general, "TOPLEFT", 82, -32)

    OptionsFrame.NewProfileBtn = CreateButton(general, L("NEW_PROFILE"), 112, 22)
    OptionsFrame.NewProfileBtn:SetPoint("TOPLEFT", general, "TOPLEFT", 280, -34)
    OptionsFrame.NewProfileBtn:SetScript("OnClick", function()
        StaticPopup_Show("CURSORTRAIL_NEW_PROFILE")
    end)

    OptionsFrame.SaveProfileBtn = CreateButton(general, L("SAVE_PROFILE"), 142, 22)
    OptionsFrame.SaveProfileBtn:SetPoint("TOPLEFT", general, "TOPLEFT", 14, -64)
    OptionsFrame.SaveProfileBtn:SetScript("OnClick", OptionsFrame_OnSaveProfile)

    OptionsFrame.DeleteProfileBtn = CreateButton(general, L("DELETE_PROFILE"), 130, 22)
    OptionsFrame.DeleteProfileBtn:SetPoint("LEFT", OptionsFrame.SaveProfileBtn, "RIGHT", 8, 0)
    OptionsFrame.DeleteProfileBtn:SetScript("OnClick", OptionsFrame_OnDeleteProfile)

    -- Footer buttons.
    OptionsFrame.CancelBtn = CreateButton(OptionsFrame, L("CANCEL"), 96, 26)
    OptionsFrame.CancelBtn:SetPoint("BOTTOMRIGHT", OptionsFrame, "BOTTOMRIGHT", -18, 14)
    OptionsFrame.CancelBtn:SetScript("OnClick", OptionsFrame_OnCancel)

    OptionsFrame.SaveBtn = CreateButton(OptionsFrame, L("APPLY"), 96, 26)
    OptionsFrame.SaveBtn:SetPoint("RIGHT", OptionsFrame.CancelBtn, "LEFT", -8, 0)
    OptionsFrame.SaveBtn:SetScript("OnClick", OptionsFrame_OnOK)

    local tip = CreateText(OptionsFrame, L("FOOTER_ACTIONS"),
        "GameFontDisableSmall", "BOTTOMRIGHT", OptionsFrame, "BOTTOMRIGHT", -18, 48)
    tip:SetWidth(360)
    tip:SetJustifyH("RIGHT")

    -- Change handlers.
    local function SliderChanged(holder, value)
        -- Legion sliders can report fractional values while dragging even when
        -- SetValueStep(1) is configured.  Snap the real slider value first so
        -- the model and the numeric EditBox always use the exact same integer.
        local normalized = holder:NormalizeValue(value)
        if math.abs((value or 0) - normalized) > 0.000001 then
            holder.slider:SetValue(normalized)
            return
        end
        holder:RefreshValue(normalized)
        if OptionsFrame.updating then return end
        OptionsFrame.modified = true
        OptionsFrame_ApplyPreview()
    end

    OptionsFrame.ScaleControl.slider:SetScript("OnValueChanged", function(_, value) SliderChanged(OptionsFrame.ScaleControl, value) end)
    OptionsFrame.OfsXControl.slider:SetScript("OnValueChanged", function(_, value) SliderChanged(OptionsFrame.OfsXControl, value) end)
    OptionsFrame.OfsYControl.slider:SetScript("OnValueChanged", function(_, value) SliderChanged(OptionsFrame.OfsYControl, value) end)
    OptionsFrame.AlphaControl.slider:SetScript("OnValueChanged", function(_, value) SliderChanged(OptionsFrame.AlphaControl, value) end)
    OptionsFrame.MarkerScaleControl.slider:SetScript("OnValueChanged", function(_, value) SliderChanged(OptionsFrame.MarkerScaleControl, value) end)
    OptionsFrame.MarkerOfsXControl.slider:SetScript("OnValueChanged", function(_, value) SliderChanged(OptionsFrame.MarkerOfsXControl, value) end)
    OptionsFrame.MarkerOfsYControl.slider:SetScript("OnValueChanged", function(_, value) SliderChanged(OptionsFrame.MarkerOfsYControl, value) end)
    OptionsFrame.MarkerAlphaControl.slider:SetScript("OnValueChanged", function(_, value) SliderChanged(OptionsFrame.MarkerAlphaControl, value) end)
    OptionsFrame.HaloThicknessControl.slider:SetScript("OnValueChanged", function(_, value) SliderChanged(OptionsFrame.HaloThicknessControl, value) end)
    OptionsFrame.HaloScaleControl.slider:SetScript("OnValueChanged", function(_, value) SliderChanged(OptionsFrame.HaloScaleControl, value) end)
    OptionsFrame.HaloAlphaControl.slider:SetScript("OnValueChanged", function(_, value) SliderChanged(OptionsFrame.HaloAlphaControl, value) end)
    OptionsFrame.HaloRotationControl.slider:SetScript("OnValueChanged", function(_, value) SliderChanged(OptionsFrame.HaloRotationControl, value) end)

    OptionsFrame.ModelCheckbox:SetScript("OnClick", function()
        if OptionsFrame.updating then return end
        OptionsFrame.modified = true
        OptionsFrame_ApplyPreview()
    end)

    OptionsFrame.MarkerCheckbox:SetScript("OnClick", function()
        if OptionsFrame.updating then return end
        OptionsFrame.modified = true
        OptionsFrame_ApplyPreview()
    end)

    OptionsFrame.HaloCheckbox:SetScript("OnClick", function()
        if OptionsFrame.updating then return end
        OptionsFrame.modified = true
        OptionsFrame_ApplyPreview()
    end)

    OptionsFrame.HaloRotationCheckbox:SetScript("OnClick", function()
        OptionsFrame_UpdateHaloRotationAvailability()
        if OptionsFrame.updating then return end
        OptionsFrame.modified = true
        OptionsFrame_ApplyPreview()
    end)

    OptionsFrame.HaloRotationInvertCheckbox:SetScript("OnClick", function()
        if OptionsFrame.updating then return end
        OptionsFrame.modified = true
        OptionsFrame_ApplyPreview()
    end)

    OptionsFrame.CombatCheckbox:SetScript("OnClick", function()
        if OptionsFrame.updating then return end
        OptionsFrame.modified = true
    end)
end

-- ---------------------------------------------------------------------------
-- Value conversion and live preview.
-- ---------------------------------------------------------------------------
local function HaloRotationSpeedToSeconds(value)
    value = RoundToNearest(tonumber(value) or 3)
    if value < 1 then value = 1 end
    if value > 5 then value = 5 end
    -- 1/2/3/4/5 -> 12/10/8/6/4 seconds per revolution.
    return 14 - (value * 2)
end

local function HaloRotationSecondsToSpeed(value)
    value = Halo_NormalizeRotationSeconds(value or 8)
    local speed = RoundToNearest((14 - value) / 2)
    if speed < 1 then speed = 1 end
    if speed > 5 then speed = 5 end
    return speed
end

function OptionsFrame_ReadConfigFromUI()
    return {
        TrailKey = Trail_NormalizeKey(OptionsFrame.TrailDropDown.trailKey),
        UserScale = (OptionsFrame.ScaleControl.slider:GetValue() or 100) / 100,
        UserOfsX = RoundToNearest(OptionsFrame.OfsXControl.slider:GetValue() or 0),
        UserOfsY = RoundToNearest(OptionsFrame.OfsYControl.slider:GetValue() or 0),
        UserAlpha = (OptionsFrame.AlphaControl.slider:GetValue() or 100) / 100,
        UserShowOnlyInCombat = OptionsFrame.CombatCheckbox:GetChecked() and true or false,
        ModelEnabled = OptionsFrame.ModelCheckbox:GetChecked() and true or false,

        MarkerEnabled = OptionsFrame.MarkerCheckbox:GetChecked() and true or false,
        MarkerName = OptionsFrame.MarkerDropDown.shapeKey or "circle_1",
        MarkerColorR = OptionsFrame.MarkerColorSwatch.r or 1.0,
        MarkerColorG = OptionsFrame.MarkerColorSwatch.g or 1.0,
        MarkerColorB = OptionsFrame.MarkerColorSwatch.b or 1.0,
        MarkerScale = (OptionsFrame.MarkerScaleControl.slider:GetValue() or 100) / 100,
        MarkerOfsX = RoundToNearest(OptionsFrame.MarkerOfsXControl.slider:GetValue() or 0),
        MarkerOfsY = RoundToNearest(OptionsFrame.MarkerOfsYControl.slider:GetValue() or 0),
        MarkerAlpha = (OptionsFrame.MarkerAlphaControl.slider:GetValue() or 100) / 100,

        HaloEnabled = OptionsFrame.HaloCheckbox:GetChecked() and true or false,
        -- Preserve the old selector value only for downgrade compatibility.
        HaloName = (PlayerConfig and PlayerConfig.HaloName) or "ring_soft_1",
        HaloShape = Halo_NormalizeShape(OptionsFrame.HaloShapeDropDown.shapeKey),
        HaloStyle = Halo_NormalizeStyle(OptionsFrame.HaloStyleDropDown.styleKey),
        HaloThickness = Halo_NormalizeThickness(OptionsFrame.HaloThicknessControl.slider:GetValue() or 1),
        HaloColorR = OptionsFrame.HaloColorSwatch.r or 1.0,
        HaloColorG = OptionsFrame.HaloColorSwatch.g or 1.0,
        HaloColorB = OptionsFrame.HaloColorSwatch.b or 1.0,
        HaloScale = (OptionsFrame.HaloScaleControl.slider:GetValue() or 100) / 100,
        HaloAlpha = (OptionsFrame.HaloAlphaControl.slider:GetValue() or 100) / 100,
        HaloRotationEnabled = OptionsFrame.HaloRotationCheckbox:GetChecked() and true or false,
        HaloRotationInverted = OptionsFrame.HaloRotationInvertCheckbox:GetChecked() and true or false,
        HaloRotationSeconds = HaloRotationSpeedToSeconds(OptionsFrame.HaloRotationControl.slider:GetValue() or 3),
    }
end

function OptionsFrame_WriteConfigToUI(config)
    assert(config)
    OptionsFrame.updating = true

    local scale = tonumber(config.UserScale) or 1.0
    local ofsX = tonumber(config.UserOfsX) or 0
    local ofsY = tonumber(config.UserOfsY) or 0
    local alpha = tonumber(config.UserAlpha) or 1.0
    local markerScale = tonumber(config.MarkerScale) or 1.0
    local markerOfsX = tonumber(config.MarkerOfsX) or 0
    local markerOfsY = tonumber(config.MarkerOfsY) or 0
    local markerAlpha = tonumber(config.MarkerAlpha) or 1.0
    local haloThickness = Halo_NormalizeThickness(config.HaloThickness or 1)
    local haloScale = tonumber(config.HaloScale) or 1.0
    local haloAlpha = tonumber(config.HaloAlpha) or 1.0
    local haloRotationSpeed = HaloRotationSecondsToSpeed(config.HaloRotationSeconds or 8)

    OptionsFrame.ScaleControl.slider:SetValue(scale * 100)
    OptionsFrame.OfsXControl.slider:SetValue(RoundToNearest(ofsX))
    OptionsFrame.OfsYControl.slider:SetValue(RoundToNearest(ofsY))
    OptionsFrame.AlphaControl.slider:SetValue(alpha * 100)
    OptionsFrame.CombatCheckbox:SetChecked(config.UserShowOnlyInCombat and true or false)
    OptionsFrame.ModelCheckbox:SetChecked(config.ModelEnabled ~= false)
    SetTrailDropDownValue(OptionsFrame.TrailDropDown, config.TrailKey)

    OptionsFrame.MarkerCheckbox:SetChecked(config.MarkerEnabled and true or false)
    SetMarkerDropDownValue(OptionsFrame.MarkerDropDown, config.MarkerName or "circle_1")
    SetColorSwatch(OptionsFrame.MarkerColorSwatch,
        tonumber(config.MarkerColorR) or 1.0,
        tonumber(config.MarkerColorG) or 1.0,
        tonumber(config.MarkerColorB) or 1.0)
    OptionsFrame.MarkerScaleControl.slider:SetValue(markerScale * 100)
    OptionsFrame.MarkerOfsXControl.slider:SetValue(RoundToNearest(markerOfsX))
    OptionsFrame.MarkerOfsYControl.slider:SetValue(RoundToNearest(markerOfsY))
    OptionsFrame.MarkerAlphaControl.slider:SetValue(markerAlpha * 100)

    OptionsFrame.HaloCheckbox:SetChecked(config.HaloEnabled and true or false)
    SetHaloShapeDropDownValue(OptionsFrame.HaloShapeDropDown, config.HaloShape or "circle")
    SetHaloStyleDropDownValue(OptionsFrame.HaloStyleDropDown, config.HaloStyle or "solid")
    OptionsFrame.HaloThicknessControl.slider:SetValue(haloThickness)
    SetColorSwatch(OptionsFrame.HaloColorSwatch,
        tonumber(config.HaloColorR) or 1.0,
        tonumber(config.HaloColorG) or 1.0,
        tonumber(config.HaloColorB) or 1.0)
    OptionsFrame_UpdateHaloColorAvailability()
    OptionsFrame.HaloScaleControl.slider:SetValue(haloScale * 100)
    OptionsFrame.HaloAlphaControl.slider:SetValue(haloAlpha * 100)
    OptionsFrame.HaloRotationCheckbox:SetChecked(config.HaloRotationEnabled and true or false)
    OptionsFrame.HaloRotationInvertCheckbox:SetChecked(config.HaloRotationInverted and true or false)
    OptionsFrame.HaloRotationControl.slider:SetValue(haloRotationSpeed)
    OptionsFrame_UpdateHaloRotationAvailability()

    OptionsFrame.ScaleControl:RefreshValue(OptionsFrame.ScaleControl.slider:GetValue())
    OptionsFrame.OfsXControl:RefreshValue(OptionsFrame.OfsXControl.slider:GetValue())
    OptionsFrame.OfsYControl:RefreshValue(OptionsFrame.OfsYControl.slider:GetValue())
    OptionsFrame.AlphaControl:RefreshValue(OptionsFrame.AlphaControl.slider:GetValue())
    OptionsFrame.MarkerScaleControl:RefreshValue(OptionsFrame.MarkerScaleControl.slider:GetValue())
    OptionsFrame.MarkerOfsXControl:RefreshValue(OptionsFrame.MarkerOfsXControl.slider:GetValue())
    OptionsFrame.MarkerOfsYControl:RefreshValue(OptionsFrame.MarkerOfsYControl.slider:GetValue())
    OptionsFrame.MarkerAlphaControl:RefreshValue(OptionsFrame.MarkerAlphaControl.slider:GetValue())
    OptionsFrame.HaloThicknessControl:RefreshValue(OptionsFrame.HaloThicknessControl.slider:GetValue())
    OptionsFrame.HaloScaleControl:RefreshValue(OptionsFrame.HaloScaleControl.slider:GetValue())
    OptionsFrame.HaloAlphaControl:RefreshValue(OptionsFrame.HaloAlphaControl.slider:GetValue())
    OptionsFrame.HaloRotationControl:RefreshValue(OptionsFrame.HaloRotationControl.slider:GetValue())

    OptionsFrame.updating = false
end

function OptionsFrame_ApplyPreview()
    if (not CursorModel) then return end
    local cfg = OptionsFrame_ReadConfigFromUI()
    if (not CursorModel.TrailConfig or CursorModel.TrailConfig.key ~= cfg.TrailKey) then
        CursorModel_Load(cfg)
    else
        CursorModel_SetEnabled(cfg.ModelEnabled)
        CursorModel_ApplyUserSettings(cfg.UserScale, cfg.UserOfsX, cfg.UserOfsY, cfg.UserAlpha)
        Shape_ApplyConfig(cfg)
    end
    CursorModel_Show(true)
end

-- ---------------------------------------------------------------------------
-- Window actions.
-- ---------------------------------------------------------------------------
function OptionsFrame_OnShow()
    if SOUNDKIT and SOUNDKIT.IG_CHARACTER_INFO_OPEN then PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN) end
    OptionsFrame.OriginalConfig = CopyTable(PlayerConfig)
    CursorModel_SetPreviewMode(true)
    OptionsFrame_WriteConfigToUI(PlayerConfig)
    local profileName = PlayerConfig.LastProfileName
    if not Profile_Get(profileName) then profileName = nil end
    OptionsFrame_SetProfileSelection(profileName)
    OptionsFrame.modified = false
    CursorModel_Show(true)
end

function OptionsFrame_OnHide()
    if SOUNDKIT and SOUNDKIT.IG_CHARACTER_INFO_CLOSE then PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE) end

    if OptionsFrame.modified and OptionsFrame.OriginalConfig then
        -- ESC / close button: restore preview to the last applied config.
        CursorModel_Load(OptionsFrame.OriginalConfig)
        OptionsFrame.modified = false
    end

    CursorModel_SetPreviewMode(false)
    if PlayerConfig.UserShowOnlyInCombat == true and not UnitAffectingCombat("player") then
        CursorModel_Hide()
    end
end

function OptionsFrame_OnOK()
    local values = OptionsFrame_ReadConfigFromUI()

    PlayerConfig.TrailKey = values.TrailKey
    PlayerConfig.UserScale = values.UserScale
    PlayerConfig.UserOfsX = values.UserOfsX
    PlayerConfig.UserOfsY = values.UserOfsY
    PlayerConfig.UserAlpha = values.UserAlpha
    PlayerConfig.UserShowOnlyInCombat = values.UserShowOnlyInCombat
    PlayerConfig.ModelEnabled = values.ModelEnabled
    PlayerConfig.MarkerEnabled = values.MarkerEnabled
    PlayerConfig.MarkerName = values.MarkerName
    PlayerConfig.MarkerColorR = values.MarkerColorR
    PlayerConfig.MarkerColorG = values.MarkerColorG
    PlayerConfig.MarkerColorB = values.MarkerColorB
    PlayerConfig.MarkerScale = values.MarkerScale
    PlayerConfig.MarkerOfsX = values.MarkerOfsX
    PlayerConfig.MarkerOfsY = values.MarkerOfsY
    PlayerConfig.MarkerAlpha = values.MarkerAlpha
    PlayerConfig.HaloEnabled = values.HaloEnabled
    PlayerConfig.HaloName = values.HaloName
    PlayerConfig.HaloShape = values.HaloShape
    PlayerConfig.HaloStyle = values.HaloStyle
    PlayerConfig.HaloThickness = values.HaloThickness
    PlayerConfig.HaloColorR = values.HaloColorR
    PlayerConfig.HaloColorG = values.HaloColorG
    PlayerConfig.HaloColorB = values.HaloColorB
    PlayerConfig.HaloScale = values.HaloScale
    PlayerConfig.HaloAlpha = values.HaloAlpha
    PlayerConfig.HaloRotationEnabled = values.HaloRotationEnabled
    PlayerConfig.HaloRotationInverted = values.HaloRotationInverted
    PlayerConfig.HaloRotationSeconds = values.HaloRotationSeconds
    PlayerConfig.LastProfileName = OptionsFrame.ProfileDropDown.profileName
    PlayerConfig.Version = kTheVersion
    PlayerConfig_Save()

    -- L("APPLY") is also the save action for the currently selected shared
    -- profile.  The explicit L("SAVE_PROFILE") button remains useful when
    -- the user wants to update the shared profile without applying it to the
    -- character.
    local profileName = OptionsFrame.ProfileDropDown.profileName
    if profileName then
        Profile_Save(profileName, values)
    end

    CursorModel_Load(PlayerConfig)
    OptionsFrame.modified = false
    OptionsFrame.OriginalConfig = CopyTable(PlayerConfig)
    -- Keep the settings window open for rapid live calibration.
end

function OptionsFrame_OnCancel()
    if not OptionsFrame.OriginalConfig then return end

    -- Revert only changes made since the last Apply.  Do not close the window.
    OptionsFrame_WriteConfigToUI(OptionsFrame.OriginalConfig)
    local profileName = OptionsFrame.OriginalConfig.LastProfileName
    if not Profile_Get(profileName) then profileName = nil end
    OptionsFrame_SetProfileSelection(profileName)
    CursorModel_Load(OptionsFrame.OriginalConfig)
    CursorModel_Show(true)
    OptionsFrame.modified = false
end

function OptionsFrame_OnPreset(self)
    local idx = self.presetIndex or 1
    local current = OptionsFrame_ReadConfigFromUI()
    local combat = current.UserShowOnlyInCombat
    local preset

    if idx == 2 then
        preset = CopyTable(kDefaultConfig2)
    elseif idx == 3 then
        preset = CopyTable(kDefaultConfig3)
    elseif idx == 4 then
        preset = CopyTable(kDefaultConfig4)
    else
        preset = CopyTable(kDefaultConfig)
    end

    -- Preserve the user's visibility preference, as the original addon did.
    preset.UserShowOnlyInCombat = combat
    preset.TrailKey = current.TrailKey
    -- Existing model presets do not alter the independent model/2D choices.
    preset.ModelEnabled = current.ModelEnabled
    preset.MarkerEnabled = current.MarkerEnabled
    preset.MarkerName = current.MarkerName
    preset.MarkerColorR = current.MarkerColorR
    preset.MarkerColorG = current.MarkerColorG
    preset.MarkerColorB = current.MarkerColorB
    preset.MarkerScale = current.MarkerScale
    preset.MarkerOfsX = current.MarkerOfsX
    preset.MarkerOfsY = current.MarkerOfsY
    preset.MarkerAlpha = current.MarkerAlpha
    preset.HaloEnabled = current.HaloEnabled
    preset.HaloName = current.HaloName
    preset.HaloShape = current.HaloShape
    preset.HaloStyle = current.HaloStyle
    preset.HaloThickness = current.HaloThickness
    preset.HaloColorR = current.HaloColorR
    preset.HaloColorG = current.HaloColorG
    preset.HaloColorB = current.HaloColorB
    preset.HaloScale = current.HaloScale
    preset.HaloAlpha = current.HaloAlpha
    preset.HaloRotationEnabled = current.HaloRotationEnabled
    preset.HaloRotationInverted = current.HaloRotationInverted
    preset.HaloRotationSeconds = current.HaloRotationSeconds

    OptionsFrame_WriteConfigToUI(preset)
    OptionsFrame.modified = true
    OptionsFrame_ApplyPreview()
end

--- End of File ---
