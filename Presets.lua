local addonName, ns = ...
local EMA_Totems = ns.EMA_Totems

-- -----------------------------------------------------------------------
-- PRESET LOGIC
-- -----------------------------------------------------------------------

function EMA_Totems:SavePreset(presetName)
    if not presetName or presetName == "" then 
        self:Print("Error: Please enter a preset name.")
        return 
    end
    
    local currentTotems = self.db.selectedTotems[self.characterName]
    if not currentTotems then 
        self:Print("Error: No totems currently selected to save. Set them on your bar first.")
        return 
    end
    
    self.db.presets[presetName] = {
        Fire = currentTotems.Fire,
        Air = currentTotems.Air,
        Water = currentTotems.Water,
        Earth = currentTotems.Earth,
    }
    self:Print("Preset saved: " .. presetName)
    self:SettingsRefresh()
end

function EMA_Totems:ApplyPreset(presetName)
    local preset = self.db.presets[presetName]
    if not preset then return end
    
    if not self.db.selectedTotems[self.characterName] then
        self.db.selectedTotems[self.characterName] = {}
    end
    
    local st = self.db.selectedTotems[self.characterName]
    st.Fire = preset.Fire
    st.Air = preset.Air
    st.Water = preset.Water
    st.Earth = preset.Earth
    
    -- Update UI and push to team
    if ns.UI then
        ns.UI:UpdateMyBar()
    end
    self:PushSettingsToTeam()
    self:Print("Preset applied: " .. presetName)
end

function EMA_Totems:DeletePreset(presetName)
    if self.db.presets[presetName] then
        self.db.presets[presetName] = nil
        self:Print("Preset deleted: " .. presetName)
        self:SettingsRefresh()
    end
end

-- -----------------------------------------------------------------------
-- PRESET SETTINGS UI
-- -----------------------------------------------------------------------

function EMA_Totems:PresetsSettingsCreate()
    self.settingsControlPresets = {}
    local EMAHelperSettings = LibStub("EMAHelperSettings-1.0")
    
    -- Create settings frames
    EMAHelperSettings:CreateSettings(self.settingsControlPresets, "Totem Presets", "Class", function() self:PushSettingsToTeam() end, "Interface\\AddOns\\EMA\\Media\\SettingsIcon.tga", 81)
    
    local top, left = EMAHelperSettings:TopOfSettings(), EMAHelperSettings:LeftOfSettings()
    local headingHeight, headingWidth = EMAHelperSettings:HeadingHeight(), EMAHelperSettings:HeadingWidth(true)
    local movingTop = top
    
    EMAHelperSettings:CreateHeading(self.settingsControlPresets, "Manage Totem Presets", movingTop, false)
    movingTop = movingTop - headingHeight
    
    -- Save Preset UI
    self.settingsControlPresets.editBoxPresetName = EMAHelperSettings:CreateEditBox(self.settingsControlPresets, 300, left, movingTop, "New Preset Name")
    self.settingsControlPresets.buttonSavePreset = EMAHelperSettings:CreateButton(self.settingsControlPresets, 120, left + 310, movingTop, "Save Current", function()
        local name = self.settingsControlPresets.editBoxPresetName:GetText()
        self:SavePreset(name)
        self.settingsControlPresets.editBoxPresetName:SetText("")
    end)
    movingTop = movingTop - EMAHelperSettings:GetEditBoxHeight()
    
    -- Preset List
    self.settingsControlPresets.presetList = {
        listFrameName = "EMATotemsPresetsSettingsListFrame", 
        parentFrame = self.settingsControlPresets.widgetSettings.content, 
        listTop = movingTop, 
        listLeft = left, 
        listWidth = headingWidth, 
        rowHeight = 25, 
        rowsToDisplay = 10, 
        columnsToDisplay = 3,
        columnInformation = {
            { width = 60, alignment = "LEFT" },
            { width = 20, alignment = "CENTER" },
            { width = 20, alignment = "CENTER" }
        },
        scrollRefreshCallback = function() self:SettingsPresetListScrollRefresh() end, 
        rowClickCallback = function(obj, rowNumber, columnNumber) self:SettingsPresetListRowClick(rowNumber, columnNumber) end
    }
    EMAHelperSettings:CreateScrollList(self.settingsControlPresets.presetList)
    movingTop = movingTop - self.settingsControlPresets.presetList.listHeight - 10

    self.settingsControlPresets.widgetSettings.content:SetHeight(-movingTop + 20)
end

function EMA_Totems:SettingsPresetListScrollRefresh()
    if not self.settingsControlPresets or not self.settingsControlPresets.presetList then return end
    
    local presets = {}
    for name, _ in pairs(self.db.presets) do
        table.insert(presets, name)
    end
    table.sort(presets)
    
    FauxScrollFrame_Update(self.settingsControlPresets.presetList.listScrollFrame, #presets, self.settingsControlPresets.presetList.rowsToDisplay, self.settingsControlPresets.presetList.rowHeight)
    local offset = FauxScrollFrame_GetOffset(self.settingsControlPresets.presetList.listScrollFrame)
    
    for i = 1, self.settingsControlPresets.presetList.rowsToDisplay do
        local row = self.settingsControlPresets.presetList.rows[i]
        local dataIndex = i + offset
        if dataIndex <= #presets then
            local name = presets[dataIndex]
            row.columns[1].textString:SetText(name)
            row.columns[2].textString:SetText("|cff00ff00[Apply]|r")
            row.columns[3].textString:SetText("|cffff0000[Delete]|r")
            row.presetName = name
            row:Show()
        else
            row:Hide()
        end
    end
end

function EMA_Totems:SettingsPresetListRowClick(rowNumber, columnNumber)
    local row = self.settingsControlPresets.presetList.rows[rowNumber]
    if not row or not row.presetName then return end
    
    if columnNumber == 2 then
        self:ApplyPreset(row.presetName)
    elseif columnNumber == 3 then
        self:DeletePreset(row.presetName)
    end
end
