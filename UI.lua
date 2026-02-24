local addonName, ns = ...
local EMA_Totems = ns.EMA_Totems
local UI = {}
ns.UI = UI

local totemLists = ns.totemLists
local totemMapping = ns.totemMapping
local SharedMedia = LibStub("LibSharedMedia-3.0")

-- UI Utils
local function ApplySkin(f)
    if not EMA_Totems.db or not f then return end
    local db = EMA_Totems.db
    local backgroundFile = SharedMedia:Fetch("background", db.backgroundStyle)
    local borderFile = SharedMedia:Fetch("border", db.borderStyle)
    
    if f.SetBackdrop then
        f:SetBackdrop({
            bgFile = backgroundFile,
            edgeFile = borderFile,
            tile = false, tileSize = 0, edgeSize = 2,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        f:SetBackdropColor(
            db.frameBackgroundColourR or 0.1, 
            db.frameBackgroundColourG or 0.1, 
            db.frameBackgroundColourB or 0.1, 
            db.frameBackgroundColourA or 0.7
        )
        f:SetBackdropBorderColor(
            db.frameBorderColourR or 0.5, 
            db.frameBorderColourG or 0.5, 
            db.frameBorderColourB or 0.5, 
            db.frameBorderColourA or 1.0
        )
    end
end

local function ApplySelectorSkin(f)
    if not f then return end
    local backgroundFile = SharedMedia:Fetch("background", "Blizzard Dialog Background Dark")
    local borderFile = SharedMedia:Fetch("border", EMA_Totems.db and EMA_Totems.db.borderStyle or "Blizzard Tooltip")
    
    if f.SetBackdrop then
        f:SetBackdrop({
            bgFile = backgroundFile,
            edgeFile = borderFile,
            tile = false, tileSize = 0, edgeSize = 2,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        f:SetBackdropColor(1, 1, 1, 1)
        f:SetBackdropBorderColor(1, 1, 1, 1)
    end
end

local function ApplyFontStyle(textString)
    if not EMA_Totems.db or not textString then return end
    local db = EMA_Totems.db
    local fontFile = SharedMedia:Fetch("font", db.fontStyle)
    textString:SetFont(fontFile, db.fontSize, "OUTLINE")
end

-----------------------------------------------------------------------
-- SELECTOR FRAME
-----------------------------------------------------------------------
local selector = CreateFrame("Frame", "EMATotemsSelector", UIParent, "BackdropTemplate")
selector:SetSize(200, 250)
selector:SetFrameStrata("HIGH")
selector:EnableMouse(true)
selector:Hide()

selector.timeSinceMouseOver = 0
selector:SetScript("OnUpdate", function(self, elapsed)
    if self:IsMouseOver() then
        self.timeSinceMouseOver = 0
    else
        self.timeSinceMouseOver = self.timeSinceMouseOver + elapsed
        if self.timeSinceMouseOver > 2 then
            self:Hide()
            self.timeSinceMouseOver = 0
        end
    end
end)

selector.items = {}

local function CreateSelectorItem(i)
    local b = CreateFrame("Button", nil, selector)
    b:SetSize(190, 24)
    b:SetPoint("TOPLEFT", 5, -5 - ((i-1) * 26))
    
    b.hl = b:CreateTexture(nil, "HIGHLIGHT")
    b.hl:SetAllPoints()
    b.hl:SetColorTexture(1, 1, 1, 0.2)

    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetSize(20, 20)
    b.icon:SetPoint("LEFT", 5, 0)
    b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.text:SetPoint("LEFT", 30, 0)
    b.text:SetJustifyH("LEFT")

    return b
end

local function ShowSelector(slotBtn, shamanName, slot)
    if EMA_Totems.db and EMA_Totems.db.onlyTimers then return end
    
    local list = totemLists[slot]
    for _, item in ipairs(selector.items) do item:Hide() end
    
    for i, totemID in ipairs(list) do
        if not selector.items[i] then selector.items[i] = CreateSelectorItem(i) end
        local b = selector.items[i]
        local name, _, icon = GetSpellInfo(totemID or 0)
        if not name then name = "Unknown ("..tostring(totemID)..")" end
        
        b.text:SetText(name)
        ApplyFontStyle(b.text)
        b.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        
        b:SetScript("OnClick", function()
            EMA_Totems:UpdateTotemForShaman(shamanName, slot, totemID)
            UI:RefreshBars()
            selector:Hide()
        end)
        b:Show()
    end
    
    selector:SetHeight(#list * 26 + 10)
    selector:ClearAllPoints()
    selector:SetPoint("BOTTOMLEFT", slotBtn, "TOPLEFT", 0, 5)
    selector:SetScale(EMA_Totems.db and EMA_Totems.db.barScale or 1.0)
    ApplySelectorSkin(selector)
    selector:Show()
end

-----------------------------------------------------------------------
-- BAR CREATION
-----------------------------------------------------------------------
local function CreateTotemBar(shamanName, parent)
    local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    f.shamanName = shamanName

    -- Move Handle
    f.handle = CreateFrame("Frame", nil, f, "BackdropTemplate")
    f.handle:SetSize(10, 10)
    f.handle:SetPoint("TOPRIGHT", f, "TOPLEFT", 0, 0)
    f.handle:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    f.handle:SetBackdropColor(0, 0, 0, 1)
    f.handle:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
    f.handle:EnableMouse(true)
    f.handle:RegisterForDrag("LeftButton")
    f.handle:SetScript("OnDragStart", function()
        if not EMA_Totems.db.lockBars then
            f:StartMoving()
        end
    end)
    f.handle:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        local point, _, relativePoint, x, y = f:GetPoint()
        if point then
            local charKey = Ambiguate(f.shamanName, "none"):lower()
            EMA_Totems.db.individualBarPositions[charKey] = { point = point, relativePoint = relativePoint, x = x, y = y }
        end
    end)

    -- Name label
    f.nameLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.nameLabel:SetText(Ambiguate(shamanName, "short"))

    local slots = {"Fire", "Air", "Water", "Earth"}
    f.buttons = {}

    for i, slot in ipairs(slots) do
        local b = CreateFrame("Button", nil, f, "SecureActionButtonTemplate, BackdropTemplate")
        b.slot = slot
        b:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = nil,
            edgeSize = 0,
        })
        b:SetBackdropColor(0, 0, 0, 0)
        b:SetBackdropBorderColor(0, 0, 0, 0)
        
        b.icon = b:CreateTexture(nil, "BACKGROUND")
        b.icon:SetAllPoints(b)
        b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        
        b.hl = b:CreateTexture(nil, "HIGHLIGHT")
        b.hl:SetAllPoints(b.icon)
        b.hl:SetColorTexture(1, 1, 1, 0.2)

        b.cooldown = CreateFrame("Cooldown", nil, b, "CooldownFrameTemplate")
        b.cooldown:SetAllPoints(b.icon)
        b.cooldown:SetFrameLevel(b:GetFrameLevel() + 1)

        b.timerText = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        b.timerText:SetPoint("CENTER", 0, 0)

        b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        b:SetScript("PostClick", function(self, button)
            if button == "RightButton" then
                ShowSelector(self, shamanName, slot)
            end
        end)
        
        b:SetScript("OnEnter", function(self)
            if not EMA_Totems.db then return end
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            
            local active = EMA_Totems.activeTotems[Ambiguate(shamanName, "none")] and EMA_Totems.activeTotems[Ambiguate(shamanName, "none")][slot]
            local last = EMA_Totems.lastUsedTotems[Ambiguate(shamanName, "none")] and EMA_Totems.lastUsedTotems[Ambiguate(shamanName, "none")][slot]
            local selected = EMA_Totems.db.selectedTotems[shamanName] and EMA_Totems.db.selectedTotems[shamanName][slot]
            
            local displayVal = (active and active.name) or selected or (last and last.name) or "None"
            local name = displayVal
            if type(displayVal) == "number" then
                name = GetSpellInfo(displayVal) or ("Unknown ("..displayVal..")")
            end
            
            GameTooltip:SetText(Ambiguate(shamanName, "short") .. " - " .. slot .. " (" .. name .. ")")
            if not EMA_Totems.db.onlyTimers then
                GameTooltip:AddLine("Right: Select Totem", 1, 1, 1)
            end
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
        
        f.buttons[slot] = b
    end

    -- Sequence Button
    if shamanName == EMA_Totems.characterName then
        local seqBtn = CreateFrame("Button", "EMATotemsSequenceButton", f, "SecureActionButtonTemplate, BackdropTemplate")
        seqBtn:RegisterForClicks("AnyUp", "AnyDown")
        seqBtn:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = nil,
            edgeSize = 0,
        })
        seqBtn:SetBackdropColor(0, 0, 0, 0)
        seqBtn:SetBackdropBorderColor(0, 0, 0, 0)

        seqBtn.icon = seqBtn:CreateTexture(nil, "BACKGROUND")
        seqBtn.icon:SetAllPoints(seqBtn)
        seqBtn.icon:SetTexture("Interface\\Icons\\Spell_totem_wardofdraining")
        seqBtn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        seqBtn.hl = seqBtn:CreateTexture(nil, "HIGHLIGHT")
        seqBtn.hl:SetAllPoints(seqBtn.icon)
        seqBtn.hl:SetColorTexture(1, 1, 1, 0.2)

        seqBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Cast Totem Sequence")
            GameTooltip:Show()
        end)
        seqBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        f.seqBtn = seqBtn
    end

    f.UpdateLayout = function(self)
        if not EMA_Totems.db then return end
        local size = EMA_Totems.db.iconSize
        local margin = EMA_Totems.db.iconMargin
        local showNames = EMA_Totems.db.showNames
        local onlyTimers = EMA_Totems.db.onlyTimers
        local nameHeight = showNames and (EMA_Totems.db.fontSize + 2) or 0
        
        local hasSeq = self.seqBtn and not onlyTimers
        local numIcons = hasSeq and 5 or 4
        
        ApplyFontStyle(self.nameLabel)
        local nameWidth = showNames and (self.nameLabel:GetStringWidth() + 4) or 0
        local iconsWidth = (size * numIcons) + (margin * (numIcons - 1))
        local totalWidth = math.max(nameWidth, iconsWidth)
        self:SetSize(math.max(1, totalWidth), size + nameHeight)

        -- Handle
        if EMA_Totems.db.breakUpBars and not EMA_Totems.db.lockBars then
            self.handle:Show()
        else
            self.handle:Hide()
        end
        self.handle:SetHeight(size + nameHeight)

        self.nameLabel:ClearAllPoints()
        if showNames then
            self.nameLabel:Show()
            self.nameLabel:SetJustifyH("LEFT")
            self.nameLabel:SetPoint("TOPLEFT", 0, 0)
        else
            self.nameLabel:Hide()
        end

        local slots = {"Fire", "Air", "Water", "Earth"}
        for i, slot in ipairs(slots) do
            local b = self.buttons[slot]
            b:SetSize(size, size)
            b:ClearAllPoints()
            b:SetPoint("BOTTOMLEFT", (i-1)*(size + margin), 0)
            
            -- Set Font
            local fontFile = SharedMedia:Fetch("font", EMA_Totems.db.fontStyle)
            b.timerText:SetFont(fontFile, EMA_Totems.db.timerFontSize or 16, "OUTLINE")
        end
        
        if self.seqBtn then
            if onlyTimers then
                self.seqBtn:Hide()
            else
                self.seqBtn:Show()
                self.seqBtn:SetSize(size, size)
                self.seqBtn:ClearAllPoints()
                self.seqBtn:SetPoint("BOTTOMLEFT", 4*(size + margin), 0)
            end
        end
        ApplySkin(self)
    end

    f:UpdateLayout()
    return f
end

-----------------------------------------------------------------------
-- UI MANAGEMENT
-----------------------------------------------------------------------
UI.teamBars = {}
UI.masterFrame = nil

function UI:UpdatePositionFromDB()
    if not EMA_Totems.db then return end
    local p = EMA_Totems.db.teamBarsPos
    if self.masterFrame then
        self.masterFrame:ClearAllPoints()
        self.masterFrame:SetPoint(p.point, UIParent, p.point, p.x, p.y)
    end
end

function UI:Initialize()
    if not self.masterFrame then
        self.masterFrame = CreateFrame("Frame", "EMATotemsMasterFrame", UIParent, "BackdropTemplate")
        self.masterFrame:SetMovable(true)
        self.masterFrame:EnableMouse(true)
        self.masterFrame:SetFrameStrata("MEDIUM")
        self.masterFrame:SetSize(200, 40)

        -- Master Handle
        self.masterFrame.handle = CreateFrame("Frame", nil, self.masterFrame, "BackdropTemplate")
        self.masterFrame.handle:SetSize(10, 40)
        self.masterFrame.handle:SetPoint("TOPRIGHT", self.masterFrame, "TOPLEFT", 0, 0)
        self.masterFrame.handle:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        self.masterFrame.handle:SetBackdropColor(0, 0, 0, 1)
        self.masterFrame.handle:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
        self.masterFrame.handle:EnableMouse(true)
        self.masterFrame.handle:RegisterForDrag("LeftButton")
        self.masterFrame.handle:SetScript("OnDragStart", function()
            if not EMA_Totems.db or not EMA_Totems.db.lockBars then
                self.masterFrame:StartMoving()
            end
        end)
        self.masterFrame.handle:SetScript("OnDragStop", function()
            self.masterFrame:StopMovingOrSizing()
            if EMA_Totems.db then
                local point, _, relativePoint, x, y = self.masterFrame:GetPoint()
                EMA_Totems.db.teamBarsPos = { point = point, relativePoint = relativePoint, x = x, y = y }
            end
        end)
    end
    
    self:UpdatePositionFromDB()
end

function UI:RefreshBars()
    if not EMA_Totems.db or not self.masterFrame or not EMAApi then return end
    
    local db = EMA_Totems.db
    if not db.showBars then
        self.masterFrame:Hide()
        return
    end

    self.masterFrame:Show()
    self.masterFrame:SetScale(db.barScale or 1.0)
    self.masterFrame:SetAlpha(db.barAlpha or 1.0)
    
    if db.breakUpBars then
        self.masterFrame:SetBackdrop(nil)
        self.masterFrame.handle:Hide()
    else
        ApplySkin(self.masterFrame)
        if not db.lockBars then
            self.masterFrame.handle:Show()
        else
            self.masterFrame.handle:Hide()
        end
    end
    
    local shamanList = {}
    
    -- Use Team list and check online status (be more permissive with online check)
    for index, characterName in EMAApi.TeamListOrdered() do
        local isOnline = EMAApi.GetCharacterOnlineStatus(characterName)
        local class, color = EMAApi.GetClass(characterName)
        local unit = Ambiguate(characterName, "none")
        
        -- Check if shaman: via EMA data, via manual report, or via direct UnitClass if nearby
        local isShaman = (class and class:lower() == "shaman") or (EMA_Totems.shamanMembers[characterName] == true)
        
        -- Local player fallback
        if characterName == EMA_Totems.characterName then
            local _, myClass = UnitClass("player")
            if myClass == "SHAMAN" then isShaman = true end
        end
        
        -- Nearby unit fallback
        if not isShaman and UnitExists(unit) then
            local _, unitClass = UnitClass(unit)
            if unitClass == "SHAMAN" then isShaman = true end
        end
        
        -- Database fallback (if they ever selected totems, they are a shaman)
        if not isShaman and (EMA_Totems.activeTotems[unit] or (db.selectedTotems and (db.selectedTotems[characterName] or db.selectedTotems[unit]))) then
            isShaman = true
        end

        if isShaman and (isOnline or characterName == EMA_Totems.characterName) then
            table.insert(shamanList, { name = characterName, position = index, color = color })
        end
    end

    -- If we still have no shamans, but the player IS a shaman, add them anyway
    if #shamanList == 0 then
        local _, myClass = UnitClass("player")
        if myClass == "SHAMAN" then
            table.insert(shamanList, { name = EMA_Totems.characterName, position = 1, color = RAID_CLASS_COLORS["SHAMAN"] or {r=0, g=0.44, b=0.87} })
        end
    end

    if not self.hasAnnounced and #shamanList > 0 then
        EMA_Totems:Print("Totem bars initialized ("..#shamanList.." Shaman found).")
        self.hasAnnounced = true
    end

    local order = EMA_Totems.db.barOrder
    if order == "NameAsc" then
        table.sort(shamanList, function(a, b) return a.name < b.name end)
    elseif order == "NameDesc" then
        table.sort(shamanList, function(a, b) return a.name > b.name end)
    elseif order == "EMAPosition" then
        table.sort(shamanList, function(a, b) return a.position < b.position end)
    elseif order == "RoleAsc" then
        local roleWeights = { ["TANK"] = 1, ["HEALER"] = 2, ["DAMAGER"] = 3, ["NONE"] = 4 }
        table.sort(shamanList, function(a, b)
            local unitA = Ambiguate(a.name, "none")
            local unitB = Ambiguate(b.name, "none")
            local roleA = UnitGroupRolesAssigned(unitA) or "NONE"
            local roleB = UnitGroupRolesAssigned(unitB) or "NONE"
            if roleA ~= roleB then
                return (roleWeights[roleA] or 99) < (roleWeights[roleB] or 99)
            end
            return a.name < b.name
        end)
    end

    for name, bar in pairs(self.teamBars) do bar:Hide() end

    local shamanCount = 0
    local currentY = 0
    local barMargin = EMA_Totems.db.barMargin
    local maxBarWidth = 0
    
    for _, info in ipairs(shamanList) do
        local characterName = info.name
        local color = info.color
        local charKey = Ambiguate(characterName, "none"):lower()
        shamanCount = shamanCount + 1
        
        if not self.teamBars[characterName] then
            self.teamBars[characterName] = CreateTotemBar(characterName, self.masterFrame)
        end
        local bar = self.teamBars[characterName]
        
        if db.breakUpBars then
            local pos = db.individualBarPositions[charKey]
            if not pos then
                -- Initial position calculation: Stay where you were in the group
                local point, relativeTo, relativePoint, x, y = bar:GetPoint()
                if point and bar:GetLeft() and bar:GetTop() then
                    -- Convert to screen coordinates
                    local s = bar:GetEffectiveScale() / UIParent:GetEffectiveScale()
                    local left = bar:GetLeft() * s
                    local top = bar:GetTop() * s
                    db.individualBarPositions[charKey] = { point = "TOPLEFT", relativePoint = "TOPLEFT", x = left, y = (top - UIParent:GetHeight()) }
                    pos = db.individualBarPositions[charKey]
                end
            end

            bar:SetParent(UIParent)
            bar:SetMovable(true)
            bar:SetScale(db.barScale or 1.0)
            bar:SetAlpha(db.barAlpha or 1.0)
            bar:SetFrameStrata("MEDIUM")
            bar:ClearAllPoints()
            
            if pos then
                bar:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
            else
                bar:SetPoint("CENTER", UIParent, "CENTER", 100, 0)
            end
        else
            bar:SetParent(self.masterFrame)
            bar:SetMovable(false)
            bar:SetScale(1.0)
            bar:SetAlpha(1.0)
            bar:ClearAllPoints()
            bar:SetPoint("TOPLEFT", 0, currentY)
        end
        
        bar:UpdateLayout()
        bar:Show() -- Ensure visibility AFTER parenting and positioning
        
        if not db.breakUpBars then
            currentY = currentY - bar:GetHeight() - barMargin
        end
        
        if color then
            bar.nameLabel:SetTextColor(color.r, color.g, color.b)
        end
        self:UpdateBarIcons(bar)
        
        maxBarWidth = math.max(maxBarWidth, bar:GetWidth())
    end
    
    if not db.breakUpBars then
        if shamanCount > 0 then
            self.masterFrame:SetHeight(math.abs(currentY) - barMargin)
            self.masterFrame:SetWidth(maxBarWidth)
            self.masterFrame.handle:SetHeight(self.masterFrame:GetHeight())
        else
            self.masterFrame:SetHeight(40)
            self.masterFrame:SetWidth(200)
        end
    else
        self.masterFrame:Hide()
    end
    
    self:UpdateMacros()
end

function UI:UpdateBarIcons(bar)
    if not EMA_Totems.db or not bar then return end
    local shamanName = bar.shamanName
    local shamanKey = Ambiguate(shamanName, "none")
    local settings = EMA_Totems.db.selectedTotems[shamanName]
    local lastUsed = EMA_Totems.lastUsedTotems[shamanKey]
    
    for slot, b in pairs(bar.buttons) do
        local active = EMA_Totems.activeTotems[shamanKey] and EMA_Totems.activeTotems[shamanKey][slot]
        local last = lastUsed and lastUsed[slot]
        local selected = settings and settings[slot]
        
        -- Priority: Active -> Manual Selection -> Last Used Fallback
        local displayIcon = (active and active.icon)
        
        if not displayIcon and selected and selected ~= "" then
            local _, _, icon = GetSpellInfo(selected)
            displayIcon = icon
        end
        
        if not displayIcon and last then
            displayIcon = last.icon
        end
        
        b.icon:SetTexture(displayIcon or "Interface\\Icons\\INV_Misc_QuestionMark")
    end
end

function UI:UpdateMyBar()
    self:RefreshBars()
end

function UI:UpdateMacros()
    if not EMA_Totems.db or InCombatLockdown() then return end
    local myName = EMA_Totems.characterName
    local s = EMA_Totems.db.selectedTotems[myName]
    local seq = EMA_Totems:GetSequenceForShaman(myName)
    
    if not s then return end

    local function GetName(val, default)
        if not val or val == "" then return default end
        if type(val) == "number" then
            local name = GetSpellInfo(val)
            return name or default
        end
        return val
    end

    local elements = {}
    for el in seq:gmatch("([^,%s]+)") do table.insert(elements, el:trim()) end
    local names = {}
    for _, el in ipairs(elements) do
        local totem = s[el]
        if totem then table.insert(names, GetName(totem, "")) end
    end
    
    local myBar = self.teamBars[myName]
    if myBar then
        if myBar.seqBtn and #names > 0 then
            local reset = EMA_Totems.db.useSpamMacro and "3" or "10/combat"
            local suffix = EMA_Totems.db.useSpamMacro and ", null" or ""
            local macro = string.format("/castsequence reset=%s %s%s", reset, table.concat(names, ", "), suffix)
            myBar.seqBtn:SetAttribute("type", "macro")
            myBar.seqBtn:SetAttribute("macrotext", macro)
        end
        
        for slot, b in pairs(myBar.buttons) do
            local totem = s[slot]
            if totem then
                b:SetAttribute("type1", "spell")
                b:SetAttribute("spell1", GetName(totem, ""))
            end
        end
    end
end

function UI:UpdateTimers()
    if not EMA_Totems.db then return end
    local barsToUpdate = {}
    for _, bar in pairs(self.teamBars) do
        if bar:IsShown() then table.insert(barsToUpdate, bar) end
    end
    
    local totemMapping = ns.totemMapping
    local db = EMA_Totems.db
    local currentTime = GetTime()

    for _, bar in ipairs(barsToUpdate) do
        local shamanName = Ambiguate(bar.shamanName, "none")
        local isLocal = (shamanName == Ambiguate(EMA_Totems.characterName, "none"))
        
        for slotName, index in pairs(totemMapping) do
            local b = bar.buttons[slotName]
            if b then
                local haveTotem, name, startTime, duration, icon
                if isLocal then
                    haveTotem, name, startTime, duration, icon = GetTotemInfo(index)
                else
                    local active = EMA_Totems.activeTotems[shamanName] and EMA_Totems.activeTotems[shamanName][slotName]
                    if active then
                        haveTotem, name, startTime, duration, icon = true, active.name, active.startTime, active.duration, active.icon
                    end
                end

                if haveTotem and duration > 0 then
                    local remaining = startTime + duration - currentTime
                    if remaining > 0 then
                        b.cooldown:SetCooldown(startTime, duration)
                        b.cooldown:Show()
                        b.icon:SetAlpha(1.0)
                        
                        if db.showTimers then
                            b.timerText:SetText(math.floor(remaining))
                            b.timerText:SetTextColor(db.timerColorR, db.timerColorG, db.timerColorB)
                            b.timerText:Show()
                        else
                            b.timerText:Hide()
                        end
                    else
                        b.cooldown:Hide()
                        b.timerText:Hide()
                        b.icon:SetAlpha(0.4)
                        UI:UpdateBarIcons(bar)
                    end
                else
                    b.cooldown:Hide()
                    b.timerText:Hide()
                    b.icon:SetAlpha(0.4)
                    UI:UpdateBarIcons(bar)
                end
            end
        end
    end
end

-- Periodical update for timers
local timerFrame = CreateFrame("Frame")
timerFrame:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed > 0.1 then
        UI:UpdateTimers()
        self.elapsed = 0
    end
end)
