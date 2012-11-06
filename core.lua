-- Viewda
--	Displays LibPeriodicTable contents
--   Author: ckaotik
--   License: You may use this code - or parts of it - freely as long as you give proper credit. Please do not upload this addon on any kind of addon distribution website. If you got it somewhere else than Curse.com, WoWinterface.com or github.com, please send me a message/write a comment on either of those sites.
--   Disclaimer: I provide no warranty whatsoever for what this addon does or doesn't do, even though I try my best to keep it working ;)

local _, Viewda = ...
_G["Viewda"] = Viewda

-- libraries & variables
local LibQTip = LibStub("LibQTip-1.0")
Viewda.LPT = LibStub("LibPeriodicTable-3.1")
Viewda.Babble = {
	talent = LibStub("LibBabble-TalentTree-3.0"),
	inventory = LibStub("LibBabble-Inventory-3.0"),
	faction = LibStub("LibBabble-Faction-3.0"),
	boss = LibStub("LibBabble-Boss-3.0"),
	zone = LibStub("LibBabble-Zone-3.0"),
	subzone = LibStub("LibBabble-SubZone-3.0"),
}

-- Event Handling
-- ---------------------------------------------------------
local function eventHandler(self, event, ...)
	if event == "ADDON_LOADED" and arg1 == "Viewda" then
		Viewda:Debug("Addon Viewda loaded!")
		Viewda:CheckSettings()
	end
end

-- register events
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
	OnTooltipShow = function(tip)
		if not tip or not tip.AddLine or not tip.AddDoubleLine then return end
		tip:AddLine("Viewda")
		tip:AddDoubleLine(Viewda.locale.leftClickToggle, Viewda.locale.rightClickConfig, 1, 1, 1, 1, 1, 1)
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
tinsert(UISpecialFrames, "ViewdaDisplayFrame")

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
local dragHandle = titleFrame:CreateTitleRegion()
	dragHandle:SetAllPoints(titleFrame)
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

	local sine, cosine = sin(-90 -45), cos(-90 - 45)	-- wanted_angle - 45
	local tex = menuButton:CreateTexture()
		tex:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up")
		tex:SetTexCoord(0.5-sine*0.5, 	0.5+cosine*0.5,
  			0.5+cosine*0.5,	0.5+sine*0.5,
  			0.5-cosine*0.5,	0.5-sine*0.5,
  			0.5+sine*0.5,	0.5-cosine*0.5)
		tex:SetAllPoints()
	menuButton:SetNormalTexture(tex)
	local hitex = menuButton:CreateTexture()
		hitex:SetTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
		hitex:SetTexCoord(0, 0.7, 0.2, 0.5)
		hitex:SetAllPoints()
	menuButton:SetHighlightTexture(hitex)
	local pushtex = menuButton:CreateTexture()
		pushtex:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Down")
		pushtex:SetTexCoord(0.5-sine*0.5, 	0.5+cosine*0.5,
  			0.5+cosine*0.5,	0.5+sine*0.5,
  			0.5-cosine*0.5,	0.5-sine*0.5,
  			0.5+sine*0.5,	0.5-cosine*0.5)
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
local function CreateFilterButton(name, icon, tooltip, isChecked)
	local button = CreateFrame("CheckButton", "ViewdaFilterButton"..name, filters, "ItemButtonTemplate")
	button.name = name
	button:SetCheckedTexture("Interface\\Buttons\\CheckButtonHilight")
	button:GetCheckedTexture():SetBlendMode("ADD")
	button:SetChecked(isChecked)
	Viewda.filter[name] = isChecked
	button:SetScale(0.6)
	button.tipText = tooltip
	button:SetScript("OnClick", function(self, button)
		if self:GetChecked() then
			Viewda.filter[self.name] = true
		else
			Viewda.filter[self.name] = false
		end
		Viewda:Show(Viewda.displayedSet)
	end)
	button:SetScript("OnEnter", Viewda.ShowTooltip)
	button:SetScript("OnLeave", Viewda.HideTooltip)
	SetItemButtonTexture(button, icon)

	return button
end
local pve = CreateFilterButton("pve", "Interface\\Icons\\INV_Misc_Head_Dragon_Blue", "Show PvE Items", true)	-- Spell_Holy_SenseUndead
local pvp = CreateFilterButton("pvp", 	"Interface\\Icons\\INV_Jewelry_TrinketPVP_"..(UnitFactionGroup("player") == "Alliance" and "01" or "02"), "Show PvP Items", true)	-- Achievement_BG_KillXEnemies_GeneralsRoom
local heroic = CreateFilterButton("heroic", 	"Interface\\Icons\\Spell_Shadow_DemonicEmpathy", "Show Heroic Items", false)	-- Spell_Ice_Lament
-- {"low", 	"Interface\\Icons\\INV_Shirt_Blue_01", "Show lower Tier items", true}, -- Spell_Holy_SummonChampion
-- {"high", 	"Interface\\Icons\\INV_Chest_Cloth_65", "Show higher Tier items", true}, -- Spell_Holy_ChampionsBond

pve:SetPoint("LEFT", 16, 0)
pvp:SetPoint("LEFT", _G["ViewdaFilterButtonpve"], "RIGHT", 6, 0)
heroic:SetPoint("LEFT", _G["ViewdaFilterButtonpvp"], "RIGHT", 16, 0)
CreateFilterButton("tank", "Interface\\Icons\\Ability_Warrior_DefensiveStance", "Show Tank items", true):SetPoint("LEFT", _G["ViewdaFilterButtonheroic"], "RIGHT", 16, 0)	-- Ability_Warrior_ShieldMastery
CreateFilterButton("melee", "Interface\\Icons\\Ability_Rogue_ShadowStrikes", "Show Melee items", true):SetPoint("LEFT", _G["ViewdaFilterButtontank"], "RIGHT", 6, 0)
CreateFilterButton("caster", "Interface\\Icons\\Spell_Lightning_LightningBolt01", "Show Caster items", true):SetPoint("LEFT", _G["ViewdaFilterButtonmelee"], "RIGHT", 6, 0)
CreateFilterButton("healer", "Interface\\Icons\\Spell_Shaman_BlessingOfTheEternals", "Show Healer items", true):SetPoint("LEFT", _G["ViewdaFilterButtoncaster"], "RIGHT", 6, 0)

local searchbox = CreateFrame("EditBox", "ViewdaItemsFrameSearchBox", filters)
	searchbox:SetAutoFocus(false)
	searchbox:SetPoint("RIGHT", filters, "RIGHT", -8, 0)
	searchbox:SetWidth(160)
	searchbox:SetHeight(32)
	searchbox:SetFontObject("GameFontNormalSmall")
local left = searchbox:CreateTexture(nil, "BACKGROUND")
	left:SetWidth(8) left:SetHeight(20)
	left:SetPoint("LEFT", -5, 0)
	left:SetTexture("Interface\\Common\\Common-Input-Border")
	left:SetTexCoord(0, 0.0625, 0, 0.625)
local right = searchbox:CreateTexture(nil, "BACKGROUND")
	right:SetWidth(8) right:SetHeight(20)
	right:SetPoint("RIGHT", 0, 0)
	right:SetTexture("Interface\\Common\\Common-Input-Border")
	right:SetTexCoord(0.9375, 1, 0, 0.625)
local center = searchbox:CreateTexture(nil, "BACKGROUND")
	center:SetHeight(20)
	center:SetPoint("RIGHT", right, "LEFT", 0, 0)
	center:SetPoint("LEFT", left, "RIGHT", 0, 0)
	center:SetTexture("Interface\\Common\\Common-Input-Border")
	center:SetTexCoord(0.0625, 0.9375, 0, 0.625)

searchbox:SetScript("OnEscapePressed", searchbox.ClearFocus)
searchbox:SetScript("OnEnterPressed", searchbox.ClearFocus)

searchbox:SetScript("OnEditFocusGained", function(self)
	if not self.searchString then
		self:SetText("")
		self:SetTextColor(1,1,1,1)
	end
end)
searchbox:SetScript("OnEditFocusLost", function(self)
	if self:GetText() == "" then
		self.searchString = nil
		self:SetText(Viewda.locale.search)
		self:SetTextColor(0.75, 0.75, 0.75, 1)
	end
end)
searchbox:SetScript("OnTextChanged", function(self)
	local t = self:GetText()
	self.searchString = (t ~= "" and t ~= Viewda.locale.search) and t:lower() or nil
	Viewda:SearchInCurrentView(self.searchString or "")
end)
searchbox:SetText(Viewda.locale.search)
searchbox:SetTextColor(0.75, 0.75, 0.75, 1)

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
