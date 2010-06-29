-- Viewda
--	Displays LibPeriodicTable contents
--   Author: ckaotik
--   License: You may use this code - or parts of it - freely as long as you give proper credit. Please do not upload this addon on any kind of addon distribution website. If you got it somewhere else than Curse.com, WoWinterface.com or github.com, please send me a message/write a comment on either of those sites.
--   Disclaimer: I provide no warranty whatsoever for what this addon does or doesn't do, even though I try my best to keep it working ;)

local _, Viewda = ...

-- libraries & variables
local LibQTip = LibStub("LibQTip-1.0")
Viewda.LPT = LibStub("LibPeriodicTable-3.1")
Viewda.Babble = {
	talent = LibStub("LibBabble-TalentTree-3.0"),
	inventory = LibStub("LibBabble-Inventory-3.0"),
	faction = LibStub("LibBabble-Faction-3.0"),
	boss = LibStub("LibBabble-Boss-3.0"),
	zone = LibStub("LibBabble-Zone-3.0")
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
	bgFile = "Interface\\AchievementFrame\\UI-Achievement-AchievementBackground",
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
-- handle
local titleText = titleFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	titleText:SetPoint("BOTTOMLEFT", titleFrame, "BOTTOMLEFT", 2, 2)
	titleText:SetText("Viewda "..GetAddOnMetadata("Viewda", "Version"))
-- show close button
local closeButton = CreateFrame("Button", "ViewdaDisplayFrame_CloseButton", titleFrame, "UIPanelCloseButton")
	closeButton:SetWidth(32)
	closeButton:SetHeight(32)
	closeButton:SetPoint("LEFT", titleText, "RIGHT", 4, 0)
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

-- header and stuff
local header = CreateFrame("Frame", nil, Viewda.mainFrame)
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
		local setName = string.match(Viewda.selectionButton:GetText(), "(.-)%.[^%.]*$")
		Viewda:Show(setName)
	elseif button == "RightButton" then
		Viewda:Show()
	end
end)

local dropDownToggleButton, dropDownContainer = Viewda:CreateDropdown(header)
	dropDownContainer:SetPoint("LEFT", menuButton, "RIGHT")
	dropDownContainer:SetPoint("RIGHT", header)
Viewda.selectionButton = dropDownToggleButton

-- actual content
Viewda.mainFrame.scrollFrame = CreateFrame("ScrollFrame", "ViewdaDisplayFrameScrollArea", Viewda.mainFrame, "UIPanelScrollFrameTemplate")
	Viewda.mainFrame.scrollFrame:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 6, 0)
	Viewda.mainFrame.scrollFrame:SetPoint("BOTTOMRIGHT", Viewda.mainFrame, "BOTTOMRIGHT", -28, 5)
Viewda.mainFrame.content = CreateFrame("Frame", nil, Viewda.mainFrame.scrollFrame)
	Viewda.mainFrame.content:SetAllPoints()
	Viewda.mainFrame.content:SetHeight(365 - 4)
	Viewda.mainFrame.content:SetWidth(270)
Viewda.mainFrame.scrollFrame:SetScrollChild(Viewda.mainFrame.content)

-- show overview
Viewda:Show()