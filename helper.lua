local _, Viewda = ...

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

function Viewda.ShowTooltip(object)
	object = object or self
	GameTooltip:SetOwner(object, "ANCHOR_RIGHT")

	local entry = object:GetParent()

	local tipText = object.tipText or entry.tipText
	if tipText then
		GameTooltip:SetText(tipText, nil, nil, nil, nil, true)

	else
		local itemID = object.itemID or entry.itemID
		if not itemID then return end

		local link
		if itemID < 0 then
			link = GetSpellLink(-1*itemID)
		else
			_, link = GetItemInfo(itemID)
		end

		if link then GameTooltip:SetHyperlink(link) end

		if entry.text:GetText() == Viewda.locale.unknown then
			Viewda.UpdateDisplayEntry(entry:GetID(), itemID, Viewda.displayedSet)
		end
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
function Viewda:IsFavorite(itemID, path)
	local found, fave
	for i = 1, #VD_LocalDB.favorites do
		fave = VD_LocalDB.favorites[i]
		if fave.itemID == itemID or (type(itemID) == "number" and fave.itemID == -1*itemID) then
			if not path or fave.set == path then
				found = i
				break
			end
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
		if stat == "ITEM_MOD_DODGE_RATING_SHORT"
			or stat == "ITEM_MOD_PARRY_RATING_SHORT" then	-- tank item
			return 0, 0, 1, "TANK"
		elseif stat == "ITEM_MOD_SPIRIT_SHORT" then	-- heal item
			return 0, 1, 0, "HEALER"
		end
	end

	-- if we get here, we didn't decide yet
	for stat, value in pairs(stats) do
		if stat == "ITEM_MOD_SPELL_POWER_SHORT"
			or stat == "ITEM_MOD_INTELLECT_SHORT" then	-- caster
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
	if Viewda.locale[name] then
		return Viewda.locale[name]
	end

	--[[ local number = tonumber(name)
	if number then
		name = GetItemInfo(number) or GetSpellInfo(number) or name
	else --]]
		local data
		for _, lib in pairs(Viewda.Babble) do
			data = lib:GetUnstrictLookupTable()
			if data and data[name] then
				return data[name]
			end
		end
	-- end

	return name
end

-- function that's called when a list entry is clicked
local function ViewOnClick(self, button)
	local entry = self:GetParent()
	local itemLink = entry.itemID and select(2, GetItemInfo(entry.itemID))

	if IsModifiedClick() then
		local setTable = Viewda.LPT:GetSetTable(entry.value) or {}
		local doReturn, link = nil, nil

		if not Viewda.LPT:IsSetMulti(entry.value) then
			for item, _ in pairs(setTable) do
				if item < 0 then
					link = GetSpellLink(item)
				else
					_, link = GetItemInfo(item)
				end
				HandleModifiedItemClick(link)
				doReturn = true
			end
		end

		if not doReturn then
			HandleModifiedItemClick(itemLink or entry.tipText)
		end

		return
	end

	if entry.tipText then
		if not entry.itemID then
			-- show content of this category
			Viewda:Show(entry.value)
		end
	elseif type(entry.value) == "string" and string.find(entry.value, "x") then
		-- show close-up for this item
		Viewda:ShowCloseUp(entry.itemID, entry.value, Viewda.displayedSet)
	end
end

-- creates a pretty display for an item/string
function Viewda.CreateDisplayEntry(index)
	-- display frame
	local entry = CreateFrame("Frame", "ViewdaLootFrameEntry"..index, Viewda.scrollFrame)
	entry:SetID(index)
	entry:SetWidth(180)
	entry:SetHeight(Viewda.scrollFrame.rowHeight)
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
	entry.icon = CreateFrame("Button", "ViewdaLootFrameEntry"..index.."Button", entry, "ItemButtonTemplate")
	entry.icon:SetPoint("TOPLEFT", entry, "TOPLEFT", 4, -4)

	entry.icon:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	entry.icon:SetScript("OnClick", ViewOnClick)
	entry.icon:SetScript("OnEnter", Viewda.ShowTooltip)
	entry.icon:SetScript("OnLeave", Viewda.HideTooltip)

	-- favorite icon, used to mark an item
	entry.favicon = CreateFrame("CheckButton", nil, entry)
	--entry.favicon:SetPoint("TOP", entry.icon, "BOTTOM", 0, 3)
	entry.favicon:SetPoint("TOPRIGHT", entry, "TOPRIGHT", -2, -2)
	entry.favicon:SetNormalTexture("Interface\\AddOns\\Viewda\\Media\\star1") -- http://i.imgur.com/cJEC2.png
	entry.favicon:GetNormalTexture():SetDesaturated(not entry.favicon:GetChecked())
	entry.favicon:SetWidth(16); entry.favicon:SetHeight(16)
	entry.favicon:SetScript("OnClick", function(self, button)
		local entry = self:GetParent()

		if not (entry.itemID or entry.spellID or entry.tipText) then
			self:SetChecked(not self:GetChecked())
			return
		end
		local isFavorite = Viewda:IsFavorite(entry.itemID or (entry.spellID and -1 * entry.spellID) or entry.tipText), Viewda.displayedSet
		if self:GetChecked() then
			self:GetNormalTexture():SetDesaturated(false)
			local found = false
			if not isFavorite then
				tinsert(VD_LocalDB.favorites, {
					itemID = entry.itemID or (entry.spellID and -1 * entry.spellID) or entry.tipText,
					set = Viewda.displayedSet
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
	entry.source:SetPoint("TOPLEFT", entry.icon, "BOTTOMLEFT", 0, -2)
	entry.source:SetPoint("BOTTOMRIGHT", entry, "BOTTOMRIGHT", -4, 2)
	entry.source:SetJustifyH("RIGHT")

	-- anchor the whole thing
	if index == 1 then
		entry:SetPoint("TOPLEFT", Viewda.scrollFrame, "TOPLEFT", 2, 0)
	elseif index % 2 == 0 then
		entry:SetPoint("TOPLEFT", "ViewdaLootFrameEntry"..(index-1), "TOPRIGHT", 4, 0)
	else
		entry:SetPoint("TOPLEFT", "ViewdaLootFrameEntry"..(index-2), "BOTTOMLEFT", 0, -4)
	end

	return entry
end

-- recycles a previously defined frame and fills it with new information
function Viewda.UpdateDisplayEntry(index, item, path)
	local entry = _G["ViewdaLootFrameEntry"..index] or Viewda.CreateDisplayEntry(index)
	if not entry or not item then return end

	local isCategory = type(item) == "string"
	local hideIconBG = false

	local itemText = Viewda.locale.unknown
	local itemTexture, itemLink, itemValue, sourceText
	if isCategory then
		entry.tipText = item
		entry.itemID = nil

		itemText = Viewda:GetLocalizedName(item)
		if item == "Favorites" or path == "Favorites" then
			itemTexture = item == "Favorites" and "Interface\\AddOns\\Viewda\\Media\\star1" or "Interface\\Icons\\Ability_EyeOfTheOwl"
			itemValue = item
			hideIconBG = true
		else
			itemTexture = "Interface\\Icons\\Ability_EyeOfTheOwl"
			itemValue = (path and (path..".") or "") .. item
		end
	else
		entry.tipText = nil
		entry.itemID = item

		itemValue = Viewda.LPT:GetSetTable(path)[item]
		if type(itemValue) == "boolean" then
			itemValue = ""
		end

		if type(item) == "number" and item < 0 then
			local rank
			itemText, rank, itemTexture = GetSpellInfo(-1*item)

			if rank and rank ~= "" then
				itemText = itemText .. ",\n" .. rank
			end
		else
			local quality, equipType, equipSlot
			itemText, itemLink, quality, _, _, _, equipType, _, equipSlot, itemTexture = GetItemInfo(item)

			itemText = itemText and (itemLink and (quality and "|c"..select(4,GetItemQualityColor(quality))) or "") .. itemText or Viewda.locale.unknown
			sourceText = "" .. (equipType and equipType .. ", " or "") .. (equipSlot and _G[equipSlot] and _G[equipSlot] .. ", " or "")

			if itemValue == "" then
				sourceText = sourceText and string.sub(sourceText, 1, -3)
			end
		end
	end

	-- show or hide the favicon
	entry.favicon:SetChecked( Viewda:IsFavorite(entry.itemID or entry.tipText, path) )
	entry.favicon:GetNormalTexture():SetDesaturated(not entry.favicon:GetChecked())

	-- set button texture
	SetItemButtonTexture(entry.icon, itemTexture or "Interface\\Icons\\Ability_EyeOfTheOwl")
	SetItemButtonNormalTextureVertexColor(entry.icon, Viewda:GetRoleColor(itemLink))

	local iconBG = _G[entry.icon:GetName().."NormalTexture"]
	if hideIconBG then iconBG:Hide() else iconBG:Show() end

	-- update the item's texts
	if isCategory or (sourceText and sourceText ~= "" and not entry.itemID) then
		-- do nothing
	elseif not itemValue or itemValue == "" then
		-- do nothing
	elseif string.find(itemValue, "x") then
		sourceText = Viewda.locale.clickForCloseUp
	elseif string.find(itemValue, "/") then
		local orange, yellow, green, gray = string.split("/", itemValue)
		sourceText = Viewda.skillColor[1] .. orange .. "|r/" ..
			Viewda.skillColor[2] .. yellow .. "|r/" ..
			Viewda.skillColor[3] .. green .. "|r/" ..
			Viewda.skillColor[4] .. gray .. "|r"
	elseif Viewda.displayedSet and string.find(Viewda.displayedSet, "InstanceLoot") then
		sourceText = (sourceText or "").. "|cffED9237" .. tonumber(itemValue or 0)/10 .. "%"
	else
		sourceText = (sourceText or "") .. "|cffED9237" .. (itemValue or "")
	end

	entry.value = itemValue
	entry.text:SetText(itemText)
	entry.source:SetText(sourceText or "")

	local currentSearch = _G["ViewdaItemsFrameSearchBox"].searchString
	if currentSearch then
		local shouldFade = Viewda:SearchEntry(entry, currentSearch)
		entry:SetAlpha(shouldFade and 0.3 or 1)
	else
		entry:SetAlpha(1)
	end
	entry:Show()
end

-- creates & manages the notice frame
function Viewda:NoticeFrame(text)
	local noticeFrame = _G["ViewdaNoticeFrame"]
	if not noticeFrame then
		noticeFrame = CreateFrame("Frame", "ViewdaNoticeFrame", Viewda.scrollFrame)
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

local ItemSearch = LibStub('LibItemSearch-1.0')
ItemSearch:RegisterTypedSearch{
	id = 'classRestriction',
	tags = {'c', 'class'},
	canSearch = function(self, _, search)
		return search
	end,
	findItem = function(self, link, _, search)
		if link:find("battlepet") then return false end

		local tooltipScanner = _G['LibItemSearchTooltipScanner']
		tooltipScanner:SetOwner(UIParent, 'ANCHOR_NONE')
		tooltipScanner:SetHyperlink(link)

		local pattern = string.gsub(ITEM_CLASSES_ALLOWED:lower(), "%%s", "(.+)")
		for i = 1, tooltipScanner:NumLines() do
			local text =  _G[tooltipScanner:GetName() .. 'TextLeft' .. i]:GetText():lower()
			text = string.find(text, pattern)

			if text and tostring(text):find(search) then
				return true
			end
		end
		return false
	end,
}
ItemSearch:RegisterTypedSearch{
	id = 'text',
	canSearch = function(self, _, search)
		return search
	end,
	findItem = function(self, text, _, search)
		return text:lower():find(search)
	end,
}
local simpleSearch = ItemSearch:GetTypedSearch('text')

function Viewda:SearchEntry(entry, searchString)
	local link
	if entry.itemID then
		if entry.itemID > 0 then
			_, link = GetItemInfo(entry.itemID)
		else
			link = GetSpellLink(-1*entry.itemID)
		end
		return not (link and ItemSearch:Find(link, searchString))

	elseif entry.tipText then
		link = entry.tipText
		if link ~= entry.text:GetText() then
			link = link and (link .. " " .. entry.text:GetText())
		end
		return not (link and ItemSearch:UseTypedSearch(simpleSearch, link, nil, searchString))
	end
end

function Viewda:SearchInCurrentView(searchString)
	local i = 1
	local entry = _G["ViewdaLootFrameEntry"..i]
	while entry do
		local shouldFade = Viewda:SearchEntry(entry, searchString)
		entry:SetAlpha(shouldFade and 0.3 or 1)

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

function Viewda.UpdateDisplay()
	local frame = Viewda.scrollFrame
	-- scrollFrame, total lines, shown lines, line height, ..., alwaysShowScrollBar
	FauxScrollFrame_Update(frame, math.ceil(#frame.data/frame.numPerRow), frame.numRows, frame.rowHeight, nil, nil, nil, nil, nil, nil, true)

	local offset = FauxScrollFrame_GetOffset(frame) * frame.numPerRow
	local entry, idx, name, path = nil, nil, nil, nil
	for i = 1, frame.numRows*frame.numPerRow do
		idx = offset + i

		if frame.data[idx] and string.find(frame.data[idx], '|') then
			name, path = string.split('|', frame.data[idx])
		else
			name = frame.data[idx]
			path = Viewda.displayedSet
		end

		entry = _G['ViewdaLootFrameEntry'..i]
		if idx <= #frame.data and name then
			Viewda.UpdateDisplayEntry(i, name, path)
		elseif entry then
			entry:Hide()
		end
	end
end

local function SortByName(a,b)
	local locA = Viewda:GetLocalizedName(a) or a
	local locB = Viewda:GetLocalizedName(b) or b
	return locA < locB
end
local function SortByValue(a, b)
	local path = Viewda.displayedSet
	if path == "Favorites" then
		path = ""
	end

	local valueA, valueB
	if path ~= "" then
		valueA = Viewda.LPT:GetSetTable(path)[a]
		valueB = Viewda.LPT:GetSetTable(path)[b]
	end

	if not valueA and not valueB then
		return SortByName(a, b)
	elseif not (valueA and valueB) then
		-- category strings before actual items
		return not valueA
	else
		valueA = (valueA == true) and -1 or valueA
		valueB = (valueB == true) and -1 or valueB

		if string.find(valueA, "/") then
			valueA = string.match(valueA, "%d+")
			valueA = tonumber(valueA)
		elseif type(valueA) == "string" then
			valueA = -1
		end
		if string.find(valueB, "/") then
			valueB = string.match(valueB, "%d+")
			valueB = tonumber(valueB)
		elseif type(valueB) == "string" then
			valueB = -1
		end

		if valueA ~= valueB then
			return valueA < valueB
		else
			return SortByName(a, b)
		end
	end
end
function Viewda:Show(setName)
	local setTable = Viewda.topLevelCategories
	if setName then
		setTable = Viewda.LPT:GetSetTable(setName) or {}
		UIDropDownMenu_SetSelectedValue(Viewda.dropDown, setName)
	end
	Viewda.displayedSet = setName
	UIDropDownMenu_SetText(Viewda.dropDown, setName or Viewda.locale.selectionButtonText)

	local totalShown, numShown = 0
	local sortTable = Viewda.scrollFrame.data
	if not sortTable then
		sortTable = {}
		Viewda.scrollFrame.data = sortTable
	end
	wipe(sortTable)

	if not setName then
		-- show top level categories
		for i, subSet in pairs(setTable) do
			table.insert(sortTable, subSet)
		end

		table.sort(sortTable, SortByName)
		table.insert(sortTable, "Favorites")

	elseif setName == "Favorites" then
		-- show favorite sets/items, set by the player
		local faves = VD_LocalDB.favorites
		local name
		for i = 1, #faves do
			name = faves[i].set
			if type(faves[i].itemID) ~= "number" then
				name = name .. "." .. faves[i].itemID
			end
			table.insert(sortTable, name)
		end
		table.sort(sortTable, SortByName)

	elseif Viewda.LPT:IsSetMulti(setName) then
		-- show category sub-categories
		local subCategory, treeLevel, path

		for _, subTable in pairs(setTable) do
			-- note: "." in setNames might mess up matching, but I don't care right now
			if string.match(subTable.set, "^"..setName) then
				subCategory = string.sub(subTable.set, strlen(setName)+2) -- after setName end + following "."
				subCategory = string.split('.', subCategory)
			else
				_, treeLevel = string.gsub(setName, "%.", "")
				treeLevel = treeLevel and treeLevel+1
				path = nil

				for i, part in ipairs( { string.split('.', subTable.set) } ) do
					if i <= treeLevel then
						path = (path and path.."." or "") .. part
					else
						subCategory = part
						break
					end
				end
				subCategory = subCategory.."|"..path
			end

			if not Viewda:Find(sortTable, subCategory) then
				table.insert(sortTable, subCategory)
			end
		end
		table.sort(sortTable, SortByName)

	else
		-- show category entries
		for itemID, value in pairs(setTable) do
			if itemID ~= "set" then
				-- table.insert(sortTable, {itemID = itemID, value = value})
				table.insert(sortTable, itemID)
			end
		end
		table.sort(sortTable, SortByValue)
	end

	Viewda.UpdateDisplay()

	-- search
	--[[ local searchString = _G["ViewdaItemsFrameSearchBox"]:GetText()
	searchString = searchString ~= Viewda.locale.search and searchString ~= "" and searchString or nil
	Viewda:SearchInCurrentView(searchString)
	if Viewda:SetFilter(item) then
		used = used + 1
		Viewda:UpdateDisplayEntry(used, item, setName)
	end --]]

	-- notice frame
	--[[ if not _G["ViewdaLootFrameEntry"..1] or not _G["ViewdaLootFrameEntry"..1]:IsShown() then
		Viewda:NoticeFrame(Viewda.locale.setNotFound)
	else
		Viewda:NoticeFrame()
	end --]]
end

-- displays tradeskill materials required
function Viewda:ShowCloseUp(item, value, setName)
	-- parse value string
	local itemInfo = { strsplit(";", value) }
	local setTable = {}
	for i = 1, #itemInfo do
		local infoID, infoCount = strsplit("x", itemInfo[i])
		tinsert(setTable, { itemID = tonumber(infoID), count = tonumber(infoCount) })
	end

	-- show item entries
	local totalShown = #setTable
	for i = 1, totalShown do
		Viewda.UpdateDisplayEntry(i, setTable[i].itemID, setName)
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
	UIDropDownMenu_SetText(Viewda.dropDown, (setName or "").."."..(itemName or Viewda.locale.unknown))
	local searchString = _G["ViewdaItemsFrameSearchBox"]:GetText()
	searchString = searchString ~= Viewda.locale.search and searchString ~= "" and searchString or nil
	Viewda:SearchInCurrentView(searchString)
end

function Viewda:CreateDropdown(parent)
	local categories = {}
	for category, _ in pairs(Viewda.LPT.embedversions) do
		table.insert(categories, category)
	end
	table.sort(categories)
	Viewda.topLevelCategories = categories

	local dropDown = CreateFrame("Frame", "ViewdaDropDownMenuFrame", parent, "UIDropDownMenuTemplate")
	dropDown.displayMode = "MENU"

	local function SelectCategory(self)
		UIDropDownMenu_SetSelectedValue(dropDown, self.value)
		UIDropDownMenu_SetText(dropDown, self.value)
		Viewda:Show(self.value)
	end

	local setData, temp, hasSubSet
	dropDown.initialize = function(self, level)
		local lvl = level or 1
		local info = UIDropDownMenu_CreateInfo()
		local selected = UIDropDownMenu_GetSelectedValue(self)
		local parentValue, subSets

		-- header text
		if lvl == 1 then
			info.text = "LibPeriodicTable"
			info.isTitle = true
			info.hasArrow = nil
			UIDropDownMenu_AddButton(info, lvl)
		end

		parentValue = UIDROPDOWNMENU_MENU_VALUE
		if lvl == 1 then
			subSets = categories
		elseif parentValue and Viewda.LPT:IsSetMulti(parentValue) then
			setData = Viewda.LPT:GetSetString(parentValue)
			setData = { strsplit( ",", setData ) }
			table.remove(setData, 1)

			subSets = {}
			for _,setName in pairs(setData) do
				temp = string.sub(setName, strlen(parentValue) + 2)
				temp = string.sub(temp, 0, (string.find(temp, "%.") or 0) - 1)
				temp = parentValue .. "." .. temp
				if not tContains(subSets, temp) then
					table.insert(subSets, temp)
				end
			end
			table.sort(subSets)
		end

		-- common attributes
		info.isTitle = nil
		info.disabled = nil
		info.func = SelectCategory

		for _, set in ipairs(subSets) do
			info.text = string.match(set, "^.*%.(.*)$") or set
			info.value = set
			info.checked = (set == selected)
			info.hasArrow = Viewda.LPT:IsSetMulti(set)

			--[[ hasSubSet = nil
			if Viewda.LPT:IsSetMulti(set) then
				_, hasSubSet = string.gsub(Viewda.LPT:GetSetString(set), ",", ",")
			end
			info.hasArrow = hasSubSet and hasSubSet > 1 or nil --]]


			UIDropDownMenu_AddButton(info, lvl)
		end
	end
	-- UIDropDownMenu_Initialize(dropDown)

	-- return menuButton, dropDown
	return dropDown
end
