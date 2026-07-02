-- DruidCatBarShift
-- Automatischer Aktionsleisten-Wechsel bei Katzengestalt + Schleichen

local ADDON_NAME = "DruidCatBarShift"

local DEFAULTS = {
    stealthBar = 2,
    normalBar  = 1,
}

local CAT_FORM_INDEX = 3

local PROWL_AURA = {
    ["Schleichen"] = true,
    ["Prowl"]      = true,
}

local wasInStealthCat = false

local function InitDB()
    if not DruidCatBarShiftDB then DruidCatBarShiftDB = {} end
    if not DruidCatBarShiftDB.stealthBar then DruidCatBarShiftDB.stealthBar = DEFAULTS.stealthBar end
    if not DruidCatBarShiftDB.normalBar  then DruidCatBarShiftDB.normalBar  = DEFAULTS.normalBar  end
end

local function IsInCatStealth()
    if GetShapeshiftForm() ~= CAT_FORM_INDEX then return false end
    for i = 1, 40 do
        local name = UnitBuff("player", i)
        if not name then break end
        if PROWL_AURA[name] then return true end
    end
    return false
end

local function UpdateBar()
    local inStealthCat = IsInCatStealth()
    if inStealthCat and not wasInStealthCat then
        ChangeActionBarPage(DruidCatBarShiftDB.stealthBar)
    elseif not inStealthCat and wasInStealthCat then
        ChangeActionBarPage(DruidCatBarShiftDB.normalBar)
    end
    wasInStealthCat = inStealthCat
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

-- Verzögerter Check nach Spell-Cast (UNIT_AURA feuert bevor Prowl aus UnitBuff entfernt ist)
local pendingCheck = false
local pendingTimer = 0

local frame = CreateFrame("Frame", "DruidCatBarShiftFrame", UIParent)
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
frame:RegisterEvent("UNIT_AURA")
frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

frame:SetScript("OnEvent", function(self, event, unit)
    if event == "PLAYER_LOGIN" then
        InitDB()
        print("|cff00ccff[DruidCatBarShift]|r geladen — |cffffd100/dcbs|r fuer Einstellungen.")
        return
    end
    if event == "UNIT_AURA" and unit ~= "player" then return end
    if event == "UNIT_SPELLCAST_SUCCEEDED" and unit ~= "player" then return end
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        -- Spell könnte Schleichen brechen — nach kurzer Verzögerung prüfen
        pendingCheck = true; pendingTimer = 0; return
    end
    UpdateBar()
end)

frame:SetScript("OnUpdate", function(self, elapsed)
    if not pendingCheck then return end
    pendingTimer = pendingTimer + elapsed
    if pendingTimer >= 0.15 then
        pendingCheck = false; pendingTimer = 0
        UpdateBar()
    end
end)

SLASH_DRUIDCATBARSHIFT1 = "/dcbs"
SlashCmdList["DRUIDCATBARSHIFT"] = function()
    ToggleConfig()
end
