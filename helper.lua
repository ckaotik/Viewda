_, Viewda = ...

local debug = false

-- Saved Variables
-- --------------------------------------------------------
-- check if all saved variables exist
function Viewda:CheckSettings()
	-- check for settings
	if not VD_GlobalDB then VD_GlobalDB = {} end
	for key, value in pairs(Viewda.defaultGlobalSettings) do
		if VD_GlobalDB[key] == nil then
			VD_GlobalDB[key] = value
		end
	end
	
	if not VD_LocalDB then VD_LocalDB = {} end
	for key, value in pairs(Viewda.defaultLocalSettings) do
		if VD_LocalDB[key] == nil then
			VD_LocalDB[key] = value
		end
	end
end

Viewda:CheckSettings()

-- Helper Functions
-- --------------------------------------------------------
-- Prints a message to the DEFAULT_CHAT_FRAME with Viewda prefix
function Viewda:Print(text)
	DEFAULT_CHAT_FRAME:AddMessage("|caaee6622Viewda|r "..text)
end

-- prints a debug message
function Viewda:Debug(...)
  if debug then
	Viewda:Print("! "..string.join(", ", tostringall(...)))
  end
end

-- check if a given value can be found in a table
function Viewda:Find(table, value)
	for k, v in pairs(table) do
		if (v == value) then return true end
	end
	return false
end

-- returns saved variables for external use
function Viewda:GetOption(optionName, global)
	--if global == nil then
		--return VD_GlobalDB[optionName], BG_GlobalDB[optionName]
	--elseif global == false then
		--return BG_LocalDB[optionName]
	--else
		--return BG_GlobalDB[optionName]
	--end
	return VD_GlobalDB[optionName]
end

function Viewda:SetOption(optionName, value)
	if VD_GlobalDB[optionName] then
		VD_GlobalDB[optionName] = value
		return true
	else
		return false
	end
end

function Viewda:ShowTooltip()
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	local itemID = self.itemID or self:GetParent().itemID
	local itemLink = self.itemLink or self:GetParent().itemLink or (itemID and select(2,GetItemInfo(itemID)))
	
	if itemID and self.tipText and self.tipText == Viewda.locale.tooltipQueryServer 
		and VD_GlobalDB.queryOnMouseover and not self.request then
		
		if VD_GlobalDB.showChatMessage_Query then
			Viewda:Print(Viewda.locale.chatQueryServer)
		end
		GameTooltip:SetHyperlink("item:"..itemID..":0:0:0:0:0:0:0")
		
		self.tipText = Viewda.locale.tooltipUpdateIcon
		self.request = true
	
	elseif self.tipText and self.tipText == Viewda.locale.tooltipUpdateIcon and itemLink then
		
		self.request = nil
		self.tipText = nil
		self:GetParent().itemLink = itemLink
		
		GameTooltip:SetHyperlink(itemLink)
		Viewda:UpdateDisplayEntry((self.ID or self:GetParent().ID), itemID, (self.value or self:GetParent().value))
	
    elseif self.tipText then
		GameTooltip:SetText(self.tipText, nil, nil, nil, nil, true)
    elseif itemLink then
		GameTooltip:SetHyperlink(itemLink)
		-- TODO: 5420 doesn't show a tooltip
    end
    GameTooltip:Show()
end

function Viewda:HideTooltip()
	GameTooltip:Hide()
end

-- Item Functions
-- --------------------------------------------------------
-- returns an item's itemID
function Viewda:GetItemID(itemLink)
	if not itemLink then return end
	local itemID = string.gsub(itemLink, ".-Hitem:([0-9]*):.*", "%1")
	return tonumber(itemID)
end

-- returns true if the given item is soulbound
local scanTooltip = CreateFrame('GameTooltip', 'ViewdaItemScan', UIParent, 'GameTooltipTemplate')
function Viewda:IsItemSoulbound(itemLink, bag, slot)
	scanTooltip:SetOwner(UIParent, 'ANCHOR_NONE')
	local searchString
	
	if not (bag and slot) then
		-- check if item is BOP
		scanTooltip:SetHyperlink(itemLink)
		searchString = ITEM_BIND_ON_PICKUP
	else
		-- check if item is soulbound
		scanTooltip:SetBagItem(bag, slot)
		searchString = ITEM_SOULBOUND
	end

	local numLines = scanTooltip:NumLines()
	for i = 1, numLines do
		local leftLine = getglobal("ViewdaItemScan".."TextLeft"..i)
		local leftLineText = leftLine:GetText()
		
		if string.find(leftLineText, searchString) then
			return true
		end
	end
	return false
end

-- returns index in favorites table if itemID is found, nil otherwise
function Viewda:IsFavorite(itemID)
	local found
	for i = 1, #VD_LocalDB.favorites do
		if VD_LocalDB.favorites[i].itemID == itemID or (type(itemID) == "number" and VD_LocalDB.favorites[i].itemID == -1*itemID) then
			found = i
			break
		end
	end
	
	return found
end

-- shorten strings that exceed a length of 'limit'
function Viewda:Shorten(text, limit)
	if not text then return nil end
	if not limit then limit = 100 end
	if string.len(text) > limit then
		text = string.gsub(text, "%s*(.)%S*%s+", "%1. ")
	end
	
	return text
end

-- returns LFD colors
function Viewda:GetRoleColor(itemLink)
	-- only care about equippable items
	local itemSlot = select(9, GetItemInfo(itemLink))
	if not itemSlot or not VD_GlobalDB.colorByRole
		or not string.find(itemSlot, "INVTYPE") or string.find(itemSlot, "BAG") then
		
		return 0, 0, 0
	end

	-- see if we find any clues as for what role this item is intended
	local stats = GetItemStats(itemLink)
	for stat, value in pairs(stats) do
		if stat == "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT"
			or stat == "ITEM_MOD_DODGE_RATING_SHORT"
			or stat == "ITEM_MOD_PARRY_RATING_SHORT"
			or stat == "ITEM_MOD_BLOCK_RATING_SHORT" then
			-- tank item
			return 0, 0.2, 1
		elseif stat == "ITEM_MOD_MANA_REGENERATION_SHORT"
			or stat == "ITEM_MOD_POWER_REGEN0_SHORT" then
			-- heal item
			return 0.1, 0.5, 0.4
		end
	end
	
	-- dps item / don't know
	return 0.4, 0.1, 0.1
end

-- returns a localization of name, or nil if not found
function Viewda:GetLocalizedName(name)
	local data
	for _, lib in pairs(Viewda.Babble) do
		data = lib:GetUnstrictLookupTable()
		if data and data[name] then
			return data[name]
		end
	end
	
	return nil
end

-- function that's called when a list entry is clicked
local function ViewOnClick(self, button)
	local itemLink = self.itemLink or self:GetParent().itemLink
	local itemID = self.itemID or self:GetParent().itemID
	local value = self.value or self:GetParent().value
	
	if IsModifiedClick("CHATLINK") and ChatFrame1EditBox:IsVisible() then
		ChatFrame1EditBox:Insert(itemLink or self.tipText)
	
	elseif IsModifiedClick("DRESSUP") and IsDressableItem(itemLink) then
		DressUpItemLink(itemLink)
	
	elseif button == "RightButton" and not self.request and itemID and not itemLink then
		-- query server
		if VD_GlobalDB.showChatMessage_Query then
			Viewda:Print(Viewda.locale.chatQueryServer)
		end
		GameTooltip:SetHyperlink("item:"..itemID..":0:0:0:0:0:0:0")
		
		self.tipText = Viewda.locale.tooltipUpdateIcon
		self.request = true
	
	elseif button == "RightButton" and self.request then
		-- update display of queried items
		local link = select(2, GetItemInfo(itemID))
		if link then
			self.request = nil
			self.tipText = nil
			self:GetParent().itemLink = itemLink
			Viewda:UpdateDisplayEntry((self.ID or self:GetParent().ID), link, value)
		end
		
	elseif self:GetParent().itemName == Viewda.locale.favorites then
		-- show the favorites display
		Viewda:ShowFavorites()
	
	elseif self:GetParent().type == "category" or Viewda.selectionButton:GetText() == Viewda.locale.favorites then
		-- show content of this category
		Viewda:Show(value)
	
	elseif type(value) == "string" and string.find(value, "x") then
		-- show close-up for this item
		Viewda:ShowCloseUp(itemID, value, Viewda.selectionButton:GetText())
	end
end

-- creates a pretty display for an item/string
function Viewda:CreateDisplayEntry(index, item, value, setName, isSetMulti)
	if not item then return nil	end
	-- display frame
	local entry = CreateFrame("Frame", "ViewdaLootFrameEntry"..index, Viewda.mainFrame.content)
	entry:SetWidth(180)
	entry:SetHeight(4 + 32 + 12 + 4)	-- top + icon + extra line + bottom
	entry:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Background",
		tile = false,
		edgeFile = "Interface\\Addons\\Viewda\\Media\\glow",
		edgeSize = 2,
		insets = {6, 6, 6, 6},
	})
	entry:SetBackdropColor(1, 1, 1, 0.3)
	entry:SetBackdropBorderColor(1, 0.9, 0.5)
	entry.ID = index

	local itemTexture
	-- icon & needed texture for it
	entry.icon = CreateFrame("Button", nil, entry)
	entry.icon:SetPoint("TOPLEFT", entry, "TOPLEFT", 4, -4)
	entry.icon:SetWidth(32)
	entry.icon:SetHeight(32)
	entry.icon:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
	
	entry.icon:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	entry.icon:SetScript("OnClick", ViewOnClick)
	entry.icon:SetScript("OnEnter", Viewda.ShowTooltip)
	entry.icon:SetScript("OnLeave", Viewda.HideTooltip)
	
	-- overlay texture for glow effect (used for role coloring)
	entry.overlay = entry.icon:CreateTexture()
	entry.overlay:SetAllPoints()
	entry.overlay:SetTexture("Interface\\Buttons\\CheckButtonHilight")
	entry.overlay:SetBlendMode("ADD")
	entry.overlay:SetDrawLayer("OVERLAY")
	
	-- favorite icon, used to mark an item
	entry.favicon = CreateFrame("CheckButton", nil, entry)
	entry.favicon:SetPoint("TOP", entry.icon, "BOTTOM", 0, 2)
	entry.favicon:SetNormalTexture("Interface\\AddOns\\Viewda\\Media\\star1")
	entry.favicon:GetNormalTexture():SetDesaturated(not entry.favicon:GetChecked())
	entry.favicon:SetWidth(16)
	entry.favicon:SetHeight(16)
		
	entry.favicon:SetScript("OnClick", function(self, button)
		if not entry.itemID then
			self:SetChecked(not self:GetChecked())
			return
		end
		local isFavorite = Viewda:IsFavorite(entry.itemID)
		if self:GetChecked() then
			self:GetNormalTexture():SetDesaturated(false)
			local found = false
			if not isFavorite then
				tinsert(VD_LocalDB.favorites, {
					itemID = entry.type == "spell" and -1*entry.itemID or entry.itemID,
					type = entry.type,
					set = entry.type == "category" and entry.value or entry.setName
				})
			end
		else
			self:GetNormalTexture():SetDesaturated(true)
			if isFavorite then
				tremove(VD_LocalDB.favorites, isFavorite)
			end
		end
	end)

	entry.text = entry:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	entry.text:SetWidth(entry:GetWidth() - entry.icon:GetWidth() - 2*4)
	entry.text:SetHeight(entry.icon:GetHeight())
	entry.text:SetPoint("TOPLEFT", entry.icon, "TOPRIGHT", 4, 0)
	entry.text:SetJustifyH("LEFT")
	entry.text:SetJustifyV("TOP")
		
	entry.source = entry:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	entry.source:SetPoint("TOPLEFT", entry.icon, "BOTTOMLEFT", 0, 0)
	entry.source:SetPoint("BOTTOMRIGHT", entry, "BOTTOMRIGHT", -4, 4)
	entry.source:SetJustifyH("RIGHT")
	
	-- anchor the whole thing
	if index == 1 then
		entry:SetPoint("TOPLEFT", Viewda.mainFrame.content, "TOPLEFT")
	elseif index % 2 == 0 then
		entry:SetPoint("TOPLEFT", Viewda.items[index-1], "TOPRIGHT", 4, 0)
	else
		entry:SetPoint("TOPLEFT", Viewda.items[index-2], "BOTTOMLEFT", 0, -4)
	end
	tinsert(Viewda.items, entry)
	Viewda:UpdateDisplayEntry(index, item, value, setName, isSetMulti)
end

-- recycles a previously defined frame and fills it with new information
function Viewda:UpdateDisplayEntry(i, item, value, setName, isSetMulti)
	if not item then return end
	local entry = Viewda.items[i]
	local quality, itemTexture, equipSlot, equipType
	
	entry.itemID = item -- type(item) == "number" and item or Viewda:GetItemID(item)
	entry.value = value
	entry.setName = setName
	
	local typ
	if type(isSetMulti) == "string" then
		typ = isSetMulti
	end
	if typ == "category" or isSetMulti == true then
		entry.type = "category"
		entry.itemID = tostring(item)	-- category itemIDs are strings
	
	elseif typ == "item" or (type(entry.itemID) == "number" and entry.itemID == math.abs(entry.itemID)) then
		entry.type = "item"
	
	else
		entry.type = "spell"
		entry.itemID = math.abs(entry.itemID)	-- in LPT, signum negates you!
	end
	
	-- update the icon
	local showFavicon = true
	if entry.type == "category" then
		-- this is a category
		if entry.value == Viewda.locale.favorites then
			itemTexture = "Interface\\AddOns\\Viewda\\Media\\star1"
			showFavicon = false
		else
			itemTexture = "Interface\\Icons\\Ability_EyeOfTheOwl"
		end
		
		entry.itemName = tostring(item)
		entry.itemLink = nil
		entry.icon.tipText = item
	
	elseif entry.type == "spell" then
		-- this is a spell
		local rank
		entry.itemName, rank, itemTexture = GetSpellInfo(entry.itemID)
		entry.itemLink = GetSpellLink(entry.itemID)
		entry.icon.tipText = nil
		
		if rank and rank ~= "" then
			entry.itemName = entry.itemName .. ", " .. rank
		end
	
	else
		-- this is an item
		entry.itemName, entry.itemLink, quality, _, _, _, equipType, _, equipSlot, itemTexture = GetItemInfo(entry.itemID)
		entry.icon.tipText = nil
	end
	
	-- show or hide the favicon
	entry.favicon:SetChecked(Viewda:IsFavorite(entry.itemID) and true or false)
	entry.favicon:GetNormalTexture():SetDesaturated(not entry.favicon:GetChecked())
	if showFavicon and not typ then
		entry.favicon:Show()
	else
		entry.favicon:Hide()
	end
	
	local itemTex
	-- update item texture
	if not itemTexture then
		itemTex = entry.icon:CreateTexture()
		itemTex:SetTexture("Interface\\Spellbook\\UI-Spellbook-SpellBackground")
		itemTex:SetTexCoord(0, 0.68, 0, 0.68)
		itemTex:SetAllPoints()
		
		entry.icon.tipText = Viewda.locale.tooltipQueryServer
	else
		itemTex = entry.icon:CreateTexture()
		itemTex:SetTexture(itemTexture)
		itemTex:SetTexCoord(0, 1, 0, 1)
		itemTex:SetAllPoints()
	end
	entry.icon:SetNormalTexture(itemTex)
	
	-- update the icon overlay
	if entry.itemLink and equipSlot then
		entry.overlay:SetVertexColor(Viewda:GetRoleColor(entry.itemLink))
		entry.overlay:Show()
	else
		entry.overlay:Hide()
	end
	
	-- update the item's texts
	equipType = equipType and Viewda.locale.ShortenItemSlot and Viewda.locale.ShortenItemSlot(equipType) or equipType
	local equipment = (equipType and Viewda.locale.equipLocation[equipSlot] and not typ) and equipType.. ", " .. Viewda.locale.equipLocation[equipSlot]
	local name = Viewda:GetLocalizedName(entry.itemName) or entry.itemName or Viewda.locale.unknown
	local rarityColor = quality and select(4,GetItemQualityColor(quality))
	
	local sourceText = ""
	-- set the text values
	if not value or type(value) == "boolean" or entry.type == "category" then
		sourceText = equipment or ""
	
	elseif string.find(value, "x") then
		sourceText = Viewda.locale.clickForCloseUp
	
	elseif string.find(value, "/") then
		local orange, yellow, green, gray = string.split("/", value)
		sourceText = Viewda.skillColor[1] .. orange .. "|r/" ..
			Viewda.skillColor[2] .. yellow .. "|r/" ..
			Viewda.skillColor[3] .. green .. "|r/" ..
			Viewda.skillColor[4] .. gray .. "|r"
	elseif setName and string.find(setName, "InstanceLoot") then
		sourceText = value/10 .. "%"
	
	else
		sourceText = (equipment and equipment .. ", " or "") .. "|cffED9237" .. value
	end
	
	entry.text:SetText((entry.itemLink and rarityColor or "") .. name)
	entry.source:SetText(sourceText)
	
	entry:Show()
end

-- creates & manages the notice frame
function Viewda:NoticeFrame(text)
	local noticeFrame = _G["ViewdaNoticeFrame"]
	if not noticeFrame then
		noticeFrame = CreateFrame("Frame", "ViewdaNoticeFrame", Viewda.mainFrame.scrollFrame)
		noticeFrame:SetAllPoints()
		noticeFrame:Hide()
		
		noticeFrame.textureTop = noticeFrame:CreateTexture()
		noticeFrame.textureTop:SetParent(noticeFrame)
		noticeFrame.textureTop:SetTexture("Interface\\QuestFrame\\UI-HorizontalBreak")
		noticeFrame.textureTop:SetPoint("TOPLEFT")
		noticeFrame.textureTop:SetPoint("BOTTOMRIGHT", noticeFrame, "TOPRIGHT", 0, -40)
		noticeFrame.textureTop:SetBlendMode("ADD")
		noticeFrame.textureTop:SetVertexColor(1, 1, 1, 1)
		
		noticeFrame.textureBottom = noticeFrame:CreateTexture()
		noticeFrame.textureBottom:SetParent(noticeFrame)
		noticeFrame.textureBottom:SetTexture("Interface\\QuestFrame\\UI-HorizontalBreak")
		-- noticeFrame.textureBottom:SetRotation(math.pi)
		noticeFrame.textureBottom:SetPoint("TOPLEFT", noticeFrame, "BOTTOMLEFT", 0, 40)
		noticeFrame.textureBottom:SetPoint("BOTTOMRIGHT")
		noticeFrame.textureBottom:SetBlendMode("ADD")
		noticeFrame.textureBottom:SetVertexColor(1, 1, 1, 1)
		
		noticeFrame.text = noticeFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightMedium")
		noticeFrame.text:SetPoint("TOPLEFT", noticeFrame.textureTop, "BOTTOMLEFT")
		noticeFrame.text:SetPoint("BOTTOMRIGHT", noticeFrame.textureBottom, "TOPRIGHT")
		noticeFrame.text:SetNonSpaceWrap(true)
		noticeFrame.text:SetJustifyH("CENTER")
		noticeFrame.text:SetJustifyV("TOP")
	end
	
	if not text then
		noticeFrame:Hide()
	else
		noticeFrame:Show()
		noticeFrame.text:SetText(text)
	end
end

-- TODO: enable searching
function Viewda:Search(searchString)
	if type(searchString) == "number" then
		-- PT:ItemSearch(14373)
	else
		-- this. will. hurt.
	end
end

function Viewda:Show(setName)
	local setTable
	if not setName then
		setTable = Viewda.periodicTable
	else
		setTable = Viewda.LPT:GetSetTable(setName)
	end
	
	local totalShown = 0
	if not setName then
		-- show absolute index
		local sortTable = {}
		for subSet, _ in pairs(setTable) do
			tinsert(sortTable, subSet)
		end
		sort(sortTable)
		
		totalShown = #sortTable
		for i = 1, totalShown do
			local subSet = sortTable[i]
			
			if not Viewda.items[i] then
				--						index  item     value    set(?)      isSetMulti
				Viewda:CreateDisplayEntry(i, subSet, subSet, subSet, true)
			else
				Viewda:UpdateDisplayEntry(i, subSet, subSet, subSet, true)
			end
		end
		
		totalShown = totalShown + 1
		if not Viewda.items[totalShown] then
			Viewda:CreateDisplayEntry(totalShown, Viewda.locale.favorites, Viewda.locale.favorites, "Favorites", true)
		else
			Viewda:UpdateDisplayEntry(totalShown, Viewda.locale.favorites, Viewda.locale.favorites, "Favorites", true)
		end
	
	elseif Viewda.LPT:IsSetMulti(setName) then
		-- show sub-categories
		-- TODO: link impossible sets -.-", e.g. ["Tradeskill.Mat.BySource.Gather"]="m,Tradeskill.Gather",
		local sortTable = {}
		for _, subTable in pairs(setTable) do
			local subCategory = strsplit(".", string.sub(subTable.set, strlen(setName)+2))
			if not Viewda:Find(sortTable, subCategory) and (setName == string.sub(subTable.set, 1, strlen(setName))) then
				tinsert(sortTable, subCategory)
			end
		end
		sort(sortTable, function(a,b)
			local locA = Viewda:GetLocalizedName(a) or a
			local locB = Viewda:GetLocalizedName(b) or b
			return locA < locB
		end)
		
		totalShown = #sortTable
		for i = 1, totalShown do
			local subCategory = sortTable[i]
		
			local itemFrame
			if not Viewda.items[i] then
				Viewda:CreateDisplayEntry(i, subCategory, setName.."."..subCategory, setName, true)
			else
				itemFrame = Viewda:UpdateDisplayEntry(i, subCategory, setName.."."..subCategory, setName, true)
			end
		end
	else
		-- show item entries
		local sortTable = {}
		for itemID, value in pairs(setTable) do
			if itemID ~= "set" then
				tinsert(sortTable, {itemID = itemID, value = value})
			end
		end
		sort(sortTable, function(a, b)
			if type(a.value) == "boolean" or type(b.value) == "boolean" then
				return a.itemID < b.itemID
			
			elseif tonumber(a.value) and tonumber(b.value) then
				return tonumber(a.value) < tonumber(b.value)
			
			elseif string.find(a.value, "/") or string.find(b.value, "/") then
				local aTab = { strsplit("/", a.value) }
				local bTab = { strsplit("/", b.value) }
				
				local aVal, bVal
				
				for i = #aTab, 1, -1 do
					aVal = tonumber(aTab[i])
					bVal = tonumber(bTab[i])
					
					if aVal and bVal and aVal ~= bVal then
						return aVal < bVal
					end
				end
				return a.value < b.value
			
			else
				return a.value < b.value
			end
		end)
		
		totalShown = #sortTable
		for i = 1, totalShown do
			local item = sortTable[i].itemID
			local value = sortTable[i].value
			
			if not Viewda.items[i] then
				Viewda:CreateDisplayEntry(i, item, value, setName)
			else
				Viewda:UpdateDisplayEntry(i, item, value, setName)
			end
		end
	end
	
	-- hide unused frames
	for i = totalShown + 1, #(Viewda.items) do
		Viewda.items[i]:Hide()
	end
	
	-- notice frame
	if not Viewda.items[1] or not Viewda.items[1]:IsShown() then 
		Viewda:NoticeFrame(Viewda.locale.setNotFound)
	else
		Viewda:NoticeFrame()
	end
	
	-- update display text
	Viewda.selectionButton:SetText(setName or Viewda.locale.selectionButtonText)
end

-- displays tradeskill materials required
function Viewda:ShowCloseUp(item, value, setName)
	-- parse value string
	local itemInfo = { strsplit(";", value) }
	local setTable = {}
	for i = 1, #itemInfo do
		local infoID, infoCount = strsplit("x", itemInfo[i])
		tinsert(setTable, { itemID = infoID, count = infoCount })
	end
	
	-- show item entries
	local totalShown = #setTable
	for i = 1, totalShown do
		local item = setTable[i].itemID
		local value = setTable[i].count
		local itemFrame
		
		if not Viewda.items[i] then
			Viewda:CreateDisplayEntry(i, item, value, setName)
		else
			itemFrame = Viewda:UpdateDisplayEntry(i, item, value, setName, "item")
		end
	end

	-- hide unused frames
	for i = totalShown + 1, #(Viewda.items) do
		Viewda.items[i]:Hide()
	end
	
	-- update display text
	local itemName = GetItemInfo(item)
	Viewda.selectionButton:SetText((setName or "").."."..(itemName or Viewda.locale.unknown))
end

-- displayed fav'ed items
function Viewda:ShowFavorites()
	-- collect items
	local itemInfo = VD_LocalDB.favorites
	local sortTable = {}
	for i = 1, #itemInfo do
		tinsert(sortTable, { itemID = itemInfo[i].itemID, type = itemInfo[i].type, set = itemInfo[i].set })
	end
	sort(sortTable, function(a, b)
		return a.set < b.set
	end)
	
	-- show item entries
	local totalShown = #sortTable
	for i = 1, totalShown do
		if not Viewda.items[i] then
			Viewda:CreateDisplayEntry(i, sortTable[i].itemID, sortTable[i].set, Viewda.locale.favorites, sortTable[i].type)
		else
			Viewda:UpdateDisplayEntry(i, sortTable[i].itemID, sortTable[i].set, Viewda.locale.favorites, sortTable[i].type)
		end
	end

	-- hide unused frames
	for i = totalShown + 1, #(Viewda.items) do
		Viewda.items[i]:Hide()
	end
	
	-- notice frame
	if not Viewda.items[1] or not Viewda.items[1]:IsShown() then 
		Viewda:NoticeFrame(Viewda.locale.noFavorites)
	else
		Viewda:NoticeFrame()
	end
	
	-- update display text
	Viewda.selectionButton:SetText(Viewda.locale.favorites)
end

function Viewda:CreateDropdown(parent)
	local periodicTable = {}
	for set, _ in pairs(Viewda.LPT.sets) do
		local partials = { strsplit(".", set) }
		local maxParts = #partials
		local pre = periodicTable
		
		for i = 1, maxParts do
			if i == maxParts then
				-- actual clickable entries
				pre[ partials[i] ] = set
			else
				-- all parts before that
				if not pre[ partials[i] ] or type(pre[ partials[i] ]) == "string" then
					pre[ partials[i] ] = {}
				end
				pre = pre[ partials[i] ]
			end
		end
	end
	sort(periodicTable)
	Viewda.periodicTable = periodicTable
	
	local dropDown = CreateFrame("Frame", "ViewdaDropDownMenuFrame", parent)--, "UIDropDownMenuTemplate")
	
	-- button
	local menuButton = CreateFrame("Button", nil, dropDown) -- "UIPanelButtonTemplate"
	menuButton:SetAllPoints()
	menuButton:SetWidth(500)
	menuButton:SetHighlightFontObject(GameFontHighlight)
	menuButton:SetNormalFontObject(GameFontNormal)
	menuButton:SetText(Viewda.locale.selectionButtonText)
	
	menuButton:RegisterForClicks("AnyUp")
	menuButton:SetScript("OnClick", function(self, button)
		ToggleDropDownMenu(1, nil, dropDown, menuButton, 0, 0)
	end)
	
	local function DropdownInit(self,level)
		local selected = UIDropDownMenu_GetSelectedValue(menuButton)
		level = level or 1
		
		if level == 1 then
			for key, subarray in pairs(periodicTable) do
				-- submenus
				local info = UIDropDownMenu_CreateInfo()
				info.hasArrow = true
				info.text = key
				info.category = key
				info.checked = key == selected
				info.value = {
					[1] = key
				}
				info.func = function()
					category = key
					UIDropDownMenu_SetSelectedValue(menuButton, category)
					menuButton:SetText(category)
					Viewda:Show(category)
					
					CloseDropDownMenus()
				end
				UIDropDownMenu_AddButton(info, level)
			end
		
		else
			-- getting values of first menu
			local parentValue = UIDROPDOWNMENU_MENU_VALUE
			local PTSets = periodicTable
			for i = 1, level - 1 do
				PTSets = PTSets[ parentValue[i] ]
			end
			
			for key, value in pairs(PTSets) do
				local newValue = {}
				for i = 1, level - 1 do
					newValue[i] = parentValue[i]
				end
				newValue[level] = key
				-- calculate category string
				local valueString = newValue[1]
				for i = 2, level do
					valueString = valueString.."."..newValue[i]
				end
				
				local info = UIDropDownMenu_CreateInfo()
				if type(value) == "table" then
					-- submenu
					info.hasArrow = true
					info.category = valueString
					info.value = newValue
				else
					-- end node
					info.hasArrow = false
				end
				info.func = function()
					category = valueString
					UIDropDownMenu_SetSelectedValue(menuButton, category)
					menuButton:SetText(category)
					Viewda:Show(category)
					
					CloseDropDownMenus()
				end
				info.checked = valueString == selected
				info.text = key
				
				UIDropDownMenu_AddButton(info, level)
			end
		end
	end
	
	UIDropDownMenu_Initialize(dropDown, DropdownInit)--, "MENU")
	
	return menuButton, dropDown
end