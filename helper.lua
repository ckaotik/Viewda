_, Viewda = ...

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
  if VD_GlobalDB.debug then
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

local function RequestItem(entry)
	if not entry then return end
	
	if entry.request then
		if entry.tipText and entry.tipText == Viewda.locale.tooltipUpdateIcon then
			entry.request = nil
			entry.tipText = nil
			
			Viewda:UpdateDisplayEntry(entry:GetID(), entry.itemID, entry.value)
		end
	else
		if VD_GlobalDB.showChatMessage_Query then
			Viewda:Print(Viewda.locale.chatQueryServer)
		end
		GameTooltip:SetHyperlink("item:"..entry.itemID..":0:0:0:0:0:0:0")
		
		entry.request = true
		entry.tipText = Viewda.locale.tooltipUpdateIcon
	end
end

function Viewda:ShowTooltip()
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	local entry = self:GetParent()
	local itemID = self.itemID or entry.itemID
	local spellID = self.spellID or entry.spellID
	local tipText = self.tipText or entry.tipText
	local link = self.itemLink or entry.itemLink or (itemID and select(2,GetItemInfo(itemID))) or (spellID and GetSpellLink(spellID))
	
	if itemID and (not link and VD_GlobalDB.queryOnMouseover) or entry.request then
		RequestItem(entry)
	end
	
	if tipText then
		GameTooltip:SetText(tipText, nil, nil, nil, nil, true)
    elseif link then
		GameTooltip:SetHyperlink(link)	-- TODO: 5420 doesn't show a tooltip
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

-- scans a given item for searchString
local scanTooltip = CreateFrame("GameTooltip", "ViewdaItemScan", UIParent, "GameTooltipTemplate")
function Viewda:ScanTooltip(itemLink, searchString)
	if not itemLink or not searchString then return end
	scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
	scanTooltip:SetHyperlink(itemLink)
	
	for i = 1, scanTooltip:NumLines() or 0 do
		local leftLine = getglobal(scanTooltip:GetName().."TextLeft"..i)
		local leftLineText = leftLine and leftLine:GetText() or ""
		
		local found, _, text = string.find(leftLineText, searchString)
		if found then
			return true, text ~= "" and text or nil
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
	if not itemLink or not VD_GlobalDB.colorByRole then return 1, 1, 1, nil end
	-- only care about equippable items
	local itemSlot = select(9, GetItemInfo(itemLink))
	if not itemSlot or not string.find(itemSlot, "INVTYPE") or string.find(itemSlot, "BAG") then
		
		return 1, 1, 1, nil
	end

	-- see if we find any clues as for what role this item is intended
	local stats = GetItemStats(itemLink)
	-- first mutually exclusive stats
	for stat, value in pairs(stats) do
		if stat == "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT"
			or stat == "ITEM_MOD_DODGE_RATING_SHORT"
			or stat == "ITEM_MOD_PARRY_RATING_SHORT"
			or stat == "ITEM_MOD_BLOCK_RATING_SHORT" then	-- tank item
			return 0, 0, 1, "TANK"
		elseif stat == "ITEM_MOD_MANA_REGENERATION_SHORT"
			or stat == "ITEM_MOD_POWER_REGEN0_SHORT" then	-- heal item
			return 0, 1, 0, "HEALER"
		end
	end
	
	-- if we get here, we didn't decide yet
	for stat, value in pairs(stats) do
		if stat == "ITEM_MOD_SPELL_POWER_SHORT" then	-- caster
			return 1, 0.4, 0, "CASTER"
		elseif stat == "ITEM_MOD_ATTACK_POWER_SHORT" or
			stat == "ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT" or
			stat == "ITEM_MOD_EXPERTISE_RATING_SHORT" or 
			stat == "ITEM_MOD_AGILITY_SHORT" or 
			stat == "ITEM_MOD_STRENGTH_SHORT" then	-- melee
			return 1, 0, 0.4, "MELEE"
		end
	end
	
	-- don't know
	return 1, 1, 1, nil
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
	
	return name
end

-- function that's called when a list entry is clicked
local function ViewOnClick(self, button)
	local entry = self:GetParent()
	local itemLink = entry.itemID and select(2, GetItemInfo(entry.itemID))
	
	if IsModifiedClick() then										-- this handles chat linking as well as dress-up
		HandleModifiedItemClick(itemLink or entry.tipText)
		return
	end
	
	if button == "RightButton" and ((entry.itemID and not itemLink) or entry.request) then
		RequestItem(entry:GetID())
	
	elseif entry.tipText == Viewda.locale.favorites then			-- show the favorites display
		Viewda:ShowFavorites()
	
	elseif entry.tipText and not entry.itemID and not entry.spellID then	-- show content of this category
		Viewda:Show(entry.value)
	
	elseif type(value) == "string" and string.find(value, "x") then	-- show close-up for this item
		Viewda:ShowCloseUp(entry.itemID, entry.value, Viewda.mainFrame.scrollFrame.current)
	end
end

-- creates a pretty display for an item/string
function Viewda:CreateDisplayEntry(index, item, value, forceType)
	if not item then return nil	end
	-- display frame
	local entry = CreateFrame("Frame", "ViewdaLootFrameEntry"..index, Viewda.mainFrame.content)
	entry:SetID(index)
	entry:SetWidth(180)
	entry:SetHeight(4 + 37 + 12 + 4)	-- top + icon + extra line + bottom
	entry:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Background",
		tile = false,
		edgeFile = "Interface\\Addons\\Viewda\\Media\\glow",
		edgeSize = 2,
		insets = {6, 6, 6, 6},
	})
	entry:SetBackdropColor(1, 1, 1, 0.3)
	entry:SetBackdropBorderColor(1, 0.9, 0.5)

	-- icon & needed texture for it
	entry.icon = CreateFrame("Button", "Entry"..index.."Button", entry, "ItemButtonTemplate")
	entry.icon:SetPoint("TOPLEFT", entry, "TOPLEFT", 4, -4)
	
	entry.icon:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	entry.icon:SetScript("OnClick", ViewOnClick)
	entry.icon:SetScript("OnEnter", Viewda.ShowTooltip)
	entry.icon:SetScript("OnLeave", Viewda.HideTooltip)
	
	-- favorite icon, used to mark an item
	entry.favicon = CreateFrame("CheckButton", nil, entry)
	entry.favicon:SetPoint("TOP", entry.icon, "BOTTOM", 0, 3)
	entry.favicon:SetNormalTexture("Interface\\AddOns\\Viewda\\Media\\star1")
	entry.favicon:GetNormalTexture():SetDesaturated(not entry.favicon:GetChecked())
	entry.favicon:SetWidth(16); entry.favicon:SetHeight(16)
	entry.favicon:SetScript("OnClick", function(self, button)
		local entry = self:GetParent()
		if not (entry.itemID or entry.spellID or entry.tipText) then
			self:SetChecked(not self:GetChecked())
			return
		end
		local isFavorite = Viewda:IsFavorite(entry.itemID or (entry.spellID and -1 * entry.spellID) or entry.tipText)
		if self:GetChecked() then
			self:GetNormalTexture():SetDesaturated(false)
			local found = false
			if not isFavorite then
				tinsert(VD_LocalDB.favorites, {
					itemID = entry.itemID or (entry.spellID and -1 * entry.spellID) or entry.tipText,
					set = Viewda.mainFrame.scrollFrame.current
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
		entry:SetPoint("TOPLEFT", "ViewdaLootFrameEntry"..(index-1), "TOPRIGHT", 4, 0)
	else
		entry:SetPoint("TOPLEFT", "ViewdaLootFrameEntry"..(index-2), "BOTTOMLEFT", 0, -4)
	end
	Viewda:UpdateDisplayEntry(index, item, value, entryType)
end

-- recycles a previously defined frame and fills it with new information
function Viewda:UpdateDisplayEntry(i, item, value, entryType)
	local entry = _G["ViewdaLootFrameEntry"..i]
	if not item or not entry then return end
	
	local isCategory = nil
	local itemTexture, itemLink
	local itemText, sourceText = Viewda.locale.unknown, ""
	
	_G[entry.icon:GetName().."NormalTexture"]:Show()
	entry.favicon:Show()
    entry.value = value
	
	if type(item) == "string" then	-- category
		entry.tipText = item
		entry.itemID = nil
		entry.spellID = nil
		
		isCategory = true
		if value == Viewda.locale.favorites then
			itemText = value
			value = ""
			itemTexture = "Interface\\AddOns\\Viewda\\Media\\star1"
			_G[entry.icon:GetName().."NormalTexture"]:Hide()
			entry.favicon:Hide()
		else
			itemText = Viewda:GetLocalizedName(item)
		end
		
	elseif type(item) == "number" and item < 0 then	-- spell
		entry.tipText = nil
		entry.itemID = nil
		entry.spellID = -1 * item
		
		local rank
		itemText, rank, itemTexture = GetSpellInfo(entry.spellID)
		
		if rank and rank ~= "" then
			itemText = itemText .. ",\n" .. rank
		end
		if string.find(value, "x") then
			sourceText = Viewda.locale.clickForCloseUp
		end
		
	else					-- item
		entry.tipText = nil
		entry.itemID = item
		entry.spellID = nil
		
		local quality, equipType, equipSlot
		itemText, itemLink, quality, _, _, _, equipType, _, equipSlot, itemTexture = GetItemInfo(item)
		itemText = itemText and (itemLink and (quality and select(4,GetItemQualityColor(quality))) or "") .. itemText or Viewda.locale.unknown
		
		equipType = Viewda.locale.ShortenItemSlot and Viewda.locale.ShortenItemSlot(equipType) or equipType
		sourceText = equipType and equipType .. ", " or ""
		sourceText = sourceText .. (Viewda.locale.equipLocation[equipSlot] and Viewda.locale.equipLocation[equipSlot] .. ", " or "")
	end
    if value == true then
        value = ""
        entry.value = ""
        sourceText = string.gsub(sourceText, ", $", "")
    end
	
	-- show or hide the favicon
	entry.favicon:SetChecked(Viewda:IsFavorite(entry.itemID or (entry.spellID and -1 * entry.spellID) or entry.tipText) and true or false)
	entry.favicon:GetNormalTexture():SetDesaturated(not entry.favicon:GetChecked())
	
	SetItemButtonTexture(entry.icon, itemTexture or "Interface\\Icons\\Ability_EyeOfTheOwl")
	SetItemButtonNormalTextureVertexColor(entry.icon, Viewda:GetRoleColor(itemLink))
	
	-- update the item's texts
	if isCategory or (sourceText ~= "" and not entry.itemID) then
		-- do nothing
	elseif string.find(value, "x") then
		sourceText = Viewda.locale.clickForCloseUp
	elseif string.find(value, "/") then
		local orange, yellow, green, gray = string.split("/", value)
		sourceText = Viewda.skillColor[1] .. orange .. "|r/" ..
			Viewda.skillColor[2] .. yellow .. "|r/" ..
			Viewda.skillColor[3] .. green .. "|r/" ..
			Viewda.skillColor[4] .. gray .. "|r"
	elseif Viewda.mainFrame.scrollFrame.current and string.find(Viewda.mainFrame.scrollFrame.current, "InstanceLoot") then
		sourceText = sourceText .. "|cffED9237" .. value/10 .. "%"
	else
		sourceText = sourceText .. "|cffED9237" .. value
	end
	
	entry:SetAlpha(1)
	entry.text:SetText(itemText)
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

function Viewda:SearchInCurrentView(searchString)
	--[[ local parts = { string.split("\"", searchString) }
	local primaryParts, secondaryParts = {}, {}
	for i = 1, #parts do
		if i % 2 == 0 and i < #parts then
			tinsert(primaryParts, parts[i])
		else
			tinsert(secondaryParts, parts[i])
		end
	end ]]

	local i = 1
	local entry = _G["ViewdaLootFrameEntry"..i]
	while entry and entry:IsVisible() do
		local itemName, itemLink
        local classes, iLvl = "all", 0
		if entry.itemID then
			itemName, itemLink, _, iLvl	= GetItemInfo(entry.itemID)
			
			classes = string.gsub(ITEM_CLASSES_ALLOWED, "%s", "(.+)")
			_, classes = Viewda:ScanTooltip(itemLink, classes)
		end
		local spellName, spellLink
		if entry.spellID then
			spellName = GetSpellInfo(entry.spellID)
			spellLink = GetSpellLink(entry.spellID)
		end
        
		local collection = (itemName or spellName or entry.tipText or Viewda.locale.unknown) .. "#" .. 
			(iLvl and "iLvl:" .. iLvl or "") .. "#" ..
			(classes and "c:" .. classes or "") .. "#" .. 
			(itemLink and select(4, Viewda:GetRoleColor(itemLink)) or "") .. "#" ..
			(entry.source and entry.source.GetText and entry.source:GetText() or "")
		collection = collection:lower()
		
		Viewda:Debug("Searching in", collection)
		if not searchString or string.match(collection, searchString) then
			entry:SetAlpha(1)
		else
			entry:SetAlpha(0.3)
		end
		
		i = i + 1
		entry = _G["ViewdaLootFrameEntry"..i]
	end
end

-- returns true if the <item> should be shown because of filter <filterName>
function Viewda:SetFilter(item)
	if not item or not (type(item) == "number" and item >= 0) then return end
	item = select(2, GetItemInfo(item))
	
	local pve = Viewda.filter["pve"] and not Viewda:ScanTooltip(item, ITEM_MOD_RESILIENCE_RATING_SHORT)
	local pvp = Viewda.filter["pvp"] and Viewda:ScanTooltip(item, ITEM_MOD_RESILIENCE_RATING_SHORT)
	local heroic = (Viewda.filter["heroic"] and Viewda:ScanTooltip(item, ITEM_HEROIC)) or 
		(not Viewda.filter["heroic"] and not Viewda:ScanTooltip(item, ITEM_HEROIC))
	
	local role = select(4, Viewda:GetRoleColor(item))
	local tank = Viewda.filter["tank"] and role == "TANK"
	local melee = Viewda.filter["melee"] and role == "MELEE"
	local caster = Viewda.filter["caster"] and role == "CASTER"
	local healer = Viewda.filter["healer"] and role == "HEALER"
	
	return (pve or pvp) and (not role or tank or melee or caster or healer) and heroic
end

function Viewda:Show(setName)
	local setTable
	if not setName then
		setTable = Viewda.periodicTable
	else
		setTable = Viewda.LPT:GetSetTable(setName) or {}
	end
	Viewda.mainFrame.scrollFrame.current = setName
	
	local totalShown = 0
	if not setName then		-- show absolute index
		local sortTable = {}
		for subSet, _ in pairs(setTable) do
			tinsert(sortTable, subSet)
		end
		sort(sortTable)
		
		totalShown = #sortTable
		for i = 1, totalShown do
			local subSet = sortTable[i]
			
			if not _G["ViewdaLootFrameEntry"..i] then
				--						index  item     value
				Viewda:CreateDisplayEntry(i, subSet, subSet, true)
			else
				Viewda:UpdateDisplayEntry(i, subSet, subSet, true)
			end
		end
		
		totalShown = totalShown + 1
		if not _G["ViewdaLootFrameEntry"..totalShown] then
			Viewda:CreateDisplayEntry(totalShown, Viewda.locale.favorites, "Favorites", true)
		else
			Viewda:UpdateDisplayEntry(totalShown, Viewda.locale.favorites, "Favorites", true)
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
			if not _G["ViewdaLootFrameEntry"..i] then
				Viewda:CreateDisplayEntry(i, subCategory, setName.."."..subCategory, true)
			else
				itemFrame = Viewda:UpdateDisplayEntry(i, subCategory, setName.."."..subCategory, true)
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
		
		local used = 0
		for i = 1, #sortTable do
			local item = sortTable[i].itemID
			local value = sortTable[i].value
			
			if Viewda:SetFilter(item) then
				used = used + 1
				if not _G["ViewdaLootFrameEntry"..i] then
					Viewda:CreateDisplayEntry(used, item, value, setName)
				else
					Viewda:UpdateDisplayEntry(used, item, value, setName)
				end
			end
		end
		totalShown = used
		
		local searchString = _G["ViewdaItemsFrameSearchBox"]:GetText()
		searchString = searchString ~= Viewda.locale.search and searchString ~= "" and searchString or nil
		Viewda:SearchInCurrentView(searchString)
	end
	
	-- hide unused frames
	local total = totalShown
	local frame = _G["ViewdaLootFrameEntry"..total + 1]
	while frame do
		total = total + 1
		frame:Hide()
		frame = _G["ViewdaLootFrameEntry"..total]
	end
	
	-- notice frame
	if not _G["ViewdaLootFrameEntry"..1] or not _G["ViewdaLootFrameEntry"..1]:IsShown() then 
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
		
		if not _G["ViewdaLootFrameEntry"..i] then
			Viewda:CreateDisplayEntry(i, item, value, setName)
		else
			itemFrame = Viewda:UpdateDisplayEntry(i, item, value, setName, "item")
		end
	end

	-- hide unused frames
	local total = totalShown
	local frame = _G["ViewdaLootFrameEntry"..total + 1]
	while frame do
		total = total + 1
		frame:Hide()
		frame = _G["ViewdaLootFrameEntry"..total]
	end
	
	-- update display text
	local itemName = GetItemInfo(item)
	Viewda.selectionButton:SetText((setName or "").."."..(itemName or Viewda.locale.unknown))
	local searchString = _G["ViewdaItemsFrameSearchBox"]:GetText()
	searchString = searchString ~= Viewda.locale.search and searchString ~= "" and searchString or nil
	Viewda:SearchInCurrentView(searchString)
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
		if not _G["ViewdaLootFrameEntry"..i] then
			Viewda:CreateDisplayEntry(i, sortTable[i].itemID, sortTable[i].set, Viewda.locale.favorites, sortTable[i].type)
		else
			Viewda:UpdateDisplayEntry(i, sortTable[i].itemID, sortTable[i].set, Viewda.locale.favorites, sortTable[i].type)
		end
	end

	-- hide unused frames
	local total = totalShown
	local frame = _G["ViewdaLootFrameEntry"..total + 1]
	while frame do
		total = total + 1
		frame:Hide()
		frame = _G["ViewdaLootFrameEntry"..total]
	end
	
	-- notice frame
	if not _G["ViewdaLootFrameEntry"..1] or not _G["ViewdaLootFrameEntry"..1]:IsShown() then 
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