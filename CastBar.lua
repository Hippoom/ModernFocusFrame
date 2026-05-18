-- CastBar.lua

local ModernFocusFrame = ModernFocusFrame

local DFR_CASTBAR_PATH = "Interface\\AddOns\\ModernFocusFrame\\textures\\dragonflight\\castbar\\"

function ModernFocusFrame:UpdateDragonflightCastBarPosition(force)
    if not self:IsDragonflightStyle() or not self.castBar or not self.healthBar then return end

    local targetOfFocus = self.TargetOfFocusFrame and self.TargetOfFocusFrame:IsShown()
    local buff1 = self.buffFrames and self.buffFrames[1] and self.buffFrames[1]:IsShown()
    local debuff1 = self.debuffFrames and self.debuffFrames[1] and self.debuffFrames[1]:IsShown()

    if not force and self.castBarLayoutTargetOfFocus == targetOfFocus and self.castBarLayoutBuff1 == buff1 and self.castBarLayoutDebuff1 == debuff1 and self.castBarLayoutScale == self.scale then return end
    self.castBarLayoutTargetOfFocus = targetOfFocus
    self.castBarLayoutBuff1 = buff1
    self.castBarLayoutDebuff1 = debuff1
    self.castBarLayoutScale = self.scale

    local y = -24 * self.scale
    if targetOfFocus or buff1 then
        y = y - 25 * self.scale
    end
    if debuff1 then
        y = y - 25 * self.scale
    end

    self.castBar:ClearAllPoints()
    self.castBar:SetPoint("TOPRIGHT", self.healthBar, "BOTTOMRIGHT", 0, y)
end

function ModernFocusFrame:CreateCastBar()
    local backdrop = {
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    }

    -- create the castbar
    self.castBar = CreateFrame("StatusBar", nil, self.frame)
    if self:IsDragonflightStyle() then
        self.castBar:SetWidth(129 * self.scale)
        self.castBar:SetHeight(14 * self.scale)
        self.castBar:SetStatusBarTexture(DFR_CASTBAR_PATH .. "CastingBarStandard3.tga")
    else
        self.castBar:SetPoint("TOPLEFT", self.manaBar, "BOTTOMLEFT", self.frame:GetWidth() * 0.059, -self.frame:GetHeight() * 0.47)
        self.castBar:SetPoint("TOPRIGHT", self.manaBar, "BOTTOMRIGHT", self.frame:GetWidth() * 0.059, -self.frame:GetHeight() * 0.47)
        self.castBar:SetHeight(14 * self.scale)
        self.castBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    end
    self.castBar:SetStatusBarColor(1, .8, 0, 1)
    self.castBar:SetMinMaxValues(0, 1)

    -- create the spell icon
    self.castIconFrame = CreateFrame("Frame", nil, self.castBar)
    self.castIconFrame:SetPoint("RIGHT", self.castBar, "LEFT", 0, 0)
    self.castIconFrame:SetHeight(25 * self.scale) -- ShaguTweaks icon frame size
    self.castIconFrame:SetWidth(25 * self.scale)  -- ShaguTweaks icon frame size
    self.castIcon = self.castIconFrame:CreateTexture(nil, "BACKGROUND")
    self.castIcon:SetPoint("CENTER", 0, 0)
    self.castIcon:SetWidth(19 * self.scale) -- ShaguTweaks icon size
    self.castIcon:SetHeight(19 * self.scale) -- ShaguTweaks icon size
    self.castIconFrame:SetBackdrop(backdrop)
    self.castIconFrame:SetBackdropBorderColor(1,.8,0)

    -- castbar background
    self.castBG = self.castBar:CreateTexture(nil, "BACKGROUND")
    if self:IsDragonflightStyle() then
        self.castBG:SetTexture(DFR_CASTBAR_PATH .. "CastingBarBackground.blp")
    else
        self.castBG:SetTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
        self.castBG:SetVertexColor(.1, .1, 0, .8)
    end
    self.castBG:SetAllPoints(true)

    -- castbar spark
    self.castSpark = self.castBar:CreateTexture(nil, "OVERLAY")
    self.castSpark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    self.castSpark:SetWidth(24 * self.scale) -- ShaguTweaks spark width
    self.castSpark:SetHeight(24 * self.scale) -- ShaguTweaks spark height
    self.castSpark:SetBlendMode("ADD")

    -- castbar border
    self.castBackdrop = CreateFrame("Frame", nil, self.castBar)
    self.castBackdrop:SetFrameLevel(self.castBar:GetFrameLevel())
    if self:IsDragonflightStyle() then
        self.castBackdrop:SetAllPoints(self.castBar)
        self.castBackdropTexture = self.castBackdrop:CreateTexture(nil, "ARTWORK")
        self.castBackdropTexture:SetAllPoints(self.castBackdrop)
        self.castBackdropTexture:SetTexture(DFR_CASTBAR_PATH .. "CastingBarFrame.blp")

        self.castDropShadow = self.castBar:CreateTexture(nil, "BACKGROUND")
        self.castDropShadow:SetWidth(130 * self.scale)
        self.castDropShadow:SetHeight(23 * self.scale)
        self.castDropShadow:SetPoint("TOP", self.castBar, "BOTTOM", 0, 5 * self.scale)
        self.castDropShadow:SetTexture(DFR_CASTBAR_PATH .. "CastingBarFrameDropShadow.blp")
    else
        self.castBackdrop:SetPoint("TOPLEFT", self.castBar, "TOPLEFT", -3 * self.scale, 3 * self.scale)
        self.castBackdrop:SetPoint("BOTTOMRIGHT", self.castBar, "BOTTOMRIGHT", 3 * self.scale, -3 * self.scale)
        self.castBackdrop:SetBackdrop(backdrop)
        self.castBackdrop:SetBackdropBorderColor(1,.8,0)
    end

    -- castbar spellname
    self.castText = self.castBar:CreateFontString(nil, "HIGH", "GameFontWhite")
    if self:IsDragonflightStyle() then
        self.castText:SetPoint("LEFT", self.castBar, "LEFT", 4 * self.scale, -14 * self.scale)
        self.castText:SetPoint("RIGHT", self.castBar, "RIGHT", -4 * self.scale, -14 * self.scale)
    else
        self.castText:SetPoint("CENTER", self.castBar, "CENTER", 0, 0)
    end
    local font, size, opts = self.castText:GetFont()
    self.castText:SetFont(font, (size - 1) * self.scale, "THINOUTLINE")

    self:UpdateDragonflightCastBarPosition(true)
    self.castBar:Hide()
end

function ModernFocusFrame:StartCastBar(spellID, castDuration, isChanneling)
    local spellName, _, spellIcon = SpellInfo(spellID)
    spellName = spellName or "Unknown Spell"

    self.castText:SetText(spellName)
    self.castStartTime = GetTime()
    self.castDuration = castDuration / 1000
    self.isCasting = not isChanneling
    self.isChanneling = isChanneling

    UIFrameFadeRemoveFrame(self.castBar)

    self.castBar:SetMinMaxValues(0, self.castDuration)
    self.castBar:SetValue(isChanneling and self.castDuration or 0)
    self.castBar:SetStatusBarColor(1, 0.8, 0)
    self.castBar:SetAlpha(1)
    self.castBar:Show()

    if spellIcon then
        self.castIcon:SetTexture(spellIcon)
        self.castIcon:Show()
        self.castIconFrame:Show()
    else
        self.castIcon:Hide()
        self.castIconFrame:Hide()
    end
end

function ModernFocusFrame:StopCastBar(failed)
    self.isCasting = false
    self.isChanneling = false

    if failed then
        self.castBar:SetStatusBarColor(1, 0, 0)
        self.castBar:SetAlpha(1)
        UIFrameFadeOut(self.castBar, 0.5, 1, 0)
    else
        UIFrameFadeOut(self.castBar, 0.5, 1, 0)
    end
end