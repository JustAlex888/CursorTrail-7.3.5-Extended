--[[---------------------------------------------------------------------------
    Addon:  CursorTrail
    File:   CursorTrailLocale.lua
    Desc:   Russian / English localization for CursorTrail 7.3.5 Extended.

    The client locale is used automatically.  A hidden developer/test override
    can be selected with /ct english or /ct ru and takes effect after /reload.
-----------------------------------------------------------------------------]]

local Globals = _G
local CursorTrail = Globals.CursorTrail or {}
if (not Globals.CursorTrail) then Globals.CursorTrail = CursorTrail end

local RU = {
    -- General / interface panel.
    AUTHOR_ORIGINAL = "Автор оригинала: UppyDan (DJU)",
    ADAPTATION_EXTENDED = "Расширенная адаптация: JustAlex888",
    STANDARD_DESC = "Расширенная адаптация CursorTrail для World of Warcraft: Legion 7.3.5. Оригинальный аддон: UppyDan (DJU).",
    OPEN_SETTINGS = "Открыть настройки CursorTrail",

    -- Main sections.
    CURSOR_EFFECTS = "Эффекты курсора",
    EFFECTS_3D = "3D-эффекты",
    EFFECTS_2D = "2D-эффекты",
    DISPLAY = "Отображение",
    SHOW_ONLY_COMBAT = "Показывать только в бою",
    CURSOR_HALO = "Ореол курсора",
    PROFILES = "Профили",

    -- Generic controls.
    ON_OFF = "Вкл/Выкл",
    TYPE = "Тип",
    SIZE = "Размер",
    OFFSET_X = "Сдвиг X",
    OFFSET_Y = "Сдвиг Y",
    OPACITY = "Непрозр.",
    COLOR = "Цвет",
    SHAPE = "Форма",
    STYLE = "Стиль",
    THICKNESS = "Толщина",
    ROTATION = "Вращение",
    REVERSE_ROTATION = "Инверсия вращения",
    ROTATION_SPEED = "Скорость вращения",
    PROFILE = "Профиль:",
    NEW_PROFILE = "Новый профиль",
    SAVE_PROFILE = "Сохранить профиль",
    DELETE_PROFILE = "Удалить профиль",
    APPLY = "Применить",
    CANCEL = "Отмена",
    FOOTER_ACTIONS = "«Применить» — сохраняет.      «Отмена» — откатывает.",

    -- Tooltips.
    TT_MODEL_TOGGLE = "Включает или выключает выбранный анимированный 3D-эффект курсора.",
    TT_MODEL_TYPE_TITLE = "3D-эффект",
    TT_MODEL_TYPE = "Переключает анимированный 3D-эффект курсора. Некоторые модели могут отсутствовать в отдельных сборках клиента WoW 7.3.5.",
    TT_MODEL_SIZE = "Размер 3D-эффекта. Диапазон: 4% — 300%.",
    TT_MODEL_X = "Перемещает 3D-эффект левее или правее относительно курсора. Диапазон: -20 — +20.",
    TT_MODEL_Y = "Перемещает 3D-эффект выше или ниже относительно курсора. Диапазон: -20 — +20.",
    TT_MODEL_ALPHA = "Регулирует видимость 3D-эффекта: 100% означает полностью видимый эффект.",
    TT_MARKER_TOGGLE = "Включает или выключает выбранный плоский 2D-эффект курсора.",
    TT_MARKER_TITLE = "2D-эффект",
    TT_MARKER_TYPE = "Плоский 2D-эффект курсора: диск, свечение, крест или вихрь.",
    TT_MARKER_COLOR = "Изменяет цвет 2D-эффекта.",
    TT_MARKER_SIZE = "Изменяет размер 2D-эффекта.",
    TT_MARKER_X = "Перемещает 2D-эффект левее или правее относительно курсора.",
    TT_MARKER_Y = "Перемещает 2D-эффект выше или ниже относительно курсора.",
    TT_MARKER_ALPHA = "Регулирует видимость 2D-эффекта.",
    TT_HALO_TOGGLE = "Включает или выключает ореол вокруг курсора.",
    TT_HALO_SHAPE_TITLE = "Форма ореола",
    TT_HALO_SHAPE = "Выберите круг или квадрат.",
    TT_HALO_STYLE_TITLE = "Стиль ореола",
    TT_HALO_STYLE = "Одноцветный стиль использует выбранный цвет. Спектральный содержит собственный радужный градиент.",
    TT_HALO_THICKNESS = "Толщина ореола. Увеличение идёт внутрь при неизменном внешнем размере.",
    TT_HALO_COLOR = "Изменяет цвет одноцветного ореола. Для спектрального стиля цвет задан самой текстурой.",
    TT_HALO_SIZE = "Изменяет размер ореола вокруг курсора.",
    TT_HALO_ALPHA = "Регулирует видимость ореола.",
    TT_HALO_ROTATION = "Вращает весь ореол. По умолчанию направление против часовой стрелки.",
    TT_HALO_REVERSE = "Меняет направление вращения на противоположное: по часовой стрелке.",
    TT_HALO_SPEED = "Скорость вращения ореола: 1 — минимальная, 5 — максимальная.",
    TT_COMBAT = "Эффект появляется при входе в бой и скрывается после выхода из боя.",
    TT_PROFILE_TITLE = "Профиль",
    TT_PROFILE = "Общий набор настроек, доступный всем персонажам этого WoW-аккаунта.",

    -- Profile UI and dialogs.
    PROFILE_NONE = "Не выбран",
    PROFILE_EMPTY = "Нет сохранённых профилей",
    PROFILE_NAME_EMPTY = "Имя профиля не может быть пустым.",
    PROFILE_ENTER_NAME = "Введите непустое имя профиля.",
    PROFILE_SELECT_OR_CREATE = "Сначала выберите профиль или создайте новый.",
    PROFILE_SELECT_DELETE = "Сначала выберите профиль для удаления.",
    OK = "Понятно",
    NEW_PROFILE_PROMPT = "Введите имя нового профиля:",
    CREATE = "Создать",
    OVERWRITE_PROFILE = "Профиль «%s» уже существует. Перезаписать его текущими настройками?",
    OVERWRITE = "Перезаписать",
    DELETE_PROFILE_PROMPT = "Удалить профиль «%s»? Это нельзя отменить.",
    DELETE = "Удалить",

    -- 2D marker names.
    MARKER_DISK = "Диск",
    MARKER_GLOW = "Свечение",
    MARKER_CROSS_1 = "Крест 1",
    MARKER_CROSS_2 = "Крест 2",
    MARKER_SWIRL = "Вихрь",

    -- Halo names.
    HALO_CIRCLE = "Круг",
    HALO_SQUARE = "Квадрат",
    HALO_SOLID = "Одноцветный",
    HALO_SPECTRAL = "Спектральный",
    HALO_RING_1 = "Кольцо 1",
    HALO_RING_2 = "Кольцо 2",
    HALO_RING_3 = "Кольцо 3",
    HALO_RING_4 = "Кольцо 4",
    HALO_RING_SOFT_1 = "Мягкое кольцо 1",
    HALO_RING_SOFT_2 = "Мягкое кольцо 2",

    -- 3D effect names.
    TRAIL_ELECTRIC_BLUE_LONG = "Электрический — синий, длинный",
    TRAIL_ELECTRIC_BLUE_SHORT = "Электрический — синий, короткий",
    TRAIL_ELECTRIC_GREEN_SHORT = "Электрический — зелёный, короткий",
    TRAIL_ELECTRIC_GREEN_PULSE = "Электрический — зелёный импульс",
    TRAIL_LIGHT = "Световой",
    TRAIL_GHOST = "Призрачный",
    TRAIL_PULSE_GREEN = "Пульсация — зелёная",
    TRAIL_PULSE_YELLOW = "Пульсация — жёлтая",
    TRAIL_SWIRL_NATURE = "Вихрь — природный",
    TRAIL_SPHERE_ORANGE = "Сфера — оранжевая",

    -- Slash / chat strings.
    COMMANDS = "Команды:",
    CMD_RELOAD = "Перезагрузить текущие настройки курсора.",
    CMD_RESET = "Сбросить настройки курсора к исходным.",
    CMD_COMBAT = "Переключить режим «только в бою».",
    CMD_SCREEN = "Показать информацию об экране в чате.",
    CMD_CAMERA = "Показать информацию о камере в чате.",
    CMD_CONFIG = "Показать конфигурацию в чате.",
    CMD_MODEL = "Показать информацию о модели в чате.",
    CMD_CAL = "Откалибровать эффект курсора по мыши.",
    RESET_DONE = "настройки сброшены к исходным.",
    RELOAD_DONE = "настройки перезагружены.",
    MODE_ALWAYS = "режим = показывать всегда",
    MODE_COMBAT = "режим = показывать только в бою",
    INVALID_COMMAND = "Недопустимая команда",
    LOADED = "загружен. Настройки: /ct или /CursorTrail.",
}

local EN = {
    AUTHOR_ORIGINAL = "Original author: UppyDan (DJU)",
    ADAPTATION_EXTENDED = "Extended adaptation: JustAlex888",
    STANDARD_DESC = "Extended CursorTrail adaptation for World of Warcraft: Legion 7.3.5. Original addon: UppyDan (DJU).",
    OPEN_SETTINGS = "Open CursorTrail Settings",

    CURSOR_EFFECTS = "Cursor Effects",
    EFFECTS_3D = "3D Effects",
    EFFECTS_2D = "2D Effects",
    DISPLAY = "Display",
    SHOW_ONLY_COMBAT = "Show only in combat",
    CURSOR_HALO = "Cursor Halo",
    PROFILES = "Profiles",

    ON_OFF = "On/Off",
    TYPE = "Type",
    SIZE = "Size",
    OFFSET_X = "X Offset",
    OFFSET_Y = "Y Offset",
    OPACITY = "Opacity",
    COLOR = "Color",
    SHAPE = "Shape",
    STYLE = "Style",
    THICKNESS = "Thickness",
    ROTATION = "Rotation",
    REVERSE_ROTATION = "Reverse Rotation",
    ROTATION_SPEED = "Rotation Speed",
    PROFILE = "Profile:",
    NEW_PROFILE = "New Profile",
    SAVE_PROFILE = "Save Profile",
    DELETE_PROFILE = "Delete Profile",
    APPLY = "Apply",
    CANCEL = "Cancel",
    FOOTER_ACTIONS = "\"Apply\" — saves.      \"Cancel\" — reverts.",

    TT_MODEL_TOGGLE = "Enables or disables the selected animated 3D cursor effect.",
    TT_MODEL_TYPE_TITLE = "3D Effect",
    TT_MODEL_TYPE = "Selects the animated 3D cursor effect. Some models may be unavailable in particular WoW 7.3.5 client builds.",
    TT_MODEL_SIZE = "3D effect size. Range: 4%–300%.",
    TT_MODEL_X = "Moves the 3D effect left or right relative to the cursor. Range: -20 to +20.",
    TT_MODEL_Y = "Moves the 3D effect up or down relative to the cursor. Range: -20 to +20.",
    TT_MODEL_ALPHA = "Controls 3D effect visibility: 100% is fully visible.",
    TT_MARKER_TOGGLE = "Enables or disables the selected flat 2D cursor effect.",
    TT_MARKER_TITLE = "2D Effect",
    TT_MARKER_TYPE = "Flat 2D cursor effect: disk, glow, cross, or swirl.",
    TT_MARKER_COLOR = "Changes the 2D effect color.",
    TT_MARKER_SIZE = "Changes the 2D effect size.",
    TT_MARKER_X = "Moves the 2D effect left or right relative to the cursor.",
    TT_MARKER_Y = "Moves the 2D effect up or down relative to the cursor.",
    TT_MARKER_ALPHA = "Controls 2D effect visibility.",
    TT_HALO_TOGGLE = "Enables or disables the halo around the cursor.",
    TT_HALO_SHAPE_TITLE = "Halo Shape",
    TT_HALO_SHAPE = "Choose a circle or square.",
    TT_HALO_STYLE_TITLE = "Halo Style",
    TT_HALO_STYLE = "Single Color uses the selected color. Spectral uses its own rainbow gradient.",
    TT_HALO_THICKNESS = "Halo thickness. Thickness grows inward while the outer size stays unchanged.",
    TT_HALO_COLOR = "Changes the solid halo color. Spectral style uses the color embedded in its texture.",
    TT_HALO_SIZE = "Changes the halo size around the cursor.",
    TT_HALO_ALPHA = "Controls halo visibility.",
    TT_HALO_ROTATION = "Rotates the entire halo. Default direction is counter-clockwise.",
    TT_HALO_REVERSE = "Reverses the rotation direction to clockwise.",
    TT_HALO_SPEED = "Halo rotation speed: 1 is slowest, 5 is fastest.",
    TT_COMBAT = "The effect appears when combat starts and hides after combat ends.",
    TT_PROFILE_TITLE = "Profile",
    TT_PROFILE = "A shared settings preset available to all characters on this WoW account.",

    PROFILE_NONE = "Not selected",
    PROFILE_EMPTY = "No saved profiles",
    PROFILE_NAME_EMPTY = "Profile name cannot be empty.",
    PROFILE_ENTER_NAME = "Enter a non-empty profile name.",
    PROFILE_SELECT_OR_CREATE = "Select a profile first or create a new one.",
    PROFILE_SELECT_DELETE = "Select a profile to delete first.",
    OK = "OK",
    NEW_PROFILE_PROMPT = "Enter a name for the new profile:",
    CREATE = "Create",
    OVERWRITE_PROFILE = "Profile \"%s\" already exists. Overwrite it with the current settings?",
    OVERWRITE = "Overwrite",
    DELETE_PROFILE_PROMPT = "Delete profile \"%s\"? This cannot be undone.",
    DELETE = "Delete",

    MARKER_DISK = "Disk",
    MARKER_GLOW = "Glow",
    MARKER_CROSS_1 = "Cross 1",
    MARKER_CROSS_2 = "Cross 2",
    MARKER_SWIRL = "Swirl",

    HALO_CIRCLE = "Circle",
    HALO_SQUARE = "Square",
    HALO_SOLID = "Single Color",
    HALO_SPECTRAL = "Spectral",
    HALO_RING_1 = "Ring 1",
    HALO_RING_2 = "Ring 2",
    HALO_RING_3 = "Ring 3",
    HALO_RING_4 = "Ring 4",
    HALO_RING_SOFT_1 = "Soft Ring 1",
    HALO_RING_SOFT_2 = "Soft Ring 2",

    TRAIL_ELECTRIC_BLUE_LONG = "Electric — Blue, Long",
    TRAIL_ELECTRIC_BLUE_SHORT = "Electric — Blue, Short",
    TRAIL_ELECTRIC_GREEN_SHORT = "Electric — Green, Short",
    TRAIL_ELECTRIC_GREEN_PULSE = "Electric — Green Pulse",
    TRAIL_LIGHT = "Light",
    TRAIL_GHOST = "Ghostly",
    TRAIL_PULSE_GREEN = "Pulse — Green",
    TRAIL_PULSE_YELLOW = "Pulse — Yellow",
    TRAIL_SWIRL_NATURE = "Swirl — Nature",
    TRAIL_SPHERE_ORANGE = "Sphere — Orange",

    COMMANDS = "Commands:",
    CMD_RELOAD = "Reload current cursor settings.",
    CMD_RESET = "Reset cursor settings to defaults.",
    CMD_COMBAT = "Toggle the show-only-in-combat mode.",
    CMD_SCREEN = "Print screen information in chat.",
    CMD_CAMERA = "Print camera information in chat.",
    CMD_CONFIG = "Print configuration information in chat.",
    CMD_MODEL = "Print model information in chat.",
    CMD_CAL = "Calibrate the cursor effect to your mouse.",
    RESET_DONE = "settings reset to defaults.",
    RELOAD_DONE = "settings reloaded.",
    MODE_ALWAYS = "mode = Always Show",
    MODE_COMBAT = "mode = Show Only in Combat",
    INVALID_COMMAND = "Invalid slash command",
    LOADED = "loaded. Options: /ct or /CursorTrail.",
}

local function NormalizeLanguage(code)
    if type(code) ~= "string" then return nil end
    code = string.lower(code)
    if code == "ru" or code == "ruru" or code == "russian" then return "ru" end
    if code == "en" or code == "enus" or code == "engb" or code == "english" then return "en" end
    return nil
end

local function DetectLanguage()
    local saved = Globals.CursorTrail_ProfilesDB
    local override = type(saved) == "table" and NormalizeLanguage(saved.LanguageOverride) or nil
    if override then return override end

    local clientLocale = Globals.GetLocale and Globals.GetLocale() or "enUS"
    if clientLocale == "ruRU" then return "ru" end
    return "en"
end

CursorTrail.LocaleCode = DetectLanguage()

function CursorTrail.Locale_RefreshFromSaved()
    CursorTrail.LocaleCode = DetectLanguage()
    return CursorTrail.LocaleCode
end

function CursorTrail.L(key)
    local tableForLocale = (CursorTrail.LocaleCode == "ru") and RU or EN
    return tableForLocale[key] or EN[key] or RU[key] or key
end

function CursorTrail.Locale_GetCode()
    return CursorTrail.LocaleCode
end

function CursorTrail.Locale_SetOverride(code)
    local normalized = NormalizeLanguage(code)
    if not normalized then return false end

    Globals.CursorTrail_ProfilesDB = Globals.CursorTrail_ProfilesDB or {}
    Globals.CursorTrail_ProfilesDB.LanguageOverride = normalized
    return true
end

