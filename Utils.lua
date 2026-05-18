-- Utils.lua

------------------------
-- Main Frame Updates --
------------------------
local ModernFocusFrame = ModernFocusFrame

local function GetHealthBarColor(unit)
    if UnitIsPlayer(unit) then
        local _, classToken = UnitClass(unit)
        local classColor = classToken and RAID_CLASS_COLORS[classToken]
        if classColor then
            return classColor.r, classColor.g, classColor.b
        end
    end

    local canAttack = UnitCanAttack("player", unit)
    if canAttack and UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) then
        return 0.5, 0.5, 0.5
    end

    local reaction = UnitReaction("player", unit)
    if reaction then
        if reaction >= 5 then
            return 0.2, 0.9, 0.2
        elseif reaction == 4 then
            return 1.0, 0.85, 0.1
        end
    end

    if canAttack then
        return 0.9, 0.1, 0.1
    end

    return 0.2, 0.9, 0.2
end

function ModernFocusFrame:UpdateModernFocusFrame()
    if self.focusGUID then
        local unit = self.focusGUID
        if not UnitExists(unit) then
            self.frame:Hide()
            self:ClearModernToFocusFrame()
            return
        end

        local name = UnitName(unit)
        self.nameText:SetText(name or "Unknown")

        local hp, hpMax = UnitHealth(unit), UnitHealthMax(unit)
        local powerType = UnitPowerType(unit)
        local power, powerMax = UnitMana(unit), UnitManaMax(unit)
        local isDead = UnitIsDead(unit)

        self.healthBar:SetMinMaxValues(0, hpMax)
        self.healthBar:SetValue(hp)
        if isDead then
            self.healthText:Hide()
            self.deadText:Show()
        else
            self.healthText:SetText(hp)
            self.healthText:Show()
            self.deadText:Hide()
        end

        self.healthBar:SetStatusBarColor(GetHealthBarColor(unit))


        self.manaBar:SetMinMaxValues(0, powerMax)
        self.manaBar:SetValue(power)

        if powerType == 1 then
            self.manaBar:SetStatusBarColor(1, 0, 0)
            self.manaText:SetText(power)
        elseif powerType == 3 then
            self.manaBar:SetStatusBarColor(1, 1, 0)
            self.manaText:SetText(power)
        else
            self.manaBar:SetStatusBarColor(0, 0, 1)
            self.manaText:SetText(power)
        end

        SetPortraitTexture(self.portrait, unit)

        local level = UnitLevel(unit)
        if level and level > 0 then
            self.levelText:SetText(level)
            if UnitCanAttack("player", unit) then
                local color = GetDifficultyColor(level)
                self.levelText:SetTextColor(color.r, color.g, color.b)
            else
                self.levelText:SetTextColor(1.0, 0.82, 0.0)
            end
        else
            self.levelText:SetText("??")
        end

        self.portraitFrame:Show()
        self.levelFrame:Show()
        self.healthBar:Show()
        self.manaBar:Show()
		self.frame:Show()
    end
end

-----------------------------------
-- Target of Focus Frame Updates --
-----------------------------------
function ModernFocusFrame:ClearModernToFocusFrame()
    if not self.tofocusGUID and not self.TargetOfFocusFrame:IsShown() then
        return
    end

    self.tofocusGUID = nil
    self.TargetOfFocusFrame:Hide()
    self.tofHealthBar:Hide()
    self.tofPortraitFrame:Hide()
end

function ModernFocusFrame:UpdateModernToFocusFrame()
    if self.tofocusGUID then
        local unit = self.tofocusGUID
        if not UnitExists(unit) then
            self:ClearModernToFocusFrame()
            return
        end

        local name = UnitName(unit)
        self.tofNameText:SetText(name or "Unknown")

        local hp, hpMax = UnitHealth(unit), UnitHealthMax(unit)
        self.tofHealthBar:SetMinMaxValues(0, hpMax)
        self.tofHealthBar:SetValue(hp)

        self.tofHealthBar:SetStatusBarColor(GetHealthBarColor(unit))

        SetPortraitTexture(self.tofPortrait, unit)

		self.tofHealthBar:Show()
		self.tofPortraitFrame:Show()
        self.TargetOfFocusFrame:Show()
    end
end

----------------
-- Frame Size --
----------------
function ModernFocusFrame:LoadScale()
    if not ModernFocusFrameDB then
        ModernFocusFrameDB = {}
    end
    if not ModernFocusFrameDB.scale then
        ModernFocusFrameDB.scale = 1
    end
    self.scale = ModernFocusFrameDB.scale
end

function ModernFocusFrame:SaveScale(newScale)
    ModernFocusFrameDB.scale = newScale
    self.scale = newScale

    if self.frame then
        self.frame:Hide()
        self.frame = nil
    end

	if self.TargetOfFocusFrame then
        self.TargetOfFocusFrame:Hide()
        self.TargetOfFocusFrame = nil
    end

	self:LoadScale()
    self:CreateMainFrame()
    self:CreateHealthBar()
    self:CreateManaBar()
    self:CreateTextElements()
    self:CreatePortrait()
    self:CreateLevelCircle()
    self:CreateCastBar()

	self:CreateTargetOfFocusFrame()
	self:CreateToFPortrait()
	self:CreateToFHealthBar()
	self:CreateToFTextElements()

    self:LoadPosition()

	if self.db.profile.isDraggingEnabled then
        self:EnableDragging()
    end

    self.focusGUID = nil
	self.tofocusGUID = nil
    self:RegisterEvent("UNIT_HEALTH")
    self:RegisterEvent("UNIT_MANA")
    self:RegisterEvent("UNIT_RAGE")
    self:RegisterEvent("UNIT_ENERGY")
    self:RegisterEvent("UNIT_LEVEL")
    self:RegisterEvent("UNIT_CASTEVENT")

    self.frame:SetScript("OnUpdate", function() self:OnUpdate(arg1) end)
end

local originalSaveScale = ModernFocusFrame.SaveScale
function ModernFocusFrame:SaveScale(newScale)
    originalSaveScale(self, newScale)
    self:InitBuffsModule()
    if self.focusGUID then
        self:ScanAndCacheAuras()
    end
end

---------------------------
-- Position and Dragging --
---------------------------
function ModernFocusFrame:LoadPosition()
    local pos = self.db.profile.position
    if type(pos) ~= "table" or not pos[1] or not pos[2] or not pos[3] or not pos[4] then
        pos = { "CENTER", "UIParent", "CENTER", 0, 0 }
        self.db.profile.position = pos
    end
    self.frame:ClearAllPoints()
    self.frame:SetPoint(pos[1], pos[2], pos[3], pos[4], pos[5])
end

function ModernFocusFrame:SavePosition()
    local point, relativeTo, relativePoint, xOfs, yOfs = self.frame:GetPoint()
    if not relativeTo or type(relativeTo) ~= "string" then
        relativeTo = "UIParent"
    end
    self.db.profile.position = { point, relativeTo, relativePoint, xOfs, yOfs }
end

function ModernFocusFrame:EnableDragging()
    self.frame:SetMovable(true)
    self.frame:EnableMouse(true)
    self.frame:RegisterForDrag("LeftButton")

    self.frame:SetScript("OnDragStart", function()
        self.frame:StartMoving()
    end)

    self.frame:SetScript("OnDragStop", function()
        self.frame:StopMovingOrSizing()
        self:SavePosition()
    end)
end

function ModernFocusFrame:DisableDragging()
    self.frame:SetMovable(false)
    self.frame:RegisterForDrag(nil)
    self.frame:SetScript("OnDragStart", nil)
    self.frame:SetScript("OnDragStop", nil)
end

-------------------
-- Focus Casting --
-------------------
-- Utils.lua
-------------------
-- Focus Casting --
-------------------
function ModernFocusFrame:CastOnFocus(spellName)
    if not spellName or spellName == "" then
        DEFAULT_CHAT_FRAME:AddMessage("Usage: /mff cast <spell name>")
        return
    end

    if not self.focusGUID then
        DEFAULT_CHAT_FRAME:AddMessage("No focus target set.")
        return
    end

    local _, originalTargetGUID = UnitExists("target") -- Store the original target GUID
    TargetUnit(self.focusGUID) -- Temporarily target the focus unit
    CastSpellByName(spellName) -- Cast the spell

    if originalTargetGUID then
        TargetUnit(originalTargetGUID) -- Retarget the original target
    else
        ClearTarget() -- If no original target, clear target
    end
end