-- DruidCatBarShift
-- Automatischer Aktionsleisten-Wechsel bei Katzengestalt + Schleichen

local ADDON_NAME = "DruidCatBarShift"

local DEFAULTS = {
    stealthBar = 2,
    normalBar  = 1,
}

local function InitDB()
    if not DruidCatBarShiftDB then DruidCatBarShiftDB = {} end
    if not DruidCatBarShiftDB.stealthBar then DruidCatBarShiftDB.stealthBar = DEFAULTS.stealthBar end
    if not DruidCatBarShiftDB.normalBar  then DruidCatBarShiftDB.normalBar  = DEFAULTS.normalBar  end
end

-- ============================================================
-- Secure State Driver
-- ============================================================
-- ChangeActionBarPage() wird im Kampf blockiert — genau dann bricht Prowl aber
-- meistens (Angriff aus dem Schleichen). Deshalb laeuft der Leistenwechsel komplett
-- im sicheren Kontext ueber das "actionpage"-Attribut DIREKT auf ActionButton1-12:
-- SecureButton_CalculateAction bevorzugt das Button-eigene Attribut, und jede
-- Attribut-Aenderung feuert OnAttributeChanged -> UpdateAction (volles Update,
-- Icons inklusive, auch im Kampf). Beim Sichtbarwerden wird das Attribut auf nil
-- gesetzt -> Blizzards eigene Seiten-Logik (inkl. Katzen-Bonusleiste) greift wieder.
-- Funktioniert identisch auf Anniversary (2.5.6) und Classic Era (1.15).

local driver
local driverSetupPending = false

local function SetupSecureDriver()
    if InCombatLockdown() then driverSetupPending = true; return end
    if not _G["ActionButton1"] then
        print("|cffff5555[DruidCatBarShift]|r ActionButton1 nicht gefunden — bitte Bug melden.")
        return
    end
    if not driver then
        driver = CreateFrame("Frame", "DruidCatBarShiftDriver", nil, "SecureHandlerStateTemplate")
        for i = 1, 12 do
            local btn = _G["ActionButton" .. i]
            if btn then driver:SetFrameRef("btn" .. i, btn) end
        end
        driver:SetAttribute("_onstate-dcbsprowl", [=[
            local page
            if newstate == "stealth" then
                page = self:GetAttribute("stealthpage") or 2
            else
                -- normalpage 1 = Blizzard-Standard (nil hebt den Override auf,
                -- damit Katzen-/Baeren-Bonusleiste wieder normal funktioniert)
                local np = self:GetAttribute("normalpage") or 1
                if np ~= 1 then page = np end
            end
            for i = 1, 12 do
                local btn = self:GetFrameRef("btn" .. i)
                if btn then btn:SetAttribute("actionpage", page) end
            end
        ]=])
    end
    driver:SetAttribute("stealthpage", DruidCatBarShiftDB.stealthBar or DEFAULTS.stealthBar)
    driver:SetAttribute("normalpage",  DruidCatBarShiftDB.normalBar  or DEFAULTS.normalBar)
    UnregisterStateDriver(driver, "dcbsprowl")
    RegisterStateDriver(driver, "dcbsprowl", "[stealth] stealth; nostealth")
end

-- ============================================================
-- Config UI (WoW Style)
-- ============================================================

local configFrame

local function CreateConfigFrame()
    local f = CreateFrame("Frame", "DruidCatBarShiftConfig", UIParent, "BasicFrameTemplateWithInset")
    f:SetSize(300, 210)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetFrameStrata("DIALOG")
    f:Hide()

    f.TitleBg:SetHeight(30)
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.title:SetPoint("LEFT", f.TitleBg, "LEFT", 8, 0)
    f.title:SetText("Druid CatBarShift — Einstellungen")

    -- Stealth Bar Dropdown
    local labelStealth = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelStealth:SetPoint("TOPLEFT", f.InsetBg, "TOPLEFT", 12, -14)
    labelStealth:SetText("Leiste beim Schleichen:")

    local ddStealth = CreateFrame("Frame", "DruidCatBarShiftDDStealth", f, "UIDropDownMenuTemplate")
    ddStealth:SetPoint("TOPLEFT", labelStealth, "BOTTOMLEFT", -15, -2)
    UIDropDownMenu_SetWidth(ddStealth, 160)

    UIDropDownMenu_Initialize(ddStealth, function(self, level)
        for i = 1, 6 do
            local info = UIDropDownMenu_CreateInfo()
            info.text    = "Leiste " .. i
            info.value   = i
            info.checked = (DruidCatBarShiftDB.stealthBar == i)
            info.func    = function(btn)
                DruidCatBarShiftDB.stealthBar = btn.value
                UIDropDownMenu_SetSelectedValue(ddStealth, btn.value)
                UIDropDownMenu_SetText(ddStealth, "Leiste " .. btn.value)
                SetupSecureDriver()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    UIDropDownMenu_SetSelectedValue(ddStealth, DruidCatBarShiftDB.stealthBar)
    UIDropDownMenu_SetText(ddStealth, "Leiste " .. (DruidCatBarShiftDB.stealthBar or DEFAULTS.stealthBar))

    -- Normal Bar Dropdown
    local labelNormal = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelNormal:SetPoint("TOPLEFT", ddStealth, "BOTTOMLEFT", 15, -10)
    labelNormal:SetText("Leiste ohne Schleichen:")

    local ddNormal = CreateFrame("Frame", "DruidCatBarShiftDDNormal", f, "UIDropDownMenuTemplate")
    ddNormal:SetPoint("TOPLEFT", labelNormal, "BOTTOMLEFT", -15, -2)
    UIDropDownMenu_SetWidth(ddNormal, 160)

    UIDropDownMenu_Initialize(ddNormal, function(self, level)
        for i = 1, 6 do
            local info = UIDropDownMenu_CreateInfo()
            info.text    = "Leiste " .. i
            info.value   = i
            info.checked = (DruidCatBarShiftDB.normalBar == i)
            info.func    = function(btn)
                DruidCatBarShiftDB.normalBar = btn.value
                UIDropDownMenu_SetSelectedValue(ddNormal, btn.value)
                UIDropDownMenu_SetText(ddNormal, "Leiste " .. btn.value)
                SetupSecureDriver()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    UIDropDownMenu_SetSelectedValue(ddNormal, DruidCatBarShiftDB.normalBar)
    UIDropDownMenu_SetText(ddNormal, "Leiste " .. (DruidCatBarShiftDB.normalBar or DEFAULTS.normalBar))

    configFrame = f
end

local function ToggleConfig()
    if not configFrame then CreateConfigFrame() end
    if configFrame:IsShown() then
        configFrame:Hide()
    else
        -- Dropdowns auf aktuelle Werte refreshen
        if _G["DruidCatBarShiftDDStealth"] then
            UIDropDownMenu_SetText(_G["DruidCatBarShiftDDStealth"], "Leiste " .. DruidCatBarShiftDB.stealthBar)
        end
        if _G["DruidCatBarShiftDDNormal"] then
            UIDropDownMenu_SetText(_G["DruidCatBarShiftDDNormal"], "Leiste " .. DruidCatBarShiftDB.normalBar)
        end
        configFrame:Show()
    end
end

-- ============================================================
-- Events
-- ============================================================

local frame = CreateFrame("Frame", "DruidCatBarShiftFrame", UIParent)
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")

frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        InitDB()
        SetupSecureDriver()
        print("|cff00ccff[DruidCatBarShift]|r geladen — |cffffd100/dcbs|r fuer Einstellungen.")
    elseif event == "PLAYER_REGEN_ENABLED" and driverSetupPending then
        driverSetupPending = false
        SetupSecureDriver()
    end
end)

SLASH_DRUIDCATBARSHIFT1 = "/dcbs"
SlashCmdList["DRUIDCATBARSHIFT"] = function()
    ToggleConfig()
end
