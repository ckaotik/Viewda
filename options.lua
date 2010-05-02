local addonName, Viewda = ...

Viewda.options = CreateFrame("Frame", "ViewdaOptionsFrame", InterfaceOptionsFramePanelContainer)
Viewda.options.name = "Viewda"
Viewda.options:Hide()

Viewda.options:SetScript("OnShow", function(self)
	local title, subtitle = LibStub("tekKonfig-Heading").new(self, "Viewda", Viewda.locale.optionsSubTitle)

	local colorByRole = LibStub("tekKonfig-Checkbox").new(self, nil, Viewda.locale.optionsColorByRole, "TOPLEFT", subtitle, "BOTTOMLEFT", -2, -4)
	colorByRole.tiptext = Viewda.locale.optionsColorByRoleTooltip
	colorByRole:SetChecked(VD_GlobalDB.colorByRole)
	local checksound = colorByRole:GetScript("OnClick")
	colorByRole:SetScript("OnClick", function(self)
		checksound(self)
		VD_GlobalDB.colorByRole = not VD_GlobalDB.colorByRole
	end)
	
	local chatMessage_ItemQueried = LibStub("tekKonfig-Checkbox").new(self, nil, Viewda.locale.optionsChatMessageQueried, "TOPLEFT", colorByRole, "BOTTOMLEFT", 0, -4)
	chatMessage_ItemQueried.tiptext = Viewda.locale.optionsChatMessageQueriedTooltip
	chatMessage_ItemQueried:SetChecked(VD_GlobalDB.showChatMessage_Query)
	local checksound = chatMessage_ItemQueried:GetScript("OnClick")
	chatMessage_ItemQueried:SetScript("OnClick", function(self)
		checksound(self)
		VD_GlobalDB.showChatMessage_Query = not VD_GlobalDB.showChatMessage_Query
	end)
	
	local queryOnMouseOver = LibStub("tekKonfig-Checkbox").new(self, nil, Viewda.locale.optionsMouseOverQuery, "TOPLEFT", chatMessage_ItemQueried, "BOTTOMLEFT", 0, -4)
	queryOnMouseOver.tiptext = Viewda.locale.optionsMouseOverQueryTooltip
	queryOnMouseOver:SetChecked(VD_GlobalDB.queryOnMouseover)
	local checksound = queryOnMouseOver:GetScript("OnClick")
	queryOnMouseOver:SetScript("OnClick", function(self)
		checksound(self)
		VD_GlobalDB.queryOnMouseover = not VD_GlobalDB.queryOnMouseover
	end)

	self:SetScript("OnShow", nil)
end)	


InterfaceOptions_AddCategory(Viewda.options)
LibStub("tekKonfig-AboutPanel").new("Viewda", "Viewda")