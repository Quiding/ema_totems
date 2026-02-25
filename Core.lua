local addonName, ns = ...
-- Official EMA Module initialization
local EMA_Totems = LibStub("AceAddon-3.0"):NewAddon("EMA_Totems", "Module-1.0", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
ns.EMA_Totems = EMA_Totems
EMA_Totems.ns = ns

EMA_Totems.moduleName = "EMA_Totems"
EMA_Totems.settingsDatabaseName = "EMA_TotemsProfileDB"
EMA_Totems.chatCommand = "ema-totems"

-- REQUIRED: GetConfiguration for EMA core
function EMA_Totems:GetConfiguration()
    return {
        name = "Totems", handler = self, type = 'group',
        args = {
            showBars = { type = "toggle", name = "Show Totem Bars", get = "EMAConfigurationGetSetting", set = "EMAConfigurationSetSetting" },
        },
    }
end

-- Initialize runtime tables
EMA_Totems.shamanMembers = {}
EMA_Totems.activeTotems = {}
EMA_Totems.lastUsedTotems = {}

local L = LibStub("AceLocale-3.0"):GetLocale("Core")
local EMAUtilities = LibStub:GetLibrary("EbonyUtilities-1.0")

EMA_Totems.parentDisplayName = "Class"
EMA_Totems.moduleDisplayName = "Totems"
EMA_Totems.moduleIcon = "Interface\\AddOns\\EMA\\Media\\SettingsIcon.tga"
EMA_Totems.moduleOrder = 80

_G["BINDING_HEADER_EMATOTEMS"] = "EMA Totems"
_G["BINDING_NAME_EMATOTEMSSEQUENCE"] = "EMA: Cast Totem Sequence"

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

EMA_Totems.settings = {
    profile = {
        showBars = true,
        onlyTimers = false,
        useSpamMacro = false,
        barScale = 1.0,
        barAlpha = 1.0,
        lockBars = false,
        barOrder = "RoleAsc",
        showNames = true,
        barLayout = "Horizontal",
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
        breakUpBars = false,
        individualBarPositions = {},
        selectedTotems = {},
        castSequences = {},
        teamBarsPos = { point = "CENTER", x = 0, y = 0 },
        sequenceKeybind = "",
        presets = {},
        frameBackgroundColourR = 0.1, frameBackgroundColourG = 0.1, frameBackgroundColourB = 0.1, frameBackgroundColourA = 0.7,
        frameBorderColourR = 0.5, frameBorderColourG = 0.5, frameBorderColourB = 0.5, frameBorderColourA = 1.0,
    }
}

local function PatchSharedMediaWidgets()
    local EMAHelperSettings = LibStub:GetLibrary("EMAHelperSettings-1.0", true)
    if not EMAHelperSettings or EMAHelperSettings.EMAPatchedV5 then return end

    local function FixLayout(widget)
        if not widget or not widget.frame then return end
        local frame = widget.frame
        
        -- Force widget height
        widget:SetHeight(85)
        frame:SetHeight(85)
        
        if frame.label then
            frame.label:ClearAllPoints()
            frame.label:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
            frame.label:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
            frame.label:SetJustifyH("LEFT")
            frame.label:SetHeight(20)
        end

        if frame.displayButton then
            frame.displayButton:ClearAllPoints()
            -- Position texture preview square below the label
            frame.displayButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -25)
            frame.displayButton:SetSize(42, 42)
            
            if frame.DLeft then
                frame.DLeft:ClearAllPoints()
                -- Anchor dropdown box to the right of the texture preview with a 10px gap
                frame.DLeft:SetPoint("LEFT", frame.displayButton, "RIGHT", 10, 0)
                
                if frame.DRight then
                    frame.DRight:ClearAllPoints()
                    frame.DRight:SetPoint("TOP", frame.DLeft, "TOP")
                    frame.DRight:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
                end
                
                if frame.DMiddle then
                    frame.DMiddle:ClearAllPoints()
                    frame.DMiddle:SetPoint("TOP", frame.DLeft, "TOP")
                    frame.DMiddle:SetPoint("LEFT", frame.DLeft, "RIGHT")
                    frame.DMiddle:SetPoint("RIGHT", frame.DRight, "LEFT")
                end

                if frame.text then
                    frame.text:ClearAllPoints()
                    frame.text:SetPoint("LEFT", frame.DLeft, "LEFT", 26, 1)
                    frame.text:SetPoint("RIGHT", frame.DRight, "RIGHT", -43, 1)
                    frame.text:SetJustifyH("RIGHT")
                end

                if frame.dropButton then
                    frame.dropButton:ClearAllPoints()
                    frame.dropButton:SetPoint("TOPRIGHT", frame.DRight, "TOPRIGHT", -16, -18)
                    
                    -- Create or update the clickable overlay for the entire bar
                    if not frame.clickableOverlay then
                        frame.clickableOverlay = CreateFrame("Button", nil, frame)
                        frame.clickableOverlay:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
                        frame.clickableOverlay:SetScript("OnClick", function()
                            if frame.dropButton then
                                frame.dropButton:Click()
                            end
                        end)
                    end
                    frame.clickableOverlay:ClearAllPoints()
                    frame.clickableOverlay:SetPoint("TOPLEFT", frame.DLeft, "TOPLEFT", 15, -15)
                    frame.clickableOverlay:SetPoint("BOTTOMRIGHT", frame.DRight, "BOTTOMRIGHT", -15, 15)
                end
            end
        end
    end

    local function UpdateSliderText(w)
        if not w or not w.editbox or not w.value then return end
        local value = w.value
        if w.ispercent then
            w.editbox:SetText(("%s%%"):format(math.floor(value * 1000 + 0.5) / 10))
        else
            w.editbox:SetText(math.floor(value * 100 + 0.5) / 100)
        end
    end

    local AceGUI = LibStub("AceGUI-3.0", true)
    if AceGUI then
        local oldAcquire = AceGUI.Acquire
        AceGUI.Acquire = function(self, type)
            local widget = oldAcquire(self, type)
            if not widget then return widget end
            
            if widget.frame and type and type:find("^LSM30_") then
                widget.alignoffset = 0
                FixLayout(widget)
                if not widget.EMAPatchedHookV4 then
                    hooksecurefunc(widget, "SetLabel", function() FixLayout(widget) end)
                    hooksecurefunc(widget, "SetWidth", function() FixLayout(widget) end)
                    widget.EMAPatchedHookV4 = true
                end
            end
            
            if type == "Slider" and not widget.EMASliderPatched then
                hooksecurefunc(widget, "SetValue", function(w) UpdateSliderText(w) end)
                widget.frame:HookScript("OnShow", function() UpdateSliderText(widget) end)
                widget.EMASliderPatched = true
            end
            
            return widget
        end
    end

    local methods = {"CreateMediaStatus", "CreateMediaBorder", "CreateMediaBackground", "CreateMediaFont", "CreateMediaSound"}
    for _, m in ipairs(methods) do
        local old = EMAHelperSettings[m]
        if old then
            EMAHelperSettings[m] = function(self, ...)
                local w = old(self, ...)
                if w then
                    FixLayout(w)
                    C_Timer.After(0.01, function() FixLayout(w) end)
                end
                return w
            end
        end
    end
    EMAHelperSettings.EMAPatchedV5 = true
end

function EMA_Totems:OnInitialize()
    PatchSharedMediaWidgets()
    self:SettingsCreate()
    self:RegisterChatCommand("et", "ChatCommand")
    self:RegisterChatCommand("ema-totems", "ChatCommand")
end

function EMA_Totems:UpdateTotemForShaman(shamanName, slot, totemID)
    local myName = self.characterName
    if shamanName == myName then
        if not self.db.selectedTotems[myName] then self.db.selectedTotems[myName] = {} end
        self.db.selectedTotems[myName][slot] = totemID
        ns.UI:UpdateMyBar()
        self:PushSettingsToTeam()
    else
        self:EMASendCommandToToon(shamanName, "EMATotemsUpdate", slot, totemID)
    end
end

function EMA_Totems:ChatCommand(input)
    local cmd = input and input:trim():lower() or ""
    if cmd == "config" then self:EMAChatCommand("config")
    elseif cmd == "refresh" then ns.UI:RefreshBars()
    elseif cmd == "show" then self.db.showBars = true; ns.UI:RefreshBars()
    elseif cmd == "hide" then self.db.showBars = false; ns.UI:RefreshBars()
    elseif cmd == "test" then self:TestTotems()
    else self:Print("Usage: /et config, /et refresh, /et show, /et hide, /et test") end
end

function EMA_Totems:TestTotems()
    local currentTime = GetTime()
    for index, characterName in EMAApi.TeamListOrdered() do
        local isOnline = EMAApi.GetCharacterOnlineStatus(characterName)
        if (isOnline == true or characterName == self.characterName) then
            local class, _ = EMAApi.GetClass(characterName)
            local unit = Ambiguate(characterName, "none")
            local isShaman = (class and class:lower() == "shaman") or (self.shamanMembers[characterName] == true)
            if characterName == self.characterName then
                local _, myClass = UnitClass("player")
                if myClass == "SHAMAN" then isShaman = true end
            end
            
            if isShaman then
                local sender = Ambiguate(characterName, "none")
                self.activeTotems[sender] = self.activeTotems[sender] or {}
                local slots = {"Fire", "Air", "Water", "Earth"}
                for _, slot in ipairs(slots) do
                    self.activeTotems[sender][slot] = { name = "Test Totem", startTime = currentTime, duration = 10, icon = 134400 }
                end
            end
        end
    end
    self:Print("Started 10s Test on all totem slots.")
    if ns.UI then ns.UI:RefreshBars() end
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
    if ns.UI then 
        ns.UI:Initialize() 
        ns.UI:RefreshBars()
        -- Force multiple refreshes during the first 30 seconds of login
        self:ScheduleRepeatingTimer(function()
            if ns.UI then ns.UI:RefreshBars() end
        end, 2.0, 15) -- 15 times every 2 seconds = 30 seconds
    end
end

function EMA_Totems:UPDATE_BINDINGS()
    if InCombatLockdown() then return end
    ClearOverrideBindings(self.keyBindingFrame)
    local directKey = self.db.sequenceKeybind
    if directKey and directKey ~= "" then SetOverrideBindingClick(self.keyBindingFrame, false, directKey, "EMATotemsSequenceButton") end
    local n1, n2 = GetBindingKey("EMATOTEMSSEQUENCE")
    if n1 then SetOverrideBindingClick(self.keyBindingFrame, false, n1, "EMATotemsSequenceButton") end
    if n2 then SetOverrideBindingClick(self.keyBindingFrame, false, n2, "EMATotemsSequenceButton") end
end

function EMA_Totems:DoInitialReport()
    local _, class = UnitClass("player")
    if class == "SHAMAN" then self:EMASendCommandToMaster("EMATotemsReportClass", true) end
end

function EMA_Totems:PLAYER_LOGIN() if ns.UI then ns.UI:RefreshBars() end end

function EMA_Totems:PLAYER_TOTEM_UPDATE()
    if ns.UI then ns.UI:UpdateTimers() end
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
                self.activeTotems[sender][data.element] = { name = spellName, startTime = GetTime(), duration = data.duration, icon = icon }
                self.lastUsedTotems[sender] = self.lastUsedTotems[sender] or {}
                self.lastUsedTotems[sender][data.element] = { name = spellName, icon = icon }
                if ns.UI then ns.UI:UpdateTimers() end
            elseif spellName == "Totemic Call" or spellName == "Totemic Recall" then
                local sender = Ambiguate(characterName, "none")
                self.activeTotems[sender] = {}
                if ns.UI then ns.UI:UpdateTimers() end
            end
        end
    end
    if event == "UNIT_DIED" then
        local unit = Ambiguate(destName, "none")
        if self.activeTotems[unit] then self.activeTotems[unit] = {}; if ns.UI then ns.UI:UpdateTimers() end end
    end
end

function EMA_Totems:PushSettingsToTeam() self:EMASendSettings(); self:EMASendCommandToTeam("EMATotemsPushAll") end

-- REQUIRED BY EMA CORE FOR SYNC
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

function EMA_Totems:EMAOnCommandReceived(characterName, commandName, ...)
    if commandName == "EMATotemsUpdate" then
        local slot, totemName = ...
        local myName = self.characterName
        if not self.db.selectedTotems[myName] then self.db.selectedTotems[myName] = {} end
        self.db.selectedTotems[myName][slot] = totemName
        ns.UI:UpdateMyBar()
    elseif commandName == "EMATotemsReportClass" then
        local isShaman = ...
        if isShaman then self.shamanMembers[characterName] = true end
        ns.UI:RefreshBars()
    elseif commandName == "EMATotemsPushAll" then ns.UI:RefreshBars() end
end

function EMA_Totems:BeforeEMAProfileChanged() end
function EMA_Totems:OnEMAProfileChanged() self:SettingsRefresh(); ns.UI:RefreshBars() end

function EMA_Totems:PLAYER_REGEN_ENABLED() ns.UI:UpdateMacros(); self:UPDATE_BINDINGS() end

function EMA_Totems:SettingsCreate()
    self.settingsControl = {}
    self.settingsControlClass = {}
    local EMAHelperSettings = LibStub("EMAHelperSettings-1.0")
    EMAHelperSettings:CreateSettings(self.settingsControlClass, "Class", "Class", function() self:PushSettingsToTeam() end, "Interface\\AddOns\\EMA\\Media\\TeamCore.tga", 5)
    EMAHelperSettings:CreateSettings(self.settingsControl, "Totems", "Class", function() self:PushSettingsToTeam() end, "Interface\\AddOns\\EMA\\Media\\SettingsIcon.tga", 80)
    
    local top, left = EMAHelperSettings:TopOfSettings(), EMAHelperSettings:LeftOfSettings()
    local headingHeight, headingWidth = EMAHelperSettings:HeadingHeight(), EMAHelperSettings:HeadingWidth(true)
    local checkBoxHeight, sliderHeight = EMAHelperSettings:GetCheckBoxHeight(), EMAHelperSettings:GetSliderHeight()
    local dropdownHeight, verticalSpacing = EMAHelperSettings:GetDropdownHeight(), EMAHelperSettings:GetVerticalSpacing()
    local movingTop = top
    local halfWidth = headingWidth / 2
    
    EMAHelperSettings:CreateHeading(self.settingsControl, "General Options", movingTop, false)
    movingTop = movingTop - headingHeight
    self.settingsControl.checkBoxShowBars = EMAHelperSettings:CreateCheckBox(self.settingsControl, headingWidth, left, movingTop, "Show Totem Bars", function(w, e, v) self.db.showBars = v; ns.UI:RefreshBars(); self:SettingsRefresh() end)
    movingTop = movingTop - checkBoxHeight
    self.settingsControl.checkBoxLockBars = EMAHelperSettings:CreateCheckBox(self.settingsControl, headingWidth, left, movingTop, "Lock Bars", function(w, e, v) self.db.lockBars = v; ns.UI:RefreshBars(); self:SettingsRefresh() end)
    movingTop = movingTop - checkBoxHeight
    self.settingsControl.checkBoxShowNames = EMAHelperSettings:CreateCheckBox(self.settingsControl, headingWidth, left, movingTop, "Show Character Names", function(w, e, v) self.db.showNames = v; ns.UI:RefreshBars(); self:SettingsRefresh() end)
    movingTop = movingTop - checkBoxHeight
    self.settingsControl.checkBoxBreakUpBars = EMAHelperSettings:CreateCheckBox(self.settingsControl, headingWidth, left, movingTop, "Ungrouped Bars (Independent Movement)", function(w, e, v) self.db.breakUpBars = v; ns.UI:RefreshBars(); self:SettingsRefresh() end)
    movingTop = movingTop - checkBoxHeight
    self.settingsControl.dropdownLayout = EMAHelperSettings:CreateDropdown(self.settingsControl, 450, left, movingTop, "Bar Orientation")
    self.settingsControl.dropdownLayout:SetList({ ["Horizontal"] = "Horizontal (Icons in a row)", ["Vertical"] = "Vertical (Icons in a column)" })
    self.settingsControl.dropdownLayout:SetCallback("OnValueChanged", function(w, e, v) self.db.barLayout = v; ns.UI:RefreshBars(); self:SettingsRefresh() end)
    movingTop = movingTop - dropdownHeight - verticalSpacing
    self.settingsControl.buttonResetPositions = EMAHelperSettings:CreateButton(self.settingsControl, headingWidth, left, movingTop, "Reset All Independent Bar Positions", function() 
        self.db.individualBarPositions = {}
        if ns.UI and ns.UI.teamBars then
            for characterName, bar in pairs(ns.UI.teamBars) do
                local charKey = Ambiguate(characterName, "none"):lower()
                self.db.individualBarPositions[charKey] = { point = "CENTER", relativePoint = "CENTER", x = 0, y = 0 }
                bar:ClearAllPoints()
                bar:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
            end
        end
        ns.UI:RefreshBars()
        self:Print("Independent bar positions reset to center.") 
    end)
    movingTop = movingTop - 30
    self.settingsControl.checkBoxOnlyTimers = EMAHelperSettings:CreateCheckBox(self.settingsControl, headingWidth, left, movingTop, "Only Timers Mode (Passive)", function(w, e, v) self.db.onlyTimers = v; ns.UI:RefreshBars(); self:SettingsRefresh() end)
    movingTop = movingTop - checkBoxHeight
    self.settingsControl.checkBoxSpamMacro = EMAHelperSettings:CreateCheckBox(self.settingsControl, headingWidth, left, movingTop, "Use Spam-safe Sequence (,null)", function(w, e, v) self.db.useSpamMacro = v; self:UpdateMacros(); self:SettingsRefresh() end)
    movingTop = movingTop - checkBoxHeight
    self.settingsControl.dropdownOrder = EMAHelperSettings:CreateDropdown(self.settingsControl, 450, left, movingTop, "Bar Order")
    self.settingsControl.dropdownOrder:SetList({ ["NameAsc"] = "Name (Asc)", ["NameDesc"] = "Name (Desc)", ["EMAPosition"] = "EMA Team Order", ["RoleAsc"] = "Role (Tank > Healer > DPS)" })
    self.settingsControl.dropdownOrder:SetCallback("OnValueChanged", function(w, e, v) self.db.barOrder = v; ns.UI:RefreshBars(); self:SettingsRefresh() end)
    movingTop = movingTop - dropdownHeight - verticalSpacing
    self.settingsControl.sliderScale = EMAHelperSettings:CreateSlider(self.settingsControl, headingWidth, left, movingTop, "Overall Scale")
    self.settingsControl.sliderScale:SetSliderValues(0.5, 2.0, 0.01)
    self.settingsControl.sliderScale:SetCallback("OnValueChanged", function(w, e, v) self.db.barScale = tonumber(v); ns.UI:RefreshBars(); self:SettingsRefresh() end)
    movingTop = movingTop - sliderHeight
    self.settingsControl.sliderAlpha = EMAHelperSettings:CreateSlider(self.settingsControl, headingWidth, left, movingTop, "Overall Alpha")
    self.settingsControl.sliderAlpha:SetSliderValues(0.0, 1.0, 0.01)
    self.settingsControl.sliderAlpha:SetCallback("OnValueChanged", function(w, e, v) self.db.barAlpha = tonumber(v); ns.UI:RefreshBars(); self:SettingsRefresh() end)
    movingTop = movingTop - sliderHeight
    self.settingsControl.buttonRefreshTeam = EMAHelperSettings:CreateButton(self.settingsControl, headingWidth, left, movingTop, "Refresh Team Members", function() ns.UI:RefreshBars(); self:SettingsRefresh() end)
    movingTop = movingTop - 30

    EMAHelperSettings:CreateHeading(self.settingsControl, "Appearance: Whole UI Frame", movingTop, false)
    movingTop = movingTop - headingHeight
    self.settingsControl.dropdownBorder = EMAHelperSettings:CreateMediaBorder(self.settingsControl, 450, left, movingTop, "UI Border Style")
    self.settingsControl.dropdownBorder:SetCallback("OnValueChanged", function(w, e, v) self.db.borderStyle = v; ns.UI:RefreshBars(); self:SettingsRefresh() end)
    movingTop = movingTop - 85
    self.settingsControl.dropdownBackground = EMAHelperSettings:CreateMediaBackground(self.settingsControl, 450, left, movingTop, "UI Background Style")
    self.settingsControl.dropdownBackground:SetCallback("OnValueChanged", function(w, e, v) self.db.backgroundStyle = v; ns.UI:RefreshBars(); self:SettingsRefresh() end)
    movingTop = movingTop - 85
    self.settingsControl.colorBackground = EMAHelperSettings:CreateColourPicker(self.settingsControl, 450, left, movingTop, "UI Background Color")
    self.settingsControl.colorBackground:SetCallback("OnValueChanged", function(w, e, r, g, b, a) self.db.frameBackgroundColourR, self.db.frameBackgroundColourG, self.db.frameBackgroundColourB, self.db.frameBackgroundColourA = r, g, b, a; ns.UI:RefreshBars(); self:SettingsRefresh() end)
    movingTop = movingTop - 30
    self.settingsControl.colorBorder = EMAHelperSettings:CreateColourPicker(self.settingsControl, 450, left, movingTop, "UI Border Color")
    self.settingsControl.colorBorder:SetCallback("OnValueChanged", function(w, e, r, g, b, a) self.db.frameBorderColourR, self.db.frameBorderColourG, self.db.frameBorderColourB, self.db.frameBorderColourA = r, g, b, a; ns.UI:RefreshBars(); self:SettingsRefresh() end)
    movingTop = movingTop - 30

    EMAHelperSettings:CreateHeading(self.settingsControl, "Sizing & Spacing", movingTop, false)
    movingTop = movingTop - headingHeight
    self.settingsControl.sliderIconSize = EMAHelperSettings:CreateSlider(self.settingsControl, headingWidth, left, movingTop, "Icon Size")
    self.settingsControl.sliderIconSize:SetSliderValues(16, 64, 1)
    self.settingsControl.sliderIconSize:SetCallback("OnValueChanged", function(w, e, v) self.db.iconSize = tonumber(v); ns.UI:RefreshBars(); self:SettingsRefresh() end)
    movingTop = movingTop - sliderHeight
    self.settingsControl.sliderIconMargin = EMAHelperSettings:CreateSlider(self.settingsControl, headingWidth, left, movingTop, "Icon Spacing")
    self.settingsControl.sliderIconMargin:SetSliderValues(0, 20, 1)
    self.settingsControl.sliderIconMargin:SetCallback("OnValueChanged", function(w, e, v) self.db.iconMargin = tonumber(v); ns.UI:RefreshBars(); self:SettingsRefresh() end)
    movingTop = movingTop - sliderHeight
    self.settingsControl.sliderBarMargin = EMAHelperSettings:CreateSlider(self.settingsControl, headingWidth, left, movingTop, "Bar Spacing")
    self.settingsControl.sliderBarMargin:SetSliderValues(0, 50, 1)
    self.settingsControl.sliderBarMargin:SetCallback("OnValueChanged", function(w, e, v) self.db.barMargin = tonumber(v); ns.UI:RefreshBars(); self:SettingsRefresh() end)
    movingTop = movingTop - sliderHeight

    EMAHelperSettings:CreateHeading(self.settingsControl, "Text & Timers", movingTop, false)
    movingTop = movingTop - headingHeight
    self.settingsControl.dropdownFont = EMAHelperSettings:CreateMediaFont(self.settingsControl, 450, left, movingTop, "Font Style")
    self.settingsControl.dropdownFont:SetCallback("OnValueChanged", function(w, e, v) self.db.fontStyle = v; ns.UI:RefreshBars(); self:SettingsRefresh() end)
    movingTop = movingTop - 85
    self.settingsControl.sliderFontSize = EMAHelperSettings:CreateSlider(self.settingsControl, headingWidth, left, movingTop, "Name Font Size")
    self.settingsControl.sliderFontSize:SetSliderValues(6, 24, 1)
    self.settingsControl.sliderFontSize:SetCallback("OnValueChanged", function(w, e, v) self.db.fontSize = tonumber(v); ns.UI:RefreshBars(); self:SettingsRefresh() end)
    movingTop = movingTop - sliderHeight
    self.settingsControl.checkBoxShowTimers = EMAHelperSettings:CreateCheckBox(self.settingsControl, headingWidth, left, movingTop, "Show Timer Text (Disable if using OmniCC/ElvUI)", function(w, e, v) self.db.showTimers = v; self:SettingsRefresh(); ns.UI:RefreshBars() end)
    movingTop = movingTop - checkBoxHeight
    self.settingsControl.sliderTimerFontSize = EMAHelperSettings:CreateSlider(self.settingsControl, headingWidth, left, movingTop, "Timer Font Size")
    self.settingsControl.sliderTimerFontSize:SetSliderValues(6, 32, 1)
    self.settingsControl.sliderTimerFontSize:SetCallback("OnValueChanged", function(w, e, v) self.db.timerFontSize = tonumber(v); ns.UI:RefreshBars(); self:SettingsRefresh() end)
    movingTop = movingTop - sliderHeight
    self.settingsControl.colorTimer = EMAHelperSettings:CreateColourPicker(self.settingsControl, 450, left, movingTop, "Timer Color")
    self.settingsControl.colorTimer:SetCallback("OnValueChanged", function(w, e, r, g, b, a) self.db.timerColorR, self.db.timerColorG, self.db.timerColorB = r, g, b; ns.UI:RefreshBars(); self:SettingsRefresh() end)
    movingTop = movingTop - 30

    EMAHelperSettings:CreateHeading(self.settingsControl, "Totem Type Sequence", movingTop, false)
    movingTop = movingTop - headingHeight
    self.settingsControl.buttonSetKeybind = EMAHelperSettings:CreateButton(self.settingsControl, headingWidth, left, movingTop, "Set Cast Totem Sequence Keybind", function() self.waitingForKey = true; self.settingsControl.buttonSetKeybind:SetText("Press any key..."); self:SettingsRefresh() end)
    movingTop = movingTop - 30
    
    self.settingsControl.sequenceList = {
        listFrameName = "EMATotemsSettingsSequenceListFrame", parentFrame = self.settingsControl.widgetSettings.content, listTop = movingTop, listLeft = left, listWidth = headingWidth, rowHeight = 25, rowsToDisplay = 5, columnsToDisplay = 2,
        columnInformation = {{ width = 30, alignment = "LEFT" }, { width = 70, alignment = "LEFT" }},
        scrollRefreshCallback = function() self:SettingsSequenceListScrollRefresh() end, rowClickCallback = function(obj, rowNumber, columnNumber) self:SettingsSequenceListRowClick(rowNumber, columnNumber) end
    }
    EMAHelperSettings:CreateScrollList(self.settingsControl.sequenceList)
    movingTop = movingTop - self.settingsControl.sequenceList.listHeight - verticalSpacing
    self.settingsControl.editBoxSelectedShaman = EMAHelperSettings:CreateEditBox(self.settingsControl, 450, left, movingTop, "Edit Sequence for Selected Shaman")
    self.settingsControl.editBoxSelectedShaman:SetCallback("OnEnterPressed", function(w, e, v) if self.selectedShamanName then self.db.castSequences[self.selectedShamanName] = v; self:SettingsSequenceListScrollRefresh(); self:UpdateMacros(); self:SettingsRefresh() end end)
    movingTop = movingTop - EMAHelperSettings:GetEditBoxHeight()

    self:EMAModuleInitialize(self.settingsControl.widgetSettings.frame)
    self:PresetsSettingsCreate()
    self:SettingsRefresh()
    self.settingsControl.widgetSettings.content:SetHeight(-movingTop + 20)
    
    local keyListener = CreateFrame("Frame", nil, self.settingsControl.widgetSettings.frame)
    keyListener:SetPropagateKeyboardInput(true)
    keyListener:SetScript("OnKeyDown", function(sf, key) if self.waitingForKey then if key ~= "ESCAPE" then self.db.sequenceKeybind = key; self:UPDATE_BINDINGS(); self:Print("Keybind set to: " .. key) end; self.waitingForKey = false; self:SettingsRefresh() end end)
end

function EMA_Totems:GetSequenceForShaman(name) return self.db.castSequences[name] or "Fire, Air, Water, Earth" end

function EMA_Totems:SettingsSequenceListScrollRefresh()
    local shamans = {}
    for index, characterName in EMAApi.TeamListOrdered() do
        local class, _ = EMAApi.GetClass(characterName)
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
        else row:Hide() end
    end
end

function EMA_Totems:SettingsSequenceListRowClick(rowNumber, columnNumber)
    if self.db.onlyTimers then return end
    local shamans = {}
    for index, characterName in EMAApi.TeamListOrdered() do
        local class, _ = EMAApi.GetClass(characterName)
        if class == "shaman" or self.shamanMembers[characterName] or self.db.selectedTotems[characterName] then table.insert(shamans, characterName) end
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
    if self.settingsControl and self.db then
        local db = self.db
        local onlyTimers = db.onlyTimers
        local showTimers = db.showTimers
        self.settingsControl.checkBoxShowBars:SetValue(db.showBars)
        self.settingsControl.checkBoxOnlyTimers:SetValue(onlyTimers)
        self.settingsControl.checkBoxSpamMacro:SetValue(db.useSpamMacro)
        self.settingsControl.checkBoxSpamMacro:SetDisabled(onlyTimers)
        self.settingsControl.checkBoxLockBars:SetValue(db.lockBars)
        self.settingsControl.checkBoxShowNames:SetValue(db.showNames)
        self.settingsControl.dropdownLayout:SetValue(db.barLayout or "Horizontal")
        self.settingsControl.checkBoxBreakUpBars:SetValue(db.breakUpBars)
        
        self.settingsControl.sliderScale:SetValue(db.barScale or 1.0)
        self.settingsControl.sliderAlpha:SetValue(db.barAlpha or 1.0)
        
        self.settingsControl.dropdownOrder:SetValue(db.barOrder or "RoleAsc")
        self.settingsControl.dropdownBorder:SetValue(db.borderStyle or "Blizzard Tooltip")
        self.settingsControl.dropdownBackground:SetValue(db.backgroundStyle or "Blizzard Dialog Background")
        self.settingsControl.dropdownFont:SetValue(db.fontStyle or "Arial Narrow")
        
        self.settingsControl.sliderFontSize:SetValue(db.fontSize or 12)
        self.settingsControl.sliderIconSize:SetValue(db.iconSize or 36)
        self.settingsControl.sliderIconMargin:SetValue(db.iconMargin or 4)
        self.settingsControl.sliderBarMargin:SetValue(db.barMargin or 4)
        
        self.settingsControl.checkBoxShowTimers:SetValue(showTimers)
        self.settingsControl.sliderTimerFontSize:SetValue(db.timerFontSize or 16)
        self.settingsControl.sliderTimerFontSize:SetDisabled(not showTimers)
        
        self.settingsControl.colorTimer:SetColor(db.timerColorR or 1, db.timerColorG or 1, db.timerColorB or 1, 1.0)
        self.settingsControl.colorTimer:SetDisabled(not showTimers)
        self.settingsControl.buttonSetKeybind:SetDisabled(onlyTimers)
        self.settingsControl.buttonSetKeybind:SetText(db.sequenceKeybind ~= "" and "Keybind: " .. db.sequenceKeybind or "Set Cast Totem Sequence Keybind")
        self.settingsControl.editBoxSelectedShaman:SetDisabled(onlyTimers)
        
        self.settingsControl.colorBackground:SetColor(db.frameBackgroundColourR or 1, db.frameBackgroundColourG or 1, db.frameBackgroundColourB or 1, db.frameBackgroundColourA or 1)
                self.settingsControl.colorBorder:SetColor(db.frameBorderColourR or 1, db.frameBorderColourG or 1, db.frameBorderColourB or 1, db.frameBorderColourA or 1)
                self:SettingsSequenceListScrollRefresh()
                self:SettingsPresetListScrollRefresh()
            end
        end

function EMA_Totems:OnEMAProfileChanged() self:SettingsRefresh(); ns.UI:RefreshBars() end
function EMA_Totems:BeforeEMAProfileChanged() end
