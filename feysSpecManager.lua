-- =====================================
-- FSM (feys Spec Manager)
-- Wrath of the Lich King 3.3.5 (30300)
-- =====================================

------------------------------------------------
-- CONSTANTS
------------------------------------------------
local PADDING = 6
local ICON = 32
local GAP = 6
local HEADER_H = 20

------------------------------------------------
-- SPEC ICONS
------------------------------------------------
local SPEC_ICONS = {
    PRIEST = {
        holy = "Interface\\Icons\\Spell_Holy_HolyBolt",
        disc = "Interface\\Icons\\Spell_Holy_PowerWordShield",
        shadow = "Interface\\Icons\\Spell_Shadow_ShadowWordPain",
    },
    PALADIN = {
        prot = "Interface\\Icons\\Spell_Holy_DevotionAura",
        holy = "Interface\\Icons\\Spell_Holy_HolyBolt",
        ret  = "Interface\\Icons\\Spell_Holy_AuraOfLight",
    },
    WARRIOR = {
        prot = "Interface\\Icons\\Ability_Warrior_DefensiveStance",
        arms = "Interface\\Icons\\Ability_Warrior_SavageBlow",
        fury = "Interface\\Icons\\Ability_Warrior_InnerRage",
    },
    DEATHKNIGHT = {
        blood  = "Interface\\Icons\\Spell_Deathknight_BloodPresence",
        frost  = "Interface\\Icons\\Spell_Deathknight_FrostPresence",
        unholy = "Interface\\Icons\\Spell_Deathknight_UnholyPresence",
    },
    DRUID = {
        bear    = "Interface\\Icons\\Ability_Racial_BearForm",
        cat     = "Interface\\Icons\\Ability_Druid_CatForm",
        resto   = "Interface\\Icons\\Spell_Nature_HealingTouch",
        balance = "Interface\\Icons\\Spell_Nature_StarFall",
    },
    SHAMAN = {
        resto = "Interface\\Icons\\Spell_Nature_HealingWaveGreater",
        ele   = "Interface\\Icons\\Spell_Nature_Lightning",
        enh   = "Interface\\Icons\\Spell_Nature_LightningShield",
    },
    HUNTER = {
        bm   = "Interface\\Icons\\Ability_Hunter_BeastTaming",
        mm   = "Interface\\Icons\\Ability_Marksmanship",
        surv = "Interface\\Icons\\Ability_Hunter_SwiftStrike",
    },
    ROGUE = {
        as       = "Interface\\Icons\\Ability_Rogue_Eviscerate",
        combat   = "Interface\\Icons\\Ability_BackStab",
        subtlety = "Interface\\Icons\\Ability_Stealth",
    },
    MAGE = {
        arcane = "Interface\\Icons\\Spell_Holy_MagicalSentry",
        fire   = "Interface\\Icons\\Spell_Fire_FireBolt02",
        frost  = "Interface\\Icons\\Spell_Frost_FrostBolt02",
    },
    WARLOCK = {
        affli  = "Interface\\Icons\\Spell_Shadow_DeathCoil",
        demo   = "Interface\\Icons\\Spell_Shadow_Metamorphosis",
        destro = "Interface\\Icons\\Spell_Shadow_RainOfFire",
    },
}

------------------------------------------------
-- CLASS SPECS
------------------------------------------------
local CLASS_SPECS = {
    PRIEST = {"holy","disc","shadow"},
    PALADIN = {"prot","holy","ret"},
    WARRIOR = {"prot","arms","fury"},
    DEATHKNIGHT = {"blood","frost","unholy"},
    DRUID = {"bear","cat","resto","balance"},
    SHAMAN = {"resto","ele","enh"},
    HUNTER = {"bm","mm","surv"},
    ROGUE = {"as","combat","subtlety"},
    MAGE = {"arcane","fire","frost"},
    WARLOCK = {"affli","demo","destro"},
}

------------------------------------------------
-- HELPERS
------------------------------------------------
local function Exec(spec, mode)
    SendChatMessage("talents spec "..spec.." "..mode, "WHISPER", nil, UnitName("target"))
end

local function Pretty(text)
    return text:sub(1,1):upper() .. text:sub(2)
end

------------------------------------------------
-- MAIN FRAME
------------------------------------------------
local frame = CreateFrame("Frame", "FSMFrame", UIParent)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:Hide()

frame:SetBackdrop({
    bgFile="Interface\\Buttons\\WHITE8x8",
    edgeFile="Interface\\Buttons\\WHITE8x8",
    edgeSize=1,
})
frame:SetBackdropColor(0.05,0.05,0.05,0.95)
frame:SetBackdropBorderColor(0.25,0.25,0.25,1)

------------------------------------------------
-- HEADER
------------------------------------------------
local title = frame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
title:SetPoint("TOPLEFT",PADDING,-PADDING)
title:SetText("|cffffcc00FSM|r")

local classText = frame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
classText:SetPoint("TOPRIGHT",-PADDING,-PADDING)

------------------------------------------------
-- AUTOGEAR BUTTON (ELVUI STYLE)
------------------------------------------------
local autogear = CreateFrame("Button", nil, frame)
autogear:SetSize(72, 16)
autogear:SetPoint("TOPRIGHT", classText, "BOTTOMRIGHT", 0, -4)

autogear:SetBackdrop({
    bgFile="Interface\\Buttons\\WHITE8x8",
    edgeFile="Interface\\Buttons\\WHITE8x8",
    edgeSize=1,
})
autogear:SetBackdropColor(0.15,0.15,0.15,1)
autogear:SetBackdropBorderColor(0.3,0.3,0.3,1)

autogear.text = autogear:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
autogear.text:SetPoint("CENTER")
autogear.text:SetText("Autogear")

autogear:SetScript("OnEnter", function(self)
    self:SetBackdropColor(0.25,0.25,0.25,1)
end)
autogear:SetScript("OnLeave", function(self)
    self:SetBackdropColor(0.15,0.15,0.15,1)
end)
autogear:SetScript("OnClick", function()
    SendChatMessage("autogear","PARTY")
end)

------------------------------------------------
-- MODE LABELS
------------------------------------------------
local pveLabel = frame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
pveLabel:SetText("PVE:")

local pvpLabel = frame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
pvpLabel:SetText("PVP:")

------------------------------------------------
-- SPEC BUTTONS
------------------------------------------------
local buttons = {}

local function GetButton(i)
    if buttons[i] then return buttons[i] end
    local b = CreateFrame("Button", nil, frame)
    b:SetSize(ICON, ICON)

    b.icon = b:CreateTexture(nil,"ARTWORK")
    b.icon:SetAllPoints()

    buttons[i] = b
    return b
end

------------------------------------------------
-- UPDATE UI
------------------------------------------------
local function UpdateUI()
    for _,b in ipairs(buttons) do b:Hide() end

if not UnitExists("target") or not UnitIsPlayer("target") then
    classText:SetText("no target")

    pveLabel:Hide()
    pvpLabel:Hide()
    autogear:Hide()

    -- tighter idle height (no dead space)
    frame:SetSize(200, HEADER_H + 4)

    return
end

    pveLabel:Show()
    pvpLabel:Show()
    autogear:Show()

    local _, class = UnitClass("target")
    local specs = CLASS_SPECS[class]
    local icons = SPEC_ICONS[class]
    if not specs or not icons then return end

    classText:SetText(class)

    local y = -HEADER_H - PADDING
    local index = 1

    -- PVE
    pveLabel:SetPoint("TOPLEFT", PADDING, y)
    y = y - 18

    for i,spec in ipairs(specs) do
        local b = GetButton(index)
        b.icon:SetTexture(icons[spec])

        b:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING + (i-1)*(ICON+GAP), y)

        b:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(Pretty(spec).." (PVE)",1,1,1)
            GameTooltip:AddLine("Click to assign spec",0.8,0.8,0.8)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", GameTooltip_Hide)
        b:SetScript("OnClick", function() Exec(spec,"pve") end)

        b:Show()
        index = index + 1
    end

    y = y - ICON - GAP

    -- PVP
    pvpLabel:SetPoint("TOPLEFT", PADDING, y)
    y = y - 18

    for i,spec in ipairs(specs) do
        local b = GetButton(index)
        b.icon:SetTexture(icons[spec])

        b:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING + (i-1)*(ICON+GAP), y)

        b:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(Pretty(spec).." (PVP)",1,1,1)
            GameTooltip:AddLine("Click to assign spec",0.8,0.8,0.8)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", GameTooltip_Hide)
        b:SetScript("OnClick", function() Exec(spec,"pvp") end)

        b:Show()
        index = index + 1
    end

    local cols = #specs
    frame:SetSize(
        PADDING*2 + (cols*ICON) + ((cols-1)*GAP),
        HEADER_H + ICON*2 + 54
    )
end

------------------------------------------------
-- LAUNCHER
------------------------------------------------
local launcher = CreateFrame("Button","FSMLauncher",UIParent)
launcher:SetSize(28,28)
launcher:SetPoint("CENTER",UIParent,"CENTER",-200,0)
launcher:SetMovable(true)
launcher:EnableMouse(true)
launcher:RegisterForDrag("LeftButton")
launcher:SetScript("OnDragStart",launcher.StartMoving)
launcher:SetScript("OnDragStop",launcher.StopMovingOrSizing)

launcher:SetBackdrop({
    bgFile="Interface\\Buttons\\WHITE8x8",
    edgeFile="Interface\\Buttons\\WHITE8x8",
    edgeSize=1,
})
launcher:SetBackdropColor(0.1,0.1,0.1,1)
launcher:SetBackdropBorderColor(0.35,0.35,0.35,1)

launcher.text = launcher:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
launcher.text:SetPoint("CENTER")
launcher.text:SetText("|cffffcc00FSM|r")

launcher:SetScript("OnClick", function()
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
        UpdateUI()
    end
end)

------------------------------------------------
-- EVENTS
------------------------------------------------
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:SetScript("OnEvent", UpdateUI)
