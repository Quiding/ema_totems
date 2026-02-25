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
-- TEAM PRESET LOGIC
-- -----------------------------------------------------------------------

function EMA_Totems:SaveTeamPreset(presetName)
    self:Print("DEBUG: SaveTeamPreset called with name: " .. tostring(presetName))
    if not presetName or presetName == "" then 
        self:Print("Error: Please enter a team preset name.")
        return 
    end
    
    local teamData = {}
    local count = 0
    for index, characterName in EMAApi.TeamListOrdered() do
        self:Print("DEBUG: Checking character: " .. characterName)
        local totems = self.db.selectedTotems[characterName]
        local sequence = self.db.castSequences[characterName]
        if totems or sequence then
            self:Print("DEBUG: Found data for: " .. characterName)
            teamData[characterName] = {
                totems = totems and EMAUtilities:CopyTable(totems) or nil,
                sequence = sequence
            }
            count = count + 1
        end
    end
    
    if count == 0 then
        self:Print("Error: No team data found to save.")
        return
    end

    self.db.teamPresets[presetName] = teamData
    self:Print("Team Preset saved: " .. presetName)
    self:SettingsRefresh()
end

function EMA_Totems:ApplyTeamPreset(presetName)
    local teamData = self.db.teamPresets[presetName]
    if not teamData then return end
    
    for characterName, data in pairs(teamData) do
        if data.totems then
            self.db.selectedTotems[characterName] = EMAUtilities:CopyTable(data.totems)
        end
        if data.sequence then
            self.db.castSequences[characterName] = data.sequence
        end
    end
    
    if ns.UI then
        ns.UI:UpdateMyBar()
    end
    self:PushSettingsToTeam()
    self:Print("Team Preset applied: " .. presetName)
end

function EMA_Totems:DeleteTeamPreset(presetName)
    if self.db.teamPresets[presetName] then
        self.db.teamPresets[presetName] = nil
        self:Print("Team Preset deleted: " .. presetName)
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
        local name = self.settingsControlPresets.editBoxPresetName.editbox:GetText()
        self:Print("DEBUG: Single Save button clicked. Name from editbox: " .. tostring(name))
        if name and name ~= "" then
            self:SavePreset(name)
            self.settingsControlPresets.editBoxPresetName.editbox:SetText("")
        else
            self:Print("Error: Please enter a name for the preset.")
        end
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

    -- Team Preset UI
    EMAHelperSettings:CreateHeading(self.settingsControlPresets, "Manage Team Presets", movingTop, false)
    movingTop = movingTop - headingHeight
    
    self.settingsControlPresets.editBoxTeamPresetName = EMAHelperSettings:CreateEditBox(self.settingsControlPresets, 300, left, movingTop, "New Team Preset Name")
    self.settingsControlPresets.buttonSaveTeamPreset = EMAHelperSettings:CreateButton(self.settingsControlPresets, 120, left + 310, movingTop, "Save Current Team", function()
        local name = self.settingsControlPresets.editBoxTeamPresetName.editbox:GetText()
        self:Print("DEBUG: Team Save button clicked. Name from editbox: " .. tostring(name))
        if name and name ~= "" then
            self:SaveTeamPreset(name)
            self.settingsControlPresets.editBoxTeamPresetName.editbox:SetText("")
        else
            self:Print("Error: Please enter a name for the team preset.")
        end
    end)
    movingTop = movingTop - EMAHelperSettings:GetEditBoxHeight()

    self.settingsControlPresets.teamPresetList = {
        listFrameName = "EMATotemsTeamPresetsSettingsListFrame", 
        parentFrame = self.settingsControlPresets.widgetSettings.content, 
        listTop = movingTop, 
        listLeft = left, 
        listWidth = headingWidth, 
        rowHeight = 25, 
        rowsToDisplay = 5, 
        columnsToDisplay = 3,
        columnInformation = {
            { width = 60, alignment = "LEFT" },
            { width = 20, alignment = "CENTER" },
            { width = 20, alignment = "CENTER" }
        },
        scrollRefreshCallback = function() self:SettingsTeamPresetListScrollRefresh() end, 
        rowClickCallback = function(obj, rowNumber, columnNumber) self:SettingsTeamPresetListRowClick(rowNumber, columnNumber) end
    }
    EMAHelperSettings:CreateScrollList(self.settingsControlPresets.teamPresetList)
    movingTop = movingTop - self.settingsControlPresets.teamPresetList.listHeight - 10

    -- Team Preset Editor
    EMAHelperSettings:CreateHeading(self.settingsControlPresets, "Team Preset Editor (Edit Offline/Online Members)", movingTop, false)
    movingTop = movingTop - headingHeight

    self.settingsControlPresets.dropdownEditTeamPreset = EMAHelperSettings:CreateDropdown(self.settingsControlPresets, 300, left, movingTop, "Select Team Preset to Edit")
    self.settingsControlPresets.dropdownEditTeamPreset:SetCallback("OnValueChanged", function(w, e, v) 
        self.selectedTeamPresetToEdit = v
        self.selectedMemberToEdit = nil
        self:SettingsRefresh()
    end)
    movingTop = movingTop - 40

    self.settingsControlPresets.teamMemberList = {
        listFrameName = "EMATotemsTeamMemberListFrame", 
        parentFrame = self.settingsControlPresets.widgetSettings.content, 
        listTop = movingTop, 
        listLeft = left, 
        listWidth = headingWidth, 
        rowHeight = 25, 
        rowsToDisplay = 5, 
        columnsToDisplay = 1,
        columnInformation = {
            { width = 100, alignment = "LEFT" }
        },
        scrollRefreshCallback = function() self:SettingsTeamMemberListScrollRefresh() end, 
        rowClickCallback = function(obj, rowNumber, columnNumber) self:SettingsTeamMemberListRowClick(rowNumber, columnNumber) end
    }
    EMAHelperSettings:CreateScrollList(self.settingsControlPresets.teamMemberList)
    movingTop = movingTop - self.settingsControlPresets.teamMemberList.listHeight - 10

    -- Member Editor Fields
    self.settingsControlPresets.labelEditMember = EMAHelperSettings:CreateLabel(self.settingsControlPresets, headingWidth, left, movingTop, "Editing Member: None")
    movingTop = movingTop - 20

    local dropdownWidth = (headingWidth - 20) / 2
    self.settingsControlPresets.dropdownFire = EMAHelperSettings:CreateDropdown(self.settingsControlPresets, dropdownWidth, left, movingTop, "Fire Totem")
    self.settingsControlPresets.dropdownAir = EMAHelperSettings:CreateDropdown(self.settingsControlPresets, dropdownWidth, left + dropdownWidth + 10, movingTop, "Air Totem")
    movingTop = movingTop - 40
    self.settingsControlPresets.dropdownWater = EMAHelperSettings:CreateDropdown(self.settingsControlPresets, dropdownWidth, left, movingTop, "Water Totem")
    self.settingsControlPresets.dropdownEarth = EMAHelperSettings:CreateDropdown(self.settingsControlPresets, dropdownWidth, left + dropdownWidth + 10, movingTop, "Earth Totem")
    movingTop = movingTop - 40
    
    self.settingsControlPresets.editBoxSequence = EMAHelperSettings:CreateEditBox(self.settingsControlPresets, headingWidth, left, movingTop, "Cast Sequence")
    movingTop = movingTop - EMAHelperSettings:GetEditBoxHeight()

    -- Set callbacks for editor fields
    local function UpdateMemberData()
        if not self.selectedTeamPresetToEdit or not self.selectedMemberToEdit then return end
        local preset = self.db.teamPresets[self.selectedTeamPresetToEdit]
        if not preset then return end
        preset[self.selectedMemberToEdit] = preset[self.selectedMemberToEdit] or {}
        local m = preset[self.selectedMemberToEdit]
        m.totems = m.totems or {}
        m.totems.Fire = self.settingsControlPresets.dropdownFire:GetValue()
        m.totems.Air = self.settingsControlPresets.dropdownAir:GetValue()
        m.totems.Water = self.settingsControlPresets.dropdownWater:GetValue()
        m.totems.Earth = self.settingsControlPresets.dropdownEarth:GetValue()
        m.sequence = self.settingsControlPresets.editBoxSequence.editbox:GetText()
        self:SettingsTeamMemberListScrollRefresh()
    end

    self.settingsControlPresets.dropdownFire:SetCallback("OnValueChanged", UpdateMemberData)
    self.settingsControlPresets.dropdownAir:SetCallback("OnValueChanged", UpdateMemberData)
    self.settingsControlPresets.dropdownWater:SetCallback("OnValueChanged", UpdateMemberData)
    self.settingsControlPresets.dropdownEarth:SetCallback("OnValueChanged", UpdateMemberData)
    self.settingsControlPresets.editBoxSequence:SetCallback("OnEnterPressed", UpdateMemberData)

    self:SettingsRefreshPresets()
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

-- -----------------------------------------------------------------------
-- TEAM PRESET REFRESH/CLICK
-- -----------------------------------------------------------------------

function EMA_Totems:SettingsTeamPresetListScrollRefresh()
    if not self.settingsControlPresets or not self.settingsControlPresets.teamPresetList then return end
    
    local presets = {}
    for name, _ in pairs(self.db.teamPresets) do
        table.insert(presets, name)
    end
    table.sort(presets)
    
    FauxScrollFrame_Update(self.settingsControlPresets.teamPresetList.listScrollFrame, #presets, self.settingsControlPresets.teamPresetList.rowsToDisplay, self.settingsControlPresets.teamPresetList.rowHeight)
    local offset = FauxScrollFrame_GetOffset(self.settingsControlPresets.teamPresetList.listScrollFrame)
    
    for i = 1, self.settingsControlPresets.teamPresetList.rowsToDisplay do
        local row = self.settingsControlPresets.teamPresetList.rows[i]
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

function EMA_Totems:SettingsTeamPresetListRowClick(rowNumber, columnNumber)
    local row = self.settingsControlPresets.teamPresetList.rows[rowNumber]
    if not row or not row.presetName then return end
    
    if columnNumber == 2 then
        self:ApplyTeamPreset(row.presetName)
    elseif columnNumber == 3 then
        self:DeleteTeamPreset(row.presetName)
    end
end

-- -----------------------------------------------------------------------
-- TEAM MEMBER EDITOR REFRESH/CLICK
-- -----------------------------------------------------------------------

function EMA_Totems:SettingsTeamMemberListScrollRefresh()
    if not self.settingsControlPresets or not self.settingsControlPresets.teamMemberList then return end
    if not self.selectedTeamPresetToEdit then
        FauxScrollFrame_Update(self.settingsControlPresets.teamMemberList.listScrollFrame, 0, 5, 25)
        for i=1,5 do self.settingsControlPresets.teamMemberList.rows[i]:Hide() end
        return
    end

    local members = {}
    for index, characterName in EMAApi.TeamListOrdered() do
        table.insert(members, characterName)
    end
    
    FauxScrollFrame_Update(self.settingsControlPresets.teamMemberList.listScrollFrame, #members, self.settingsControlPresets.teamMemberList.rowsToDisplay, self.settingsControlPresets.teamMemberList.rowHeight)
    local offset = FauxScrollFrame_GetOffset(self.settingsControlPresets.teamMemberList.listScrollFrame)
    
    for i = 1, self.settingsControlPresets.teamMemberList.rowsToDisplay do
        local row = self.settingsControlPresets.teamMemberList.rows[i]
        local dataIndex = i + offset
        if dataIndex <= #members then
            local name = members[dataIndex]
            local preset = self.db.teamPresets[self.selectedTeamPresetToEdit]
            local data = preset and preset[name]
            local color = (name == self.selectedMemberToEdit) and "|cffffff00" or "|cffffffff"
            local info = ""
            if data and data.totems then
                local function GetSN(id) if not id then return "None" end; local n = GetSpellInfo(id); return n or ("ID "..id) end
                info = string.format(" - [F: %s, A: %s, W: %s, E: %s]", GetSN(data.totems.Fire):sub(1,4), GetSN(data.totems.Air):sub(1,4), GetSN(data.totems.Water):sub(1,4), GetSN(data.totems.Earth):sub(1,4))
            end
            row.columns[1].textString:SetText(color .. Ambiguate(name, "short") .. "|r" .. info)
            row.memberName = name
            row:Show()
        else
            row:Hide()
        end
    end
end

function EMA_Totems:SettingsTeamMemberListRowClick(rowNumber, columnNumber)
    local row = self.settingsControlPresets.teamMemberList.rows[rowNumber]
    if not row or not row.memberName then return end
    
    self.selectedMemberToEdit = row.memberName
    self:SettingsRefresh()
end

-- Helper to get totem list for dropdown
local function GetTotemListForDropdown(element)
    local list = ns.totemLists[element]
    local dropdownList = { [""] = "None" }
    for _, id in ipairs(list) do
        local name = GetSpellInfo(id)
        if name then
            dropdownList[id] = name
        else
            dropdownList[id] = "ID: " .. id
        end
    end
    return dropdownList
end

function EMA_Totems:SettingsRefreshPresets()
    if not self.settingsControlPresets then return end
    
    self:SettingsPresetListScrollRefresh()
    self:SettingsTeamPresetListScrollRefresh()
    
    -- Update Team Preset Dropdown
    local teamPresetList = {}
    for name, _ in pairs(self.db.teamPresets) do
        teamPresetList[name] = name
    end
    self.settingsControlPresets.dropdownEditTeamPreset:SetList(teamPresetList)
    self.settingsControlPresets.dropdownEditTeamPreset:SetValue(self.selectedTeamPresetToEdit)
    
    -- Update Member Editor
    if self.selectedMemberToEdit then
        self.settingsControlPresets.labelEditMember:SetText("Editing Member: |cffffff00" .. Ambiguate(self.selectedMemberToEdit, "short"))
        
        -- Populate dropdowns if not already done (or just always refresh list)
        self.settingsControlPresets.dropdownFire:SetList(GetTotemListForDropdown("Fire"))
        self.settingsControlPresets.dropdownAir:SetList(GetTotemListForDropdown("Air"))
        self.settingsControlPresets.dropdownWater:SetList(GetTotemListForDropdown("Water"))
        self.settingsControlPresets.dropdownEarth:SetList(GetTotemListForDropdown("Earth"))
        
        local preset = self.db.teamPresets[self.selectedTeamPresetToEdit]
        local data = preset and preset[self.selectedMemberToEdit]
        if data then
            self.settingsControlPresets.dropdownFire:SetValue(data.totems and data.totems.Fire or "")
            self.settingsControlPresets.dropdownAir:SetValue(data.totems and data.totems.Air or "")
            self.settingsControlPresets.dropdownWater:SetValue(data.totems and data.totems.Water or "")
            self.settingsControlPresets.dropdownEarth:SetValue(data.totems and data.totems.Earth or "")
            self.settingsControlPresets.editBoxSequence:SetText(data.sequence or "Fire, Air, Water, Earth")
        else
            self.settingsControlPresets.dropdownFire:SetValue("")
            self.settingsControlPresets.dropdownAir:SetValue("")
            self.settingsControlPresets.dropdownWater:SetValue("")
            self.settingsControlPresets.dropdownEarth:SetValue("")
            self.settingsControlPresets.editBoxSequence:SetText("Fire, Air, Water, Earth")
        end
        
        self.settingsControlPresets.dropdownFire:SetDisabled(false)
        self.settingsControlPresets.dropdownAir:SetDisabled(false)
        self.settingsControlPresets.dropdownWater:SetDisabled(false)
        self.settingsControlPresets.dropdownEarth:SetDisabled(false)
        self.settingsControlPresets.editBoxSequence:SetDisabled(false)
    else
        self.settingsControlPresets.labelEditMember:SetText("Editing Member: None")
        self.settingsControlPresets.dropdownFire:SetDisabled(true)
        self.settingsControlPresets.dropdownAir:SetDisabled(true)
        self.settingsControlPresets.dropdownWater:SetDisabled(true)
        self.settingsControlPresets.dropdownEarth:SetDisabled(true)
        self.settingsControlPresets.editBoxSequence:SetDisabled(true)
    end
    
    self:SettingsTeamMemberListScrollRefresh()
end
