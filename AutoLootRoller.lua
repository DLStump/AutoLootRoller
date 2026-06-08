local ADDON_NAME = ... or "AutoLootRoller"

local AutoLootRoller = {}
local DB

local QUALITY_UNCOMMON = 2
local QUALITY_RARE = 3
local QUALITY_EPIC = 4
local QUALITY_LEGENDARY = 5

local ROLL_PASS = 0
local ROLL_NEED = 1
local ROLL_GREED = 2

local DEFAULTS = {
    enabled = true,
    actions = {
        [QUALITY_UNCOMMON] = "DEFAULT",
        [QUALITY_RARE] = "DEFAULT",
        [QUALITY_EPIC] = "DEFAULT",
        [QUALITY_LEGENDARY] = "DEFAULT",
    },
}

local QUALITY_ROWS = {
    { quality = QUALITY_UNCOMMON, label = "Greens" },
    { quality = QUALITY_RARE, label = "Blues" },
    { quality = QUALITY_EPIC, label = "Purples" },
    { quality = QUALITY_LEGENDARY, label = "Oranges" },
}

local ACTIONS = {
    { key = "DEFAULT", label = "Default Prompt" },
    { key = "PASS", label = PASS or "Pass", rollType = ROLL_PASS },
    { key = "NEED", label = NEED or "Need", rollType = ROLL_NEED },
    { key = "GREED", label = GREED or "Greed", rollType = ROLL_GREED },
}

local ACTION_LABELS = {}
for _, action in ipairs(ACTIONS) do
    ACTION_LABELS[action.key] = action.label
end

local handledRolls = {}
local pendingConfirms = {}

local function CopyDefaults()
    local copy = { enabled = DEFAULTS.enabled, actions = {} }
    for quality, action in pairs(DEFAULTS.actions) do
        copy.actions[quality] = action
    end
    return copy
end

local function CopyConfig(source)
    local copy = { enabled = source.enabled, actions = {} }
    for _, row in ipairs(QUALITY_ROWS) do
        copy.actions[row.quality] = source.actions[row.quality]
    end
    return copy
end

local function ApplyDefaults(target)
    if target.enabled == nil then
        target.enabled = DEFAULTS.enabled
    end

    target.actions = target.actions or {}
    for quality, action in pairs(DEFAULTS.actions) do
        if ACTION_LABELS[target.actions[quality]] == nil then
            target.actions[quality] = action
        end
    end
end

local function InitializeDatabase()
    if type(AutoLootRollerDB) ~= "table" then
        AutoLootRollerDB = CopyDefaults()
    end

    if type(AutoLootRollerDB.actions) ~= "table" then
        AutoLootRollerDB.actions = {}
    end

    ApplyDefaults(AutoLootRollerDB)
    DB = AutoLootRollerDB
end

local function HideRollFrame(rollID)
    if NUM_GROUP_LOOT_FRAMES then
        for index = 1, NUM_GROUP_LOOT_FRAMES do
            local frame = _G["GroupLootFrame" .. index]
            if frame and frame.rollID == rollID then
                frame:Hide()
            end
        end
    end

    if StaticPopup_Hide then
        StaticPopup_Hide("CONFIRM_LOOT_ROLL", rollID)
    end
end

local function ClearRoll(rollID)
    handledRolls[rollID] = nil
    pendingConfirms[rollID] = nil
end

local function ResolveRollType(actionKey, canNeed, canGreed)
    if actionKey == "PASS" then
        return ROLL_PASS
    end

    if actionKey == "NEED" then
        if canNeed then
            return ROLL_NEED
        end
        if canGreed then
            return ROLL_GREED
        end
        return ROLL_PASS
    end

    if actionKey == "GREED" then
        if canGreed then
            return ROLL_GREED
        end
        return ROLL_PASS
    end

    return nil
end

function AutoLootRoller:HandleLootRoll(rollID)
    if not DB or not DB.enabled or not rollID then
        return
    end

    local _, _, _, quality, bindOnPickUp, canNeed, canGreed = GetLootRollItemInfo(rollID)
    local actionKey = quality and DB.actions[quality]
    if not actionKey then
        return
    end

    local rollType = ResolveRollType(actionKey, canNeed, canGreed)
    if rollType == nil then
        return
    end

    handledRolls[rollID] = true
    if bindOnPickUp and rollType ~= ROLL_PASS then
        pendingConfirms[rollID] = rollType
    end

    RollOnLoot(rollID, rollType)

    HideRollFrame(rollID)
end

function AutoLootRoller:HandleConfirm(rollID, rollType)
    local pendingRollType = pendingConfirms[rollID]
    if not pendingRollType then
        return
    end

    ConfirmLootRoll(rollID, rollType or pendingRollType)
    pendingConfirms[rollID] = nil
    HideRollFrame(rollID)
end

local function SetCheckButtonText(checkButton, text)
    local label = _G[checkButton:GetName() .. "Text"]
    if label then
        label:SetText(text)
    end
end

local function CreateLabel(parent, text, point, relativeTo, relativePoint, xOffset, yOffset)
    local label = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
    label:SetText(text)
    return label
end

local function GetActionLabel(actionKey)
    return ACTION_LABELS[actionKey] or ACTION_LABELS.DEFAULT
end

local function SaveEnabled(panel, enabled)
    enabled = enabled and true or false
    panel.working.enabled = enabled
    DB.enabled = enabled
end

local function SaveQualityAction(panel, quality, actionKey)
    if ACTION_LABELS[actionKey] == nil then
        actionKey = DEFAULTS.actions[quality] or "DEFAULT"
    end

    panel.working.actions[quality] = actionKey
    DB.actions = DB.actions or {}
    DB.actions[quality] = actionKey
end

local function Dropdown_OnClick(self)
    local dropdown = self.owner
    local actionKey = self.value

    dropdown.value = actionKey
    SaveQualityAction(dropdown.panel, dropdown.quality, actionKey)
    UIDropDownMenu_SetSelectedValue(dropdown, actionKey)
    UIDropDownMenu_SetText(dropdown, GetActionLabel(actionKey))
end

local function Dropdown_Initialize(dropdown)
    local info
    for _, action in ipairs(ACTIONS) do
        info = UIDropDownMenu_CreateInfo()
        info.text = action.label
        info.value = action.key
        info.func = Dropdown_OnClick
        info.owner = dropdown
        info.checked = dropdown.value == action.key
        UIDropDownMenu_AddButton(info)
    end
end

local function RefreshOptionsPanel(panel)
    panel.working = CopyConfig(DB)
    panel.enabledCheck:SetChecked(panel.working.enabled)

    for _, dropdown in ipairs(panel.dropdowns) do
        local actionKey = panel.working.actions[dropdown.quality] or "DEFAULT"
        dropdown.value = actionKey
        UIDropDownMenu_SetSelectedValue(dropdown, actionKey)
        UIDropDownMenu_SetText(dropdown, GetActionLabel(actionKey))
    end
end

local function ApplyOptionsPanel(panel)
    DB.enabled = panel.working.enabled and true or false
    DB.actions = DB.actions or {}

    for _, row in ipairs(QUALITY_ROWS) do
        DB.actions[row.quality] = panel.working.actions[row.quality] or DEFAULTS.actions[row.quality]
    end
end

local function ResetOptionsPanel(panel)
    DB.enabled = DEFAULTS.enabled
    DB.actions = {}
    for quality, action in pairs(DEFAULTS.actions) do
        DB.actions[quality] = action
    end
    RefreshOptionsPanel(panel)
end

local function CreateOptionsPanel()
    local panel = CreateFrame("Frame", "AutoLootRollerOptionsPanel", UIParent)
    panel.name = "Auto Loot Roller"
    panel.dropdowns = {}

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Auto Loot Roller")

    local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetText("Choose the automatic roll action for each item quality.")

    local enabledCheck = CreateFrame("CheckButton", "AutoLootRollerEnabledCheck", panel, "UICheckButtonTemplate")
    enabledCheck:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", -2, -18)
    SetCheckButtonText(enabledCheck, "Enable automatic loot rolling")
    enabledCheck:SetScript("OnClick", function(self)
        SaveEnabled(panel, self:GetChecked())
    end)
    panel.enabledCheck = enabledCheck

    local rowAnchor = enabledCheck
    for index, row in ipairs(QUALITY_ROWS) do
        local rowLabel = CreateLabel(panel, row.label, "TOPLEFT", rowAnchor, "BOTTOMLEFT", index == 1 and 2 or 0, index == 1 and -20 or -14)
        rowLabel:SetWidth(110)
        rowLabel:SetJustifyH("LEFT")

        local dropdown = CreateFrame("Frame", "AutoLootRollerQuality" .. row.quality .. "DropDown", panel, "UIDropDownMenuTemplate")
        dropdown:SetPoint("LEFT", rowLabel, "RIGHT", 18, -2)
        dropdown.panel = panel
        dropdown.quality = row.quality
        UIDropDownMenu_SetWidth(dropdown, 120)
        UIDropDownMenu_Initialize(dropdown, Dropdown_Initialize)
        panel.dropdowns[#panel.dropdowns + 1] = dropdown

        rowAnchor = rowLabel
    end

    local note = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    note:SetPoint("TOPLEFT", rowAnchor, "BOTTOMLEFT", 2, -22)
    note:SetWidth(520)
    note:SetJustifyH("LEFT")
    note:SetText("Default Prompt leaves Blizzard's normal roll prompt alone. If Need is unavailable, the addon rolls Greed if possible, otherwise Pass.")

    panel.refresh = function()
        RefreshOptionsPanel(panel)
    end
    panel.okay = function()
        ApplyOptionsPanel(panel)
    end
    panel.cancel = function()
        RefreshOptionsPanel(panel)
    end
    panel.default = function()
        ResetOptionsPanel(panel)
    end

    InterfaceOptions_AddCategory(panel)
    RefreshOptionsPanel(panel)
    AutoLootRoller.optionsPanel = panel
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("START_LOOT_ROLL")
eventFrame:RegisterEvent("CONFIRM_LOOT_ROLL")
eventFrame:RegisterEvent("CONFIRM_DISENCHANT_ROLL")
eventFrame:RegisterEvent("CANCEL_LOOT_ROLL")
eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddonName = ...
        if loadedAddonName == ADDON_NAME then
            InitializeDatabase()
            CreateOptionsPanel()
            eventFrame:UnregisterEvent("ADDON_LOADED")
        end
        return
    end

    if not DB then
        return
    end

    if event == "START_LOOT_ROLL" then
        AutoLootRoller:HandleLootRoll(...)
    elseif event == "CONFIRM_LOOT_ROLL" or event == "CONFIRM_DISENCHANT_ROLL" then
        AutoLootRoller:HandleConfirm(...)
    elseif event == "CANCEL_LOOT_ROLL" then
        local rollID = ...
        ClearRoll(rollID)
    end
end)

if hooksecurefunc and GroupLootFrame_OpenNewFrame then
    hooksecurefunc("GroupLootFrame_OpenNewFrame", function(rollID)
        if handledRolls[rollID] then
            HideRollFrame(rollID)
        end
    end)
end

SLASH_AUTOLOOTROLLER1 = "/alr"
SLASH_AUTOLOOTROLLER2 = "/autolootroller"
SlashCmdList.AUTOLOOTROLLER = function(message)
    if not DB then
        DEFAULT_CHAT_FRAME:AddMessage("Auto Loot Roller is still loading.")
        return
    end

    message = strlower(message or "")
    if message == "on" then
        DB.enabled = true
        if AutoLootRoller.optionsPanel then
            RefreshOptionsPanel(AutoLootRoller.optionsPanel)
        end
        DEFAULT_CHAT_FRAME:AddMessage("Auto Loot Roller enabled.")
    elseif message == "off" then
        DB.enabled = false
        if AutoLootRoller.optionsPanel then
            RefreshOptionsPanel(AutoLootRoller.optionsPanel)
        end
        DEFAULT_CHAT_FRAME:AddMessage("Auto Loot Roller disabled.")
    elseif InterfaceOptionsFrame_OpenToCategory and AutoLootRoller.optionsPanel then
        InterfaceOptionsFrame_OpenToCategory(AutoLootRoller.optionsPanel)
        InterfaceOptionsFrame_OpenToCategory(AutoLootRoller.optionsPanel)
    else
        DEFAULT_CHAT_FRAME:AddMessage("Auto Loot Roller: use /alr on, /alr off, or open Interface > AddOns > Auto Loot Roller.")
    end
end
