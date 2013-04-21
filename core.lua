local _, Viewda = ...

-- GLOBALS: SEARCH
-- GLOBALS: CreateFrame, PlaySound, SetItemButtonTexture, EditBox_ClearFocus, InterfaceOptionsFrame_OpenToCategory, UIDropDownMenu_GetText, FauxScrollFrame_OnVerticalScroll
-- GLOBALS: string

-- libraries & variables
Viewda.LPT = LibStub("LibPeriodicTable-3.1")
Viewda.Babble = {
	talent = 	LibStub("LibBabble-TalentTree-3.0"),
	inventory = LibStub("LibBabble-Inventory-3.0"),
	faction = 	LibStub("LibBabble-Faction-3.0"),
	boss = 		LibStub("LibBabble-Boss-3.0"),
	zone = 		LibStub("LibBabble-Zone-3.0"),
	subzone = 	LibStub("LibBabble-SubZone-3.0"),
}

-- Event Handling
-- ---------------------------------------------------------
local function eventHandler(self, event, arg1, ...)
	if event == "ADDON_LOADED" and arg1 == "Viewda" then
		Viewda:Debug("Addon Viewda loaded!")
		Viewda:CheckSettings()
	end
end
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", eventHandler)

-- LDB Plugin
-- ---------------------------------------------------------
-- notation mix-up for B2FB to work
local LDB = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("Viewda", {
	type	= "launcher",
	icon	= "Interface\\Icons\\Ability_Hunter_SilentHunter",
	label	= "Viewda",

	OnClick = function(self, button)
		if button == "RightButton" then
			-- open config
			InterfaceOptionsFrame_OpenToCategory(Viewda.options)
		else
			-- toggle display frame
			if Viewda.mainFrame:IsShown() then
				Viewda.mainFrame:Hide()
			else
				Viewda.mainFrame:Show()
			end
		end
	end,
})

-- Display Frame
-- ---------------------------------------------------------
Viewda.mainFrame = CreateFrame("Frame", "ViewdaDisplayFrame", UIParent)
Viewda.mainFrame:SetFrameStrata("MEDIUM")
Viewda.mainFrame:SetFrameLevel(10)
Viewda.mainFrame:SetBackdrop({
	bgFile = "Interface\\AchievementFrame\\UI-Achievement-StatsBackground",
	tile = false,
	edgeFile = "Interface\\AchievementFrame\\UI-Achievement-WoodBorder",
	edgeSize = 16,
})
Viewda.mainFrame:EnableMouse(true)
Viewda.mainFrame:SetWidth(400)
Viewda.mainFrame:SetHeight(500)
Viewda.mainFrame:Hide()

-- close with ESC
table.insert(UISpecialFrames, "ViewdaDisplayFrame")

local titleFrame = CreateFrame("Frame", nil, Viewda.mainFrame)
	titleFrame:SetPoint("CENTER", UIParent, "CENTER", 0, Viewda.mainFrame:GetHeight() / 2)
	titleFrame:SetHeight(30)
-- handle
local titleText = titleFrame:CreateFontString(nil, "ARTWORK", "AchievementPointsFont")
	titleText:SetPoint("BOTTOMRIGHT", titleFrame, "BOTTOMRIGHT", -22, 2)
	titleText:SetPoint("BOTTOMLEFT", titleFrame, "BOTTOMLEFT", 2, 2)
	titleText:SetText("Viewda "..GetAddOnMetadata("Viewda", "Version"))
-- show close button
local closeButton = CreateFrame("Button", "ViewdaDisplayFrame_CloseButton", titleFrame, "UIPanelCloseButton")
	closeButton:SetWidth(32)
	closeButton:SetHeight(32)
	closeButton:SetPoint("RIGHT", titleFrame, "RIGHT", 8, -3)
	closeButton:SetScript("OnClick", function(...) Viewda.mainFrame:Hide() end)

-- background for titleFrame
local center = Viewda.mainFrame:CreateTexture("$parentCenter")
	center:SetTexture("Interface\\QuestFrame\\UI-QuestLogSortTab-Middle")
	center:SetPoint("BOTTOMLEFT", titleFrame)
	center:SetPoint("TOPRIGHT", titleFrame)
local left = Viewda.mainFrame:CreateTexture("$parentLeft")
	left:SetTexture("Interface\\QuestFrame\\UI-QuestLogSortTab-Left")
	left:SetPoint("BOTTOMRIGHT", center, "BOTTOMLEFT")
	left:SetPoint("TOPRIGHT", center, "TOPLEFT")
	left:SetWidth(5)
local right = Viewda.mainFrame:CreateTexture("$parentRight")
	right:SetTexture("Interface\\QuestFrame\\UI-QuestLogSortTab-Right")
	right:SetPoint("BOTTOMLEFT", center, "BOTTOMRIGHT")
	right:SetPoint("TOPLEFT", center, "TOPRIGHT")
	right:SetWidth(5)

titleFrame:SetHeight(titleText:GetHeight() + 8)
titleFrame:SetWidth(titleText:GetWidth() + 4 + 32 + 2)
titleFrame:EnableMouse(true)
titleFrame:CreateTitleRegion():SetAllPoints(titleFrame)

Viewda.mainFrame:SetPoint("TOP", titleFrame, "BOTTOM")
Viewda.mainFrame:SetClampedToScreen(true)
Viewda.mainFrame:SetToplevel(true)

-- header and stuff
local header = CreateFrame("Frame", "ViewdaHeaderBar", Viewda.mainFrame)
header:SetPoint("TOPLEFT", Viewda.mainFrame)
header:SetPoint("BOTTOMRIGHT", Viewda.mainFrame, "TOPRIGHT", 0, -30)
header:SetBackdrop({
	edgeFile = "Interface\\AchievementFrame\\UI-Achievement-WoodBorder",
	edgeSize = 16,
})

local menuButton = CreateFrame("Button", nil, header)
menuButton:SetPoint("LEFT", header, "LEFT", 4)
menuButton:SetWidth(24)
menuButton:SetHeight(24)
menuButton.tipText = Viewda.locale.tooltipMenuButton

local sine, cosine = sin(-90 - 45), cos(-90 - 45)	-- wanted_angle - 45
local rot1, rot2, rot3, rot4, rot5, rot6, rot7, rot8 = 0.5-sine*0.5, 	0.5+cosine*0.5, 0.5+cosine*0.5,	0.5+sine*0.5, 0.5-cosine*0.5,	0.5-sine*0.5, 0.5+sine*0.5,	0.5-cosine*0.5

local tex = menuButton:CreateTexture()
	tex:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up")
	tex:SetTexCoord(rot1, rot2, rot3, rot4, rot5, rot6, rot7, rot8)
	tex:SetAllPoints()
menuButton:SetNormalTexture(tex)
local hitex = menuButton:CreateTexture()
	hitex:SetTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
	hitex:SetTexCoord(0, 0.7, 0.2, 0.5)
	hitex:SetAllPoints()
menuButton:SetHighlightTexture(hitex)
local pushtex = menuButton:CreateTexture()
	pushtex:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Down")
	pushtex:SetTexCoord(rot1, rot2, rot3, rot4, rot5, rot6, rot7, rot8)
	pushtex:SetAllPoints()
menuButton:SetPushedTexture(pushtex)

menuButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
menuButton:SetScript("OnEnter", Viewda.ShowTooltip)
menuButton:SetScript("OnLeave", Viewda.HideTooltip)
menuButton:SetScript("OnClick", function(self, button)
	if button == "LeftButton" then
		local setName = string.match(UIDropDownMenu_GetText(Viewda.dropDown), "(.-)%.[^%.]*$")
		Viewda:Show(setName)
	elseif button == "RightButton" then
		Viewda:Show()
	end
end)

local dropDown = Viewda:CreateDropdown(header)
	dropDown:SetPoint("LEFT", menuButton, "RIGHT", -15, 0)
	UIDropDownMenu_SetText(dropDown, Viewda.locale.selectionButtonText)
	UIDropDownMenu_SetWidth(dropDown, 350)
	UIDropDownMenu_JustifyText(dropDown, "CENTER")
Viewda.dropDown = dropDown

local filters = CreateFrame("Frame", "ViewdaFilterBar", Viewda.mainFrame)
	filters:SetPoint("BOTTOMLEFT", Viewda.mainFrame)
	filters:SetPoint("TOPRIGHT", Viewda.mainFrame, "BOTTOMRIGHT", 0, 40)	-- -> height :: 30
	filters:SetBackdrop({
		edgeFile = "Interface\\AchievementFrame\\UI-Achievement-WoodBorder",
		edgeSize = 16,
	})

Viewda.filter = {}
local function CreateFilterButton(name, icon, tooltip, isChecked, ...)
	local button = CreateFrame("CheckButton", "$parent"..name, filters, "ItemButtonTemplate")
	SetItemButtonTexture(button, icon)
	button:SetCheckedTexture("Interface\\Buttons\\CheckButtonHilight")
	button:GetCheckedTexture():SetBlendMode("ADD")
	button:SetChecked(isChecked)
	button:SetScale(0.6)
	button.name = name
	button.tipText = tooltip

	button:SetScript("OnEnter", Viewda.ShowTooltip)
	button:SetScript("OnLeave", Viewda.HideTooltip)
	button:SetScript("OnClick", function(self, button)
		if self:GetChecked() then
			Viewda.filter[self.name] = true
		else
			Viewda.filter[self.name] = false
		end
		Viewda:Show(Viewda.displayedSet)
	end)
	Viewda.filter[name] = isChecked

	if ... then
		button:SetPoint(...)
	end

	return button
end

CreateFilterButton("pve", "Interface\\Icons\\INV_Misc_Head_Dragon_Blue",
	"Show PvE Items", true,
	"LEFT", 16, 0)
CreateFilterButton("pvp", "Interface\\Icons\\INV_Jewelry_TrinketPVP_"..(UnitFactionGroup("player") == "Alliance" and "01" or "02"),
	"Show PvP Items", true,
	"LEFT", "$parentpve", "RIGHT", 6, 0)
CreateFilterButton("heroic", "Interface\\Icons\\Spell_Shadow_DemonicEmpathy",
	"Show Heroic Items", false,
	"LEFT", "$parentpvp", "RIGHT", 16, 0)
CreateFilterButton("tank", "Interface\\Icons\\Ability_Warrior_DefensiveStance",
	"Show Tank items", true,
	"LEFT", "$parentheroic", "RIGHT", 16, 0)
CreateFilterButton("melee", "Interface\\Icons\\Ability_Rogue_ShadowStrikes",
	"Show Melee items", true,
	"LEFT", "$parenttank", "RIGHT", 6, 0)
CreateFilterButton("caster", "Interface\\Icons\\Spell_Lightning_LightningBolt01",
	"Show Caster items", true,
	"LEFT", "$parentmelee", "RIGHT", 6, 0)
CreateFilterButton("healer", "Interface\\Icons\\Spell_Shaman_BlessingOfTheEternals",
	"Show Healer items", true,
	"LEFT", "$parentcaster", "RIGHT", 6, 0)
-- {"low", 	"Interface\\Icons\\INV_Shirt_Blue_01", "Show lower Tier items", true},
-- {"high", 	"Interface\\Icons\\INV_Chest_Cloth_65", "Show higher Tier items", true},
-- Spell_Holy_SenseUndead, Achievement_BG_KillXEnemies_GeneralsRoom, Spell_Ice_Lament, Spell_Holy_SummonChampion, Spell_Holy_ChampionsBond, Ability_Warrior_ShieldMastery

local searchbox = CreateFrame("EditBox", "$parentSearchBox", Viewda.mainFrame, "SearchBoxTemplate")
searchbox:SetPoint("RIGHT", filters, "RIGHT", -8, 0)
searchbox:SetSize(120, 20)

searchbox:SetScript("OnEnterPressed", EditBox_ClearFocus)
searchbox:SetScript("OnEscapePressed", function(self)
	self:SetText(SEARCH)
	PlaySound("igMainMenuOptionCheckBoxOn")
	EditBox_ClearFocus(self)
end)
searchbox:SetScript("OnTextChanged", function(self)
	local text = self:GetText()
	local oldText = self.searchString

	if text == "" or text == SEARCH then
		self.searchString = nil
	else
		self.searchString = string.lower(text)
	end

	if oldText ~= self.searchString then
		Viewda:SearchInCurrentView(self.searchString or "")
	end
end)
searchbox.clearFunc = function(self)
	Viewda:SearchInCurrentView(self.searchString or "")
end

-- actual content
Viewda.scrollFrame = CreateFrame("ScrollFrame", "Viewda_ScrollFrame", Viewda.mainFrame, "FauxScrollFrameTemplate")
Viewda.scrollFrame:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 6, 0)
Viewda.scrollFrame:SetPoint("BOTTOMRIGHT", filters, "TOPRIGHT", -28, 0)

Viewda.scrollFrame.rowHeight = 4+37+12 +4	-- top + icon + extra line + bottom
Viewda.scrollFrame.numRows = 7
Viewda.scrollFrame.numPerRow = 2
Viewda.scrollFrame:SetScript("OnVerticalScroll", function(frame, offset)
	FauxScrollFrame_OnVerticalScroll(frame, offset, frame.rowHeight, Viewda.UpdateDisplay)
end)

-- show overview
Viewda:Show()

-- -----------
-- Whishlist: Create a regular styles frame that shows entries like gnomishvendorshrinker
-- <Frame name="CharacterFrame" toplevel="true" movable="true" parent="UIParent" hidden="true" inherits="ButtonFrameTemplate">
-- foo = CreateFrame("Frame", "LPTBrowser", UIParent, "ButtonFrameTemplate")
--[[
foo:EnableMouse()
foo:SetWidth(646)
foo:Hide()
foo:SetAttribute("UIPanelLayout-defined", true)
foo:SetAttribute("UIPanelLayout-enabled", true)
foo:SetAttribute("UIPanelLayout-whileDead", true)
foo:SetAttribute("UIPanelLayout-area", "left")
foo:SetAttribute("UIPanelLayout-pushable", 5)
foo:SetAttribute("UIPanelLayout-width", 646)
foo:SetAttribute("UIPanelLayout-height", 468)

ButtonFrameTemplate_HideAttic(frame)
ButtonFrameTemplate_HideButtonBar(frame)
SetPortraitToTexture(frame:GetName().."Portrait", "Interface\\Icons\\Achievement_BG_trueAVshutout")
frame.TitleText:SetText("TopFit")
]]
--[[ <CheckButton parentKey="LFGBonusRepButton" motionScriptsWhileDisabled="true">
  <Size x="16" y="16"/>
  <Anchors>
    <Anchor point="RIGHT" relativeTo="$parentBackground" relativePoint="LEFT" x="-2" y="0"/>
  </Anchors>
  <NormalTexture file="Interface\Common\ReputationStar">
    <TexCoords left="0.5" right="1" top="0" bottom="0.5"/>
  </NormalTexture>
  <HighlightTexture file="Interface\Common\ReputationStar">
    <TexCoords left="0" right="0.5" top="0.5" bottom="1"/>
  </HighlightTexture>
  <CheckedTexture file="Interface\Common\ReputationStar">
    <TexCoords left="0" right="0.5" top="0" bottom="0.5"/>
  </CheckedTexture>
  <Scripts>
    <OnEnter>
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
      GameTooltip:SetText(LFG_BONUS_REPUTATION_TOOLTIP, nil, nil, nil, nil, true);
      GameTooltip:Show();
    </OnEnter>
    <OnLeave function="GameTooltip_Hide"/>
    <OnClick function="ReputationBarLFGBonusRepButton_OnClick"/>
  </Scripts>
</CheckButton> --]]
