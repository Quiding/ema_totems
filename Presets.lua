local addonName, ns = ...
local EMA_Totems = ns.EMA_Totems

function EMA_Totems_Presets_Migration(db)
    if not db or not db.teamPresets then return end
    local EMAUtilities = LibStub:GetLibrary("EbonyUtilities-1.0")
    for name, data in pairs(db.teamPresets) do
        if not data.members then
            local members = EMAUtilities:CopyTable(data)
            db.teamPresets[name] = { members = members, icon = "Interface\\Icons\\Spell_Totem_WardOfDraining" }
        end
    end
end

-- -----------------------------------------------------------------------
-- INDIVIDUAL PRESET LOGIC
-- -----------------------------------------------------------------------

function EMA_Totems:SaveIndividualPreset(charName, presetName)
    local EMAUtilities = LibStub:GetLibrary("EbonyUtilities-1.0")
    if not charName or charName == "" then self:Print("Error: No character selected."); return end
    if not presetName or presetName == "" then self:Print("Error: Please enter a preset name."); return end
    
    local totems = self.db.selectedTotems[charName]
    local sequence = self.db.castSequences[charName]
    
    if not totems and not sequence then
        self:Print("Error: No data found for character: " .. charName)
        return
    end
    
    if not self.db.presets[charName] then self.db.presets[charName] = {} end
    self.db.presets[charName][presetName] = {
        totems = totems and EMAUtilities:CopyTable(totems) or nil,
        sequence = sequence
    }
    self:Print(string.format("Individual preset '%s' saved for %s", presetName, Ambiguate(charName, "short")))
    self:SettingsRefresh()
end

function EMA_Totems:ApplyIndividualPreset(charName, presetName)
    local charPresets = self.db.presets[charName]
    local preset = charPresets and charPresets[presetName]
    if not preset then return end
    
    if preset.totems then self.db.selectedTotems[charName] = EMAUtilities:CopyTable(preset.totems) end
    if preset.sequence then self.db.castSequences[charName] = preset.sequence end
    
    if charName:lower() == self.characterName:lower() and ns.UI then ns.UI:UpdateMyBar() end
    self:PushSettingsToTeam()
    self:Print(string.format("Individual preset '%s' applied to %s", presetName, Ambiguate(charName, "short")))
end

function EMA_Totems:DeleteIndividualPreset(charName, presetName)
    if self.db.presets[charName] and self.db.presets[charName][presetName] then
        self.db.presets[charName][presetName] = nil
        self:Print(string.format("Individual preset '%s' deleted for %s", presetName, Ambiguate(charName, "short")))
        self:SettingsRefresh()
    end
end

-- -----------------------------------------------------------------------
-- TEAM PRESET LOGIC
-- -----------------------------------------------------------------------

function EMA_Totems:SaveTeamPreset(presetName)
    local EMAUtilities = LibStub:GetLibrary("EbonyUtilities-1.0")
    if not presetName or presetName == "" then self:Print("Error: Please enter a team preset name."); return end
    local teamData = {}
    local count = 0
    for index, characterName in EMAApi.TeamListOrdered() do
        local class, _ = EMAApi.GetClass(characterName)
        local isShaman = (class and class:lower() == "shaman") or (self.shamanMembers[characterName] == true)
        if not isShaman and characterName == self.characterName then
            local _, myClass = UnitClass("player"); if myClass == "SHAMAN" then isShaman = true end
        end
        if isShaman then
            local totems = self.db.selectedTotems[characterName]
            local sequence = self.db.castSequences[characterName]
            if totems or sequence then
                teamData[characterName] = { totems = totems and EMAUtilities:CopyTable(totems) or nil, sequence = sequence }
                count = count + 1
            end
        end
    end
    if count == 0 then self:Print("Error: No team data found to save."); return end
    self.db.teamPresets[presetName] = { members = teamData, icon = "Interface\\Icons\\Spell_Totem_WardOfDraining" }
    self:Print("Team Preset saved: " .. presetName); self:SettingsRefresh()
end

function EMA_Totems:ApplyTeamPreset(presetName)
    local preset = self.db.teamPresets[presetName]
    if not preset or not preset.members then return end
    local EMAUtilities = LibStub:GetLibrary("EbonyUtilities-1.0")
    for characterName, data in pairs(preset.members) do
        if data.totems then self.db.selectedTotems[characterName] = EMAUtilities:CopyTable(data.totems) end
        if data.sequence then self.db.castSequences[characterName] = data.sequence end
    end
    if ns.UI then ns.UI:UpdateMyBar() end
    self:PushSettingsToTeam(); self:Print("Team Preset applied: " .. presetName)
end

function EMA_Totems:DeleteTeamPreset(presetName)
    if self.db.teamPresets[presetName] then
        self.db.teamPresets[presetName] = nil
        self:Print("Team Preset deleted: " .. presetName); self:SettingsRefresh()
    end
end

-- -----------------------------------------------------------------------
-- INDIVIDUAL PRESETS UI
-- -----------------------------------------------------------------------

function EMA_Totems:IndividualPresetsSettingsCreate()
    self.settingsControlIndividualPresets = {}
    local EMAHelperSettings = LibStub("EMAHelperSettings-1.0")
    EMAHelperSettings:CreateSettings(self.settingsControlIndividualPresets, "Individual Presets", "Totems", function() self:PushSettingsToTeam() end, "Interface\\AddOns\\EMA\\Media\\SettingsIcon.tga", 14)
    local top, left = EMAHelperSettings:TopOfSettings(), EMAHelperSettings:LeftOfSettings()
    local headingHeight, headingWidth = EMAHelperSettings:HeadingHeight(), EMAHelperSettings:HeadingWidth(true)
    local movingTop = top

    EMAHelperSettings:CreateHeading(self.settingsControlIndividualPresets, "Manage Individual Totem Presets", movingTop, false)
    movingTop = movingTop - headingHeight - 10

    self.settingsControlIndividualPresets.dropdownSelectMember = EMAHelperSettings:CreateDropdown(self.settingsControlIndividualPresets, 300, left, movingTop, "Select Shaman to Manage")
    self.settingsControlIndividualPresets.dropdownSelectMember:SetCallback("OnValueChanged", function(w, e, v) 
        self.selectedShamanForIndividualPresets = v
        self:SettingsRefresh()
    end)
    movingTop = movingTop - 45

    self.settingsControlIndividualPresets.editBoxPresetName = EMAHelperSettings:CreateEditBox(self.settingsControlIndividualPresets, 300, left, movingTop, "New Preset Name")
    self.settingsControlIndividualPresets.buttonSavePreset = EMAHelperSettings:CreateButton(self.settingsControlIndividualPresets, 80, left + 310, movingTop - 20, "Save", function()
        self:SaveIndividualPreset(self.selectedShamanForIndividualPresets, self.settingsControlIndividualPresets.editBoxPresetName.editbox:GetText())
        self.settingsControlIndividualPresets.editBoxPresetName.editbox:SetText("")
    end)
    movingTop = movingTop - EMAHelperSettings:GetEditBoxHeight() - 15
    
    self.settingsControlIndividualPresets.presetList = {
        listFrameName = "EMATotemsIndividualPresetsSettingsListFrame", parentFrame = self.settingsControlIndividualPresets.widgetSettings.content, listTop = movingTop, listLeft = left, listWidth = headingWidth, rowHeight = 25, rowsToDisplay = 15, columnsToDisplay = 3,
        columnInformation = { { width = 60, alignment = "LEFT" }, { width = 20, alignment = "CENTER" }, { width = 20, alignment = "CENTER" } },
        scrollRefreshCallback = function() self:SettingsIndividualPresetListScrollRefresh() end, 
        rowClickCallback = function(obj, rowNumber, columnNumber) self:SettingsIndividualPresetListRowClick(rowNumber, columnNumber) end
    }
    EMAHelperSettings:CreateScrollList(self.settingsControlIndividualPresets.presetList)
    movingTop = movingTop - self.settingsControlIndividualPresets.presetList.listHeight - 10
    self.settingsControlIndividualPresets.widgetSettings.content:SetHeight(-movingTop + 20)
end

function EMA_Totems:SettingsIndividualPresetListScrollRefresh()
    if not self.settingsControlIndividualPresets or not self.settingsControlIndividualPresets.presetList then return end
    local charName = self.selectedShamanForIndividualPresets
    local presets = {}
    if charName and self.db.presets[charName] then
        for name, _ in pairs(self.db.presets[charName]) do table.insert(presets, name) end
        table.sort(presets)
    end
    FauxScrollFrame_Update(self.settingsControlIndividualPresets.presetList.listScrollFrame, #presets, self.settingsControlIndividualPresets.presetList.rowsToDisplay, self.settingsControlIndividualPresets.presetList.rowHeight)
    local offset = FauxScrollFrame_GetOffset(self.settingsControlIndividualPresets.presetList.listScrollFrame)
    for i = 1, self.settingsControlIndividualPresets.presetList.rowsToDisplay do
        local row = self.settingsControlIndividualPresets.presetList.rows[i]
        local dataIndex = i + offset
        if dataIndex <= #presets then
            local name = presets[dataIndex]
            row.columns[1].textString:SetText(name); row.columns[2].textString:SetText("|cff00ff00[Apply]|r"); row.columns[3].textString:SetText("|cffff0000[Delete]|r")
            row.presetName = name; row:Show()
        else row:Hide() end
    end
end

function EMA_Totems:SettingsIndividualPresetListRowClick(rowNumber, columnNumber)
    local row = self.settingsControlIndividualPresets.presetList.rows[rowNumber]
    if not row or not row.presetName then return end
    if columnNumber == 2 then self:ApplyIndividualPreset(self.selectedShamanForIndividualPresets, row.presetName)
    elseif columnNumber == 3 then self:DeleteIndividualPreset(self.selectedShamanForIndividualPresets, row.presetName) end
end

-- -----------------------------------------------------------------------
-- TEAM PRESETS UI
-- -----------------------------------------------------------------------

function EMA_Totems:TeamPresetsSettingsCreate()
    EMA_Totems_Presets_Migration(self.db)
    self.settingsControlTeamPresets = {}
    local EMAHelperSettings = LibStub("EMAHelperSettings-1.0")
    EMAHelperSettings:CreateSettings(self.settingsControlTeamPresets, "Team Presets", "Totems", function() self:PushSettingsToTeam() end, "Interface\\AddOns\\EMA\\Media\\TeamCore.tga", 15)
    local top, left = EMAHelperSettings:TopOfSettings(), EMAHelperSettings:LeftOfSettings()
    local headingHeight, headingWidth = EMAHelperSettings:HeadingHeight(), EMAHelperSettings:HeadingWidth(true)
    local movingTop = top
    
    EMAHelperSettings:CreateHeading(self.settingsControlTeamPresets, "Manage Team Totem Presets", movingTop, false)
    movingTop = movingTop - headingHeight - 10
    self.settingsControlTeamPresets.editBoxTeamPresetName = EMAHelperSettings:CreateEditBox(self.settingsControlTeamPresets, 300, left, movingTop, "New Team Preset Name")
    self.settingsControlTeamPresets.buttonSaveTeamPreset = EMAHelperSettings:CreateButton(self.settingsControlTeamPresets, 80, left + 310, movingTop - 20, "Save", function()
        self:SaveTeamPreset(self.settingsControlTeamPresets.editBoxTeamPresetName.editbox:GetText())
        self.settingsControlTeamPresets.editBoxTeamPresetName.editbox:SetText("")
    end)
    movingTop = movingTop - EMAHelperSettings:GetEditBoxHeight() - 15

    self.settingsControlTeamPresets.teamPresetList = {
        listFrameName = "EMATotemsTeamPresetsSettingsListFrame", parentFrame = self.settingsControlTeamPresets.widgetSettings.content, listTop = movingTop, listLeft = left, listWidth = headingWidth, rowHeight = 35, rowsToDisplay = 5, columnsToDisplay = 3,
        columnInformation = { { width = 60, alignment = "LEFT" }, { width = 20, alignment = "CENTER" }, { width = 20, alignment = "CENTER" } },
        scrollRefreshCallback = function() self:SettingsTeamPresetListScrollRefresh() end, 
        rowClickCallback = function(obj, rowNumber, columnNumber) self:SettingsTeamPresetListRowClick(rowNumber, columnNumber) end
    }
    EMAHelperSettings:CreateScrollList(self.settingsControlTeamPresets.teamPresetList)
    movingTop = movingTop - self.settingsControlTeamPresets.teamPresetList.listHeight - 25

    EMAHelperSettings:CreateHeading(self.settingsControlTeamPresets, "Team Preset Editor", movingTop, false)
    movingTop = movingTop - headingHeight - 15
    self.settingsControlTeamPresets.dropdownEditTeamPreset = EMAHelperSettings:CreateDropdown(self.settingsControlTeamPresets, 200, left, movingTop, "Select Preset to Edit")
    self.settingsControlTeamPresets.dropdownEditTeamPreset:SetCallback("OnValueChanged", function(w, e, v) self.selectedTeamPresetToEdit = v; self.selectedMemberToEdit = nil; self:SettingsRefresh() end)
    self.settingsControlTeamPresets.displayPresetIcon = EMAHelperSettings:Icon(self.settingsControlTeamPresets, 42, 42, "Interface\\Icons\\INV_Misc_QuestionMark", left + 220, movingTop, "Icon", function() self:Print("Drag a totem, spell, or item here to change the icon.") end, "Drag a spell or item here.")
    local iconFrame = self.settingsControlTeamPresets.displayPresetIcon.frame
    iconFrame:SetScript("OnReceiveDrag", function()
        if not self.selectedTeamPresetToEdit then return end
        local type, id, info = GetCursorInfo()
        local icon
        if type == "spell" then icon = select(3, GetSpellInfo(id, info)) elseif type == "item" then icon = select(10, GetItemInfo(id)) end
        if icon then self.db.teamPresets[self.selectedTeamPresetToEdit].icon = icon; ClearCursor(); self:SettingsRefresh() end
    end)
    iconFrame:HookScript("OnMouseUp", function() if not self.selectedTeamPresetToEdit then return end; local type, id, info = GetCursorInfo(); if type == "spell" or type == "item" then iconFrame:GetScript("OnReceiveDrag")() end end)
    self.settingsControlTeamPresets.editBoxPresetIcon = EMAHelperSettings:CreateEditBox(self.settingsControlTeamPresets, 150, left + 350, movingTop, "Icon Name/ID")
    self.settingsControlTeamPresets.editBoxPresetIcon:SetCallback("OnEnterPressed", function(w, e, v)
        if not self.selectedTeamPresetToEdit then return end
        local function FindIconRobust(search)
            if tonumber(search) then return tonumber(search) end; local sLower = search:lower()
            local name, _, icon = GetSpellInfo(search); if name and name:lower() == sLower then return icon end
            for element, list in pairs(ns.totemLists) do for _, id in ipairs(list) do local tName, _, tIcon = GetSpellInfo(id); if tName and tName:lower() == sLower then return tIcon end end end
            local _, _, _, _, _, _, _, _, _, iIcon = GetItemInfo(search); if iIcon then return iIcon end; return nil
        end
        local icon = FindIconRobust(v:trim()); if icon then self.db.teamPresets[self.selectedTeamPresetToEdit].icon = icon; self:SettingsRefresh() else self:Print("Error: Icon not found.") end
    end)
    movingTop = movingTop - 65

    self.settingsControlTeamPresets.teamMemberList = {
        listFrameName = "EMATotemsTeamMemberListFrame", parentFrame = self.settingsControlTeamPresets.widgetSettings.content, listTop = movingTop, listLeft = left, listWidth = headingWidth, rowHeight = 25, rowsToDisplay = 5, columnsToDisplay = 1,
        columnInformation = { { width = 100, alignment = "LEFT" } },
        scrollRefreshCallback = function() self:SettingsTeamMemberListScrollRefresh() end, 
        rowClickCallback = function(obj, rowNumber, columnNumber) self:SettingsTeamMemberListRowClick(rowNumber, columnNumber) end
    }
    EMAHelperSettings:CreateScrollList(self.settingsControlTeamPresets.teamMemberList)
    movingTop = movingTop - self.settingsControlTeamPresets.teamMemberList.listHeight - 15
    self.settingsControlTeamPresets.labelEditMember = EMAHelperSettings:CreateLabel(self.settingsControlTeamPresets, headingWidth, left, movingTop, "Editing Member: None")
    movingTop = movingTop - 25
    local dropdownWidth = (headingWidth - 20) / 2
    self.settingsControlTeamPresets.dropdownFire = EMAHelperSettings:CreateDropdown(self.settingsControlTeamPresets, dropdownWidth, left, movingTop, "Fire Totem")
    self.settingsControlTeamPresets.dropdownAir = EMAHelperSettings:CreateDropdown(self.settingsControlTeamPresets, dropdownWidth, left + dropdownWidth + 10, movingTop, "Air Totem")
    movingTop = movingTop - 50
    self.settingsControlTeamPresets.dropdownWater = EMAHelperSettings:CreateDropdown(self.settingsControlTeamPresets, dropdownWidth, left, movingTop, "Water Totem")
    self.settingsControlTeamPresets.dropdownEarth = EMAHelperSettings:CreateDropdown(self.settingsControlTeamPresets, dropdownWidth, left + dropdownWidth + 10, movingTop, "Earth Totem")
    movingTop = movingTop - 50
    self.settingsControlTeamPresets.editBoxSequence = EMAHelperSettings:CreateEditBox(self.settingsControlTeamPresets, headingWidth, left, movingTop, "Cast Sequence")
    movingTop = movingTop - EMAHelperSettings:GetEditBoxHeight() - 15

    local function UpdateMemberData()
        if not self.selectedTeamPresetToEdit or not self.selectedMemberToEdit then return end
        local preset = self.db.teamPresets[self.selectedTeamPresetToEdit]
        if not preset then return end
        local m = preset.members[self.selectedMemberToEdit] or { totems = {}, sequence = "" }; preset.members[self.selectedMemberToEdit] = m
        m.totems.Fire = self.settingsControlTeamPresets.dropdownFire:GetValue()
        m.totems.Air = self.settingsControlTeamPresets.dropdownAir:GetValue()
        m.totems.Water = self.settingsControlTeamPresets.dropdownWater:GetValue()
        m.totems.Earth = self.settingsControlTeamPresets.dropdownEarth:GetValue()
        m.sequence = self.settingsControlTeamPresets.editBoxSequence.editbox:GetText()
        self:SettingsTeamMemberListScrollRefresh()
    end
    self.settingsControlTeamPresets.dropdownFire:SetCallback("OnValueChanged", UpdateMemberData); self.settingsControlTeamPresets.dropdownAir:SetCallback("OnValueChanged", UpdateMemberData); self.settingsControlTeamPresets.dropdownWater:SetCallback("OnValueChanged", UpdateMemberData); self.settingsControlTeamPresets.dropdownEarth:SetCallback("OnValueChanged", UpdateMemberData); self.settingsControlTeamPresets.editBoxSequence:SetCallback("OnEnterPressed", UpdateMemberData)
    self.settingsControlTeamPresets.widgetSettings.content:SetHeight(-movingTop + 20)
end

function EMA_Totems:SettingsTeamPresetListScrollRefresh()
    if not self.settingsControlTeamPresets or not self.settingsControlTeamPresets.teamPresetList then return end
    local presets = {}
    for name, _ in pairs(self.db.teamPresets) do table.insert(presets, name) end
    table.sort(presets)
    local list = self.settingsControlTeamPresets.teamPresetList
    FauxScrollFrame_Update(list.listScrollFrame, #presets, list.rowsToDisplay, list.rowHeight)
    local offset = FauxScrollFrame_GetOffset(list.listScrollFrame)
    for i = 1, list.rowsToDisplay do
        local row = list.rows[i]
        local dataIndex = i + offset
        if dataIndex <= #presets then
            local name = presets[dataIndex]
            local preset = self.db.teamPresets[name]
            if not row.presetIcon then row.presetIcon = row.columns[1]:CreateTexture(nil, "ARTWORK"); row.presetIcon:SetSize(list.rowHeight - 4, list.rowHeight - 4); row.presetIcon:SetPoint("LEFT", 4, 0); row.presetIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
            row.presetIcon:SetTexture(preset.icon or "Interface\\Icons\\Spell_Totem_WardOfDraining")
            row.columns[1].textString:ClearAllPoints(); row.columns[1].textString:SetPoint("LEFT", list.rowHeight + 4, 0); row.columns[1].textString:SetPoint("RIGHT", 0, 0)
            row.columns[1].textString:SetText(name); row.columns[2].textString:SetText("|cff00ff00[Apply]|r"); row.columns[3].textString:SetText("|cffff0000[Delete]|r")
            row.presetName = name; row:Show()
        else row:Hide() end
    end
end

function EMA_Totems:SettingsTeamPresetListRowClick(rowNumber, columnNumber)
    local row = self.settingsControlTeamPresets.teamPresetList.rows[rowNumber]
    if not row or not row.presetName then return end
    if columnNumber == 2 then self:ApplyTeamPreset(row.presetName)
    elseif columnNumber == 3 then self:DeleteTeamPreset(row.presetName) end
end

function EMA_Totems:SettingsTeamMemberListScrollRefresh()
    if not self.settingsControlTeamPresets or not self.settingsControlTeamPresets.teamMemberList then return end
    if not self.selectedTeamPresetToEdit then
        FauxScrollFrame_Update(self.settingsControlTeamPresets.teamMemberList.listScrollFrame, 0, 5, 25); for i=1,5 do self.settingsControlTeamPresets.teamMemberList.rows[i]:Hide() end; return
    end
    local members = {}
    for index, characterName in EMAApi.TeamListOrdered() do
        local class, _ = EMAApi.GetClass(characterName)
        local isShaman = (class and class:lower() == "shaman") or (self.shamanMembers[characterName] == true)
        if not isShaman and characterName == self.characterName then local _, myClass = UnitClass("player"); if myClass == "SHAMAN" then isShaman = true end end
        if isShaman then table.insert(members, characterName) end
    end
    local list = self.settingsControlTeamPresets.teamMemberList
    FauxScrollFrame_Update(list.listScrollFrame, #members, list.rowsToDisplay, list.rowHeight)
    local offset = FauxScrollFrame_GetOffset(list.listScrollFrame)
    for i = 1, list.rowsToDisplay do
        local row = list.rows[i]
        local dataIndex = i + offset
        if dataIndex <= #members then
            local name = members[dataIndex]
            local preset = self.db.teamPresets[self.selectedTeamPresetToEdit]
            local data = preset and preset.members[name]
            local color = (name == self.selectedMemberToEdit) and "|cffffff00" or "|cffffffff"
            local info = ""
            if data and data.totems then
                local function GetSN(id) if not id then return "None" end; local n = GetSpellInfo(id); return n or ("ID "..id) end
                info = string.format(" - [F: %s, A: %s, W: %s, E: %s]", GetSN(data.totems.Fire):sub(1,4), GetSN(data.totems.Air):sub(1,4), GetSN(data.totems.Water):sub(1,4), GetSN(data.totems.Earth):sub(1,4))
            end
            row.columns[1].textString:SetText(color .. Ambiguate(name, "short") .. "|r" .. info)
            row.memberName = name; row:Show()
        else row:Hide() end
    end
end

function EMA_Totems:SettingsTeamMemberListRowClick(rowNumber, columnNumber)
    local row = self.settingsControlTeamPresets.teamMemberList.rows[rowNumber]
    if not row or not row.memberName then return end
    self.selectedMemberToEdit = row.memberName; self:SettingsRefresh()
end

local function GetTotemListForDropdown(element)
    local list = ns.totemLists[element]
    local dropdownList = { [""] = "None" }
    for _, id in ipairs(list) do local name = GetSpellInfo(id); dropdownList[id] = name or ("ID: " .. id) end
    return dropdownList
end

function EMA_Totems:SettingsRefreshPresets()
    if self.settingsControlIndividualPresets then
        local shamans = { [""] = "Select Shaman..." }
        for index, characterName in EMAApi.TeamListOrdered() do
            local class, _ = EMAApi.GetClass(characterName)
            local isShaman = (class and class:lower() == "shaman") or (self.shamanMembers[characterName] == true)
            if not isShaman and characterName == self.characterName then local _, myClass = UnitClass("player"); if myClass == "SHAMAN" then isShaman = true end end
            if isShaman then shamans[characterName] = Ambiguate(characterName, "short") end
        end
        self.settingsControlIndividualPresets.dropdownSelectMember:SetList(shamans)
        self.settingsControlIndividualPresets.dropdownSelectMember:SetValue(self.selectedShamanForIndividualPresets or "")
        self:SettingsIndividualPresetListScrollRefresh()
    end
    
    if self.settingsControlTeamPresets then
        self:SettingsTeamPresetListScrollRefresh()
        local teamPresetList = {}
        for name, _ in pairs(self.db.teamPresets) do teamPresetList[name] = name end
        self.settingsControlTeamPresets.dropdownEditTeamPreset:SetList(teamPresetList)
        self.settingsControlTeamPresets.dropdownEditTeamPreset:SetValue(self.selectedTeamPresetToEdit)
        if self.selectedTeamPresetToEdit then
            local icon = self.db.teamPresets[self.selectedTeamPresetToEdit].icon or "Interface\\Icons\\Spell_Totem_WardOfDraining"
            self.settingsControlTeamPresets.displayPresetIcon:SetImage(icon); self.settingsControlTeamPresets.editBoxPresetIcon:SetDisabled(false)
        else self.settingsControlTeamPresets.displayPresetIcon:SetImage("Interface\\Icons\\INV_Misc_QuestionMark"); self.settingsControlTeamPresets.editBoxPresetIcon:SetDisabled(true) end
        self.settingsControlTeamPresets.editBoxPresetIcon.editbox:SetText("")
        if self.selectedMemberToEdit then
            self.settingsControlTeamPresets.labelEditMember:SetText("Editing Member: |cffffff00" .. Ambiguate(self.selectedMemberToEdit, "short"))
            self.settingsControlTeamPresets.dropdownFire:SetList(GetTotemListForDropdown("Fire")); self.settingsControlTeamPresets.dropdownAir:SetList(GetTotemListForDropdown("Air")); self.settingsControlTeamPresets.dropdownWater:SetList(GetTotemListForDropdown("Water")); self.settingsControlTeamPresets.dropdownEarth:SetList(GetTotemListForDropdown("Earth"))
            local preset = self.db.teamPresets[self.selectedTeamPresetToEdit]
            local data = preset and preset.members[self.selectedMemberToEdit]
            if data then
                self.settingsControlTeamPresets.dropdownFire:SetValue(data.totems and data.totems.Fire or ""); self.settingsControlTeamPresets.dropdownAir:SetValue(data.totems and data.totems.Air or ""); self.settingsControlTeamPresets.dropdownWater:SetValue(data.totems and data.totems.Water or ""); self.settingsControlTeamPresets.dropdownEarth:SetValue(data.totems and data.totems.Earth or ""); self.settingsControlTeamPresets.editBoxSequence:SetText(data.sequence or "Fire, Air, Water, Earth")
            else
                self.settingsControlTeamPresets.dropdownFire:SetValue(""); self.settingsControlTeamPresets.dropdownAir:SetValue(""); self.settingsControlTeamPresets.dropdownWater:SetValue(""); self.settingsControlTeamPresets.dropdownEarth:SetValue(""); self.settingsControlTeamPresets.editBoxSequence:SetText("Fire, Air, Water, Earth")
            end
            self.settingsControlTeamPresets.dropdownFire:SetDisabled(false); self.settingsControlTeamPresets.dropdownAir:SetDisabled(false); self.settingsControlTeamPresets.dropdownWater:SetDisabled(false); self.settingsControlTeamPresets.dropdownEarth:SetDisabled(false); self.settingsControlTeamPresets.editBoxSequence:SetDisabled(false)
        else
            self.settingsControlTeamPresets.labelEditMember:SetText("Editing Member: None")
            self.settingsControlTeamPresets.dropdownFire:SetDisabled(true); self.settingsControlTeamPresets.dropdownAir:SetDisabled(true); self.settingsControlTeamPresets.dropdownWater:SetDisabled(true); self.settingsControlTeamPresets.dropdownEarth:SetDisabled(true); self.settingsControlTeamPresets.editBoxSequence:SetDisabled(true)
        end
        self:SettingsTeamMemberListScrollRefresh()
    end
end
