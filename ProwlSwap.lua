local ADDON_NAME = "ProwlSwap"

-- Cat Form ist in TBC Gestalt-Index 3
local CAT_FORM_INDEX = 3

-- Prowl-Auraname auf DE und EN
local PROWL_AURA = {
    ["Schleichen"] = true,
    ["Prowl"]      = true,
}

local BAR_STEALTH = 2
local BAR_NORMAL  = 1

local wasInStealthCat = false

local function IsInCatStealth()
    if GetShapeshiftForm() ~= CAT_FORM_INDEX then
        return false
    end
    for i = 1, 40 do
        local name = UnitBuff("player", i)
        if not name then break end
        if PROWL_AURA[name] then
            return true
        end
    end
    return false
end

local function UpdateBar()
    local inStealthCat = IsInCatStealth()

    if inStealthCat and not wasInStealthCat then
        ChangeActionBarPage(BAR_STEALTH)
    elseif not inStealthCat and wasInStealthCat then
        ChangeActionBarPage(BAR_NORMAL)
    end

    wasInStealthCat = inStealthCat
end

local frame = CreateFrame("Frame", "ProwlSwapFrame", UIParent)
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
frame:RegisterEvent("UNIT_AURA")

frame:SetScript("OnEvent", function(self, event, unit)
    if event == "UNIT_AURA" and unit ~= "player" then return end
    UpdateBar()
end)
