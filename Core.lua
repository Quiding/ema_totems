local addonName, ns = ...
local EMA_Totems = LibStub("AceAddon-3.0"):NewAddon("EMA_Totems", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
ns.EMA_Totems = EMA_Totems

EMA_Totems.moduleName = "EMA_Totems"
EMA_Totems.settingsDatabaseName = "EMA_TotemsProfileDB"
EMA_Totems.chatCommand = "ema-totems"

-- Initialize runtime tables immediately
EMA_Totems.shamanMembers = {}
EMA_Totems.activeTotems = {}
EMA_Totems.lastUsedTotems = {}

local L = LibStub("AceLocale-3.0"):GetLocale("Core")
local EMAUtilities = LibStub:GetLibrary("EbonyUtilities-1.0")

-- EMA metadata
EMA_Totems.parentDisplayName = "Class"
EMA_Totems.moduleDisplayName = "Totems"
EMA_Totems.moduleIcon = "Interface\\Addons\\EMA\\Media\\SettingsIcon.tga"
EMA_Totems.moduleOrder = 10

-- EMA key bindings
_G["BINDING_HEADER_EMATOTEMS"] = "Totems"
_G["BINDING_NAME_EMATOTEMSSEQUENCE"] = "EMA: Cast Totem Sequence"

-- EMA integration mixins
local EMAModule = LibStub("Module-1.0")
EMAModule:Embed(EMA_Totems)

-- Totem Data
ns.totemData = {
    ["Searing Totem"] = { element = "Fire", duration = 55 },
    ["Magma Totem"] = { element = "Fire", duration = 20 },
    ["Fire Nova Totem"] = { element = "Fire", duration = 5 },
    ["Flametongue Totem"] = { element = "Fire", duration = 120 },
    ["Frost Resistance Totem"] = { element = "Fire", duration = 120 },
    ["Totem of Wrath"] = { element = "Fire", duration = 120 },
    ["Fire Elemental Totem"] = { element = "Fire", duration = 120 },
    ["Strength of Earth Totem"] = { element = "Earth", duration = 120 },
    ["Stoneskin Totem"] = { element = "Earth", duration = 120 },
    ["Earthbind Totem"] = { element = "Earth", duration = 45 },
    ["Stoneclaw Totem"] = { element = "Earth", duration = 15 },
    ["Earth Elemental Totem"] = { element = "Earth", duration = 120 },
    ["Tremor Totem"] = { element = "Earth", duration = 120 },
    ["Healing Stream Totem"] = { element = "Water", duration = 120 },
    ["Mana Spring Totem"] = { element = "Water", duration = 120 },
    ["Fire Resistance Totem"] = { element = "Water", duration = 120 },
    ["Poison Cleansing Totem"] = { element = "Water", duration = 120 },
    ["Disease Cleansing Totem"] = { element = "Water", duration = 120 },
    ["Windfury Totem"] = { element = "Air", duration = 120 },
    ["Grace of Air Totem"] = { element = "Air", duration = 120 },
    ["Wrath of Air Totem"] = { element = "Air", duration = 120 },
    ["Nature Resistance Totem"] = { element = "Air", duration = 120 },
    ["Windwall Totem"] = { element = "Air", duration = 120 },
    ["Grounding Totem"] = { element = "Air", duration = 45 },
    ["Sentry Totem"] = { element = "Air", duration = 300 },
    ["Tranquil Air Totem"] = { element = "Air", duration = 120 },
}

ns.totemLists = {
    Fire = { 30706, 2894, 8227, 8190, 3599, 8181, 1535 },
    Air = { 8835, 8177, 10595, 6495, 25908, 8512, 15107, 3738 },
    Earth = { 8143, 8075, 2484, 5730, 2062, 8071 },
    Water = { 5675, 5394, 8184, 8170, 8166 }
}

ns.totemMapping = { Fire = 1, Earth = 2, Water = 3, Air = 4 }

-- Settings defaults
EMA_Totems.settings = {
    profile = {
        showBars = true,
        onlyTimers = false,
        useSpamMacro = false,
        barScale = 1.0,
        barAlpha = 1.0,
        lockBars = false,
        barOrder = "NameAsc",
        showNames = true,
        borderStyle = "Blizzard Tooltip",
        backgroundStyle = "Blizzard Dialog Background",
        fontStyle = "Arial Narrow",
        fontSize = 12,
        iconSize = 36,
        iconMargin = 4,
        barMargin = 4,
        showTimers = true,
        timerFontSize = 16,
        timerColorR = 1.0,
        timerColorG = 1.0,
        timerColorB = 1.0,
        selectedTotems = {},
        castSequences = {},
        teamBarsPos = { point = "CENTER", x = 0, y = 0 },
        sequenceKeybind = "",
    }
}

-- Commands
EMA_Totems.COMMAND_UPDATE_TOTEMS = "EMATotemsUpdate"
EMA_Totems.COMMAND_PUSH_ALL = "EMATotemsPushAll"
EMA_Totems.COMMAND_REPORT_CLASS = "EMATotemsReportClass"
EMA_Totems.COMMAND_TOTEM_STATUS = "EMATotemsStatus"

function EMA_Totems:OnInitialize()
    local k = GetRealmName()
    local realm = k:gsub( "%s+", "")
    self.characterRealm = realm
    self.characterNameLessRealm = UnitName( "player" ) 
    self.characterName = self.characterNameLessRealm.."-"..self.characterRealm

    self:SettingsCreate()
    self:RegisterChatCommand("et", "ChatCommand")
    self:RegisterChatCommand("ema-totems", "ChatCommand")
    self:SettingsRefresh()
end

function EMA_Totems:ChatCommand(input)
    local cmd = input and input:trim():lower() or ""
    if cmd == "config" then
        self:EMAChatCommand("config")
    elseif cmd == "refresh" then
        ns.UI:RefreshBars()
    elseif cmd == "show" then
        self.db.showBars = true
        ns.UI:RefreshBars()
    elseif cmd == "hide" then
        self.db.showBars = false
        ns.UI:RefreshBars()
    else
        self:Print("Usage: /et config, /et refresh, /et show, /et hide")
    end
end

function EMA_Totems:OnEnable()
    self:RegisterEvent("PLAYER_TOTEM_UPDATE")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterEvent("PLAYER_LOGIN")
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    self:RegisterEvent("UPDATE_BINDINGS")
    if EMAApi then
        self:RegisterMessage( EMAApi.MESSAGE_CHARACTER_ONLINE, "PLAYER_LOGIN" )
        self:RegisterMessage( EMAApi.MESSAGE_CHARACTER_OFFLINE, "PLAYER_LOGIN" )
    end
    self.keyBindingFrame = CreateFrame("Frame", nil, UIParent)
    self:UPDATE_BINDINGS()
    self:ScheduleTimer("DoInitialReport", 1.0)
    if ns.UI then ns.UI:Initialize() end
end

function EMA_Totems:UPDATE_BINDINGS()
    if InCombatLockdown() then return end
    ClearOverrideBindings(self.keyBindingFrame)
    local directKey = self.db.sequenceKeybind
    if directKey and directKey ~= "" then
        SetOverrideBindingClick(self.keyBindingFrame, false, directKey, "EMATotemsSequenceButton")
    end
    local nativeKey1, nativeKey2 = GetBindingKey("EMATOTEMSSEQUENCE")
    if nativeKey1 then SetOverrideBindingClick(self.keyBindingFrame, false, nativeKey1, "EMATotemsSequenceButton") end
    if nativeKey2 then SetOverrideBindingClick(self.keyBindingFrame, false, nativeKey2, "EMATotemsSequenceButton") end
end

function EMA_Totems:DoInitialReport()
    local _, class = UnitClass("player")
    if class == "SHAMAN" then
        self:EMASendCommandToMaster(self.COMMAND_REPORT_CLASS, true)
    end
end

function EMA_Totems:PLAYER_LOGIN()
    if ns.UI then ns.UI:RefreshBars() end
end

function EMA_Totems:COMBAT_LOG_EVENT_UNFILTERED()
    local _, event, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    if event == "SPELL_SUMMON" or event == "SPELL_CAST_SUCCESS" then
        local characterName = EMAUtilities:AddRealmToNameIfMissing(sourceName)
        if EMAApi.IsCharacterInTeam(characterName) then
            local data = ns.totemData[spellName]
            if data then
                local sender = Ambiguate(characterName, "none")
                local icon = select(3, GetSpellInfo(spellID))
                self.activeTotems[sender] = self.activeTotems[sender] or {}
                self.activeTotems[sender][data.element] = {
                    name = spellName,
                    startTime = GetTime(),
                    duration = data.duration,
                    icon = icon
                }
                self.lastUsedTotems[sender] = self.lastUsedTotems[sender] or {}
                self.lastUsedTotems[sender][data.element] = {
                    name = spellName,
                    icon = icon
                }
                ns.UI:UpdateTimers()
            end
        end
    end
end

function EMA_Totems:PushSettingsToTeam()
    self:EMASendSettings()
    self:EMASendCommandToTeam(self.COMMAND_PUSH_ALL)
end

function EMA_Totems:UpdateTotemForShaman(shamanName, slot, totemName)
    if not self.db.selectedTotems[shamanName] then
        self.db.selectedTotems[shamanName] = {}
    end
    self.db.selectedTotems[shamanName][slot] = totemName
    if EMAApi.IsCharacterTheMaster(self.characterName) then
        if shamanName == "all" then
             self:EMASendCommandToTeam(self.COMMAND_UPDATE_TOTEMS, slot, totemName)
        else
             self:EMASendCommandToToon(shamanName, self.COMMAND_UPDATE_TOTEMS, slot, totemName)
        end
    end
end

function EMA_Totems:EMAOnCommandReceived(characterName, commandName, ...)
    if commandName == self.COMMAND_UPDATE_TOTEMS then
        local slot, totemName = ...
        local myName = self.characterName
        if not self.db.selectedTotems[myName] then self.db.selectedTotems[myName] = {} end
        self.db.selectedTotems[myName][slot] = totemName
        ns.UI:UpdateMyBar()
    elseif commandName == self.COMMAND_REPORT_CLASS then
        local isShaman = ...
        if isShaman then self.shamanMembers[characterName] = true end
        ns.UI:RefreshBars()
    elseif commandName == self.COMMAND_TOTEM_STATUS then
        local statusData = ...
        local sender = Ambiguate(characterName, "none")
        self.activeTotems[sender] = statusData
        if statusData then
            self.lastUsedTotems[sender] = self.lastUsedTotems[sender] or {}
            for slot, data in pairs(statusData) do
                self.lastUsedTotems[sender][slot] = { name = data.name, icon = data.icon }
            end
        end
    elseif commandName == self.COMMAND_PUSH_ALL then
        ns.UI:RefreshBars()
    end
end

function EMA_Totems:EMAOnSettingsReceived(characterName, settings)
    if characterName ~= self.characterName then
        self.db.showBars = settings.showBars
        self.db.onlyTimers = settings.onlyTimers
        self.db.useSpamMacro = settings.useSpamMacro
        self.db.barScale = settings.barScale
        self.db.barAlpha = settings.barAlpha
        self.db.lockBars = settings.lockBars
        self.db.barOrder = settings.barOrder
        self.db.showNames = settings.showNames
        self.db.borderStyle = settings.borderStyle
        self.db.backgroundStyle = settings.backgroundStyle
        self.db.fontStyle = settings.fontStyle
        self.db.fontSize = settings.fontSize
        self.db.iconSize = settings.iconSize
        self.db.iconMargin = settings.iconMargin
        self.db.barMargin = settings.barMargin
        self.db.showTimers = settings.showTimers
        self.db.timerFontSize = settings.timerFontSize
        self.db.timerColorR = settings.timerColorR
        self.db.timerColorG = settings.timerColorG
        self.db.timerColorB = settings.timerColorB
        self.db.frameBackgroundColourR = settings.frameBackgroundColourR
        self.db.frameBackgroundColourG = settings.frameBackgroundColourG
        self.db.frameBackgroundColourB = settings.frameBackgroundColourB
        self.db.frameBackgroundColourA = settings.frameBackgroundColourA
        self.db.frameBorderColourR = settings.frameBorderColourR
        self.db.frameBorderColourG = settings.frameBorderColourG
        self.db.frameBorderColourB = settings.frameBorderColourB
        self.db.frameBorderColourA = settings.frameBorderColourA
        self.db.selectedTotems = EMAUtilities:CopyTable( settings.selectedTotems )
        self.db.castSequences = EMAUtilities:CopyTable( settings.castSequences )
        self.db.teamBarsPos = EMAUtilities:CopyTable( settings.teamBarsPos )
        self.db.sequenceKeybind = settings.sequenceKeybind
        self:SettingsRefresh()
        ns.UI:RefreshBars()
        ns.UI:UpdatePositionFromDB()
        self:UPDATE_BINDINGS()
    end
end

function EMA_Totems:PLAYER_TOTEM_UPDATE()
    ns.UI:UpdateTimers()
    self:BroadcastTotemStatus()
end

function EMA_Totems:BroadcastTotemStatus()
    local _, class = UnitClass("player")
    if class ~= "SHAMAN" then return end
    self:DoBroadcastTotemStatus()
end

function EMA_Totems:DoBroadcastTotemStatus()
    local status = {}
    for slotName, index in pairs(ns.totemMapping) do
        local haveTotem, name, startTime, duration, icon = GetTotemInfo(index)
        if haveTotem and duration > 0 then
            status[slotName] = { name = name, startTime = startTime, duration = duration, icon = icon }
        end
    end
    self:EMASendCommandToTeam(self.COMMAND_TOTEM_STATUS, status)
end

function EMA_Totems:PLAYER_REGEN_ENABLED()
    ns.UI:UpdateMacros()
    self:UPDATE_BINDINGS()
end

-- Define GetConfiguration BEFORE EMAModuleInitialize
function EMA_Totems:GetConfiguration()
    local configuration = {
        name = "Totems", handler = self, type = 'group',
        args = {
            showBars = { type = "toggle", name = "Show Totem Bars", get = "EMAConfigurationGetSetting", set = "EMAConfigurationSetSetting" },
        },
    }
    return configuration
end

function EMA_Totems:SettingsCreate()
    self.settingsControl = {}
    self.settingsControlClass = {}
    local EMAHelperSettings = LibStub:GetLibrary("EMAHelperSettings-1.0")
    
    EMAHelperSettings:CreateSettings(self.settingsControlClass, "Class", "Class", function() end, "Interface\\AddOns\\EMA\\Media\\TeamCore.tga", 5)
    EMAHelperSettings:CreateSettings(self.settingsControl, "Totems", "Class", function() self:PushSettingsToTeam() end, "Interface\\Addons\\EMA\\Media\\SettingsIcon.tga", 10)
    
    local top, left = EMAHelperSettings:TopOfSettings(), EMAHelperSettings:LeftOfSettings()
    local headingHeight, headingWidth = EMAHelperSettings:HeadingHeight(), EMAHelperSettings:HeadingWidth(true)
    local checkBoxHeight, sliderHeight = EMAHelperSettings:GetCheckBoxHeight(), EMAHelperSettings:GetSliderHeight()
    local dropdownHeight = EMAHelperSettings:GetDropdownHeight()
    local verticalSpacing = EMAHelperSettings:GetVerticalSpacing()
    local movingTop = top
    
    EMAHelperSettings:CreateHeading(self.settingsControl, "General Options", movingTop, false)
    movingTop = movingTop - headingHeight
    self.settingsControl.checkBoxShowBars = EMAHelperSettings:CreateCheckBox(self.settingsControl, headingWidth, left, movingTop, "Show Totem Bars", function(w, e, v) self.db.showBars = v; ns.UI:RefreshBars() end)
    movingTop = movingTop - checkBoxHeight
    self.settingsControl.checkBoxOnlyTimers = EMAHelperSettings:CreateCheckBox(self.settingsControl, headingWidth, left, movingTop, "Only Timers Mode (Passive)", function(w, e, v) self.db.onlyTimers = v; self:SettingsRefresh(); ns.UI:RefreshBars() end)
    movingTop = movingTop - checkBoxHeight
    self.settingsControl.checkBoxSpamMacro = EMAHelperSettings:CreateCheckBox(self.settingsControl, headingWidth, left, movingTop, "Use Spam-safe Sequence (,null)", function(w, e, v) self.db.useSpamMacro = v; ns.UI:UpdateMacros() end)
    movingTop = movingTop - checkBoxHeight
    self.settingsControl.checkBoxLockBars = EMAHelperSettings:CreateCheckBox(self.settingsControl, headingWidth, left, movingTop, "Lock Bars (Alt-Click to move)", function(w, e, v) self.db.lockBars = v end)
    movingTop = movingTop - checkBoxHeight
    self.settingsControl.checkBoxShowNames = EMAHelperSettings:CreateCheckBox(self.settingsControl, headingWidth, left, movingTop, "Show Character Names", function(w, e, v) self.db.showNames = v; ns.UI:RefreshBars() end)
    movingTop = movingTop - checkBoxHeight
    self.settingsControl.sliderScale = EMAHelperSettings:CreateSlider(self.settingsControl, headingWidth, left, movingTop, "Bar Scale")
    self.settingsControl.sliderScale:SetSliderValues(0.5, 2.0, 0.01)
    self.settingsControl.sliderScale:SetCallback("OnValueChanged", function(w, e, v) self.db.barScale = tonumber(v); ns.UI:RefreshBars() end)
    movingTop = movingTop - sliderHeight
    self.settingsControl.sliderAlpha = EMAHelperSettings:CreateSlider(self.settingsControl, headingWidth, left, movingTop, "Bar Alpha")
    self.settingsControl.sliderAlpha:SetSliderValues(0.1, 1.0, 0.01)
    self.settingsControl.sliderAlpha:SetCallback("OnValueChanged", function(w, e, v) self.db.barAlpha = tonumber(v); ns.UI:RefreshBars() end)
    movingTop = movingTop - sliderHeight
    self.settingsControl.dropdownOrder = EMAHelperSettings:CreateDropdown(self.settingsControl, headingWidth, left, movingTop, "Bar Order")
    self.settingsControl.dropdownOrder:SetList({["NameAsc"] = "Name (Asc)", ["NameDesc"] = "Name (Desc)", ["EMAPosition"] = "EMA Team Order"})
    self.settingsControl.dropdownOrder:SetCallback("OnValueChanged", function(w, e, v) self.db.barOrder = v; ns.UI:RefreshBars() end)
    movingY = movingTop - dropdownHeight - verticalSpacing
    self.settingsControl.buttonRefreshTeam = EMAHelperSettings:CreateButton(self.settingsControl, headingWidth, left, movingY, "Refresh Team Members", function() ns.UI:RefreshBars() end)
    movingY = movingY - 30

    EMAHelperSettings:CreateHeading(self.settingsControl, "Appearance & Layout", movingY, false)
    movingY = movingY - headingHeight
    self.settingsControl.dropdownBorder = EMAHelperSettings:CreateMediaBorder(self.settingsControl, headingWidth, left, movingY, "Border Style")
    self.settingsControl.dropdownBorder:SetCallback("OnValueChanged", function(w, e, v) self.db.borderStyle = v; ns.UI:RefreshBars() end)
    movingY = movingY - 110
    self.settingsControl.dropdownBackground = EMAHelperSettings:CreateMediaBackground(self.settingsControl, headingWidth, left, movingY, "Background Style")
    self.settingsControl.dropdownBackground:SetCallback("OnValueChanged", function(w, e, v) self.db.backgroundStyle = v; ns.UI:RefreshBars() end)
    movingY = movingY - 110
    self.settingsControl.dropdownFont = EMAHelperSettings:CreateMediaFont(self.settingsControl, headingWidth, left, movingY, "Font Style")
    self.settingsControl.dropdownFont:SetCallback("OnValueChanged", function(w, e, v) self.db.fontStyle = v; ns.UI:RefreshBars() end)
    movingY = movingY - 110
    self.settingsControl.sliderFontSize = EMAHelperSettings:CreateSlider(self.settingsControl, headingWidth, left, movingY, "Font Size")
    self.settingsControl.sliderFontSize:SetSliderValues(6, 24, 1)
    self.settingsControl.sliderFontSize:SetCallback("OnValueChanged", function(w, e, v) self.db.fontSize = tonumber(v); ns.UI:RefreshBars() end)
    movingY = movingY - sliderHeight
    self.settingsControl.sliderIconSize = EMAHelperSettings:CreateSlider(self.settingsControl, headingWidth, left, movingY, "Icon Size")
    self.settingsControl.sliderIconSize:SetSliderValues(16, 64, 1)
    self.settingsControl.sliderIconSize:SetCallback("OnValueChanged", function(w, e, v) self.db.iconSize = tonumber(v); ns.UI:RefreshBars() end)
    movingY = movingY - sliderHeight
    self.settingsControl.sliderIconMargin = EMAHelperSettings:CreateSlider(self.settingsControl, headingWidth, left, movingY, "Icon Spacing")
    self.settingsControl.sliderIconMargin:SetSliderValues(0, 20, 1)
    self.settingsControl.sliderIconMargin:SetCallback("OnValueChanged", function(w, e, v) self.db.iconMargin = tonumber(v); ns.UI:RefreshBars() end)
    movingY = movingY - sliderHeight
    self.settingsControl.sliderBarMargin = EMAHelperSettings:CreateSlider(self.settingsControl, headingWidth, left, movingY, "Bar Spacing")
    self.settingsControl.sliderBarMargin:SetSliderValues(0, 50, 1)
    self.settingsControl.sliderBarMargin:SetCallback("OnValueChanged", function(w, e, v) self.db.barMargin = tonumber(v); ns.UI:RefreshBars() end)
    movingY = movingY - sliderHeight
    self.settingsControl.checkBoxShowTimers = EMAHelperSettings:CreateCheckBox(self.settingsControl, headingWidth, left, movingY, "Show Timer Text (Disable if using OmniCC/ElvUI)", function(w, e, v) 
        self.db.showTimers = v
        self:SettingsRefresh()
        ns.UI:RefreshBars() 
    end)
    movingY = movingY - checkBoxHeight
    self.settingsControl.sliderTimerFontSize = EMAHelperSettings:CreateSlider(self.settingsControl, headingWidth, left, movingY, "Timer Font Size")
    self.settingsControl.sliderTimerFontSize:SetSliderValues(6, 32, 1)
    self.settingsControl.sliderTimerFontSize:SetCallback("OnValueChanged", function(w, e, v) self.db.timerFontSize = tonumber(v); ns.UI:RefreshBars() end)
    movingY = movingY - sliderHeight
    self.settingsControl.colorTimer = EMAHelperSettings:CreateColourPicker(self.settingsControl, headingWidth, left, movingY, "Timer Color")
    self.settingsControl.colorTimer:SetCallback("OnValueChanged", function(w, e, r, g, b, a) self.db.timerColorR, self.db.timerColorG, self.db.timerColorB = r, g, b; ns.UI:RefreshBars() end)
    movingY = movingY - 30
    EMAHelperSettings:CreateHeading(self.settingsControl, "Colors", movingY, false)
    movingY = movingY - headingHeight
    self.settingsControl.colorBackground = EMAHelperSettings:CreateColourPicker(self.settingsControl, headingWidth, left, movingY, "Background Color")
    self.settingsControl.colorBackground:SetCallback("OnValueChanged", function(w, e, r, g, b, a) self.db.frameBackgroundColourR, self.db.frameBackgroundColourG, self.db.frameBackgroundColourB, self.db.frameBackgroundColourA = r, g, b, a; ns.UI:RefreshBars() end)
    movingY = movingY - 30
    self.settingsControl.colorBorder = EMAHelperSettings:CreateColourPicker(self.settingsControl, headingWidth, left, movingY, "Border Color")
    self.settingsControl.colorBorder:SetCallback("OnValueChanged", function(w, e, r, g, b, a) self.db.frameBorderColourR, self.db.frameBorderColourG, self.db.frameBorderColourB, self.db.frameBorderColourA = r, g, b, a; ns.UI:RefreshBars() end)
    movingTop = movingY - 30

    EMAHelperSettings:CreateHeading(self.settingsControl, "Totem Type Sequence", movingTop, false)
    movingTop = movingTop - headingHeight
    
    self.settingsControl.buttonSetKeybind = EMAHelperSettings:CreateButton(self.settingsControl, headingWidth, left, movingTop, "Set Cast Totem Sequence Keybind", function()
        self.waitingForKey = true
        self.settingsControl.buttonSetKeybind:SetText("Press any key...")
    end)
    movingTop = movingTop - 30
    
    self.settingsControl.sequenceList = {
        listFrameName = "EMATotemsSettingsSequenceListFrame",
        parentFrame = self.settingsControl.widgetSettings.content,
        listTop = movingTop,
        listLeft = left,
        listWidth = headingWidth,
        rowHeight = 25, rowsToDisplay = 5, columnsToDisplay = 2,
        columnInformation = {{ width = 30, alignment = "LEFT" }, { width = 70, alignment = "LEFT" }},
        scrollRefreshCallback = function() self:SettingsSequenceListScrollRefresh() end,
        rowClickCallback = function(obj, rowNumber, columnNumber) self:SettingsSequenceListRowClick(rowNumber, columnNumber) end
    }
    EMAHelperSettings:CreateScrollList(self.settingsControl.sequenceList)
    movingTop = movingTop - self.settingsControl.sequenceList.listHeight - verticalSpacing
    self.settingsControl.editBoxSelectedShaman = EMAHelperSettings:CreateEditBox(self.settingsControl, headingWidth, left, movingTop, "Edit Sequence for Selected Shaman")
    self.settingsControl.editBoxSelectedShaman:SetCallback("OnEnterPressed", function(w, e, v)
        if self.selectedShamanName then
            self.db.castSequences[self.selectedShamanName] = v
            self:SettingsSequenceListScrollRefresh()
            self:UpdateMacros()
        end
    end)
    movingTop = movingTop - EMAHelperSettings:GetEditBoxHeight()

    self:EMAModuleInitialize(self.settingsControl.widgetSettings.frame)
    self.settingsControl.widgetSettings.content:SetHeight(-movingTop + 20)
    
    -- Keyboard listener for direct binding
    local keyListener = CreateFrame("Frame", nil, self.settingsControl.widgetSettings.frame)
    keyListener:SetPropagateKeyboardInput(true)
    keyListener:SetScript("OnKeyDown", function(sf, key)
        if self.waitingForKey then
            if key ~= "ESCAPE" then
                self.db.sequenceKeybind = key
                self:UPDATE_BINDINGS()
                self:Print("Keybind set to: " .. key)
            end
            self.waitingForKey = false
            self:SettingsRefresh()
        end
    end)
end

function EMA_Totems:GetSequenceForShaman(name)
    return self.db.castSequences[name] or "Fire, Air, Water, Earth"
end

function EMA_Totems:SettingsSequenceListScrollRefresh()
    local shamans = {}
    for index, characterName in EMAApi.TeamListOrdered() do
        local class, _ = EMAApi.GetClass(characterName)
        local unit = Ambiguate(characterName, "none")
        local isShaman = (class == "shaman") or (self.shamanMembers[characterName] == true) or (self.db.selectedTotems[characterName] ~= nil)
        if isShaman then table.insert(shamans, characterName) end
    end
    FauxScrollFrame_Update(self.settingsControl.sequenceList.listScrollFrame, #shamans, self.settingsControl.sequenceList.rowsToDisplay, self.settingsControl.sequenceList.rowHeight)
    local offset = FauxScrollFrame_GetOffset(self.settingsControl.sequenceList.listScrollFrame)
    for i = 1, self.settingsControl.sequenceList.rowsToDisplay do
        local row = self.settingsControl.sequenceList.rows[i]
        local dataIndex = i + offset
        if dataIndex <= #shamans then
            local name = shamans[dataIndex]
            row.columns[1].textString:SetText(Ambiguate(name, "short"))
            row.columns[2].textString:SetText(self.db.castSequences[name] or "Fire, Air, Water, Earth")
            row.shamanName = name
            row.highlight:SetColorTexture(1.0, 1.0, 0.0, (name == self.selectedShamanName) and 0.5 or 0.0)
            row:Show()
        else
            row:Hide()
        end
    end
end

function EMA_Totems:SettingsSequenceListRowClick(rowNumber, columnNumber)
    if self.db.onlyTimers then return end
    local shamans = {}
    for index, characterName in EMAApi.TeamListOrdered() do
        local class, _ = EMAApi.GetClass(characterName)
        if class == "shaman" or self.shamanMembers[characterName] or self.db.selectedTotems[characterName] then
            table.insert(shamans, characterName)
        end
    end
    local offset = FauxScrollFrame_GetOffset(self.settingsControl.sequenceList.listScrollFrame)
    local dataIndex = rowNumber + offset
    if dataIndex <= #shamans then
        self.selectedShamanName = shamans[dataIndex]
        self.settingsControl.editBoxSelectedShaman:SetText(self.db.castSequences[self.selectedShamanName] or "Fire, Air, Water, Earth")
        self:SettingsSequenceListScrollRefresh()
    end
end

function EMA_Totems:SettingsRefresh()
    if self.settingsControl then
        local onlyTimers = self.db.onlyTimers
        local showTimers = self.db.showTimers
        
        self.settingsControl.checkBoxShowBars:SetValue(self.db.showBars)
        self.settingsControl.checkBoxOnlyTimers:SetValue(onlyTimers)
        self.settingsControl.checkBoxSpamMacro:SetValue(self.db.useSpamMacro)
        self.settingsControl.checkBoxSpamMacro:SetDisabled(onlyTimers)
        self.settingsControl.checkBoxLockBars:SetValue(self.db.lockBars)
        self.settingsControl.checkBoxShowNames:SetValue(self.db.showNames)
        self.settingsControl.sliderScale:SetValue(self.db.barScale)
        self.settingsControl.sliderAlpha:SetValue(self.db.barAlpha)
        self.settingsControl.dropdownOrder:SetValue(self.db.barOrder)
        self.settingsControl.dropdownBorder:SetValue(self.db.borderStyle)
        self.settingsControl.dropdownBackground:SetValue(self.db.backgroundStyle)
        self.settingsControl.dropdownFont:SetValue(self.db.fontStyle)
        self.settingsControl.sliderFontSize:SetValue(self.db.fontSize)
        self.settingsControl.sliderIconSize:SetValue(self.db.iconSize)
        self.settingsControl.sliderIconMargin:SetValue(self.db.iconMargin)
        self.settingsControl.sliderBarMargin:SetValue(self.db.barMargin)
        self.settingsControl.checkBoxShowTimers:SetValue(showTimers)
        
        self.settingsControl.sliderTimerFontSize:SetValue(self.db.timerFontSize)
        self.settingsControl.sliderTimerFontSize:SetDisabled(not showTimers)
        self.settingsControl.colorTimer:SetColor(self.db.timerColorR or 1, self.db.timerColorG or 1, self.db.timerColorB or 1, 1.0)
        self.settingsControl.colorTimer:SetDisabled(not showTimers)
        
        self.settingsControl.buttonSetKeybind:SetDisabled(onlyTimers)
        self.settingsControl.buttonSetKeybind:SetText(self.db.sequenceKeybind ~= "" and "Keybind: " .. self.db.sequenceKeybind or "Set Cast Totem Sequence Keybind")
        self.settingsControl.editBoxSelectedShaman:SetDisabled(onlyTimers)
        
        self.settingsControl.colorBackground:SetColor(self.db.frameBackgroundColourR or 1, self.db.frameBackgroundColourG or 1, self.db.frameBackgroundColourB or 1, self.db.frameBackgroundColourA or 1)
        self.settingsControl.colorBorder:SetColor(self.db.frameBorderColourR or 1, self.db.frameBorderColourG or 1, self.db.frameBorderColourB or 1, self.db.frameBorderColourA or 1)
        self:SettingsSequenceListScrollRefresh()
    end
end

function EMA_Totems:OnEMAProfileChanged() self:SettingsRefresh(); ns.UI:RefreshBars() end
function EMA_Totems:BeforeEMAProfileChanged() end
